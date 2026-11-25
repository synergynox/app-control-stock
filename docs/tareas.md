# Tareas

Lista **única** de tareas pendientes de la App Control Stock. Los demás documentos enlazan aquí con `(T-xx)`. Las reglas para mantenerla están en [CLAUDE.md](../CLAUDE.md#mantenimiento-de-tareas): cada tema resuelto se **borra** de aquí y, si era una decisión, pasa a [decisiones.md](decisiones.md).

**Estado:** ⬜ Pendiente · 🟡 En curso · ⛔ Bloqueada.

**Responsable:**
- **Negocio:** dirección de Synergy. Decide y da los datos.
- **Desarrollo:** quien construye la app y los flujos.
- **Administración:** introduce los datos y valida la app.

## Resumen

| Bloque | Pendientes |
|---|---|
| [A. Decisiones y datos de negocio](#a-decisiones-y-datos-de-negocio) | 5 |
| [Fase 0 · Preparación](#fase-0--preparación) | 2 |
| [Fase 3 · Recuento](#fase-3--recuento) | 1 |
| [Fase 5 · Automatización](#fase-5--automatización) | 2 |

Las fases se describen en [plan-lanzamiento.md](plan-lanzamiento.md).

---

## A. Decisiones y datos de negocio

| ID | Tarea | Responsable | Depende de | Bloquea | Estado |
|---|---|---|---|---|---|
| T-04 | Pesos específicos de cada material para la lista MATERIALES | Negocio | | T-12 | ⬜ |
| T-06 | Rellenar `StockMinimo` en los artículos que necesiten aviso | Administración | T-12 | | ⬜ |
| T-07 | Calidad del stock histórico: ¿el primer recuento sirve de punto de partida, con una regularización inicial al 1111? | Negocio | T-12 | | ⬜ |
| T-11 | ¿Cómo llegan hoy los proveedores de Contasimple a la lista PROVEEDORES (a mano, importación…)? | Negocio | | T-09 | ⬜ |
| T-17 | Comunicar a todos los que editan ENTRADAS ALMACEN (también desde App Taller) la norma de D-19: no borrar filas ni cambiar el CODIGO; los errores se corrigen con una fila nueva que compense, con nota en EXTRA DESCRIPCION | Negocio | | | ⬜ |

## Fase 0 · Preparación

| ID | Tarea | Responsable | Depende de | Bloquea | Estado |
|---|---|---|---|---|---|
| T-02 | Qué artículos son planchas o macizos (Jumec, torno, chapero), con su forma y medidas. Revisar también los datos de [estructura-tablas.md](estructura-tablas.md#valores-en-uso-21112026): LUGAR mezcla ubicaciones con estados (`descatalogado`, `CANCELADO`) y el 73 % está vacío; MEDIDA repite unidades (`kg`/`kgs`, `m`/`MTS`…); GRUPO tiene `CONSUMIBLE HABITUAL` y `CONSUMIBLES HABITUAL` | Desarrollo + Negocio | | T-12 | ⬜ |
| T-12 | Crear las columnas nuevas de ARTICULOS ALMACEN y las listas MATERIALES y ADMIN ALMACEN, montar los flujos StockTotales y hacer la carga inicial. **Hecho (21/11/2026):** copias de prueba `ARTICULOS ALMACEN PRUEBA`, `MATERIALES PRUEBA` y `ADMIN ALMACEN PRUEBA` con `scripts/03-Columnas-Listas.ps1`, y 20 artículos de muestra copiados con `scripts/04-Copiar-Articulos-Prueba.ps1` (el esperado queda en `archivos/esperado-ARTICULOS_PRUEBA.csv`). **Hecho (24/11/2026):** los tres flujos de la guía [stock/flujo-StockTotales.md](../stock/flujo-StockTotales.md) montados. Tras `StockTotalesLote`, los 20 artículos de la prueba coinciden en stock, último precio y proveedor según `05-Comprobar-Stock-Prueba.ps1` (V-0.1, V-0.2). V-0.3 superada (24/11/2026): al crear una fila de prueba en `7019807`, el stock se actualizó en 64 s. V-0.4 superada: borrada la fila, `StockTotalesLote` lo devolvió a 0 y los otros 19 no se reescribieron. Script de recálculo completo `scripts/06-Recalcular-Stock.ps1` hecho y probado en la copia (da lo mismo que el flujo y corrige artículos estropeados a propósito). **Hecho (25/11/2026):** `03-Columnas-Listas.ps1 -Destino Real` aplicado: 9 columnas nuevas en ARTICULOS ALMACEN y listas MATERIALES y ADMIN ALMACEN creadas (vacías). `Fila destino` cambiada a solicitud HTTP, variable **Lista Articulos** apuntando a ARTICULOS ALMACEN, `StockTotalesLote` apagado y cuentas de ADMIN ALMACEN apuntadas. Carga inicial con `06-Recalcular-Stock.ps1 -Destino Real -Confirmar`: 4.547 artículos; la comprobación posterior da 0 cambios, también con los movimientos nuevos que ha ido recogiendo el flujo. **Falta:** permisos de ADMIN ALMACEN (solo negocio edita) | Desarrollo | T-02, T-04 | | 🟡 |

## Fase 3 · Recuento

| ID | Tarea | Responsable | Depende de | Bloquea | Estado |
|---|---|---|---|---|---|
| T-13 | La regularización tiene que usar un stock al día: comprobar que `FechaStock` es posterior a la última fila del artículo, o recalcular desde la app antes de regularizar | Desarrollo | T-12 | | ⬜ |

## Fase 5 · Automatización

| ID | Tarea | Responsable | Depende de | Bloquea | Estado |
|---|---|---|---|---|---|
| T-09 | Estudiar la API de Contasimple: ¿da las líneas de cada factura? Idea: leer las facturas y crear borradores en ENTRADAS ALMACEN. Sin Premium, con un script programado fuera de Power Automate (D-12) | Desarrollo | T-11 | | ⬜ |
| T-10 | Prueba de lectura automática de los PDF de facturas (carpeta de OneDrive → script → filas en estado «pendiente de revisar»). AI Builder es Premium (D-12) | Desarrollo | | | ⬜ |
