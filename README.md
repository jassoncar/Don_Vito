# Sistema de inventario y ventas — Ruby on Rails

Aplicación inicial modular en Ruby on Rails 7.2, MySQL 8.4, Devise, Pundit, Bootstrap 5 y Docker Compose. Interfaz y documentación en español; moneda visual predeterminada: córdobas nicaragüenses (C$).

## Incluye

- Inicio de sesión con Devise y roles de usuario.
- Dashboard con conteo de productos, alertas de stock bajo y valor de inventario.
- Catálogo de productos, categorías y marcas.
- Gestión de proveedores y clientes.
- Registro de compras y recepción de mercancía.
- Caja/ventas con validación de existencias dentro de transacción y comprobante imprimible.
- Ajustes de inventario con movimientos auditables.
- Reportes HTML y CSV para inventario, ventas, compras y movimientos.
- Migraciones con claves foráneas, índices únicos y tipos decimales para importes.
- Datos de demostración y pruebas básicas.

## Requisitos

Docker Desktop o Docker Engine con el complemento Docker Compose. No es necesario instalar Ruby ni MySQL en el equipo anfitrión.

## Instalación

1. Descomprime el ZIP y entra en la carpeta `sistema_comercial_rails`.
2. Copia `.env.example` a `.env`.
3. Cambia `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` y `SECRET_KEY_BASE`.
4. Ejecuta:

```bash
docker compose up --build
```

El servicio web instala las gemas, prepara la base de datos y levanta Rails. Abre `http://localhost:3000`.

En una terminal separada, carga datos de demostración:

```bash
docker compose exec web bin/rails db:seed
docker compose up -d --build
docker compose logs -f app   # primera vez: instala gemas, crea tablas y carga datos demo
```

Usuarios de demostración (todos usan inicialmente `Cambiar123!`):

| Rol | Correo |
|---|---|
| Administrador | admin@comercio.local |
| Encargado de inventario | inventario@comercio.local |
| Cajero | caja@comercio.local |

**Seguridad:** estas credenciales son únicamente para desarrollo local. Cámbialas o elimina los usuarios demo antes de exponer el sistema a una red.

## Comandos útiles

```bash
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails test
docker compose logs -f web
docker compose down
```

Para borrar también la base de datos persistida (¡se pierden los datos!):

```bash
docker compose down -v
```

## Notas técnicas y alcance

Este ZIP es una base funcional de desarrollo, no una instalación auditada para producción. Las rutas, modelos, migraciones, vistas y flujos principales están implementados como punto de partida, pero deben revisarse y probarse en el entorno objetivo antes de utilizarse con dinero o inventario real.

- La autorización Pundit está incluida como política base, pero las políticas específicas por recurso y su aplicación uniforme en cada acción deben completarse antes de producción.
- La creación de usuarios por registro público debe deshabilitarse o limitarse en despliegues reales.
- La auditoría cubre operaciones principales, no todos los cambios de todos los módulos.
- El formulario de ventas recibe impuesto como importe, no como porcentaje; adapta la regla fiscal a la normativa aplicable.
- La paginación, lectura de códigos de barras, flujo de caja por turnos, devolución/anulación de ventas y cierre diario no están implementados aún.
- Las pruebas son iniciales y no se han ejecutado en este entorno; no se afirma que pasen.
- Se recomienda configurar HTTPS, copias de seguridad, envío de correo, rotación de secretos, permisos específicos y pruebas de concurrencia antes de producción.

## Estructura

```text
app/
  controllers/   # endpoints y operaciones de negocio
  models/        # asociaciones y validaciones
  policies/      # política base Pundit
  views/         # vistas ERB responsivas
config/
db/migrate/      # esquema relacional
db/seeds.rb      # usuarios y catálogo de ejemplo
test/            # pruebas iniciales
Dockerfile
docker-compose.yml
```
