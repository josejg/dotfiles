.PHONY: all install setup test clean

all: setup install

install:
	python3 install.py --force

setup:
	python3 setup.py

test:
	docker compose build
	docker compose run --rm shell test-shell
	docker compose run --rm bench

clean:
	python3 install.py --unlink
