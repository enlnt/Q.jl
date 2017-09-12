JL_SHARE = $(shell julia -e 'print(joinpath(JULIA_HOME,Base.DATAROOTDIR,"julia"))')
CFLAGS   += -DKXVER=3
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)
SOFLAGS_Linux = -shared -fPIC
SOFLAGS_Darwin = -bundle -undefined dynamic_lookup
SOFLAGS  += $(SOFLAGS_$(shell uname))

JULIA_HOME = $(shell julia -e 'print(joinpath(JULIA_HOME))')
JULIA_LIB = $(shell julia -e 'print(Libdl.dlpath("libjulia"))')
JULIA_DEBUG_LIB = \
  $(shell $(JULIA_HOME)/julia-debug -e 'print(Libdl.dlpath("libjulia-debug"))')

J.so: J.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(SOFLAGS)

install: J.so
	cp J.k $(QHOME)
	cp J.so $(QHOME)/$(QARCH)
	echo ".J.home:\"$(JULIA_HOME)\"" > $(QHOME)/julia-config.q
	echo ".J.lib:\"$(JULIA_LIB)\"" >> $(QHOME)/julia-config.q
	echo "#! $(QHOME)/$(QARCH)/q" | cat - julia.q > $(QHOME)/julia.q
	chmod +x $(QHOME)/julia.q

all: J.so

clean:
	rm -f J.so

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
print-%:
	@echo '$*=$($*)'
