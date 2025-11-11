#!/bin/bash
set -e

# MariaDB data ve socket dizinlerini hazırla
mkdir -p /var/run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Environment variables'dan değerleri al
DB_NAME="${MYSQL_DATABASE}"
DB_USER="${MYSQL_USER}"

# Eğer MariaDB henüz initialize edilmemişse, initialize et
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    echo "MariaDB database initialized!"
    
    # Geçici olarak skip-networking ile başlat
    mysqld --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    pid="$!"
    
    # Servisin hazır olmasını bekle
    echo "Waiting for MariaDB to be ready..."
    for i in {30..0}; do
        if mysqladmin ping --socket=/var/run/mysqld/mysqld.sock &>/dev/null; then
            break
        fi
        echo "MariaDB connection attempt $((30-i))/30..."
        sleep 1
    done
    
    if [ "$i" = 0 ]; then
        echo >&2 "MariaDB did not start"
        exit 1
    fi
    
    echo "MariaDB is now ready! Setting up database and users..."
    
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
    
    echo "Database ${DB_NAME} and user ${DB_USER} created successfully!"
    
    # Geçici MariaDB'yi kapat
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 "MariaDB initialization process failed"
        exit 1
    fi
    
    echo "Initialization complete!"
fi

# Normal modda MariaDB'yi başlat
echo "Starting MariaDB..."
exec mysqld --user=mysql --console