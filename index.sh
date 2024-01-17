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

if [[ -n "$NewGame" ]]; then

    if [[ "$NewGame" == "Local" ]]; then
        folder="games"
    elif [[ "$NewGame" == "Online" ]]; then
        folder="online"
    else
        exit
    fi

    # erstellt einen eintrag in die Error Log Datei wenn der Name Leer ist
    if [[ ! -n $nameInput ]]; then
        echo "No Name Input"
        exit
    fi
    
    # erstellt einen eintrag in die Error Log Datei wenn der Name nicht Ascii Zeichen beinhaltet
    if [[ "$nameInput" =~ [^a-zA-Z0-9]$ ]]; then
        echo "Name may not contain non ASCII characters"
        exit
    fi

    # prüft ob der User bereits spiele Gespielt hat und erstellt ein neues verzeichnis falls nicht
    if [ ! -d "$saveDatadir/$nameInput/$folder" ]; then
        if [ ! -d "$saveDatadir/$nameInput" ]; then
            mkdir -p "$saveDatadir/$nameInput";
        fi

        # erstellt den Games ordner 
        mkdir "$saveDatadir/$nameInput/$folder";
    fi

    # zählt die anzahl an bereits existierenden spielständen
    numberOfFiles=`ls "$saveDatadir/$nameInput/$folder" -1q | wc -l`
    
    # pfaad zur speicherdatei
    saveFile="$saveDatadir/$nameInput/$folder/$numberOfFiles.json"

    # Copys the Default Save Game to the current Game
    cp "$saveDatadir/defaultsaveData.json" "$saveFile"

    # Einstellungen Bearbeiten, die spezifisch für das Lokale spiel benötigt werden
    echo `jq ".GameType |= \"$NewGame\"" "$saveFile"` > "$saveFile"
    echo `jq ".Players[0] |= \"$nameInput\"" "$saveFile"` > "$saveFile"

    if [[ "$NewGame" == "Local" ]]; then
        echo `jq ".Players[1] |= \"Local\"" "$saveFile"` > "$saveFile"
    elif [[ "$NewGame" == "Online" ]]; then
        folder="online"
    fi

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

elif [[ -n "$NewOnlineGame" ]]; then

# erstellt einen eintrag in die Error Log Datei wenn der Name Leer ist
    if [[ ! -n $nameInput ]]; then
        echo "No Name Input"
        exit
    fi
    
    # erstellt einen eintrag in die Error Log Datei wenn der Name nicht Ascii Zeichen beinhaltet
    if [[ "$nameInput" =~ [^a-zA-Z0-9]$ ]]; then
        echo "Name may not contain non ASCII characters"
        exit
    fi

    # prüft ob der User bereits spiele Gespielt hat und erstellt ein neues verzeichnis falls nicht
    if [ ! -d "$saveDatadir/$nameInput/online" ]; then
        if [ ! -d "$saveDatadir/$nameInput" ]; then
            mkdir -p "$saveDatadir/$nameInput";
        fi

        # erstellt den Games ordner 
        mkdir "$saveDatadir/$nameInput/online";
    fi

    # zählt die anzahl an bereits existierenden spielständen
    numberOfFiles=`ls "$saveDatadir/$nameInput/games" -1q | wc -l`
    
    # pfaad zur speicherdatei
    saveFile="$saveDatadir/$nameInput/online/$numberOfFiles.json"

    # Copys the Default Save Game to the current Game
    cp "$saveDatadir/defaultsaveData.json" "$saveFile"

    # Einstellungen Bearbeiten, die spezifisch für das Lokale spiel benötigt werden
    echo `jq ".GameType |= \"Online\"" "$saveFile"` > "$saveFile"
    echo `jq ".Players[0] |= \"$nameInput\"" "$saveFile"` > "$saveFile"

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

# Läd das asugewählte spiel und leitet direkt weiter
elif [[ -n "$LoadLocalSavedGames" ]]; then
    cat << EOF
    <form name="instasubmit" action="/cgi-bin/Advanced-Tick-Tac-Toe/game.sh" method="post">
        <input type="hidden" name="NameInput" value="$LoadLocalSavedGames">
        <input type="hidden" name="numberOfFiles" value="$numberOfFiles">
    </form>
EOF

elif [[ -n "$SavedGames" ]]; then

    if [[ "$Type" == "LocalSavedGames" ]]; then
        type="games"
        emptyText="Keine Spiele unter diesem Namen gespeichert, erstelle ein Neues um zu Spielen"
    elif [[ "$Type" == "OnlineSavedGames" ]]; then
        type="online"
        emptyText="Keine Spiele unter diesem Namen gespeichert, erstelle ein Neues oder Trete einem anderen Online Spiel bei um zu Spielen"
    else
        exit
    fi

    SavedGamesDir="$saveDatadir/$SavedGames/$type"

    if [[ -d "$saveDatadir/$SavedGames" ]] &&  [[ -d "$SavedGamesDir" ]] && [[ `ls "$SavedGamesDir" -1q | wc -l` != 0 ]]; then
        for SavedGame in `ls "$SavedGamesDir"`; do
            playername1=`jq -r ".Players[0]" "$SavedGamesDir/$SavedGame"`
            playername2=`jq -r ".Players[1]" "$SavedGamesDir/$SavedGame"`
            Winner=`jq -r ".Winner" "$SavedGamesDir/$SavedGame"`

            SavedGameNumberOnly=`tr -d '.json' <<< "$SavedGame"`

            echo "<div onclick=\"startGame('$SavedGames', $SavedGameNumberOnly)\">"
            echo "$playername1 VS $playername2"
            if [[ $Winner != "" ]]; then
                echo "- Gewonnen: $Winner"
            fi
            echo "</div>"
        done
    else
        echo "$emptyText"
    fi

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