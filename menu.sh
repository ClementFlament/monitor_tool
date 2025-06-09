#!/bin/bash

DATA_DIR="./data"

# Main menu function
main_menu() {
    while true; do
        CHOICE=$(dialog --clear \
            --title "Menu Principal" \
            --menu "Choisis une action :" \
            20 60 10 \
            1 "Voir un host" \
            2 "Résumé des hosts" \
            3 "Supprimer un host" \
            4 "Quitter" \
            2>&1 >/dev/tty)

        case $CHOICE in
            1) view_host ;;
            2) show_summary ;;
            3) delete_host ;;
            4) clear; echo "À bientôt !"; exit 0 ;;
        esac
    done
}

# View_host function, open a new dialog box to choose a hostname, then, create a temporary file to display information
view_host() {
    OPTIONS=()
    i=1
    for FILE in "$DATA_DIR"/*; do
        HOSTNAME=$(basename "$FILE" .json)
        OPTIONS+=($i "$HOSTNAME")
        ((i++))
    done

    if [ ${#OPTIONS[@]} -eq 0 ]; then
        dialog --msgbox "Aucun host trouvé dans $DATA_DIR" 8 40
        return
    fi

    CHOICE=$(dialog --menu "Hosts disponibles (ESC pour annuler):" \
        20 60 10 "${OPTIONS[@]}" \
        2>&1 >/dev/tty)

    if [[ $? -ne 0 ]]; then return; fi

    INDEX=$(( (CHOICE - 1) * 2 + 1 ))
    SELECTED_HOST="${OPTIONS[$INDEX]}"

    # Format and create a temporary file to display the informations
    jq . "$DATA_DIR/$SELECTED_HOST.json" > /tmp/view_host.tmp
    dialog --title "Détails du host: $SELECTED_HOST" --textbox /tmp/view_host.tmp 40 200
    rm /tmp/view_host.tmp
}

# Show summary function, create a temporary file with the hostnames and names to create a small summary about the hosts
show_summary() {
    TMP_FILE=$(mktemp)
    echo "Résumé des hosts :" > "$TMP_FILE"
    echo "=====================" >> "$TMP_FILE"
    for FILE in "$DATA_DIR"/*.json; do
        [ -e "$FILE" ] || continue
        HOST=$(jq -r .hostname "$FILE")
        IP=$(jq -r .network_info.ipv4 "$FILE")
        DATE=$(date -r "$FILE" "+%Y-%m-%d %H:%M:%S")
        echo "$HOST - $IP - Dernière mise à jour : $DATE" >> "$TMP_FILE"
    done
    dialog --title "Résumé des hosts" --textbox "$TMP_FILE" 25 100
    rm "$TMP_FILE"
}

# Delete_hosts function to display the content of the ./data folder and choose a file to be removed
delete_host() {
    OPTIONS=()
    i=1
    for FILE in "$DATA_DIR"/*; do
        HOSTNAME=$(basename "$FILE" .json)
        OPTIONS+=($i "$HOSTNAME")
        ((i++))
    done

    if [ ${#OPTIONS[@]} -eq 0 ]; then
        dialog --msgbox "Aucun host à supprimer." 8 40
        return
    fi

    CHOICE=$(dialog --menu "Sélectionne un host à supprimer :" \
        20 60 10 "${OPTIONS[@]}" \
        2>&1 >/dev/tty)

    if [[ $? -ne 0 ]]; then return; fi

    INDEX=$(( (CHOICE - 1) * 2 + 1 ))
    SELECTED_HOST="${OPTIONS[$INDEX]}"
    FILE_PATH="$DATA_DIR/$SELECTED_HOST.json"

    dialog --yesno "Es-tu sûr de vouloir supprimer les données du host '$SELECTED_HOST' ?" 7 60
    if [[ $? -eq 0 ]]; then
        rm "$FILE_PATH"
        dialog --msgbox "Host supprimé." 6 40
    fi
}

 # Call the main loop
main_menu
