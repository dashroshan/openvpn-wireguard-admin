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

# Ensure the script is run with root privileges
if [ "$(id -u)" != "0" ]; then
   echo "Error: This script must be run with root privileges." >&2
   echo "Please use 'sudo' or log in as the root user and try again." >&2
   exit 1
fi

divider
print_info "Initializing swap memory adjustment script..."
divider

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
    print_info "Swapfile already exists. Do you want to resize it to $SWAP_SIZE MB? (yes/no)"
    read answer
    if [ "$answer" == "yes" ]; then
        print_info "Turning off existing swap..."
        swapoff /var/swapmemory/swapfile
        print_info "Resizing swapfile..."
        dd if=/dev/zero of=/var/swapmemory/swapfile bs=1M count=$SWAP_SIZE && \
        mkswap /var/swapmemory/swapfile && \
        swapon /var/swapmemory/swapfile && \
        print_success "Swap memory resized to $SWAP_SIZE MB." || \
        print_error "Error occurred while resizing swap memory."
    else
        print_info "Keeping the current swap size."
    fi
else
    print_info "Creating new swapfile..."
    dd if=/dev/zero of=/var/swapmemory/swapfile bs=1M count=$SWAP_SIZE && \
    mkswap /var/swapmemory/swapfile && \
    swapon /var/swapmemory/swapfile && \
    chmod 600 /var/swapmemory/swapfile && \
    echo "/var/swapmemory/swapfile none swap sw 0 0" >> /etc/fstab && \
    print_success "Swap memory of size $SWAP_SIZE MB created." || \
    print_error "Error occurred while creating swap memory."
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
        print_error "Detected an unsupported OS version."
        print_error "Recommended OS: Debian 11 Minimal."
        read -p "The script is not optimized for this version and there's no guarantee of successful installation. Do you want to proceed? (y/N) " choice
        case "$choice" in
    [yY]* )
        # Add the code to continue installation for other versions here
        print_info "Continuing installation on unsupported OS version..."
        ;;
    * )
        print_error "Installation aborted."
        exit 1
    esac

                ;;
        esac

else
    print_error "Unsupported distribution."
fi

divider

divider
print_info "Updating system packages..."

# Using stderr redirection only for apt update
OUTPUT=$(apt update 2>/dev/null && apt upgrade -y 2>&1)

if [ $? -eq 0 ]; then
    print_success "System packages updated successfully."
    echo "Upgraded packages:"
    echo "$OUTPUT" | grep 'upgraded'
else
    print_error "Failed to update system packages!"
    exit 1
fi

divider
print_info "Installing necessary packages..."

LOGFILE="/root/apt_install.log"
DEBIAN_FRONTEND=noninteractive apt install -y ufw git wget python3 python3-pip screen gpg fail2ban curl cron debian-keyring debian-archive-keyring apt-transport-https apt-transport-https systemd >$LOGFILE 2>&1

if [ $? -eq 0 ]; then
    print_success "Necessary packages installed successfully."
else
    print_error "Failed to install necessary packages!"
    print_info "Please check the log file for details: $LOGFILE"
    exit 1
fi

divider
print_info "Synchronizing system time..."
divider

# Update package list
if apt update; then
    print_success "Package list updated."
else
    print_error "Failed to update package list."
    exit 1
fi

# Install ntp package
if apt install ntp -y; then
    print_success "NTP package installed successfully."
else
    print_error "Failed to install NTP package."
    exit 1
fi

# Start ntp service
if systemctl start ntp; then
    print_success "NTP service started successfully."
else
    print_error "Failed to start NTP service."
    exit 1
fi

# Enable ntp service at boot
if systemctl enable ntp; then
    print_success "NTP service enabled to start at boot."
else
    print_error "Failed to enable NTP service at boot."
    exit 1
fi

print_success "System time is synchronized."

divider

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
print_question "Web admin panel username: "
read adminuser

# Simple validation for the username
while [[ ! "$adminuser" =~ ^[a-zA-Z0-9_]{3,15}$ ]]; do
    print_error "Username should be between 3 and 15 characters long and can only contain alphanumeric characters and underscores."
    print_question "Web admin panel username: "
    read adminuser
done

# Read the password with hidden input
print_question "Web admin panel password: "
read -s adminpass
echo

# Validate the password based on the chosen requirements.

# The following block checks for:
# - At least one uppercase character
# - At least one lowercase character
# - At least one digit
# - Password length between 8 and 64 characters
while [[ ! "$adminpass" =~ [A-Z] ]] || 
      [[ ! "$adminpass" =~ [a-z] ]] || 
      [[ ! "$adminpass" =~ [0-9] ]] || 
      [[ ${#adminpass} -lt 8 ]] || 
      [[ ${#adminpass} -gt 64 ]]; do
    print_error "Password must be between 8 and 64 characters, include at least one uppercase letter, one lowercase letter, and one number."
    print_question "Web admin panel password: "
    read -s adminpass
    echo
done

# Alternative simpler password requirements (uncomment as needed):

# 1. No specific requirements for the password.
# print_question "Web admin panel password (no restrictions): "
# read -s adminpass
# echo

# 2. Only check for password length.
# while [[ ${#adminpass} -lt 8 ]] || [[ ${#adminpass} -gt 64 ]]; do
#     print_error "Password must be between 8 and 64 characters."
#     print_question "Web admin panel password: "
#     read -s adminpass
#     echo
# done

# 3. Password can only contain letters.
# while [[ ! "$adminpass" =~ ^[a-zA-Z]+$ ]]; do
#     print_error "Password can only contain letters."
#     print_question "Web admin panel password: "
#     read -s adminpass
#     echo
# done

# Confirm the password with hidden input
print_question "Confirm password: "
read -s adminpass_confirm
echo

# Check if the passwords match
while [[ "$adminpass" != "$adminpass_confirm" ]]; do
    print_error "Passwords do not match. Please try again."
    print_question "Web admin panel password: "
    read -s adminpass
    echo

    print_question "Confirm password: "
    read -s adminpass_confirm
    echo
done

passwordhash=$(echo -n $adminpass | sha256sum | cut -d" " -f1)

print_info "Setting up VPN service..."

while true; do
    print_question "1) WireGuard"
    print_question "2) OpenVPN"
    read -p "Enter choice [1-2]: " choice

    case $choice in
        1)
            vpntype="wireguard"
            print_info "Downloading WireGuard setup script..."
            if wget https://raw.githubusercontent.com/Nyr/wireguard-install/master/wireguard-install.sh -O vpn-install.sh; then
                print_success "WireGuard setup script downloaded successfully."
                chmod +x vpn-install.sh
                ./vpn-install.sh
                print_success "WireGuard service installed successfully."
            else
                print_error "Failed to download WireGuard setup script."
                exit 1
            fi

            WIREGUARD_CONFIG="/etc/wireguard/wg0.conf"
            port=$(grep -Po '(?<=ListenPort\s=\s)\d+' "$WIREGUARD_CONFIG")

            if [ -z "$port" ]; then
                print_error "Failed to extract port from WireGuard configuration."
                exit 1
            fi
			
			ufw allow out on wg0 from any to any
			ufw reload

            print_info "Setting up logging for WireGuard..."
            LOGFILE_PATH="/var/log/wireguard.log"
            echo "@reboot root sleep 20 && /usr/bin/journalctl -u wg-quick@wg0.service -f -n 0 -o cat | tee -a /var/log/wireguard.log &" >> /etc/cron.d/wireguard_custom
            cat <<EOF > /etc/fail2ban/jail.d/wireguard.conf
[wireguard]
enabled  = true
port     = $port
filter   = wireguard
logpath  = $LOGFILE_PATH
maxretry = 3
EOF
            print_success "Configured logging for WireGuard."

            print_info "Setting up filter for WireGuard..."
            cat <<EOF > /etc/fail2ban/filter.d/wireguard.conf
[Definition]
failregex = .*WG:.*\[.*\]: Handshake for peer .* failed for .*: Invalid MAC=
           .*peer:(\S+).*AllowedIPs\s*=\s*0.0.0.0\/0
ignoreregex =
EOF

            # Simplified AdBlock choice
            print_question "Choose an option for AdBlock:"
            echo "1. True"
            echo "2. False"
            read -p "Enter 1 or 2: " choice

            case $choice in
                1) adblock="True" ;;
                2) adblock="False" ;;
                *) echo "Invalid choice. Exiting."; exit 1 ;;
            esac

            cat << EOF > configWireguard.py
wireGuardBlockAds = $adblock
EOF
            print_success "configureWireguard.py file created for AdBlock settings."

            divider

            # Define the path to save the cron job file
            CRON_JOB_FILE="/etc/cron.d/wireguard_cron_tasks"

            # Clear previous jobs if they exist
            > $CRON_JOB_FILE

            divider
            print_info "Would you like to set up auto-restart for the server?"

            if get_user_choice "Enable auto-restart?"; then
                print_question "Enter the time interval for server restart (e.g., 2 for every 2 hours):"
                read restart_interval
                echo "@reboot root /usr/bin/systemctl restart wg-quick@wg0" >> $CRON_JOB_FILE
                echo "0 */$restart_interval * * * root /usr/bin/systemctl restart wg-quick@wg0" >> $CRON_JOB_FILE
                print_success "Auto-restart setup completed."
            fi

            divider
print_info "Would you like to set up automatic updates for WireGuard?"

if get_user_choice "Enable automatic updates?"; then
    apt-get install -y unattended-upgrades
    echo 'Unattended-Upgrade::Allowed-Origins {' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}:${distro_codename}";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}:${distro_codename}-security";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}ESM:${distro_codename}";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '};' >> /etc/apt/apt.conf.d/50unattended-upgrades
    print_success "Auto-update for WireGuard setup completed."
fi

            divider
            print_info "Would you like to set up local monitoring for WireGuard?"

            if get_user_choice "Enable monitoring?"; then
                MONITORING_DEST="/root/vpn/wireguard_status.log"
                echo "* * * * * root wg show > $MONITORING_DEST" >> $CRON_JOB_FILE
                print_success "Local monitoring for WireGuard has been set up and logs will be saved to $MONITORING_DEST every minute."
            fi

            divider
            print_info "All configurations are set up!"
            break
            ;;

        2)
            vpntype="openvpn"
            print_info "Downloading OpenVPN setup script..."

            if wget https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh -O vpn-install.sh; then
                print_success "OpenVPN setup script downloaded successfully."
                chmod +x vpn-install.sh
                ./vpn-install.sh
                print_success "OpenVPN service installed successfully."
            else
                print_error "Failed to download OpenVPN setup script."
                exit 1
            fi

            port=$(grep -Po '(?<=^port\s)\d+' /etc/openvpn/server/server.conf)
            protocol=$(grep -Po '(?<=^proto\s)\w+' /etc/openvpn/server/server.conf)

            if [ -z "$port" ] || [ -z "$protocol" ]; then
                print_error "Failed to extract port or protocol from OpenVPN configuration."
                exit 1
            fi

            print_info "Configuring fail2ban for OpenVPN..."
            cat << EOF > /etc/fail2ban/jail.d/openvpn.conf
[openvpn]
enabled  = true
port     = $port
protocol = $protocol
filter   = openvpn
logpath  = /var/log/openvpn.log
maxretry = 3
bantime  = 3600
EOF
            print_success "Configured fail2ban for OpenVPN."

            print_info "Setting up filter for OpenVPN..."
            cat <<EOF > /etc/fail2ban/filter.d/openvpn.conf
[Definition]
failregex = TLS Auth Error: Auth Username/Password verification failed for peer
EOF
            print_success "Set up filter for OpenVPN."

            divider
            CRON_JOB_FILE="/etc/cron.d/openvpn_cron_tasks"
            > $CRON_JOB_FILE

            divider
            print_info "Would you like to set up auto-restart for the OpenVPN server?"

            while true; do
                print_question "Enable auto-restart? (yes/y or no/n)"
                read openvpn_choice_restart

                case "$openvpn_choice_restart" in
                    yes|y)
                        print_question "Enter the time interval for server restart (e.g., 2 for every 2 hours):"
                        read restart_interval
                        echo "@reboot root /usr/bin/systemctl restart openvpn-server@server" >> $CRON_JOB_FILE
                        echo "0 */$restart_interval * * * root /usr/bin/systemctl restart openvpn-server@server" >> $CRON_JOB_FILE
                        print_success "Auto-restart setup completed for OpenVPN."
                        break
                        ;;
                    no|n)
                        break
                        ;;
                    *)
                        print_error "Invalid choice. Please answer yes/y or no/n."
                        ;;
                esac
            done

            divider
            print_info "Would you like to set up automatic updates for OpenVPN?"

            while true; do
                print_question "Enable automatic updates? (yes/y or no/n)"
                read openvpn_choice_updates

                case "$openvpn_choice_updates" in
                    yes|y)
    apt-get install -y unattended-upgrades
    echo 'Unattended-Upgrade::Allowed-Origins {' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}:${distro_codename}";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}:${distro_codename}-security";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '        "${distro_id}ESM:${distro_codename}";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo '};' >> /etc/apt/apt.conf.d/50unattended-upgrades
    print_success "Auto-update for OpenVPN setup completed."
    break
    ;;
                    *)
                        print_error "Invalid choice. Please answer yes/y or no/n."
                        ;;
                esac
            done

            divider
            print_info "Would you like to set up local monitoring for OpenVPN?"

            while true; do
                print_question "Enable monitoring? (yes/y or no/n)"
                read openvpn_choice_monitoring

                case "$openvpn_choice_monitoring" in
                    yes|y)
                        MONITORING_DEST="/root/vpn/openvpn_status.log"
                        echo "* * * * * root cat /etc/openvpn/server/openvpn-status.log > $MONITORING_DEST" >> $CRON_JOB_FILE
                        print_success "Local monitoring for OpenVPN has been set up and logs will be saved to $MONITORING_DEST every minute."
                        break
                        ;;
                    no|n)
                        break
                        ;;
                    *)
                        print_error "Invalid choice. Please answer yes/y or no/n."
                        ;;
                esac
            done

            divider
            print_info "All configurations for OpenVPN are set up!"
            break
            ;;
        *)
            print_error "Invalid choice. Please select 1 or 2."
            ;;
    esac
done

cd
cd vpn
cat << EOF > config.py
import $vpntype as vpn
creds = {
    "username": "$adminuser",
    "password": "$passwordhash",
}
EOF
print_success "config.py file created for web admin panel."

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

print_info "Restarting fail2ban..."
systemctl restart fail2ban
print_success "Restarted fail2ban successfully."

divider
print_info "Configuring firewall ports..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow $port
ufw allow 80/tcp
ufw allow 443/tcp
if [ $? -eq 0 ]; then
    print_success "Ports 22, 80, 443, and $port opened successfully."
else
    print_error "Failed to configure firewall ports!"
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
while true; do
    print_question "Enter your Web admin panel domain or subdomain (e.g., sub.example.com): "
    read admindomain

    # Regex to check if the input might be a valid domain or subdomain
    if [[ $admindomain =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.?)+\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        print_error "Invalid domain format. Please enter a valid domain or subdomain (e.g., sub.example.com)."
    fi
done

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
print_info "Setting up the startup script..."

# Define the path to save the startup script
SCRIPT_PATH="/root/startup.sh"

# Creating the startup script with a heredoc
cat <<EOL > $SCRIPT_PATH
#!/usr/bin/env bash

# Delay to stabilize the system after reboot
sleep 5

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
print_question "For the changes to take effect, a reboot is required. Would you like to reboot the computer now? (yes/no)"
read choice

case "$(echo $choice | tr '[:upper:]' '[:lower:]')" in 
  y|yes )
    print_info "Rebooting now..."
    reboot
    ;;
  n|no )
    print_success "Please remember to reboot the computer later."
    ;;
  * )
    print_error "Invalid input. Please remember to reboot the computer later."
    ;;
esac
