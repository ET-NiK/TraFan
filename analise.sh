#!/bin/bash

TCPDUMP_SNAME='trafan'
INTERFACE='lo'
SLEEP_TIME=5

# Основные параметры
if [[ -s ./analise.conf ]]; then
	# echo -e "Configuration loaded"
	source ./analise.conf
fi

# ----------------------------------------------------------------------
# Дальше лучше не трогать!

SPIN=0
SPOUT=0
PSIN=0
PSOUT=0

MAX_PS=10000

LAST_RX=0
LAST_TX=0

CUR_RX=0
CUR_TX=0

TCPDUMP_STARTED=0

# Продолжительность атаки
ATTACK_DURATION=0

# ----------------------------------------------------------------------
# Получение текущих значение rx/tx
#
function get_values()
{
	stat="$(netstat -i $INTERFACE -w | grep $INTERFACE)";
	echo $stat > stat.txt
	
	CUR_RX=$(echo $stat | awk '{print $4}')
	CUR_TX=$(echo $stat | awk '{print $8}')
}

# ----------------------------------------------------------------------
# Остановка TCPDUMP
#
function stop_tcpdump()
{
	if [[ $TCPDUMP_STARTED == 0 ]]
	then
		return
	fi
	
	SECNORM=$(($SECNORM+1))
	
	if (( $SECNORM < 10 ))
	then 
		# Еще не нормализовалось
		return
	fi
	
	SECNORM=0
	TCPDUMP_STARTED=0
	
	screen -U -X -S $TCPDUMP_SNAME kill
	
	echo "TCPDUMP STOPPED"
	
	# Переименовываем json файлы
	mv ./data/analise_src.json ./data/analise_src_$(date +%Y_%m_%d_%H%M).json
	mv ./data/analise_dst.json ./data/analise_dst_$(date +%Y_%m_%d_%H%M).json
}

# ----------------------------------------------------------------------
# Запуск TCPDUMP
#
function run_tcpdump()
{
	if [[ $TCPDUMP_STARTED == 1 ]]
	then
		ATTACK_DURATION=$(($ATTACK_DURATION+1))
		return
	fi
	
	#~ if (( $ATTACK_DURATION >= 12 ))
	#~ then 
		#~ # Продолжительность > 60 секунд, считаем, что
		#~ # tcpdump записал достаточно логов,
		#~ # иначе существует риск забить логами все дисковое
		#~ # пространство
		#~ stop_tcpdump
		#~ return
	#~ fi
	
	SECNORM=0
	TCPDUMP_STARTED=1
	echo "ALERT! DDoS Detected"
	
	if [[ $NOTISE_ENABLED == 1 ]]
	then
		VOLUME=$(awk "BEGIN {printf \"%.2f\",$SPIN/1000000"})
		(echo "Subject:DDoS Attack"; echo "Alert! DDoS Atack Detected! Volume $VOLUME Mbps") | sendmail $NOTICE_MAIL
	fi
	
	ATTACK_DURATION=0
	screen -U -m -d -S $TCPDUMP_SNAME ./run_tcpdump.sh $INTERFACE
}

echo "Traffic monitor started on $INTERFACE"

while [ true ]
do
	get_values
	
	SPIN=$(( ($CUR_RX-$LAST_RX)/$SLEEP_TIME ))
	SPOUT=$(( ($CUR_TX-$LAST_TX)/$SLEEP_TIME ))
	
	if [[ $LAST_RX != 0 ]]; then
		echo "IN: $SPIN p/s OUT: $SPOUT p/s"
		
		#if (($SPIN >= $MAX_PS)) || (($SPOUT >= $MAX_PS)) 	# Входящий и исходящий
		#if (($SPOUT >= $MAX_PS)) 							# Исходящий
		if (($SPIN >= $MAX_PS)) 							# Входящий
		then
			run_tcpdump
		else
			stop_tcpdump
		fi
		
	fi
	
	LAST_RX=$CUR_RX;
	LAST_TX=$CUR_TX;

	sleep $SLEEP_TIME
done
