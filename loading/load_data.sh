#! /usr/bin/env bash

Help()
{
   echo "Get play-by-play and shotdetail data from sites nbastats.com, pbpstats.com and data.nba.com"
   echo
   echo "usage    : ./run_script [option] ..."
   echo "example  : ./run_script -n 5 --season 2019 -s 2 -e 34"
   echo
   echo "options  :"
   echo "   -n             number repeat loops"
   echo "       --season   season (start year) for play-by-play information"
   echo "   -s, --start    number of first game of season for play-by-play information"
   echo "   -e, --end      number of last game of season for play-by-play information"
   echo "   -l, --league   league name: nba or wnba"
   echo "   -d, --datatype type of data received:"
   echo "                     all - play-by-play and shotdetail data"
   echo "                     pbp - Only play-by-play data"
   echo "                     shot - Only shotdetails data"
   echo "                     nbastats - Only nbastats.com (version v2) data"
   echo "                     nbastatsv3 - Only nbastats.com (version v3) data"
   echo "                     pbpstats - Only pbpstats.com data"
   echo "                     datanba - Only data.nba.com data"
   echo "                     cdnnba - Only cdn.nba.com data"
   echo "                     matchups - Only matchups data from nba.stats.com"
   echo "   -st, --seasontype type of season:"
   echo "                     rg - Regular Season"
   echo "                     po - Playoffs"
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
		-l) league="$2"; shift;;
		--league) league="$2"; shift;;
    --stop) stop="$2"; shift;;
		-d) datatype="$2"; shift;;
		--datatype) datatype="$2"; shift;;
		-st) seasontype="$2"; shift;;
    --seasontype) seasontype="$2"; shift;;
		-v) verbose="$2"; shift;;
		--verbose) verbose="$2"; shift;;
		-h) Help; exit;;
		--help) Help; exit;;
		*) echo "Error: Invalid option"; exit;;
	esac
	shift
done

for VAR in nloop season start end league stop datatype seasontype verbose
do
	if [ -v $VAR ]
		then :
		else
			case $VAR in
				nloop) nloop=1;;
				season) season=2023;;
				start) start=1;;
				end) end=1230;;
				league) league='nba';;
				stop) stop=5;;
				datatype) datatype='all';;
				seasontype) seasontype='rg';;
				verbose) verbose='FALSE'
			esac
	fi
done


for ((i=0; i<$nloop; i++))
do
	./load_data.R --season $season --start $start --end $end --league $league --stop $stop --datatype $datatype --seasontype $seasontype --verbose $verbose
	sleep 120
done
