#include "SchemaValidator.h"
#include "XdmItem.h"
#include "XdmNode.h"
#include "XdmValue.h"

//#define DEBUG

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

SchemaValidator::SchemaValidator() {
  SaxonProcessor *p = new SaxonProcessor(true);
  SchemaValidator(p, "");
}

SchemaValidator::SchemaValidator(SaxonProcessor *p, std::string curr) {
  proc = p;
  cppV = createSchemaValidatorWithProcessor(SaxonProcessor::sxn_environ->thread,
                                            (void *)p->procRef);
  exception = nullptr;

  if (cppV < 0) {
    throw SaxonApiException();
  }

  if (!(proc->cwd.empty()) && curr.empty()) {
    cwdV = proc->cwd;
  } else {
    cwdV = curr;
  }

  lax = false;
}

SchemaValidator::SchemaValidator(const SchemaValidator &other) {

  exception = nullptr;
  lax = other.lax;
  cwdV = other.cwdV;
  cppV = other.cppV;
  outputFile = other.outputFile;

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

SchemaValidator::~SchemaValidator() {
  clearProperties();
  clearParameters();

  if (cppV > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)cppV);
  }

  /*if(exception != nullptr) {
      delete exception;
  }*/
}

void SchemaValidator::setcwd(const char *dir) {
  if (dir != nullptr) {
    cwdV = std::string(dir);
  }
}

void SchemaValidator::setOutputFile(const char *sourceFile) {
  if (sourceFile != nullptr) {
    outputFile = std::string(sourceFile);
  }
}

void SchemaValidator::setLax(bool l) { lax = l; }

XdmNode *SchemaValidator::getValidationReport() {
  int64_t result =
      j_getValidationReport(SaxonProcessor::sxn_environ->thread, (void *)cppV);

  if (result > 0) {
    XdmNode *node = new XdmNode(result);
    return node;
  } else if (result == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

void SchemaValidator::registerSchemaFromNode(XdmNode *node) {
  setProperty("resources", proc->getResourcesDirectory());

  if (node == nullptr) {
    exception = new SaxonApiException("Error:: XdmNode XSD is NULL");
    return;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);

  int64_t status = j_registerSchemaNode(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
      (void *)node->getUnderlyingValue(),
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

void SchemaValidator::registerSchemaFromFile(const char *sourceFile) {
  SaxonProcessor::attachCurrentThread();
  setProperty("resources", proc->getResourcesDirectory());
  if (sourceFile == nullptr) {
    throw SaxonApiException("Error: sourceFile string cannot be empty or NULL");
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);

  int64_t status = j_registerSchema(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
      (char *)cwdV.c_str(), (char *)sourceFile,
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

void SchemaValidator::exportSchema(const char *fileName) {
  if (fileName == nullptr) {
    exception = new SaxonApiException(
        "Error: fileName string cannot be empty or nullptr");
    return;
  }

  int64_t status =
      j_exportSchema(SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
                     (char *)cwdV.c_str(), (char *)fileName);
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
}

void SchemaValidator::registerSchemaFromString(const char *sourceStr,
                                               const char *systemID) {

  setProperty("resources", proc->getResourcesDirectory());
  if (sourceStr == nullptr) {
    exception = new SaxonApiException(
        "Error:: Schema string cannot be empty or nullptr");
    return;
  }
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);

  int64_t status = j_registerSchemaString(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef,
      (char *)(systemID == nullptr ? cwdV.c_str() : systemID),
      (char *)sourceStr,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
}

void SchemaValidator::validate(const char *sourceFile) {
  SaxonProcessor::attachCurrentThread();
  setProperty("resources", proc->getResourcesDirectory());
  if (lax) {
    setProperty("lax", "1");
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  int64_t status = j_validate(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef, (void *)cppV,
      (char *)cwdV.c_str(), (char *)sourceFile, (char *)nullptr,
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

XdmNode *SchemaValidator::validateToNode(const char *sourceFile) {
  SaxonProcessor::attachCurrentThread();
  setProperty("resources", proc->getResourcesDirectory());
  if (lax) {
    setProperty("lax", "1");
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  int64_t result = j_validateToNode(
      SaxonProcessor::sxn_environ->thread, (void *)proc->procRef, (void *)cppV,
      (char *)cwdV.c_str(), (char *)sourceFile,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  if (result > 0) {
    XdmNode *node = new XdmNode(result);
    return node;
  } else if (result == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

  return nullptr;
}

void SchemaValidator::exceptionClear() {
  if (exception != nullptr) {
    delete exception;
    exception = nullptr;
  }
}

const char *SchemaValidator::getErrorCode() {
  if (proc->exception == nullptr) {
    return nullptr;
  }
  return proc->exception->getErrorCode();
}

const char *SchemaValidator::getErrorMessage() {
  if (exception == nullptr) {
    return nullptr;
  }
  return exception->getMessage();
}

bool SchemaValidator::exceptionOccurred() {
  return proc->exceptionOccurred() || exception != nullptr;
}

const char *SchemaValidator::checkException() { return proc->checkException(); }

/*int SchemaValidator::exceptionCount(){
 if(proc->exception != nullptr){
 return proc->exception->count();
 }
 return 0;
 }   */

void SchemaValidator::setSourceNode(XdmNode *value) {
  if (value != nullptr) {
    value->incrementRefCount();
    parameters["node"] = (XdmValue *)value;
  }
}

void SchemaValidator::setParameter(const char *name, XdmValue *value) {
  if (value != nullptr) {
    // value->incrementRefCount();
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

bool SchemaValidator::removeParameter(const char *name) {
  return (bool)(parameters.erase("param:" + std::string(name)));
}

void SchemaValidator::setProperty(const char *name, const char *value) {
#ifdef DEBUG
  if (value == nullptr) {
    std::cerr << "Validator setProperty is nullptr" << std::endl;
  }
#endif
  properties.insert(std::pair<std::string, std::string>(
      std::string(name), std::string((value == nullptr ? "" : value))));
}

void SchemaValidator::clearParameters(bool delVal) {
  if (delVal) {
    for (std::map<std::string, XdmValue *>::iterator itr = parameters.begin();
         itr != parameters.end(); itr++) {
      XdmValue *value = itr->second;
      value->decrementRefCount();
#ifdef DEBUG
      std::cout << "SchemaValidator.clearParameter() - XdmValue refCount="
                << value->getRefCount() << std::endl;
#endif
      if (value != nullptr && value->getRefCount() < 1) {
        delete value;
      }
    }
  }
  parameters.clear();
}

void SchemaValidator::clearProperties() { properties.clear(); }

std::map<std::string, XdmValue *> &SchemaValidator::getParameters() {
  std::map<std::string, XdmValue *> &ptr = parameters;
  return ptr;
}

std::map<std::string, std::string> &SchemaValidator::getProperties() {
  std::map<std::string, std::string> &ptr = properties;
  return ptr;
}
