#!/bin/bash
exec > installer.log 2> installer_error.log

# Remote server
SERVER_IP=lab.clementflament.fr
SERVER_PORT=9999

# Retrieve the hostname
HOSTNAME=$(hostname)

# Retrieve the OS and version
OS="macOS $(sw_vers -productVersion) (Build $(sw_vers -buildVersion))"

# IP information for macOS
IPv4=$(ipconfig getifaddr en0)
[ -z "$IPv4" ] && IPv4=$(ipconfig getifaddr en1)
MAC=$(ifconfig en0 | awk '/ether/{print $2}')
[ -z "$MAC" ] && MAC=$(ifconfig en1 | awk '/ether/{print $2}')

# CPU info for macOS
cpu_type=$(sysctl -n machdep.cpu.brand_string)
cpu_line=$(top -l 1 | grep "CPU usage")
cpu_user=$(echo "$cpu_line" | awk '{print $3}' | tr -d '%')
cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | tr -d '%')
cpu_idle=$(echo "$cpu_line" | awk '{print $7}' | tr -d '%')

# RAM info for macOS
used=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$3} END {gsub(/\./,"",active); gsub(/\./,"",wired); print (active + wired) * 4096 / 1024 / 1024 / 1024}')
total=$(sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024 / 1024}')

# Disk information
disk_size=$(df -H / | awk 'NR==2 {gsub("G","",$2); print $2}')
disk_free=$(df -H / | awk 'NR==2 {gsub("G","",$4); print $4}')

# Applications list in array format
APP_INFO=$(ls /Applications | sed 's/\.app$//' | jq -R . | jq -s .)

# Create JSON data and map the values
DATA=$(jq -n \
  --arg hostname "$HOSTNAME" \
  --arg os "$OS" \
  --arg ipv4 "$IPv4" \
  --arg mac "$MAC" \
  --arg cpu_type "$cpu_type" \
  --arg cpu_user "$cpu_user" \
  --arg cpu_sys "$cpu_sys" \
  --arg cpu_idle "$cpu_idle" \
  --arg ram_used "$used" \
  --arg ram_total "$total" \
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
echo "$DATA" | nc "$SERVER_IP" "$SERVER_PORT"
echo "Données envoyées à $SERVER_IP:$SERVER_PORT"
