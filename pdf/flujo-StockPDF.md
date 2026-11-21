# Flujo StockPDF

Guía para montar el flujo que convierte a PDF el listado del recuento (CU-08, D-16). Es una copia adaptada de `prueba-presupuesto/pdf/flujo-PresupuestoPDF.md`.

> **Pendiente de detallar** en la fase 3.

## Esquema

1. La app monta el HTML del listado en una etiqueta oculta de `scrRecuento`: encabezado con fecha y filtros, y una tabla con código, concepto, medida, stock, equivalencia y una columna Contado en blanco.
2. La app llama al flujo `StockPDF` (desencadenador Power Apps V2) con el HTML y el nombre del archivo.
3. El flujo:
   1. crea un `.html` temporal en OneDrive;
   2. lo convierte con **OneDrive for Business → Convertir archivo** (PDF);
   3. guarda el PDF en la carpeta `Recuentos PDF` con fecha y hora en el nombre (`Recuento_TORNO_20261121-1030.pdf`);
   4. borra el temporal;
   5. devuelve un vínculo de solo lectura.
4. La app abre el PDF en una pestaña nueva para imprimirlo.

Limitaciones de la conversión con OneDrive (D-39 de presupuestos): maqueta con tablas y CSS en `<style>`, sin flexbox ni grid, sin fondos de color y sin numeración de páginas. Sí repite la cabecera de la tabla (`thead`) en cada página.
