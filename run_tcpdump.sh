#!/bin/sh
DATE=$(date +%Y_%m_%d_%H%M)
#~ tcpdump -i $1 -n -nn -ttt not port 22 > ./dump/dump_$DATE.txt
tcpdump -i $1 -n -nn -ttt not port 22 | ./trafan
