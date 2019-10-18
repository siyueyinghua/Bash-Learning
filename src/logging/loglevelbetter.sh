#!/bin/bash

#********************************************************************
#            Copyright (C) wuyou Technologies, 2012-3
#
#  #FileName                : loglevelbetter.sh
#  #Writter                 : wuyou update by yemingguang
#  #Sub Modules             :
#  #Mudule Name             : LOG
#  #Language                : shell-Bash
#  #Environment             : Ubuntu 18.04
#  #First Release Date      : 2019-10-18
#  #Description             : This script contains the MiniOS Log
#                             interfaces and generic Utility functions.
#********************************************************************

#templogfile
#LOG_FILE="/var/log/bashdbug.log"
#export LOG_FILE

#const value of different loglevel
CON_EMERG="0"
CON_ALERT="1"
CON_CRIT="2"
CON_ERROR="3"
CON_WARN="4"
CON_NOTICE="5"
CON_INFO="6"
CON_DEBUG="7"

#set default log level
DEFAULT_LEVEL="7"
LOG_LEVEL=${DEFAULT_LEVEL}
DEFAULT_LOGFILE="./defaultBashDebug.log"
LOG_FILE=${DEFAULT_LOGFILE}
DEFAULT_LOG_2TERM2="0"
LOG_2TERM2=${DEFAULT_LOG_2TERM2}

CURRENT_TTY=`tty`
if [ $? -ne 0 ];then
    CURRENT_TTY="/dev/console"
fi
#echo $CURRENT_TTY

#####################################################################
# Function Name: g_LOG_Init
# Description  : MiniOS Init Log interface
# Parameter    : 1) move logfile? default is move, 0 = no move
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function g_LOG_Init()
{
    #local loglevel=`cat /proc/cmdline | awk -F 'log_level=' '{print $2}' | awk '{print $1}'`
    local isDel
    local loglevel
    local logfile
    local log2term2

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
                echo The option logfile is: ${log2term2}
                ;;
            h )
                echo usage: g_LOG_Init [arguments]
                echo Arguments:
                echo " -m           move the former log file or not? 1-Yes, 0-No"
                echo " -l           log print verbose level, from 0 to 7"
                echo " -d           log file, by indirect or direct directory"
                echo " -t           if the log message will be print to terminal too? 1-Yes, 0-No"
                echo " -h           print this help message"
                ;;
            ? )
                echo 'right usage: g_LOG_Init [-m move-or-not] [-l log-level] [-d log-directory] [-t log-also-2-terminal] [-h]'
                ;;
            * )
                echo "The case default"
                ;;
        esac
    done

    # set the log file
    if [ -z "${logfile}" ]
    then
        echo "Warning: input logfile is null! the logfile will be set to default: ${LOG_FILE}!" >> ${LOG_FILE}
    else
        LOG_FILE=${logfile}
        echo "Info: get the input logfile! the logfile will be set to it: ${logfile}!" >> ${LOG_FILE}
    fi

    local logdir="`dirname ${LOG_FILE}`"
    
    if [ "$isDel" = "1" ]
    then
        if [ -f "${LOG_FILE}" ]
        then
            rm -rf ${LOG_FILE}
        fi

        #set logdir
        if [ ! -d "${logdir}" ]
        then
            mkdir -p ${logdir}
        fi
        touch ${LOG_FILE}
    fi

    #set loglevel
    if [ -z "${loglevel}" ]
    then
        echo "Warning: input loglevel is null! the loglevel will be set to default: ${DEFAULT_LEVEL}!" >> ${LOG_FILE}
    elif [ ! `echo ${loglevel} | grep '^[0-7]$'` ]
    then
        echo "Warning: input loglevel is invalid! the loglevel will be set to default: ${DEFAULT_LEVEL}!" >> ${LOG_FILE}
    else
        echo "Info: input loglevel is valid! the loglevel will be set to it: ${loglevel}!" >> ${LOG_FILE}
        LOG_LEVEL=${loglevel}
    fi

    # set the log2trem
    if [ -z "${log2term2}" ]
    then
        echo "Warning: input log2term2 is null! the log2term2 will be set to default: ${LOG_2TERM2}!" >> ${LOG_FILE}
    else
        LOG_2TERM2=${log2term2}
        echo "Info: get the input log2term2! the log2term2 will be set to it: ${log2term2}!" >> ${LOG_FILE}
    fi

    echo "current log level is ${LOG_LEVEL}." >> ${LOG_FILE}
    chmod 640 ${LOG_FILE}
    return 0
}

#####################################################################
# Function Name: LOG_WriteLog
# Description  : MiniOS Log interface for installation
# Parameter    : 1) Severity of the log
#                2) Line number of log message
#                3) Log message
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function LOG_WriteLog()
{
    local progname=`basename ${BASH_SOURCE[2]}`
    local severity=$1
    local line_no=$2
    shift 2
    local logmsg=$@

    if [ ${severity} -le ${LOG_LEVEL} ]
    then
        case ${severity} in
            0)  #Emerg log
                echo -n "[ EMERG ] - " >> ${LOG_FILE}
                ;;
            1)  #Alert log
                echo -n "[ ALERT ] - " >> ${LOG_FILE}
                ;;
            2)  #crit log
                echo -n "[ CRIT ] - " >> ${LOG_FILE}
                ;;
            3)  # Error log
                echo -n "[ ERROR ] - " >> ${LOG_FILE}
                ;;
            4)  # Warning log
                echo -n "[ WARN ] - " >> ${LOG_FILE}
                ;;
            5)  #Notice log
                echo -n "[ NOTICE ] - " >> ${LOG_FILE}
                ;;
            6)  # Information log
                echo -n "[ INFO ] - " >> ${LOG_FILE}
                ;;
            7)  # Debug log
                echo -n "[ DEBUG ] - " >> ${LOG_FILE}
                ;;
            *)  # Any other logs
                echo -n "[       ] - " >> ${LOG_FILE}
                ;;
        esac
        echo "`date "+%Y-%m-%d %H:%M:%S"`" ${progname} "[line_no=${line_no}]:" \
            "${logmsg}" >> ${LOG_FILE}
    fi

    if [ ${LOG_2TERM2} = "1" ]
    then
        if [ ${severity} -le ${LOG_LEVEL} ]
        then
            case ${severity} in
                0)  #Emerg log
                    echo -n "[ EMERG ] - "
                    ;;
                1)  #Alert log
                    echo -n "[ ALERT ] - "
                    ;;
                2)  #crit log
                    echo -n "[ CRIT ] - "
                    ;;
                3)  # Error log
                    echo -n "[ ERROR ] - "
                    ;;
                4)  # Warning log
                    echo -n "[ WARN ] - "
                    ;;
                5)  #Notice log
                    echo -n "[ NOTICE ] - "
                    ;;
                6)  # Information log
                    echo -n "[ INFO ] - "
                    ;;
                7)  # Debug log
                    echo -n "[ DEBUG ] - "
                    ;;
                *)  # Any other logs
                    echo -n "[       ] - "
                    ;;
            esac
            echo -e "`date "+%Y-%m-%d %H:%M:%S"`" ${progname} "[line_no=${line_no}]:" \
                "${logmsg}"
        fi
    fi

    return 0
}

#####################################################################
# Function Name: g_LOG_Emerg
# Description  : MiniOS Emerg Log interface
# Parameter    : 1) Emerg message
# Date         : <05-18-2012>
# Author       : 
#####################################################################
function g_LOG_Emerg()
{
    LOG_WriteLog $CON_EMERG $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Alert
# Description  : MiniOS Alert Log interface
# Parameter    : 1) Alert message
# Date         : <05-18-2012>
# Author       : 
#####################################################################
function g_LOG_Alert()
{
    LOG_WriteLog $CON_ALERT $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Crit
# Description  : MiniOS Crit Log interface
# Parameter    : 1) Crit message
# Date         : <05-18-2012>
# Author       : 
#####################################################################
function g_LOG_Crit()
{
    LOG_WriteLog $CON_CRIT $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Error
# Description  : MiniOS Error Log interface
# Parameter    : 1) Error message
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function g_LOG_Error()
{
    LOG_WriteLog $CON_ERROR $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Warn
# Description  : MiniOS Warning Log interface
# Parameter    : 1) Warning message
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function g_LOG_Warn()
{
    LOG_WriteLog $CON_WARN $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Notice
# Description  : MiniOS Notice Log interface
# Parameter    : 1) Notice message
# Date         : <05-18-2012>
# Author       : 
#####################################################################
function g_LOG_Notice()
{
    LOG_WriteLog $CON_NOTICE $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Info
# Description  : MiniOS Information Log interface
# Parameter    : 1) Info  message
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function g_LOG_Info()
{
    LOG_WriteLog $CON_INFO $BASH_LINENO "$@"
	return 0
}

#####################################################################
# Function Name: g_LOG_Debug
# Description  : MiniOS Debug Log interface
# Parameter    : 1) Debug  message
# Date         : <03-04-2012>
# Author       : 
#####################################################################
function g_LOG_Debug()
{
    LOG_WriteLog $CON_DEBUG $BASH_LINENO "$@"
	return 0
}

g_LOG_Init $@
