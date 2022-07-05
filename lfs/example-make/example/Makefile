CC = gcc

CFLAGS = -Wall -Werror -Wextra -Wpedantic -O3 -march=native

SOURCE = $(wildcard *.c)

.EXTRA_PREREQS:= $(abspath $(lastword $(MAKEFILE_LIST)))

OBJECTS = $(SOURCE:.c=.o)

main: ${OBJECTS}
	${CC} -o $@ ${OBJECTS} ${CFLAGS}

release: CFLAGS += -O3
release: main

.PHONY: clean

clean:
	rm -f main
	rm -f *.o
