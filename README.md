# Sistema de administración para licorería (Ruby on Rails 7.1 + MySQL + Docker)

Módulos: productos, categorías, marcas, proveedores, clientes, compras (órdenes y recepción),
inventario (kardex y ajustes), ventas/POS con comprobante PDF, devoluciones, usuarios,
roles y permisos por módulo, reportes (PDF / Excel / CSV), configuración y auditoría.

## Requisitos
Docker + Docker Compose (en Windows: Docker Desktop con WSL2). Recomendado descomprimir dentro
de WSL (por ejemplo `~/licoreria`) para mayor velocidad.

## Puesta en marcha
```bash
docker compose up -d --build
docker compose logs -f app   # primera vez: instala gemas, crea tablas y carga datos demo
```
Cuando aparezca "Aplicación lista":

| Servicio     | URL                   |
|--------------|-----------------------|
| Aplicación   | http://localhost:8080 |
| phpMyAdmin   | http://localhost:8081 |
| MySQL (host) | localhost:3307        |


Cambie estas contraseñas antes de usar el sistema en producción.

## Comandos útiles
```bash
docker compose exec app ruby bin/rails db:migrate:reset db:seed   # reinicia la base con datos demo
docker compose exec -e RAILS_ENV=test app ruby bin/rails db:schema:load   # base de pruebas (si el volumen es antiguo, cree/otorgue licoreria_test desde phpMyAdmin con root)
docker compose exec app ruby bin/rails test                       # pruebas de integración
docker compose down -v                                       # apaga y borra base y gemas
```

## Marca, imágenes, pagos e importación
- **Identidad visual Don Vito:** negro carbón en la navegación, marfil de fondo, dorado en botones y
  elementos de marca, verde botella como color secundario; éxito/alerta/error usan colores funcionales
  propios. Los logos están en `public/images/` y el favicon en `public/favicon.png`.
- **Imágenes de producto:** se suben/cambian/quitan desde Productos > Editar (JPG, PNG o WEBP, máx. 2 MB).
  Se guardan en `public/uploads/products/` y se ven en el listado, el POS y las existencias.
- **Pagos:** transferencia pide banco, n.º de referencia y titular (opcional); tarjeta pide marca,
  últimos 4 dígitos y código de autorización. No se solicita ni guarda el número completo, el
  vencimiento ni el CVV de la tarjeta.
- **Carga masiva:** Productos > Importar desde archivo (.xlsx o .csv). Hay plantilla descargable.
  Crea categorías/marcas/proveedores que falten y actualiza productos existentes por SKU.

## Notas de diseño
- El stock solo cambia mediante `StockService` (compras recibidas, ventas, anulaciones,
  devoluciones y ajustes): registra cada movimiento en el kardex y bloquea la fila del producto.
- Precios y totales de una venta se recalculan en el servidor (`SaleCreator`).
- Permisos con formato `modulo.accion` (ej. `products.edit`) asignables por rol; el rol
  Administrador siempre tiene acceso total.
- Impuesto (IVA) por producto; moneda y datos del negocio en Configuración.
- Interfaz con Bootstrap 5 por CDN (se necesita internet en el navegador).
