#!/bin/bash
set -e

echo "Setting up Nginx..."

# SSL dizinini oluştur
mkdir -p /etc/nginx/ssl

# Self-signed SSL sertifikası oluştur (eğer yoksa)
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=42/OU=42/CN=${DOMAIN_NAME}"
    
    echo "SSL certificate generated."
fi

# WordPress dizinini kontrol et
if [ ! -d /var/www/html/wp ]; then
    echo "Creating WordPress directory..."
    mkdir -p /var/www/html/wp
fi

# Domain name'i config'e yerleştir
echo "Setting up domain name: ${DOMAIN_NAME}"
sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf


echo "Testing Nginx configuration..."
nginx -t

# Nginx'i başlat (foreground modda)
echo "Starting Nginx..."
exec nginx -g "daemon off;"