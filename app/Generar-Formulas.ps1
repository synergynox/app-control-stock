#Requires -Version 7.2
<#
.SYNOPSIS
    Genera App.Formulas.es.fx (sintaxis española) a partir de App.Formulas.fx.

.DESCRIPTION
    Studio en español usa ";" como separador de argumentos, ";;" entre fórmulas y "," como separador decimal.
    Respeta las cadenas entre comillas dobles, los nombres entre comillas simples y los comentarios //.
    Lánzalo cada vez que cambies App.Formulas.fx. Adaptado de APP TALLER/app/Generar-Formulas.ps1.
#>
$ErrorActionPreference = 'Stop'
$src = [IO.File]::ReadAllText("$PSScriptRoot\App.Formulas.fx")

$sb = [Text.StringBuilder]::new(); $i = 0
while ($i -lt $src.Length) {
    $c = $src[$i]
    if ($c -eq '"') {
        # Cadena: "" es una comilla escapada
        $j = $i + 1
        while ($true) { $j = $src.IndexOf('"', $j); if ($j + 1 -lt $src.Length -and $src[$j + 1] -eq '"') { $j += 2 } else { break } }
        [void]$sb.Append($src.Substring($i, $j - $i + 1)); $i = $j + 1; continue
    }
    if ($c -eq "'") { $j = $src.IndexOf("'", $i + 1); [void]$sb.Append($src.Substring($i, $j - $i + 1)); $i = $j + 1; continue }
    if ($c -eq '/' -and $i + 1 -lt $src.Length -and $src[$i + 1] -eq '/') {
        $j = $src.IndexOf("`n", $i); if ($j -lt 0) { $j = $src.Length }
        [void]$sb.Append($src.Substring($i, $j - $i)); $i = $j; continue
    }
    # Punto decimal (0.4 -> 0,4): un punto entre cifras, si las cifras de antes no son el final de un nombre (Medida1.x)
    if ($c -eq '.' -and $i -gt 0 -and [char]::IsDigit($src[$i - 1]) -and $i + 1 -lt $src.Length -and [char]::IsDigit($src[$i + 1])) {
        $k = $i - 1; while ($k -ge 0 -and [char]::IsDigit($src[$k])) { $k-- }
        if ($k -lt 0 -or -not ([char]::IsLetter($src[$k]) -or $src[$k] -eq '_')) { [void]$sb.Append(','); $i++; continue }
    }
    if ($c -eq ',') { [void]$sb.Append(';') } elseif ($c -eq ';') { [void]$sb.Append(';;') } else { [void]$sb.Append($c) }
    $i++
}
$es = $sb.ToString() -replace '^// App\.Formulas de "App Control Stock"\.', '// App.Formulas de "App Control Stock" en sintaxis española. Generado por Generar-Formulas.ps1: no editar a mano.'
[IO.File]::WriteAllText("$PSScriptRoot\App.Formulas.es.fx", $es, [Text.UTF8Encoding]::new($false))
'App.Formulas.es.fx generado.'
