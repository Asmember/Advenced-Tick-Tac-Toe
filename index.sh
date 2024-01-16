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
errorLog=error.log
cssFile="staticContent/style.css"
indexHTMLTemplate="templates/index.html"

# Content Type Setzen
echo -ne "Content-type: text/html; charset=utf-8\n\n"

# eingabe in das script
read querystring
eval "${querystring//&/;}"

if [[ -n "$NewLocalGame" ]]; then

    # erstellt einen eintrag in die Error Log Datei wenn der Name Leer ist
    if [[ ! -n $nameInput ]]; then
        createErrorLogEntry "No Name Input"
    fi
    
    # erstellt einen eintrag in die Error Log Datei wenn der Name nicht Ascii Zeichen beinhaltet
    if [[ "$nameInput" =~ [^a-zA-Z0-9]$ ]]; then
        createErrorLogEntry "Name may not contain non ASCII characters"
    fi

    # prüft ob der User bereits spiele Gespielt hat und erstellt ein neues verzeichnis falls nicht
    if [ ! -d "$saveDatadir/$nameInput/games" ]; then
        if [ ! -d "$saveDatadir/$nameInput" ]; then
            mkdir -p "$saveDatadir/$nameInput";
        fi

        # erstellt den Games ordner 
        mkdir "$saveDatadir/$nameInput/games";
    fi

    # zählt die anzahl an bereits existierenden spielständen
    numberOfFiles=`ls "$saveDatadir/$nameInput/games" -1q | wc -l`
    
    # pfaad zur speicherdatei
    saveFile="$saveDatadir/$nameInput/games/$numberOfFiles.json"

    # Copys the Default Save Game to the current Game
    cp "$saveDatadir/defaultsaveData.json" "$saveFile"

    # Einstellungen Bearbeiten, die spezifisch für das Lokale spiel benötigt werden
    echo `jq ".GameType |= \"Local\"" "$saveFile"` > "$saveFile"
    echo `jq ".Players[0] |= \"$nameInput\"" "$saveFile"` > "$saveFile"
    echo `jq ".Players[1] |= \"Local\"" "$saveFile"` > "$saveFile"

    # Erstellt eine Form, welche direkt abgeschickt wird
    # leitet an das Game script weiter
    # überträgt wichtige informationen and das game script
    cat << EOF
    <form name="instasubmit" action="/cgi-bin/Advanced-Tick-Tac-Toe/game.sh" method="post">
        <input type="hidden" name="NameInput" value="$nameInput">
        <input type="hidden" name="numberOfFiles" value="$numberOfFiles">
    </form>
    <script>
        document.forms["instasubmit"].submit()
    </script>
EOF
else
    # Liest das HTML Template und füllt die platzhalter mit inhalt
    while IFS= read -r line
    do
        # übergibt den Skript namen an Javascript
        if [[ "$line" == *"%SetUrl%"* ]]; then
            echo "<script>"
            echo "  var url = \"$SCRIPT_NAME\"";
            echo "</script>"
			
        # importiert die css datei in die Website, weil ich das installieren so einfach wie möglich gestalten möchte 
        # und usern nicht zutraue das sie es hinbekommen css dateien in /var/www/html abzulegen
		elif [[ "$line" == *"%Style%"* ]]; then
			echo "<style>"
			cat "$cssFile"
			echo "</style>"

        # fügt den Form header in das HTML Template ein
        elif [[ "$line" == *"%BeginForm%"* ]]; then
            echo "<form method="post" action="$SCRIPT_NAME">"
    
        # Gibt alles was nicht platzhalter sind aus
        else
            echo "$line"
        fi
    done < "$indexHTMLTemplate"
fi

# function die den angegebenen error in den Errorlog schreibt
createErrorLogEntry(){
    # Makes sure the function is used correctly
    if [[ ! -n "$1" ]]; then
        return
    fi

    echo "$(date): $1" >> "$errorLog"
}