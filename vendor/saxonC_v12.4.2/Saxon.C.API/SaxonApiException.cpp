// SaxonApiException.cpp : Defines the exported functions for the DLL
// application.
//

#include "SaxonApiException.h"

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

const char *SaxonApiException::what() {
  if (message.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    if (isStaticError) {
      tempm = j_getCombinedStaticErrorMessages(
          SaxonProcessor::sxn_environ->thread, (void *)fn);

    } else {
      tempm =
          j_getErrorMessage(SaxonProcessor::sxn_environ->thread, (void *)fn);
    }
    if (tempm == nullptr) {
      return nullptr;
    }
    message = std::string(tempm);
    operator delete(tempm);
  }
  return message.c_str();
}

SaxonApiException::SaxonApiException(bool staticError) {
  message = "";
  lineNumber = -1;
  errorCode = "";
  systemId = "";
  cppException = false;
  isStaticError = staticError;
}

SaxonApiException::SaxonApiException(const SaxonApiException &ex) {
  message = ex.message;
  lineNumber = ex.lineNumber;
  errorCode = ex.errorCode;
  systemId = ex.systemId;
  cppException = ex.cppException;
  isStaticError = ex.isStaticError;
}

SaxonApiException::SaxonApiException(const char *m) {
  if (m != nullptr) {
    message = std::string(m);
  } else {
    message = "unknown exception";
  }

  lineNumber = -1;
  errorCode = "";
  systemId = "";
  cppException = true;
  isStaticError = false;
}

SaxonApiException::SaxonApiException(const char *m, const char *ec,
                                     const char *sysId, int linenumber) {
  if (m != nullptr) {
    message = std::string(m);
  } else {
    message = "";
  }

  lineNumber = linenumber;

  if (ec != nullptr) {
    errorCode = std::string(ec);
  } else {
    errorCode = "";
  }

  if (sysId != nullptr) {
    systemId = std::string(sysId);
  } else {
    systemId = "";
  }
  cppException = true;
  isStaticError = false;
}

SaxonApiException::~SaxonApiException() throw() {
  if (!message.empty()) {
    message.clear();
  }
  if (!s_message.empty()) {
    s_message.clear();
  }
  if (!ec_message.empty()) {
    ec_message.clear();
  }
  if (!errorCode.empty()) {
    errorCode.clear();
  }
  if (!systemId.empty()) {
    systemId.clear();
  }
  if (!cppException) {
    j_clearException(SaxonProcessor::sxn_environ->thread);
  }
}

/**
 * Get the error code associated with the ith exception in the vector, if there
 * is one
 * @param i - ith exception in the vector
 * @return the associated error code, or nullptr if no error code is available
 */
const char *SaxonApiException::getErrorCode() {
  if (errorCode.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    tempm = j_getErrorCode(SaxonProcessor::sxn_environ->thread, (void *)fn);
    if (tempm == nullptr) {
      return nullptr;
    }
    errorCode = std::string(tempm);
    operator delete(tempm);
  }
  return errorCode.c_str();
}

int SaxonApiException::getLineNumber() {
  if (lineNumber == -1 && !cppException) {
    lineNumber = j_getLineNumber(SaxonProcessor::sxn_environ->thread);
  }
  return lineNumber;
}

const char *SaxonApiException::getSystemId() {
  if (systemId.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    tempm = j_getSystemId(SaxonProcessor::sxn_environ->thread, (void *)fn);
    if (tempm == nullptr) {
      return nullptr;
    }
    systemId = std::string(tempm);
    operator delete(tempm);
  }
  return systemId.c_str();
}

const char *SaxonApiException::getMessage() {
  if (message.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    if (isStaticError) {
      tempm = j_getCombinedStaticErrorMessages(
          SaxonProcessor::sxn_environ->thread, (void *)fn);
    } else {
      tempm =
          j_getErrorMessage(SaxonProcessor::sxn_environ->thread, (void *)fn);
    }
    if (tempm == nullptr) {
      return nullptr;
    }
    message = std::string(tempm);
    operator delete(tempm);
  }

  return message.c_str();
}

const char *SaxonApiException::getMessageWithErrorCode() {

  if (ec_message.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    if (isStaticError) {
      tempm = j_getCombinedStaticErrorMessages(
          SaxonProcessor::sxn_environ->thread, (void *)fn);
    } else {
      tempm = j_getErrorMessageWithErrorCode(
          SaxonProcessor::sxn_environ->thread, (void *)fn);
    }
    if (tempm == nullptr) {
      return nullptr;
    }
    ec_message = std::string(tempm);
    operator delete(tempm);
  }
  return ec_message.c_str();
}

const char *SaxonApiException::getCombinedStaticErrorMessages() {
  if (s_message.empty() && !cppException) {
    allocFn fn = operator new;
    char *tempm = nullptr;
    tempm = j_getCombinedStaticErrorMessages(
        SaxonProcessor::sxn_environ->thread, (void *)fn);
    if (tempm == nullptr) {
      return nullptr;
    }
    s_message = std::string(tempm);
    operator delete(tempm);
  }
  return s_message.c_str();
}

int SaxonApiException::staticErrorCount() {
  return j_staticErrorCount(SaxonProcessor::sxn_environ->thread);
}
