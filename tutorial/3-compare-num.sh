#! /bin/bash

num1=10
num2=20

if [ $num1 -gt $num2 ]; then
    echo "$num1 is greater than num2"
elif [ $num1 -lt $num2 ]; then
    echo "$num1 is lesser than $num2"
elif [ $num1 -eq $num2 ]; then
    echo "$num1 is equal to $num2"
fi