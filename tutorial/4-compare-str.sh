#! /bin/bash

str1=hello
str2=world

if [ $str1 -== $str2 ]; then
    echo "$str1 is the same as $str2"
else
    echo "$str1 is not the same as $str2"
fi
