# Flujos StockTotales

Guía para montar en Power Automate (conectores estándar) los flujos que guardan en ARTICULOS ALMACEN el stock y el último precio de cada artículo (D-15). Sigue el patrón de `APP TALLER/totales/flujo-TallerTotales.md`.

> **Pendiente de detallar** cuando existan las columnas nuevas (T-12). Los nombres internos ya están en [estructura-tablas.md](../docs/estructura-tablas.md).

## Flujos

| Flujo | Desencadenador | Qué hace |
|---|---|---|
| `StockTotalesMovimiento` | SharePoint · Cuando se crea o modifica un elemento en ENTRADAS ALMACEN | Recalcula el artículo de la fila |
| `StockTotalesNoche` | Periodicidad · cada día a las 02:00 | Recalcula todos los artículos (recoge borrados y cambios de artículo) |

## Cálculo de un artículo (esquema)

1. **Obtener elementos** de ENTRADAS ALMACEN con filtro `CODIGO/Id eq <id>` (`CODIGO` está indexada), con paginación activada. El artículo `0000` tiene 5.200 filas: el umbral de paginación tiene que ser mayor (por ejemplo 10.000).
2. **Seleccionar** `CANTIDAD` y `CANTIDADSALIDA` (vacío = 0) y sumar con `xpath`, como en TallerTotales.
3. **Último precio:** filtrar las filas con `CANTIDAD > 0` y proveedor distinto de `STOCK synergy`, ordenar por `FECHA` e `ID` de mayor a menor y tomar la primera: `PRECIO × (1 − DESCUENTO)` y proveedor.
4. **Actualizar elemento** en ARTICULOS ALMACEN: `StockActual`, `UltimoPrecio`, `UltimoProveedor` y `FechaStock = utcNow()`.

Recuerda: en las expresiones, los nombres internos que empiezan por `_` llevan delante `OData_`.

## Prueba

En `ARTICULOS ALMACEN PRUEBA` hay 20 artículos de muestra, copiados con `scripts/04-Copiar-Articulos-Prueba.ps1`. Cubren varios proveedores con salidas de STOCK synergy, solo compras directas, stock negativo, sin compras reales, kg, muchos movimientos y sin movimientos. El stock y el último precio esperados están en `archivos/esperado-ARTICULOS_PRUEBA.csv` (V-0.1, V-0.2). El flujo lee ENTRADAS ALMACEN real y escribe en la copia de prueba buscando por `CODIGO`.
