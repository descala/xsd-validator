////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if defined __linux__ || defined __APPLE__
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#else
#include <windows.h>
#endif

#include "../Saxon.C.API/SaxonCGlue.h"
//#include "../Saxon.C.API/SaxonApiException.h"

const char *failure;

int gizmo(sxnc_environment *environi, int argc, const char *argv[]) {

#ifdef DEBUG
  setDebugMode(environi->thread, 1);
#endif

  if (argc < 2) {
    printf("\nError: Not enough arguments in Transform");
    return 0;
  }
  int64_t processorDataRef =
      createProcessorDataWithCapacity(environi->thread, argc);

  for (int i = 1; i < argc; i++) {
#ifdef DEBUG
    printf("\nArgument = %s", (char *)argv[i]);
#endif
    addProcessorProperty(environi->thread, (void *)processorDataRef,
                         (char *)argv[i]);
  }
#ifdef DEBUG
  printf("\nprocessorData = %i", (int)processorDataRef);
#endif
  long status = j_run_gizmo(environi->thread, (void *)processorDataRef);
#ifdef DEBUG
  printf("\nj_run_gizmo status=%i", (int)status);
  if (status == -1) {
    printf("\nProcessorDataRef is null");
  }
#endif

  return 0;
}

int main(int argc, const char *argv[]) {
  sxnc_environment *environi;
  environi = (sxnc_environment *)malloc(sizeof(sxnc_environment));
  create_graalvm_isolate(environi);
#ifdef DEBUG
  setDebugMode(environi->thread, 1);
#endif
  gizmo(environi, argc, argv);

  fflush(stdout);
  if (graal_detach_thread(environi->thread) != 0) {
    fprintf(stderr, "graal_detach_thread error\n");
    return -1;
  }

  return 0;
}
