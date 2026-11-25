# App Control Stock (Power Apps)

Código de la app de lienzo **App Control Stock**. Formato tableta (pantalla ancha) para el navegador del PC (D-8). Solo controles clásicos. Las pantallas se construyen por fases ([plan-lanzamiento.md](../docs/plan-lanzamiento.md)). Hechas: fórmulas y `scrStock`.

| Fichero | Qué es | Fase |
|---|---|---|
| `App.Formulas.fx` / `App.Formulas.es.fx` | Fórmulas con nombre: colores, `nfEsAdmin` (permisos, D-5), valores fijos (`nfIdStockSynergy`, Jobs `1111` y `6969`, margen 40 %) y `nfLugaresOcultos`. La versión `.es` la genera `Generar-Formulas.ps1`, que también cambia el punto decimal por coma | 1 |
| `scrStock.pa.yaml` | Inicio (CU-01): carga los artículos en `colArticulos` (4 bloques por el primer carácter del código, una vez por sesión), con stock, aviso, valor y equivalencia kg ↔ medida (D-4). Filtros por concepto o código, lugar y grupo, «Solo con aviso» y «Ver descatalogados». Resumen por lugar; clic en un lugar filtra la lista | 1 |
| `scrArticulo.pa.yaml` | Ficha, historial de compras, calculadora, alta y edición | 1 y 2 |
| `scrBuscar.pa.yaml` | Movimientos por proveedor o por Job | 1 |
| `scrEntrada.pa.yaml` | Albarán o factura con varias filas | 2 |
| `scrSalida.pa.yaml` | Salida desde el stock | 2 |
| `scrAlbaranes.pa.yaml` | Asignar el nº de factura | 2 |
| `scrRecuento.pa.yaml` | PDF y regularización | 3 |

## Montaje en Power Apps Studio

1. **App nueva:** Crear > Aplicación de lienzo en blanco, formato **Tableta**. Nombre: `App Control Stock`.
2. **Datos:** SharePoint > sitio CONTROLTRABAJOSTALLER > `ARTICULOS ALMACEN`, `ENTRADAS ALMACEN`, `PROYECTOS`, `PROVEEDORES`, `PRECIOS HORAS`, `MATERIALES` y `ADMIN ALMACEN`.
3. **Configuración > General > Límite de filas de datos:** `2000`.
4. **Fórmulas:** App > propiedad **Formulas**: pega `App.Formulas.es.fx` (Studio en español) o `App.Formulas.fx` (en inglés).
5. **Pantallas:** copia cada `.pa.yaml` y pégalo en la vista de árbol (clic derecho sobre la lista de pantallas > **Pegar**). Pega todas antes de revisar errores, porque se llaman entre sí.
6. **App > StartScreen:** `=scrStock`. Borra `Screen1`.
7. Guarda y publica.

## Colecciones

| Colección | Dónde se carga | Qué tiene |
|---|---|---|
| `colArticulos` | `scrStock`, botón Recargar (al entrar, si está vacía) | Todos los artículos con las columnas de ARTICULOS ALMACEN que usa la app, más `Lugar`, `Grupo`, `Stock`, `Rho`, `Aviso` (0, 1 naranja, 2 rojo), `Valor`, `Oculto`, `PesoUnidad` y `Equivalencia`. La usan también `scrArticulo` y las pantallas de entrada y salida |
| `colMateriales` | Igual | MATERIALES: `ID`, `Title`, `PesoEspecifico` |

Si un bloque de carga llega a 2.000 artículos, la app avisa: hay que partir ese bloque en `btnStoCargar`.

## Convenciones (heredadas de App Taller)

- Las columnas se escriben con el nombre interno; Studio las muestra con el visible. Si un nombre interno empieza por `_`, Studio no lo reconoce y se usa el visible.
- En los `.pa.yaml`, una fórmula que contenga `: ` (por ejemplo `{Value: …}` o `"Total: "`) va en bloque `|-`; en una sola línea, YAML la confunde con una clave.
- Los ficheros `.pa.yaml` usan siempre la sintaxis inglesa (`,`). Las fórmulas que se escriben a mano en un Studio en español usan `;` y `;;`, y los decimales llevan coma.
- Números con formato es-ES (coma decimal).
- `<>` no es delegable en SharePoint: va en un `Filter` exterior.
- No se usan las columnas calculadas (`SALIDA COSTE`, `coste SY`): el coste se calcula con `CANTIDAD × PRECIO × (1 − DESCUENTO)`.
- De PRECIOS HORAS solo se muestra `NOMBRE`; nunca columnas de coste ni datos personales.
- Si cambias algo en Studio, copia el código de la pantalla (clic derecho > **Ver código**) y actualiza aquí el fichero.
