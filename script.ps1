#Write-Host "Delete any existing WinRM listeners"
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

#Write-Host "Create a new WinRM listener and configure"
winrm create winrm/config/listener?Address=*+Transport=HTTP
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

#Write-Host "Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

#Write-Host "turn off PowerShell execution policy restrictions"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

#Write-Host "Configure and restart the WinRM Service; Enable the required firewall exception"
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
Start-Service -Name WinRM


#Now WSL
#
# STEP 1: Enable Virtual Machine Platform feature
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# STEP 2: Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# STEP 3: download Kali
Invoke-WebRequest -Uri https://aka.ms/wsl-kali-linux-new -OutFile kali.appx -UseBasicParsing

# STEP 4: Kali Application
Add-AppxPackage .\kali.appx

# STEP 5: To set the WSL default version to 2.
# Any distribution installed after this, would run on WSL 2
wsl --set-default-version 2

# STEP 4:
#wsl --install -d kali-linux


