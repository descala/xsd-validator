#include "XQueryProcessor.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"
#include "XdmValue.h"

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

XQueryProcessor::XQueryProcessor() {
  SaxonProcessor *p = new SaxonProcessor(false);
  XQueryProcessor(p, "");
}

XQueryProcessor::~XQueryProcessor() {
  clearProperties();
  clearParameters();
  if (cppXQ != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)cppXQ);
    cppXQ = SXN_UNSET;
  }
  cwdXQ.erase();
  exceptionClear();
}

XQueryProcessor::XQueryProcessor(SaxonProcessor *p, std::string curr) {
  proc = p;
  exception = nullptr;
  cppXQ = j_createXQueryEngineWithProcessor(SaxonProcessor::sxn_environ->thread,
                                            (void *)p->procRef);
  if (cppXQ == SXN_UNSET) {
    throw SaxonApiException(
        "Error: Failed to create the XPathProcessor internal object");
  } else if (cppXQ == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

#ifdef DEBUG
  // jmethodID debugMID =
  // SaxonProcessor::sxn_environ->env->GetStaticMethodID(cppClass,
  // "setDebugMode", "(Z)V");
  // SaxonProcessor::sxn_environ->env->CallStaticVoidMethod(cppClass, debugMID,
  // (jboolean)true);
#endif

  if (!(proc->cwd.empty()) && curr.empty()) {
    cwdXQ = proc->cwd;
  } else {
    cwdXQ = curr;
  }
}

XQueryProcessor::XQueryProcessor(const XQueryProcessor &other) {
  cwdXQ = other.cwdXQ;
  proc = other.proc;

  cppXQ = other.cppXQ;
  std::map<std::string, XdmValue *>::const_iterator paramIter =
      other.parameters.begin();
  while (paramIter != other.parameters.end()) {

    XdmValue *valuei = paramIter->second;
    if (valuei == nullptr) {

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

XQueryProcessor *XQueryProcessor::clone() {
  XQueryProcessor *proc = new XQueryProcessor(*this);
  return proc;
}

std::map<std::string, XdmValue *> &XQueryProcessor::getParameters() {
  std::map<std::string, XdmValue *> &ptr = parameters;
  return ptr;
}

std::map<std::string, std::string> &XQueryProcessor::getProperties() {
  std::map<std::string, std::string> &ptr = properties;
  return ptr;
}

/**
 * Set the source document for the query
 */
void XQueryProcessor::setContextItem(XdmItem *value) {
  if (value != nullptr) {
    value->incrementRefCount();
    parameters["node"] = (XdmValue *)value;
  }
}

void XQueryProcessor::declareNamespace(const char *prefix, const char *uri) {
  if (prefix == nullptr || uri == nullptr) {
    return;
  } else {
    // setProperty("ns-prefix", uri);
    int s = properties.size();
    std::string skey = std::string("ns-prefix:") + prefix;
    properties.insert(
        std::pair<std::string, std::string>(skey, std::string(uri)));

    if (s == properties.size()) {
      std::map<std::string, std::string>::iterator it;
      it = properties.find(skey);
      if (it != properties.end()) {
        properties.erase(skey);
        properties[skey] = std::string(uri);
      }
    }
  }
}

/**
 * Set the source document for the query
 */
void XQueryProcessor::setContextItemFromFile(const char *ifile) {
  setProperty("s", ifile);
}

/**
 * Set the output file where the result is sent
 */
void XQueryProcessor::setOutputFile(const char *ofile) {
  setProperty("o", ofile);
}

/**
 * Set a parameter value used in the query
 */
void XQueryProcessor::setParameter(const char *name, XdmValue *value) {
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

/**
 * Remove a parameter (name, value) pair
 */
bool XQueryProcessor::removeParameter(const char *name) {
  return (bool)(parameters.erase("param:" + std::string(name)));
}
/**
 * Set a property.
 */
void XQueryProcessor::setProperty(const char *name, const char *value) {
#ifdef DEBUG
  if (value == nullptr) {
    std::cerr << "XQueryProc setProperty is nullptr" << std::endl;
  }
#endif
  if (name != nullptr) {
    properties.erase(name);
    std::string skey = std::string(name);
    properties[skey] = std::string((value == nullptr ? "" : value));
  }
}

void XQueryProcessor::clearParameters(bool delVal) {
  if (delVal) {
    for (std::map<std::string, XdmValue *>::iterator itr = parameters.begin();
         itr != parameters.end(); itr++) {
      XdmValue *value = itr->second;
      if (value != nullptr) {
#ifdef DEBUG
        std::cerr << "XQueryProc.clearParameter() - XdmValue refCount="
                  << value->getRefCount() << std::endl;
#endif
        delete value;
        value = nullptr;
      }
    }
  }
  parameters.clear();
}

void XQueryProcessor::clearProperties() {
  properties.clear();
  // outputfile1.clear();
}

void XQueryProcessor::setcwd(const char *dir) {
  if (dir != nullptr) {
    cwdXQ = std::string(dir);
  }
}

void XQueryProcessor::setQueryBaseURI(const char *baseURI) {
  setProperty("base", baseURI);
}

void XQueryProcessor::setUpdating(bool updating) {
  SaxonProcessor::attachCurrentThread();
  if (updating) {
    setProperty("updating", "on");
  } else {
    setProperty("updating", "off");
  }
}

void XQueryProcessor::executeQueryToFile(const char *infilename,
                                         const char *ofilename,
                                         const char *query,
                                         const char *encoding) {
  SaxonProcessor::attachCurrentThread();

  setProperty("resources", proc->getResourcesDirectory());
  if (infilename != nullptr) {
    setProperty("s", infilename);
  }
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  int64_t status = j_executeQueryToFile(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
      (char *)cwdXQ.c_str(), (char *)query, (char *)ofilename, (char *)encoding,
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

XdmValue *XQueryProcessor::executeQueryToValue(const char *infilename,
                                               const char *query,
                                               const char *encoding) {
  SaxonProcessor::attachCurrentThread();
  setProperty("resources", proc->getResourcesDirectory());
  if (infilename != nullptr) {
    setProperty("s", infilename);
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  int64_t result = j_executeQueryToValue(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
      (char *)cwdXQ.c_str(), (char *)query, (char *)encoding,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef != SXN_UNSET) {
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

const char *XQueryProcessor::executeQueryToString(const char *infilename,
                                                  const char *query,
                                                  const char *encoding) {
  SaxonProcessor::attachCurrentThread();
  setProperty("resources", proc->getResourcesDirectory());
  if (infilename != nullptr) {
    setProperty("s", infilename);
  }
  allocFn fn = operator new;
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  char *result = j_executeQueryToString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (void *)proc->procRef,
      (char *)cwdXQ.c_str(), (char *)query, (char *)encoding,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));

  if (result == nullptr) {
    throw SaxonApiException();
  }
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  return (const char *)result;
}

const char *XQueryProcessor::runQueryToString() {
  return executeQueryToString(nullptr, nullptr);
}

XdmValue *XQueryProcessor::runQueryToValue() {
  return executeQueryToValue(nullptr, nullptr);
}

void XQueryProcessor::runQueryToFile() {
  executeQueryToFile(nullptr, nullptr, nullptr);
}

void XQueryProcessor::setQueryFile(const char *ofile) {
  // outputfile1 = std::string(ofile);
  setProperty("q", ofile);
}

void XQueryProcessor::setStreaming(bool option) {
  streaming = option;
  if (option) {
    setProperty("-streaming", "1");
  } else {
    setProperty("-streaming", "0");
  }
}

bool XQueryProcessor::isStreaming() { return streaming; }

void XQueryProcessor::setLanguageVersion(const char *version) {
  setProperty("-lang-version", version);
}

void XQueryProcessor::setQueryContent(const char *content) {
  // outputfile1 = std::string(content);
  setProperty("qs", content);
}

void XQueryProcessor::exceptionClear() {
  if (exception != nullptr) {
    delete exception;
    exception = nullptr;
  }
  j_clearException(SaxonProcessor::sxn_environ->thread);
}

bool XQueryProcessor::exceptionOccurred() {
  return proc->exceptionOccurred() || exception != nullptr;
}

const char *XQueryProcessor::getErrorCode() {
  if (exception == nullptr) {
    return nullptr;
  }
  return exception->getErrorCode();
}

const char *XQueryProcessor::getErrorMessage() {
  if (exception == nullptr) {
    return nullptr;
  }
  return exception->getMessage();
}

const char *XQueryProcessor::checkException() {
  /*if(proc->exception == nullptr) {
          proc->exception =
  proc->checkForException(SaxonProcessor::sxn_environ->env, cppClass, cppXQ);
  }
  return proc->exception;*/
  return proc->checkException();
}

SaxonApiException *XQueryProcessor::getException() { return exception; }

void XQueryProcessor::createException(const char *message) {
  if (exception != nullptr) {
    delete exception;
    exception = nullptr;
  }
  if (message == nullptr) {
    // exception = proc->checkAndCreateException(cppClass);
  } else {
    exception = new SaxonApiException(message);
  }
}
