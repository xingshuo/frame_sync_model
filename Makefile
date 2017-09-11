include platform.mk

TOP=$(CURDIR)
BUILD_DIR=./build
INC_DIR=./include
CFLAGS = -g3 -O2 -rdynamic -Wall -I$(INC_DIR)

all: build-skynet

build-skynet:
	cd skynet && $(MAKE) linux

$(BUILD):
	mkdir $(BUILD_DIR)

all: sproto | $(BUILD)

sproto:
	export LUA_CPATH=$(TOP)/skynet/luaclib/?.so && cd $(TOP)/3rd/sprotodump/ \
	&& $(TOP)/bin/lua sprotodump.lua -spb `find -L $(TOP)/common/sproto/  -name "*.sproto"` -o $(TOP)/build/sproto.spb

pysproto:
	cd $(TOP)/3rd/pysproto && $(TOP)/bin/python setup.py build \
	&& $(TOP)/bin/python setup.py install && rm -rf build pysproto.egg-info dist

clean:
	rm -f $(BUILD_DIR)/luaclib/*
