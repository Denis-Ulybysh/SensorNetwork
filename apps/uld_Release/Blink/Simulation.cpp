#include <tossim.h>
#include <stdlib.h>
//uld #include <SerialForwarder.h>
//uld #include <Throttle.h>

int main() {
    Tossim* t = new Tossim(NULL);
    Radio* r = t->radio();
    
    //uld SerialForwarder sf(9001);
    
    FILE * file = fopen("linkgain.out", "r");
    if (file == NULL){
        printf("Error: %d (%s)\n", errno, strerror(errno));
        exit(1);
    }
    FILE * noiseFile = fopen("meyer-short.txt","r");
    
    //FILE * energyTrace = fopen("postprocessZ/Energy.txt", "w");
    MAC* mac = t->mac();
    //mac->setBitsBerSymbol(4);
    //mac->setSymbolsPerSec(882);
    //printf("Sysmbols per second = %d ");
    
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
    
    
    //t->addChannel("Display", stdout);
    //t->addChannel("ENERGY_HANDLER", energyTrace);
    
    
    
    for (int k = 0; k < numOfNodes; k++)
        t->getNode(k)->bootAtTime(k*100001 + k*10);
    
    //uld  sf.process();   
    long long int time = t->time(); //10000000000 = 1 SEC
    while (true) {    
        //uld sf.process();
        t->runNextEvent();
    }
} 

