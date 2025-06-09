#!/bin/bash

# Configuration
INSTALL_DIR="/opt/agent-monitor"
SCRIPT_NAME="agent_ubuntu.sh"
SCRIPT_URL="https://files.clementflament.fr/monitor/agents/agent_ubuntu.sh"
CRON_JOB="*/30 * * * * $INSTALL_DIR/$SCRIPT_NAME"

# Relaunch the script with sudo if not already root
if [ "$EUID" -ne 0 ]; then
  echo "[INFO] Relancement du script avec sudo..."
  exec sudo "$0" "$@"
fi

# Step 1: Create the installation directory
echo "[INFO] Création du répertoire : $INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo chmod 755 "$INSTALL_DIR"

# Step 2: Download the agent script
echo "[INFO] Téléchargement du script agent depuis $SCRIPT_URL"
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"

# Check download success
if [[ $? -ne 0 ]]; then
  echo "[ERREUR] Échec du téléchargement du script agent."
  exit 1
fi

# Step 3: Make the script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Step 4: Add cron job if not already present
CRONTAB_LINE=$(crontab -l 2>/dev/null | grep -F "$SCRIPT_NAME")
if [[ -z "$CRONTAB_LINE" ]]; then
  echo "[INFO] Ajout de la tâche cron : $CRON_JOB"
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
  echo "[INFO] La tâche cron existe déjà. Passage à l'étape suivante."
fi

echo "[SUCCÈS] Installation terminée avec succès."
