grid = "<table class="game">"

for i in $(seq 0 2);
do
    grid += "<tr>"
    for j in $(seq 0 2);
    do
        grid += "<th class=\"borderbottom"
        if [j = 2] then
            grid += " borderright"
        fi
        grid += "\">"
    done
    grid += "</tr>"
done