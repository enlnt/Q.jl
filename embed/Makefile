JL_SHARE = $(shell julia -e 'print(joinpath(JULIA_HOME,Base.DATAROOTDIR,"julia"))')
CFLAGS   += -DKXVER=3
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)
SOFLAGS_Linux = -shared -fPIC
SOFLAGS_Darwin = -bundle -undefined dynamic_lookup
SOFLAGS  += $(SOFLAGS_$(shell uname))

J.so: J.c
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(SOFLAGS)

install: J.so
	cp J.k julia.q $(QHOME)
	cp J.so $(QHOME)/$(QARCH)

all: J.so

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
print-%:
	@echo '$*=$($*)'
