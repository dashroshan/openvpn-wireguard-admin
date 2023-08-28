#!/usr/bin/env bash

# Define color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET="\033[0m"

divider() {
    echo -e "${CYAN}------------------------------------------------${RESET}"
}

print_error() {
    echo -e "${RED}[ERROR]: $1${RESET}"
}

print_info() {
    echo -e "${BLUE}[INFO]: $1${RESET}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]: $1${RESET}"
}

print_question() {
    echo -e "${YELLOW}[QUESTION]: $1${RESET}"
}

# Handle errors
trap 'print_error "Command failed!"' ERR
set -e

divider
print_info "Initializing swap memory adjustment script..."
divider

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   print_error "This script must be run as root."
   exit 1
fi

print_info "Ensuring /var/swapmemory directory exists..."
mkdir -p /var/swapmemory

divider
print_info "Checking total RAM and existing swap..."
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')

if [ "$TOTAL_RAM" -lt 1024 ]; then
    SWAP_SIZE=$TOTAL_RAM
else
    SWAP_SIZE=1000
fi
print_success "Swap size determined: $SWAP_SIZE MB."

divider
if [ -f "/var/swapmemory/swapfile" ]; then
    print_question "Swapfile already exists. Do you want to resize it to $SWAP_SIZE MB? (yes/no)"
    read answer
    if [ "$answer" == "yes" ]; then
        print_info "Turning off existing swap..."
        swapoff /var/swapmemory/swapfile
        print_info "Resizing swapfile..."
        dd if=/dev/zero of=/var/swapmemory/swapfile bs=1M count=$SWAP_SIZE
        mkswap /var/swapmemory/swapfile
        swapon /var/swapmemory/swapfile
        print_success "Swap memory resized to $SWAP_SIZE MB."
    else
        print_info "Keeping the current swap size."
    fi
else
    print_info "Creating new swapfile..."
    dd if=/dev/zero of=/var/swapmemory/swapfile bs=1M count=$SWAP_SIZE
    mkswap /var/swapmemory/swapfile
    swapon /var/swapmemory/swapfile
    chmod 600 /var/swapmemory/swapfile
    echo "/var/swapmemory/swapfile none swap sw 0 0" >> /etc/fstab
    print_success "Swap memory of size $SWAP_SIZE MB created."
fi

divider
print_info "Showing current swap usage..."
free -m

divider
print_info "Boosting network performance..."
sysctl -w net.core.rmem_max=26214400
sysctl -w net.core.rmem_default=26214400
print_success "Network performance boosted."

divider
print_info "Fetching distribution information..."
divider

divider

# Get distro info
DISTRO=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
VERSION_ID=$(grep "VERSION_ID" /etc/os-release | cut -d'=' -f2 | tr -d '"')

if [[ "$DISTRO" == "debian" ]]; then
    print_info "Detected Debian distribution."
    
    case "$VERSION_ID" in
        "11")
        # Debian 11 Bullseye
        divider
        print_info "Setting sources for Debian 11 Bullseye..."
        tee /etc/apt/sources.list > /dev/null << EOF
deb http://ftp.debian.org/debian bullseye main contrib non-free 
deb-src http://ftp.debian.org/debian bullseye main contrib non-free 
deb http://ftp.debian.org/debian bullseye-updates main contrib non-free 
deb-src http://ftp.debian.org/debian bullseye-updates main contrib non-free 
deb http://security.debian.org/debian-security bullseye-security main contrib non-free 
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free 
deb http://ftp.debian.org/debian bullseye-backports main contrib non-free
EOF
        print_success "Sources set for Debian 11 Bullseye."
        ;;
        
        *)
        print_error "Unsupported Debian version."
        ;;
    esac
else
    print_error "Unsupported distribution."
fi

divider

divider
print_info "Updating system packages..."
apt update && apt upgrade -y
if [ $? -eq 0 ]; then
    print_success "System packages updated successfully."
else
    print_error "Failed to update system packages!"
    exit 1
fi

divider
print_info "Installing necessary packages..."
apt install -y ufw git wget python3 python3-pip screen gpg fail2ban curl cron debian-keyring debian-archive-keyring apt-transport-https
if [ $? -eq 0 ]; then
    print_success "Necessary packages installed successfully."
else
    print_error "Failed to install necessary packages!"
    exit 1
fi

divider
print_info "Enabling UFW firewall..."
echo "y" | ufw enable
if [ $? -eq 0 ]; then
    print_success "UFW firewall enabled successfully."
else
    print_error "Failed to enable UFW firewall!"
    exit 1
fi

divider
print_info "Configuring firewall ports..."
read -p "Enter the VPN connection port: " vpnport
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow $vpnport
ufw allow 80/tcp
ufw allow 443/tcp
if [ $? -eq 0 ]; then
    print_success "Ports 22, 80, 443, and $vpnport opened successfully."
else
    print_error "Failed to configure firewall ports!"
    exit 1
fi

divider

divider
print_info "Installing Caddy..."
divider

# Add Caddy's GPG key for package verification
if curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg; then
    print_success "Caddy's GPG key added successfully."
else
    print_error "Failed to add Caddy's GPG key."
    exit 1
fi

# Add Caddy's APT repository to the source list
if echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | tee /etc/apt/sources.list.d/caddy-stable.list; then
    print_success "Added Caddy's APT repository to the source list."
else
    print_error "Failed to add Caddy's APT repository."
    exit 1
fi

# Update package list and install Caddy
if apt update && apt install -y caddy; then
    print_success "Caddy installed successfully."
else
    print_error "Failed to install Caddy."
    exit 1
fi

divider
print_info "Configuring Caddy..."
divider

# Stop the Caddy service for configuration
if systemctl stop caddy; then
    print_success "Caddy service stopped for configuration."
else
    print_error "Failed to stop Caddy service."
    exit 1
fi

# Ask the user for the domain
print_question "Enter your Web admin panel domain (e.g., example.com): "
read admindomain

# Configure Caddy to use the provided domain details and default proxy to localhost:5000
cat <<EOF > /etc/caddy/Caddyfile
$admindomain {
    reverse_proxy localhost:5000
}
EOF

# Adjust permissions to ensure Caddy can read the file
chmod 644 /etc/caddy/Caddyfile

# Format the Caddyfile
if caddy fmt --overwrite /etc/caddy/Caddyfile; then
    print_success "Caddyfile formatted successfully."
else
    print_error "Failed to format Caddyfile."
    exit 1
fi

# Start the Caddy service and enable it to start on boot
if systemctl start caddy && systemctl enable caddy; then
    print_success "Caddy service started and enabled on boot."
else
    print_error "Failed to start and enable Caddy service."
    exit 1
fi

# Reload Caddy configuration specifying the path to the Caddyfile
if caddy reload --config /etc/caddy/Caddyfile; then
    print_success "Caddy configuration reloaded successfully."
else
    print_error "Failed to reload Caddy configuration."
    exit 1
fi

if systemctl is-active --quiet caddy; then
    print_success "Reverse proxy configured with Caddy."
else
    print_error "Caddy service isn't running."
    exit 1
fi

divider

divider
print_info "Setting up the web admin panel..."
divider

cd
if git clone https://github.com/dashroshan/openvpn-wireguard-admin vpn; then
    print_success "Cloned the Web admin panel successfully."
else
    print_error "Failed to clone the Web admin panel."
    exit 1
fi

cd vpn
if python3 -m pip install -r requirements.txt; then
    print_success "Requirements for Web admin panel installed successfully."
else
    print_error "Failed to install requirements for Web admin panel."
    exit 1
fi

divider
print_question "Enter 'wireguard' or 'openvpn' as needed: "
read vpntype

if [ "$vpntype" == "wireguard" ]; then
    print_question "Enter 'True' or 'False' for AdBlock: "
    read adblock
    cat << EOF > configWireguard.py
wireGuardBlockAds = $adblock
EOF
    print_success "configureWireguard.py file created for AdBlock settings."
fi

divider
print_question "Web admin panel username: "
read adminuser

print_question "Web admin panel password: "
read adminpass

passwordhash=$(echo -n $adminpass | sha256sum | cut -d" " -f1)

cat << EOF > config.py
import $vpntype as vpn
creds = {
    "username": "$adminuser",
    "password": "$passwordhash",
}
EOF
print_success "config.py file created for web admin panel."

divider
print_info "Downloading VPN setup script..."
divider

cd
if [ "$vpntype" == "wireguard" ]; then
    if wget https://raw.githubusercontent.com/Nyr/wireguard-install/master/wireguard-install.sh -O vpn-install.sh; then
        print_success "WireGuard setup script downloaded successfully."
    else
        print_error "Failed to download WireGuard setup script."
        exit 1
    fi
else
    if wget https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh -O vpn-install.sh; then
        print_success "OpenVPN setup script downloaded successfully."
    else
        print_error "Failed to download OpenVPN setup script."
        exit 1
    fi
fi

divider
print_info "Setting up VPN service..."
divider

chmod +x vpn-install.sh
./vpn-install.sh
print_success "VPN service installed successfully."

divider
print_info "Installing fail2ban..."
divider

if apt install -y fail2ban; then
    systemctl enable fail2ban
    systemctl start fail2ban
    print_success "fail2ban installed and started successfully."
else
    print_error "Failed to install fail2ban."
    exit 1
fi

divider

divider
print_info "Configuring fail2ban for SSH on port 22..."
cat << EOF > /etc/fail2ban/jail.d/custom-sshd.conf
[sshd]
enabled  = true
port     = 22
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 3600
EOF
print_success "Configured fail2ban for SSH on port 22."

divider
print_info "Configuring fail2ban for OpenVPN..."
cat << EOF > /etc/fail2ban/jail.d/openvpn.conf
[openvpn]
enabled  = true
port     = $vpnport
protocol = udp
filter   = openvpn
logpath  = /var/log/openvpn.log
maxretry = 3
bantime  = 3600
EOF
print_success "Configured fail2ban for OpenVPN."

divider
print_info "Setting up logging for WireGuard..."
if [ "$vpntype" == "wireguard" ]; then
    WIREGUARD_CONFIG="/etc/wireguard/wg0.conf"
    LOGFILE_PATH="/var/log/wireguard.log"

    echo "PostUp = wg-quick save %i; /usr/bin/journalctl -u wg-quick@wg0.service -f -n 0 -o cat >> $LOGFILE_PATH" >> $WIREGUARD_CONFIG

    cat <<EOF > /etc/fail2ban/jail.d/wireguard.conf
[wireguard]
enabled  = true
port     = $vpnport
filter   = wireguard
logpath  = $LOGFILE_PATH
maxretry = 3
EOF
    print_success "Configured logging for WireGuard."
else
    print_info "WireGuard not detected. Skipping WireGuard logging setup."
fi

divider
print_info "Setting up filter for OpenVPN..."
echo "[Definition]" > /etc/fail2ban/filter.d/openvpn.conf
echo "failregex = TLS Auth Error: Auth Username/Password verification failed for peer" >> /etc/fail2ban/filter.d/openvpn.conf
print_success "Set up filter for OpenVPN."

divider
print_info "Setting up filter for WireGuard..."
cat <<EOF > /etc/fail2ban/filter.d/wireguard.conf
[Definition]
failregex = .*WG:.*\[.*\]: Handshake for peer .* failed for .*: Invalid MAC=
           .*peer:(\S+).*AllowedIPs\s*=\s*0.0.0.0\/0
ignoreregex =
EOF
print_success "Set up filter for WireGuard."

divider
print_info "Restarting fail2ban..."
systemctl restart fail2ban
print_success "Restarted fail2ban successfully."

divider
print_info "Setting up the startup script..."

# Define the path to save the startup script
SCRIPT_PATH="/root/startup.sh"

# Creating the startup script with a heredoc
cat <<EOL > $SCRIPT_PATH
#!/usr/bin/env bash

# Delay to stabilize the system after reboot
sleep 30

# Change to the correct directory
cd /root/vpn

# Launch the application using the determined path for python3
env nohup python3 main.py &> /root/vpn/vpn.log &

EOL

# Making the startup script executable
chmod +x $SCRIPT_PATH
print_success "Startup script setup completed."

divider
print_info "Checking and adding the startup.sh script to cron for auto-start at boot..."

CRON_JOB_FILE="/etc/cron.d/my_startup_script"

# Check if our cron job file already exists
if [ ! -f "$CRON_JOB_FILE" ]; then
    echo "@reboot root $SCRIPT_PATH" > $CRON_JOB_FILE
    if [ $? -eq 0 ]; then
        print_success "Script is set up and added to cron for automatic startup."
    else
        print_error "Failed to add the script to cron."
    fi
else
    print_info "Script already exists in cron."
fi

divider
print_question "For the changes to take effect, a reboot is required. Would you like to reboot the computer now? (y/n)"
read choice

case "$choice" in 
  y|Y )
    print_info "Rebooting now..."
    reboot
    ;;
  n|N )
    print_success "Please remember to reboot the computer later."
    ;;
  * )
    print_error "Invalid input. Please remember to reboot the computer later."
    ;;
esac
