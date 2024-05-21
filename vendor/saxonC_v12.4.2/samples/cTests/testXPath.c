#include "../../Saxon.C.API/SaxonCXPath.h"
#include <stdio.h> /* defines FILENAME_MAX */
#if defined(__APPLE__) || defined __linux__
#include <unistd.h>
#define GetCurrentDir getcwd
#else
#include <direct.h>
#define GetCurrentDir _getcwd
#endif

int main() {

  char cwd[FILENAME_MAX]; // create string buffer to hold path
  GetCurrentDir(cwd, FILENAME_MAX);
  printf("CWD = %s\n", cwd);
  int cap = 10;
  sxnc_parameter *parameters; /*!< array of paramaters used for the
                                 transformation as (string, value) pairs */
  int parLen = 0, parCap;
  parCap = cap;
  sxnc_property *properties; /*!< array of properties used for the
                                transformation as (string, string) pairs */
  int propLen = 0, propCap;
  propCap = cap;
  sxnc_environment *environi;
  sxnc_processor *processor;

  initSaxonc(&environi, &processor, &parameters, &properties, parCap, propCap);

  /*
   * Initialize Graalvm run-time.
   * The handle of loaded component is used to retrieve Invocation API.
   */

  create_graalvm_isolate(environi);

  c_createSaxonProcessor(environi, processor, 0);

  sxnc_xpath *xpathProc = (sxnc_xpath *)malloc(sizeof(sxnc_xpath));

  int checkProc = c_createXPathProcessor(environi, processor, xpathProc);

  if (!checkProc) {
    const char *errorMessage = c_getErrorMessage(environi);
    if (errorMessage) {
      printf("Error message: %s \n", errorMessage);
    }
    return -1;
  }

  const char *verCh = version(environi, processor);
  printf("XPath Tests\n\nSaxon version: %s \n", verCh);
  setProperty(&properties, &propLen, &propCap, "s", "../data/cat.xml");

  sxnc_value *result = evaluate(environi, xpathProc, cwd, "/out/person", NULL,
                                parameters, properties, 0, propLen);

  bool resultBool =
      effectiveBooleanValue(environi, xpathProc, cwd, "count(/out/person)>0", NULL,
                            parameters, properties, parLen, propLen);

  if (!result) {
    printf("result is null");
  } else {
    printf("Test 1  - Result = %s\n", getStringValue(environi, *result));
  }

  if (resultBool == 1) {
    printf("Test 2 - Boolean result is as expected: true\n");
  } else {
    printf("Boolean result is incorrectly: false");
    const char *errorMessage = c_getErrorMessage(environi);
    if (errorMessage) {
      printf("Error message %s \n", errorMessage);
    }
  }
  fflush(stdout);

  graal_tear_down(environi->thread);
  freeSaxonc(&environi, &processor, &parameters, &properties);
  return 0;
}
