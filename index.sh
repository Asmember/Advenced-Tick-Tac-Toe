#!/bin/bash

saveDatadir=saveData
errorLog=error.log

read querystring
eval "${querystring//&/;}"

if [[ -n $create_Game ]]; then

    if [[ ! -n $nameInput ]]; then
        echo "No Name Input" >> errorLog
        return
    fi

    if [ ! -d "$saveDatadir/$name/games" ]; then
        if [ ! -d "$saveDatadir/$name" ]; then
            mkdir -p "$saveDatadir/$name";
        fi

        mkdir "$saveDatadir/$name/games";
    fi
    numberOfFiles=`ls -1q | wc -l`
    cp "$saveDatadir/defaultsaveData.json" "$saveDatadir/$name/games/$numberOfFiles.json"

    jq ".GameType |= \"$create_Game\"" "$saveDatadir/$name/games/$numberOfFiles.json" # Sets the GameType to requested Game Type
else
    while IFS= read -r line
    do
        if [[ "$line" == *"%SetUrl%"* ]]; then
            echo "<script>"
            echo "  var url = \"$SCRIPT_NAME\"";
            echo "</script>"
			
		elif [[ "$line" == *"%Style%"* ]]; then
			echo "<style>"
			cat "staticContent/style.css"
			echo "</style>"

        elif [[ "$line" == *"%BeginForm%"* ]]; then
            echo "<form method="post" action="$SCRIPT_NAME">"

        else
            echo "$line"
        fi
    done < "index.html" 
fi
