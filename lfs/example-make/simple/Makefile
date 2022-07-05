CC = gcc
CFLAGS = -Werror -Wall

all: main

main: main.c
	$(CC) $^ -o $@ $(CFLAGS)

.PHONY: clean

clean:
	rm -rf main
