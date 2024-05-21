#include "SaxonCGlue.h"

char *resources_dir;
/*jobject cpp;
char * dllname;

int jvmCreated = 0;
char * tempDllname =
#if defined (__linux__)
"/libsaxonhec.so";
#elif  defined (__APPLE__) && defined(__MACH__)
"/libsaxonhec.dylib";
#else
"\\libsaxonhec.dll";
#endif

char * dllPath =
#if defined (__linux__)
"/usr/lib";
#elif  defined (__APPLE__) && defined(__MACH__)
"/usr/local/lib";
#else
"C:\\Program Files\\Saxonica\\SaxonHEC 12.4.2";
#endif*/

char *_getResourceDirectory() { return resources_dir; }

/*
 * Load dll.
 */
int create_graalvm_isolate(sxnc_environment *env) {

  if (graal_create_isolate(NULL, &((env)->isolate), &((env)->thread)) != 0) {
    fprintf(stderr, "graal_create_isolate error\n");
    return 1;
  }
  (env)->mainthread = (env)->thread;
  /*fprintf(stdout, "main thread pointer %p\n", (void *)(((env)->thread)));
  fflush(stdout);*/
  return 0;
}

int attach_graalvm_thread(sxnc_environment *env) {
  graal_isolatethread_t *newthread = graal_get_current_thread(((env)->isolate));
  if (newthread) {
    /*fprintf(stdout, "Cur attach thread pointer same %p\n", (void *)newthread);
    fflush(stdout);*/
    (env)->thread = newthread;
    return 1;
  }

  if (graal_attach_thread(((env)->isolate), &newthread) != 0) {
    /*fprintf(stdout, "graal_attach_thread error\n");
    fflush(stdout);*/
    return 1;
  }
  /*fprintf(stdout, "graal_attach_thread pointer %p\n", (void *)newthread);
  fflush(stdout);*/
  (env)->thread = newthread;
  return 0;
}

int detach_graalvm_thread(sxnc_environment *env) {
  graal_isolatethread_t *curthread = graal_get_current_thread(((env)->isolate));
  if (!curthread) {
    if (getenv("SAXONC_DEBUG_FLAG")) {
      fprintf(stdout, "Cur detach thread pointer not in isolate \n");
      fflush(stdout);
    }
    return 1;
  }
  if (getenv("SAXONC_DEBUG_FLAG")) {
    fprintf(stdout, "detach: Cur thread pointer %p\n", (void *)curthread);
    fflush(stdout);
  }
  if (graal_detach_thread(curthread) != 0) {
    if (getenv("SAXONC_DEBUG_FLAG")) {
      fprintf(stdout, "graal_detach_thread error\n");
      fflush(stdout);
    }
    return 1;
  }
  (env)->thread = (env)->mainthread;
  if (getenv("SAXONC_DEBUG_FLAG")) {
    fprintf(stdout, "graal_dettach_thread pointer %p\n",
            (void *)((env)->thread));
    fflush(stdout);
  }

  return 0;
}

/*
 * Create the Java SaxonProcessor
 */
int64_t createSaxonProcessor2(graal_isolatethread_t *thread, int license) {
  return createSaxonProcessor(thread, license);
}

int c_createSaxonProcessor(sxnc_environment *environii, sxnc_processor *proc,
                           int license) {
  int64_t result = createSaxonProcessor(environii->thread, license);

  if (result == -2) {
    return 0;
  }

  (*proc).value = result;

  return 1;
}

/*
 * Callback to check for exceptions. When called it returns the exception as a
 * string
 */
const char *checkForException(sxnc_environment *environii) { return 0; }

/*
 * Clean up and destroy Java VM to release memory used.
 */
void graal_tear_down(graal_isolatethread_t *thread) {

  // if (jvmCreated != 0) {
  graal_tear_down_isolate(thread);
  //	jvmCreated = 0;
  //	}
}

/*
 * Get a parameter from list
 */
int64_t getParameter(sxnc_parameter *parameters, int parLen, const char *name) {
  int i = 0;
  for (i = 0; i < parLen; i++) {
    if (strcmp(parameters[i].name, name) == 0)
      return parameters[i].value;
  }
  return 0;
}

/*
 * Get a property from list
 */
char *getProperty(sxnc_property *properties, int propLen, const char *name) {
  int i = 0;
  for (i = 0; i < propLen; i++) {
    if (strcmp(properties[i].name, name) == 0)
      return properties[i].value;
  }
  return 0;
}

/*
 * set a parameter
 */
void setParameter(sxnc_parameter **parameters, int *parLen, int *parCap,
                  const char *name, sxnc_value *value) {
  if (getParameter(*parameters, *parLen, name) != 0) {
    return;
  }
  (*parLen)++;
  if ((*parLen) >= (*parCap)) {
    (*parCap) *= 2;
    sxnc_parameter *temp =
        realloc(*parameters, sizeof(sxnc_parameter) * (*parCap));
    if (temp == NULL) {
      /* XXX: handle the error */
      return;
    }
    *parameters = temp;
  }
  int nameLen = strlen(name) + 7;
  char *newName = malloc(sizeof(char) * nameLen);
  snprintf(newName, nameLen, "%s%s", "param:", name);
  (*parameters)[(*parLen) - 1].name = (char *)newName;
  (*parameters)[(*parLen) - 1].value = value->xdmvalue;
}

/*
 * set a property
 */
void setProperty(sxnc_property **properties, int *propLen, int *propCap,
                 const char *name, const char *value) {
  if (getProperty(*properties, *propLen, name) != 0) {
    return;
  }

  if (((*propLen) + 1) >= (*propCap)) {
    (*propCap) *= 2;
    sxnc_property *temp =
        realloc(*properties, sizeof(sxnc_property) * (*propCap));
    if (temp == NULL) {
      /* XXX: handle the error */
      return;
    }
    *properties = temp;
  }
  int nameLen = strlen(name) + 1;
  char *newName = (char *)malloc(sizeof(char) * nameLen);
  snprintf(newName, nameLen, "%s", name);
  char *newValue = (char *)malloc(sizeof(char) * strlen(value) + 1);
  snprintf(newValue, strlen(value) + 1, "%s", value);
  (*properties)[(*propLen)].name = (char *)newName;
  (*properties)[(*propLen)].value = (char *)newValue;
  (*propLen)++;
}

/*
 * clear parameter
 */
void clearSettings(sxnc_parameter **parameters, int *parLen,
                   sxnc_property **properties, int *propLen) {
  free(*parameters);
  free(*parameters);

  *parameters = (sxnc_parameter *)calloc(10, sizeof(sxnc_parameter));
  *properties = (sxnc_property *)calloc(10, sizeof(sxnc_property));
  (*parLen) = 0;
  (*propLen) = 0;
}
