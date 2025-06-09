#!/bin/bash

LOG_DIR="./log"
mkdir -p "$LOG_DIR"
exec 2> "$LOG_DIR/server_error.log"

PORT=9999
DATA_DIR="./data"

# Log function to add the timestamp in the terminal and copy the content in the log file
log() {
  TIMESTAMP="[$(date '+%Y-%m-%d %H:%M:%S')]"
  MESSAGE="$TIMESTAMP $*"
  echo "$MESSAGE"
}

# Create the folder if inexistant
log "[INFO] Check ou création du répertoire $DATA_DIR"
mkdir -p "$DATA_DIR"

# Initiate the server
log "[INFO] Démarrage du serveur sur le port $PORT"

# Check if the port is already in use
if lsof -iTCP:$PORT -sTCP:LISTEN -t >/dev/null; then
  log "[ERROR] Le port $PORT est déjà utilisé. Le serveur ne peut pas démarrer."
  exit 1
fi

while true; do
  # Listen for a connection
  DATA=$(nc -l $PORT)

  # Retrieve the hostname and IP
  hostname=$(echo "$DATA" | jq -r '.hostname')
  ip=$(echo "$DATA" | jq -r '.network_info.ipv4')

  log "Data received from $hostname from $ip"

  # Save data to ./data/<hostname>.json
  echo "$DATA" > "${DATA_DIR}/${hostname}.json"
done
