#Requires -Version 7.2
<#
.SYNOPSIS
    Copia artículos de muestra de ARTICULOS ALMACEN a ARTICULOS ALMACEN PRUEBA y calcula su stock
    y último precio esperados, para probar los flujos StockTotales (T-12, V-0.1, V-0.2).

.DESCRIPTION
    Lee (solo lectura) ARTICULOS ALMACEN y todas las filas de ENTRADAS ALMACEN, y elige unos 20
    artículos que cubren los casos del cálculo:
      A  Compras de varios proveedores y salidas de STOCK synergy (último precio, V-0.2)  6
      B  Solo compras directas a Job (entrada = salida en la misma fila)                  3
      C  Stock negativo                                                                   3
      D  Sin compras reales (último precio vacío)                                         2
      E  En kg (MACIZOS, CHAPA, PLETINAS)                                                 3
      F  Con muchos movimientos                                                           2
      G  Sin ningún movimiento (stock 0)                                                  1
    La elección es siempre la misma (semilla fija). Con -Codigos se añaden artículos concretos.

    Copia CODIGO, CONCEPTO, CONCEPTO2, Campo1 (LUGAR), LUGAR (GRUPO), LUGAR0 y MEDIDA. No rellena
    StockActual ni UltimoPrecio: eso lo hará el flujo. Los códigos que ya están en la prueba se saltan.

    Deja en archivos/esperado-ARTICULOS_PRUEBA.csv (formato es-ES, no se sube al repositorio) el
    stock y el último precio esperados, calculados con las reglas de docs/modelo-datos.md:
      StockActual  = Σ CANTIDAD − Σ CANTIDADSALIDA
      UltimoPrecio = PRECIO × (1 − DESCUENTO) de la fila más reciente (FECHA, luego ID) con
                     CANTIDAD > 0 y proveedor distinto de STOCK synergy
    Sin -Confirmar no escribe en SharePoint (el CSV sí se genera).

.EXAMPLE
    ./04-Copiar-Articulos-Prueba.ps1                          # simulación + CSV
    ./04-Copiar-Articulos-Prueba.ps1 -Confirmar
    ./04-Copiar-Articulos-Prueba.ps1 -Codigos 8331412 -Confirmar
#>
param(
    [string[]] $Codigos = @(),
    [switch] $Confirmar
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Conectar.ps1"

$Origen = 'ARTICULOS ALMACEN'
$Destino = 'ARTICULOS ALMACEN PRUEBA'
$IdStockSynergy = 626   # PROVEEDORES: STOCK synergy (docs/estructura-tablas.md)
$es = [Globalization.CultureInfo]::GetCultureInfo('es-ES')
$Salida = Join-Path $PSScriptRoot '..\archivos'
New-Item -ItemType Directory -Force $Salida | Out-Null

function Num($v) { if ($null -eq $v -or "$v" -eq '') { 0.0 } else { [double]$v } }

# --- 1. Artículos ------------------------------------------------------------------------------
$camposArt = 'CODIGO', 'CONCEPTO', 'CONCEPTO2', 'Campo1', 'LUGAR', 'LUGAR0', 'MEDIDA'
Write-Host "Leyendo $Origen..." -ForegroundColor DarkGray
$articulos = @{}
Get-PnPListItem -List $Origen -PageSize 2000 -Fields $camposArt | ForEach-Object { $articulos[$_.Id] = $_ }
Write-Host "  $($articulos.Count) artículos" -ForegroundColor DarkGray

# --- 2. Movimientos ----------------------------------------------------------------------------
$camposMov = 'CODIGO', 'CANTIDAD', 'CANTIDADSALIDA', 'PRECIO', 'DESCUENTO', 'PROVEEDOR', 'FECHA'
Write-Host "Leyendo ENTRADAS ALMACEN (tarda un poco)..." -ForegroundColor DarkGray
$movs = @{}
$sinCodigo = 0
$descMax = 0.0
Get-PnPListItem -List 'ENTRADAS ALMACEN' -PageSize 2000 -Fields $camposMov | ForEach-Object {
    $c = $_['CODIGO']
    if (-not $c) { $sinCodigo++; return }
    $p = $_['PROVEEDOR']
    $d = Num $_['DESCUENTO']
    if ($d -gt $descMax) { $descMax = $d }
    $fila = [pscustomobject]@{
        Id        = $_.Id
        Entrada   = Num $_['CANTIDAD']
        Salida    = Num $_['CANTIDADSALIDA']
        Precio    = Num $_['PRECIO']
        Descuento = $d
        ProvId    = if ($p) { $p.LookupId } else { 0 }
        Proveedor = if ($p) { $p.LookupValue } else { '' }
        Fecha     = $_['FECHA']
    }
    if (-not $movs.ContainsKey($c.LookupId)) { $movs[$c.LookupId] = [Collections.Generic.List[object]]::new() }
    $movs[$c.LookupId].Add($fila)
}
$total = ($movs.Values | Measure-Object Count -Sum).Sum
Write-Host "  $total filas con código, $sinCodigo sin código, $($movs.Count) artículos con movimientos" -ForegroundColor DarkGray
if ($descMax -gt 1) { Write-Warning "Hay DESCUENTO mayor que 1 ($descMax): revisar si se guarda en tanto por uno o en %." }

# --- 3. Resumen por artículo -------------------------------------------------------------------
function Get-Resumen([int]$IdArt) {
    $f = if ($movs.ContainsKey($IdArt)) { $movs[$IdArt] } else { @() }
    $compras = @($f | Where-Object { $_.Entrada -gt 0 -and $_.ProvId -ne $IdStockSynergy } |
        Sort-Object @{ e = { $_.Fecha } }, Id)
    $ultima = if ($compras) { $compras[-1] } else { $null }
    [pscustomobject]@{
        IdArt       = $IdArt
        Filas       = @($f).Count
        Stock       = (($f | Measure-Object Entrada -Sum).Sum ?? 0) - (($f | Measure-Object Salida -Sum).Sum ?? 0)
        Proveedores = @($compras | Select-Object -ExpandProperty ProvId -Unique).Count
        ConSS       = [bool]@($f | Where-Object { $_.ProvId -eq $IdStockSynergy -and $_.Salida -gt 0 }).Count
        SoloDirecta = (@($f).Count -gt 0) -and -not @($f | Where-Object { -not ($_.Entrada -gt 0 -and $_.Entrada -eq $_.Salida) }).Count
        Ultima      = $ultima
    }
}
$resumen = @{}
foreach ($id in $articulos.Keys) { $resumen[$id] = Get-Resumen $id }

# --- 4. Elección -------------------------------------------------------------------------------
$elegidos = [Collections.Generic.Dictionary[int,string]]::new()   # IdArt -> categoría (orden de inserción)
$aleatorio = [Random]::new(20261121)
function Add-Categoria([string]$Cat, [int]$N, [scriptblock]$Filtro) {
    $cand = @($resumen.Values | Where-Object { -not $elegidos.ContainsKey($_.IdArt) } | Where-Object $Filtro | Sort-Object IdArt)
    $toma = @($cand | Sort-Object { $aleatorio.Next() } | Select-Object -First $N)
    foreach ($r in $toma) { $elegidos[$r.IdArt] = $Cat }
    Write-Host ("  {0,-28} {1,2} de {2} candidatos" -f $Cat, $toma.Count, $cand.Count)
}
$kg = 'kg', 'kgs'
$grupoKg = 'MACIZOS', 'CHAPA', 'PLETINAS', 'CHAPA JUMEC', 'CHAPA OTROS'
Write-Host "`nElección" -ForegroundColor Cyan
Add-Categoria 'A varios proveedores + SS' 6 { $_.Proveedores -ge 2 -and $_.ConSS -and $_.Filas -le 60 }
Add-Categoria 'B solo compra directa'     3 { $_.SoloDirecta -and $_.Filas -ge 2 }
Add-Categoria 'C stock negativo'          3 { $_.Stock -lt 0 }
Add-Categoria 'D sin compras reales'      2 { $_.Filas -gt 0 -and -not $_.Ultima }
Add-Categoria 'E en kg'                   3 { "$($articulos[$_.IdArt]['MEDIDA'])".Trim().ToLower() -in $kg -and "$($articulos[$_.IdArt]['LUGAR'])".Trim() -in $grupoKg -and $_.Filas -gt 0 }
$muchos = @($resumen.Values | Where-Object { -not $elegidos.ContainsKey($_.IdArt) } | Sort-Object Filas -Descending | Select-Object -First 2)
foreach ($r in $muchos) { $elegidos[$r.IdArt] = 'F muchos movimientos' }
Write-Host ("  {0,-28} {1,2} (los de más filas: {2})" -f 'F muchos movimientos', $muchos.Count, (($muchos | ForEach-Object Filas) -join ', '))
Add-Categoria 'G sin movimientos'         1 { $_.Filas -eq 0 }
foreach ($c in $Codigos) {
    $a = $articulos.Values | Where-Object { "$($_['CODIGO'])".Trim() -eq $c } | Select-Object -First 1
    if ($a) { $elegidos[$a.Id] = 'H pedido a mano' } else { Write-Warning "El código $c no existe en $Origen." }
}

# --- 5. CSV con lo esperado --------------------------------------------------------------------
$filasCsv = foreach ($id in $elegidos.Keys) {
    $a = $articulos[$id]; $r = $resumen[$id]; $u = $r.Ultima
    [pscustomobject]@{
        Categoria             = $elegidos[$id]
        CODIGO                = "$($a['CODIGO'])".Trim()
        CONCEPTO              = "$($a['CONCEPTO'])".Trim()
        MEDIDA                = "$($a['MEDIDA'])".Trim()
        Filas                 = $r.Filas
        StockEsperado         = $r.Stock.ToString('0.###', $es)
        UltimoPrecioEsperado  = if ($u) { ($u.Precio * (1 - $u.Descuento)).ToString('0.0000', $es) } else { '' }
        UltimoProveedor       = if ($u) { $u.Proveedor } else { '' }
        FechaUltimaCompra     = if ($u -and $u.Fecha) { ([datetime]$u.Fecha).ToLocalTime().ToString('dd/MM/yyyy', $es) } else { '' }
        IdUltimaCompra        = if ($u) { $u.Id } else { '' }
    }
}
$csv = Join-Path $Salida 'esperado-ARTICULOS_PRUEBA.csv'
$filasCsv | Export-Csv $csv -Delimiter ';' -Encoding utf8BOM
$filasCsv | Format-Table Categoria, CODIGO, MEDIDA, Filas, StockEsperado, UltimoPrecioEsperado, UltimoProveedor -AutoSize | Out-Host
Write-Host "Esperado guardado en $csv" -ForegroundColor Green

# --- 6. Copia a la prueba ----------------------------------------------------------------------
$yaEstan = @{}
Get-PnPListItem -List $Destino -PageSize 2000 -Fields CODIGO | ForEach-Object { $yaEstan["$($_['CODIGO'])".Trim()] = $true }
$nuevos = @($elegidos.Keys | Where-Object { -not $yaEstan["$($articulos[$_]['CODIGO'])".Trim()] })
Write-Host "`n$($elegidos.Count) elegidos, $($elegidos.Count - $nuevos.Count) ya están en $Destino, $($nuevos.Count) por copiar" -ForegroundColor Cyan

if (-not $Confirmar) {
    Write-Host "Simulación: no se ha copiado nada. Para aplicar: ./04-Copiar-Articulos-Prueba.ps1 -Confirmar" -ForegroundColor Yellow
    return
}
foreach ($id in $nuevos) {
    $a = $articulos[$id]
    $v = @{}
    foreach ($c in $camposArt) { if ("$($a[$c])".Trim()) { $v[$c] = "$($a[$c])".Trim() } }
    Add-PnPListItem -List $Destino -Values $v | Out-Null
    Write-Host "  + $($v['CODIGO'])  $($v['CONCEPTO'])" -ForegroundColor Cyan
}
Write-Host "`nHecho: $($nuevos.Count) artículos copiados a $Destino." -ForegroundColor Green
