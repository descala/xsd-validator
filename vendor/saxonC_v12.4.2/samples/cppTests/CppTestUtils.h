////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef CPPTESTS_CPPTESTUTILS_H
#define CPPTESTS_CPPTESTUTILS_H

#if defined(__linux__) || defined(__APPLE__) || defined(__MACH__)
#include <unistd.h>
#define GetCurrentDir getcwd
#else
#include <direct.h>
#define GetCurrentDir _getcwd
#endif

#include <list>

typedef struct {
  int success;
  int failure;
  std::list<std::string> failureList;

} sResultCount;

class CppTestUtils {

public:
  static int exists(const char *fname) {
    FILE *file;
    file = fopen(fname, "r");
    if (file) {
      fclose(file);
      return 1;
    }
    return 0;
  }

  static int assertEquals(const char *str1, const char *str2) {
    if (str1 != nullptr && str2 != nullptr) {
      return strcmp(str1, str2) == 0;
    } else {
      return 1;
    }
  }

private:
};

#endif // CPPTESTS_CPPTESTUTILS_H
