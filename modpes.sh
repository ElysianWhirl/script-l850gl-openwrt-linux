#!/bin/ash

echo -e "AT+CFUN=4\r" > "/dev/ttyACM2" && sleep 2 && ifdown wwan0 && sleep 2 && echo -e "AT+CFUN=1\r" > "/dev/ttyACM2" && sleep 1 && ifup wwan0 
