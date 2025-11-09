FROM debian:bullseye

#php-fpm ve gerekli paketler
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-gd \
    php-xml \
    php-mbstring \
    php-zip \
    unzip \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

#wordpress dosyalarını kopyalama
COPY wordpress/ /var/www/html/

RUN chown -R www-data:www-data /var/www/html/
    && chmod -R 755 /var/www/html/

EXPOSE 9000

CMD ["php-fpm8.1", "-F"]