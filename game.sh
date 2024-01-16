#!/bin/bash

##################################################################################
# #
# #                             Autor: Armin Scheu
# #
# #                            Erstellt: Januar 2024
# #
##################################################################################

# Einstellungen
saveDatadir=saveData
cssFile="staticContent/style.css"
gameHtmlTemplate="templates/spiel.html"
ErrorHTMLTemplate="templates/error.html"

# Content Type Setzen
echo -ne "Content-type: text/html; charset=utf-8\n\n"

# eingabe in das script
read querystring

if [[ "$querystring" != *"="* ]]; then
    # Bash kann nicht gescheid mit json umgehen, deshalb muss ich manuell die variablen aus json herauspopeln
    # dazu verwende ich eines der am wenigst performanten packages auf diesem planeten, jq, ich liebe es
    NameInput=`echo "$querystring" | jq -r ".NameInput"`
    numberOfFiles=`echo "$querystring" | jq -r ".numberOfFiles"`
    smallFieldX=`echo "$querystring" | jq ".smallField[0]"`
    smallFieldY=`echo "$querystring" | jq ".smallField[1]"`
    bigFieldX=`echo "$querystring" | jq ".bigField[0]"`
    bigFieldY=`echo "$querystring" | jq ".bigField[1]"`
    currentPlayer=`echo "$querystring" | jq ".currentPlayer"`
    nextPlayer=`echo "$querystring" | jq ".nextPlayer"`
    id=`echo "$querystring" | jq ".id"`

    gameSaveFile="$saveDatadir/$NameInput/games/$numberOfFiles.json"

    # spiel Speicherstand ändern
    echo `jq ".LastMove[0] |= $smallFieldX" "$gameSaveFile"` > "$gameSaveFile"
    echo `jq ".LastMove[1] |= $smallFieldY" "$gameSaveFile"` > "$gameSaveFile"
    echo `jq ".CurrentPlayer |= $nextPlayer" "$gameSaveFile"` > "$gameSaveFile"
    echo `jq ".GameField[$bigFieldX][$bigFieldY][$smallFieldX][$smallFieldY] |= $currentPlayer" "$gameSaveFile"` > "$gameSaveFile"
else
    eval "${querystring//&/;}"

    gameSaveFile="$saveDatadir/$NameInput/games/$numberOfFiles.json"
fi

# wenn warum auch immer die Save File nicht existiert, 
# anstatt die logs voll zu spammen bekommt man eine Error 
# Website auf der der Fehler beschrieben wird
if [[ ! -f "$gameSaveFile" ]]; then
    ThrowErrorScreen "Save File \"$gameSaveFile\" does not exist"
    return
fi

# Gespeicherte Daten aus save File auslesen
saveFileContent=`cat "$gameSaveFile"`

if [[ -n $smallField ]]; then
    echo ""
else
    # Liest das HTML Template und füllt die platzhalter mit inhalt
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
                            echo "<th id=\"$id\" onclick=\"clickHandler([$i,$ii],[$iii,$iiii],$id)\">$(echo "$saveFileContent" | jq -r ".GameField[$i][$ii][$iii][$iiii]")</th>"
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

        # importiert die css datei in die Website, weil ich das installieren so einfach wie möglich gestalten möchte 
        # und usern nicht zutraue das sie es hinbekommen css dateien in /var/www/html abzulegen
        elif [[ "$line" == *"%Style%"* ]]; then
            echo "<style>"
            cat "$cssFile"
            echo "</style>"
        
        # Setzt benötigte Javascript Varriablen
        # Geplant ist dies durch eine Ajax Anfrage zu ersetzen
        elif [[ "$line" == *"%GameData%"* ]]; then
            cat << EOF
            <script>
               var gameType = "$(echo "$saveFileContent" | jq -r ".GameType")";
               var currentPlayer = "$(echo "$saveFileContent" | jq -r ".CurrentPlayer")";
               var lastMove = $(echo "$saveFileContent" | jq -r ".LastMove");
               var playerFigures = $(echo "$saveFileContent" | jq -r ".PlayerFigurs");
               var spotLight ="$(echo "$saveFileContent" | jq -r ".BackGroundSpotlightColor")";
               var NameInput ="$NameInput";
               var numberOfFiles ="$numberOfFiles";
               
               console.log(gameType, currentPlayer, lastMove, playerFigures, spotLight, NameInput, numberOfFiles);
               if(lastMove.length != 0){
                  document.getElementById(lastMove[0] + "|" + lastMove[1]).style = "background-color: " + spotLight + ";";
               }
            </script>
EOF

        # Setzt den Titel der Game Seite
        elif [[ "$line" == *"%Title%"* ]]; then
            echo "<title>$(echo "$saveFileContent" | jq -r ".GameType") Game : $(echo "$saveFileContent" | jq -r ".Players[0]") - $(echo "$saveFileContent" | jq -r ".Players[1]")</title>"
        
        # Setzt die Überschrift der Game Seite
        elif [[ "$line" == *"NameOponent"* ]]; then
            echo "<h1 id="NameRival">$(echo "$saveFileContent" | jq -r ".Players[0]") VS $(echo "$saveFileContent" | jq -r ".Players[1]")</h1>"

        # Gibt alles was nicht platzhalter sind aus
        else
            echo "$line"
        fi
    done < "$gameHtmlTemplate"
fi

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

ThrowErrorScreen() {
    # Makes sure the function is used correctly
    if [[ ! -n "$1" ]]; then
        return
    fi

    while IFS= read -r line
    do
        if [[ "$line" == *"%ErrorMessage%"* ]]; then
            echo "<div class=\"Error\">$1</div>"
        else
            echo "$line"
        fi
    done < "$ErrorHTMLTemplate"
}
