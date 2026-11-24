#Requires -Version 7.2
<#
.SYNOPSIS
    Recálculo completo de StockActual, UltimoPrecio, UltimoProveedor y FechaStock de todos los
    artículos (T-16, D-19). Sirve para la carga inicial, a final de año y antes de cada recuento.

.DESCRIPTION
    Lee (solo lectura) ARTICULOS ALMACEN y todas las filas de ENTRADAS ALMACEN y calcula, con las
    mismas reglas que el flujo StockTotalesArticulo (stock/flujo-StockTotales.md):
      StockActual     = Σ CANTIDAD − Σ CANTIDADSALIDA, redondeado a 3 decimales (vacío = 0)
      UltimoPrecio    = PRECIO × (1 − DESCUENTO), redondeado a 4 decimales, de la fila más reciente
                        (FECHA y, si empatan, ID) con CANTIDAD > 0 y proveedor distinto de
                        STOCK synergy. Si no hay ninguna, vacío.
      UltimoProveedor = proveedor de esa fila
    Las filas de ENTRADAS ALMACEN se enlazan por el ID del lookup CODIGO, que apunta siempre a
    ARTICULOS ALMACEN (la real). En la lista de destino los artículos se buscan por CODIGO.

    Solo escribe los artículos en que cambia el stock, el precio o el proveedor (la misma
    condición que el flujo), y entonces pone FechaStock a la hora actual. Escribe en lotes y con
    SystemUpdate: no crea versiones ni cambia «Modificado» ni «Modificado por».

    Con -Destino Prueba (por defecto) escribe en ARTICULOS ALMACEN PRUEBA; con -Destino Real, en
    ARTICULOS ALMACEN. Sin -Confirmar solo muestra lo que haría. En los dos casos deja la lista de
    cambios en archivos/recalculo-<Destino>-<fecha>.csv (es-ES, no se sube al repositorio).

.EXAMPLE
    ./06-Recalcular-Stock.ps1                              # simulación sobre la prueba
    ./06-Recalcular-Stock.ps1 -Confirmar                   # escribe en la prueba
    ./06-Recalcular-Stock.ps1 -Destino Real                # simulación sobre la real
    ./06-Recalcular-Stock.ps1 -Destino Real -Confirmar     # carga inicial / recálculo real
    ./06-Recalcular-Stock.ps1 -Destino Real -Codigos 8110,0000
#>
param(
    [ValidateSet('Prueba', 'Real')] [string] $Destino = 'Prueba',
    [string[]] $Codigos = @(),
    [switch] $Confirmar
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Conectar.ps1"

$Origen = 'ARTICULOS ALMACEN'
$Lista = if ($Destino -eq 'Prueba') { 'ARTICULOS ALMACEN PRUEBA' } else { 'ARTICULOS ALMACEN' }
$IdStockSynergy = 626   # PROVEEDORES: STOCK synergy (docs/estructura-tablas.md)
$es = [Globalization.CultureInfo]::GetCultureInfo('es-ES')
$Salida = Join-Path $PSScriptRoot '..\archivos'
New-Item -ItemType Directory -Force $Salida | Out-Null

$faltan = @('StockActual', 'UltimoPrecio', 'UltimoProveedor', 'FechaStock') |
    Where-Object { -not (Get-PnPField -List $Lista -Identity $_ -ErrorAction SilentlyContinue) }
if ($faltan) { throw "$Lista no tiene las columnas $($faltan -join ', '). Créalas antes con ./03-Columnas-Listas.ps1 -Destino $Destino -Confirmar" }

function Num($v) { if ($null -eq $v -or "$v" -eq '') { 0.0 } else { [double]$v } }
function NumONulo($v) { if ($null -eq $v -or "$v" -eq '') { $null } else { [double]$v } }

# --- 1. Artículos de origen: ID del lookup -> código ------------------------------------------
Write-Host "Leyendo $Origen..." -ForegroundColor DarkGray
$idPorCodigo = @{}
Get-PnPListItem -List $Origen -PageSize 2000 -Fields CODIGO | ForEach-Object {
    $c = "$($_['CODIGO'])".Trim()
    if ($c) { $idPorCodigo[$c] = $_.Id }
}
Write-Host "  $($idPorCodigo.Count) artículos" -ForegroundColor DarkGray

# --- 2. Movimientos: acumulado por artículo ---------------------------------------------------
Write-Host "Leyendo ENTRADAS ALMACEN (tarda un poco)..." -ForegroundColor DarkGray
$calc = @{}   # IdArt -> @{ Entrada; Salida; Ultima }
$filas = 0
Get-PnPListItem -List 'ENTRADAS ALMACEN' -PageSize 2000 -Fields CODIGO, CANTIDAD, CANTIDADSALIDA, PRECIO, DESCUENTO, PROVEEDOR, FECHA |
    ForEach-Object {
        $c = $_['CODIGO']
        if (-not $c) { return }
        $filas++
        $id = $c.LookupId
        if (-not $calc.ContainsKey($id)) { $calc[$id] = [pscustomobject]@{ Entrada = 0.0; Salida = 0.0; Ultima = $null } }
        $a = $calc[$id]
        $ent = Num $_['CANTIDAD']
        $a.Entrada += $ent
        $a.Salida += Num $_['CANTIDADSALIDA']
        $p = $_['PROVEEDOR']
        $provId = if ($p) { $p.LookupId } else { 0 }
        if ($ent -gt 0 -and $provId -ne $IdStockSynergy) {
            $fecha = $_['FECHA']
            $u = $a.Ultima
            # Más reciente por FECHA y, si empatan, por ID (como la clave k del flujo).
            if (-not $u -or $fecha -gt $u.Fecha -or ($fecha -eq $u.Fecha -and $_.Id -gt $u.Id)) {
                $a.Ultima = [pscustomobject]@{
                    Id        = $_.Id
                    Fecha     = $fecha
                    Precio    = [math]::Round((Num $_['PRECIO']) * (1 - (Num $_['DESCUENTO'])), 4, [MidpointRounding]::AwayFromZero)
                    Proveedor = if ($p) { $p.LookupValue } else { $null }
                }
            }
        }
    }
Write-Host "  $filas filas con código, $($calc.Count) artículos con movimientos" -ForegroundColor DarkGray

# --- 3. Lista de destino: comparar ------------------------------------------------------------
Write-Host "Leyendo $Lista..." -ForegroundColor DarkGray
$filasDestino = @(Get-PnPListItem -List $Lista -PageSize 2000 -Fields CODIGO, StockActual, UltimoPrecio, UltimoProveedor, FechaStock)
if ($Codigos) { $filasDestino = @($filasDestino | Where-Object { "$($_['CODIGO'])".Trim() -in $Codigos }) }
Write-Host "  $($filasDestino.Count) artículos a revisar" -ForegroundColor DarkGray

$cambios = [Collections.Generic.List[object]]::new()
$sinOrigen = 0
foreach ($d in $filasDestino) {
    $codigo = "$($d['CODIGO'])".Trim()
    if (-not $idPorCodigo.ContainsKey($codigo)) { $sinOrigen++; Write-Warning "El código '$codigo' (ID $($d.Id)) no está en $Origen."; continue }
    $a = $calc[$idPorCodigo[$codigo]]
    $stock = if ($a) { [math]::Round($a.Entrada - $a.Salida, 3, [MidpointRounding]::AwayFromZero) } else { 0.0 }
    $precio = if ($a -and $a.Ultima) { $a.Ultima.Precio } else { $null }
    $prov = if ($a -and $a.Ultima) { $a.Ultima.Proveedor } else { $null }

    # Misma condición que el paso 1.8 del flujo.
    $stockG = NumONulo $d['StockActual']
    $precioG = NumONulo $d['UltimoPrecio']
    $provG = "$($d['UltimoProveedor'])"
    $cambia = ($null -eq $stockG -or $stockG -ne $stock) -or
              ((($precioG ?? -1)) -ne ($precio ?? -1)) -or
              ($provG -ne "$prov")
    if (-not $cambia) { continue }

    $cambios.Add([pscustomobject]@{
        Id              = $d.Id
        CODIGO          = $codigo
        StockAntes      = if ($null -ne $stockG) { $stockG.ToString('0.###', $es) } else { '' }
        StockNuevo      = $stock.ToString('0.###', $es)
        PrecioAntes     = if ($null -ne $precioG) { $precioG.ToString('0.0000', $es) } else { '' }
        PrecioNuevo     = if ($null -ne $precio) { $precio.ToString('0.0000', $es) } else { '' }
        ProveedorAntes  = $provG
        ProveedorNuevo  = "$prov"
        _Stock          = $stock
        _Precio         = $precio
        _Proveedor      = $prov
    })
}

$csv = Join-Path $Salida ("recalculo-{0}-{1}.csv" -f $Destino, (Get-Date -Format 'yyyyMMdd-HHmm'))
$cambios | Select-Object Id, CODIGO, StockAntes, StockNuevo, PrecioAntes, PrecioNuevo, ProveedorAntes, ProveedorNuevo |
    Export-Csv $csv -Delimiter ';' -Encoding utf8BOM
$cambios | Select-Object -First 25 | Format-Table CODIGO, StockAntes, StockNuevo, PrecioAntes, PrecioNuevo, ProveedorNuevo -AutoSize | Out-Host
if ($cambios.Count -gt 25) { Write-Host "  … y $($cambios.Count - 25) más (ver CSV)" -ForegroundColor DarkGray }

Write-Host "`n$($filasDestino.Count) revisados, $($cambios.Count) cambian, $($filasDestino.Count - $cambios.Count - $sinOrigen) ya estaban bien, $sinOrigen sin artículo de origen" -ForegroundColor Cyan
Write-Host "Cambios guardados en $csv" -ForegroundColor Green

if (-not $Confirmar) {
    Write-Host "Simulación: no se ha escrito nada en $Lista. Para aplicar: añade -Confirmar" -ForegroundColor Yellow
    return
}
if ($cambios.Count -eq 0) { return }

# --- 4. Escribir en lotes ---------------------------------------------------------------------
$ahora = (Get-Date).ToUniversalTime()
$tam = 100
for ($i = 0; $i -lt $cambios.Count; $i += $tam) {
    $lote = New-PnPBatch
    foreach ($c in $cambios[$i..([math]::Min($i + $tam, $cambios.Count) - 1)]) {
        $v = @{
            StockActual     = $c._Stock
            UltimoPrecio    = $c._Precio
            UltimoProveedor = $c._Proveedor
            FechaStock      = $ahora
        }
        Set-PnPListItem -List $Lista -Identity $c.Id -Values $v -UpdateType SystemUpdate -Batch $lote | Out-Null
    }
    Invoke-PnPBatch -Batch $lote
    Write-Host ("  Escritos {0} de {1}" -f ([math]::Min($i + $tam, $cambios.Count)), $cambios.Count) -ForegroundColor DarkGray
}
Write-Host "`nHecho: $($cambios.Count) artículos actualizados en $Lista." -ForegroundColor Green
