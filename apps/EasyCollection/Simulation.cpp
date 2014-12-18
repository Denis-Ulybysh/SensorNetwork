/*
 * @author: Iftekharul Alam
 * @Modifications and additions made by: Denis Ulybyshev
 * @date  Dec.07 2014
*/

 #include <tossim.h>
 #include <stdlib.h>
int main() {

   Tossim* t = new Tossim(NULL);
   Radio* r = t->radio();
    
   FILE * file = fopen("linkgain.out", "r");
   FILE * noiseFile = fopen("meyer-short.txt","r");
   MAC* mac = t->mac();
 

   int numOfNodes = 25;
   int src;
   int dest;
   float gain;
   char string[10];
   int noiseVal = -1;

   while (!feof(file)){
  	   fscanf(file,"%s",string);
  	   if (strcmp(string,"gain") == 0){
  	    fscanf(file,"%d %d %f",&src, &dest, &gain);
  	    if ((src >= 0 && src < numOfNodes) && (dest >= 0 && dest < numOfNodes))
  	      r->add(src,dest,gain);

  	   }
   }

   while (!feof(noiseFile)){
    fscanf(noiseFile,"%d",&noiseVal);
    for (int i = 0; i <numOfNodes ; i++)
    	t->getNode(i)->addNoiseTraceReading(noiseVal);
   }

   for (int j = 0; j <numOfNodes; j++) {
        t->getNode(j)->createNoiseModel();
   }


   //uld t->addChannel("EasyCollection", stdout);
   


   for (int k = 0; k < numOfNodes; k++)
	  t->getNode(k)->bootAtTime(k*100001 + k*10);  //to start nodes at diff times, not simultaneously

  
  t->runNextEvent();
  long long int time = t->time(); //10000000000 = 1 SEC, 1 unit = 1^-10 sec
    while (true) { // while(t->time() < time + 10*10000000000){
    //OK while(t->time() < time + 100*10000000000){  //second is not a real,it is a simulation second,can be faster	  		  
     t->runNextEvent();  //all events are queued in the queue of Tiny OS and run continuously while condition is true
   }
 } 

