FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/nginx.cnf /etc/nginx/nginx.conf

COPY tools/nginx.sh /usr/local/bin/nginx.sh

RUN chmod +x /usr/local/bin/nginx.sh

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/nginx.sh"]