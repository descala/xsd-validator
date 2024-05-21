set graalvmdir=..\..\Saxon.C.API\graalvm

cl /EHsc "-I%graalvmdir%" testXSLT.c ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c ../../Saxon.C.API/SaxonCXPath.c   /link ..\..\libs\win\libsaxon-hec-12.4.2.lib

cl /EHsc "-I%graalvmdir%" testXQuery.c ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c /link ..\..\libs\win\libsaxon-hec-12.4.2.lib

cl /EHsc "-I%graalvmdir%" testXPath.c   ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCProcessor.c ../../Saxon.C.API/SaxonCXPath.c  /link ..\..\libs\win\libsaxon-hec-12.4.2.lib
