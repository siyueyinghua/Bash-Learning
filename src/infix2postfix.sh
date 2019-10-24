#!/bin/bash
source ./logging/loglevel.sh
#for example:
#logThis "This will log" "WARN"
#logThis "DEBUG" "This will not log"
#logThis "This will not log" "OUCH"

inputfile="../data/infixExpr.txt"

declare -a stack
function push
{
    logThis "DEBUG" "Before push, stack size: ${#stack[@]}; stack content: ${stack[@]}"
    logThis "DEBUG" "Push $* to the stack"
    stack+=( "$*" )
    logThis "DEBUG" "After push, stack size: ${#stack[@]} stack content: ${stack[@]}"
}
pop()
{
    local size=${#stack[@]}
    logThis "DEBUG" "Before pop, stack size: ${size}; stack content: ${stack[@]}"
    logThis "DEBUG" "Pop the stack top: ${stack[$size-1]}"
    unset stack[$size-1]
    logThis "DEBUG" "After pop, stack size: ${#stack[@]}; stack content: ${stack[@]}"
}

#=======================================================================
# logInit: 
# logInit logFile loglevel log2term2
# the loglevel can be one of: DEBUG, INFO, WARN, ERROR, SEVERE, CRITICAL
#=======================================================================
#logInit "./infix2postfix_debug.log" DEBUG 0
#logInit "./infix2postfix_debug.log" DEBUG 1
logInit "./infix2postfix_debug.log" INFO 1

#ensure the stack to be empty
while [[ ${#stack[@]} -gt 0 ]]
do
    pop
done

operator="+-*/"
logThis  DEBUG operator is: $operator
declare -A priority=(["("]=-1 ["+"]=0 ["-"]=0 ["*"]=1 ["/"]=1)
#also can be initialized one by one
#priority["("]=-1
#priority["+"]=0
#priority["-"]=0
#priority["*"]=1
#priority["/"]=1
logThis "DEBUG" "priority index: ${!priority[@]}"
logThis "DEBUG" "priority content: ${priority[@]}"
logThis "DEBUG" "priority (: ${priority["("]}"
logThis "DEBUG" "priority +: ${priority["+"]}"
logThis "DEBUG" "priority -: ${priority["-"]}"
logThis "DEBUG" "priority *: ${priority["*"]}"
logThis "DEBUG" "priority /: ${priority["/"]}"


while read -r line
do
    #the set -f means noglob, so that bash will not do pathname expansion,
    #such as "* expanded to any path name, ~ expanded to home directory"
    #logThis "INFO" "the expr is: ${line}"
    #set -f
    #logThis "DEBUG" "the expr is: ${line}"
    #set +f

    declare -a result
    logThis "DEBUG" "now, the optionis: $-"
    set -f
    logThis "DEBUG" "now, the optionis: $-"
    exprArr=( ${line} )
    set +f
    logThis "DEBUG" "now, the optionis: $-"
    logThis "INFO" "the infix expr is: ${exprArr[*]}"
    logThis "DEBUG" "string to array, index: ${!exprArr[@]}"
    logThis "DEBUG" "string to array, content: ${#exprArr[@]}"
    logThis "DEBUG" "string to array, array[0]: ${exprArr[0]}"

    for ele in "${exprArr[@]}"
    do
        logThis "DEBUG" "one by one: $ele"
        if [[ "$ele" =~ [a-z]+ ]]
        then
            logThis DEBUG "find a operand(entire matched): ${BASH_REMATCH[0]}"
            result+=${BASH_REMATCH[0]}
            logThis "DEBUG" "result now: ${result[@]}"
            logThis "DEBUG" "the pattern matched num: ${#BASH_REMATCH[*]}"
            logThis "DEBUG" "the first sub-pattern matched: ${BASH_REMATCH[1]}"
        elif [[ "$operator" =~ "$ele" ]]
        then
            logThis "DEBUG" "find a operator:${BASH_REMATCH[0]}"
            logThis "DEBUG" "its priority is: ${priority["$ele"]}"
            size=${#stack[@]}
            while [[ $size -gt 0 ]] && [[ ${priority["${stack[$size-1]}"]} -ge ${priority["$ele"]} ]]
            do
                logThis "DEBUG" "stack top priority: ${priority["${stack[$size-1]}"]} "
                result+=${stack[$size-1]}
                pop
                size=${#stack[@]}
            done
            push "$ele"
        elif [[ "$ele" =~ ")" ]]
        then
            logThis "DEBUG" "find the close parenthis symbol )"
            size=${#stack[@]}
            logThis "DEBUG" "stack size: $size"
            while [[ $size -gt 0 ]] && [[ "${stack[$size-1]}" != "(" ]]
            do
                logThis "DEBUG" "top ${stack[$size-1]}"
                result+=${stack[$size-1]}
                logThis "DEBUG" "result now: ${result[@]}"
                pop
                size=${#stack[@]}
            done
            pop #pop the "(" and drop
        else #is the "(" symbol
            logThis "DEBUG" "find a symbol ("
            push "$ele"
        fi
    done
    size=${#stack[@]}
    while [[ $size -gt 0 ]]
    do
        result+=${stack[$size-1]}
        logThis "DEBUG" "result now: ${result[@]}"
        pop
        size=${#stack[@]}
    done
    logThis "INFO" "final result postfix: ${result[@]}"
    logThis "INFO" "-------------------------------------->"
    unset result

done < "$inputfile"

exit 0
