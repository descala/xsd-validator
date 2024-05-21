// DocumentBuilder.cpp : Defines the exported functions for the DLL application.
//

#include "DocumentBuilder.h"
#include "XdmNode.h"

DocumentBuilder::DocumentBuilder() {
  exception = nullptr;
  schemaValidator = nullptr;
  proc = new SaxonProcessor(false);
  docBuilderObject = createDocumentBuilder(SaxonProcessor::sxn_environ->thread,
                                           (void *)proc->procRef);
  lineNumbering = -1;
  dtdVal = -1;
}

DocumentBuilder::DocumentBuilder(SaxonProcessor *p, int64_t docObject,
                                 std::string cwd) {

  docBuilderObject = docObject;
  lineNumbering = false;
  dtdVal = false;
  schemaValidator = nullptr;
  cwdDB = cwd;
  proc = p;
  exception = nullptr;
  /*if(!cwd.empty()) {
       setBaseUri(cwd.c_str());
  }  */
}

DocumentBuilder::DocumentBuilder(const DocumentBuilder &other) {

  docBuilderObject = other.docBuilderObject;
  lineNumbering = other.lineNumbering;
  schemaValidator = other.schemaValidator;
  dtdVal = other.dtdVal;
  cwdDB = other.cwdDB;
  proc = other.proc;
  exception = other.exception;
}

DocumentBuilder::~DocumentBuilder() {
  if (docBuilderObject != -1) {
    docBuilderObject = -1;
  }
  cwdDB.erase();
  baseURI.erase();
  exceptionClear();
  // delete contextItem;
}

void DocumentBuilder::setLineNumbering(bool option) {
  lineNumbering = option;
  int64_t status = j_db_setLineNumbering(SaxonProcessor::sxn_environ->thread,
                                         (void *)docBuilderObject, (int)option);
  if (status == -2) {
    throw SaxonApiException();
  }
}

bool DocumentBuilder::isLineNumbering() { return lineNumbering; }

void DocumentBuilder::setSchemaValidator(SchemaValidator *validator) {
  schemaValidator = validator;
}

SchemaValidator *DocumentBuilder::getSchemaValidator() {
  return schemaValidator;
}

void DocumentBuilder::setDTDValidation(bool option) {
  dtdVal = option;
  int64_t status = j_db_setDTDValidation(SaxonProcessor::sxn_environ->thread,
                                         (void *)docBuilderObject, (int)option);
  if (status == -2) {
    throw SaxonApiException();
  }
}

bool DocumentBuilder::isDTDValidation() { return dtdVal; }

void DocumentBuilder::setBaseUri(const char *uri) {
  if (!baseURI.empty()) {
    baseURI.erase();
  }
  baseURI = std::string(uri);

  int64_t status = j_db_setBaseURI(SaxonProcessor::sxn_environ->thread,
                                   (void *)docBuilderObject, (char *)uri);
  if (status == -2) {
    throw SaxonApiException();
  }
}

const char *DocumentBuilder::getBaseUri() { return baseURI.c_str(); }

XdmNode *DocumentBuilder::parseXmlFromString(const char *source,
                                             const char *encoding) {
  int64_t result = j_main_parseXmlString(
      SaxonProcessor::sxn_environ->thread,
      (baseURI.empty() ? (char *)nullptr : (char *)baseURI.c_str()),
      (void *)proc->procRef, (void *)docBuilderObject,
      (schemaValidator != nullptr
           ? (void *)schemaValidator->getUnderlyingValidator()
           : (void *)nullptr),
      (char *)source, (char *)encoding);
  if (result > 0) {
    XdmNode *node = new XdmNode(result);
    return node;
  } else if (result == -2) {
    throw SaxonApiException();
  }

  return nullptr;
}

XdmNode *DocumentBuilder::parseXmlFromFile(const char *filename) {
  int64_t result = j_main_parseXmlFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdDB.c_str(),
      (void *)proc->procRef, (void *)docBuilderObject,
      (schemaValidator != nullptr
           ? (void *)schemaValidator->getUnderlyingValidator()
           : (void *)nullptr),
      (char *)filename);
  if (result > 0) {
    XdmNode *node = new XdmNode(result);
    return node;
  } else if (result == -2) {
    throw SaxonApiException();
  }
  return nullptr;
}

XdmNode *DocumentBuilder::parseXmlFromUri(const char *uri) {
  int64_t result = j_main_parseXmlFile(
      SaxonProcessor::sxn_environ->thread, (char *)cwdDB.c_str(),
      (void *)proc->procRef, (void *)docBuilderObject,
      (schemaValidator != nullptr
           ? (void *)schemaValidator->getUnderlyingValidator()
           : (void *)nullptr),
      (char *)uri);
  if (result > 0) {
    XdmNode *node = new XdmNode(result);
    return node;
  } else if (result == -2) {
    throw SaxonApiException();
  }

  return nullptr;
}

void DocumentBuilder::exceptionClear() {

  j_clearException(SaxonProcessor::sxn_environ->thread);
}

const char *DocumentBuilder::getErrorCode() { return nullptr; }

const char *DocumentBuilder::getErrorMessage() { return nullptr; }

SaxonApiException *DocumentBuilder::getException() { return nullptr; }

bool DocumentBuilder::exceptionOccurred() { return proc->exceptionOccurred(); }

void DocumentBuilder::createException(const char *message) {}
