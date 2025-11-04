#!/bin/ash
#===PLEASE DO NOT REMOVE===#
#===SCRIPT BY RUBBY_WRT====#
#===IMPROVEMENT WELCOME====#
#===COPYRIGHT SCRIPT=======#

interface=wwan0
portAT=ACM0

echo -e "AT+CFUN=4\r" > "/dev/tty$portAT" && sleep 1 && ifdown $interface && sleep 1 && echo -e "AT+CFUN=1\r" > "/dev/tty$portAT" && sleep 1 && ifup $interface 
