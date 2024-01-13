#!/bin/bash

echo -ne "Content-type: text/html; charset=utf-8\n\n"

saveDatadir=saveData
name=Testing
numberOfFiles=0

gameSaveFile="$saveDatadir/$name/games/$numberOfFiles.json"

# reads Game html Template and then replaces the placeholder with the game grid
while IFS= read -r line
do
    if [[ "$line" == *"%GameField%"* ]]; then
        echo "<table class="game">"
        id=0

        for i in $(seq 0 2);
        do
            echo "<tr>"
            for ii in $(seq 0 2);
            do
                echo "<th><table id=\"$i|$ii\" class=\".smallField\">"
                for iii in $(seq 0 2);
                do
                    echo "<tr>"
                    for iiii in $(seq 0 2);
                    do
                        echo "<th id=\"$id\" onclick=\"clickHandler([$i,$ii],[$iii,$iiii],$id)\">$(jq -r ".GameField[$i][$ii][$iii][$iiii]" $gameSaveFile)</th>"
                        #                                           Big Field, Small Field
                        id=$(($id+1))
                    done
                    echo "</tr>"
                done
                echo "</table></th>"
            done
            echo "</tr>"
        done
        echo "</table>"

	elif [[ "$line" == *"%Style%"* ]]; then
		echo "<style>"
		cat "staticContent/style.css"
		echo "</style>"
    elif [[ "$line" == *"%GameData%"* ]]; then
        echo "<script>"
        echo "   var gameType = \"$(jq -r ".GameType" $gameSaveFile)\";"
        echo "   var currentPlayer = \"$(jq -r ".CurrentPlayer" $gameSaveFile)\";"
        echo "   var lastMove = $(jq -crj .LastMove $gameSaveFile);"
        echo "   var playerFigures = $(jq -crj .PlayerFigurs $gameSaveFile);"
        echo "   var spotLight =\"$(jq -r ".BackGroundSpotlightColor" $gameSaveFile)\";"
        echo "   document.getElementById(lastMove[0] + \"|\" + lastMove[1]).style = \"background-color: \" + spotLight + \";\"";
        echo "</script>"

    elif [[ "$line" == *"%Title%"* ]]; then
        echo "<title>$(jq -r ".GameType" $gameSaveFile) Game : $(jq -r ".Players[0]" $gameSaveFile) - $(jq -r ".Players[1]" $gameSaveFile)</title>"
    
    elif [[ "$line" == *"NameOponent"* ]]; then
        echo "<h1 id="NameRival">$(jq -r ".Players[0]" $gameSaveFile) VS $(jq -r ".Players[1]" $gameSaveFile)</h1>"

    else
       echo "$line"
    fi

done < "spiel.html"

check_three_in_a_row() {
    local matrix=("$@")

    # Check rows
    for ((i = 0; i < 3; i++)); do
        if [[ "${matrix[$i,0]}" == "${matrix[$i,1]}" && "${matrix[$i,1]}" == "${matrix[$i,2]}" && "${matrix[$i,0]}" != "" ]]; then
            return 0
        fi
    done

    # Check columns
    for ((j = 0; j < 3; j++)); do
        if [[ "${matrix[0,$j]}" == "${matrix[1,$j]}" && "${matrix[1,$j]}" == "${matrix[2,$j]}" && "${matrix[0,$j]}" != "" ]]; then
            return 0
        fi
    done

    # Check diagonals
    if [[ "${matrix[0,0]}" == "${matrix[1,1]}" && "${matrix[1,1]}" == "${matrix[2,2]}" && "${matrix[0,0]}" != "" ]]; then
        return 0
    fi

    if [[ "${matrix[0,2]}" == "${matrix[1,1]}" && "${matrix[1,1]}" == "${matrix[2,0]}" && "${matrix[0,2]}" != "" ]]; then
        return 0
    fi

    return 1
}
