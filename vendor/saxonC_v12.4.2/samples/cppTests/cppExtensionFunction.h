//
// Created by O'Neil Delpratt on 14/01/2021.
//

#ifndef CPPTESTS_CPPEXTENSIONFUNCTION_H
#define CPPTESTS_CPPEXTENSIONFUNCTION_H

#include <sstream>

#include "../../Saxon.C.API/SaxonProcessor.h"
#include "../../Saxon.C.API/XdmAtomicValue.h"
#include "../../Saxon.C.API/XdmItem.h"
#include "../../Saxon.C.API/XdmNode.h"
#include "../../Saxon.C.API/XdmValue.h"
#include <string>

// TODO: write test case for checking parameters which are null

using namespace std;

class cppExtensionFunction {
public:
  static jobject JNICALL cppNativeCall(jstring funcName, jobjectArray arguments,
                                       jobjectArray argTypes);

  static string nativeExtensionMethod(char *param1, int number);

private:
};

#endif // CPPTESTS_CPPEXTENSIONFUNCTION_H
