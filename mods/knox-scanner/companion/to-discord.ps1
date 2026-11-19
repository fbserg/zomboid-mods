# Posts each new Knox Scanner line to a Discord webhook. Leave it running while you play.
# Usage: .\to-discord.ps1 https://discord.com/api/webhooks/...
param([Parameter(Mandatory)][string]$Webhook)
$feed = "$env:USERPROFILE\Zomboid\Lua\KnoxScanner.txt"
if (-not (Test-Path $feed)) { New-Item $feed | Out-Null }
Get-Content $feed -Wait -Tail 0 | ForEach-Object {
  Invoke-RestMethod -Uri $Webhook -Method Post -ContentType 'application/json; charset=utf-8' -Body $_
}
