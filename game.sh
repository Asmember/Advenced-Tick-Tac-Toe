#!/bin/bash

while IFS= read -r line
do
    if [[ "$line" == *"%GameField%"* ]]; then
        echo "<table class="game">"
        id=0
        bigField=0

        for i in $(seq 1 3);
        do
            echo "<tr>"
            for ii in $(seq 1 3);
            do
                echo "<th><table class=\".smallField\">"
                smallField=0
                for iii in $(seq 1 3);
                do
                    echo "<tr>"
                    for iiii in $(seq 1 3);
                    do
                        echo "<th id=\"$id\" onclick=\"clickHandler($bigField,$smallField,$id)\"></th>"
                        
                        id=$(($id+1))
                        smallField=$(($smallField+1))
                    done
                    echo "</tr>"
                done
                echo "</table></th>"
                bigField=$(($bigField+1))
            done
            echo "</tr>"
        done

        echo "</table>"
    else
        echo "$line"
    fi

done < "spiel.html"