#!/bin/bash
set -e

DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD:-$(cat ${MYSQL_PASSWORD_FILE} 2>/dev/null)}
DB_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(cat ${MYSQL_ROOT_PASSWORD_FILE} 2>/dev/null)}
DB_HOST=${MYSQL_HOST:-mariadb}

WP_ADMIN_USER=${WORDPRESS_ADMIN_USER}
WP_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
WP_ADMIN_PASS=${WORDPRESS_ADMIN_PASS:-$(cat ${WORDPRESS_PASSWORD_FILE} 2>/dev/null)}
DOMAIN_NAME=${DOMAIN_NAME}

WP_PATH="/var/www/html/wp"

echo "waiting for mariadb to be ready..."
until mysqladmin ping -h"$DB_HOST" --silent; do
	sleep 2
done
echo "mariadb is ready!"

#WordPress Config Oluştur
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --skip-check
fi

#WordPress Kurulumu
if ! wp core is-installed --path="${WP_PATH}" >/dev/null 2>&1; then
    echo "Installing WordPress..."
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
else
    echo "WordPress already installed."
fi

echo "Starting php-fpm..."
exec php-fpm7.4 -F