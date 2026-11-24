# Plan de lanzamiento

Plan por fases. Cada fase termina cuando se cumplen sus criterios de salida y sus pruebas de [verificacion.md](verificacion.md). Los pendientes están en [tareas.md](tareas.md).

| Fase | Contenido | Criterio de salida |
|---|---|---|
| **0 · Preparación** | Planchas, macizos y limpieza de datos (T-02), columnas y listas nuevas, flujos StockTotales y carga inicial (T-12) | `StockActual` coincide con la suma manual en una muestra de 20 artículos (V-0.x) |
| **1 · Consulta** | `scrStock`, `scrArticulo` (solo lectura), `scrBuscar` y permisos | Todos ven el stock y los precios; los no admin no ven botones de edición |
| **2 · Introducción** | Alta y edición de artículos, `scrEntrada`, `scrSalida` y `scrAlbaranes` | Administración mete una semana de albaranes y partes en la app, y los resultados coinciden con el método actual |
| **3 · Recuento** | Flujo PDF, `scrRecuento` y regularización (T-13) | Un recuento real de un lugar, regularizado, deja el stock igual a lo contado |
| **4 · Piloto** | Administración y taller usan la app en lugar del método actual | Dos semanas sin incidencias que bloqueen |
| **5 · Automatización** | Contasimple (T-09) y lectura de PDF (T-10) | Por decidir tras el estudio |

## Riesgos

| Riesgo | Mitigación |
|---|---|
| El stock histórico no es fiable (filas antiguas, retales, errores) | Primer recuento completo como punto de partida, con una regularización inicial (T-07) |
| Delegación: más de 2.000 filas en búsquedas por proveedor o Job | Filtros por Id de lookup (`CODIGO`, `PROVEEDOR` y `PROYECTO` ya indexadas) y rango de fechas |
| Un cambio en ENTRADAS ALMACEN rompe App Taller | Solo se añaden filas y columnas en ARTICULOS ALMACEN; no se toca el esquema de ENTRADAS ALMACEN. Al terminar cada fase se comprueba `TallerTotalesMaterial` |
| El flujo StockTotales tarda o falla y se regulariza con un stock viejo | Comprobar `FechaStock` antes de regularizar (T-13) y recálculo completo con `06-Recalcular-Stock.ps1` antes de cada recuento |
| Pesos específicos o medidas mal puestos dan equivalencias erróneas | Validar con negocio una muestra de artículos (T-02, T-04) |
