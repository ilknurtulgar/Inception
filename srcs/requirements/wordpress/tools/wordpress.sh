#!/bin/bash
set -e

WORDPRESS_PATH="/var/www/html/wp"

echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysqladmin ping -h"$MYSQL_HOST" -u"root" -p"${MYSQL_ROOT_PASSWORD}" --silent 2>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: MariaDB did not become ready in time"
        exit 1
    fi
    sleep 2
done

sleep 3

if [ ! -f "${WORDPRESS_PATH}/wp-settings.php" ]; then
    echo "Downloading WordPress core..."
    wp core download --path="${WORDPRESS_PATH}" --allow-root
fi

if [ ! -f "${WORDPRESS_PATH}/wp-config.php" ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --path="${WORDPRESS_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --skip-check \
        --allow-root
fi

# WordPress kurulumu
if ! wp core is-installed --path="${WORDPRESS_PATH}" --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --path="${WORDPRESS_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
else
    echo "WordPress already installed."
fi

# Editor kullanıcısı oluştur
if ! wp user get "${WORDPRESS_EDITOR_USER}" --path="${WORDPRESS_PATH}" --allow-root >/dev/null 2>&1; then
    echo "Creating editor user..."
    wp user create "${WORDPRESS_EDITOR_USER}" "${WORDPRESS_EDITOR_EMAIL}" \
        --path="${WORDPRESS_PATH}" \
        --role=editor \
        --user_pass="${WORDPRESS_EDITOR_PASSWORD}" \
        --allow-root
    echo "Editor user created successfully!"
else
    echo "Editor user already exists."
fi

# PHP-FPM'yi başlat
echo "Starting php-fpm..."
exec php-fpm8.2 -F