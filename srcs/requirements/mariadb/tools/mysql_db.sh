#!/bin/bash
set -e

# MariaDB data ve socket dizinlerini hazırla
mkdir -p /var/run/mysqld /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Secrets'den şifreleri oku
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_NAME="${MYSQL_DATABASE}"
DB_USER="${MYSQL_USER}"

# Eğer MariaDB henüz initialize edilmemişse, initialize et
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "Initializing MariaDB database..."
    
    # MariaDB'yi initialize et (eğer mysql klasörü yoksa)
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi
    
    # Geçici olarak skip-networking ile başlat
    mysqld --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    pid="$!"
    
    # Servisin hazır olmasını bekle
    echo "Waiting for MariaDB to be ready..."
    for i in {30..0}; do
        if mysqladmin ping --socket=/var/run/mysqld/mysqld.sock &>/dev/null; then
            break
        fi
        sleep 1
    done
    
    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB did not start"
        exit 1
    fi
    
    echo "Setting up database and users..."
    
    # Environment variable'ları temizle (mysql komutunun çakışmaması için)
    unset MYSQL_HOST MYSQL_TCP_PORT
    
    # Database ve user'ı oluştur
    mysql --socket=/var/run/mysqld/mysqld.sock -uroot <<-EOSQL
		SET @@SESSION.SQL_LOG_BIN=0;
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL
    
    echo "Database setup completed!"
    
    # Geçici MariaDB'yi kapat
    kill -s TERM "$pid" && wait "$pid"
    
    # Initialized flag'ini oluştur
    touch /var/lib/mysql/.initialized
fi

# Normal modda MariaDB'yi başlat
echo "Starting MariaDB..."
exec mysqld --user=mysql --console