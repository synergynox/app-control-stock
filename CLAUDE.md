# CLAUDE.md

## Qué es este proyecto

**App Control Stock**: app de Power Apps (canvas) para el control del almacén de Synergy Nox.

- Administración introduce las **entradas** (albaranes y facturas de proveedores) y las **salidas** de material a los proyectos (Jobs), según los partes de trabajo.
- Todos pueden ver el **stock por lugar y grupo**, buscar artículos por concepto, proveedor o proyecto y consultar el **historial de precios** de compra.
- Se saca un **listado PDF** para el recuento en el taller. Las diferencias se regularizan contra el Job `1111`.

**Stack:** SharePoint Online (sitio `https://synergynoxcom.sharepoint.com/sites/CONTROLTRABAJOSTALLER`), Power Apps canvas y Power Automate. Solo **conectores estándar** de Microsoft 365: no hay licencias Premium.

**Listas:**
- `ARTICULOS ALMACEN` (lectura y escritura).
- `ENTRADAS ALMACEN` (lectura y escritura). La comparte con App Taller.
- `PROYECTOS`, `PROVEEDORES` y `PRECIOS HORAS` (solo lectura).
- Listas nuevas: `MATERIALES` y `ADMIN ALMACEN`.

El stock y el último precio de cada artículo los guarda en `ARTICULOS ALMACEN` el flujo `StockTotales…` (D-15). La app no los calcula sobre las 32.000 filas de movimientos.

## Documentación

| Documento | Para qué sirve |
|---|---|
| [docs/requisitos.md](docs/requisitos.md) | Casos de uso, reglas y criterios de aceptación. **Empieza por aquí** |
| [docs/modelo-datos.md](docs/modelo-datos.md) | Columnas y listas nuevas, qué lee y escribe cada pantalla, y las fórmulas (stock, precio, kg ↔ medida) |
| [docs/flujos.md](docs/flujos.md) | Procesos (entrada, salida, albarán → factura, recuento → regularización) y navegación |
| [docs/tareas.md](docs/tareas.md) | **Lista única de tareas pendientes**. Ver [Mantenimiento de tareas](#mantenimiento-de-tareas) |
| [docs/plan-lanzamiento.md](docs/plan-lanzamiento.md) | Fases, criterios de salida y riesgos |
| [docs/verificacion.md](docs/verificacion.md) | Pruebas por fase. Si cambia una regla, actualiza sus pruebas |
| [docs/decisiones.md](docs/decisiones.md) | Decisiones tomadas y puntos abiertos |
| [docs/estructura-tablas.md](docs/estructura-tablas.md) | Estructura de las listas existentes, con sus nombres internos |
| [app/](app/README.md) | Código de la app: fórmulas y pantallas en YAML para pegar en Studio |
| [scripts/](scripts/README.md) | Scripts PnP.PowerShell (consultas y cambios en SharePoint) |
| [stock/](stock/flujo-StockTotales.md) | Guía del flujo de stock y último precio |
| [pdf/](pdf/flujo-StockPDF.md) | Guía del flujo que genera el PDF del recuento |

## Reglas del proyecto

- **Usa siempre el nombre interno** de las columnas de SharePoint, nunca el visible. En ENTRADAS ALMACEN, CANTIDAD ENTRADA es `CANTIDAD`, CANTIDAD SALIDA es `CANTIDADSALIDA`, MARGEN es `Campo1` y JOB NUMBER es `PROYECTO`. Consulta [estructura-tablas.md](docs/estructura-tablas.md).
- En Power Automate (salidas del desencadenador y de «Obtener elementos»), los nombres internos que empiezan por `_` llevan delante `OData_`.
- **ENTRADAS ALMACEN la comparte App Taller** (flujo `TallerTotalesMaterial`, repo `APP TALLER`). No cambies ni borres columnas existentes: solo se añaden.
- **No copies datos de `PRECIOS HORAS`** (DNI, salarios, teléfonos, coste por hora) a la documentación ni a código de ejemplo. De esa lista solo se usa `NOMBRE`.
- Los correos de `ADMIN ALMACEN` no se suben al repositorio.
- Los CSV de `archivos/` son exportaciones locales y **no se suben al repositorio**.
- Los CSV exportados usan formato **es-ES** (`52.300,00 €`, `40,00%`).
- Documentación, comentarios y nombres de negocio **en español**.
- No propongas conectores Premium (Dataverse, SQL, HTTP, AI Builder, plantilla de Word…) sin avisar de que requieren licencia.
- Los cambios de esquema se prueban primero en una copia de prueba. Los scripts simulan si no se les pasa `-Confirmar`.

## Mantenimiento de tareas

[docs/tareas.md](docs/tareas.md) es la **única** lista de pendientes.

- **Pendiente nuevo:** añádelo en el mismo cambio a `tareas.md`, con un ID nuevo (`T-xx`, el siguiente libre), responsable y dependencias. Deja la referencia `(T-xx)` en el documento de origen. No crees casillas `- [ ]` en otros documentos.
- **Tema resuelto:** bórralo de `tareas.md` junto con sus referencias `(T-xx)`. Si era una decisión, regístrala con fecha en [decisiones.md](docs/decisiones.md). Actualiza los documentos afectados, las dependencias y los contadores.
- **Al empezar una sesión**, revisa `tareas.md` por si algo ya se resolvió.
- Los IDs **no se reutilizan**.

## Glosario

| Término | Significado |
|---|---|
| **Artículo** | Fila de `ARTICULOS ALMACEN`, identificada por `CODIGO`. Los códigos los escribe administración, no siguen ninguna regla y no se cambian |
| **Movimiento** | Fila de `ENTRADAS ALMACEN`. Puede tener entrada (`CANTIDAD`), salida (`CANTIDADSALIDA`) o las dos |
| **Job** | Número de proyecto (`PROYECTOS.Job_x0020_`) al que se imputa la salida |
| **STOCK synergy** | Proveedor que se usa en las salidas desde el stock propio |
| **Lugar** | Ubicación del artículo (Jumec, torno, chapero…) |
| **Retales** | Sobrantes de planchas y macizos. No se controlan, y por eso el stock puede quedar en negativo |
| **Job 6969** | Gastos del taller: material de uso de la empresa |
| **Job 1111** | Regularización de las diferencias de los recuentos |

## Reglas de negocio clave

- **Stock** del artículo = Σ `CANTIDAD` − Σ `CANTIDADSALIDA` de todas sus filas. Puede ser negativo.
- **Compra directa a un Job:** una sola fila con entrada y salida iguales, el Job y el proveedor real.
- **Compra para almacén:** fila con solo entrada. Cuando sale, fila con solo salida, el Job, proveedor `STOCK synergy` y el **último precio de compra** neto (sin contar las filas de STOCK synergy).
- **Avisos:**
  - Job no `ABIERTO`: avisa, pero deja guardar tras confirmar.
  - Stock ≤ `StockMinimo`, o stock ≤ 0: avisa, pero deja guardar.
- **Margen** propuesto: 40 %, editable en cada fila.
- **Permisos:** solo las cuentas de `ADMIN ALMACEN` introducen y regularizan. El resto consulta e imprime.
- **Planchas y macizos** (Jumec, torno, chapero) se guardan en kg. La app convierte kg ↔ medida con la forma, las medidas y el peso específico del material.
