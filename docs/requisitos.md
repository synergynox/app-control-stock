# Requisitos

Requisitos funcionales de la App Control Stock: casos de uso, reglas de negocio y criterios de aceptación. Las decisiones están en [decisiones.md](decisiones.md) y las columnas, en [modelo-datos.md](modelo-datos.md).

## Usuarios

| Perfil | Quién | Puede |
|---|---|---|
| **Administración** | Cuentas de la lista `ADMIN ALMACEN` (D-5) | Todo: dar de alta y editar artículos, entradas, salidas, facturas y regularizaciones |
| **Consulta** | Resto de cuentas (taller, encargados) | Ver el stock, buscar, consultar precios e imprimir el PDF del recuento |

La app se usa en el PC, en el navegador, con formato de pantalla ancha (D-8).

## Proceso actual que cubre la app

1. Llegan albaranes (los traen los trabajadores) o facturas (por correo) con artículos.
2. **Albarán:** administración mete cada artículo en ENTRADAS ALMACEN con fecha, nº de albarán, cantidad, precio, descuento, artículo, proveedor, margen (40 %) y, si va a un Job, el Job y el trabajador.
3. **Factura:** se contabiliza en Contasimple y sus artículos se meten en ENTRADAS ALMACEN. Si ya había albarán, se pone el nº de factura en las filas de ese albarán.
4. **Salida:** con el parte de trabajo diario, se anota la cantidad que sale, el Job y el trabajador.

## Casos de uso

### CU-01 · Ver el stock

Todos los perfiles.

- Lista de artículos con código, concepto, lugar, grupo, medida, stock, último precio y último proveedor.
- Filtros: búsqueda por **concepto** (o código), **lugar** y **grupo**.
- Resumen por lugar: número de artículos y valor del stock (stock × último precio).
- **Aviso visual:** en rojo si stock ≤ 0, en naranja si stock ≤ `StockMinimo` (D-1).
- Planchas y macizos muestran, además de los kg, la equivalencia en medida (m² o metros, D-4).

**Aceptación:**
- El stock coincide con Σ `CANTIDAD` − Σ `CANTIDADSALIDA` del artículo, con un retraso máximo de unos minutos (D-15).
- Los filtros se combinan.

### CU-02 · Ficha del artículo y precios

Todos los perfiles.

- Datos del artículo y stock.
- **Historial de compras** (D-9): las filas con entrada que no son de STOCK synergy, con fecha, proveedor, albarán, factura, cantidad, precio, descuento y precio neto. Ordenado por fecha, de la más reciente a la más antigua, y con filtro por proveedor.
- Últimos movimientos de salida, con fecha, Job, cantidad y trabajador.
- **Calculadora kg ↔ medida** para planchas y macizos (D-4).

### CU-03 · Alta y edición de artículo

Solo administración.

- Campos: código, concepto, medida, lugar, grupo y stock mínimo, y para planchas y macizos, material, forma y medidas.
- El **código lo escribe administración** (D-3). La app comprueba que no existe y no deja cambiarlo después.

**Aceptación:** no se puede guardar un código repetido ni vacío.

### CU-04 · Entrada de material (albarán o factura)

Solo administración.

- Cabecera: fecha, proveedor, nº de albarán y/o nº de factura.
- Varias filas con artículo, cantidad, precio, descuento, margen (40 % propuesto, D-7) y extra descripción.
- Por cada fila, el **destino**:
  - **Almacén:** solo entrada.
  - **Job:** entrada y salida de la misma cantidad, con Job y trabajador (D-13).

**Aceptación:**
- Una fila con destino Job deja el stock igual.
- Una fila con destino almacén suma la cantidad al stock.

### CU-05 · Salida desde el stock

Solo administración.

- Artículo, cantidad, Job, trabajador (de PRECIOS HORAS), fecha y extra descripción.
- Se rellenan solos el proveedor `STOCK synergy` y el **último precio de compra** neto (D-13). El precio se puede corregir.
- Material de uso de la empresa: Job `6969` (D-14).
- Planchas y macizos: se puede escribir la **medida** y la app calcula los kg (D-4).

**Avisos** (dejan guardar tras confirmar):
- Job no `ABIERTO` (D-6): «El Job X está en estado Y. Revisa si ya está facturado».
- Stock después de la salida ≤ `StockMinimo` o ≤ 0 (D-1). El stock puede quedar negativo por los retales.

### CU-06 · Asignar factura a albaranes

Solo administración.

- Se elige el proveedor y la app lista las filas con albarán y **sin nº de factura**, agrupadas por albarán.
- Se marcan los albaranes, se escribe el nº de factura una vez y se guarda en todas sus filas (D-10).
- Si la factura trae otro precio, se puede corregir en la fila.

### CU-07 · Buscar movimientos

Todos los perfiles.

- **Por proveedor:** movimientos de un proveedor en un rango de fechas.
- **Por proyecto:** material imputado a un Job: artículos, cantidades, coste y precio de venta.
- **Por concepto:** ver CU-01.

### CU-08 · Listado PDF del recuento

Todos los perfiles.

- Filtros: **lugar**, **grupo** y «solo stock ≠ 0» (D-11).
- Columnas: código, concepto, medida, stock del sistema, equivalencia en medida (planchas y macizos) y una columna **Contado** en blanco.
- Encabezado con fecha, filtros y hueco para la firma de quien cuenta.
- Se genera como PDF imprimible con la conversión de OneDrive, que es estándar ([pdf/](../pdf/flujo-StockPDF.md)).

### CU-09 · Regularizar tras el recuento

Solo administración.

- Se elige el mismo filtro del PDF y se escribe la cantidad **contada** de cada artículo.
- La app muestra la diferencia (contado − sistema) y, al confirmar, crea una fila por cada artículo con diferencia (D-2):
  - **Contado < sistema:** salida al Job `1111`.
  - **Contado > sistema:** entrada con Job `1111`.
  - En las dos: proveedor `STOCK synergy`, último precio de compra y extra descripción «Regularización recuento dd/mm/aaaa».

**Aceptación:** después de regularizar, el stock de cada artículo coincide con lo contado.

## Reglas generales

- Los retales no se controlan: el stock puede ser negativo.
- La app no cambia columnas existentes de ENTRADAS ALMACEN, que App Taller también usa.

## Fuera de alcance de la versión 1

- Leer albaranes o facturas en PDF de forma automática (T-10).
- Integración con Contasimple (T-09).
- Control de retales.
