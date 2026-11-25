# Verificación

Pruebas por fase. Si cambia una regla, actualiza sus pruebas. Las pruebas de escritura se hacen primero en las copias de prueba y con artículos de prueba (concepto `PRUEBA APP`) que se borran al terminar.

## Fase 0 · Preparación

| ID | Prueba | Resultado esperado |
|---|---|---|
| V-0.1 | Ejecutar la carga inicial y comparar `StockActual` de 20 artículos con Σ `CANTIDAD` − Σ `CANTIDADSALIDA` sacado de un CSV exportado | Coinciden todos |
| V-0.2 | `UltimoPrecio` de 10 artículos con compras de varios proveedores y salidas de STOCK synergy | Es el neto de la última compra real |
| V-0.3 | Crear una fila de entrada de prueba | `StockActual` y `FechaStock` se actualizan en menos de 5 min |
| V-0.4 | Borrar la fila de prueba y lanzar `StockTotalesLote` | El stock vuelve al valor anterior |
| V-0.5 | Después de los cambios, abrir App Taller | Los totales de material de los Jobs no cambian |

## Fase 1 · Consulta

| ID | Prueba | Resultado esperado |
|---|---|---|
| V-1.1 | Filtrar por lugar `JUMEC` y por un grupo | Solo salen los artículos de ese lugar y grupo |
| V-1.2 | Artículo con stock negativo, otro ≤ mínimo, otro con stock 0 sin mínimo y otro positivo sin mínimo | Rojo, naranja, gris y normal (D-20) |
| V-1.3 | Plancha de hierro de 5 mm con 392,5 kg | Equivalencia de 10 m² |
| V-1.4 | Historial de un artículo, filtrado por proveedor | Solo compras de ese proveedor, sin STOCK synergy |
| V-1.5 | Entrar con una cuenta que no está en ADMIN ALMACEN | No hay botones de alta, entrada, salida, albaranes ni regularizar |
| V-1.6 | Buscar por el Job 6969 y por un proveedor con muchas filas | Salen todas las filas del rango de fechas, sin aviso de delegación |
| V-1.7 | En la copia de prueba, cambiar a mano `StockActual` de un artículo y pulsar «Recalcular» en su ficha | Vuelve al valor correcto y `FechaStock` es la de ese momento |

## Fase 2 · Introducción

| ID | Prueba | Resultado esperado |
|---|---|---|
| V-2.1 | Alta de un artículo con un código existente | No deja guardar |
| V-2.2 | Entrada a almacén de 100 unidades | El stock sube 100 |
| V-2.3 | Entrada directa a un Job de 100 unidades | Una fila con entrada y salida de 100; el stock no cambia |
| V-2.4 | Salida de 50 desde stock | Proveedor STOCK synergy, último precio, stock −50 |
| V-2.5 | Salida a un Job CERRADO o PREFACTURADO | Aviso; guarda tras confirmar |
| V-2.6 | Salida que deja el stock en negativo | Aviso; guarda tras confirmar; stock negativo |
| V-2.7 | Salida de plancha por medida (1 × 0,5 m, 5 mm, hierro) | 19,63 kg |
| V-2.8 | Asignar factura a dos albaranes de un proveedor | Todas sus filas tienen el nº de factura; los de otros proveedores no cambian |
| V-2.9 | Abrir un movimiento guardado | No hay botón de borrar y no se puede cambiar el artículo |

## Fase 3 · Recuento

| ID | Prueba | Resultado esperado |
|---|---|---|
| V-3.1 | PDF del lugar TORNO, solo stock ≠ 0 | Solo esos artículos, con columna Contado y equivalencias |
| V-3.2 | Regularizar un artículo contado de menos y otro de más | Salida y entrada al Job 1111 con STOCK synergy; stock = contado |
| V-3.3 | Regularizar justo después de una salida, sin esperar al flujo | La app avisa o recalcula antes (T-13) |
