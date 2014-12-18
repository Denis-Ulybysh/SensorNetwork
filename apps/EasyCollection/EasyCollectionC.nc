/*
 * @author: Iftekharul Alam
 * @Modifications and additions made by: Denis Ulybyshev
 * @date  Dec.07 2014
*/

#include <Timer.h>

module EasyCollectionC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface StdControl as RoutingControl;
 
  uses interface Send;
  uses interface Leds;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface Intercept;


  uses interface CtpInfo;
}
implementation {
  int rootNode = 0;		//#of node to be a root
  message_t packet;
  bool sendBusy = FALSE;
  uint16_t index = 1;
  
typedef nx_struct EasyCollectionMsg {
    nx_uint16_t source;
    nx_uint16_t id;
    nx_uint16_t data;
} EasyCollectionMsg;


void printNbrList(){
    int i =0;
    uint16_t parent;
    call CtpInfo.getParent(&parent);
printf("=========== I am %d; My parent %d; ==my neighbours are below ==============\n",TOS_NODE_ID, parent);
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
        call RootControl.setRoot();		//becomes a root for CTP
      else if (TOS_NODE_ID%3 == 0)		//evry third is a source node, i.e. they generate data
        call Timer.startPeriodic(3000);		
    }
  }

event void RadioControl.stopDone(error_t err) {}

//for any intermediate on the path from source to dest
//it is called automatically when packet reaches the intermediate node
event bool Intercept.forward(message_t* msg, void* payload, uint8_t len){
  
  EasyCollectionMsg* packetRcvd = (EasyCollectionMsg*)payload;
  //type cast to access fields of payload message

  dbg("EasyCollection", "Intercepted: Origin %d Id %d Data %d\n", packetRcvd->source, packetRcvd->id, packetRcvd->data);
  //OK return TRUE;
  return FALSE;
  //if return FALSE the packet will be dropped immediately
}

//is called every time timer is fired
  void sendMessage(uint16_t value) {
    EasyCollectionMsg* msg =
      (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
    msg->source = TOS_NODE_ID;
    msg->id = index;		//seq number
    index = (index + 1)%32000;  //seq numbers from 0 to 32000, i.e. very small but is enough in sensor network
    msg->data = value;		//

    if(index % 10 == 0)
        printNbrList();		//every 10-th packet will call and get CTPInfo info 
    if (call Send.send(&packet, sizeof(EasyCollectionMsg)) != SUCCESS)
      call Leds.led0On();	//red light on the sender
    else {
      call Leds.led1Toggle();   //green light on the sender
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
   
//is automatically called once packet is received by base station, i.e. by root node 
  event message_t* 
  Receive.receive(message_t* msg, void* payload, uint8_t len) {    
    
    EasyCollectionMsg* in;
    in = (EasyCollectionMsg *)payload;
    dbg("EasyCollection", "Received: Origin %d Id %d Data %d\n", in->source, in->id, in->data);
    return msg;
  }
}

//LQ: expected number of retransmission 
//RQ: link quality of the whole path, just sum of link qualities along the path 
