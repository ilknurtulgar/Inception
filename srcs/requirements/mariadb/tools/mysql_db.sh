#!/bin/bash
set -e

# MariaDB data ve socket dizinlerini hazırla
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-mysecretpassword}

# Arka planda MariaDB'yi başlat
mysqld_safe &

# Servisin hazır hale gelmesini bekle
until mysqladmin ping &>/dev/null; do
  echo "Waiting for MariaDB to be ready..."
  sleep 5
done

echo "MariaDB is now ready!"

DB_NAME=${DB_NAME:-inception}
DB_USER=${DB_USER:-user}
DB_PASSWORD=${DB_PASSWORD:-password}

mysql <<-EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

wait #containeri ayakta tutmak için