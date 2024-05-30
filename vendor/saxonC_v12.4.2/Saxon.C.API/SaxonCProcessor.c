#include "SaxonCProcessor.h"

/*
 * Get the Saxon version
 */
const char *version(sxnc_environment *environi, sxnc_processor *proc) {

  return j_c_getProductVersion(environi->thread, (void *)proc->value);
}

/*
 * Get the Saxon version
 */
const char *getProductVariantAndVersion(sxnc_environment *environi,
                                        sxnc_processor *proc) {

  return j_c_getProductVersion(environi->thread, (void *)proc->value);
}

void initSaxonc(sxnc_environment **environi, sxnc_processor **proc,
                sxnc_parameter **param, sxnc_property **prop, int cap,
                int propCap) {

  *param = (sxnc_parameter *)calloc(cap, sizeof(sxnc_parameter));
  *prop = (sxnc_property *)calloc(propCap, sizeof(sxnc_property));
  *environi = (sxnc_environment *)malloc(sizeof(sxnc_environment));
  *proc = (sxnc_processor *)malloc(sizeof(sxnc_processor));
}

void freeSaxonc(sxnc_environment **environi, sxnc_processor **proc,
                sxnc_parameter **param, sxnc_property **prop) {
  free(*environi);
  free(*proc);
  free(*param);
  free(*prop);
}

void xsltSaveResultToFile(sxnc_environment *environi, sxnc_processor *proc,
                          char *cwd, char *source, char *stylesheet,
                          char *outputfile, sxnc_parameter *parameters,
                          sxnc_property *properties, int parLen, int propLen) {
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

  long result =
      c_xsltSaveResultToFile(environi->thread, (void *)proc->value, cwd, source,
                             stylesheet, outputfile, (void *)processorDataRef);

  if (result == -2) {
    printf("Error: Exception found\n");
  }
  return;
}

const char *xsltApplyStylesheet(sxnc_environment *environi,
                                sxnc_processor *proc, char *cwd, char *source,
                                char *stylesheet, sxnc_parameter *parameters,
                                sxnc_property *properties, int parLen,
                                int propLen) {

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

  return c_xsltApplyStylesheet(environi->thread, (void *)proc->value, cwd,
                               source, stylesheet, (void *)processorDataRef);
}

void executeQueryToFile(sxnc_environment *environi, sxnc_processor *proc,
                        char *cwd, char *outputfile, sxnc_parameter *parameters,
                        sxnc_property *properties, int parLen, int propLen) {
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

  long result =
      j_executeQueryToFile(environi->thread, (void *)proc->value, cwd, NULL,
                           outputfile, NULL, (void *)processorDataRef);
}

const char *executeQueryToString(sxnc_environment *environi,
                                 sxnc_processor *proc, char *cwd,
                                 sxnc_parameter *parameters,
                                 sxnc_property *properties, int parLen,
                                 int propLen) {
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

  return j_executeQueryToString_c(environi->thread, (void *)proc->value, cwd,
                                  (void *)processorDataRef);
}

const char *c_getErrorMessage(sxnc_environment *environi) {
  return j_getErrorMessageInJavaMem(environi->thread);
}
