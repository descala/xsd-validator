// XsltExecutable.cpp : Defines the exported functions for the DLL application.
//

#include "XsltExecutable.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"
#include "XdmValue.h"

#ifdef DEBUG
#include <typeinfo> //used for testing only
#endif

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

XsltExecutable::XsltExecutable(SaxonProcessor *proci, int64_t exRef,
                               std::string curr, std::string resources) {

#ifdef DEBUG

#endif
  proc = proci;
  tunnel = false;
  rawResultsFlag = false;
  selectionRef = SXN_UNSET;
  saxonMessageListenerRef = SXN_UNSET;
  saxonResultDocRef = SXN_UNSET;
  executableRef = exRef;
  procRef = proc->procRef;
  cwdXE = curr;
  resources_dir = resources;
  exceptionFound = false;
  selectionStringFlag = false;
}

XsltExecutable::~XsltExecutable() {
  clearProperties();
  clearParameters();

  if (saxonMessageListenerRef != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)saxonMessageListenerRef);
    saxonMessageListenerRef = SXN_UNSET;
  }
  if (saxonResultDocRef != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)saxonResultDocRef);
    saxonResultDocRef = SXN_UNSET;
  }
  if (executableRef != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)executableRef);
    executableRef = SXN_UNSET;
  }
}

XsltExecutable::XsltExecutable(const XsltExecutable &other) {

  executableRef = other.executableRef;
  procRef = other.procRef;
  cwdXE = other.cwdXE;
  resources_dir = other.resources_dir;
  selectionRef = other.selectionRef;
  tunnel = other.tunnel;
  rawResultsFlag = other.rawResultsFlag;
  exceptionFound = other.exceptionFound;
  saxonMessageListenerRef = other.saxonMessageListenerRef;
  selectionStringFlag = other.selectionStringFlag;

  std::map<std::string, XdmValue *>::const_iterator paramIter =
      other.parameters.begin();
  while (paramIter != other.parameters.end()) {

    XdmValue *valuei = paramIter->second;
    if (valuei == nullptr) {
      /*throw SaxonApiException("Error in XsltExecutable copy constructor -
         parameter value " "is NULL");*/
    } else {
      parameters[paramIter->first] = new XdmValue(*(valuei));
    }
    paramIter++;
  }

  std::map<std::string, std::string>::const_iterator propIter =
      other.properties.begin();
  while (propIter != other.properties.end()) {
    properties[propIter->first] = propIter->second;
    propIter++;
  }
}

void XsltExecutable::deleteXdmValueArray(XdmValue **arr, int len) {
  if (arr != nullptr && len > 0) {
    for (int i = 0; i < len; i++) {
      if (arr[i]->getRefCount() < 1) {
        delete arr[i];
      } else {
        arr[i]->decrementRefCount();
      }
    }
    delete[] arr;
  }
}

bool XsltExecutable::exceptionOccurred() { return exceptionFound; }

void XsltExecutable::setGlobalContextItem(XdmItem *value) {
  if (value != nullptr) {
    parameters["node"] = value;
  }
}

void XsltExecutable::setGlobalContextFromFile(const char *ifile) {
  if (ifile != nullptr) {
    setProperty("s", ifile);
  }
}

void XsltExecutable::setInitialMatchSelection(XdmValue *_selection) {

  if (_selection == nullptr) {
    selectionRef = SXN_UNSET;
  } else {
    selectionRef = _selection->getUnderlyingValue();
    selectionStringFlag = false;
  }
}

void XsltExecutable::setInitialMatchSelectionAsFile(const char *filename) {

  if (selectionRef != SXN_UNSET && selectionStringFlag) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)selectionRef);
  }
  selectionRef = SXN_UNSET;

  if (filename != nullptr) {
    selectionRef = j_createStringObject(SaxonProcessor::sxn_environ->thread,
                                        (char *)filename);
    selectionStringFlag = true;
    if (selectionRef == SXN_EXCEPTION) {
      exceptionFound = true;
      throw SaxonApiException();
    }
  } else {
    selectionRef = SXN_UNSET;
  }
}

void XsltExecutable::setOutputFile(const char *ofile) {
  setProperty("o", ofile);
}

void XsltExecutable::setBaseOutputURI(const char *baseURI) {
  if (baseURI != nullptr) {
    setProperty("baseoutput", baseURI);
  }
}

void XsltExecutable::setInitialMode(const char *modeName) {
  if (modeName != nullptr) {
    setProperty("im", modeName);
  }
}

void XsltExecutable::setParameter(const char *name, XdmValue *value) {
  if (value != nullptr && name != nullptr) {
    std::string skey = ("param:" + std::string(name));
    std::map<std::string, XdmValue *>::iterator it = parameters.find(skey);
    if (it != parameters.end()) {
      XdmValue *valuei = it->second;
      if (valuei != nullptr) {
        valuei->decrementRefCount();
        parameters.erase(skey);
      }
    }
    parameters[skey] = value;
  }
}

void XsltExecutable::setInitialTemplateParameters(
    std::map<std::string, XdmValue *> _itparameters, bool _tunnel) {
  for (std::map<std::string, XdmValue *>::iterator itr = _itparameters.begin();
       itr != _itparameters.end(); itr++) {

    parameters["itparam:" + std::string(itr->first)] = itr->second;
  }
  tunnel = _tunnel;
  if (tunnel) {
    setProperty("tunnel", "true");
  }
}

void XsltExecutable::setCaptureResultDocuments(bool flag, bool rawResults) {

  if (flag) {
    resultDocumentMap.clear();
    if (saxonResultDocRef != SXN_UNSET) {
      saxonResultDocRef = SXN_UNSET;
    }

    rawResultsFlag = rawResults || rawResultsFlag;

    saxonResultDocRef = createSaxonCResultDocumentHandler(
        SaxonProcessor::sxn_environ->thread, (int)rawResultsFlag);

    if (saxonResultDocRef == SXN_EXCEPTION) {
      throw SaxonApiException();
    }
  } else {
    setProperty("rd", "off");

    if (saxonResultDocRef > 0) {
      j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                        (void *)saxonResultDocRef);
      saxonResultDocRef = SXN_UNSET;
    }

    while (!resultDocumentMap.empty()) {
      delete resultDocumentMap.begin()->second;
      resultDocumentMap.erase(resultDocumentMap.begin());
    }
  }
}

std::map<std::string, XdmValue *> &XsltExecutable::getResultDocuments() {

  if (saxonResultDocRef > 0) {
    allocFn fn = operator new;
    long long *results =
        j_getResultDocuments(SaxonProcessor::sxn_environ->thread, (void *)fn,
                             (void *)saxonResultDocRef);
    int64_t resultUrisRef = j_getResultDocumentURIs(
        SaxonProcessor::sxn_environ->thread, (void *)saxonResultDocRef);
    if (results != nullptr) {
      int sizex = results[0];
      // std::cerr<<"getResultDocuments cp0 size= "<<sizex<<std::endl;
      for (int i = 1; i <= sizex; i++) {
        XdmValue *value = nullptr;
        char *str = j_getProcessorDataProperty(
            SaxonProcessor::sxn_environ->thread, (void *)fn,
            (void *)resultUrisRef, i - 1);

        value = SaxonProcessor::makeXdmValueFromRef(results[i]);
        if (value != nullptr && str != nullptr) {
          std::string docUriString = std::string(str);
          resultDocumentMap[docUriString] = value;
          operator delete(str);
        } else {
          throw SaxonApiException("getResultDocuments failed to create value");
        }
      }
      operator delete(results);
      j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                        (void *)resultUrisRef);
    } /*else {
      exceptionFound = true;
      throw SaxonApiException();
    } */
  }

  return resultDocumentMap;
}

XdmValue *XsltExecutable::getParameter(const char *name) {
  std::map<std::string, XdmValue *>::iterator it;
  it = parameters.find("param:" + std::string(name));
  if (it != parameters.end())
    return it->second;
  else {
    it = parameters.find("sparam:" + std::string(name));
    if (it != parameters.end())
      return it->second;
  }
  return nullptr;
}

bool XsltExecutable::removeParameter(const char *name) {
  return (bool)(parameters.erase("param:" + std::string(name)));
}

void XsltExecutable::setResultAsRawValue(bool option) {
  if (option) {
    setProperty("outvalue", "yes");
    rawResultsFlag = true;
  } else {
    removeProperty("outvalue");
    rawResultsFlag = false;
  }
}

XsltExecutable *XsltExecutable::clone() {
  XsltExecutable *executable = new XsltExecutable(*this);
  return executable;
}

void XsltExecutable::setProperty(const char *name, const char *value) {
#ifdef DEBUG
  if (value == nullptr) {
    std::cerr << "XsltExecutable setProperty is nullptr" << std::endl;
  }
#endif
  if (name != nullptr) {
    properties.erase(name);
    std::string skey = std::string(name);
    properties[skey] = std::string((value == nullptr ? "" : value));
  }
}

bool XsltExecutable::removeProperty(const char *name) {
  return (bool)(properties.erase(std::string(name)));
}

const char *XsltExecutable::getProperty(const char *name) {
  std::map<std::string, std::string>::iterator it;
  it = properties.find(std::string(name));
  if (it != properties.end())
    return it->second.c_str();
  return nullptr;
}

void XsltExecutable::clearParameters(bool delValues) {
  if (delValues) {
    for (std::map<std::string, XdmValue *>::iterator itr = parameters.begin();
         itr != parameters.end(); itr++) {

      XdmValue *value = itr->second;
      if (value != nullptr) {
#ifdef DEBUG
        std::cout << "clearParameter() - XdmValue refCount="
                  << value->getRefCount() << std::endl;
#endif
        delete value;
        value = nullptr;
      }
    }
  }
  parameters.clear();
}

void XsltExecutable::clearProperties() {

  properties.clear();
  if (selectionRef != SXN_UNSET && selectionStringFlag) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)selectionRef);
    selectionRef = SXN_UNSET;
  }
}

std::map<std::string, XdmValue *> &XsltExecutable::getParameters() {
  std::map<std::string, XdmValue *> &ptr = parameters;
  return ptr;
}

std::map<std::string, std::string> &XsltExecutable::getProperties() {
  std::map<std::string, std::string> &ptr = properties;
  return ptr;
}

void XsltExecutable::exceptionClear() {
  j_clearException(SaxonProcessor::sxn_environ->thread);
  exceptionFound = false;
}

void XsltExecutable::setcwd(const char *dir) {
  if (dir != nullptr) {
    cwdXE = std::string(dir);
  }
}

void XsltExecutable::exportStylesheet(const char *filename) {
  long status =
      j_save(SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
             (void *)executableRef, (char *)filename);
  if (status == SXN_EXCEPTION) {
    exceptionFound = true;
    throw SaxonApiException();
  }
}

void XsltExecutable::applyTemplatesReturningFile(const char *output_filename) {
  proc->attachCurrentThread();
  if (selectionRef == SXN_UNSET) {
    throw SaxonApiException(
        "Error: The initial match selection has not been set. Please set it "
        "using setInitialMatchSelection or setInitialMatchSelectionAsFile.");
  }

  setProperty("resources", resources_dir.c_str());

  int additions = 0;
  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef != SXN_UNSET) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  long status = j_applyTemplatesReturningFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef,
      (void *)(selectionRef == SXN_UNSET ? (void *)nullptr
                                         : (void *)selectionRef),
      (char *)output_filename,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));

  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (status == SXN_EXCEPTION) {
    exceptionFound = true;
    throw SaxonApiException();
  }

  return;
}

const char *XsltExecutable::applyTemplatesReturningString() {
  proc->attachCurrentThread();
  if (selectionRef == SXN_UNSET) {
    throw SaxonApiException(
        "Error: The initial match selection has not been set. Please set it "
        "using setInitialMatchSelection or setInitialMatchSelectionAsFile.");
  }

  setProperty("resources", resources_dir.c_str());

  int additions = 0;
  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef != SXN_UNSET) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }
  allocFn fn = operator new;
  char *result = j_applyTemplatesReturningString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (char *)cwdXE.c_str(),
      (void *)executableRef,
      (selectionRef == SXN_UNSET ? (void *)NULL : (void *)selectionRef),
      (processorDataRef == SXN_UNSET ? (void *)NULL
                                     : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }

  if (result == nullptr) {
    exceptionFound = true;
    throw SaxonApiException();
  }

  return result;
}

XdmValue *XsltExecutable::applyTemplatesReturningValue() {
  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef != SXN_UNSET) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  std::string optionStr;
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  int64_t result = j_applyTemplatesReturningValue(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef,
      (void *)(selectionRef == SXN_UNSET ? (void *)NULL : (void *)selectionRef),
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result > 0) {
    return SaxonProcessor::makeXdmValueFromRef(result);
  } else if (result == SXN_EXCEPTION) {
    exceptionFound = true;
    throw SaxonApiException();
  }
  return nullptr;
}

void XsltExecutable::callFunctionReturningFile(const char *functionName,
                                               XdmValue **arguments,
                                               int argument_length,
                                               const char *outfile) {

  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;
  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  int64_t argumentValuesRef = createProcessorDataWithCapacity(
      SaxonProcessor::sxn_environ->thread, argument_length);

  for (int i = 0; i < argument_length; i++) {
    addProcessorValue(SaxonProcessor::sxn_environ->thread,
                      (void *)argumentValuesRef,
                      (void *)arguments[i]->getUnderlyingValue());
  }

  long status = j_callFunctionReturningFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)functionName, (char *)outfile,
      (argumentValuesRef == SXN_UNSET ? (void *)NULL
                                      : (void *)argumentValuesRef),
      (processorDataRef == SXN_UNSET ? (void *)NULL
                                     : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return;
}

const char *XsltExecutable::callFunctionReturningString(
    const char *functionName, XdmValue **arguments, int argument_length) {

  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  int64_t argumentValuesRef = createProcessorDataWithCapacity(
      SaxonProcessor::sxn_environ->thread, argument_length);

  for (int i = 0; i < argument_length; i++) {
    addProcessorValue(SaxonProcessor::sxn_environ->thread,
                      (void *)argumentValuesRef,
                      (void *)arguments[i]->getUnderlyingValue());
  }
  allocFn fn = operator new;
  char *result = j_callFunctionReturningString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)functionName,
      (void *)(argumentValuesRef == SXN_UNSET ? (void *)nullptr
                                              : (void *)argumentValuesRef),
      (void *)(processorDataRef == SXN_UNSET ? (void *)nullptr
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }

  if (result == nullptr) {
    throw SaxonApiException();
  }

  return result;
}

XdmValue *XsltExecutable::callFunctionReturningValue(const char *functionName,
                                                     XdmValue **arguments,
                                                     int argument_length) {

  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  int64_t argumentValuesRef = createProcessorDataWithCapacity(
      SaxonProcessor::sxn_environ->thread, argument_length);

  for (int i = 0; i < argument_length; i++) {
    addProcessorValue(SaxonProcessor::sxn_environ->thread,
                      (void *)argumentValuesRef,
                      (void *)arguments[i]->getUnderlyingValue());
  }

  int64_t result = j_callFunctionReturningValue(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)functionName, (void *)argumentValuesRef,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result > 0) {
    return SaxonProcessor::makeXdmValueFromRef(result);
  } else if (result == SXN_EXCEPTION) {

    exceptionFound = true;
    throw SaxonApiException();
  }
  return nullptr;
}

void XsltExecutable::callTemplateReturningFile(const char *templateName,
                                               const char *outfile) {

  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  if (saxonMessageListenerRef != SXN_UNSET) {
    additions++;
  }
  if (saxonResultDocRef > 0) {
    additions++;
  }
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  std::string optionStr;
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  long status = j_callTemplateReturningFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)templateName, (char *)outfile,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
}

const char *
XsltExecutable::callTemplateReturningString(const char *templateName) {
  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  } */
  std::string optionStr;
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }
  allocFn fn = operator new;
  char *result = j_callTemplateReturningString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)templateName,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result == nullptr) {
    throw SaxonApiException();
  }
  return result;
}

XdmValue *XsltExecutable::callTemplateReturningValue(const char *templateName) {
  proc->attachCurrentThread();
  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }

  int64_t result = j_callTemplateReturningValue(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)executableRef, (char *)templateName,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result > 0) {
    return SaxonProcessor::makeXdmValueFromRef(result);
  } else if (result == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

  return nullptr;
}

XdmValue *XsltExecutable::transformFileToValue(const char *sourcefile) {

  if (sourcefile == nullptr) {

    return nullptr;
  }

  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }
  char *cstylesheet = nullptr;
  int64_t result = j_transformToValue(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)nullptr, (void *)executableRef, (char *)sourcefile, cstylesheet,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));

  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result > 0) {
    return SaxonProcessor::makeXdmValueFromRef(result);
  } else if (result == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

  return nullptr;
}

void XsltExecutable::transformFileToFile(const char *source,
                                         const char *outputfile) {

  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  std::string optionStr;
  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }
  char *cstylesheet = nullptr;
  long status = j_transformToFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXE.c_str(),
      (void *)nullptr, (void *)executableRef, (char *)source, cstylesheet,
      (char *)outputfile,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
}

void XsltExecutable::setSaveXslMessage(bool create, const char *filename) {

  if (create) {

    if (filename == nullptr) {
      std::string optionStr = "-:on";
      saxonMessageListenerRef = createSaxonCMessageListener(
          SaxonProcessor::sxn_environ->thread, (void *)procRef,
          (char *)cwdXE.c_str(), (char *)optionStr.c_str());

      setProperty("m", "on");
    } else {
      saxonMessageListenerRef = createSaxonCMessageListener(
          SaxonProcessor::sxn_environ->thread, (void *)procRef,
          (char *)cwdXE.c_str(), (char *)filename);
    }
    if (saxonMessageListenerRef == SXN_EXCEPTION) {
      exceptionFound = true;
      throw SaxonApiException();
    }
    /*if (getenv("SAXONC_DEBUG_FLAG")) {
      std::cerr << "C++: setSaveXslMessage saxonMessageListenerRef = "
                << ((long)saxonMessageListenerRef) << std::endl;
    }*/
  } else {
    if (saxonMessageListenerRef > 0) {
      j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                        (void *)saxonMessageListenerRef);
    }
    saxonMessageListenerRef = SXN_UNSET;
    setProperty("m", "off");
  }
}

XdmValue *XsltExecutable::getXslMessages() {
  if (saxonMessageListenerRef > 0) {
    allocFn fn = operator new;
    long long *results =
        j_getXslMessages(SaxonProcessor::sxn_environ->thread, (void *)fn,
                         (void *)saxonMessageListenerRef);

    if (results != nullptr) {
      int sizex = results[0];
      /*if (getenv("SAXONC_DEBUG_FLAG")) {
        std::cerr << "C++: getXslMessages size= " << sizex << std::endl;
      }*/
      XdmValue *value = new XdmValue();
      for (int i = 1; i <= sizex; i++) {
        XdmItem *item = nullptr;
        item = SaxonProcessor::makeXdmItemFromRef(results[i]);
        if (value != nullptr) {
          value->addXdmItem(item);
        } else {
          throw SaxonApiException("getXslMessages failed to create value");
        }
      }
      operator delete(results);
      return value;
    }
  }
  return nullptr;
}

const char *XsltExecutable::transformFileToString(const char *source) {

  setProperty("resources", resources_dir.c_str());

  int additions = 0;

  /*if(saxonMessageListenerRef != SXN_UNSET ) {
      additions++;
  }
  if(saxonResultDocRef > 0) {
      additions++;
  }*/
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, additions);

  // TODO change map to set values as int64_t then we can add
  // saxonMessageListenerRef directly
  std::string optionStr;
  if (saxonMessageListenerRef != SXN_UNSET) {
    optionStr = "m";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (void *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonMessageListenerRef);
  }
  if (saxonResultDocRef > 0) {
    optionStr = "rd";
    addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                         (char *)processorDataRef, (char *)optionStr.c_str(),
                         (void *)saxonResultDocRef);
  }
  char *cstylesheet = nullptr;
  allocFn fn = operator new;

  char *result = j_transformToString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (char *)cwdXE.c_str(),
      (void *)nullptr, (void *)executableRef, (char *)source, cstylesheet,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (result == nullptr) {
    exceptionFound = true;
  }
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  return result;
}

const char *XsltExecutable::transformToString(XdmNode *source) {

  if (source != nullptr) {
    parameters["node"] = source;
  }
  return transformFileToString(nullptr);
}

XdmValue *XsltExecutable::transformToValue(XdmNode *source) {

  if (source != nullptr) {
    parameters["node"] = source;
  }
  return transformFileToValue(nullptr);
}

void XsltExecutable::transformToFile(XdmNode *source) {

  if (source != nullptr) {
    parameters["node"] = source;
  }
  transformFileToFile(nullptr, nullptr);
}

SaxonApiException *XsltExecutable::getException() { return nullptr; }

const char *XsltExecutable::getErrorMessage() { return nullptr; }
