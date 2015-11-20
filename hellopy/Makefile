SHELL = /bin/bash -eu
.DELETE_ON_ERROR:

all: foo.so
	python test.py

foo.so: foo.c
	gcc -shared -fPIC $< \
		-I/System/Library/Frameworks/Python.framework/Headers \
		-I../vix/include \
		-lpython \
		-L../vix -l vixAllProducts \
	-o $@
	install_name_tool -change libvixAllProducts.dylib /Applications/VMware\ Fusion.app/Contents/Public/libvixAllProducts.dylib $@

foo.c: foo.pyx
	cython $<


