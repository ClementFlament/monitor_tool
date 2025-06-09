#!/bin/bash
exec > installer.log 2> installer_error.log

# Remote server
SERVER_IP=lab.clementflament.fr
SERVER_PORT=9999

# Retrieve the hostname
HOSTNAME=$(hostname)

# Retrieve the OS and version
OS="$(lsb_release -ds) (Kernel $(uname -r))"

# IP and MAC information
IPv4=$(hostname -I | awk '{print $1}')
INTERFACE=$(ip route | grep default | awk '{print $5}')
MAC=$(cat /sys/class/net/"$INTERFACE"/address)

# CPU info
cpu_type=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^[ \t]*//')
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%id,')
cpu_user=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%us,')
cpu_sys=$(top -bn1 | grep "Cpu(s)" | awk '{print $4}' | tr -d '%sy,')

# RAM info
ram_total=$(free -g | awk '/^Mem:/ {print $2}')
ram_used=$(free -g | awk '/^Mem:/ {print $3}')

# Disk info
disk_size=$(df -h / | awk 'NR==2 {print $2}' | sed 's/G//')
disk_free=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')

# Application list (installed packages)
APP_INFO=$(dpkg-query -f '${binary:Package}\n' -W | jq -R . | jq -s .)

# Create JSON data
DATA=$(jq -n \
  --arg hostname "$HOSTNAME" \
  --arg os "$OS" \
  --arg ipv4 "$IPv4" \
  --arg mac "$MAC" \
  --arg cpu_type "$cpu_type" \
  --arg cpu_user "$cpu_user" \
  --arg cpu_sys "$cpu_sys" \
  --arg cpu_idle "$cpu_idle" \
  --arg ram_used "$ram_used" \
  --arg ram_total "$ram_total" \
  --arg disk_free "$disk_free" \
  --arg disk_total "$disk_size" \
  --argjson app_info "$APP_INFO" \
  '{
    hostname: $hostname,
    os: $os,
    network_info: {
      ipv4: $ipv4,
      mac: $mac
    },
    cpu_info: {
      type: $cpu_type,
      user: $cpu_user,
      system: $cpu_sys,
      idle: $cpu_idle
    },
    ram_info: {
      used_gb: $ram_used,
      total_gb: $ram_total
    },
    disk_info: {
      free_gb: $disk_free,
      total_gb: $disk_total
    },
    app_info: $app_info
  }')

# Send the information to the server
echo "$DATA" | nc -q 1 "$SERVER_IP" "$SERVER_PORT"
echo "Données envoyées à $SERVER_IP:$SERVER_PORT"
