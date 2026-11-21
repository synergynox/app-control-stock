#Requires -Version 7.2
<#
.SYNOPSIS
    Índices de columna en ENTRADAS ALMACEN para las búsquedas de la app (T-08).

.DESCRIPTION
    Indexa los lookups por los que filtran el historial del artículo y la búsqueda por proveedor,
    para que las consultas no fallen por el umbral de 5.000 elementos (la lista tiene más de 32.000):
      - ENTRADAS ALMACEN.CODIGO      (lookup → ARTICULOS ALMACEN)
      - ENTRADAS ALMACEN.PROVEEDOR   (lookup → PROVEEDORES)
      - ENTRADAS ALMACEN.PROYECTO    (JOB NUMBER; ya la indexó APP TALLER/scripts/03-Indices.ps1)
    Un índice no cambia columnas ni datos, así que no afecta a App Taller. Lo que ya está
    indexado no se toca. Sin -Confirmar solo muestra lo que haría.
    En listas grandes SharePoint crea el índice en segundo plano: vuelve a lanzar el script
    (sin -Confirmar) al cabo de un rato para comprobar que aparece como indexado.

.EXAMPLE
    ./02-Indices.ps1              # simulación
    ./02-Indices.ps1 -Confirmar   # crea los índices
#>
param([switch] $Confirmar)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Conectar.ps1"

$indices = @(
    @{ Lista = 'ENTRADAS ALMACEN'; Campo = 'CODIGO' }
    @{ Lista = 'ENTRADAS ALMACEN'; Campo = 'PROVEEDOR' }
    @{ Lista = 'ENTRADAS ALMACEN'; Campo = 'PROYECTO' }
)

$pendientes = 0
foreach ($i in $indices) {
    $l = Get-PnPList -Identity $i.Lista -Includes ItemCount
    $f = Get-PnPField -List $l -Identity $i.Campo
    $txt = "$($i.Lista).$($i.Campo) ($($f.Title), $($l.ItemCount) elementos)"
    if ($f.Indexed) { Write-Host "  = $txt ya está indexada" -ForegroundColor DarkGray; continue }
    $pendientes++
    if (-not $Confirmar) { Write-Host "  + $txt se indexaría (simulación)" -ForegroundColor Yellow; continue }
    try {
        Set-PnPField -List $l -Identity $i.Campo -Values @{ Indexed = $true } | Out-Null
        $f = Get-PnPField -List $l -Identity $i.Campo
        if ($f.Indexed) { Write-Host "  + $txt indexada" -ForegroundColor Cyan }
        else { Write-Host "  ~ $txt pedida; SharePoint la está creando en segundo plano" -ForegroundColor Yellow }
    }
    catch {
        Write-Host "  ! $txt no se ha podido indexar: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Alternativa: Configuración de la lista > Columnas indizadas > Crear un nuevo índice." -ForegroundColor Red
    }
}

if ($pendientes -eq 0) { Write-Host "`nTodas las columnas están indexadas." -ForegroundColor Green }
elseif (-not $Confirmar) { Write-Host "`nSimulación: no se ha cambiado nada. Para aplicar: ./02-Indices.ps1 -Confirmar" -ForegroundColor Yellow }
else { Write-Host "`nHecho. Vuelve a lanzarlo sin -Confirmar más tarde para comprobar que salen indexadas." -ForegroundColor Green }
