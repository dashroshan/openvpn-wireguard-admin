Open ports

```
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 4000
```

Install python

```
sudo apt update && sudo apt install python3 python3-pip screen
```

Install caddy

```
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

Create Caddyfile

```
openvpn-username.dashroshan.com {
    reverse_proxy localhost:5000
}
```

Reload caddy

```
sudo caddy reload
```

Setup openvpn

```
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
wget https://git.io/vpn -O openvpn-install.sh
sudo chmod +x openvpn-install.sh
sudo bash openvpn-install.sh
```
