#! /bin/bash
echo echo

select letter in A B C D E
do 
    echo "You picked: $letter"
    echo "Selcted number: $REPLY"
break
done