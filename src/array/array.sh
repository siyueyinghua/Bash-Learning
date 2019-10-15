#!/bin/bash

#echo ${#stack[@]}
#echo ${!stack[@]}
#echo ${stack[@]}
#
#stack=( 'ubuntu' 'red hat' 'mac' )
#echo ${#stack[@]}
#echo ${!stack[@]}
#echo ${stack[@]}
#
#stack+=('solaris')
#echo ${#stack[@]}
#echo ${!stack[@]}
#echo ${stack[@]}
#
#unset stack[3]
#echo ${#stack[@]}
#echo ${!stack[@]}
#echo ${stack[@]}

#associative array
openSymbol="([<{"
closeSymbol=")]>}"
declare -A symbolarr
symbolarr[")"]="("
symbolarr["]"]="["
symbolarr[">"]="<"
symbolarr["}"]="{"
#echo ${symbolarr[@]}
#echo ${!symbolarr[@]}
#echo ${symbolarr["("]}
#echo open_close
#echo $openSymbol
#echo $closeSymbol

