#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASE_DIR

. ${BASE_DIR}/conf/rig-monitor.conf

unset DATA_BINARY

# epoch RUN_TIME
#RUN_TIME=`date +%s`

if [ -f ${BASE_DIR}/run/POOL_LOCK ]; then
    	echo "pool-monitor process still running! Exiting..."
	exit
else
	touch  ${BASE_DIR}/run/POOL_LOCK
fi

for ARGUMENT in "$@"; do
        if [ "$ARGUMENT" == "-bt" ]; then
                set -x
        elif [ "$ARGUMENT" == "-d" ]; then
                DEBUG=1
        elif [ "$ARGUMENT" == "-nw" ]; then
                NO_WRITE=1
	elif [[ $ARGUMENT =~ ^-p[0-9]+ ]]; then
#		MYSQL_VERBOSE=" -vvv --show-warnings " 
		L_INDEX=${ARGUMENT:2}
		POOL_LIST=("${POOL_LIST[@]:$L_INDEX:1}")
	else
		echo "Argument unknonw: ${ARGUMENT}"
		rm ${BASE_DIR}/run/POOL_LOCK 
		exit
	fi
done

SAVEIFS=$IFS

# Call appropriate pool script
for POOL_LINE in "${POOL_LIST[@]}"
do
	IFS=$',' read POOL_TYPE CRYPTO LABEL BASE_API_URL API_TOKEN WALLET_ADDR <<<${POOL_LINE}
	if (( DEBUG == 1 )); then
		echo "Pool info in conf file: $POOL_TYPE $CRYPTO $LABEL $BASE_API_URL $API_TOKEN $WALLET_ADDR"
	fi
	. ${BASE_DIR}/monitors/pool-${POOL_TYPE,,}.sh
done

IFS=$SAVEIFS

echo "$DATA_BINARY" > tmp/pool_binary_data.tmp
if (( NO_WRITE == 1 ));then
        echo "NO WRITE enabled. Skipping influxDB http write"
else
        curl -s -i -XPOST 'http://'${INFLUX_HOST}':8086/write?db='${INFLUX_DB} --data-binary @tmp/pool_binary_data.tmp
fi


rm ${BASE_DIR}/run/POOL_LOCK 

