# PLAT ?= none
PLAT ?= linux
PLATS = linux freebsd macosx

CC ?= gcc

.PHONY : none $(PLATS) 

#ifneq ($(PLAT), none)

.PHONY : default

default :
	$(MAKE) $(PLAT)

#endif

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

BNH_LIBS := -pthread -lm
SHARED := -fPIC --shared

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
macosx linux : BNH_LIBS += -ldl
linux freebsd : BNH_LIBS += -lrt

linux freebsd : CJSON_DEP :=
macosx : CJSON_DEP :=CJSON_LDFLAGS='-bundle -undefined dynamic_lookup'\
		FPCONV_OBJS='g_fmt.o dtoa.o'

linux freebsd : OPEN_SSL_LIB :=
macosx : OPEN_SSL_LIB :=-I/usr/local/opt/openssl/include -L/usr/local/opt/openssl/lib

linux macosx freebsd :
	$(MAKE) all  PLAT=$(PLAT) BNH_LIBS="$(BNH_LIBS)" SHARED="$(SHARED)"   CJSON_DEP="$(CJSON_DEP)"  OPEN_SSL_LIB="$(OPEN_SSL_LIB)"