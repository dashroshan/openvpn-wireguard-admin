from subprocess import Popen, PIPE
from configWireguard import wireGuardBlockAds

vpnName = "WireGuard"
vpnExtension = "conf"


def createUser(user):
    if user in listUsers():
        return

    if wireGuardBlockAds:
        dns = "94.140.14.14, 94.140.15.15"
    else:
        dns = "1.1.1.1, 1.0.0.1"

    commandsOctet = [
        "sudo grep AllowedIPs /etc/wireguard/wg0.conf | cut -d '.' -f 4 | cut -d '/' -f 1",
    ]

    processOctet = Popen(
        "/bin/bash",
        shell=False,
        universal_newlines=True,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    octets, err = processOctet.communicate("\n".join(commandsOctet))
    octets = [octet for octet in octets.split("\n") if octet]

    octet = -1
    for i in range(2, 255):
        if str(i) not in octets:
            octet = i
            break

    if octet == -1:
        return

    commandsRSA = [
        f"octet={octet}",
        "key=$(wg genkey)",
        "psk=$(wg genpsk)",
        "sudo bash -c 'cat >> /etc/wireguard/wg0.conf' << EOF",
        f"# BEGIN_PEER {user}",
        "[Peer]",
        "PublicKey = $(wg pubkey <<< $key)",
        "PresharedKey = $psk",
        "AllowedIPs = 10.7.0.$octet/32$(sudo grep -q 'fddd:2c4:2c4:2c4::1' /etc/wireguard/wg0.conf && echo ', fddd:2c4:2c4:2c4::$octet/128')",
        f"# END_PEER {user}",
        "EOF",
        f"sudo bash -c 'cat >> ~/{user}.conf' << EOF",
        "[Interface]",
        "Address = 10.7.0.$octet/24$(sudo grep -q 'fddd:2c4:2c4:2c4::1' /etc/wireguard/wg0.conf && echo ', fddd:2c4:2c4:2c4::$octet/64')",
        f"DNS = {dns}",
        "PrivateKey = $key",
        " ",
        "[Peer]",
        "PublicKey = $(sudo grep PrivateKey /etc/wireguard/wg0.conf | cut -d ' ' -f 3 | wg pubkey)",
        "PresharedKey = $psk",
        "AllowedIPs = 0.0.0.0/0, ::/0",
        "Endpoint = $(sudo grep '^# ENDPOINT' /etc/wireguard/wg0.conf | cut -d ' ' -f 3):$(sudo grep ListenPort /etc/wireguard/wg0.conf | cut -d ' ' -f 3)",
        "PersistentKeepalive = 25",
        "EOF",
        f'''sudo bash -c "wg addconf wg0 <(sed -n '/^# BEGIN_PEER {user}/,/^# END_PEER {user}/p' /etc/wireguard/wg0.conf)"''',
    ]

    processRSA = Popen(
        "/bin/bash",
        shell=False,
        universal_newlines=True,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    processRSA.communicate("\n".join(commandsRSA))


def getConfig(user):
    commands = [
        f"sudo cat /root/{user}.conf",
    ]

    process = Popen(
        "/bin/bash",
        shell=False,
        universal_newlines=True,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    config, err = process.communicate("\n".join(commands))

    return config


def listUsers():
    commands = ['sudo grep "^# BEGIN_PEER" /etc/wireguard/wg0.conf | cut -d " " -f 3']
    process = Popen(
        "/bin/bash",
        shell=False,
        universal_newlines=True,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    users, err = process.communicate("\n".join(commands))

    return [user for user in users.split("\n") if user]


def removeUser(user):
    if user not in listUsers():
        return

    commands = [
        f"""sudo bash -c 'wg set wg0 peer "$(sed -n "/^# BEGIN_PEER {user}$/,\$p" /etc/wireguard/wg0.conf | grep -m 1 PublicKey | cut -d " " -f 3)" remove'""",
        f"sudo sed -i '/^# BEGIN_PEER {user}$/,/^# END_PEER {user}$/d' /etc/wireguard/wg0.conf",
    ]
    process = Popen(
        "/bin/bash",
        shell=False,
        universal_newlines=True,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
    )
    process.communicate("\n".join(commands))
