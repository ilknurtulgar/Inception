#!/bin/bash
set -e

service mysql start

DB_NAME=${DB_NAME:-inception}
DB_USER=${DB_USER:-user}
DB_PASSWORD=${DB_PASSWORD:-password}

mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
mysql -e    "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e    "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';"
mysql -e "FLUSH PRIVILEGES;"

exec mysqld_safe