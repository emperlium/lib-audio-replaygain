CC:=gcc
CFLAGS+=-O2
CFLAGS+=-fPIC
SODIR=.

.PHONY: all
all: libreplaygain.so

.PHONY: clean
clean:
	rm -f libreplaygain.so gain_analysis.o

.PHONY: install
install: libreplaygain.so
install: gain_analysis.h

libreplaygain.so: gain_analysis.o
	gcc -shared -o $@ $<
gain_analysis.o: gain_analysis.h
