## bash from advanced_nba-data
#! /usr/bin/env bash

Help()
{
   echo "Get full play-by-play data from sites nbastats.com and pbpstats.com"
   echo
   echo "usage    : ./run_script [option] ..."
   echo "example  : ./run_script -n 5 --season 2019 -s 2 -e 34"
   echo
   echo "options  :"
   echo "   -n             number repeat loops"
   echo "       --season   season (start year) for play-by-play information"
   echo "   -s, --start    number of first game of season for play-by-play information"
   echo "   -e, --end      number of last game of season for play-by-play information"
   echo "       --stop     maximum number of consecutive numbers skipped before stopping"
   echo "   -h             print this help"
   echo "   -v, --verbose  verbose mode"
   echo
}

while [[ -n "$1" ]]; do
	case "$1" in
		-n) nloop="$2"; shift;;
		--season) season="$2"; shift;;
		-s) start="$2"; shift;;
		--start) start="$2"; shift;;
		-e) end="$2"; shift;;
		--end) end="$2"; shift;;
		--stop) stop="$2"; shift;;
		-v) verbose="$2"; shift;;
		--verbose) verbose="$2"; shift;;
		-h) Help; exit;;
		--help) Help; exit;;
		*) echo "Error: Invalid option"; exit;;
	esac
	shift
done

for VAR in nloop season start end stop verbose
do
	if [ -v $VAR ]
		then :
		else 
			case $VAR in
				nloop) nloop=1;;
				season) season=2020;;
				start) start=1;;
				end) end=1230;;
				stop) stop=5;;
				verbose) verbose='FALSE'
			esac
	fi
done


for ((i=0; i<$nloop; i++))
do
	./get_all_data.R --season $season --start $start --end $end --stop $stop --verbose $verbose
	sleep 120
done

## bash from experiment_dff_shot
#! /usr/bin/env bash

Help()
{
   echo "Get full play-by-play data from sites nbastats.com"
   echo
   echo "usage    : ./load_nbadata.sh [option] ..."
   echo "example  : ./load_nbadata.sh -n 5 --season 2019 -s 2 -e 34"
   echo
   echo "options  :"
   echo "   -n             number repeat loops"
   echo "       --season   season (start year) for play-by-play information"
   echo "   -s, --start    number of first game of season for play-by-play information"
   echo "   -e, --end      number of last game of season for play-by-play information"
   echo "       --stop     maximum number of consecutive numbers skipped before stopping"
   echo "   -h             print this help"
   echo "   -v, --verbose  verbose mode"
   echo "   -d, --datatype type of data received:"
   echo "                     pbp - play-by-play data"
   echo "                     shot - shotdetails data"
   echo "                     players - player information"
   echo
}

while [[ -n "$1" ]]; do
	case "$1" in
		-n) nloop="$2"; shift;;
		--season) season="$2"; shift;;
		-s) start="$2"; shift;;
		--start) start="$2"; shift;;
		-e) end="$2"; shift;;
		--end) end="$2"; shift;;
		--stop) stop="$2"; shift;;
		-v) verbose="$2"; shift;;
		--verbose) verbose="$2"; shift;;
		-d) datatype="$2"; shift;;
		-h) Help; exit;;
		--help) Help; exit;;
		*) echo "Error: Invalid option"; exit;;
	esac
	shift
done

for VAR in nloop season start end stop verbose datatype
do
	if [ -v $VAR ]
	then :
	else
		case $VAR in
			nloop) nloop=1;;
			season) season=2020;;
			start) start=1;;
			end) end=1230;;
			stop) stop=5;;
			verbose) verbose='FALSE';;
			datatype) datatype='pbp'
		esac
	fi
done


for ((i=0; i<$nloop; i++))
do
	./load_nbadata.R --season $season --start $start --end $end --stop $stop --verbose $verbose -d $datatype
done
