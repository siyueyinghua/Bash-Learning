#!/bin/bash

# handle the options
# the option is as follows:
# [-m move-or-not] [-l log-level] [-d log-directory] [-t log-also-2-terminal]'
while getopts ":m:l:d:t:h" option
do
    case ${option} in
        m )
            isDel=${OPTARG}
            #echo the option isDel is: ${isDel}
            ;;
        l )
            loglevel=${OPTARG}
            #echo the option loglevel is: ${loglevel}
            ;;
        d )
            logfile=${OPTARG}
            #echo The option logfile is: ${logfile}
            ;;
        t )
            log2term2=${OPTARG}
            #echo The option logfile is: ${log2term2}
            ;;
        h )
            echo usage: getopts_demo.sh [arguments]
            echo Arguments:
            echo " -m           move the former log file or not? 1-Yes, 0-No"
            echo " -l           log print verbose level, from 0 to 7"
            echo " -d           log file, by indirect or direct directory"
            echo " -t           if the log message will be print to terminal too? 1-Yes, 0-No"
            echo " -h           print this help message"
            ;;
        ? )
            echo 'right usage: getopts_demo.sh [-m move-or-not] [-l log-level] [-d log-file] [-t log-also-2-terminal] [-h]'
            ;;
        * )
            echo "The case default"
            ;;
    esac
done

echo
echo "the optind=$OPTIND"
echo "the parameter number is: $#"
echo "the all parameter is: $*"
echo "the all parameter is: $@"
shift $(($OPTIND-1))
echo "the parameter number is: $#"
echo "the all parameter is: $*"
echo "the all parameter is: $@"

echo "so! the cmd getopts will not shift or delete the patameter."
echo "it just read and handle by the inner variable OPTIND."
echo "but leave the parameter as itself."
