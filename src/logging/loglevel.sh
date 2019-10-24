#!/usr/bin/env bash
#Note, this is from the following stack question and answers
#https://stackoverflow.com/questions/48086633/simple-logging-levels-in-bash

#################################################################################
# SCRIPT LOGGING CONFIGURATION
#
# The following is used by the script to output log data. Depending upon the log
# level indicated, more or less data may be output, with a "lower" level
# providing more detail, and the "higher" level providing less verbose output.
#################################################################################
dateTime="`date +%Y-%m-%d` `date +%T%z`" # Date format at beginning of log entries to match RFC
defaultLogLevel="DEBUG" #be one of: DEBUG, INFO, WARN, ERROR, SEVERE, CRITICAL
scriptLoggingLevel=${defaultLogLevel}
log2term2="0"

appName=${0%.*}
#echo "the scripts name is: ${appName}"
defaultLogFile="./${appName}Debug.log"
logFile=${defaultLogFile}


# Logging Level configuration works as follows:
# DEBUG - Provides all logging output
# INFO  - Provides all but debug messages
# WARN  - Provides all but debug and info
# ERROR - Provides all but debug, info and warn
#
# SEVERE and CRITICAL are also supported levels as extremes of ERROR
#
#################################################################################
#          ##      END OF GLOBAL VARIABLE CONFIGURATION      ##
#################################################################################

#################################################################################
# LOGGING
#
# Calls to the logThis() function will determine if an appropriate log file
# exists. If it does, then it will use it, if not, a call to openLog() is made,
# if the log file is created successfully, then it is used.
#
# All log output is comprised of
# [+] An RFC 3339 standard date/time stamp
# [+] The declared level of the log output
# [+] The runtime process ID (PID) of the script
# [+] The log message
#################################################################################
function logInit() {
    local dateTime=$(date --rfc-3339=seconds)

    # $1 is logFile 
    if [[ ! -z $1 ]]
    then
        logFile=$1
        #echo fist parameter: $1
    fi

    # $2 is loglevel
    if [[ ! -z $2 ]]
    then
        scriptLoggingLevel=$2
        #echo the second parameter is: $2
    fi

    # $3 is log to terminal too?
    if [[ ! -z $3 ]]
    then
        log2term2=$3
        #echo the third parameter is: $3
    fi

    echo "=================================================="
    echo -e "INFO : the logFile is:${logFile}"
    scriptLogDir=${logFile%/*}
    echo -e "INFO : the directory (${scriptLogDir})"
    echo "=================================================="

    # No log file, create it.
    if ! [[ -f ${logFile} ]]
    then
        # No log directory, create it first.
        if ! [[ -d ${scriptLogDir} ]]
        then
            echo -e "INFO : No log directory located, creating the directory (${scriptLogDir})"
            mkdir -p ${scriptLogDir}
        fi
        echo -e "INFO : No log file located, creating new log file (${logFile})"
        echo "${dateTime} : PID $$ :INFO : No log file located, creating new log file (${logFile})" >> "${logFile}"
        echo -e "${dateTime} : PID $$ : INFO : New log file (${logFile}) created." >> "${logFile}"
        if ! [[ "$?" -eq 0 ]]
        then
            echo "${dateTime} - ERROR : UNABLE TO OPEN LOG FILE - EXITING SCRIPT."
            exit 1
        fi
    fi
}

#################################################################################
# LOGGING
#
# Calls to the logThis() function will determine if an appropriate log file
# exists. If it does, then it will use it, if not, a call to openLog() is made,
# if the log file is created successfully, then it is used.
#
# All log output is comprised of
# [+] An RFC 3339 standard date/time stamp
# [+] The declared level of the log output
# [+] The runtime process ID (PID) of the script
# [+] The log message
#################################################################################
function logThis() {
    local dateTime=$(date --rfc-3339=seconds)
    
    #if [[ -z "${1}" || -z "${2}" ]]
    if [[ ! -z "${1}" ]]
    then
        local logMessagePriority=${1}
        #echo "${dateTime} - ERROR : INPUTS WERE: ${1} and ${2}."
    else
        echo "${dateTime} - ERROR : LOGGING REQUIRES A PRIORITY AND A MESSAGE, IN THAT ORDER."
        echo "${dateTime} - ERROR : INPUTS WERE: ${1} and ${2}."
    fi

    # other than the $1 are all log message
    shift 1
    local logMessage="$@"

    declare -A logPriorities=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [SEVERE]=4 [CRITICAL]=5)
    [[ ${logPriorities[$logMessagePriority]} ]] || return 1
    (( ${logPriorities[$logMessagePriority]} < ${logPriorities[$scriptLoggingLevel]} )) && return 2

    # Write log details to file
    echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${logMessage}" >> "${logFile}"
    if [[ $log2term2 = "1" ]]
    then
        echo -e "${dateTime} : ${logMessagePriority} : ${logMessage}"
    fi
}
