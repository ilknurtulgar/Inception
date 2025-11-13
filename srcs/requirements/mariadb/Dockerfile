FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	mariadb-server mariadb-client && \
	rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/my.cnf 

COPY tools/mysql_db.sh /usr/local/bin/mysql_db.sh

RUN chmod +x /usr/local/bin/mysql_db.sh

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
	chmod 777 /var/run/mysqld

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/mysql_db.sh"]