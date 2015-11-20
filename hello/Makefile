CFLAGS = -W -Wall -I../vix/include
LDFLAGS = -L../vix -lvixAllProducts

all: powerOn2

powerOn2: powerOn
	cp $< $@
	install_name_tool -change libvixAllProducts.dylib /Applications/VMware\ Fusion.app/Contents/Public/libvixAllProducts.dylib $@
