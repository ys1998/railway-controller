import serial, time
import random
import thread

#initialization and open the port

#possible timeout values:
#    1. None: wait forever, block call
#    2. 0: non-blocking mode, return immediately
#    3. x, x is bigger than 0, float allowed, timeout block call

ser1 = serial.Serial()
ser2 = serial.Serial()

ser1.port = "/dev/ttyXRUSB0"
ser2.port = "/dev/ttyXRUSB1"

ser1.baudrate = 2400
ser2.baudrate = 2400

ser1.bytesize = serial.EIGHTBITS #number of bits per bytes
ser1.bytesize = serial.EIGHTBITS #number of bits per bytes

ser1.dsrdtr = False       #disable hardware (DSR/DTR) flow control
ser2.dsrdtr = False       #disable hardware (DSR/DTR) flow control
ser1.parity = serial.PARITY_NONE #set parity check: no parity
ser2.parity = serial.PARITY_NONE #set parity check: no parity
ser1.stopbits = serial.STOPBITS_ONE #number of stop bits
ser2.stopbits = serial.STOPBITS_ONE #number of stop bits
ser1.xonxoff = False     #disable software flow control
ser2.xonxoff = False     #disable software flow control
ser1.rtscts = False     #disable hardware (RTS/CTS) flow control
ser2.rtscts = False     #disable hardware (RTS/CTS) flow control


def communicate12(ser1,ser2):
	while True:
		message = ser1.read(1)
		ser2.write(message)
		print("Message Exchanged : " + (" ".join(hex(ord(n)) for n in message)))

def communicate21(ser1,ser2):
	while True:
		message = ser2.read(1)
		ser1.write(message)
		print("Message Exchanged : " + (" ".join(hex(ord(n)) for n in message)))		

try: 
	ser1.open()
except Exception, e:
	print "error open serial port: " + str(e)
	exit()

try: 
	ser2.open()
except Exception, e:
	print "error open serial port: " + str(e)
	exit()	

if ser1.isOpen() and ser2.isOpen():
	try:
		ser1.flushInput()  #flush input buffer, discarding all its contents
		ser1.flushOutput() #flush output buffer, aborting current output 
				 		   #and discard all that is in buffer
		ser2.flushInput()  #flush input buffer, discarding all its contents
		ser2.flushOutput() #flush output buffer, aborting current output 
				 		   #and discard all that is in buffer		 		   
		#write data
	   	communicate12(ser1,ser2)

	except Exception, e1:
		print "error communicating...: " + str(e1)

else:
	print "cannot open serial port "
