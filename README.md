SensorNetwork
=============

Basic project for root-cause analysis in wireless sensor networks under Tiny OS

1. /apps/EasyCollection implements injecting packet loss 
and building the local diagnosis area: see source code files 
EasyCollectionC.nC,  EasyCollectionAppC.nc,  Simulation.cpp.

2. In /apps/Blink, /apps/RadioCoundToLeds , /apps/MultihopOscilloscope
   the following small parts are implemented for tutorial 
purposes: send/receive packets, create events, print debug 
messages to the corresponding channel, firing the timers.
