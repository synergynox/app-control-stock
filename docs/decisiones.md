# Decisiones

Registro de las decisiones de diseño de la App Control Stock y de los puntos que siguen abiertos. Cuando se tome una decisión nueva, añádela aquí con la fecha.

## Decisiones tomadas

| # | Fecha | Decisión | Motivo |
|---|---|---|---|
| D-1 | 2026-11-21 | Aviso «queda poco» con una columna nueva `StockMinimo` por artículo: avisa si stock ≤ mínimo o stock ≤ 0. El stock puede quedar negativo | Pedido por negocio. Es más fiable que un 10 % automático. Los retales no se controlan |
| D-2 | 2026-11-21 | Regularización: si se cuenta menos, fila de **salida** al Job `1111`; si se cuenta más, fila de **entrada** con Job `1111`. Las dos con proveedor `STOCK synergy` y el último precio de compra | Pedido por negocio |
| D-3 | 2026-11-21 | El código de un artículo nuevo lo escribe administración; la app solo comprueba que no exista. Los códigos no se cambian y los antiguos se mantienen | Pedido por negocio |
| D-4 | 2026-11-21 | Kilos ↔ medida: el artículo guarda material, forma y medidas fijas (`Medida1`, `Medida2`), y la lista nueva `MATERIALES` guarda el peso específico. La app convierte en los dos sentidos | Las facturas vienen en kg; el taller da medidas y se cuenta sin pesar |
| D-5 | 2026-11-21 | Permisos con la lista nueva `ADMIN ALMACEN` (un correo por fila), como `ENCARGADOS TALLER` en App Taller. El resto de cuentas solo consulta e imprime | Se cambian las personas sin tocar la app |
| D-6 | 2026-11-21 | Avisa si el Job no está en `ABIERTO` (cualquier otro estado), y deja guardar tras confirmar | Pedido por negocio: puede que el Job ya esté facturado |
| D-7 | 2026-11-21 | El margen propuesto es siempre 40 % (`Campo1` = 0,40), editable en la fila | Pedido por negocio |
| D-8 | 2026-11-21 | La app se usa en PC (pantalla ancha) | Pedido por negocio |
| D-9 | 2026-11-21 | La búsqueda de precios muestra el historial de compras del artículo por proveedor: fecha, proveedor, precio, descuento y neto | Pedido por negocio: comparar proveedores |
| D-10 | 2026-11-21 | El nº de factura se asigna en una pantalla de albaranes pendientes: se elige el proveedor, se marcan los albaranes y se escribe el nº una vez | Menos trabajo que fila a fila |
| D-11 | 2026-11-21 | El PDF del recuento se filtra por lugar y grupo y tiene la opción «solo stock ≠ 0» | Pedido por negocio |
| D-12 | 2026-11-21 | La lectura automática de PDF de facturas y la integración con Contasimple quedan para después del lanzamiento (T-09, T-10). No se usan conectores Premium: se estudiará un script programado fuera de Power Automate | AI Builder y el conector HTTP son Premium. Primero, la app manual |
| D-13 | 2026-11-21 | La salida desde stock lleva proveedor `STOCK synergy` y el último precio de compra neto (sin contar las filas de STOCK synergy). Una compra directa a un Job es una sola fila con entrada y salida | Así se trabaja hoy |
| D-14 | 2026-11-21 | El material de uso de la empresa va al Job `6969` (gastos del taller) | Así se trabaja hoy |
| D-15 | 2026-11-21 | El stock y el último precio no se calculan en la app. Los guarda en ARTICULOS ALMACEN un flujo estándar que se dispara con cada fila de ENTRADAS ALMACEN, más un recálculo nocturno | ENTRADAS ALMACEN tiene más de 32.000 filas y `Sum` no se delega. Es el mismo patrón que D-17 de App Taller |
| D-16 | 2026-11-21 | El PDF se genera como en presupuestos: la app monta el HTML y un flujo lo convierte a PDF con OneDrive «Convertir archivo» | Es estándar y ya está probado (D-39 de `prueba-presupuesto`) |
| D-17 | 2026-11-21 | Repo propio (`APP CONTROL STOCK`, GitHub `synergynox/app-control-stock`) con el mismo método que `prueba-presupuesto` y `APP TALLER` | Proyecto independiente |

## Puntos abiertos

Están en [tareas.md](tareas.md#a-decisiones-y-datos-de-negocio).
