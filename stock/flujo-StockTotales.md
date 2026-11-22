# Flujos de stock (`StockTotales…`)

Guardan en ARTICULOS ALMACEN el stock y el último precio de cada artículo (`StockActual`, `UltimoPrecio`, `UltimoProveedor` y `FechaStock`, D-15). Así la app no tiene que sumar las más de 32.000 filas de ENTRADAS ALMACEN. Solo usan conectores estándar (SharePoint y flujos secundarios), sin licencia Premium. Siguen el patrón de `APP TALLER/totales/flujo-TallerTotales.md`, que funciona en producción desde el 18/11/2026.

| Flujo | Cuándo se ejecuta | Qué hace |
|---|---|---|
| `StockTotalesArticulo` | Lo llaman los otros dos, el botón «Recalcular» de la app y, más adelante, la regularización (T-13) | Recalcula **un** artículo y guarda su stock y último precio. Es el único que calcula |
| `StockTotalesMovimiento` | Al crear o modificar una fila de ENTRADAS ALMACEN | Llama a `StockTotalesArticulo` con el código de esa fila |
| `StockTotalesLote` | A mano | Llama a `StockTotalesArticulo` para todos los artículos de la lista de destino. Solo para las pruebas: en la lista real serían demasiadas ejecuciones |

No hay flujo nocturno (D-19). El recálculo completo de la lista real lo hace el script `06-Recalcular-Stock.ps1` (T-16).

Los flujos calculan con las reglas de [modelo-datos.md](../docs/modelo-datos.md#fórmulas):
- `StockActual = Σ CANTIDAD − Σ CANTIDADSALIDA` de todas las filas del artículo (vacío = 0). Puede ser negativo.
- `UltimoPrecio = PRECIO × (1 − DESCUENTO)` de la fila más reciente (por `FECHA` y, si empatan, por `ID`) con `CANTIDAD > 0` y proveedor distinto de `STOCK synergy`. Si no hay ninguna, queda vacío. `UltimoProveedor` es el proveedor de esa fila.

Datos generales:
- **Dónde:** en una solución nueva, **App Control Stock**. Los flujos secundarios solo funcionan dentro de una solución.
- **Cuenta:** créalos con la sesión iniciada como **workshop@synergynox.com**, igual que los de App Taller.
- **Nombres:** exactamente los de la tabla, sin espacios.
- **Lista de destino:** la variable de entorno **Lista Articulos**. Durante las pruebas apunta a **ARTICULOS ALMACEN PRUEBA**.
- **Lista de origen del artículo:** siempre **ARTICULOS ALMACEN**, la real, y solo se lee. La columna CODIGO de ENTRADAS ALMACEN enlaza con ella, así que su ID es el que se usa para filtrar los movimientos.
- **STOCK synergy** es el elemento con ID **626** de PROVEEDORES.

**Cómo se meten las expresiones:** lo que aparece entre `@{...}` en esta guía es una expresión dentro de un texto. En el campo, escribe el texto a mano. En el sitio del `@{...}`, pulsa **fx** y pega **solo lo de dentro**, sin `@{` ni `}`. Lo que la guía da como «expresión» sin `@{}` se pega entero en **fx**.

**Campos ocultos:** en **Obtener elementos**, la **Consulta de filtro** y el **Recuento superior** (en el diseñador nuevo, **Primeros puestos**) están en **Parámetros avanzados**. La **Paginación** está en la pestaña **Configuración** de la acción.

En las expresiones, los nombres de las acciones van con `_` en lugar de espacios. **Renombra cada acción en cuanto la añadas** (pulsa la acción y edita el título de arriba del panel), con el nombre exacto de la guía y **sin tildes**. Si una acción se queda como «Obtener elementos» o «Redactar», al guardar sale el error «contienen una referencia no válida a…» en la acción que la usa. Recuerda que los nombres internos que empiezan por `_` llevan delante `OData_` (en estos flujos no hay ninguno).

## 0. Solución y variables de entorno

1. En [make.powerautomate.com](https://make.powerautomate.com), en **Soluciones > + Nueva solución**:
   - Nombre para mostrar: `App Control Stock`
   - Editor: el mismo que usan las soluciones **App Taller** y **Presupuestos Synergy**
2. Dentro de la solución, en **+ Agregar existente > Más > Variable de entorno**, añade **Sitio SharePoint**. Es la misma variable que usan los otros flujos.
3. En **+ Nuevo > Más > Variable de entorno**, crea esta otra:
   - Nombre para mostrar: `Lista Articulos`
   - Tipo de datos: Texto
   - Valor actual: `ARTICULOS ALMACEN PRUEBA`

En todas las acciones de SharePoint:
- **Dirección del sitio:** la variable de entorno **Sitio SharePoint** (contenido dinámico, apartado *Variables de entorno*; si no aparece, **Introducir un valor personalizado** y búscala).
- **Nombre de la lista:** cuando la guía dice **Lista Articulos**, pulsa **Introducir un valor personalizado** > rayo > variable de entorno **Lista Articulos**. **Nunca** elijas ARTICULOS ALMACEN PRUEBA ni ARTICULOS ALMACEN en el desplegable.

## 1. `StockTotalesArticulo` (flujo secundario)

### 1.1 Desencadenador

**+ Nuevo > Automatización > Flujo de nube > Instantáneo**, con el desencadenador **Desencadenar manualmente un flujo**. Añade una entrada:

| Tipo | Nombre | Qué recibe |
|---|---|---|
| Texto | `Codigo` | El código del artículo (`8110`, `0000`…). En las expresiones es `triggerBody()['text']` |

### 1.2 Código para los filtros

**Redactar** (Compose). Renómbralo `Codigo filtro`. Expresión:

```
replace(trim(triggerBody()['text']), '''', '''''')
```

Quita los espacios y dobla las comillas simples, para que un código con `'` no rompa la consulta de filtro.

### 1.3 Leer el artículo en ARTICULOS ALMACEN

**SharePoint > Obtener elementos**. Renómbralo `Leer articulo`.
- Nombre de la lista: `ARTICULOS ALMACEN`, del desplegable. Aquí sí es la lista real, porque solo se lee.
- Consulta de filtro, en tres partes:
  1. a mano: `CODIGO eq '` (con la comilla simple al final);
  2. **rayo** > debajo del título **Codigo filtro**, elige **Salidas**. El título morado «Codigo filtro» no se puede elegir: es la línea **Salidas** de debajo. Si no aparece, pulsa **fx** y pega `outputs('Codigo_filtro')`;
  3. a mano: `'`.

  Queda `CODIGO eq '[Salidas]'`, con la ficha azul en medio. No lo pegues entero en **fx**.
- Recuento superior: `1`

### 1.4 Si el artículo no existe, terminar

**Control > Condición**: en el primer valor, por **fx**, `length(body('Leer_articulo')?['value'])`; operador **es igual que**; en el segundo valor, **también por fx**, `0`. Si el 0 se escribe como texto, la condición nunca se cumple.
- **Si es verdadero:**
  1. **Responder a una aplicación o flujo de Power Apps**, con dos salidas: texto `Resultado` = `NO EXISTE` y número `Stock` = `0`.
  2. **Control > Terminar**, con estado Correcto. Sin esta acción, el flujo sigue aunque haya respondido.
- **Si es falso:** vacío. El flujo sigue debajo de la condición.

### 1.5 Movimientos del artículo

1. **Redactar**. Renómbralo `IdArticulo`. Expresión: `first(body('Leer_articulo')?['value'])?['ID']`
2. **SharePoint > Obtener elementos**. Renómbralo `Movimientos`.
   - Nombre de la lista: `ENTRADAS ALMACEN`
   - Consulta de filtro: `CODIGOId eq @{outputs('IdArticulo')}`. Se filtra por el ID del lookup (`CODIGOId`), igual que App Taller con `PROYECTOId`. `CODIGO` está indexada, así que no falla por el umbral de 5.000.
   - Recuento superior: `5000`
   - En la pestaña **Configuración** de la acción, activa **Paginación** con umbral `100000`. El artículo `0000` tiene 5.200 filas: sin paginación sumaría mal.

### 1.6 Stock

1. **Operación de datos > Seleccionar**. Renómbralo `Valores entrada`.
   - Desde: `body('Movimientos')?['value']`
   - En Asignar, pulsa el icono de **modo texto** y pon la expresión `float(coalesce(item()?['CANTIDAD'], 0))`
2. **Seleccionar**. Renómbralo `Valores salida`. Igual, con `float(coalesce(item()?['CANTIDADSALIDA'], 0))`.
3. **Redactar**. Renómbralo `Total entrada`. Expresión:

   ```
   float(formatNumber(xpath(xml(json(concat('{"r":{"v":', string(body('Valores_entrada')), '}}'))), 'sum(/r/v)'), 'F3', 'en-US'))
   ```

   Es la misma suma con `xpath` de App Taller, redondeada a 3 decimales. Con 0 filas da 0.
4. **Redactar**. Renómbralo `Total salida`. La misma expresión, cambiando `Valores_entrada` por `Valores_salida`.
5. **Redactar**. Renómbralo `Stock`. Expresión:

   ```
   float(formatNumber(sub(outputs('Total_entrada'), outputs('Total_salida')), 'F3', 'en-US'))
   ```

### 1.7 Último precio de compra

1. **Operación de datos > Filtrar matriz**. Renómbralo `Compras reales`.
   - Desde: `body('Movimientos')?['value']`
   - Condición: en el primer valor, por **fx**, `and(greater(float(coalesce(item()?['CANTIDAD'], 0)), 0), not(equals(item()?['PROVEEDOR']?['Id'], 626)))`; operador **es igual que**; en el segundo valor, por **fx**, `true`
2. **Seleccionar**. Renómbralo `Claves compras`. Desde: `body('Compras_reales')`. En Asignar, en modo **clave / valor** (el normal), tres filas, con los valores por **fx**:

   | Clave | Valor (expresión) |
   |---|---|
   | `k` | `concat(item()?['FECHA'], '\|', formatNumber(item()?['ID'], '0000000000'))` |
   | `precio` | `float(formatNumber(mul(float(coalesce(item()?['PRECIO'], 0)), sub(1, float(coalesce(item()?['DESCUENTO'], 0)))), 'F4', 'en-US'))` |
   | `proveedor` | `item()?['PROVEEDOR']?['Value']` |

   `k` junta la fecha y el ID con ceros delante (`2026-03-04T23:00:00Z|0000031250`), así que ordenar por `k` es ordenar por fecha y, si empatan, por ID. En la tabla, `\|` es solo `|`.
3. **Redactar**. Renómbralo `Ultima compra`. Expresión:

   ```
   if(empty(body('Claves_compras')), null, last(sort(body('Claves_compras'), 'k')))
   ```

   Queda la compra más reciente, o vacío si el artículo no tiene compras reales.

### 1.8 Guardar en la lista de destino

1. **SharePoint > Obtener elementos**. Renómbralo `Fila destino`.
   - Nombre de la lista: variable de entorno **Lista Articulos**
   - Consulta de filtro: `CODIGO eq '[Salidas de Codigo filtro]'`, montado igual que en `Leer articulo` (paso 1.3)
   - Recuento superior: `1`
2. **Redactar**. Renómbralo `Cuerpo`. Expresión:

   ```
   setProperty(setProperty(setProperty(setProperty(json('{}'), 'StockActual', outputs('Stock')), 'UltimoPrecio', outputs('Ultima_compra')?['precio']), 'UltimoProveedor', outputs('Ultima_compra')?['proveedor']), 'FechaStock', utcNow())
   ```

   Monta el JSON que se guarda. Si no hay compras, `UltimoPrecio` y `UltimoProveedor` quedan a `null` y se vacían.
3. **Control > Condición**. Se escribe solo si el artículo está en la lista de destino y algo ha cambiado, para no crear versiones de más. En el primer valor, por **fx**, la expresión de abajo; operador **es igual que**; en el segundo valor, por **fx**, `true`.

   ```
   and(greater(length(body('Fila_destino')?['value']), 0), or(not(equals(float(coalesce(first(body('Fila_destino')?['value'])?['StockActual'], -999999)), outputs('Stock'))), not(equals(float(coalesce(first(body('Fila_destino')?['value'])?['UltimoPrecio'], -1)), float(coalesce(outputs('Ultima_compra')?['precio'], -1)))), not(equals(coalesce(first(body('Fila_destino')?['value'])?['UltimoProveedor'], ''), coalesce(outputs('Ultima_compra')?['proveedor'], '')))))
   ```

4. **Si es verdadero:** **SharePoint > Enviar una solicitud HTTP a SharePoint**. Es del conector de SharePoint (estándar), no el conector HTTP Premium. Se usa porque **Actualizar elemento** obliga a rellenar CODIGO y CONCEPTO, que son obligatorias. Renómbrala `Guardar stock`.
   - Método: `POST`
   - Uri, montada en cinco partes:
     1. a mano: `_api/web/lists/getbytitle('`;
     2. **rayo** > variable de entorno **Lista Articulos** (ficha);
     3. a mano: `')/items(`;
     4. **fx**: `first(body('Fila_destino')?['value'])?['ID']`;
     5. a mano: `)`.
   - Encabezados:

     | Clave | Valor |
     |---|---|
     | `Accept` | `application/json;odata=nometadata` |
     | `Content-Type` | `application/json;odata=nometadata` |
     | `IF-MATCH` | `*` |
     | `X-HTTP-Method` | `MERGE` |

   - Cuerpo: **rayo** > salida de **Cuerpo**.

   **Si es falso:** vacío.

### 1.9 Respuesta y uso por otros flujos

1. Al final, fuera de la condición: **Responder a una aplicación o flujo de Power Apps**, con texto `Resultado` = `OK` y número `Stock` = (fx) `outputs('Stock')`. Tiene que tener las mismas salidas que la respuesta del paso 1.4.
2. Guarda el flujo. En la pantalla de detalles, en **Usuarios solo de ejecución > Editar**, pon la conexión de SharePoint en **Usar esta conexión (workshop@…)**. Sin este paso, los otros flujos no pueden llamarlo.

### 1.10 Probarlo solo

**Probar > Manualmente** con estos códigos, y comprueba en ARTICULOS ALMACEN PRUEBA que coinciden con `archivos/esperado-ARTICULOS_PRUEBA.csv`:

| Código | Qué prueba |
|---|---|
| `8024` | Varios proveedores y salidas de STOCK synergy: el último precio es de la última compra real |
| `2012` | Stock negativo |
| `822940320` | Sin compras reales: `UltimoPrecio` vacío |
| `0000` | 5.200 filas: comprueba la paginación |
| `7019807` | Sin movimientos: stock 0 |

Si repites la prueba con el mismo código, la condición de 1.8 sale *falso* y no escribe nada (no cambia `FechaStock`).

Si el diseñador no reconoce la función `sort` del paso 1.7, avisa antes de seguir.

## 2. `StockTotalesMovimiento`

1. Dentro de la solución: **+ Nuevo > Automatización > Flujo de nube > Automatizado**, con el desencadenador **SharePoint > Cuando se crea o modifica un elemento**.
   - Dirección del sitio: **Sitio SharePoint**
   - Nombre de la lista: `ENTRADAS ALMACEN`
2. En **⋯ > Configuración** del desencadenador, en **Condiciones de desencadenador**, añade:

   ```
   @not(empty(triggerBody()?['CODIGO']?['Value']))
   ```

3. **Flujos > Ejecutar un flujo secundario**: elige `StockTotalesArticulo` y, en `Codigo`, pon la expresión `triggerBody()?['CODIGO']?['Value']`.

Mientras la variable apunte a la prueba, el flujo se ejecuta con cada movimiento real, pero solo escribe si el artículo está en ARTICULOS ALMACEN PRUEBA. ENTRADAS ALMACEN ya tiene otro flujo, `TallerTotalesMaterial` de App Taller; los dos son independientes.

## 3. `StockTotalesLote` (solo pruebas)

1. **+ Nuevo > Automatización > Flujo de nube > Instantáneo**, con **Desencadenar manualmente un flujo**, sin entradas.
2. **SharePoint > Obtener elementos**, renombrado `Articulos`:
   - Nombre de la lista: variable **Lista Articulos**
   - Recuento superior: `5000`, y paginación con umbral `100000`
3. **Aplicar a cada uno** sobre `body('Articulos')?['value']`, renombrado `Cada articulo`. En **⋯ > Configuración**, activa **Control de simultaneidad** con grado `5`. Dentro: **Ejecutar un flujo secundario** `StockTotalesArticulo`, con Codigo = `items('Cada_articulo')?['CODIGO']`.
4. **Probar > Manualmente**. Con los 20 artículos de la prueba tarda un par de minutos. Después, comprueba con `scripts/05-Comprobar-Stock-Prueba.ps1` (V-0.1, V-0.2).

## Comprobación

```powershell
./scripts/05-Comprobar-Stock-Prueba.ps1
```

Compara `StockActual`, `UltimoPrecio` y `UltimoProveedor` de ARTICULOS ALMACEN PRUEBA con `archivos/esperado-ARTICULOS_PRUEBA.csv` y dice cuáles no coinciden. Si en ENTRADAS ALMACEN ha habido movimientos de esos artículos desde que se generó el CSV, vuelve a lanzar `04-Copiar-Articulos-Prueba.ps1` (sin `-Confirmar`) para recalcular el esperado.

## Consumo

Cada recálculo de un artículo son unas 15 acciones. Con los movimientos de un día normal, el flujo queda muy por debajo del límite diario de solicitudes de una licencia Microsoft 365, que es de unas 6.000. En cambio, recalcular los 4.544 artículos serían unas 68.000 acciones: por eso no hay recálculo nocturno en Power Automate, y el completo se hace con un script (D-19).

## Limitaciones conocidas

- Si se **borra** una fila de ENTRADAS ALMACEN, o se le cambia el CODIGO, el artículo afectado no se corrige hasta su siguiente movimiento, el botón «Recalcular» o el recálculo completo. SharePoint no dispara flujos al borrar, y al cambiar el código el desencadenador solo da el código nuevo. Por eso no se borran filas ni se cambian códigos: los errores se corrigen con una fila nueva (D-19).
- Guardar el stock cambia el **Modificado** y crea una versión del artículo. Por eso se escribe solo cuando algo cambia.
- Antes de regularizar un recuento hay que asegurarse de que el stock está al día (T-13).
