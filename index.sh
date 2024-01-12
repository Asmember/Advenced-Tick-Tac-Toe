#!/bin/bash

saveDatadir=saveData

read querystring
eval "${querystring//&/;}"

if [[ -n $create_Game ]] then
    if [ ! -d "$saveDatadir/$name/games" ]; then
        if [ ! -d "$saveDatadir/$name" ]; then
            mkdir -p "$saveDatadir/$name";
        fi
    
        mkdir "$saveDatadir/$name/games";
    fi
    numberOfFiles=`ls -1q | wc -l`
    cp "$saveDatadir/defaultsaveData.json" "$saveDatadir/$name/games/$numberOfFiles.json"

    jq ".GameType |= \"$create_Game\"" "$saveDatadir/$name/games/$numberOfFiles.json" # Sets the GameType to requested Game Type

    echo "<script>"
    echo "  window.location.href = \"/../game.sh?Player=$name&SaveState=$numberOfFiles\""
    echo "</script>"

else
    while IFS= read -r line
    do
        if [[ "$line" == *"%SetUrl%"* ]]; then
            echo "<script>"
            echo "  var url = \"$SCRIPT_NAME\"";
            echo "</script>"
        else
            echo "$line"
        fi
    done < "index.html"
fi