/*
Builds the vendored Lua library as a single translation unit, the same way
mem.c builds mimalloc. Lua is compiled without LUA_USE_LINUX/MACOSX/POSIX so
that it sticks to ISO C and provides no dynamic loading or process spawning.

Upstream warnings are none of our business, so every build system compiles
this file with warnings turned off: common.make passes -w, Meson lowers the
warning level of the target, and the Visual Studio project turns them off for
this file.
*/

#define MAKE_LIB
#include "lua/onelua.c"
