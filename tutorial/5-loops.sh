#! /bin/bash
echo "This is a while loop"
count_while=6
while [ $count_while -gt 0 ]
do
    echo $count_while
        let count_while=count_while-1
done

echo
echo "This is an until loop"
count_until=0
until [ $count_until -eq 6 ]
do
    echo $count_until
        let count_until=count_until+1
done

echo
echo "This is a for loop"
count_for=6
sum=0
for i in $seq 1$count_for;
do
    sum=$(($sum+$i))
done
echo "The sum is $sum"