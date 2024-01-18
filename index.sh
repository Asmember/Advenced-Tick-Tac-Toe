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
onlineGamesFile="$saveDatadir/onlineGames.json"

# Content Type Setzen
echo -ne "Content-type: text/html; charset=utf-8\n\n"

# eingabe in das script
read querystring
eval "${querystring//&/;}"

if [[ -n "$NewGame" ]]; then

    # wählt den speicherort aus, in welchem der Spielstand gespeichert wird
    # beendet das script falls eine falsche eingabe passiert ist
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

    # Allgemeine Einstellungen in die game save File schreiben
    echo `jq ".GameType |= \"$NewGame\"" "$saveFile"` > "$saveFile"
    echo `jq ".Players[0] |= \"$nameInput\"" "$saveFile"` > "$saveFile"

    if [[ "$NewGame" == "Local" ]]; then
        # Einstellungen Bearbeiten, die spezifisch für das Lokale spiel benötigt werden
        echo `jq ".Players[1] |= \"Local\"" "$saveFile"` > "$saveFile"

    elif [[ "$NewGame" == "Online" ]]; then
        code=`tr -dc A-Z </dev/urandom | head -c 8` # Generiert den invite Code

        echo `jq ".OnlineCode |= \"$code\"" "$saveFile"` > "$saveFile" # Speichert den invite Code im game save File des erstellers

        echo `cat "$onlineGamesFile" | jq ". += { $code: { \"voll\": false, $nameInput : $numberOfFiles}}"` > $onlineGamesFile # fügt den gamecode und die zu Kopierende Datei in den Online Game Speicher an
    fi

    # Erstellt eine Form, welche direkt abgeschickt wird
    # leitet an das Game script weiter
    # überträgt wichtige informationen and das game script
    cat << EOF
    <form name="instasubmit" action="/cgi-bin/Advanced-Tick-Tac-Toe/game.sh" method="post">
        <input type="hidden" name="NameInput" value="$nameInput">
        <input type="hidden" name="numberOfFiles" value="$numberOfFiles">
        <input type="hidden" name="GameType" value="$folder">
    </form>
    <script>
        document.forms["instasubmit"].submit();
    </script>
EOF

# Läd das asugewählte spiel und leitet direkt zum Spiel weiter
elif [[ -n "$LoadSavedGames" ]]; then
    cat << EOF
    <form name="instasubmit" action="/cgi-bin/Advanced-Tick-Tac-Toe/game.sh" method="post">
        <input type="hidden" name="NameInput" value="$LoadSavedGames">
        <input type="hidden" name="numberOfFiles" value="$numberOfFiles">
        <input type="hidden" name="GameType" value="$GameType">
    </form>
EOF

# Lässt spieler online Games Beitreten
elif [[ -n "$JoinOnlineGame" ]]; then
    [[ -n `jq ". | select(.$JoinCode == null)" "$onlineGamesFile"` ]] && echo "invalid Join Code" && exit # prüft ob sich der code in der Datei befindet
    [[ `jq ".$JoinCode | .voll" $onlineGamesFile` == "true" ]] && echo "Raum ist bereits voll" && exit # prüft ob bereits eine Person dem Spiel Beigetreten ist

    # prüft ob der User bereits spiele Gespielt hat und erstellt ein neues verzeichnis falls nicht
    if [ ! -d "$saveDatadir/$nameInput/online" ]; then
        if [ ! -d "$saveDatadir/$nameInput" ]; then
            mkdir -p "$saveDatadir/$nameInput";
        fi

        # erstellt den Games ordner 
        mkdir "$saveDatadir/$nameInput/online";
    fi

    joineeOnlineSaveLocation="$saveDatadir/$nameInput/online"

    # zählt die anzahl an bereits existierenden spielständen
    numberOfFiles=`ls "$joineeOnlineSaveLocation" -1q | wc -l`

    # name und file des anderen Spielers holen
    otherPlayerName=`jq -r ".$JoinCode | keys[0]" $onlineGamesFile`
    otherPlayerSaveFileNumber=`jq -r ".$JoinCode | .$otherPlayerName" $onlineGamesFile`
    otherPlayerSaveFile="$saveDatadir/$otherPlayerName/online/$otherPlayerSaveFileNumber.json"
    
    # online Game File Bearbeiten
    echo `jq ".$JoinCode += {\"$nameInput\": $numberOfFiles}" "$onlineGamesFile"` > "$onlineGamesFile"
    echo `jq ".$JoinCode.voll |= true" "$onlineGamesFile"` > "$onlineGamesFile"

    # fügt den beigetretenen spieler als mitspieler hinzu
    echo `jq ".Players[1] |= \"$nameInput\"" "$otherPlayerSaveFile"` > "$otherPlayerSaveFile"

    # Kopiert das Game File des Gegners in eigenen Online Save
    cp $otherPlayerSaveFile "$joineeOnlineSaveLocation/$numberOfFiles.json"


    # Erstellt eine Form, welche direkt abgeschickt wird
    # leitet an das Game script weiter
    # überträgt wichtige informationen and das game script
    cat << EOF
    <form name="instasubmit" action="/cgi-bin/Advanced-Tick-Tac-Toe/game.sh" method="post">
        <input type="hidden" name="NameInput" value="$nameInput">
        <input type="hidden" name="numberOfFiles" value="$numberOfFiles">
        <input type="hidden" name="GameType" value="online">
    </form>
    <script>
        document.forms["instasubmit"].submit();
    </script>
EOF

# Liefert alle gespeicherten Spiele eines Bestimmten Users zurück
# dabei wird unterschieden ob es ein Online oder Local Game ist
elif [[ -n "$SavedGames" ]]; then

    # wählt den speicherort aus, in welchem der Spielstand gespeichert wird
    # ebenso wird der Text für einene Leeren Games Ordner definiert
    # beendet das script falls eine falsche eingabe passiert ist
    if [[ "$Type" == "LocalSavedGames" ]]; then
        type="games"
        emptyText="Keine Spiele unter diesem Namen gespeichert, erstelle ein Neues um zu Spielen"
    elif [[ "$Type" == "OnlineSavedGames" ]]; then
        type="online"
        emptyText="Keine Spiele unter diesem Namen gespeichert, erstelle ein Neues oder Trete einem anderen Online Spiel bei um zu Spielen"
    else
        exit
    fi

    # allgemeine Speicher Location
    SavedGamesDir="$saveDatadir/$SavedGames/$type"

    if [[ -d "$saveDatadir/$SavedGames" ]] &&  [[ -d "$SavedGamesDir" ]] && [[ `ls "$SavedGamesDir" -1q | wc -l` != 0 ]]; then
        for SavedGame in `ls "$SavedGamesDir"`; do
            playername1=`jq -r ".Players[0]" "$SavedGamesDir/$SavedGame"`
            playername2=`jq -r ".Players[1]" "$SavedGamesDir/$SavedGame"`
            Winner=`jq -r ".Winner" "$SavedGamesDir/$SavedGame"`

            # läd alle Dateien aus dem verzeichnis und entfernt die Dateiendung
            SavedGameNumberOnly=`tr -d '.json' <<< "$SavedGame"`

            # generiert den HTML Code für die ausgabe auf der Website, 
            echo "<div onclick=\"startGame('$SavedGames', $SavedGameNumberOnly, '$type')\">"
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