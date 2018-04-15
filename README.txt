Team : Entity
Members : 
160050042 Rupesh
160050032 Utkarsh Gupta
160050025 Naman Jain
160050002 Yash Shah

Code of Conduct
===============
"We pledge on our honour that we have not given or received any unauthorized assistance on this assignment or any previous task."

Instructions
============
1. Paste the "Entity" folder besides "makestuff" folder in "20140524".
2. 'cd' into "Entity" folder and run these commands
bash c.sh
bash vhdl.sh
bash run.sh


Assumptions
===========
1. To indicate whether a train comes from ith direction, we indicate it by sliding the switch corresponding to LEDi.
2. The input corresponding to the direction, track exist, track ok, nextsignal is fed from high order bit to lower order bit i.e in left to right order in readable format.
3. After macrostate S5, controller waits for another 10 seconds (T0) wherein it displays the latest value of uart buffer (which would be used in the next iteration).


UART details
============
We have implemented both the mandatory and the optional UART part. 
The second board should function exactly similar to the first board. But since this would lead to unnecessary delays in case that board isn't connected to the backend computer, we have provided a 'shorted' version of cksum_rtl.vhd in "optional" folder which should be loaded on the second board.

(The 'shorted' cksum_rtl.vhdl oscillates between states S0, S4, S5 and S6 and skips intermediate states)

For the relay portion, we used PySerial library and a python script. Two instances, 1.py and 2.py need to be run on the relay computer (they map ttyXRUSB0 to ttyXRUSB1).

Citation
========
For Uart communication, http://www.bealto.com/fpga-uart.html provided us with a basic_uart module which did the uart read and write when run from cksum_rtl as portmap.
For the Optional part on communicating between serial ports, https://stackoverflow.com/questions/676172/full-examples-of-using-pyserial-package
