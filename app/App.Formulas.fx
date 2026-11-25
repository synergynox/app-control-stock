// App.Formulas de "App Control Stock".
// Pegar en Power Apps Studio: vista de árbol > App > propiedad Formulas.
// Studio en español: pega App.Formulas.es.fx (lo genera Generar-Formulas.ps1).

// Colores (los mismos que App Taller y la app de presupuestos)
nfColor = ColorValue("#2AA0A0");
nfColorOscuro = ColorValue("#1D7373");
nfColorClaro = ColorValue("#E3F3F3");
nfColorFondo = ColorValue("#F5F7F7");
nfColorTexto = ColorValue("#1F2A2A");
nfColorTextoSuave = ColorValue("#5B6B6B");
nfColorBorde = ColorValue("#D5DEDE");
nfColorAviso = ColorValue("#C26A00");
nfColorError = ColorValue("#B3261E");
nfBlanco = RGBA(255, 255, 255, 1);

// Permisos (D-5): solo las cuentas de ADMIN ALMACEN introducen y regularizan; el resto consulta e imprime.
// ADMIN ALMACEN: columna Título = correo, en minúsculas.
nfEsAdmin = !IsBlank(LookUp('ADMIN ALMACEN', Title = Lower(User().Email)));

// Valores fijos de negocio
nfIdStockSynergy = 626;      // PROVEEDORES: «STOCK synergy», proveedor de las salidas desde el stock (D-13)
nfJobRegularizacion = "1111"; // Job de las diferencias del recuento (D-2)
nfJobTaller = "6969";         // Gastos del taller (D-14)
nfMargen = 0.4;               // Margen propuesto (D-7)

// Lugares que no se muestran por defecto en el stock: no son ubicaciones, son estados.
// En minúsculas: se comparan con Lower(Lugar).
nfLugaresOcultos = ["descatalogado", "cancelado"];
