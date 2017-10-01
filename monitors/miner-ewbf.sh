#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CREATED FOR EWBF VERSION 0.3.4b
# Port assumed to be 42000

# epoch TIME
TIME=`date +%s`

echo "collecting data from $RIG_NAME..."

#INFLUXDB_IP='localhost'

# load and capture claymore's http status page
EWBF_READOUT=`curl -s -m 5 "http://${RIG_IP}:42000/getstat"`

if (( DEBUG == 1 )); then
	echo "$TIME $CLAYMORE_READOUT"
fi


# parse miner output, prepare data for influxdb ingest and filter out null tags, fields
if [ "$EWBF_READOUT" == "" ]; then
	echo "CURL FAILED"

else
	echo "CURL SUCCESS"

	DATA_POINTS_GPU_CSV=`jq -r '.result | .[] | [.gpuid,.speed_sps,.accepted_shares,.rejected_shares,.temperature,.gpu_power_usage,.gpu_status,.name,.start_time] | @csv'\
				<<< "$EWBF_READOUT"`
	RIG_START=`jq -r '.start_time ' <<< "$EWBF_READOUT"`

	#quickfix for spaces and quotes in TAG
	#FIXME check for commas inside of quoted strings
	DATA_POINTS_GPU_CSV=`sed -e 's/ /_/g' -e 's/"//g' <<< "$DATA_POINTS_GPU_CSV"`


        DATA_POINTS_GPU=`awk -v RIGNAME=${RIGNAME} -v coin=${COIN_LABEL} -F"," \
		        '{print "miner_gpu_ewbf,rig_id="RIGNAME",gpu_id="$1",gpu_specs="$8",coin=ZEC "\
		        "gpu_hr="$2",gpu_shares="$3"i,gpu_rej_shares="$4"i,gpu_temp="$5"i,gpu_power="$6i",gpu_status="$7"i"}' \
			<<< "$DATA_POINTS_GPU_CSV"`

	# Math to create system stats, ewbf does not report it
	RIG_HR=`awk -F"," '{x+=$2}END{print x}' <<< "$DATA_POINTS_GPU_CSV"`	
	RIG_GPU_HEALTH=`awk -F"," '$7=="2" {c++}END{print c}' <<< "$DATA_POINTS_GPU_CSV"`
	RIG_SHARES=`awk -F"," '{x+=$3}END{print x}' <<< "$DATA_POINTS_GPU_CSV"`
	RIG_REJ=`awk -F"," '{x+=$4}END{print x}' <<< "$DATA_POINTS_GPU_CSV"`
	RIG_POWER=`awk -F"," '{x+=$6}END{print x}' <<< "$DATA_POINTS_GPU_CSV"`
	RIG_UPTIME=`awk -F"," -v TIME=${TIME} '{printf "%i",TIME-$1}' <<< "$RIG_START"`
	DATA_POINTS_RIG="miner_system_ewbf,rig_id=${RIGNAME},coin=${COIN_LABEL} installed_gpus=${INSTALLED_GPUS}i,active_gpus=${RIG_GPU_HEALTH}i,target_hr=${TARGET_HR_ETH},total_hr=${RIG_HR},total_shares=${RIG_SHARES}i,rej_shares=${RIG_REJ}i,max_power=${MAX_POWER},power_usage=${RIG_POWER},mining_time=${RIG_UPTIME}i"

	DATA_POINTS=${DATA_POINTS_RIG}$'\n'${DATA_POINTS_GPU}

	DATA_BINARY=`echo "${DATA_POINTS}" |  sed -e 's/[a-z0-9_]\+=,//g' -e 's/,[a-z0-9_]\+= $//g'`

	if (( DEBUG == 1 )); then
	     echo "$DATA_BINARY"
	fi

	#write out to influxdb
	curl -s -i -m 5 -XPOST 'http://localhost:8086/write?db=rigdata' --data-binary "${DATA_BINARY}"
fi


IFS=$SAVEIFS
