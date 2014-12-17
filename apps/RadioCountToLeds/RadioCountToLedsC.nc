// $Id: RadioCountToLedsC.nc,v 1.7 2010-06-29 22:07:17 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
#include "Timer.h"
#include "RadioCountToLeds.h"
 
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author: Philip Levis
 * @Minor modifications made by: Denis Ulybyshev
 * @date   June 6 2005, Nov.11 2014
 */

module RadioCountToLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;

    interface SplitControl as RadioControl;
    interface StdControl as RoutingControl;
    interface Send;
    interface RootControl;
    interface Intercept;
    interface CtpInfo;

  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;

  //uld new EasyCollection
  int rootNode = 0;
  bool sendBusy = FALSE;
  uint16_t index = 1;
  
/* uld 
  event void Boot.booted() {
    call Leds.led0On();
    dbg("Boot", "uld===> Application booted.\n");
    dbg("RadioCountToLedsC", "Time==> : %s\n", sim_time_string());
    call AMControl.start();
  }
*/

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(1111250);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // here we do nothing
  }
  
  event void MilliTimer.fired() {
    counter++;
    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      //empty packet is prepared
      if (rcm == NULL) {
	return;
      }

      rcm->counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      //send our packet with filled rcm->counter field to all other nodes (broadcasting) 
	dbg("RadioCountToLedsC", "RadioCountToLedsC: packet sent.\n", counter);	
	locked = TRUE;
      }
    }
  }

/*
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
    
    //if packet is only partially received 	
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    
    //if packet was fully received
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      if (rcm->counter & 0x1) {
	call Leds.led0On();
      }
      else {
	call Leds.led0Off();
      }
      if (rcm->counter & 0x2) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (rcm->counter & 0x4) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      return bufPtr;
    }
  }
*/

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

//new part uld Easy Collection 

 typedef nx_struct EasyCollectionMsg {
    nx_uint16_t source;
    nx_uint16_t id;
    nx_uint16_t data;
  } EasyCollectionMsg;


void printNbrList(){
    int i =0;
    uint16_t parent;
    call CtpInfo.getParent(&parent);
printf("=========== I am %d; My parent %d; My nbrhood is below ==============\n",TOS_NODE_ID, parent);
    for (i = 0; i < call CtpInfo.numNeighbors(); i++)
        printf("%d -> Nbr: %d LQ: %d RQ: %d\n", TOS_NODE_ID, call CtpInfo.getNeighborAddr(i), call CtpInfo.getNeighborLinkQuality(i), call CtpInfo.getNeighborRouteQuality(i));
}

  event void Boot.booted() {
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS)
      call RadioControl.start();
    else {
      call RoutingControl.start();
      if (TOS_NODE_ID == rootNode)
        call RootControl.setRoot();
      else if (TOS_NODE_ID%3 == 0)
        call Timer.startPeriodic(3000);
    }
  }

event void RadioControl.stopDone(error_t err) {}

event bool Intercept.forward(message_t* msg, void* payload, uint8_t len){
  
  EasyCollectionMsg* packetRcvd = (EasyCollectionMsg*)payload;
  dbg("EasyCollection", "Intercepted: Origin %d Id %d Data %d\n", packetRcvd->source, packetRcvd->id, packetRcvd->data);
  return TRUE;
}
  void sendMessage(uint16_t value) {
    EasyCollectionMsg* msg =
      (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
    msg->source = TOS_NODE_ID;
    msg->id = index;
    index = (index + 1)%32000;
    msg->data = value;

    if(index % 10 == 0)
        printNbrList();
    if (call Send.send(&packet, sizeof(EasyCollectionMsg)) != SUCCESS)
      call Leds.led0On();
    else {
      call Leds.led1Toggle();
      dbg("EasyCollection", "Sent: Origin %d Id %d Data %d\n", msg->source, msg->id, msg->data);
      sendBusy = TRUE;
    }
  }
  event void Timer.fired() {

    if (!sendBusy)
      sendMessage(0xA);
  }
  
  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) 
      call Leds.led0On();
    sendBusy = FALSE;
  }
  
  event message_t* 
  Receive.receive(message_t* msg, void* payload, uint8_t len) {    
    
    EasyCollectionMsg* in;
    in = (EasyCollectionMsg *)payload;
    dbg("EasyCollection", "Received: Origin %d Id %d Data %d\n", in->source, in->id, in->data);
    return msg;
  }


}




