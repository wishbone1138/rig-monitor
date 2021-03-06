
BEGIN {
	FS = "(: )|(, )"
	ORS = "\n"
	NUM_GPUS=0
	TRACE=0
}

# IGNORE LINES WITH SHARE FOUND MESSAGE
/SHARE FOUND/ {next}
/Share accepted/ {next}
# IGNORE LINES WITH INCORRECT SHARES WARNING
/ got incorrect share/ {next}

# READ GPU INFO E.G.
# GPU #0: Ellesmere, 8192 MB available, 36 compute units
# GPU #0: GeForce GTX 1060 6GB, 6144 MB available, 10 compute units, capability: 6.1
/^GPU #/ { 
	#gpu[NUM_GPUS,"MODEL"]=$2
	#gpu[NUM_GPUS,"MEMORY"]=$3
	#sub(/ MB available/,"",gpu[NUM_GPUS,"MEMORY"])	
	#gpu[NUM_GPUS,"PROC"]=$4
	#sub(/ compute units/,"",gpu[NUM_GPUS,"PROC"])
	gpu[NUM_GPUS,"SPECS"]=$2 "," $3 "," $4
	gsub(/ /,"\ ",gpu[NUM_GPUS,"SPECS"])
	gsub(/,/,"\,",gpu[NUM_GPUS,"SPECS"])
	NUM_GPUS++
}

#READ ETH TOTAL HASHRATE and SHARE INFO  E.G.
#ETH - Total Speed: 160.966 Mh/s, Total Shares: 13015(2219+2204+2130+2167+2186+2226), Rejected: 0, Time: 100:02
/^ETH - Total Speed: / { 
	#print $0
	#print $2,$4,$6,
	hr=$2
	sub(/ .*/,"",hr)

	valid_shares=$4
	sub(/\([0-9+]+\)/,"",valid_shares)

	_gpu_shares=$4
	gsub(/^[0-9]+\(|\)/,"",_gpu_shares)
	split(_gpu_shares,gpu_shares,"+")
	for ( i = 0; i < NUM_GPUS; i++ ) {
		gpu[i,"VALID_SHARES"]=gpu_shares[i+1]
	}

	invalid_shares+=$6
	mining_time=$8
}	

#READ DCR/SC/LBC/PASC TOTAL HASHRATE and SHARE INFO  E.G.
#  SC - Total Speed: 43.678 Mh/s, Total Shares: 13015(2219+2204+2130+2167+2186+2226), Rejected: 0
/^  (DCR|SC|LBC|PASC) - Total Speed: / { 
	#print $0
	#print $2,$4,$6
	hr_dcoin=$2
	sub(/ .*/,"",hr_dcoin)

	valid_shares_dcoin+=$4
	sub(/\([0-9+]+\)/,"",valid_shares_dcoin)

	_gpu_shares_dcoin=$4
	gsub(/^[0-9]+\(|\)/,"",_gpu_shares_dcoin)
	split(_gpu_shares_dcoin,gpu_shares_dcoin,"+")
	for ( i = 0; i < NUM_GPUS; i++ ) {
		gpu[i,"VALID_SHARES_DCOIN"]=gpu_shares_dcoin[i+1]
	}

	invalid_shares_dcoin+=$6
}	

#READ ETH GPU HASHRATE E.G.
#ETH: GPU0 27.688 Mh/s, GPU1 27.789 Mh/s, GPU2 26.442 Mh/s, GPU3 27.245 Mh/s, GPU4 27.072 Mh/s, GPU5 27.053 Mh/s
/^ETH:/ {
        #print $0
	_index=0
	while ( _index < NUM_GPUS ) {
		gpu_field=_index + 2
		gpu_hr=$gpu_field
	        gsub(/^GPU[0-9]+ | .*/,"",gpu_hr)
		gpu[_index,"HR"]=gpu_hr
		_index++;
	}
}

#READ DCR/SC/LBC/PASC GPU HASHRATE E.G.
#  SC: GPU0 43.678 Mh/s 
/^  (DCR|SC|LBC|PASC):/ {
        #print $0
	_index=0
	while ( _index < NUM_GPUS ) {
		gpu_field=_index + 2
		gpu_hr=$gpu_field
	        gsub(/^GPU[0-9]+ | .*/,"",gpu_hr)
		gpu[_index,"HR_DCOIN"]=gpu_hr
		_index++;
	}
}

# READ INCORRECT SHARES E.G.
# Incorrect ETH shares: GPU1 23, GPU2 34
/^Incorrect ETH shares:/ { 
	#print $0
	gpu_field=2
	while ( gpu_field <= NF ) {
		gpu_index = $gpu_field
		gpu_inc_shares=$gpu_field
		gsub(/GPU| [0-9]+/,"",gpu_index)
		sub(/GPU[0-9 ]+ /,"",gpu_inc_shares)
		gpu[gpu_index,"INVALID_SHARES"] = gpu_inc_shares
		invalid_shares+=gpu_inc_shares
		gpu_field++
	}
}

# READ INCORRECT SHARES E.G.
# Incorrect DCR/SC/LBC/PASC  shares: GPU1 23, GPU2 34
/^Incorrect (DCR|SC|LBC|PASC) shares:/ { 
	#print $0
	gpu_field=2
	while ( gpu_field <= NF ) {
		gpu_index = substr($gpu_field,4,1)
		gpu_inc_shares=$gpu_field
		sub(/GPU[0-9 ]+/,"",gpu_inc_shares)
		gpu[gpu_index,"INVALID_SHARES_DCOIN"] = gpu_inc_shares
		invalid_shares_dcoin+=gpu_inc_shares
		gpu_field++
	}
}

# READ ! MIN AVERAGE HASRATE E.G.
#  1 minute average ETH total speed: 163.095 Mh/s
/^ 1 minute average / { 
	#print $0
	avg_hr_1m = $2 
	sub(/ .*/,"",avg_hr_1m)
}


# READ EPOCH AND DAG
# Current ETH share target: 0x00000000ffb34c02 (diff: 4300MH), epoch 27(1.21GB)
# Current ETH share target: 0x0000000112e0be82 (diff: 4000MH), epoch 141(2.10GB) Current SC share target: 0x0000000007547ff5 (diff: 150GH) 
/^Current ETH share target/ { 
	#print $4
        dag=$4
        dag_size=$4
        gsub(/^epoch |\([0-9A-Z\.]+\)/,"",dag)
        gsub(/^epoch [0-9]+\(|\)/,"",dag_size)
	#print dag
	#print dag_size
	}

# READ FAN SPEED and TEMP FROM GPUS E.G. 
#GPU0 t=68C fan=79%, GPU1 t=68C fan=61%, GPU2 t=68C fan=65%, GPU3 t=67C fan=66%, GPU4 t=68C fan=38%, GPU5 t=66C fan=38%
/^GPU0 t/ {
	#print $0
        gpu_field = 1
        while ( gpu_field <= NF ) {
		_index=$gpu_field
		temp=$gpu_field
		fan=$gpu_field
                gsub(/^GPU| t=.*/,"",_index)
                gsub(/^GPU[0-9]+ t=|C fan.*/,"",temp)
                gsub(/^GPU[0-9]+ t=[0-9]+C fan=|%/,"",fan)
                gpu[_index,"TEMP"] = temp
                gpu[_index,"FAN"] = fan
                gpu_field++
		pring temp "," fan
        }
}

END {
        print "miner_system,rig_id=" rig_id ",miner=claymore,coin=" coin ",dcoin=" dcoin " " "installed_gpus=" installed_gpus ",active_gpus=" NUM_GPUS ",target_hr="target_hr ",hr=" hr",avg_hr_1m=" avg_hr_1m ",valid_shares=" valid_shares ",invalid_shares=" invalid_shares ",target_hr_dcoin=" target_hr_dcoin ",hr_dcoin=" hr_dcoin ",avg_hr_1m_dcoin=" avg_hr_1m_dcoin ",valid_shares_dcoin=" valid_shares_dcoin ",invalid_shares_dcoin=" invalid_shares_dcoin ",mining_time=\"" mining_time "\""

        for ( gpu_id = 0; gpu_id < NUM_GPUS; gpu_id++ ) {
        	print "miner_gpu,rig_id=" rig_id ",miner=claymore,gpu_id=" gpu_id ",gpu_specs=" gpu[gpu_id,"SPECS"] " " "gpu_hr=" gpu[gpu_id,"HR"] ",gpu_valid_shares=" gpu[gpu_id,"VALID_SHARES"] ",gpu_invalid_shares=" gpu[gpu_id,"INVALID_SHARES"] ",gpu_hr_dcoin=" gpu[gpu_id,"HR_DCOIN"] ",gpu_valid_shares_dcoin=" gpu[gpu_id,"SHARES_DCOIN"] ",gpu_invalid_shares_dcoin="  gpu[gpu_id,"INVALID_SHARES_DCOIN"] ",gpu_max_temp=" gpu_max_temp ",gpu_temp=" gpu[gpu_id,"TEMP"] ",gpu_fan=" gpu[gpu_id,"FAN"]
        }
	
	if (TRACE != 0) { 
	print "SYSTEM NAME: " rig_id
	print "\tETH CURRENT HASHRATE: " hr
	print "\tETH AVERAGE HASHRATE ETH: " avg_hr_1m
	print "\tETH VALID SHARES: " valid_shares
	print "\tETH INVALID VALID_SHARES: " invalid_shares
	print "\tDCR/SC/LBC/PASC CURRENT HASHRATE: " hr_dcoin
	print "\tDCR/SC/LBC/PASC AVERAGE HASHRATE: " avg_hr_1m_dcoin
	print "\tDCR/SC/LBC/PASC VALID_SHARES: " valid_shares_dcoin
	print "\tDCR/SC/LBC/PASC INVALID SHARES: " invalid_shares_dcoin
	print "\tETH MINING TIME: " mining_time
	print "\tETH DAG #: " dag ", DAG SIZE: " dag_size

	for ( i = 0; i < NUM_GPUS; i++ ) {
		print "GPU#" i
		print "\tETH HASHRATE: " gpu[i,"HR"]
		print "\tSPECS: " gpu[i,"SPECS"]
		print "\tETH VALID SHARES: " gpu[i,"VALID_SHARES"]
		print "\tETH INVALID SHARES: " gpu[i,"INVALID_SHARES"]
		print "\tDCR/SC/LBC/PASC HASHRATE: " gpu[i,"HR_DCOIN"]
		print "\tDCR/SC/LBC/PASC VALID SHARES: " gpu[i,"VALID_SHARES_DCOIN"]
		print "\tDCR/SC/LBC/PASC INVALID SHARES: " gpu[i,"INVALID_SHARES_DCOIN"]
		print "\tTEMP.(C): " gpu[i,"TEMP"]
		print "\tFAN SPEED: " gpu[i,"FAN"]
	}
	}
}

