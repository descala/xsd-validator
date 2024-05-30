set graalvmdir=..\Saxon.C.API\graalvm

cl /EHsc "-I%graalvmdir%" /DEEC Transform.c ../Saxon.C.API/SaxonCGlue.c /link ..\libs\win\libsaxon-hec-12.4.2.lib

cl /EHsc "-I%graalvmdir%" /DEEC Query.c ../Saxon.C.API/SaxonCGlue.c /link ..\libs\win\libsaxon-hec-12.4.2.lib

if exist Validate.c cl /EHsc "-I%graalvmdir%"  /DEEC Validate.c ../Saxon.C.API/SaxonCGlue.c /link ..\libs\win\libsaxon-hec-12.4.2.lib
