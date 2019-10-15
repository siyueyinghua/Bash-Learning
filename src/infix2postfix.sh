#!/bin/bash
source ./logging/loglevel.sh
scriptLoggingLevel="INFO" #be one of: DEBUG, INFO, WARN, ERROR, SEVERE, CRITICAL
#for example:
#logThis "This will log" "WARN"
#logThis "This will not log" "DEBUG"
#logThis "This will not log" "OUCH"

inputfile="../data/infixExpr.txt"

declare -a stack
function push
{
    logThis "Before push, stack size: ${#stack[@]}; stack content: ${stack[@]}" "DEBUG"
    logThis "Push $* to the stack" "DEBUG"
    stack+=( "$*" )
    logThis "After push, stack size: ${#stack[@]} stack content: ${stack[@]}" "DEBUG"
}
pop()
{
    local size=${#stack[@]}
    logThis "Before pop, stack size: ${size}; stack content: ${stack[@]}" "DEBUG"
    logThis "Pop the stack top: ${stack[$size-1]}" "DEBUG"
    unset stack[$size-1]
    logThis "After pop, stack size: ${#stack[@]}; stack content: ${stack[@]}" "DEBUG"
}

#ensure the stack to be empty
while [[ ${#stack[@]} -gt 0 ]]
do
    pop
done

operator="+-*/"
logThis "operator is: $operator " "DEBUG"
declare -A priority=(["("]=-1 ["+"]=0 ["-"]=0 ["*"]=1 ["/"]=1)
#also can be initialized one by one
#priority["("]=-1
#priority["+"]=0
#priority["-"]=0
#priority["*"]=1
#priority["/"]=1
logThis "priority index: ${!priority[@]}" "DEBUG"
logThis "priority content: ${priority[@]}" "DEBUG"
logThis "priority (: ${priority["("]}" "DEBUG"
logThis "priority +: ${priority["+"]}" "DEBUG"
logThis "priority -: ${priority["-"]}" "DEBUG"
logThis "priority *: ${priority["*"]}" "DEBUG"
logThis "priority /: ${priority["/"]}" "DEBUG"


while read -r line
do
    #the set -f means noglob, so that bash will not do pathname expansion
    #logThis "the expr is: ${line}" "INFO"
    #set -f
    #logThis "the expr is: ${line}" "DEBUG"
    #set +f

    declare -a result
    logThis "$-" "DEBUG"
    set -f
    exprArr=( ${line} )
    set +f
    logThis "$-" "DEBUG"
    logThis "the infix expr is: ${exprArr[*]}" "INFO"
    #logThis "the infix expr is: ${exprArr[@]}" "INFO"
    #echo "the infix expr is: ${exprArr[@]}"
    logThis "${!exprArr[@]}" "DEBUG"
    logThis "${#exprArr[@]}" "DEBUG"
    logThis "${exprArr[0]}" "DEBUG"

    for ele in "${exprArr[@]}"
    do
        logThis "one by one: $ele" "DEBUG"
        if [[ "$ele" =~ [a-z]+ ]]
        then
            logThis "find a operand: ${BASH_REMATCH[0]}" "DEBUG"
            result+=${BASH_REMATCH[0]}
            logThis "result now: ${result[@]}" "DEBUG"
            logThis "${BASH_REMATCH[1]}" "DEBUG"
        elif [[ "$operator" =~ "$ele" ]]
        then
            logThis "match: ${BASH_REMATCH[0]}" "DEBUG"
            logThis "find a operator: $ele" "DEBUG"
            logThis "its priority is: ${priority["$ele"]}" "DEBUG"
            size=${#stack[@]}
            logThis "stack size: $size" "DEBUG"
            while [[ $size -gt 0 ]] && [[ ${priority["${stack[$size-1]}"]} -ge ${priority["$ele"]} ]]
            do
                logThis "stack top: ${stack[$size-1]}" "DEBUG"
                logThis "stack top priority: ${priority["${stack[$size-1]}"]} " "DEBUG"
                result+=${stack[$size-1]}
                pop
                size=${#stack[@]}
            done
            push "$ele"
        elif [[ "$ele" =~ ")" ]]
        then
            logThis "find the close parenthis symbol )" "DEBUG"
            logThis "${stack[@]}" "DEBUG"
            size=${#stack[@]}
            logThis "stack size: $size" "DEBUG"
            while [[ $size -gt 0 ]] && [[ "${stack[$size-1]}" != "(" ]]
            do
                logThis "top ${stack[$size-1]}" "DEBUG"
                result+=${stack[$size-1]}
                logThis "result now: ${result[@]}" "DEBUG"
                pop
                size=${#stack[@]}
            done
            pop #pop the "(" and drop
        else #is the "(" symbol
            logThis "find a symbol (" "DEBUG"
            push "$ele"
        fi
    done
    size=${#stack[@]}
    while [[ $size -gt 0 ]]
    do
        result+=${stack[$size-1]}
        logThis "result now: ${result[@]}" "DEBUG"
        pop
        size=${#stack[@]}
    done
    logThis "final result postfix: ${result[@]}" "INFO"
    logThis "-------------------------------------->" "INFO"
    unset result

done < "$inputfile"

exit 0
