#Requires -Version 7.2
<#
.SYNOPSIS
    SOLO LECTURA. Muestra el esquema de las listas del almacén (T-01, T-02).

.DESCRIPTION
    - ARTICULOS ALMACEN, PROVEEDORES y ENTRADAS ALMACEN: nombre visible, nombre interno, tipo,
      obligatorio, lista y campo de los lookups e índice.
    - PRECIOS HORAS: solo la columna NOMBRE (no se leen ni muestran otras columnas ni datos).
    - Número de elementos de cada lista.
    - ARTICULOS ALMACEN: valores distintos de LUGAR, GRUPO y MEDIDA, con su recuento.
    - Comprueba si existen los Jobs 1111 y 6969 y el proveedor STOCK synergy (T-03).

    Deja los resultados en archivos/ (no se suben al repositorio).
#>
param(
    [string]$Articulos   = 'ARTICULOS ALMACEN',
    [string]$Proveedores = 'PROVEEDORES',
    [string]$Entradas    = 'ENTRADAS ALMACEN',
    [string]$Trabajadores = 'PRECIOS HORAS'
)

. "$PSScriptRoot\Conectar.ps1"

$Salida = Join-Path $PSScriptRoot '..\archivos'
New-Item -ItemType Directory -Force $Salida | Out-Null

function Get-Esquema([string]$Lista) {
    $l = Get-PnPList -Identity $Lista -Includes ItemCount
    Write-Host "`n== $Lista ($($l.ItemCount) elementos)" -ForegroundColor Cyan
    $campos = Get-PnPField -List $Lista |
        Where-Object { -not $_.Hidden -and ($_.CanBeDeleted -or $_.InternalName -in 'Title', 'ID') }
    $filas = foreach ($c in $campos) {
        $lookup = ''
        if ($c.TypeAsString -like 'Lookup*') {
            $c2 = Get-PnPField -List $Lista -Identity $c.InternalName
            $destino = try { (Get-PnPList -Identity ([guid]$c2.LookupList)).Title } catch { $c2.LookupList }
            $lookup = "$destino.$($c2.LookupField)"
        }
        [pscustomobject]@{
            Visible   = $c.Title
            Interno   = $c.InternalName
            Tipo      = $c.TypeAsString
            Requerido = $c.Required
            Indexado  = $c.Indexed
            Lookup    = $lookup
        }
    }
    $filas | Format-Table -AutoSize | Out-Host
    $filas | Export-Csv (Join-Path $Salida "esquema-$($Lista -replace '\s','_').csv") -NoTypeInformation -Encoding utf8
    return $filas
}

# --- Esquemas
$esqArt = Get-Esquema $Articulos
Get-Esquema $Proveedores | Out-Null
Get-Esquema $Entradas | Out-Null

# --- PRECIOS HORAS: solo NOMBRE
$ph = Get-PnPList -Identity $Trabajadores -Includes ItemCount
$nombre = Get-PnPField -List $Trabajadores | Where-Object { $_.Title -eq 'NOMBRE' }
Write-Host "`n== $Trabajadores ($($ph.ItemCount) elementos): solo NOMBRE" -ForegroundColor Cyan
$nombre | Select-Object Title, InternalName, TypeAsString | Format-Table -AutoSize | Out-Host

# --- Valores de LUGAR, GRUPO y MEDIDA en ARTICULOS ALMACEN
$interesan = $esqArt | Where-Object { $_.Visible -in 'LUGAR', 'GRUPO', 'MEDIDA', 'CODIGO', 'CONCEPTO' }
if ($interesan) {
    $items = Get-PnPListItem -List $Articulos -PageSize 2000 -Fields ($interesan.Interno)
    foreach ($col in $interesan | Where-Object Visible -in 'LUGAR', 'GRUPO', 'MEDIDA') {
        Write-Host "`n-- $($col.Visible) ($($col.Interno))" -ForegroundColor Yellow
        $items | ForEach-Object { "$($_[$col.Interno])" } | Group-Object | Sort-Object Count -Descending |
            Select-Object @{n = 'Valor'; e = { if ($_.Name) { $_.Name } else { '(vacío)' } } }, Count |
            Format-Table -AutoSize | Out-Host
    }
    $codigo = $interesan | Where-Object Visible -eq 'CODIGO'
    if ($codigo) {
        $repetidos = $items | Group-Object { "$($_[$codigo.Interno])" } | Where-Object Count -gt 1
        Write-Host "Códigos repetidos: $($repetidos.Count)" -ForegroundColor Yellow
        $repetidos | Select-Object Name, Count | Format-Table -AutoSize | Out-Host
    }
} else {
    Write-Warning 'No se han encontrado las columnas LUGAR, GRUPO o MEDIDA por su nombre visible.'
}

# --- Jobs y proveedor especiales (T-03)
foreach ($job in '1111', '6969') {
    $p = Get-PnPListItem -List 'PROYECTOS' -Query "<View><Query><Where><Eq><FieldRef Name='Job_x0020_'/><Value Type='Text'>$job</Value></Eq></Where></Query></View>"
    if ($p) { Write-Host "Job $job existe (ESTADO0 = $(@($p)[0]['ESTADO0']))" -ForegroundColor Green }
    else    { Write-Host "Job $job NO existe" -ForegroundColor Red }
}
$campoNombre = Get-PnPField -List $Proveedores | Where-Object { $_.Title -like 'NOMBRE O RAZ*' } | Select-Object -First 1
if ($campoNombre) {
    $s = Get-PnPListItem -List $Proveedores -Query "<View><Query><Where><Eq><FieldRef Name='$($campoNombre.InternalName)'/><Value Type='Text'>STOCK synergy</Value></Eq></Where></Query></View>"
    if ($s) { Write-Host "Proveedor 'STOCK synergy' existe (ID $(@($s)[0].Id))" -ForegroundColor Green }
    else    { Write-Host "Proveedor 'STOCK synergy' NO encontrado con ese texto exacto" -ForegroundColor Red }
}

Write-Host "`nEsquemas guardados en $Salida" -ForegroundColor Green
