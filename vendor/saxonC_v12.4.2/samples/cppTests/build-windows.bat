set graalvmdir=..\..\Saxon.C.API\graalvm

cl /EHsc "-I%graalvmdir%"  testXPath.cpp ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCXPath.c  ../../Saxon.C.API/SaxonProcessor.cpp ../../Saxon.C.API/XdmValue.cpp ../../Saxon.C.API/XdmItem.cpp ../../Saxon.C.API/XdmAtomicValue.cpp ../../Saxon.C.API/DocumentBuilder.cpp ../../Saxon.C.API/XdmNode.cpp ../../Saxon.C.API/XdmFunctionItem.cpp ../../Saxon.C.API/XdmArray.cpp ../../Saxon.C.API/XdmMap.cpp ../../Saxon.C.API/SaxonApiException.cpp ../../Saxon.C.API/XQueryProcessor.cpp ../../Saxon.C.API/Xslt30Processor.cpp ../../Saxon.C.API/XsltExecutable.cpp ../../Saxon.C.API/XPathProcessor.cpp ../../Saxon.C.API/SchemaValidator.cpp /link ..\..\libs\win\libsaxon-hec-12.4.2.lib
cl /EHsc "-I%graalvmdir%"  testXSLT30.cpp ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCXPath.c  ../../Saxon.C.API/SaxonProcessor.cpp ../../Saxon.C.API/XdmValue.cpp ../../Saxon.C.API/XdmItem.cpp ../../Saxon.C.API/XdmAtomicValue.cpp ../../Saxon.C.API/DocumentBuilder.cpp ../../Saxon.C.API/XdmNode.cpp ../../Saxon.C.API/XdmFunctionItem.cpp ../../Saxon.C.API/XdmArray.cpp ../../Saxon.C.API/XdmMap.cpp ../../Saxon.C.API/SaxonApiException.cpp ../../Saxon.C.API/XQueryProcessor.cpp ../../Saxon.C.API/Xslt30Processor.cpp ../../Saxon.C.API/XsltExecutable.cpp ../../Saxon.C.API/XPathProcessor.cpp ../../Saxon.C.API/SchemaValidator.cpp /link ..\..\libs\win\libsaxon-hec-12.4.2.lib
cl /EHsc "-I%graalvmdir%"  testXQuery.cpp ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCXPath.c  ../../Saxon.C.API/SaxonProcessor.cpp ../../Saxon.C.API/XdmValue.cpp ../../Saxon.C.API/XdmItem.cpp ../../Saxon.C.API/XdmAtomicValue.cpp ../../Saxon.C.API/DocumentBuilder.cpp ../../Saxon.C.API/XdmNode.cpp ../../Saxon.C.API/XdmFunctionItem.cpp ../../Saxon.C.API/XdmArray.cpp ../../Saxon.C.API/XdmMap.cpp ../../Saxon.C.API/SaxonApiException.cpp ../../Saxon.C.API/XQueryProcessor.cpp ../../Saxon.C.API/Xslt30Processor.cpp ../../Saxon.C.API/XsltExecutable.cpp ../../Saxon.C.API/XPathProcessor.cpp ../../Saxon.C.API/SchemaValidator.cpp /link ..\..\libs\win\libsaxon-hec-12.4.2.lib
cl /EHsc "-I%graalvmdir%"  testValidator.cpp ../../Saxon.C.API/SaxonCGlue.c ../../Saxon.C.API/SaxonCXPath.c ../../Saxon.C.API/SaxonProcessor.cpp ../../Saxon.C.API/XdmValue.cpp ../../Saxon.C.API/XdmItem.cpp ../../Saxon.C.API/XdmAtomicValue.cpp ../../Saxon.C.API/DocumentBuilder.cpp ../../Saxon.C.API/XdmNode.cpp ../../Saxon.C.API/XdmFunctionItem.cpp ../../Saxon.C.API/XdmArray.cpp ../../Saxon.C.API/XdmMap.cpp ../../Saxon.C.API/SaxonApiException.cpp ../../Saxon.C.API/XQueryProcessor.cpp ../../Saxon.C.API/Xslt30Processor.cpp ../../Saxon.C.API/XsltExecutable.cpp ../../Saxon.C.API/XPathProcessor.cpp ../../Saxon.C.API/SchemaValidator.cpp /link ..\..\libs\win\libsaxon-hec-12.4.2.lib