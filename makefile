CFLAGS=-I/usr/local/include -Wextra -Wall -ggdb -O2 -D_REENTRANT
LDFLAGS=-L/usr/local/lib -lavformat -lavcodec -lswscale -lpthread
all: libav.so av
av: av.c
libav.so: av.c
	gcc $(CFLAGS) $(LDFLAGS) -shared -o libav.so av.c -fPIC
