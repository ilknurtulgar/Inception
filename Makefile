NAME = inception

all: build up

build:
	docker-compose -f srcs/docker-compose.yml build

up:
	docker-compose -f srcs/docker-compose.yml up -d

down:
	docker-compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -f
	docker volume prune -f

fclean: clean
	docker-compose -f srcs/docker-compose.yml down --rmi all --volumes --remove-orphans
	docker system prune -a -f
	sudo rm -rf /home/itulgar/data/mariadb/*
	sudo rm -rf /home/itulgar/data/wordpress/*

re: fclean all

.PHONY: all build up down clean fclean re