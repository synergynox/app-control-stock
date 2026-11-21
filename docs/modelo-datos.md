# Modelo de datos

Columnas que lee y escribe la app, columnas y listas nuevas, y fórmulas. La estructura de las listas existentes está en [estructura-tablas.md](estructura-tablas.md).

> **Cuidado con ARTICULOS ALMACEN:** LUGAR es `Campo1` y GRUPO es `LUGAR`. Los lookups de ENTRADAS ALMACEN (`CODIGO`, `PROVEEDOR`, `TRABAJADOR`) tienen el mismo nombre interno que el visible.

## Listas

| Lista | Uso en la app | Escribe |
|---|---|---|
| ARTICULOS ALMACEN | Catálogo, stock guardado y datos de planchas y macizos | App (alta y edición) y flujo StockTotales (stock y precio) |
| ENTRADAS ALMACEN | Movimientos de entrada y salida | App (filas nuevas, nº de factura y precio) |
| PROYECTOS | Elegir el Job y comprobar `ESTADO0` | No |
| PROVEEDORES | Elegir el proveedor | No |
| PRECIOS HORAS | Elegir el trabajador (solo `NOMBRE`) | No |
| MATERIALES (nueva) | Peso específico por material | Negocio, a mano |
| ADMIN ALMACEN (nueva) | Permisos | Negocio, a mano |

## Columnas nuevas en ARTICULOS ALMACEN

Se añaden; no se toca ninguna columna existente. Primero se prueban en una copia (T-12).

| Visible | Interno | Tipo | Escribe | Uso |
|---|---|---|---|---|
| Stock actual | `StockActual` | Number (3 decimales) | Flujo | Σ entrada − Σ salida (D-15) |
| Último precio | `UltimoPrecio` | Number (4 decimales) | Flujo | Precio neto de la última compra real |
| Último proveedor | `UltimoProveedor` | Text (255) | Flujo | Proveedor de esa compra |
| Fecha stock | `FechaStock` | DateTime | Flujo | Cuándo se recalculó |
| Stock mínimo | `StockMinimo` | Number | Administración | Umbral del aviso (D-1). Vacío = sin aviso de mínimo |
| Material | `Material` | Lookup → MATERIALES | Administración | Solo planchas y macizos |
| Forma | `Forma` | Choice | Administración | `PLANCHA`, `REDONDO`, `CUADRADO`, `PLETINA`, `HEXAGONAL`, `TUBO` (T-02) |
| Espesor / Ø (mm) | `Medida1` | Number | Administración | Espesor de la plancha o pletina, diámetro del redondo o del tubo, lado del cuadrado o entre caras del hexágono |
| Ancho / pared (mm) | `Medida2` | Number | Administración | Ancho de la pletina o pared del tubo |

## Lista nueva MATERIALES

| Visible | Interno | Tipo | Ejemplo |
|---|---|---|---|
| Título | `Title` | Text | `HIERRO`, `INOX 316`, `ALUMINIO`, `LATÓN`, `BRONCE` |
| Peso específico | `PesoEspecifico` | Number (3 decimales) | kg/dm³: hierro 7,85; inox 7,95; aluminio 2,70 (los valores definitivos los da negocio, T-04) |

## Lista nueva ADMIN ALMACEN

| Visible | Interno | Tipo | Uso |
|---|---|---|---|
| Título | `Title` | Text (255) | Correo en minúsculas. Una fila por cuenta de administración |

La leen todos; la editan solo negocio. Los correos no van al repositorio (T-05).

## Qué escribe la app en ENTRADAS ALMACEN

| Columna | Interno | Entrada a almacén | Entrada directa a Job | Salida desde stock | Regularización |
|---|---|---|---|---|---|
| FECHA | `FECHA` | Fecha del albarán o factura | ídem | Fecha del parte | Fecha del recuento |
| CODIGO | `CODIGO` (lookup) | Artículo | Artículo | Artículo | Artículo |
| CANTIDAD ENTRADA | `CANTIDAD` | Cantidad | Cantidad | — | Si se contó de más |
| CANTIDAD SALIDA | `CANTIDADSALIDA` | — | = entrada | Cantidad | Si se contó de menos |
| PRECIO | `PRECIO` | Precio de compra | Precio de compra | Último precio | Último precio |
| DESCUENTO | `DESCUENTO` | Del documento | ídem | 0 (el último precio ya es neto) | 0 |
| ALBARAN | `ALBARAN` | Si hay | Si hay | — | — |
| Nº FACTURA | `N_x00ba_FACTURA` | Si hay | Si hay | — | — |
| PROVEEDOR | `PROVEEDOR` (lookup) | Proveedor real | Proveedor real | `STOCK synergy` | `STOCK synergy` |
| JOB NUMBER | `PROYECTO` | — | Job | Job | `1111` |
| TRABAJADOR | `TRABAJADOR` (lookup) | — | Si se sabe | Quien lo saca | — |
| MARGEN | `Campo1` | 0,40 | 0,40 | 0,40 | 0,40 |
| EXTRA DESCRIPCION | `EXTRADESCRIPCION` | Opcional | Opcional | Opcional | «Regularización recuento dd/mm/aaaa» |

Las columnas calculadas (`ENTRADA COSTE`, `coste SY`, `SALIDA COSTE`) no se escriben. La app tampoco las lee: el coste se calcula con la fórmula, como en App Taller.

## Fórmulas

### Stock

```
StockActual = Σ CANTIDAD − Σ CANTIDADSALIDA   (todas las filas del artículo; vacío = 0)
```

### Último precio de compra (D-13)

Es la fila del artículo más reciente (por `FECHA` y, si hay empate, por `ID`) que cumple dos condiciones: `CANTIDAD > 0` y proveedor distinto de `STOCK synergy`.

```
UltimoPrecio = PRECIO × (1 − DESCUENTO)
```

Si no hay ninguna compra, queda vacío y la app pide escribir el precio.

### Coste y venta de una fila

```
Coste entrada = CANTIDAD × PRECIO × (1 − DESCUENTO)
Coste salida  = CANTIDADSALIDA × PRECIO × (1 − DESCUENTO)
Venta salida  = Coste salida × (1 + Campo1)
```

### Avisos

```
Job no abierto  = PROYECTOS.ESTADO0 del Job <> "ABIERTO"                 (D-6)
Stock agotado   = StockActual (después del movimiento) <= 0              (D-1)
Stock bajo      = StockMinimo no vacío y StockActual <= StockMinimo      (D-1)
```

### Kilos ↔ medida (D-4)

`ρ` = `MATERIALES.PesoEspecifico` en kg/dm³. Las medidas `Medida1` y `Medida2` van en mm.

| Forma | Peso por unidad de medida | Unidad |
|---|---|---|
| PLANCHA | `Medida1 × ρ` | kg/m² |
| REDONDO | `π/4 × Medida1² × ρ / 1000` | kg/m |
| CUADRADO | `Medida1² × ρ / 1000` | kg/m |
| PLETINA | `Medida1 × Medida2 × ρ / 1000` | kg/m |
| HEXAGONAL | `0,866 × Medida1² × ρ / 1000` | kg/m |
| TUBO | `π × (Medida1 − Medida2) × Medida2 × ρ / 1000` | kg/m |

```
Medida equivalente del stock = StockActual (kg) / peso por unidad   → m² o metros
Kg de una salida por medida  = largo (m) × ancho (m) × peso por m²  (plancha)
                             = largo (m) × peso por m               (resto)
```

Ejemplo: plancha de hierro de 5 mm → 5 × 7,85 = 39,25 kg/m². Un trozo de 1 × 0,5 m pesa 19,6 kg.

## Rendimiento y delegación

- ENTRADAS ALMACEN tiene más de 32.000 filas y `Sum` no se delega en SharePoint. Por eso el stock se lee de `StockActual` (D-15).
- El historial de un artículo y las búsquedas por proveedor o por Job filtran por el **Id del lookup**, que es delegable. `CODIGO`, `PROVEEDOR` y `PROYECTO` están indexadas (21/11/2026). Si un filtro devuelve más de 2.000 filas, se limita por rango de fechas.
- ARTICULOS ALMACEN tiene **4.544 artículos** (21/11/2026), más del límite de 2.000 filas. No se carga entero en una colección: se busca con filtros delegables sobre `CODIGO` y `CONCEPTO`, que están indexadas, o se carga por bloques de ID como `colHistorico` en App Taller. Los artículos con LUGAR `descatalogado` o `CANCELADO` se pueden dejar fuera de las búsquedas por defecto.
- PROVEEDORES (855) y PRECIOS HORAS (161) caben en una colección.
