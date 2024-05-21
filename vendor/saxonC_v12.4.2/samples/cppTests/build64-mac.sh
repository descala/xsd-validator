#!/bin/sh

#Build file for SaxonC on C++

export SAXON_ERRORS="-Wall -Werror -Wextra"

export TURN_ERRORS_TO_WARNINGS="-Wno-error=sizeof-pointer-memaccess -Wno-error=unused-value -Wno-error=extra -Wno-error=reorder -Wno-error=sign-compare -Wno-error=unused-variable -Wno-error=unused-parameter -Wno-error=return-type -Wno-error=unused-but-set-variable"

library_dir="../../libs/nix"

rm -rf bin
mkdir -p bin

gcc -fPIC -I../../Saxon.C.API/graalvm  -c ../../Saxon.C.API/SaxonCGlue.c -o bin/SaxonCGlue.o $@

gcc -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/SaxonCXPath.c -o bin/SaxonCXPath.o $@

#g++ -std=c++14 -fPIC -I../../Saxon.C.API/graalvm   -c cppExtensionFunction.cpp -o bin/cppExtensionFunction.o

g++ -std=c++14 -g  -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmValue.cpp -o bin/XdmValue.o $@

g++ -std=c++14 -g  -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmItem.cpp -o bin/XdmItem.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmMap.cpp -o bin/XdmMap.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmArray.cpp -o bin/XdmArray.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmNode.cpp -o bin/XdmNode.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmFunctionItem.cpp -o bin/XdmFunctionItem.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XdmAtomicValue.cpp -o bin/XdmAtomicValue.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/DocumentBuilder.cpp -o bin/DocumentBuilder.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/SaxonProcessor.cpp -o bin/SaxonProcessor.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/SaxonApiException.cpp -o bin/SaxonApiException.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/Xslt30Processor.cpp -o bin/Xslt30Processor.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XsltExecutable.cpp -o bin/XsltExecutable.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XQueryProcessor.cpp -o bin/XQueryProcessor.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/XPathProcessor.cpp -o bin/XPathProcessor.o $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm   -c ../../Saxon.C.API/SchemaValidator.cpp -o bin/SchemaValidator.o $@

g++ -std=c++14 -g  -g -fPIC -pthread -I../../Saxon.C.API/graalvm   bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o  bin/XsltExecutable.o bin/Xslt30Processor.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmMap.o bin/XdmFunctionItem.o bin/SchemaValidator.o bin/SaxonApiException.o testXSLT30.cpp -o testXSLT30 -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@

g++ -std=c++14 -g   -fPIC -I../../Saxon.C.API/graalvm   bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o  bin/XsltExecutable.o bin/Xslt30Processor.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmFunctionItem.o bin/XdmMap.o bin/SchemaValidator.o bin/SaxonApiException.o testXQuery.cpp -o testXQuery -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2  -L$library_dir $@


g++ -std=c++14 -g  -g -fPIC -I../../Saxon.C.API/graalvm  bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o  bin/XsltExecutable.o bin/Xslt30Processor.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmMap.o bin/XdmFunctionItem.o bin/SchemaValidator.o bin/SaxonApiException.o testXPath.cpp -o testXPath -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@

g++ -std=c++14 -g -fPIC -I../../Saxon.C.API/graalvm  bin/SaxonCGlue.o bin/SaxonCXPath.o bin/SaxonProcessor.o bin/XQueryProcessor.o  bin/XsltExecutable.o bin/Xslt30Processor.o bin/XPathProcessor.o bin/DocumentBuilder.o bin/XdmValue.o bin/XdmItem.o bin/XdmNode.o bin/XdmAtomicValue.o bin/XdmArray.o bin/XdmMap.o bin/XdmFunctionItem.o bin/SchemaValidator.o bin/SaxonApiException.o testValidator.cpp -o testValidator -Wl,-rpath,@executable_path/$library_dir -ldl -lsaxon-hec-12.4.2 -L$library_dir $@


