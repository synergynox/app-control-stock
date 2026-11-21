# Scripts

Scripts PnP.PowerShell (PowerShell 7.2+) contra el sitio CONTROLTRABAJOSTALLER.

| Script | Qué hace |
|---|---|
| `Conectar.ps1` | Conecta con el sitio de `config.psd1`. Copiado de `APP TALLER/scripts/` |
| `config.psd1` | URL del sitio y ClientId de la app de Entra ID (ya registrada desde `prueba-presupuesto`). No contiene secretos |
| `01-Esquema-Listas.ps1` | **Solo lectura.** Esquema de ARTICULOS ALMACEN, PROVEEDORES y ENTRADAS ALMACEN; la columna NOMBRE de PRECIOS HORAS; valores de LUGAR, GRUPO y MEDIDA; códigos repetidos; y si existen los Jobs 1111 y 6969 y el proveedor STOCK synergy. Ejecutado el 21/11/2026. Deja CSV en `archivos/` |
| `02-Indices.ps1` | Índices de `CODIGO` y `PROVEEDOR` en ENTRADAS ALMACEN (`PROYECTO` ya lo estaba) (T-08). No cambia columnas ni datos. Simula si no se le pasa `-Confirmar` |

Los scripts que cambien SharePoint simulan si no se les pasa `-Confirmar`, y por defecto trabajan sobre una copia de prueba.

Uso:

```powershell
cd scripts
./01-Esquema-Listas.ps1
```
