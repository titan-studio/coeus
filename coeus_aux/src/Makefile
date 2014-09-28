build:
	gcc -c -fPIC -I/usr/include/lua5.1 -llua5.1 lodepng.c luajit_thread_aux.c stb_truetype.c tinycthread.c

so:
	gcc lodepng.o luajit_thread_aux.o stb_truetype.o tinycthread.o -shared -o libcoeus_aux.so

move:
	sudo cp libcoeus_aux.so /usr/lib/x86_64-linux-gnu/