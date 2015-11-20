#import pyximport
#pyximport.install(setup_args={
#    'include_dirs': '../vix/include',
#    'libraries': ['libvixAllProducts.dylib']
#})

import foo

print dir(foo)

#x = foo.VixHostConnect(-1,
#                   3,
#                   "",
#                   0,
#                   "",
#                   "",
#                   0,
#                   -1,
#                   0,
#                   0);
#print repr(x);
