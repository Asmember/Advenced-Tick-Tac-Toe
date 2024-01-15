#!/bin/bash

saveDatadir=saveData
errorLog=error.log

echo -ne "Content-type: text/html; charset=utf-8\n\n"

read querystring
eval "${querystring//&/;}"

if [[ -n "$NewLocalGame" ]]; then
    if [[ ! -n $nameInput ]]; then
        echo "No Name Input" >> errorLog
        return
    fi

    if [ ! -d "$saveDatadir/$nameInput/games" ]; then
        if [ ! -d "$saveDatadir/$nameInput" ]; then
            mkdir -p "$saveDatadir/$nameInput";
        fi

        mkdir "$saveDatadir/$nameInput/games";
    fi
    numberOfFiles=`ls "$saveDatadir/$nameInput/games" -1q | wc -l`
    saveFile="$saveDatadir/$nameInput/games/$numberOfFiles.json"

    # Copys the Default Save Game to the current Game
    cp "$saveDatadir/defaultsaveData.json" "$saveFile"

    echo `jq ".GameType |= \"Local\"" "$saveFile"` > "$saveFile" # Sets the GameType to requested Game Type
    echo `jq ".Players[0] |= \"$nameInput\"" "$saveFile"` > "$saveFile" # Sets the Player1 to Player Name
    echo `jq ".Players[1] |= \"Local\"" "$saveFile"` > "$saveFile" # Sets the Player2 to Local

    echo "<form name=\"instasubmit\" action=\"/cgi-bin/Advanced-Tick-Tac-Toe/game.sh\" method=\"post\">"
    echo    "<input type=\"hidden\" name=\"NameInput\" value=\"$nameInput\">"
    echo    "<input type=\"hidden\" name=\"numberOfFiles\" value=\"$numberOfFiles\">"
    echo "</form>"
    echo "<script>"
    echo     "document.forms[\"instasubmit\"].submit()"
    echo "</script>"
else
    # Reads The HTML Template File line by line and replaces the Placeholders with given content
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
