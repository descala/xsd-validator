#ifndef __linux__
#ifndef __APPLE__
//#include "stdafx.h"
#include <Tchar.h>
#endif
#endif

#include "SaxonProcessor.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"
#include "XdmValue.h"

//#define DEBUG

#ifdef DEBUG
#include <signal.h>
#endif

#include <stdio.h>

#if defined MEM_DEBUG

void *newImpl(std::size_t sz, char const *file, int line) {
  static int counter{};
  void *ptr = std::malloc(sz);
  std::cerr << "SaxonC Mem test: " << file << ": " << line << " " << ptr
            << std::endl;
  myAlloc.push_back(ptr);
  return ptr;
}

void *operator new(std::size_t sz, char const *file, int line) {
  return newImpl(sz, file, line);
}

void *operator new[](std::size_t sz, char const *file, int line) {
  return newImpl(sz, file, line);
}

void operator delete(void *ptr) noexcept {
  auto ind = std::distance(myAlloc.begin(),
                           std::find(myAlloc.begin(), myAlloc.end(), ptr));
  myAlloc[ind] = nullptr;
  std::free(ptr);
}

void operator delete(void *ptr, std::size_t) noexcept {
  auto ind = std::distance(myAlloc.begin(),
                           std::find(myAlloc.begin(), myAlloc.end(), ptr));
  std::cerr << "SaxonC Mem test deleting: " << ptr << std::endl;
  myAlloc[ind] = nullptr;
  std::free(ptr);
}

#define new new (__FILE__, __LINE__)

void SaxonProcessor::getInfo() {

  std::cout << std::endl;

  std::cout << "Allocation: " << std::endl;
  for (auto i : myAlloc) {
    if (i != nullptr)
      std::cout << " " << i << std::endl;
  }

  std::cout << std::endl;
}

#endif

// jobject cpp;
const char *failure;
sxnc_environment *SaxonProcessor::sxn_environ = 0;
int SaxonProcessor::jvmCreatedCPP = 0;

bool SaxonProcessor::exceptionOccurred() {
  return (bool)j_checkForException(sxn_environ->thread);
}

const char *SaxonProcessor::checkException() {
  const char *message = nullptr;
  message = checkForException(sxn_environ);
  return message;
}

/*SaxonApiException *SaxonProcessor::checkAndCreateException() {
    SaxonProcessor::attachCurrentThread();
    if (SaxonProcessor::sxn_environ->env->ExceptionCheck()) {
        SaxonApiException *exception =
checkForExceptionCPP(SaxonProcessor::sxn_environ->env, cppClass, nullptr);
#ifdef DEBUG
        SaxonProcessor::sxn_environ->env->ExceptionDescribe();
#endif
        return exception;
    }
    return nullptr;
}
*/
const char *SaxonProcessor::getErrorMessage() {
  if (exception == nullptr) {
    return nullptr;
  }
  return exception->getMessage();
}

void SaxonProcessor::exceptionClear() {

  if (exception != nullptr) {
    delete exception;
    exception = nullptr;
  }
  j_clearException(sxn_environ->thread);
}

/*SaxonProcessor::SaxonProcessor():  {
    licensei = false;
    SaxonProcessor(false);
}*/

SaxonApiException *SaxonProcessor::checkForExceptionCPP(
    /*JNIEnv *env, jclass callingClass, jobject callingObject*/) {

  /* if (env->ExceptionCheck()) {
       std::string result1 = "";
       std::string errorCode = "";
       jthrowable exc = env->ExceptionOccurred();

#ifdef DEBUG
       env->ExceptionDescribe();
#endif
       jclass exccls(env->GetObjectClass(exc));
       jclass clscls(env->FindClass("java/lang/Class"));

       jmethodID getName(env->GetMethodID(clscls, "getName",
"()Ljava/lang/String;")); jstring
name(static_cast<jstring>(env->CallObjectMethod(exccls, getName))); char const
*utfName(env->GetStringUTFChars(name, 0)); result1 = (std::string(utfName));
       env->ReleaseStringUTFChars(name, utfName);

       jmethodID getMessage(env->GetMethodID(exccls, "getMessage",
"()Ljava/lang/String;")); if (getMessage) {

           jstring message((jstring) (env->CallObjectMethod(exc, getMessage)));
           char const *utfMessage = nullptr;
           if (!message) {
               utfMessage = "";
               return nullptr;
           } else {
               utfMessage = (env->GetStringUTFChars(message, 0));
           }
           if (utfMessage != nullptr) {
               result1 = (result1 + " : ") + utfMessage;
           }

           env->ReleaseStringUTFChars(message, utfMessage);

           std::string prefix = "net.sf.saxon.s9api.SaxonApiException";

           if (result1.compare(0, prefix.length(),
"net.sf.saxon.s9api.SaxonApiException") == 0) {

               jclass
saxonApiExceptionClass(env->FindClass("net/sf/saxon/s9api/SaxonApiException"));
               static jmethodID lineNumID = nullptr;
               lineNumID = env->GetMethodID(saxonApiExceptionClass,
"getLineNumber", "()I"); static jmethodID ecID = nullptr; ecID =
env->GetMethodID(saxonApiExceptionClass, "getErrorCode",
"()Lnet/sf/saxon/s9api/QName;");

               static jmethodID esysID = nullptr;
               esysID = env->GetMethodID(saxonApiExceptionClass, "getSystemId",
"()Ljava/lang/String;");

               jobject errCodeQName = (jobject) (env->CallObjectMethod(exc,
ecID));

               jstring errSystemID = (jstring) (env->CallObjectMethod(exc,
esysID));

               int linenum = env->CallIntMethod(exc, lineNumID);

               jclass qnameClass(env->FindClass("net/sf/saxon/s9api/QName"));
               static jmethodID qnameStrID = nullptr;
               qnameStrID = env->GetMethodID(qnameClass, "toString",
"()Ljava/lang/String;");

               jstring qnameStr = nullptr;

               if(errCodeQName) {
                   qnameStr = (jstring) (env->CallObjectMethod(errCodeQName,
qnameStrID));
               }

               SaxonApiException *saxonExceptions = new
SaxonApiException(result1.c_str(), (qnameStr ? env->GetStringUTFChars(qnameStr,
                                                                                                             0)
                                                                                    : nullptr),
                                                                          (errSystemID
? env->GetStringUTFChars( errSystemID, 0) : nullptr), linenum);

               if (errCodeQName) {
                   env->DeleteLocalRef(errCodeQName);
               }
               if (errSystemID) {
                   env->DeleteLocalRef(errSystemID);
               }
               if (qnameStr) {
                   env->DeleteLocalRef(qnameStr);
               }

               if (message) {
                   env->DeleteLocalRef(message);
               }
               env->ExceptionClear();
               return saxonExceptions;
           }
       }
       SaxonApiException *saxonExceptions = new
SaxonApiException(result1.c_str());

       env->ExceptionClear();
       return saxonExceptions;
   } TODO remove comment*/
  return nullptr;
}

SaxonProcessor::SaxonProcessor() { initialize(false); }

SaxonProcessor::SaxonProcessor(bool l) { initialize(l); }

void SaxonProcessor::initialize(bool l) {
  cwd = "";
  licensei = l;
  exception = nullptr;
  procRef = SXN_UNSET;
  if (SaxonProcessor::jvmCreatedCPP == 0) {
    SaxonProcessor::jvmCreatedCPP = 1;
    SaxonProcessor::sxn_environ =
        new sxnc_environment; //(sxnc_environment
                              //*)malloc(sizeof(sxnc_environment));

    /*
     * InitializeGraalvm run-time.
     */
    create_graalvm_isolate(SaxonProcessor::sxn_environ);
#ifdef DEBUG
    setDebugMode(SaxonProcessor::sxn_environ->thread, 1);
#endif
  } else {
#ifdef DEBUG
    std::cerr << "SaxonProc constructor: jvm exists! jvmCreatedCPP="
              << jvmCreatedCPP << std::endl;
#endif
  }
  SaxonProcessor::attachCurrentThread();
  procRef =
      createSaxonProcessor2((SaxonProcessor::sxn_environ->thread), (int)l);

  if (procRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

}

void SaxonProcessor::attachCurrentThread() {
#ifdef DEBUG
  std::cerr << "attachCurrentThread called" << std::endl;
#endif
  int result = attach_graalvm_thread(SaxonProcessor::sxn_environ);
#ifdef DEBUG
  if (result != 0) {
    std::cerr << "attachCurrentThread failed or already in the current thread"
              << std::endl;
  }
#endif
}

void SaxonProcessor::detachCurrentThread() {
#ifdef DEBUG
  std::cerr << "detachCurrentThread called" << std::endl;
#endif
  detach_graalvm_thread(SaxonProcessor::sxn_environ);
#ifdef DEBUG
  if (result != 0) {
    std::cerr << "detachCurrentThread failed" << std::endl;
  }
#endif
}

SaxonProcessor::SaxonProcessor(const char *configFile) {
  cwd = "";

  licensei = true;
  exception = nullptr;
  procRef = SXN_UNSET;
  if (SaxonProcessor::jvmCreatedCPP == 0) {
    SaxonProcessor::jvmCreatedCPP = 1;
    SaxonProcessor::sxn_environ =
        new sxnc_environment; //(sxnc_environment
                              //*)malloc(sizeof(sxnc_environment));

    /*
     * InitializeGraalvm run-time.
     */

    create_graalvm_isolate(SaxonProcessor::sxn_environ);
  } else {
#ifdef DEBUG
    std::cerr << "SaxonProc constructor: jvm exists! jvmCreatedCPP="
              << jvmCreatedCPP << std::endl;
#endif
  }
  procRef = createSaxonProcessorWithConfigurationFile(
      (SaxonProcessor::sxn_environ->thread), (char *)configFile);
  if (procRef == SXN_EXCEPTION) {
    throw SaxonApiException();
    //"Failed to create SaxonProcessor object - with configuration file");
  }

#ifdef DEBUG
  setDebugMode(SaxonProcessor::sxn_environ->thread, 1);
#endif
}

SaxonProcessor::~SaxonProcessor() {
  // SaxonProcessor::attachCurrentThread();
  clearConfigurationProperties();
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "~SaxonProcessor destructor:"
              << " proc ref=" << ((long)procRef) << std::endl;
  }
  if (procRef != SXN_UNSET) {
    if (getenv("SAXONC_DEBUG_FLAG")) {
      std::cerr << "~SaxonProcessor destructor called with destroy:"
                << " ob ref=" << (this) << std::endl;
    }
    // SaxonProcessor::sxn_environ->env->DeleteGlobalRef(proc);
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)procRef);
    procRef = SXN_UNSET;
  }
  if (!versionStr.empty()) {

    versionStr.clear();
  }
  // exceptionClear();
}

bool SaxonProcessor::isSchemaAwareProcessor() {
  SaxonProcessor::attachCurrentThread();
  if (!licensei) {
    return false;
  } else {

    if (procRef < 0) {
      return false;
    }
    licensei =
        j_isSchemaAware(SaxonProcessor::sxn_environ->thread, (void *)procRef);
    return licensei;
  }
}

void SaxonProcessor::applyConfigurationProperties() {
  SaxonProcessor::attachCurrentThread();
  if (configProperties.size() > 0) {
    int size = configProperties.size();
    int64_t processorDataRef = createProcessorDataWithCapacity(
        SaxonProcessor::sxn_environ->thread, size);

    int i = 0;
    std::map<std::string, std::string>::iterator iter =
        configProperties.begin();
    for (iter = configProperties.begin(); iter != configProperties.end();
         ++iter, i++) {
      // cnames[i] = (iter->first).c_str();
      // cvalues[i] = (iter->second).c_str();
      addProcessorPropertyPair(
          SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
          (char *)(iter->first).c_str(), (char *)(iter->second).c_str());
    }

    j_applyToConfiguration(SaxonProcessor::sxn_environ->thread, (void *)procRef,
                           (void *)processorDataRef);
  }
}

XdmValue *SaxonProcessor::makeXdmValueFromRef(int64_t results) {
  if (results > 0) {
    XdmValue *value = nullptr;
    int typeRef = j_getXdmObjectType(SaxonProcessor::sxn_environ->thread,
                                     (void *)results);

    if (getenv("SAXONC_DEBUG_FLAG")) {
      std::cerr << "C++ makeXdmValueFromRef - typeRef= " << typeRef
                << std::endl;
    }
    if (typeRef == SXN_EXCEPTION) {

      throw SaxonApiException();
    }
    XDM_TYPE xdm_type = static_cast<XDM_TYPE>(typeRef);
    if (xdm_type == XDM_ATOMIC_VALUE) {
      value = new XdmValue();
      value->addXdmItem(new XdmAtomicValue(results));

    } else if (xdm_type == XDM_NODE) {
      value = new XdmValue();
      value->addXdmItem(new XdmNode(results));

    } else if (xdm_type == XDM_MAP) {
      value = new XdmValue();
      value->addXdmItem(new XdmMap(results));

    } else if (xdm_type == XDM_ARRAY) {
      value = new XdmValue();
      value->addXdmItem(new XdmArray(results));

    } else if (xdm_type == XDM_FUNCTION_ITEM) {
      value = new XdmValue();
      value->addXdmItem(new XdmFunctionItem(results));
    } else if (typeRef == XDM_EMPTY) {
      // Empty Sequence detected.
      // TODO Maybe we should create an EmptySequence object
      j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)results);
      results = SXN_UNSET;
      return nullptr;

    } else {
      value = new XdmValue(results, true);
    }

    return value;
  } else if (results == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

  return nullptr;
}

XdmItem *SaxonProcessor::makeXdmItemFromRef(int64_t results) {
  if (results > 0) {
    int typeRef = j_getXdmObjectType(SaxonProcessor::sxn_environ->thread,
                                     (void *)results);

    XDM_TYPE xdm_type = static_cast<XDM_TYPE>(typeRef);
    XdmItem *xdmItem = nullptr;
    if (typeRef == SXN_EXCEPTION) {

      throw SaxonApiException();
    }
    if (xdm_type == XDM_ATOMIC_VALUE) {
      xdmItem = new XdmAtomicValue(results);

    } else if (xdm_type == XDM_NODE) {
      xdmItem = new XdmNode(results);

    } else if (xdm_type == XDM_MAP) {
      xdmItem = new XdmMap(results);

    } else if (xdm_type == XDM_ARRAY) {
      xdmItem = new XdmArray(results);

    } else if (xdm_type == XDM_FUNCTION_ITEM) {
      xdmItem = new XdmFunctionItem(results);
    } else if (xdm_type == XDM_EMPTY) {
      // Empty Sequence detected.
      // TODO Maybe we should create an EmptySequence object
      j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)results);
      results = SXN_UNSET;
      return nullptr;

    } else {
      throw SaxonApiException(
          "Internal Error: Cannot create XdmItem from reference");
    }

    return xdmItem;
  } else if (results == SXN_EXCEPTION) {
    throw SaxonApiException();
  }

  return nullptr;
}

int64_t SaxonProcessor::createJArray(XdmValue **values, int length) {
  if (length > 0) {
    int64_t processorDataRef = createProcessorDataWithCapacity(
        SaxonProcessor::sxn_environ->thread, length);

    for (int i = 0; i < length; i++) {

      addProcessorValue(SaxonProcessor::sxn_environ->thread,
                        (void *)processorDataRef,
                        (void *)(values[i])->getUnderlyingValue());
    }

    return processorDataRef;

  } else {
    return SXN_UNSET;
  }
}

int64_t SaxonProcessor::createParameterJArray(
    std::map<std::string, XdmValue *> parameters,
    std::map<std::string, std::string> properties, int additions) {

  int size = parameters.size() + properties.size() + additions;

  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "Properties size: " << properties.size() << std::endl;
    std::cerr << "Parameter size: " << parameters.size() << std::endl;
  }
  if (size > 0) {
    int64_t processorDataRef = createProcessorDataWithCapacity(
        SaxonProcessor::sxn_environ->thread, size);

    int i = 0;
    for (std::map<std::string, XdmValue *>::iterator iter = parameters.begin();
         iter != parameters.end(); ++iter, i++) {

#ifdef DEBUG
      std::cerr << "map 1" << std::endl;
      std::cerr << "iter->first" << (iter->first).c_str() << std::endl;
#endif

      /*#ifdef DEBUG
                  std::string s1 = typeid(iter->second).name();
                  std::cerr<<"Type of itr:"<<s1<<std::endl;

                  if((iter->second) == nullptr) {std::cerr<<"iter->second is
      nullptr"<<std::endl; } else { std::cerr<<"getting underlying
      value"<<std::endl; int64_t xx = (iter->second)->getUnderlyingValue();

                  if(xx == nullptr) {
                      std::cerr<<"value failed"<<std::endl;
                  } else {

                      std::cerr<<"Type of value:"<<((long)xx)<<std::endl;
                  }
                  if((iter->second)->getUnderlyingValue() == SXN_UNSET) {
                      std::cerr<<"(iter->second)->getUnderlyingValue() is
      nullptr"<<std::endl;
                  }}
      #endif  */

      if ((iter->second) == nullptr) {
        continue;
      }

      addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                           (void *)processorDataRef,
                           (char *)(iter->first).c_str(),
                           (void *)(iter->second)->getUnderlyingValue());
    }

    for (std::map<std::string, std::string>::iterator iter = properties.begin();
         iter != properties.end(); ++iter, i++) {
      addProcessorPropertyPair(
          SaxonProcessor::sxn_environ->thread, (void *)processorDataRef,
          (char *)(iter->first).c_str(), (char *)(iter->second).c_str());
    }

    return processorDataRef;

  } else {
    return SXN_UNSET;
  }
}

int64_t SaxonProcessor::createParameterJArray2(
    std::map<std::string, XdmValue *> parameters) {

  int size = parameters.size();
  int64_t processorDataRef = createProcessorDataWithCapacity(
      SaxonProcessor::sxn_environ->thread, size);

#ifdef DEBUG
  std::cerr << "Parameter size: " << parameters.size() << std::endl;
#endif
  if (size > 0) {

    int i = 0;
    for (std::map<std::string, XdmValue *>::iterator iter = parameters.begin();
         iter != parameters.end(); ++iter, i++) {

#ifdef DEBUG
      std::cerr << "map 1" << std::endl;
      std::cerr << "iter->first" << (iter->first).c_str() << std::endl;

#endif

      addProcessorDataPair(SaxonProcessor::sxn_environ->thread,
                           (void *)processorDataRef,
                           (char *)(iter->first).c_str(),
                           (void *)(iter->second)->getUnderlyingValue());
      /*#ifdef DEBUG
                  std::string s1 = typeid(iter->second).name();
                  std::cerr<<"Type of itr:"<<s1<<std::endl;

                  if((iter->second) == nullptr) {std::cerr<<"iter->second is
      nullptr"<<std::endl; } else { std::cerr<<"getting underlying
      value"<<std::endl; jobject xx = (iter->second)->getUnderlyingValue();

                  if(xx == nullptr) {
                      std::cerr<<"value failed"<<std::endl;
                  } else {

                      std::cerr<<"Type of
      value:"<<(typeid(xx).name())<<std::endl;
                  }
                  if((iter->second)->getUnderlyingValue() == nullptr) {
                      std::cerr<<"(iter->second)->getUnderlyingValue() is
      nullptr"<<std::endl;
                  }}
      #endif*/
    }

    return processorDataRef;

  } else {
    return SXN_UNSET;
  }
}

SaxonProcessor &SaxonProcessor::operator=(const SaxonProcessor &other) {
  // SaxonProcessor::attachCurrentThread();

  procRef = other.procRef;
  cwd = other.cwd;

  parameters = other.parameters;
  configProperties = other.configProperties;
  licensei = other.licensei;
  exception = other.exception;
  return *this;
}

SaxonProcessor::SaxonProcessor(const SaxonProcessor &other) {

  procRef = other.procRef;
  cwd = other.cwd;

  parameters = other.parameters;
  configProperties = other.configProperties;
  licensei = other.licensei;
  exception = other.exception;
}

DocumentBuilder *SaxonProcessor::newDocumentBuilder() {
  applyConfigurationProperties();
  int64_t docBuilderRef = createDocumentBuilder(
      SaxonProcessor::sxn_environ->thread, (void *)procRef);

  DocumentBuilder *builder = new DocumentBuilder(this, docBuilderRef, cwd);

  return builder;
}

Xslt30Processor *SaxonProcessor::newXslt30Processor() {
  applyConfigurationProperties();

  return (new Xslt30Processor(this, cwd));
}

XQueryProcessor *SaxonProcessor::newXQueryProcessor() {
  applyConfigurationProperties();
  return (new XQueryProcessor(this, cwd));
}

XPathProcessor *SaxonProcessor::newXPathProcessor() {
  applyConfigurationProperties();
  return (new XPathProcessor(this, cwd));
}

SchemaValidator *SaxonProcessor::newSchemaValidator() {
  if (licensei) {
    applyConfigurationProperties();
    return (new SchemaValidator(this, cwd));
  } else {
    std::cerr << "\nError: Processor is not licensed for schema processing!!"
              << std::endl;
    return nullptr;
  }
}

const char *SaxonProcessor::version() {

  if (versionStr.empty()) {
    versionStr = std::string(j_c_getProductVersion(
        SaxonProcessor::sxn_environ->thread, (void *)procRef));
  }
  return versionStr.c_str();
}

void SaxonProcessor::setcwd(const char *dir) {
  if (dir != nullptr) {
    cwd = std::string(dir);
  }
}

const char *SaxonProcessor::getcwd() { return cwd.c_str(); }

const char *SaxonProcessor::getResourcesDirectory() {
  return ""; //_getResourceDirectory();
}

void SaxonProcessor::setResourcesDirectory(const char *dir) {
  // memset(&resources_dir[0], 0, sizeof(resources_dir));
#if defined(__linux__) || defined(__APPLE__)
  strncat(_getResourceDirectory(), dir, strlen(dir));
#else
  int destSize = strlen(dir) + strlen(dir);
  strncat_s(_getResourceDirectory(), destSize, dir, strlen(dir));

#endif
}

void SaxonProcessor::setCatalog(const char *catalogFile) {
  SaxonProcessor::attachCurrentThread();

  if (catalogFile == nullptr) {

    return;
  }

  if (procRef == SXN_UNSET) {
    throw SaxonApiException(
        "Processor is null in SaxonProcessor.setCatalogFiles");
    return;
  }
  int64_t processorDataRef =
      createProcessorDataWithCapacity(sxn_environ->thread, 1);

  addProcessorProperty(sxn_environ->thread, (void *)processorDataRef,
                       (char *)catalogFile);

  long result =
      j_setCatalogFiles(sxn_environ->thread, (void *)procRef,
                        (char *)cwd.c_str(), (void *)processorDataRef);
  if (result == SXN_UNSET) {
    throw SaxonApiException("setCatalogFile failed");
  }
}

void SaxonProcessor::setCatalogFiles(const char **catalogFiles, int length) {
  SaxonProcessor::attachCurrentThread();

  if (catalogFiles == nullptr && length > 0) {

    return;
  }

  if (procRef == SXN_UNSET) {
    throw SaxonApiException(
        "Processor is null in SaxonProcessor.setCatalogFiles");
    return;
  }

  int64_t processorDataRef =
      createProcessorDataWithCapacity(sxn_environ->thread, length);

  for (int i = 0; i < length; i++) {

    if (catalogFiles[i] != nullptr) {
      addProcessorProperty(sxn_environ->thread, (void *)processorDataRef,
                           (char *)catalogFiles[i]);
    }
  }

  long result =
      j_setCatalogFiles(sxn_environ->thread, (void *)procRef,
                        (char *)cwd.c_str(), (void *)processorDataRef);
  if (result == SXN_UNSET) {
    throw SaxonApiException("setCatalogFile failed");
  } else if (result == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
}

XdmValue *SaxonProcessor::parseJsonFromString(const char *source,
                                              const char *encoding) {

  if (source == nullptr) {
    throw SaxonApiException("JSON source string is null");
  }

  applyConfigurationProperties();
  int64_t xdmValueRef = parseJsonString(sxn_environ->thread, (void *)procRef,
                                        (char *)source, (char *)encoding);
  if (xdmValueRef >= 0) {
    XdmValue *value = new XdmValue(xdmValueRef);

    return value;
  } else if (xdmValueRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

XdmValue *SaxonProcessor::parseJsonFromFile(const char *source) {

  if (source == nullptr) {
    throw SaxonApiException("JSON source file name is null");
  }

  applyConfigurationProperties();
  int64_t xdmValueRef = parseJsonFile(sxn_environ->thread, (void *)procRef,
                                      (char *)cwd.c_str(), (char *)source);
  if (xdmValueRef >= 0) {
    XdmValue *value = new XdmValue(xdmValueRef);

    return value;
  } else if (xdmValueRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

XdmNode *SaxonProcessor::parseXmlFromString(const char *source,
                                            const char *encoding,
                                            SchemaValidator *validator) {
  // SaxonProcessor::attachCurrentThread();

  applyConfigurationProperties();
  int64_t xdmNodeRef = parseXmlStringWithValidator(
      sxn_environ->thread, (void *)procRef, (char *)encoding,
      (validator != nullptr ? (void *)validator->getUnderlyingValidator()
                            : (void *)NULL),
      (char *)source);
  if (xdmNodeRef >= 0) {
    XdmNode *value = new XdmNode(xdmNodeRef);

    return value;
  } else if (xdmNodeRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

int SaxonProcessor::getNodeKind(int64_t nodeRef) {
  SaxonProcessor::attachCurrentThread();
  int nodeKind = j_getNodeKind(sxn_environ->thread, (void *)nodeRef);

  return nodeKind;
}

XdmNode *SaxonProcessor::parseXmlFromFile(const char *filename,
                                          SchemaValidator *validator) {
  applyConfigurationProperties();
  int64_t xdmNodeRef = parseXmlFileWithValidator(
      sxn_environ->thread, (char *)cwd.c_str(), (void *)procRef,
      (validator != nullptr ? (void *)validator->getUnderlyingValidator()
                            : (void *)nullptr),
      (char *)filename);
  if (xdmNodeRef >= 1) {
    XdmNode *value = nullptr;
    value = new XdmNode(xdmNodeRef);

    return value;
  } else if (xdmNodeRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

XdmNode *SaxonProcessor::parseXmlFromUri(const char *uri,
                                         SchemaValidator *validator) {
  applyConfigurationProperties();
  int64_t xdmNodeRef = parseXmlFileWithValidator(
      sxn_environ->thread, (char *)cwd.c_str(), (void *)procRef,
      (validator != nullptr ? (void *)validator->getUnderlyingValidator()
                            : (void *)nullptr),
      (char *)uri);
  if (xdmNodeRef >= 0) {
    XdmNode *value = nullptr;
    value = new XdmNode(xdmNodeRef);

    return value;
  } else if (xdmNodeRef == SXN_EXCEPTION) {
    throw SaxonApiException();
  }
  return nullptr;
}

/**
 * Set a configuration property.
 */
void SaxonProcessor::setConfigurationProperty(const char *name,
                                              const char *value) {
  if (name != nullptr && value != nullptr) {
    configProperties.insert(std::pair<std::string, std::string>(
        std::string(name), std::string((value == nullptr ? "" : value))));
  }
}

void SaxonProcessor::clearConfigurationProperties() {
  configProperties.clear();
}

void SaxonProcessor::createHeapDump(bool live) {
  j_createHeapDump(sxn_environ->thread, (int)live);
}

void SaxonProcessor::release() {
  if (SaxonProcessor::jvmCreatedCPP != 0) {
    SaxonProcessor::jvmCreatedCPP = 0;
#ifdef DEBUG
    std::cerr << "SaxonProc: JVM finalized calling !" << std::endl;
#endif
    // finalizeJavaRT(SaxonProcessor::sxn_environ->jvm);

    // delete SaxonProcessor::sxn_environ;

    if (graal_detach_thread(sxn_environ->thread) != 0) {
      fprintf(stderr, "graal_detach_thread error\n");
      return;
    }

  } else {
#ifdef DEBUG
    std::cerr << "SaxonProc: JVM finalize not called!" << std::endl;
#endif
  }
}

void SaxonProcessor::deleteXdmValueArray(XdmValue **arr, int len) {
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

void SaxonProcessor::deleteXdmAtomicValueArray(XdmAtomicValue **arr, int len) {
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

/* ========= Factory method for Xdm ======== */

XdmAtomicValue *SaxonProcessor::makeStringValue(const char *str,
                                                const char *encoding) {
  SaxonProcessor::attachCurrentThread();
  int64_t stringValueRef =
      j_makeStringValue(sxn_environ->thread, (char *)str, (char *)encoding);
  XdmAtomicValue *value = new XdmAtomicValue(stringValueRef, "xs:string");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeStringValue(std::string str,
                                                const char *encoding) {
  SaxonProcessor::attachCurrentThread();

  int64_t stringValueRef = j_makeStringValue(
      sxn_environ->thread, (char *)str.c_str(), (char *)encoding);
  XdmAtomicValue *value = new XdmAtomicValue(stringValueRef, "xs:string");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeIntegerValue(int i) {
  SaxonProcessor::attachCurrentThread();
  // jobject obj = integerValue(*SaxonProcessor::sxn_environ, i);

  int64_t intValueRef = j_makeIntegerValue(sxn_environ->thread, i);
  XdmAtomicValue *value = new XdmAtomicValue(
      intValueRef, "Q{http://www.w3.org/2001/XMLSchema}integer");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeDoubleValue(double d) {
  SaxonProcessor::attachCurrentThread();

  int64_t doubleValueRef = j_makeDoubleValue(sxn_environ->thread, d);
  XdmAtomicValue *value = new XdmAtomicValue(
      doubleValueRef, "Q{http://www.w3.org/2001/XMLSchema}double");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeFloatValue(float d) {
  int64_t floatValueRef = j_makeFloatValue(sxn_environ->thread, d);
  XdmAtomicValue *value = new XdmAtomicValue(
      floatValueRef, "Q{http://www.w3.org/2001/XMLSchema}float");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeLongValue(long l) {
  SaxonProcessor::attachCurrentThread();
  // jobject obj = longValue(*SaxonProcessor::sxn_environ, l);

  int64_t longValueRef = j_makeLongValue(sxn_environ->thread, l);
  XdmAtomicValue *value = new XdmAtomicValue(
      longValueRef, "Q{http://www.w3.org/2001/XMLSchema}long");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeBooleanValue(bool b) {
  SaxonProcessor::attachCurrentThread();
  int64_t boolValueRef = j_makeBooleanValue(sxn_environ->thread, (int)b);
  XdmAtomicValue *value = new XdmAtomicValue(
      boolValueRef, "Q{http://www.w3.org/2001/XMLSchema}boolean");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeQNameValue(const char *str) {
  SaxonProcessor::attachCurrentThread();
  int64_t qnameValueRef = j_makeQNameValue(sxn_environ->thread, (char *)str);
  XdmAtomicValue *value = new XdmAtomicValue(qnameValueRef, "QName");
  return value;
}

XdmAtomicValue *SaxonProcessor::makeAtomicValue(const char *typei,
                                                const char *strValue) {
  return nullptr;
  // TODO fix this method
  /*SaxonProcessor::attachCurrentThread();
  jobject obj = xdmValueAsObj(SaxonProcessor::sxn_environ, typei, strValue);
  XdmAtomicValue *value = new XdmAtomicValue(obj, typei);
  SaxonProcessor::sxn_environ->env->DeleteLocalRef(obj);
  return value;*/
}

const char *SaxonProcessor::clarkNameToEQName(const char *name) {
  allocFn fn = operator new;
  const char *result = j_clarkNameToEQName(SaxonProcessor::sxn_environ->thread,
                                           (void *)fn, (char *)name);
  return result;
}

const char *SaxonProcessor::EQNameToClarkName(const char *name) {
  allocFn fn = operator new;
  const char *result = j_EQNameToClarkName(SaxonProcessor::sxn_environ->thread,
                                           (void *)fn, (char *)name);
  return result;
}

const char *SaxonProcessor::getStringValue(XdmItem *item) {
  allocFn fn = operator new;
  const char *result =
      j_cpp_getStringValue(SaxonProcessor::sxn_environ->thread,
                           (void *)item->getUnderlyingValue(), (void *)fn);
#ifdef DEBUG
  if (result == nullptr) {
    std::cerr << "getStringValue of XdmItem is nullptr" << std::endl;
  } else {
    std::cerr << "getStringValue of XdmItem is OK" << std::endl;
  }
#endif

  return result;
}

#if CVERSION_API_NO >= 123

XdmArray *SaxonProcessor::makeArray(short *input, int length) {
  SaxonProcessor::attachCurrentThread();
  if (input == nullptr) {
    std::cerr << "Error found when converting pointer array of short values to "
                 "XdmArray";
    return nullptr;
  }
  int64_t xdmArrayRef =
      j_makeXdmArrayFromShort(sxn_environ->thread, input, length);

  XdmArray *newArray = new XdmArray(xdmArrayRef, length);
  return newArray;
}

XdmArray *SaxonProcessor::makeArray(XdmValue **input, int length) {
  SaxonProcessor::attachCurrentThread();
  int64_t processorDataRef = SXN_UNSET;

  if (length == 0) {
    processorDataRef = createProcessorData(sxn_environ->thread);
    std::cerr << "Converting array of XdmValue to XdmArray length=0"
              << std::endl;
  } else {
    processorDataRef =
        createProcessorDataWithCapacity(sxn_environ->thread, length);
  }

  for (int i = 0; i < length; i++) {
    if (input[i] == nullptr || input[i]->getUnderlyingValue() <= SXN_UNSET) {
      std::cerr << "Error found when converting array of XdmValue to XdmArray"
                << std::endl;
      return nullptr;
    }
    addProcessorValue(sxn_environ->thread, (void *)processorDataRef,
                      (void *)input[i]->getUnderlyingValue());
  }

  int64_t xdmArrayRef =
      j_makeXdmArray(sxn_environ->thread, (void *)processorDataRef);

  if (xdmArrayRef <= 0) {
    std::cerr
        << "Error found when converting array of XdmValue to XdmArray - Ref="
        << ((long)xdmArrayRef) << std::endl;
    return nullptr;
  }

  XdmArray *newArray = new XdmArray(xdmArrayRef, length);
  return newArray;
}

XdmArray *SaxonProcessor::makeArray(int *input, int length) {
  SaxonProcessor::attachCurrentThread();
  if (input == nullptr) {
    std::cerr << "Error found when converting pointer array of int values to "
                 "XdmArray";
    return nullptr;
  }
  int64_t xdmArrayRef =
      j_makeXdmArrayFromInt(sxn_environ->thread, input, length);

  XdmArray *newArray = new XdmArray(xdmArrayRef, length);
  return newArray;
}

XdmArray *SaxonProcessor::makeArray(long long *input, int length) {
  SaxonProcessor::attachCurrentThread();
  if (input == nullptr) {
    std::cerr << "Error found when converting pointer array of long values to "
                 "XdmArray";
    return nullptr;
  }
  int64_t xdmArrayRef =
      j_makeXdmArrayFromLong(sxn_environ->thread, input, length);

  XdmArray *newArray = new XdmArray(xdmArrayRef, length);
  return newArray;
}

XdmArray *SaxonProcessor::makeArray(bool *input, int length) {

  if (input == nullptr) {
    std::cerr << "Error found when converting pointer array of bool values to "
                 "XdmArray";
    return nullptr;
  }
  int *inputAsInts = new int[length];

  for (int i = 0; i < length; i++) {
    inputAsInts[i] = (int)input[i];
  }

  int64_t xdmArrayRef =
      j_makeXdmArrayFromBool(sxn_environ->thread, inputAsInts, length);
  XdmArray *newArray = new XdmArray(xdmArrayRef, length);
  return newArray;
}

XdmArray *SaxonProcessor::makeArray(const char **input, int length) {
  // SaxonProcessor::attachCurrentThread();
  if (input == nullptr) {
    std::cerr << "Error found when converting array of strings to XdmArray";
    return nullptr;
  }
  /*  int64_t  xdmArrayRef = j_makeXdmArrayFromStrings(sxn_environ->thread,
    input, length);

    int64_t processorDataRef =
    createProcessorDataWithCapacity(SaxonProcessor::sxn_environ->thread,
    length);

    for (int i =0 ; i< length; i++) {
        add
    }

    XdmArray * newArray = new XdmArray(xdmArrayRef, length);
    return newArray;*/
  return nullptr;
}

XdmMap *
SaxonProcessor::makeMap(std::map<XdmAtomicValue *, XdmValue *> dataMap) {
  SaxonProcessor::attachCurrentThread();
  int64_t mapDataRef = SXN_UNSET;

  mapDataRef =
      j_create_mapDataWithCapacity(sxn_environ->thread, dataMap.size());

  for (std::map<XdmAtomicValue *, XdmValue *>::iterator iter = dataMap.begin();
       iter != dataMap.end(); ++iter) {
    if ((iter->first)->getUnderlyingValue() <= SXN_UNSET ||
        (iter->second)->getUnderlyingValue() <= SXN_UNSET) {
      std::cerr << "Error found when converting array of XdmValue to XdmArray"
                << std::endl;
      return nullptr;
    }
    j_addMapPair(sxn_environ->thread, (void *)mapDataRef,
                 (void *)(iter->first)->getUnderlyingValue(),
                 (void *)(iter->second)->getUnderlyingValue());
  }

  int64_t xdmmapRef = j_makeXdmMap(sxn_environ->thread, (void *)mapDataRef);

  if (xdmmapRef <= 0) {
    std::cerr << "Error found when converting std:map of pair (XdmAtomicValue, "
                 "XdmValue) to XdmMap - Ref="
              << ((long)xdmmapRef) << std::endl;
    // TODO create exception
    return nullptr;
  }

  XdmMap *newArray = new XdmMap(xdmmapRef);
  return newArray;
}

XdmMap *SaxonProcessor::makeMap2(std::map<std::string, XdmValue *> dataMap) {
  SaxonProcessor::attachCurrentThread();
  int64_t mapDataRef = SXN_UNSET;

  mapDataRef =
      j_create_mapDataWithCapacity(sxn_environ->thread, dataMap.size());

  for (std::map<std::string, XdmValue *>::iterator iter = dataMap.begin();
       iter != dataMap.end(); ++iter) {
    if ((iter->first).empty() ||
        (iter->second)->getUnderlyingValue() <= SXN_UNSET) {
      std::cerr << "Error found when converting array of XdmValue to XdmArray"
                << std::endl;
      return nullptr;
    }
    int64_t stringValueRef = j_makeStringValue(
        sxn_environ->thread, (char *)(iter->first).c_str(), (char *)nullptr);
    XdmAtomicValue *stringValue =
        new XdmAtomicValue(stringValueRef, "xs:string");
    j_addMapPair(sxn_environ->thread, (void *)mapDataRef,
                 (void *)stringValue->getUnderlyingValue(),
                 (void *)(iter->second)->getUnderlyingValue());
    delete stringValue;
  }

  int64_t xdmmapRef = j_makeXdmMap(sxn_environ->thread, (void *)mapDataRef);

  if (xdmmapRef <= 0) {
    std::cerr << "Error found when converting std:map of pair (XdmAtomicValue, "
                 "XdmValue) to XdmMap - Ref="
              << ((long)xdmmapRef) << std::endl;
    // TODO create exception
    return nullptr;
  }

  XdmMap *newArray = new XdmMap(xdmmapRef);
  return newArray;
}

XdmMap *SaxonProcessor::makeMap3(XdmAtomicValue **keys, XdmValue **values,
                                 int size) {
  int64_t mapDataRef = SXN_UNSET;

  mapDataRef = j_create_mapDataWithCapacity(sxn_environ->thread, size);

  for (int i = 0; i < size; i++) {
    if (keys[i]->getUnderlyingValue() <= SXN_UNSET ||
        values[i]->getUnderlyingValue() <= SXN_UNSET) {
      std::cerr << "Error found when converting array of XdmValue to XdmArray"
                << std::endl;
      return nullptr;
    }
    j_addMapPair(sxn_environ->thread, (void *)mapDataRef,
                 (void *)keys[i]->getUnderlyingValue(),
                 (void *)values[i]->getUnderlyingValue());
  }

  int64_t xdmmapRef = j_makeXdmMap(sxn_environ->thread, (void *)mapDataRef);

  if (xdmmapRef <= 0) {
    std::cerr << "Error found when converting std:map of pair (XdmAtomicValue, "
                 "XdmValue) to XdmMap - Ref="
              << ((long)xdmmapRef) << std::endl;
    // TODO create exception
    return nullptr;
  }

  XdmMap *newArray = new XdmMap(xdmmapRef);
  return newArray;
}

#endif
