#Requires -Version 7.2
<#
.SYNOPSIS
    Columnas nuevas de ARTICULOS ALMACEN y listas nuevas MATERIALES y ADMIN ALMACEN (T-12).

.DESCRIPTION
    Con -Destino Prueba (por defecto) trabaja sobre copias de prueba:
      - ARTICULOS ALMACEN PRUEBA: se crea si no existe, con las columnas que usa la app de
        ARTICULOS ALMACEN y los mismos nombres internos (CODIGO, CONCEPTO, CONCEPTO2, Campo1 = LUGAR,
        LUGAR = GRUPO, LUGAR0 = ORIGEN CODIGO, MEDIDA). No copia artículos.
      - MATERIALES PRUEBA y ADMIN ALMACEN PRUEBA.
    Con -Destino Real trabaja sobre ARTICULOS ALMACEN (solo AÑADE columnas; no toca las existentes)
    y crea MATERIALES y ADMIN ALMACEN.

    Columnas nuevas de ARTICULOS ALMACEN (docs/modelo-datos.md):
      StockActual, UltimoPrecio, UltimoProveedor, FechaStock, StockMinimo,
      Material (lookup → MATERIALES), Forma (elección), Medida1, Medida2.
    MATERIALES: Title + PesoEspecifico. ADMIN ALMACEN: Title (correo, en minúsculas).

    Lo que ya existe no se toca, así que se puede volver a lanzar. Sin -Confirmar solo muestra
    lo que haría. Las listas nuevas se crean vacías: los pesos (T-04) y los correos los
    rellena negocio a mano; los correos no van al repositorio.

.EXAMPLE
    ./03-Columnas-Listas.ps1                             # simulación sobre las copias de prueba
    ./03-Columnas-Listas.ps1 -Confirmar                  # crea las copias de prueba
    ./03-Columnas-Listas.ps1 -Destino Real               # simulación sobre las listas reales
    ./03-Columnas-Listas.ps1 -Destino Real -Confirmar    # aplica en las listas reales
#>
param(
    [ValidateSet('Prueba', 'Real')] [string] $Destino = 'Prueba',
    [switch] $Confirmar
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Conectar.ps1"

$sufijo = if ($Destino -eq 'Prueba') { ' PRUEBA' } else { '' }
$sufijoUrl = if ($Destino -eq 'Prueba') { 'Prueba' } else { '' }
$nomArticulos = "ARTICULOS ALMACEN$sufijo"
$nomMateriales = "MATERIALES$sufijo"
$nomAdmin = "ADMIN ALMACEN$sufijo"

# --- Utilidades -------------------------------------------------------------------------------

# XML de una columna. El nombre visible se pone después, para que el interno sea exactamente $Nombre.
function Campo([string]$Tipo, [string]$Nombre, [hashtable]$Atributos = @{}, [string]$Interior = '') {
    $attrs = [ordered]@{ ID = "{$([guid]::NewGuid())}"; Type = $Tipo; Name = $Nombre; StaticName = $Nombre; DisplayName = $Nombre; Required = 'FALSE' }
    foreach ($k in $Atributos.Keys) { $attrs[$k] = $Atributos[$k] }
    $a = ($attrs.GetEnumerator() | ForEach-Object { "$($_.Key)=`"$([Security.SecurityElement]::Escape([string]$_.Value))`"" }) -join ' '
    if ($Interior) { "<Field $a>$Interior</Field>" } else { "<Field $a />" }
}

function Get-Lista([string]$Titulo) {
    Get-PnPList | Where-Object Title -eq $Titulo | Select-Object -First 1
}

# Crea la lista si no existe. En simulación devuelve $null si no existe.
function New-Lista([string]$Titulo, [string]$Url) {
    $l = Get-Lista $Titulo
    if ($l) { Write-Host "`n$Titulo (ya existe, $($l.ItemCount) elementos)" -ForegroundColor Cyan; return $l }
    if (-not $Confirmar) { Write-Host "`n$Titulo se crearía en Lists/$Url (simulación)" -ForegroundColor Yellow; return $null }
    New-PnPList -Title $Titulo -Url "Lists/$Url" -Template GenericList -OnQuickLaunch:$false | Out-Null
    Write-Host "`n$Titulo creada en Lists/$Url" -ForegroundColor Cyan
    Get-Lista $Titulo
}

# Añade la columna si no existe y le pone el nombre visible.
function Add-Campo($ListaObj, [string]$Xml, [string]$Visible) {
    $nombre = ([xml]$Xml).Field.Name
    $txt = if ($Visible -and $Visible -ne $nombre) { "$nombre («$Visible»)" } else { $nombre }
    if (-not $ListaObj) { Write-Host "    + $txt (simulación)" -ForegroundColor Yellow; return }
    if (Get-PnPField -List $ListaObj | Where-Object InternalName -eq $nombre) { Write-Host "    = $txt ya existe" -ForegroundColor DarkGray; return }
    if (-not $Confirmar) { Write-Host "    + $txt (simulación)" -ForegroundColor Yellow; return }
    Add-PnPFieldFromXml -List $ListaObj -FieldXml $Xml | Out-Null
    $creado = Get-PnPField -List $ListaObj -Identity ([guid]([xml]$Xml).Field.ID)
    if ($creado.InternalName -ne $nombre) { throw "La columna '$nombre' se ha creado con nombre interno '$($creado.InternalName)'." }
    if ($Visible -and $Visible -ne $nombre) { Set-PnPField -List $ListaObj -Identity $nombre -Values @{ Title = $Visible } | Out-Null }
    Write-Host "    + $txt" -ForegroundColor Cyan
}

# --- 1. MATERIALES ------------------------------------------------------------------------------
$lMat = New-Lista $nomMateriales "Materiales$sufijoUrl"
Add-Campo $lMat (Campo Number PesoEspecifico @{ Decimals = '3'; Min = '0' }) 'Peso específico'

# --- 2. ADMIN ALMACEN ---------------------------------------------------------------------------
$lAdm = New-Lista $nomAdmin "AdminAlmacen$sufijoUrl"
if ($lAdm) { Write-Host "    = Title (correo en minúsculas, una fila por cuenta)" -ForegroundColor DarkGray }

# --- 3. ARTICULOS ALMACEN -----------------------------------------------------------------------
if ($Destino -eq 'Prueba') {
    $lArt = New-Lista $nomArticulos 'ArticulosAlmacenPrueba'
    # En la lista real Title no es obligatorio (no se usa): igual en la copia.
    if ($lArt -and (Get-PnPField -List $lArt -Identity Title).Required) {
        if ($Confirmar) { Set-PnPField -List $lArt -Identity Title -Values @{ Required = $false } | Out-Null; Write-Host "    ~ Title ya no es obligatorio" -ForegroundColor Cyan }
        else { Write-Host "    ~ Title dejaría de ser obligatorio (simulación)" -ForegroundColor Yellow }
    }
    # Columnas existentes de ARTICULOS ALMACEN que usa la app, con los mismos nombres internos.
    Add-Campo $lArt (Campo Text CODIGO @{ Required = 'TRUE'; MaxLength = '255'; Indexed = 'TRUE' }) 'CODIGO'
    Add-Campo $lArt (Campo Text CONCEPTO @{ Required = 'TRUE'; MaxLength = '255'; Indexed = 'TRUE' }) 'CONCEPTO'
    Add-Campo $lArt (Campo Note CONCEPTO2 @{ NumLines = '6'; RichText = 'FALSE' }) 'CONCEPTO 2'
    Add-Campo $lArt (Campo Text Campo1 @{ MaxLength = '255' }) 'LUGAR'
    Add-Campo $lArt (Campo Text LUGAR @{ MaxLength = '255' }) 'GRUPO'
    Add-Campo $lArt (Campo Text LUGAR0 @{ MaxLength = '255' }) 'ORIGEN CODIGO'
    Add-Campo $lArt (Campo Text MEDIDA @{ MaxLength = '255' }) 'MEDIDA'
} else {
    $lArt = Get-Lista $nomArticulos
    if (-not $lArt) { throw "No existe la lista $nomArticulos." }
    Write-Host "`n$nomArticulos ($($lArt.ItemCount) elementos): solo se añaden columnas" -ForegroundColor Cyan
}

# Columnas nuevas (docs/modelo-datos.md)
Add-Campo $lArt (Campo Number StockActual @{ Decimals = '3' }) 'Stock actual'
Add-Campo $lArt (Campo Number UltimoPrecio @{ Decimals = '4' }) 'Último precio'
Add-Campo $lArt (Campo Text UltimoProveedor @{ MaxLength = '255' }) 'Último proveedor'
Add-Campo $lArt (Campo DateTime FechaStock @{ Format = 'DateTime' }) 'Fecha stock'
Add-Campo $lArt (Campo Number StockMinimo @{ Decimals = '3'; Min = '0' }) 'Stock mínimo'
if ($lMat) {
    Add-Campo $lArt (Campo Lookup Material @{ List = "{$($lMat.Id)}"; ShowField = 'Title' }) 'Material'
} else {
    Write-Host "    + Material («Material», lookup → $nomMateriales) (simulación)" -ForegroundColor Yellow
}
$formas = 'PLANCHA', 'REDONDO', 'CUADRADO', 'PLETINA', 'HEXAGONAL', 'TUBO'
$choices = '<CHOICES>' + (($formas | ForEach-Object { "<CHOICE>$_</CHOICE>" }) -join '') + '</CHOICES>'
Add-Campo $lArt (Campo Choice Forma @{ Format = 'Dropdown'; FillInChoice = 'FALSE' } $choices) 'Forma'
Add-Campo $lArt (Campo Number Medida1 @{ Decimals = '2'; Min = '0' }) 'Espesor / Ø (mm)'
Add-Campo $lArt (Campo Number Medida2 @{ Decimals = '2'; Min = '0' }) 'Ancho / pared (mm)'

# --- Fin --------------------------------------------------------------------------------------
$param = if ($Destino -eq 'Real') { ' -Destino Real' } else { '' }
if (-not $Confirmar) { Write-Host "`nSimulación ($Destino): no se ha cambiado nada. Para aplicar: ./03-Columnas-Listas.ps1$param -Confirmar" -ForegroundColor Yellow }
else { Write-Host "`nHecho ($Destino)." -ForegroundColor Green }
