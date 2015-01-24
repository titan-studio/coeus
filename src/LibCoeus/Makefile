linux64:
	gcc -c -fPIC -I/usr/include/lua5.1 -llua5.1 lodepng.c luajit_thread_aux.c stb_truetype.c tinycthread.c
	gcc lodepng.o luajit_thread_aux.o stb_truetype.o tinycthread.o -shared -o libcoeus_aux.so
	cp libcoeus_aux.so ./bin/
	cp libcoeus_aux.so ./bin/