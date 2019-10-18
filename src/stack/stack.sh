#!/bin/bash

inputfile="../../data/symbol.txt"
source "../logging/loglevelbetter.sh"
#log_file="/var/log/yesirelincoln/bashdebug.log"
log_file="./bashdebug.log"

function push
{
    stack+=( $* )
    g_LOG_Debug before push, the contents of the stack are: ${stack[@]}
    g_LOG_Debug "push" $*
    g_LOG_Debug after push, the contents of the stack are: ${stack[@]}
}

pop()
{
    let size=${#stack[@]}
    g_LOG_Debug the stack size is: $size
    g_LOG_Debug before pop, the contents of the stack are: ${stack[@]}
    g_LOG_Debug now will "pop" the stack top: ${stack[$size-1]}
    unset stack[$size-1]
    g_LOG_Debug after pop, the contents of the stack are: ${stack[@]}
}

declare -a stack

g_LOG_Init -m 1 -l 5 -d ${log_file} -t 1
if [ $? -eq 0 ]
then
    g_LOG_Debug "g_LOG_Init successfully!"
else
    g_LOG_Debug "failed to g_LOG_Init, please check!"
fi

#ensure the stack to be empty
while [[ ${#stack[@]} -gt 0 ]]
do
    pop
done

openSymbol="([<{"
closeSymbol=")]>}"
g_LOG_Debug $openSymbol
g_LOG_Debug $closeSymbol

declare -A symbolarr
symbolarr[")"]="("
symbolarr["]"]="["
symbolarr[">"]="<"
symbolarr["}"]="{"
g_LOG_Debug symbolarr: ${symbolarr[@]}
g_LOG_Debug num symbolarr: ${!symbolarr[@]}
g_LOG_Debug "the value by the key '}': ${symbolarr["}"]}"

while read -r line
do
    g_LOG_Notice the readed-in expr is: $line

    idx_begin=0
    idx_end=0
    #**# the set -f means noglob, so that bash will not do pathname expansion,
    #**# such as "* expanded to any path name, ~ expanded to home directory"
    set -f
    tmpArr=( `echo "$line" | grep -o .` )
    g_LOG_Debug "Testing if the splliting string method is effective? the result is: ${tmpArr[@]}"
    set +f

    for ch in `echo "$line" | grep -o .`
    do
        let idx_begin++
        g_LOG_Debug "loop, now to handle the ch: $ch"
        if [[ ${openSymbol} =~ "${ch}" ]] 
        then
            g_LOG_Debug find a opensymbol: $ch push it to stack
            push $ch
        elif [[ ${closeSymbol} =~ "$ch" ]]
        then
            if [[ ${#stack[@]} -eq 0 ]]
            then
                g_LOG_Error "\033[31m!!!error, $line is a wrong symbol expr\033[0m"
                break
            else
                g_LOG_Debug find a closeSymbol: $ch
                let size=${#stack[@]}
                g_LOG_Debug the key $ch is: ${symbolarr["$ch"]}
                if [[ ${symbolarr[$ch]} != ${stack[$size-1]} ]]
                then
                    g_LOG_Debug do not match, will not continue to manipulate
                    g_LOG_Error "\033[31m!!!error, $line is a wrong symbol expr\033[0m"
                    break
                fi
                #no matter wether it match or not, need to pop the former symbol
                pop
            fi
        else
            g_LOG_Debug this is not a open or close symbol: $ch, drop it, go on!
        fi
        let idx_end++
    done
    if [[ ${#stack[@]} -eq 0 ]] && [[ $idx_begin -eq $idx_end ]]
    then
        g_LOG_Notice "\033[32mright, $line is a right symbol expr!!!\033[0m"
    fi
    while [[ ${#stack[@]} -gt 0 ]]
    do
        pop
    done
done < "$inputfile"

exit $?
