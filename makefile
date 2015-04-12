CC=g++
CFLAGS=-lmine -c -Wall -std=c++11

all:
	$(CC) $(CFLAGS) functions/files.cpp
	$(CC) $(CFLAGS) functions/functions.cpp -lm -lboost_regex -lboost_thread -lboost_system
	$(CC) $(CFLAGS) trafan.cpp
	$(CC) files.o functions.o trafan.o -o trafan -static /usr/lib/x86_64-linux-gnu/libboost_system.a /usr/lib/x86_64-linux-gnu/libboost_thread.a /usr/lib/x86_64-linux-gnu/libboost_regex.a -pthread -L -lm -lboost_regex -lboost_thread -lboost_system -lcrypto -lcryptopp -ljsoncpp

clean:
	rm -rf *.o
 
