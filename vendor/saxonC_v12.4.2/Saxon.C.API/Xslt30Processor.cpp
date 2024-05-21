// Xslt30Processor.cpp : Defines the exported functions for the DLL application.
//

#include "Xslt30Processor.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"
#include "XdmValue.h"
//#include "XsltExecutable.h"
#ifdef DEBUG
#include <typeinfo> //used for testing only
#endif

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

Xslt30Processor::Xslt30Processor() {

  SaxonProcessor *p = new SaxonProcessor(false);
  Xslt30Processor(p, "");
}

Xslt30Processor::Xslt30Processor(SaxonProcessor *p, std::string curr) {

  proc = p;
  if (proc == nullptr) {

    return;
  }
  jitCompilation = false;
  importPackageValue = SXN_UNSET;
  exception = nullptr;
  cppXT = createXslt30WithProcessor(SaxonProcessor::sxn_environ->thread,
                                    (void *)proc->procRef);

#ifdef DEBUG
  // jmethodID debugMID =
  // SaxonProcessor::sxn_environ->env->GetStaticMethodID(cppClass,
  // "setDebugMode", "(Z)V");
  // SaxonProcessor::sxn_environ->env->CallStaticVoidMethod(cppClass, debugMID,
  // (jboolean)true);

#endif

  if (cppXT < 0) {
    throw SaxonApiException();
  }

  if (!(proc->cwd.empty()) && curr.empty()) {
    cwdXT = proc->cwd;
  } else if (!curr.empty()) {
    cwdXT = curr;
  }
}

Xslt30Processor::~Xslt30Processor() {
  clearParameters();
  clearProperties();
  if (cppXT != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)cppXT);
    cppXT = SXN_UNSET;
  }
  cwdXT.erase();
  exceptionClear();
  if (importPackageValue != SXN_UNSET) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)importPackageValue);
    importPackageValue = SXN_UNSET;
  }
}

Xslt30Processor::Xslt30Processor(const Xslt30Processor &other) {
  proc = other.proc;

  cppXT = other.cppXT;
  cwdXT = other.cwdXT;
  importPackageValue = other.importPackageValue;
  std::map<std::string, XdmValue *>::const_iterator paramIter =
      other.parameters.begin();
  while (paramIter != other.parameters.end()) {

    XdmValue *valuei = paramIter->second;
    if (valuei == nullptr) {
      // std::cerr<<"Error in Xslt30Processor copy constructor"<<std::endl;
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

  jitCompilation = other.jitCompilation;
}

void Xslt30Processor::setProperty(const char *name, const char *value) {
  if (name != nullptr) {
    properties.erase(name);
    std::string skey = std::string(name);
    properties[skey] = std::string((value == nullptr ? "" : value));
  }
}

void Xslt30Processor::clearProperties() { properties.clear(); }

bool Xslt30Processor::exceptionOccurred() { return false; }

const char *Xslt30Processor::getErrorCode() { return nullptr; }

void Xslt30Processor::setBaseOutputURI(const char *baseURI) {
  if (baseURI != nullptr) {
    setProperty("baseoutput", baseURI);
  }
}

void Xslt30Processor::setParameter(const char *name, XdmValue *value) {
  if (value != nullptr && name != nullptr) {
    std::string skey = ("sparam:" + std::string(name));
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

XdmValue *Xslt30Processor::getParameter(const char *name) {
  std::map<std::string, XdmValue *>::iterator it;
  it = parameters.find("sparam:" + std::string(name));
  if (it != parameters.end())
    return it->second;
  return nullptr;
}

bool Xslt30Processor::removeParameter(const char *name) {
  return (bool)(parameters.erase("param:" + std::string(name)));
}

void Xslt30Processor::setJustInTimeCompilation(bool jit) {
  jitCompilation = jit;
}

void Xslt30Processor::setFastCompilation(bool fast) {
  if (fast) {
    setProperty("-fastCompile", "1");
  } else {
    setProperty("-fastCompile", "0");
  }
}

void Xslt30Processor::setRelocatable(bool flag) {
  if (flag) {
    setProperty("-relocate", "1");
  } else {
    setProperty("-relocate", "0");
  }
}

void Xslt30Processor::setXsltLanguageVersion(const char *version) {
  if (version != nullptr) {
    setProperty("-lang", version);
  }
}

void Xslt30Processor::setTargetEdition(const char *edition) {
  if (edition != nullptr) {
    setProperty("-target", edition);
  }
}

void Xslt30Processor::clearParameters(bool delValues) {
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

std::map<std::string, XdmValue *> &Xslt30Processor::getParameters() {
  std::map<std::string, XdmValue *> &ptr = parameters;
  return ptr;
}

void Xslt30Processor::exceptionClear() {
  j_clearException(SaxonProcessor::sxn_environ->thread);
}

void Xslt30Processor::setcwd(const char *dir) {
  if (dir != nullptr) {
    cwdXT = std::string(dir);
  }
}

SaxonApiException *Xslt30Processor::getException() { return exception; }

void Xslt30Processor::createException(const char *message) {}

void Xslt30Processor::compileFromXdmNodeAndSave(XdmNode *node,
                                                const char *filename) {
  proc->attachCurrentThread();
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  long status = j_compileFromXdmNodeAndSave(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT,
      (void *)node->getUnderlyingValue(), (char *)cwdXT.c_str(),
      (char *)filename,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
}

void Xslt30Processor::compileFromStringAndSave(const char *stylesheetStr,
                                               const char *filename,
                                               const char *encoding) {
  proc->attachCurrentThread();
  if (encoding != nullptr) {
    setProperty("!input-encoding", encoding);
  }
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  long status = j_compileFromStringAndSave(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (char *)stylesheetStr, (char *)filename,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
}

void Xslt30Processor::importPackage(const char *packageFile) {

  if (packageFile == nullptr) {
    throw SaxonApiException("ImportPackage file name is NULL");
  }

  if (importPackageValue == SXN_UNSET) {
    importPackageValue =
        createProcessorData(SaxonProcessor::sxn_environ->thread);
  }

  addProcessorProperty(SaxonProcessor::sxn_environ->thread,
                       (void *)importPackageValue, (char *)packageFile);
}

void Xslt30Processor::compileFromFileAndSave(const char *xslFilename,
                                             const char *filename) {
  proc->attachCurrentThread();
  if (xslFilename == nullptr) {
    throw SaxonApiException("XSL filename is null");
  }
  if (filename == nullptr) {
    throw SaxonApiException("Output filename is null");
  }
  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties);
  long status = j_compileFromFileAndSave(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (char *)xslFilename, (char *)filename,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (status == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
}

XsltExecutable *Xslt30Processor::compileFromString(const char *stylesheetStr,
                                                   const char *encoding) {
  proc->attachCurrentThread();
  if (stylesheetStr == nullptr) {
    throw SaxonApiException("XSL string is null");
  }
  if (encoding != nullptr) {
    setProperty("!input-encoding", encoding);
  }
  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  int64_t objRef = j_compileFromString(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (char *)stylesheetStr, (int)jitCompilation,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (objRef == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
  XsltExecutable *executable =
      new XsltExecutable(proc, objRef, cwdXT, proc->getResourcesDirectory());
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  return executable;
}

XsltExecutable *Xslt30Processor::compileFromXdmNode(XdmNode *node) {
  proc->attachCurrentThread();
  if (node == nullptr) {
    throw SaxonApiException("XSL node is null");
  }

  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  int64_t objRef = j_compileFromXdmNode(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (void *)node->getUnderlyingValue(), (int)jitCompilation,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (objRef == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
  XsltExecutable *executable =
      new XsltExecutable(proc, objRef, cwdXT, proc->getResourcesDirectory());
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  return executable;
}

XsltExecutable *Xslt30Processor::compileFromAssociatedFile(const char *source) {
  proc->attachCurrentThread();
  if (source == nullptr) {
    throw SaxonApiException("XSL filename is null");
  }

  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  int64_t objRef = j_compileFromAssociatedFile(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (char *)source, (int)jitCompilation,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (objRef == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
  XsltExecutable *executable =
      new XsltExecutable(proc, objRef, cwdXT, proc->getResourcesDirectory());
  return executable;
}

XsltExecutable *Xslt30Processor::compileFromFile(const char *stylesheet) {
  proc->attachCurrentThread();
  if (stylesheet == nullptr) {
    throw SaxonApiException("XSL filename is null");
  }

  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  int64_t objRef = j_compileFromFile(
      SaxonProcessor::sxn_environ->thread, (void *)cppXT, (char *)cwdXT.c_str(),
      (char *)stylesheet, (int)jitCompilation,
      (void *)(processorDataRef == SXN_UNSET ? (void *)NULL
                                             : (void *)processorDataRef));
  if (objRef == SXN_EXCEPTION) {
    throw SaxonApiException(true);
  }
  XsltExecutable *executable =
      new XsltExecutable(proc, objRef, cwdXT, proc->getResourcesDirectory());
  if (processorDataRef > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                      (void *)processorDataRef);
    processorDataRef = SXN_UNSET;
  }
  return executable;
}

XdmValue *Xslt30Processor::transformFileToValue(const char *sourcefile,
                                                const char *stylesheetfile) {

  proc->attachCurrentThread();

  if (sourcefile == nullptr && stylesheetfile == nullptr) {
    throw SaxonApiException("Found null file name");
  }
  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  int64_t result = j_transformToValue(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXT.c_str(), (void *)cppXT,
      (void *)nullptr, (char *)sourcefile, (char *)stylesheetfile,
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

void Xslt30Processor::transformFileToFile(const char *source,
                                          const char *stylesheet,
                                          const char *outputfile) {

  if (exceptionOccurred()) {
    // Possible error detected in the compile phase. Processor not in a clean
    // state. Require clearing exception.
    return;
  }
  proc->attachCurrentThread();
  if (stylesheet == nullptr) {
    throw SaxonApiException("Error: stylesheet has not been set.");
  }

  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  long status = j_transformToFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdXT.c_str(), (void *)cppXT,
      (void *)nullptr, (char *)source, (char *)stylesheet, (char *)outputfile,
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

const char *Xslt30Processor::transformFileToString(const char *source,
                                                   const char *stylesheet) {
  if (exceptionOccurred()) {
    // Possible error detected in the compile phase. Processor not in a clean
    // state. Require clearing exception.
    throw SaxonApiException(
        "Error: Xslt30Processor not in a clean state. - Exception found");
  }
  proc->attachCurrentThread();
  if (source == nullptr && stylesheet == nullptr) {
    throw SaxonApiException(
        "Error: nullptr file name found in transformFileToString.");
  }
  allocFn fn = operator new;

  int addition = 0;
  if (importPackageValue > SXN_UNSET) {
    addition += 1;
  }

  int64_t processorDataRef =
      SaxonProcessor::createParameterJArray(parameters, properties, addition);

  if (importPackageValue > SXN_UNSET) {

    std::string packageOptionStr = "importPack:";
    addProcessorDataPair(
        SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
        (char *)packageOptionStr.c_str(), (void *)importPackageValue);
  }

  char *result = j_transformToString(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (char *)cwdXT.c_str(),
      (void *)cppXT, (void *)nullptr, (char *)source, (char *)stylesheet,
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
  return result;
}

const char *Xslt30Processor::getErrorMessage() { return nullptr; }
