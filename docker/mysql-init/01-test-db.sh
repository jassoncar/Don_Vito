#!/bin/bash
# Solo se ejecuta al crear el volumen de MySQL por primera vez: crea la base de pruebas.
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}_test\`; GRANT ALL ON \`${MYSQL_DATABASE}_test\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
