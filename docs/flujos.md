# Flujos y navegación

Procesos del almacén y pantallas de la app. Las columnas que se escriben en cada caso están en [modelo-datos.md](modelo-datos.md#qué-escribe-la-app-en-entradas-almacen).

## Procesos

### Entrada (albarán o factura)

```mermaid
flowchart LR
    A[Albarán o factura] --> B{¿Va a un Job?}
    B -- Sí --> C[Fila con entrada = salida, Job y proveedor real]
    B -- No --> D[Fila con solo entrada, proveedor real]
    C --> E[Stock sin cambios]
    D --> F[Stock + cantidad]
```

### Albarán → factura

1. Se mete el albarán: filas con `ALBARAN` y sin `N_x00ba_FACTURA`.
2. Llega la factura y se contabiliza en Contasimple.
3. En `scrAlbaranes` se elige el proveedor, se marcan sus albaranes pendientes y se escribe el nº de factura (D-10).
4. Si la factura trae artículos sin albarán, se meten como entrada nueva con el nº de factura.

### Salida desde el stock

1. Se elige el artículo; la app propone el último precio y `STOCK synergy`.
2. Se elige el Job. Si `ESTADO0 <> ABIERTO`, avisa y pide confirmación (D-6).
3. Se escribe la cantidad (o, en planchas y macizos, la medida, y la app calcula los kg).
4. Si el stock resultante es ≤ mínimo o ≤ 0, avisa (D-1). Se puede guardar igualmente.

### Recuento y regularización

```mermaid
flowchart LR
    A[scrRecuento: filtro lugar/grupo] --> B[PDF con columna Contado]
    B --> C[El taller cuenta]
    C --> D[Administración escribe lo contado]
    D --> E{Diferencia}
    E -- menos --> F[Salida al Job 1111]
    E -- más --> G[Entrada con Job 1111]
    E -- igual --> H[Nada]
```

Antes de regularizar hay que esperar a que el flujo StockTotales haya recalculado (`FechaStock` posterior a la última fila del artículo). Si no, la diferencia se calcula sobre un stock viejo (T-13).

### Recálculo del stock (flujo StockTotales, D-15 y D-19)

- **`StockTotalesArticulo`**: flujo secundario que recalcula un artículo con todas sus filas. Lo llaman el flujo de movimientos, el botón «Recalcular» de la ficha del artículo y, más adelante, la app antes de regularizar (T-13).
- **`StockTotalesMovimiento`**: se dispara al crear o modificar una fila de ENTRADAS ALMACEN y recalcula el artículo de esa fila.
- **No hay flujo nocturno** (D-19). Como no se borran filas ni se cambia su CODIGO, el flujo de cada movimiento basta. Si alguna vez falla, el siguiente movimiento del artículo o el botón «Recalcular» lo corrigen.
- **Recálculo completo** con el script `06-Recalcular-Stock.ps1` (T-16), desde el PC, a final de año y antes de cada recuento. Para las pruebas está además `StockTotalesLote`, que se lanza a mano.

### Corrección de un movimiento (D-19)

No se borra la fila ni se cambia su artículo. Se añade una fila nueva que compense el error: una entrada para anular una salida mal puesta, o una salida para anular una entrada, con el mismo artículo, Job y precio, y «Corrección de la fila del dd/mm/aaaa» en EXTRA DESCRIPCION.

La guía para montarlos está en [stock/flujo-StockTotales.md](../stock/flujo-StockTotales.md).

## Pantallas

| Pantalla | Qué hace | Perfil |
|---|---|---|
| `scrStock` | Inicio: stock con filtros, resumen por lugar y avisos | Todos |
| `scrArticulo` | Ficha, historial de compras, salidas y calculadora kg ↔ medida. Alta y edición | Ver: todos · Editar: admin |
| `scrEntrada` | Albarán o factura con varias filas | Admin |
| `scrSalida` | Salida desde el stock | Admin |
| `scrAlbaranes` | Asignar el nº de factura a albaranes | Admin |
| `scrBuscar` | Movimientos por proveedor o por Job | Todos |
| `scrRecuento` | Filtros, PDF y regularización | PDF: todos · Regularizar: admin |

```mermaid
flowchart TD
    S[scrStock] --> A[scrArticulo]
    S --> B[scrBuscar]
    S --> R[scrRecuento]
    S -->|admin| E[scrEntrada]
    S -->|admin| X[scrSalida]
    S -->|admin| F[scrAlbaranes]
    A -->|admin| X
```

Los botones de administración no aparecen si el usuario no está en `ADMIN ALMACEN` (`nfEsAdmin`, D-5).
