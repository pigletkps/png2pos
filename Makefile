CC ?= gcc
CFLAGS += -std=c99 -W -Wall -pedantic -O3 -ftree-vectorize \
	-Ideps/lodepng \
	-D_POSIX_C_SOURCE=200809L \
	-D_FILE_OFFSET_BITS=64 \
	-DLODEPNG_NO_COMPILE_ANCILLARY_CHUNKS \
	-DLODEPNG_NO_COMPILE_CPP \
	-DLODEPNG_NO_COMPILE_ALLOCATORS \
	-DLODEPNG_NO_COMPILE_ENCODER
LDFLAGS +=
PREFIX := /usr/local

OBJS = png2pos.o deps/lodepng/lodepng.o
EXEC = png2pos

all : $(EXEC)

man : $(EXEC).1.gz

strip : $(EXEC)
	-strip --strip-unneeded $<

.PHONY : clean install uninstall indent

clean :
	-rm -f $(OBJS) $(EXEC)
	-rm *.pos *.gz debug.* *.backup

$(EXEC) : $(OBJS)
	@printf "%-16s%s\n" LD $@
	@$(CC) $(OBJS) $(LDFLAGS) -o $@

%.o : %.c
	@printf "%-16s%s\n" CC $@
	@$(CC) -c $(CFLAGS) -o $@ $<

deps/lodepng/%.o : deps/lodepng/%.cpp
	@printf "%-16s%s\n" CC $@
	@$(CC) -x c -c $(CFLAGS) -o $@ $<

%.1.gz : %.1
	@printf "%-16s%s\n" GZ $@
	@gzip -c -9 $< > $@

static : CFLAGS += -static
static : LDFLAGS += -static
static : all
# This option will not work on Mac OS X unless all libraries (including libgcc.a)
# have also been compiled with -static. Since neither a static version of libSystem.dylib
# nor crt0.o are provided, this option is not useful to most people.

rpi : CFLAGS += -march=armv6j -mfpu=vfp -mfloat-abi=hard
rpi : strip

profiled :
	make CFLAGS="$(CFLAGS) -fprofile-generate" $(EXEC)
	find . -type f -exec ./$(EXEC) -o /dev/null -p -c -r -a c {} \;
	-rm -f *.pos
	make clean
	make CFLAGS="$(CFLAGS) -fprofile-use" strip
	-rm -f $(OBJS) *.gcda *.gcno *.dyn pgopti.dpi pgopti.dpi.lock

install : strip man
	mkdir -p $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/share/man/man1
	install -m755 $(EXEC) $(DESTDIR)$(PREFIX)/bin
	install -m644 $(EXEC).1.gz $(DESTDIR)$(PREFIX)/share/man/man1

uninstall :
	rm -f $(DESTDIR)$(PREFIX)/bin/$(EXEC)
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/$(EXEC).1.gz

indent : png2pos.c png2pos.1 README.md
	sed -i.backup 's/[[:blank:]]*$$//' $^

debug : CFLAGS += -DDEBUG
debug : all
	ls -l png2pos
	./png2pos -V

update :
	git submodule update --recursive --merge
