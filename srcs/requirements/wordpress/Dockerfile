FROM debian:bullseye

# 1. PHP-FPM ve Gerekli Paketleri Kurma
RUN apt-get update && apt-get install -y mariadb-client \
    php-fpm \
    php-mysql \
    php7.4-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    wget \
    procps \
    && rm -rf /var/lib/apt/lists/*


# 3. WP-CLI Aracını İndirme ve Erişilebilir Yapma
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /usr/local/bin/ && \
    chmod +x /usr/local/bin/wp-cli.phar && \
    ln -s /usr/local/bin/wp-cli.phar /usr/local/bin/wp


# WordPress dosyalarını indir
RUN mkdir -p /var/www/html/wp

# # Web dosyalarını www-data kullanıcısına ata
# RUN chown -R www-data:www-data /var/www/html/wp && \
#     chmod -R 755 /var/www/html/wp

# 5. Konfigürasyon Dosyalarını ve Script'i Kopyalama
COPY conf/wp_my.cnf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/wordpress.sh /usr/local/bin/wordpress.sh

# PHP-FPM için gerekli klasörleri oluştur
RUN mkdir -p /run/php && \
    chown www-data:www-data /run/php

RUN chmod +x /usr/local/bin/wordpress.sh 
#Script çalıştırma izni ver

# 6. Container Ayarları
WORKDIR /var/www/html/wp
EXPOSE 9000
USER root

ENTRYPOINT ["/bin/bash", "/usr/local/bin/wordpress.sh"]