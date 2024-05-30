#include "SaxonCXPath.h"

int64_t xdmValueAsObj(sxnc_environment *environi, const char *type,
                      const char *str) {

  /*jclass  saxoncClass = lookForClass(environi->env,
"net/sf/saxon/option/cpp/SaxonCAPI"); if(environi->env == NULL) { printf("Error:
Saxon-C env variable is NULL\n"); fflush (stdout); return NULL;
   }
  char methodName[] = "createXdmAtomicItem";
  char args[] =
"(Ljava/lang/String;Ljava/lang/String;)Lnet/sf/saxon/s9api/XdmValue;";

  static jmethodID MID_xdmValueo = NULL;
  if(!MID_xdmValueo) {
          MID_xdmValueo =
(jmethodID)(*(environi->env))->GetStaticMethodID(environi->env, saxoncClass,
methodName, args);
  }
 if (!MID_xdmValueo) {
    printf("\nError: MyClassInDll %s() not found\n",methodName);
    fflush (stdout);
    return NULL;
}
jobject resultObj = ((*(environi->env))->CallStaticObjectMethod(environi->env,
saxoncClass, MID_xdmValueo, type, str)); if(resultObj) { return resultObj;
} */
  return -1;
}

sxnc_value *xdmValue(sxnc_environment *environi, const char *type,
                     const char *str) {

  /*jclass  saxoncClass = lookForClass(environi->env,
"net/sf/saxon/option/cpp/SaxonCAPI"); if(environi->env == NULL) { printf("Error:
Saxon-C env variable is NULL\n"); fflush (stdout); return NULL;
   }
  char methodName[] = "createXdmAtomicValue";
  char args[] =
"(Ljava/lang/String;Ljava/lang/String;)Lnet/sf/saxon/s9api/XdmValue;";

  static jmethodID MID_xdmValue = NULL;
  if(!MID_xdmValue) {
          MID_xdmValue =
(jmethodID)(*(environi->env))->GetStaticMethodID(environi->env, saxoncClass,
methodName, args);
  }
 if (!MID_xdmValue) {
    printf("\nError: MyClassInDll %s() not found\n",methodName);
    fflush (stdout);
    return NULL;
}
jobject resultObj = ((*(environi->env))->CallStaticObjectMethod(environi->env,
saxoncClass, MID_xdmValue, type, str)); if(resultObj) { sxnc_value* result =
(sxnc_value *)malloc(sizeof(sxnc_value)); result->xdmvalue = resultObj; return
result;
} */
  return NULL;
}

int c_createXPathProcessor(sxnc_environment *environi,
                           sxnc_processor *processor, sxnc_xpath *xpath) {

  int64_t result = -1;

  if (processor) {
    result = createXPathProcessorWithProcessor(environi->thread,
                                               (void *)processor->value);
  } else {
    result = createXPathProcessor(environi->thread);
  }

  if (result == -2) {
    return 0;
  }

  (*xpath).xpathProc = result;

  return 1;
}

sxnc_value *evaluate(sxnc_environment *environi, sxnc_xpath *proc, char *cwd,
                     char *xpathStr, char *encoding, sxnc_parameter *parameters,
                     sxnc_property *properties, int parLen, int propLen) {

  if (!proc) {
    proc = (sxnc_xpath *)malloc(sizeof(sxnc_xpath));
    int check = c_createXPathProcessor(environi, NULL, proc);
    if (check == -2) {
      return NULL;
    }
  }

  int size = parLen + propLen;
  int64_t processorDataRef =
      createProcessorDataWithCapacity(environi->thread, size);
  if (size > 0) {

    int i = 0;
    for (i = 0; i < parLen; i++) {

      addProcessorDataPair(environi->thread, (void *)processorDataRef,
                           (char *)parameters[i].name,
                           (void *)parameters[i].value);
    }

    i++;
    int j = 0;
    for (; j < propLen; j++, i++) {
      addProcessorPropertyPair(environi->thread, (void *)processorDataRef,
                               (char *)properties[j].name,
                               (char *)properties[j].value);
    }
  }

  int64_t result = j_evaluate(environi->thread, (void *)proc->xpathProc, cwd,
                              xpathStr, encoding, (void *)processorDataRef);
  if (result == -2) {
    return NULL;
  }

  sxnc_value *resultValue = (sxnc_value *)malloc(sizeof(sxnc_value));
  resultValue->xdmvalue = result;

  return resultValue;
}

sxnc_value *evaluateSingle(sxnc_environment *environi, sxnc_xpath *proc,
                           char *cwd, char *xpathStr, char *encoding,
                           sxnc_parameter *parameters,
                           sxnc_property *properties, int parLen, int propLen) {

  if (!proc) {
    proc = (sxnc_xpath *)malloc(sizeof(sxnc_xpath));
    int check = c_createXPathProcessor(environi, NULL, proc);
    if (check == -2) {
      return NULL;
    }
  }

  int size = parLen + propLen;
  int64_t processorDataRef =
      createProcessorDataWithCapacity(environi->thread, size);
  if (size > 0) {

    int i = 0;
    for (i = 0; i < parLen; i++) {

      addProcessorDataPair(environi->thread, (void *)processorDataRef,
                           (char *)parameters[i].name,
                           (void *)parameters[i].value);
    }

    i++;
    int j = 0;
    for (; j < propLen; j++, i++) {
      addProcessorPropertyPair(environi->thread, (void *)processorDataRef,
                               (char *)properties[j].name,
                               (char *)properties[j].value);
    }
  }

  int64_t result =
      j_evaluateSingle(environi->thread, (void *)proc->xpathProc, cwd, xpathStr,
                       encoding, (void *)processorDataRef);
  if (result == -2) {
    return NULL;
  }

  sxnc_value *resultValue = (sxnc_value *)malloc(sizeof(sxnc_value));
  resultValue->xdmvalue = result;

  return resultValue;
}

bool effectiveBooleanValue(sxnc_environment *environi, sxnc_xpath *proc,
                           char *cwd, char *xpathStr, char *encoding,
                           sxnc_parameter *parameters,
                           sxnc_property *properties, int parLen, int propLen) {

  int size = parLen + propLen;

  if (!proc) {
    proc = (sxnc_xpath *)malloc(sizeof(sxnc_xpath));
    int check = c_createXPathProcessor(environi, NULL, proc);
    if (check == -2) {
      return NULL;
    }
  }

  int64_t processorDataRef =
      createProcessorDataWithCapacity(environi->thread, size);
  if (size > 0) {

    int i = 0;
    for (i = 0; i < parLen; i++) {

      addProcessorDataPair(environi->thread, (void *)processorDataRef,
                           (char *)parameters[i].name,
                           (void *)parameters[i].value);
    }

    i++;
    int j = 0;
    for (; j < propLen; j++, i++) {
      addProcessorPropertyPair(environi->thread, (void *)processorDataRef,
                               (char *)properties[j].name,
                               (char *)properties[j].value);
    }
  }

  int result =
      j_effectiveBooleanValue(environi->thread, (void *)proc->xpathProc, cwd,
                              xpathStr, encoding, (void *)processorDataRef);

  if (result == -2) {
    return 0;
  }

  return result;
}

const char *getStringValue(sxnc_environment *environi, sxnc_value value) {
  return (const char *)j_getStringValue(environi->thread,
                                        (void *)value.xdmvalue);
}

int size(sxnc_environment *environi, sxnc_value val) {

  /*jclass  xdmValueClass = lookForClass(environi->env,
"net/sf/saxon/s9api/XdmValue"); if(environi->env == NULL) { printf("Error:
Saxon-C env variable is NULL\n"); fflush (stdout); return 0;
   }
  char methodName[] = "size";
  char args[] = "()I";

  static jmethodID MID_xdmValue = NULL;
  if(!MID_xdmValue) {
          MID_xdmValue =
(jmethodID)(*(environi->env))->GetMethodID(environi->env, xdmValueClass,
methodName, args);
  }
 if (!MID_xdmValue) {
    printf("\nError: Saxon-C %s() not found\n",methodName);
    fflush (stdout);
    return 0;
}
jint result =
(jint)(*(environi->env))->CallIntMethod(environi->env,val.xdmvalue,
MID_xdmValue);

  return result;
*/
  return 0;
}

sxnc_value *itemAt(sxnc_environment *environi, sxnc_value val, int i) {

  /*jclass  xdmValueClass = lookForClass(environi->env,
"net/sf/saxon/s9api/XdmValue"); if(environi->env == NULL) { printf("Error:
Saxon-C env variable is NULL\n"); fflush (stdout); return 0;
   }
  char methodName[] = "itemAt";
  char args[] = "(I)Lnet/sf/saxon/s9api/XdmItem;";

  static jmethodID MID_xdmValue = NULL;
  if(!MID_xdmValue) {
          MID_xdmValue =
(jmethodID)(*(environi->env))->GetMethodID(environi->env, xdmValueClass,
methodName, args);
  }
 if (!MID_xdmValue) {
    printf("\nError: MyClassInDll %s() not found\n",methodName);
    fflush (stdout);
    return 0;
}
jobject xdmItemObj =
(*(environi->env))->CallObjectMethod(environi->env,val.xdmvalue, MID_xdmValue,
i); if(xdmItemObj) { sxnc_value* result = (sxnc_value
*)malloc(sizeof(sxnc_value)); result->xdmvalue = xdmItemObj;

  //checkForException(environi, cppClass, cpp);
  return result;
}
*/
  return 0;
}

bool isAtomicvalue(sxnc_environment *environi, sxnc_value val) {

  /*jclass  xdmItemClass = lookForClass(environi->env,
   "net/sf/saxon/s9api/XdmItem"); if(environi->env == NULL) { printf("Error:
   Saxon-C env variable is NULL\n"); fflush (stdout); return 0;
       }
      char methodName[] = "isAtomicValue";
      char args[] = "()Z";

      static jmethodID MID_xdmValue = NULL;
      if(!MID_xdmValue) {
              MID_xdmValue =
   (jmethodID)(*(environi->env))->GetMethodID(environi->env, xdmItemClass,
   methodName, args);
      }
     if (!MID_xdmValue) {
        printf("\nError: Saxon library - %s() not found\n",methodName);
        fflush (stdout);
        return 0;
    }
    jboolean result =
   (jboolean)(*(environi->env))->CallBooleanMethod(environi->env,val.xdmvalue,
   MID_xdmValue); return (bool)result;*/
  return false;
}

int getIntegerValue(sxnc_environment *environi, sxnc_value value,
                    int failureVal) {

  return (int)j_getLongValue(environi->thread, (void *)value.xdmvalue);
}

bool getBooleanValue(sxnc_environment *environi, sxnc_value value) {

  return (bool)j_getBooleanValue(environi->thread, (void *)value.xdmvalue);
}

long getLongValue(sxnc_environment *environi, sxnc_value value,
                  long failureVal) {

  return j_getLongValue(environi->thread, (void *)value.xdmvalue);
}

float getFloatValue(sxnc_environment *environi, sxnc_value value,
                    float failureVal) {

  return (float)j_getDoubleValue(environi->thread, (void *)value.xdmvalue);
}

double getDoubleValue(sxnc_environment *environi, sxnc_value value,
                      double failureVal) {

  return j_getDoubleValue(environi->thread, (void *)value.xdmvalue);
}
