#!/bin/bash

inputfile="../../data/symbol.txt"
declare -a stack

function push
{
    stack+=( $* )
    #echo ${#stack[@]}
    echo "push" $*
    #echo ${#stack[@]}
}

pop()
{
    let size=${#stack[@]}-1
    #echo the stack size is: $size
    #echo ${#stack[@]}
    #echo ${stack[@]}
    #echo "pop" ${stack[$size]}
    unset stack[$size]
}

#ensure the stack to be empty
while [[ ${#stack[@]} -gt 0 ]]
do
    pop
done

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

while read -r line
do
    echo the expr is: $line
    idx_begin=0
    idx_end=0
    arr=( `echo "$line" | grep -o .` )

    echo ${arr[@]}
    for ch in `echo "$line" | grep -o .`
    do
        let idx_begin++
        #echo $ch
        if [[ ${openSymbol} =~ "${ch}" ]] 
        then
            #echo find a opensymbol: $ch push it to stack
            push $ch
        elif [[ ${closeSymbol} =~ "$ch" ]]
        then
            if [[ ${#stack[@]} -eq 0 ]]
            then
                echo -e "\033[31m!!!error, is a wrong symbol expr\033[0m"
                break
            else
                #echo find a closeSymbol: $ch
                let size=${#stack[@]}-1
                #echo the stack size is: $(($size+1))
                #echo the index $ch is: ${symbolarr["$ch"]}
                if [[ ${symbolarr[$ch]} != ${stack[$size]} ]]
                then
                    echo do not match, will not continue to manipulate
                    echo -e "\033[31m!!!error, is a wrong symbol expr\033[0m"
                    break
                fi
                #no matter wether it match or not, need to pop the former symbol
                pop
            fi
        else
            echo this is not a open or close symbol: $ch
        fi
        let idx_end++
    done
    if [[ ${#stack[@]} -eq 0 ]] && [[ $idx_begin -eq $idx_end ]]
    then
        echo -e "\033[32mright, this is a right symbol expr!!!\033[0m"
    fi
    while [[ ${#stack[@]} -gt 0 ]]
    do
        pop
    done
done < "$inputfile"


echo ${stack[@]} 

exit $?
