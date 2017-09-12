# USED BY update-rig-info.sh

BEGIN {
	FS = "[ ,:()]"
	GPU_INDEX=0
}

# IGNORE LINES WITH SHARE FOUND
/SHARE FOUND/ {next}

# READ GPU INFO E.G.
# GPU #0: Ellesmere, 8192 MB available, 36 compute units
/^GPU #/ { 
	gpu[GPU_INDEX,"MODEL"]=$4
	gpu[GPU_INDEX,"MEMORY"]=$6
	gpu[GPU_INDEX,"PROC"]=$10
	GPU_INDEX++
}

END {
		for ( gpu_id = 0; gpu_id < GPU_INDEX; gpu_id++ ) {
			print "GPU," rig_name "/" gpu_id "," gpu[gpu_id,"MODEL"] "," gpu[gpu_id,"MEMORY"] "," gpu[gpu_id,"PROC"]
		}

#	print "SYSTEM NAME: " rig_name
#	for ( i = 0; i < GPU_INDEX; i++ ) {
#		print "GPU#" i
#		print "\tMODEL: " gpu[i,"MODEL"]
#		print "\tMEMORY: " gpu[i,"MEMORY"]
#		print "\tPROCESSOR: " gpu[i,"PROC"]
#	}
}

