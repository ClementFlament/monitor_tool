#!/bin/bash
exec 2> ./log/installer_error.log

INSTALL_DIR="/opt/monitor"
SERVICE_FILE="/etc/systemd/system/monitor-server.service"
SCRIPTS=("server.sh" "menu.sh")

# Download dependencies
echo "[INFO] Téléchargement des dépendances"
apt-get update
apt install jq dialog 

# Create installation folder
echo "[INFO] Création du dossier d'installation..."
sudo mkdir -p "$INSTALL_DIR/data"

# Copy files from the current directory to the installation directory and set the script as executable
echo "[INFO] Copie des scripts..."
for SCRIPT in "${SCRIPTS[@]}"; do
    sudo cp "$SCRIPT" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/$FILE"
done

# Create service configuration for systemd
echo "[INFO] Création du service systemd..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Monitor Server
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/server.sh
WorkingDirectory=${INSTALL_DIR}
Restart=always
User=root
Environment=PORT=9999

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
echo "[INFO] Activation du service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now monitor-server.service

echo "[INFO] Installation terminée."
