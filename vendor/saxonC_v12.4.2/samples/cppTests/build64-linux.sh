#!/bin/sh

#Build file for SaxonC on C++

export SAXON_ERRORS="-Wall -Werror -Wextra"

export TURN_ERRORS_TO_WARNINGS="-Wno-error=sizeof-pointer-memaccess -Wno-error=unused-value -Wno-error=extra -Wno-error=reorder -Wno-error=sign-compare -Wno-error=unused-variable -Wno-error=unused-parameter -Wno-error=return-type -Wno-error=unused-but-set-variable"

library_dir=../../libs/nix

rm -r bin
mkdir -p bin

gcc  -g   -fPIC -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/SaxonCGlue.c -o bin/SaxonCGlue.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

gcc  -g  -fPIC  -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/SaxonCXPath.c -o bin/SaxonCXPath.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

#g++  -std=c++14 -fPIC  -g  -c cppExtensionFunction.cpp -o bin/cppExtensionFunction.o $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XdmValue.cpp -o bin/XdmValue.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XdmItem.cpp -o bin/XdmItem.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XdmNode.cpp -o bin/XdmNode.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/XdmMap.cpp -o bin/XdmMap.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/XdmArray.cpp -o bin/XdmArray.o -ldl -lc -lsaxon-hec-12.4.2 $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g   -fPIC -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/XdmFunctionItem.cpp -o bin/XdmFunctionItem.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XdmAtomicValue.cpp -o bin/XdmAtomicValue.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/DocumentBuilder.cpp -o bin/DocumentBuilder.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/SaxonProcessor.cpp -o bin/SaxonProcessor.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g  -fPIC  -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/SaxonApiException.cpp -o bin/SaxonApiException.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/Xslt30Processor.cpp -o bin/Xslt30Processor.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++ -std=c++14  -g   -fPIC -I../../Saxon.C.API/graalvm -c ../../Saxon.C.API/XsltExecutable.cpp -o bin/XsltExecutable.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XQueryProcessor.cpp -o bin/XQueryProcessor.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/XPathProcessor.cpp -o bin/XPathProcessor.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/SchemaValidator.cpp -o bin/SchemaValidator.o -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS $@


g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm -pthread bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o bin/XsltExecutable.o bin/Xslt30Processor.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmMap.o bin/XdmFunctionItem.o bin/SchemaValidator.o bin/SaxonApiException.o  testXSLT30.cpp -o testXSLT30 -Wl,-rpath,$library_dir -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS -L$library_dir $@
g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o bin/Xslt30Processor.o bin/XsltExecutable.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmFunctionItem.o bin/XdmMap.o bin/SchemaValidator.o bin/SaxonApiException.o testXQuery.cpp -o testXQuery -Wl,-rpath,$library_dir -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS -L$library_dir $@


g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o  bin/Xslt30Processor.o bin/XsltExecutable.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmFunctionItem.o bin/XdmMap.o bin/SchemaValidator.o  bin/SaxonApiException.o testXPath.cpp -o testXPath -Wl,-rpath,$library_dir -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS -L$library_dir $@

g++  -std=c++14  -g  -fPIC -I../../Saxon.C.API/graalvm bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o bin/Xslt30Processor.o bin/XsltExecutable.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmFunctionItem.o bin/XdmMap.o bin/SchemaValidator.o bin/SaxonApiException.o testValidator.cpp -o testValidator -Wl,-rpath,$library_dir -ldl -lc -lsaxon-hec-12.4.2  $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS -L$library_dir $@

#g++  -std=c++14 -fPIC  -g  -shared -Wl,-soname,cppExtensionFunction.so -o  cppExtensionFunction.so bin/cppExtensionFunction.o $TURN_ERRORS_TO_WARNINGS $SAXON_ERRORS -L$library_dir $@
