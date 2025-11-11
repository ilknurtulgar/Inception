#!/bin/bash
set -e

if [ -f .env ]; then
  export $(cat .env | xargs)  # .env dosyasındaki tüm değişkenleri al
fi

DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASSWORD=$(cat /run/secrets/db_password 2>/dev/null || echo "${MYSQL_PASSWORD}")
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password 2>/dev/null || echo "${MYSQL_ROOT_PASSWORD}")
DB_HOST=${MYSQL_HOST}

WP_ADMIN_USER=${WORDPRESS_ADMIN_USER}
WP_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
WP_ADMIN_PASS=$(cat /run/secrets/credentials 2>/dev/null || echo "${WORDPRESS_ADMIN_PASS}")
DOMAIN_NAME=${DOMAIN_NAME}

WP_PATH="/var/www/html/wp"

echo "Waiting for MariaDB to be ready..."
MAX_TRIES=30
COUNT=0
until mysqladmin ping -h"$DB_HOST" -u"${DB_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $MAX_TRIES ]; then
        echo "Error: MariaDB did not become ready in time"
        exit 1
    fi
    echo "MariaDB connection attempt $COUNT/$MAX_TRIES..."
    sleep 2
done
echo "MariaDB is ready!"

# WordPress core dosyalarını indir
if [ ! -f "${WP_PATH}/wp-settings.php" ]; then
    echo "Downloading WordPress core..."
    wp core download --path="${WP_PATH}" --allow-root
fi

#WordPress Config Oluştur
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --skip-check \
        --allow-root
fi

#WordPress Kurulumu
if ! wp core is-installed --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    echo "Installing WordPress..."
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
else
    echo "WordPress already installed."
fi

echo "Starting php-fpm..."
exec php-fpm -F