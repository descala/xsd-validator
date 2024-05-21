#include <stdio.h> /* defines FILENAME_MAX */
#if defined(__APPLE__) || defined __linux__
#include <unistd.h>
#define GetCurrentDir getcwd
#else
#include <direct.h>
#define GetCurrentDir _getcwd
#endif

#include "../../Saxon.C.API/SaxonCProcessor.h"

int exists(const char *fname) {
  FILE *file;
  if ((file = fopen(fname, "r"))) {
    fclose(file);
    return 1;
  }
  return 0;
}

int main() {

  char cwd[FILENAME_MAX]; // create string buffer to hold path
  GetCurrentDir(cwd, FILENAME_MAX);
  printf("CWD = %s\n", cwd);
  int cap = 10;
  sxnc_parameter *parameters;
  int parLen = 0, parCap;
  parCap = cap;
  sxnc_property *properties;
  int propLen = 0;
  parCap = cap;
  sxnc_environment *environi;
  sxnc_processor *processor;

  initSaxonc(&environi, &processor, &parameters, &properties, parCap, parCap);

  create_graalvm_isolate(environi);

  int checkProc = c_createSaxonProcessor(environi, processor, 0);

  if (!checkProc) {
    const char *errorMessage = c_getErrorMessage(environi);
    if (errorMessage) {
      printf("Error message: %s \n", errorMessage);
    }
    return -1;
  }

  const char *verCh = getProductVariantAndVersion(environi, processor);
  printf("XSLT Tests\n\nSaxon version: %s \n", verCh);

  const char *result =
      xsltApplyStylesheet(environi, processor, cwd, "../data/cat.xml",
                          "../data/test.xsl", 0, 0, 0, 0);

  xsltSaveResultToFile(environi, processor, cwd, "../data/cat.xml",
                       "../data/test.xsl", "../outputFile.xml", 0, 0, 0, 0);

  if (!result) {
    printf("result is null \n");
    const char *errorMessage = c_getErrorMessage(environi);
    if (errorMessage) {
      printf("Error message %s \n", errorMessage);
    }
  } else {
    printf("Test 1 Pass: %s", result);
  }

  if (exists("../outputFile.xml")) {
    printf("Test 2 - Pass: outputFile.xml exists \n");
  } else {
    printf("Test 2 - Fail: outputFile.xml not found \n");
  }

  fflush(stdout);

  graal_tear_down(environi->thread);
  return 0;
}
