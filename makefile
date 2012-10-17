CFLAGS=-I/usr/local/include -Wextra -Wall -ggdb -O2
LDFLAGS=-L/usr/local/lib -lavformat -lavcodec -lswscale
all: libav.so av
av: av.c
libav.so: av.c
	gcc $(CFLAGS) $(LDFLAGS) -shared -o libav.so av.c -fPIC
