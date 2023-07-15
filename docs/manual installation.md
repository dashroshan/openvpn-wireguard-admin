Open ports in Azure portal then these in VM

```
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 4000
```

Create 1GB Swap memeory `(1M * 1000 ~= 1GB)`

```
mkdir -p /var/swapmemory
cd /var/swapmemory
dd if=/dev/zero of=swapfile bs=1M count=1000
mkswap swapfile
swapon swapfile
chmod 600 swapfile
free -m
```

Boost network performance

```
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
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
xvpn-username.dashroshan.com {
    reverse_proxy localhost:5000
}
```

Reload caddy

```
sudo caddy reload
```

Setup desired vpn service

> OpenVPN

```
wget https://git.io/vpn -O openvpn-install.sh
sudo chmod +x openvpn-install.sh
sudo bash openvpn-install.sh
```

> Wireguard

```
wget https://git.io/wireguard -O wireguard-install.sh
sudo chmod +x wireguard-install.sh
sudo bash wireguard-install.sh
```

Setup this admin portal

```
git clone https://github.com/dashroshan/openvpn-wireguard-admin ov
cd ov
sudo python3 -m pip install -r requirements.txt
sudo nano config.py
```

Fill config.py with below content and uncomment desired vpn

```py
# import openvpn as vpn
# import wireguard as vpn

creds = {
    "username": "roshan",
    "password": "dash",
}
```

If using wireguard create configWireguard.py with

```py
wireGuardBlockAds = False
```

Start portal in screen session

```
screen -S ov
sudo python3 main.py
```

`Ctrl+A+D` to deattach screen session and `screen -r ov` to reattach. `screen -ls` can be used to list screen session, and `screen -r ov -X quit` can be used to delete the session.
