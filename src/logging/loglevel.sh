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
dateForFileName=`date +%Y%m%d`
appName=${0%.*}
scriptLogDir="/var/log/yesirelincoln/${appName}/"
scriptLogName="${scriptLogDir}${appName}-${dateForFileName}.log"
# No log file, create it.
if ! [[ -f ${scriptLogName} ]]
then
    # No log directory, create it first.
    if ! [[ -d ${scriptLogDir} ]]
    then
        echo -e "INFO : No log directory located, creating the directory (${scriptLogDir})"
        mkdir -p ${scriptLogDir}
    fi
    echo -e "INFO : No log file located, creating new log file (${scriptLogName})"
    echo "${dateTime} : PID $$ :INFO : No log file located, creating new log file (${scriptLogName})" >> "${scriptLogName}"
    echo -e "${dateTime} : PID $$ : INFO : New log file (${scriptLogName}) created." >> "${scriptLogName}"
    if ! [[ "$?" -eq 0 ]]
    then
        echo "${dateTime} - ERROR : UNABLE TO OPEN LOG FILE - EXITING SCRIPT."
        exit 1
    fi
fi

# Logging Level configuration works as follows:
# DEBUG - Provides all logging output
# INFO  - Provides all but debug messages
# WARN  - Provides all but debug and info
# ERROR - Provides all but debug, info and warn
#
# SEVERE and CRITICAL are also supported levels as extremes of ERROR
#
scriptLoggingLevel="DEBUG"
#################################################################################
#          ##      END OF GLOBAL VARIABLE CONFIGURATION      ##
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
    dateTime=$(date --rfc-3339=seconds)

    #if [[ -z "${1}" || -z "${2}" ]]
    if [[ -z "${2}" ]]
    then
        echo "${dateTime} - ERROR : LOGGING REQUIRES A DESTINATION FILE, A MESSAGE AND A PRIORITY, IN THAT ORDER."
        echo "${dateTime} - ERROR : INPUTS WERE: ${1} and ${2}."
        exit 1
    fi

    local logMessage="${1}"
    local logMessagePriority="${2}"

    declare -A logPriorities=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [SEVERE]=4 [CRITICAL]=5)
    [[ ${logPriorities[$logMessagePriority]} ]] || return 1
    (( ${logPriorities[$logMessagePriority]} < ${logPriorities[$scriptLoggingLevel]} )) && return 2

    # Write log details to file
    echo -e "${logMessagePriority} : ${logMessage}"
    echo -e "${dateTime} : PID $$ : ${logMessagePriority} : ${logMessage}" >> "${scriptLogName}"
}
