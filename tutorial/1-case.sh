#! /bin/bash
echo echo

echo "What is your favourite language? "
echo "Python"
echo "Php"
echo "C#"
echo "C++"
echo "C"
read lang

echo -n "You picked "

case $lang in
    "Python")
    echo -n "Python"
    ;;
    "Php")
    echo -n "Php"
    ;;
    "C#")
    echo -n "C#"
    ;;
    "C++")
    echo -n "C++"
    ;;
    "C")
    echo -n "C"
    ;;
    *)
    echo -n "an invalid answer "
esac