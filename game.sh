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
    if [[ `echo "$querystring" | jq -r ".Type"` == "GameData" ]]; then
        NameInput=`echo "$querystring" | jq -r ".NameInput"`
        numberOfFiles=`echo "$querystring" | jq -r ".numberOfFiles"`

        gameSaveFile="$saveDatadir/$NameInput/games/$numberOfFiles.json"

        cat "$gameSaveFile"

    elif [[ `echo "$querystring" | jq -r ".Type"` == "Save" ]]; then
        
        echo "$querystring"
        # Bash kann nicht gescheid mit json umgehen, deshalb muss ich manuell die variablen aus json herauspopeln
        # dazu verwende ich eines der am wenigst performanten packages auf diesem planeten, jq, ich liebe es
        NameInput=`echo "$querystring" | jq -r ".NameInput"`
        numberOfFiles=`echo "$querystring" | jq -r ".numberOfFiles"`

        gameSaveFile="$saveDatadir/$NameInput/games/$numberOfFiles.json"

        echo `echo "$querystring" | jq -r ".data"` > "$gameSaveFile"
    fi
else
    eval "${querystring//&/;}"

    gameSaveFile="$saveDatadir/$NameInput/games/$numberOfFiles.json"

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
            var NameInput ="$NameInput";
            var numberOfFiles ="$numberOfFiles";
EOF

        # Gibt alles was nicht platzhalter sind aus
        else
            echo "$line"
        fi
    done < "$gameHtmlTemplate"
fi