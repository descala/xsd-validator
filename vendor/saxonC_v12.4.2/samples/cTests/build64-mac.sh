#!/bin/sh

jdkdir=../../Saxon.C.API/graalvm

library_dir="../../libs/nix"

gcc  -std=c99 -fPIC -I$jdkdir ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c ../../Saxon.C.API/SaxonCXPath.c  testXSLT.c -o testXSLT -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@

gcc  -std=c99 -fPIC -I$jdkdir ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c  testXQuery.c -o testXQuery -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@
	
gcc  -std=c99 -fPIC -I$jdkdir ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c ../../Saxon.C.API/SaxonCXPath.c testXPath.c -o testXPath -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@

