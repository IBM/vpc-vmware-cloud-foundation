Content-Type: multipart/mixed; boundary="MIMEBOUNDARY"
MIME-Version: 1.0


--MIMEBOUNDARY
Content-Transfer-Encoding: 7bit
Content-Type: text/cloud-config
MIME-Version: 1.0

#cloud-config
set_timezone: US/Eastern


--MIMEBOUNDARY
Content-Disposition: attachment; filename="initial.ps1"
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
MIME-Version: 1.0

#ps1_sysnative
Set-DnsClientGlobalSetting -SuffixSearchList @("${dns_suffix_list}")


--MIMEBOUNDARY
Content-Disposition: attachment; filename="install-software.ps1"
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
MIME-Version: 1.0

#ps1_sysnative
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install notepadplusplus -y
choco install vmware-powercli-psmodule -y
choco install firefox -y
choco install googlechrome -y
choco install mremoteng -y
choco install winscp -y
choco install putty -y
choco install wireshark -y
choco install govc -y
choco install terraform -y


--MIMEBOUNDARY
Content-Disposition: attachment; filename="openssh.ps1"
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
MIME-Version: 1.0

#ps1_sysnative
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22


--MIMEBOUNDARY
Content-Disposition: attachment; filename="update-os.ps1"
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
MIME-Version: 1.0

#ps1_sysnative
Install-Module PSWindowsUpdate -Confirm:$false -Force
Get-WindowsUpdate
Install-WindowsUpdate -Confirm:$false -AcceptAll -AutoReboot
shutdown -r -t 0

