#!/bin/bash
set -e

# Environment variables'ları oku
DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
DB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
DB_HOST=${MYSQL_HOST}
WP_ADMIN_USER=${WORDPRESS_ADMIN_USER}
WP_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
WP_PASSWORD=${WORDPRESS_PASSWORD}
WP_EDITOR_USER=${WORDPRESS_EDITOR_USER}
WP_EDITOR_PASSWORD=${WORDPRESS_EDITOR_PASSWORD}
WP_EDITOR_EMAIL=${WORDPRESS_EDITOR_EMAIL}
DOMAIN_NAME=${DOMAIN_NAME}
WP_PATH="/var/www/html/wp"

# MariaDB'nin hazır olmasını bekle
echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysqladmin ping -h"$DB_HOST" -u"root" -p"${DB_ROOT_PASSWORD}" --silent 2>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: MariaDB did not become ready in time"
        exit 1
    fi
    sleep 2
done

# MariaDB'nin initialization'ını tamamlaması için bekle
sleep 3

# WordPress core dosyalarını indir
if [ ! -f "${WP_PATH}/wp-settings.php" ]; then
    echo "Downloading WordPress core..."
    wp core download --path="${WP_PATH}" --allow-root
fi

# WordPress Config oluştur
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

# WordPress kurulumu
if ! wp core is-installed --path="${WP_PATH}" --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
else
    echo "WordPress already installed."
fi

# Editor kullanıcısı oluştur (eğer yoksa)
if ! wp user get "${WP_EDITOR_USER}" --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    echo "Creating editor user..."
    wp user create "${WP_EDITOR_USER}" "${WP_EDITOR_EMAIL}" \
        --path="${WP_PATH}" \
        --role=editor \
        --user_pass="${WP_EDITOR_PASSWORD}" \
        --allow-root
    echo "Editor user created successfully!"
else
    echo "Editor user already exists."
fi

# PHP-FPM'yi başlat
echo "Starting php-fpm..."
exec php-fpm8.2 -F