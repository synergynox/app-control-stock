# Scripts

Scripts PnP.PowerShell (PowerShell 7.2+) contra el sitio CONTROLTRABAJOSTALLER.

| Script | Qué hace |
|---|---|
| `Conectar.ps1` | Conecta con el sitio de `config.psd1`. Copiado de `APP TALLER/scripts/` |
| `config.psd1` | URL del sitio y ClientId de la app de Entra ID (ya registrada desde `prueba-presupuesto`). No contiene secretos |
| `01-Esquema-Listas.ps1` | **Solo lectura.** Esquema de ARTICULOS ALMACEN, PROVEEDORES y ENTRADAS ALMACEN; la columna NOMBRE de PRECIOS HORAS; valores de LUGAR, GRUPO y MEDIDA; códigos repetidos; y si existen los Jobs 1111 y 6969 y el proveedor STOCK synergy. Ejecutado el 21/11/2026. Deja CSV en `archivos/` |
| `02-Indices.ps1` | Índices de `CODIGO` y `PROVEEDOR` en ENTRADAS ALMACEN (`PROYECTO` ya lo estaba). Creados a mano el 21/11/2026. No cambia columnas ni datos. Simula si no se le pasa `-Confirmar`. Con más de 5.000 elementos SharePoint rechaza el índice desde PnP: se crea a mano y el script sirve para comprobarlo |
| `03-Columnas-Listas.ps1` | Columnas nuevas de ARTICULOS ALMACEN y listas MATERIALES y ADMIN ALMACEN (T-12). Por defecto (`-Destino Prueba`) crea las copias `ARTICULOS ALMACEN PRUEBA`, `MATERIALES PRUEBA` y `ADMIN ALMACEN PRUEBA`, con los mismos nombres internos. `-Destino Real` solo añade columnas a la lista real. Lo que existe no se toca. Copias creadas el 21/11/2026 |
| `04-Copiar-Articulos-Prueba.ps1` | Copia 20 artículos de muestra (elegidos por caso: varios proveedores, compra directa, stock negativo, sin compras, kg, muchos movimientos, sin movimientos) a ARTICULOS ALMACEN PRUEBA. Calcula su stock y último precio esperados en `archivos/esperado-ARTICULOS_PRUEBA.csv`. Solo lee las listas reales. Ejecutado el 21/11/2026. Con `-Recalcular` solo rehace el CSV de los artículos que ya están en la prueba, sin elegir ni copiar: úsalo cuando haya movimientos nuevos |
| `05-Comprobar-Stock-Prueba.ps1` | **Solo lectura.** Compara `StockActual`, `UltimoPrecio` y `UltimoProveedor` de ARTICULOS ALMACEN PRUEBA con el esperado del CSV (V-0.1, V-0.2) |

Los scripts que cambien SharePoint simulan si no se les pasa `-Confirmar`, y por defecto trabajan sobre una copia de prueba.

Uso:

```powershell
cd scripts
./01-Esquema-Listas.ps1
```
