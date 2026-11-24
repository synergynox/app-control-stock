#Requires -Version 7.2
<#
.SYNOPSIS
    SOLO LECTURA. Compara el stock y el último precio que ha guardado el flujo en
    ARTICULOS ALMACEN PRUEBA con lo esperado (V-0.1, V-0.2).

.DESCRIPTION
    Lee archivos/esperado-ARTICULOS_PRUEBA.csv (lo genera 04-Copiar-Articulos-Prueba.ps1) y,
    para cada código, compara con ARTICULOS ALMACEN PRUEBA:
      - StockActual      (tolerancia 0,001)
      - UltimoPrecio     (tolerancia 0,0001; vacío = vacío)
      - UltimoProveedor  (texto exacto, sin espacios a los lados)
    Muestra también FechaStock, para ver si el flujo ha pasado por el artículo.

.EXAMPLE
    ./05-Comprobar-Stock-Prueba.ps1
#>
param([string] $Lista = 'ARTICULOS ALMACEN PRUEBA')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Conectar.ps1"

$es = [Globalization.CultureInfo]::GetCultureInfo('es-ES')
$csv = Join-Path $PSScriptRoot '..\archivos\esperado-ARTICULOS_PRUEBA.csv'
if (-not (Test-Path $csv)) { throw "No existe $csv. Lánzalo antes: ./04-Copiar-Articulos-Prueba.ps1" }
$esperado = Import-Csv $csv -Delimiter ';' -Encoding utf8

function Num([string]$s) { if ([string]::IsNullOrWhiteSpace($s)) { $null } else { [double]::Parse($s, $es) } }

$guardado = @{}
Get-PnPListItem -List $Lista -PageSize 2000 -Fields CODIGO, StockActual, UltimoPrecio, UltimoProveedor, FechaStock |
    ForEach-Object { $guardado["$($_['CODIGO'])".Trim()] = $_ }

$fallos = 0
$filas = foreach ($e in $esperado) {
    $g = $guardado[$e.CODIGO]
    $stockE = Num $e.StockEsperado
    $precioE = Num $e.UltimoPrecioEsperado
    $provE = "$($e.UltimoProveedor)".Trim()
    $stockG = if ($g) { $g['StockActual'] } else { $null }
    $precioG = if ($g) { $g['UltimoPrecio'] } else { $null }
    $provG = if ($g) { "$($g['UltimoProveedor'])".Trim() } else { '' }

    $problemas = @()
    if (-not $g) { $problemas += 'no está en la lista' }
    elseif ($null -eq $stockG) { $problemas += 'sin calcular' }
    else {
        if ([math]::Abs([double]$stockG - $stockE) -gt 0.001) { $problemas += 'stock' }
        if (($null -eq $precioE) -ne ($null -eq $precioG)) { $problemas += 'precio' }
        elseif ($null -ne $precioE -and [math]::Abs([double]$precioG - $precioE) -gt 0.0001) { $problemas += 'precio' }
        if ($provG -ne $provE) { $problemas += 'proveedor' }
    }
    if ($problemas) { $fallos++ }
    [pscustomobject]@{
        Resultado      = if ($problemas) { 'FALLA: ' + ($problemas -join ', ') } else { 'OK' }
        CODIGO         = $e.CODIGO
        StockEsperado  = $e.StockEsperado
        StockGuardado  = if ($null -ne $stockG) { ([double]$stockG).ToString('0.###', $es) } else { '' }
        PrecioEsperado = $e.UltimoPrecioEsperado
        PrecioGuardado = if ($null -ne $precioG) { ([double]$precioG).ToString('0.0000', $es) } else { '' }
        FechaStock     = if ($g -and $g['FechaStock']) { ([datetime]$g['FechaStock']).ToLocalTime().ToString('dd/MM/yyyy HH:mm', $es) } else { '' }
    }
}

$filas | Format-Table -AutoSize | Out-Host
if ($fallos -eq 0) { Write-Host "Los $($esperado.Count) artículos coinciden." -ForegroundColor Green }
else {
    Write-Host "$fallos de $($esperado.Count) artículos no coinciden." -ForegroundColor Red
    Write-Host "Si ha habido movimientos nuevos de esos artículos, recalcula el esperado con ./04-Copiar-Articulos-Prueba.ps1 -Recalcular." -ForegroundColor Yellow
    exit 1
}
