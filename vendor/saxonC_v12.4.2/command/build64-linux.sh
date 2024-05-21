#!/bin/sh

#Build file for SaxonC on C++

library_dir="../libs/nix"

gcc -m64 -std=c99 -fPIC -I../Saxon.C.API/graalvm  -c ../Saxon.C.API/SaxonCGlue.c -o SaxonCGlue.o $@

gcc -m64 -std=c99 -fPIC -I../Saxon.C.API/graalvm  Transform.c  -o transform -ldl -lc SaxonCGlue.o -L$library_dir -lsaxon-hec-12.4.2 -L$library_dir -Wl,-rpath,$library_dir $@

gcc -m64 -std=c99 -fPIC -I../Saxon.C.API/graalvm Query.c -o query -ldl -lc SaxonCGlue.o -L$library_dir -lsaxon-hec-12.4.2 -L$library_dir -Wl,-rpath,$library_dir $@

if [ -f Validate.c ]; then
    gcc -m64 -std=c99 -fPIC -I../Saxon.C.API/graalvm Validate.c -o validate -ldl -lc SaxonCGlue.o -L$library_dir -lsaxon-hec-12.4.2 -L$library_dir -Wl,-rpath,$library_dir $@
fi

