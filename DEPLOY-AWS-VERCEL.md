# Despliegue de Don Vito: AWS RDS (MySQL) + Vercel (Container)

Arquitectura: **Vercel** ejecuta la app Rails (contenedor de `Dockerfile.vercel`) y **AWS RDS** guarda los datos.
Las imágenes de productos viven en la base de datos (tabla `product_images`), porque en Vercel el disco es de
solo lectura y temporal.

> Los scripts de `deploy/` se ejecutan con `bash deploy/<script>.sh` (WSL/Linux/macOS) y necesitan Docker.

## 0. Antes de empezar
- Plan de Vercel: **Hobby** es solo para uso personal/no comercial. Para el negocio real usa **Pro** (hay prueba).
- AWS (cuentas nuevas): el plan gratis dura hasta 6 meses o hasta agotar créditos; luego hay que pasar a plan de pago.
- Genera dos contraseñas y un secreto (en WSL): `openssl rand -hex 16` (x2) y `openssl rand -hex 64`.

## 1. Crear la base en AWS RDS (consola, región us-east-2)
Elige **Configuración completa** y usa estos valores:

| Campo | Valor |
|---|---|
| Motor / versión | MySQL **8.4.x** (8.0 ya exige soporte extendido de pago) |
| Plantilla / instancia | Capa gratuita · `db.t4g.micro` |
| Identificador | `licoreria-db` |
| Usuario maestro | `dbadmin` |
| Credenciales | **Autoadministrado** (contraseña propia, sin `/ ' " @`) |
| Almacenamiento | gp2 · 20 GiB · **desactivar** el autoescalado |
| Conectividad | Default VPC · **Acceso público: Sí** · **Crear nuevo** grupo de seguridad `licoreria-db-sg` |
| Nombre de base inicial | `licoreria` |
| Copias automáticas | retención **1 día** (el plan gratis no permite más) |
| Monitoreo | Performance Insights y Enhanced Monitoring apagados · Multi-AZ apagado |
| Protección contra eliminación | activada |

Cuando figure "Disponible", copia el **endpoint** (Conectividad y seguridad).

## 2. Abrir el puerto en el grupo de seguridad
EC2 > Security Groups > `licoreria-db-sg` > Edit inbound rules: tipo **MYSQL/Aurora**, puerto **3306**, origen
`0.0.0.0/0`. Vercel no tiene IPs fijas en el plan estándar, por eso se abre al mundo; lo compensan:
contraseña larga, usuario limitado a la base `licoreria` y conexión cifrada (`DB_SSL_MODE=required`).
Más seguro (requiere Vercel Pro/Enterprise, ~$100/mes por proyecto): Static IPs y permitir solo esas IPs.

## 3. Credenciales locales y usuario de la aplicación
```bash
cp deploy/env.production.example deploy/.env.production   # complete los valores (no se sube a GitHub)
bash deploy/create_app_user.sh      # crea la base y el usuario licoreria_app (pide la clave de dbadmin)
bash deploy/test_connection.sh      # verifica versión, usuario y SSL
```
`create_app_user.sh` usa `mysql_native_password` (compatible con el cliente MySQL de la imagen). Si falla por ese
método, el propio script indica cómo crear el usuario con el método por defecto.

## 4. Tablas y administrador inicial
```bash
bash deploy/migrate_remote.sh
```
Ejecuta las migraciones y un seed de producción: roles, permisos, configuración y **un** administrador
(`ADMIN_EMAIL` / `ADMIN_PASSWORD`). No crea usuarios ni productos de demostración.

## 5. Subir a GitHub
`git add -A && git commit -m "Despliegue Vercel + AWS" && git push`
(no se sube `deploy/.env.production`; está en `.gitignore`).

## 6. Vercel
1. New Project > importar el repo (Root Directory `./`, preset **Container**).
2. Environment Variables (marcar como *Sensitive*):

| Variable | Valor |
|---|---|
| `SECRET_KEY_BASE` | el de `deploy/.env.production` |
| `DB_HOST` | endpoint de RDS |
| `DB_PORT` | `3306` |
| `DB_DATABASE` | `licoreria` |
| `DB_USERNAME` | `licoreria_app` |
| `DB_PASSWORD` | clave del usuario de la app |
| `DB_SSL_MODE` | `required` |

3. En Settings > Functions elige una región cercana a Ohio (costa este de EE. UU.).
4. **Deploy**. Abre `/up` (health check) y luego `/login`.

## 7. Respaldos (obligatorio con 1 día de retención)
```bash
bash deploy/backup_remote.sh        # guarda backups/respaldo-FECHA.sql.gz (conserva los últimos 14)
```
Prográmalo a diario (cron) y copia la carpeta `backups/` a otro lugar (PC, nube).

## Costos y límites
- Dirección IPv4 pública de RDS: cargo por hora; crea una alerta en AWS Budgets (p. ej. $5/mes).
- Vercel Container es **beta**, escala a cero (primer arranque lento) y limita el tamaño de las peticiones.
- Cambia/elimina cualquier credencial de demostración antes de usar datos reales.

## Problemas frecuentes
- **Conexión rechazada/timeout a RDS:** puerto 3306 abierto, "Acceso público: Sí" y endpoint correcto.
- **Error de plugin de autenticación:** vuelve a crear el usuario con el método por defecto (ver paso 3).
- **500 en Vercel:** revisa los logs del deployment; casi siempre falta `SECRET_KEY_BASE` o `DB_SSL_MODE`.
- **Falla el build por `\r`:** `.gitattributes` fuerza LF en `Dockerfile*`, `*.sh` y `bin/*`.
