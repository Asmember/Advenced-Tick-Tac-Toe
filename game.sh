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
onlineGamesFile="$saveDatadir/onlineGames.json"

# Content Type Setzen
echo -ne "Content-type: text/html; charset=utf-8\n\n"

# eingabe in das script
read querystring

if [[ "$querystring" != *"="* ]]; then
    # Bash kann nicht gescheid mit json umgehen, deshalb muss ich manuell die variablen aus json herauspopeln
    # dazu verwende ich eines der am wenigst performanten packages auf diesem planeten, jq, ich liebe es
    NameInput=`echo "$querystring" | jq -r ".NameInput"`
    numberOfFiles=`echo "$querystring" | jq -r ".numberOfFiles"`
    GameType=`echo "$querystring" | jq -r ".GameType"`

    gameSaveFile="$saveDatadir/$NameInput/$GameType/$numberOfFiles.json"

    # liest den Spielstand
    if [[ `echo "$querystring" | jq -r ".Type"` == "GameData" ]]; then
        cat "$gameSaveFile"

    # Persistiert den Spielstand
    elif [[ `echo "$querystring" | jq -r ".Type"` == "Save" ]]; then
        echo `echo "$querystring" | jq -r ".data"` > "$gameSaveFile"

    # wartet bis ein weiterer Spieler dem Spiel Beitritt
    elif [[ `echo "$querystring" | jq -r ".Type"` == "WaitForJoin" ]]; then
        [[ `inotifywait -t 700 -q -e modify $gameSaveFile` != *"MODIFY"* ]] && exit # wartet bis sich die Datei verändert hat, falls ein timeout passiert wird das script beendet
        [[ `echo "$querystring" | jq -r ".Players[1]"` == "" ]] && echo "retry"

        cat "$gameSaveFile"
    
    # wartet bis sich die Datei Updated sodass das Spiel diese laden kann
    elif [[ `echo "$querystring" | jq -r ".Type"` == "WaitForOtherPlayersTurn" ]]; then
        [[ `inotifywait -t 700 -q -e modify $gameSaveFile` != *"MODIFY"* ]] && exit # wartet bis sich die Datei verändert hat, falls ein timeout passiert wird das script beendet

        cat "$gameSaveFile"

    # Kopiert den Aktuellen Zug des einen Spielers zum anderen Spieler    
    elif [[ `echo "$querystring" | jq -r ".Type"` == "CopyPlayersTurn" ]]; then
        onlineCode=`jq -r ".OnlineCode" $gameSaveFile`

        # name und file des anderen Spielers holen
        otherPlayerName=`jq -r "del(.$onlineCode | .voll, .$NameInput) | .$onlineCode | keys[]" $onlineGamesFile`
        otherPlayerSaveFileNumber=`jq -r ".$onlineCode | .$otherPlayerName" $onlineGamesFile`
        otherPlayerSaveFile="$saveDatadir/$otherPlayerName/online/$otherPlayerSaveFileNumber.json"
        
        cp $gameSaveFile $otherPlayerSaveFile
        
    fi
else
    eval "${querystring//&/;}"

    # Liest das HTML Template und füllt die platzhalter mit inhalt
    while IFS= read -r line
    do

        # importiert die css datei in die Website, weil ich das installieren so einfach wie möglich gestalten möchte 
        # und usern nicht zutraue das sie es hinbekommen css dateien in /var/www/html abzulegen
        if [[ "$line" == *"%Style%"* ]]; then
            echo "<style>"
            cat "$cssFile"
            echo "</style>"
        
        # Setzt benötigte Javascript Varriablen
        # Geplant ist dies durch eine Ajax Anfrage zu ersetzen
        elif [[ "$line" == *"%GameData%"* ]]; then
            cat << EOF
            var NameInput = "$NameInput";
            var numberOfFiles = "$numberOfFiles";
            var GameType = "$GameType";
EOF

        # Gibt alles was nicht platzhalter sind aus
        else
            echo "$line"
        fi
    done < "$gameHtmlTemplate"
fi