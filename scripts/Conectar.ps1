#Requires -Version 7.2
# Conecta con el sitio de config.psd1. Los demás scripts lo cargan con ". $PSScriptRoot\Conectar.ps1".

$ErrorActionPreference = 'Stop'
Import-Module PnP.PowerShell

$Config = Import-PowerShellDataFile "$PSScriptRoot\config.psd1"
if ($Config.SiteUrl -match 'CAMBIAR') { throw 'Rellena SiteUrl en config.psd1.' }
if (-not $Config.ClientId) { throw 'Rellena ClientId en config.psd1 (lo da 00-Registrar-App.ps1).' }

Connect-PnPOnline -Url $Config.SiteUrl -ClientId $Config.ClientId -Interactive
$Usuario = Get-PnPProperty -ClientObject (Get-PnPWeb) -Property CurrentUser
Write-Host "Conectado a $($Config.SiteUrl) como $($Usuario.LoginName)" -ForegroundColor Green
