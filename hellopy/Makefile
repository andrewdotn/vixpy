SHELL = /bin/bash -eu
.DELETE_ON_ERROR:

all: vix.so
	python3.5 experiment.py

vix.so: vix.c
	gcc -shared -fPIC $< \
		-I/opt/homebrew/Frameworks/Python.framework/Versions/3.5/Headers \
		-I../vix/include \
		-L/opt/homebrew/Frameworks/Python.framework/Versions/3.5/lib \
		-lpython3.5 \
		-L../vix -l vixAllProducts \
	-o $@
	install_name_tool -change libvixAllProducts.dylib /Applications/VMware\ Fusion.app/Contents/Public/libvixAllProducts.dylib $@

vix.c: vix.pyx
	cython $<

clean:
	rm -f vix.c vix.so
