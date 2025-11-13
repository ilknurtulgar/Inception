FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-client \
    php-fpm \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    wget \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /usr/local/bin/ && \
    chmod +x /usr/local/bin/wp-cli.phar && \
    ln -s /usr/local/bin/wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html/wp

COPY conf/wp_my.cnf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wordpress.sh /usr/local/bin/wordpress.sh

RUN mkdir -p /run/php && \
    chown www-data:www-data /run/php

RUN chmod +x /usr/local/bin/wordpress.sh

WORKDIR /var/www/html/wp
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress.sh"]