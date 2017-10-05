JL_SHARE = $(shell julia -e 'print(joinpath(JULIA_HOME,Base.DATAROOTDIR,"julia"))')
JULIA_HOME = $(shell julia -e 'print(JULIA_HOME)')
JULIA_LIB = $(shell julia -e 'print(abspath(Libdl.dlpath("libjulia")))')
JULIA_DEBUG_LIB = \
  $(shell $(JULIA_HOME)/julia-debug -e 'print(abspath(Libdl.dlpath("libjulia-debug")))')
CFLAGS   += -DKXVER=3 -O0 -g
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)
SOFLAGS_Linux = -shared -fPIC
SOFLAGS_Darwin = -bundle -undefined dynamic_lookup
SOFLAGS_Darwin += -Wl,-rpath $(shell dirname $(JULIA_LIB)) -ljulia
SOFLAGS  += $(SOFLAGS_$(shell uname))

J.so: J.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(SOFLAGS)

jl.so: jl.c jl-lib.h
		$(CC) jl.c -o $@ $(CFLAGS) $(LDFLAGS) $(SOFLAGS)

install: J.so jl.so
	cp J.k $(QHOME)
	cp J.so jl.so $(QHOME)/$(QARCH)
	echo ".J.home:\"$(JULIA_HOME)\"" > $(QHOME)/julia-config.q
	echo ".J.lib:\"$(JULIA_LIB)\"" >> $(QHOME)/julia-config.q
	echo "#! $(QHOME)/$(QARCH)/q" | cat - julia.q > $(QHOME)/julia.q
	chmod +x $(QHOME)/julia.q
	echo ".J.home:\"$(JULIA_HOME)\"" > $(QHOME)/julia-debug-config.q
	echo ".J.lib:\"$(JULIA_DEBUG_LIB)\"" >> $(QHOME)/julia-debug-config.q
	printf "#! $(QHOME)/$(QARCH)/q\n\\l julia-debug-config.q\n" | \
            cat - julia.q > $(QHOME)/julia-debug.q
	chmod +x $(QHOME)/julia-debug.q

all: J.so jl.so

clean:
	rm -f J.so jl.so

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
print-%:
	@echo '$*=$($*)'
