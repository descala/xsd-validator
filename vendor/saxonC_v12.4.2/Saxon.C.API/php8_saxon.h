////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#ifndef
/// PHP_SAXON_H

#ifndef PHP_SAXON_H
#define PHP_SAXON_H

#ifdef __cplusplus
extern "C" { // remove comment
#endif

#include "php.h"
#include "php_ini.h"
#include "Zend/zend_exceptions.h"
#include "ext/standard/info.h"

#include "SAPI.h"
#include "zend_closures.h"
#include "zend_ini.h"
#include "zend_interfaces.h"
#include "zend_types.h"
#ifdef PHP_WIN32
#define _ALLOW_KEYWORD_MACROS
#endif

#ifdef PHP_WIN32
#define PHP_SAXON_API __declspec(dllexport)
#define PHP_SAXON __declspec(dllimport)
//#elif define(__GNUC__) && __GNUC__ >= 4
//#define PHP_SAXON __attribute__ ((visibility("default")))
//#else
//#define PHP_SAXON_API
#endif

#ifdef ZTS
#include "TSRM.h"
#endif
#ifdef __cplusplus
} // remove comment
#endif
#include "SaxonProcessor.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"
#include "XdmValue.h"

#include "php8_saxon_arginfo.h"

/*class SaxonProcessor;
class XQueryProcessor;
class XsltProcessor;
class XdmValue;*/

extern zend_module_entry saxon_module_entry;
#define phpext_saxon_ptr &saxon_module_entry;

#ifdef PHP_WIN32
#define PHP_SAXON_API __declspec(dllexport)
#elif defined(__GNUC__) && __GNUC__ >= 4
#define PHP_SAXON_API __attribute__((visibility("default")))
#else
#define PHP_SAXON_API
#endif

#define SAXON_G(v) ZEND_MODULE_GLOBALS_ACCESSOR(saxon, v)

#if defined(ZTS) && defined(COMPILE_DL_SAXON)
ZEND_TSRMLS_CACHE_EXTERN()
#endif

/*
#if PHP_MAJOR_VERSION < 7
#define _ZVAL_STRING(str, len) ZVAL_STRING(str, len, 0)
#define _RETURN_STRING(str) RETURN_STRING(str, 0)
#else
#define _ZVAL_STRING(str, len) ZVAL_STRING(str, len)
#define _RETURN_STRING(str) RETURN_STRING(str)
#endif    */

struct zvalArr {
  zval *_val;
};

struct saxonProcessor_object {

  SaxonProcessor *saxonProcessor;
  zend_object std;
};

struct documentBuilder_object {

  DocumentBuilder *documentBuilder;
  zend_object std;
};

struct xqueryProcessor_object {
  XQueryProcessor *xqueryProcessor;
  zend_object std;
};

struct xpathProcessor_object {

  XPathProcessor *xpathProcessor;
  zend_object std;
};

struct schemaValidator_object {

  SchemaValidator *schemaValidator;
  zend_object std;
};

struct xdmValue_object {

  XdmValue *xdmValue;
  zend_object std;
};

struct xdmItem_object {

  XdmItem *xdmItem;
  zend_object std;
};

struct xdmNode_object {

  XdmNode *xdmNode;
  zend_object std;
};

struct xdmAtomicValue_object {

  XdmAtomicValue *xdmAtomicValue;
  zend_object std;
};

struct xdmFunctionItem_object {

  XdmFunctionItem *xdmFunctionItem;
  zend_object std;
};

struct xdmMap_object {

  XdmMap *xdmMap;
  zend_object std;
};

struct xdmArray_object {

  XdmArray *xdmArray;
  zend_object std;
};

struct xslt30Processor_object {

  Xslt30Processor *xslt30Processor;
  zend_object std;
};

struct xsltExecutable_object {

  XsltExecutable *xsltExecutable;
  zend_object std;
};

#define PHP_SAXON_EXTNAME "saxonc"
#define PHP_SAXON_EXTVER "11.4"

/*
 * Class:     com_saxonica_functions_extfn_PhpCall_PhpFunctionCall
 * Method:    _phpCall
 * Signature: ([Ljava/lang/String;[Ljava/lang/String;)Ljava/lang/Object;
 */

/* jobject JNICALL phpNativeCall
  (JNIEnv *env, jobject object, jstring funcName, jobjectArray arguments,
  jobjectArray arrayTypes); */

PHP_MSHUTDOWN_FUNCTION(saxon);
PHP_MINFO_FUNCTION(saxon);
PHP_MINIT_FUNCTION(saxon);
PHP_RINIT_FUNCTION(saxon);

PHP_METHOD(SaxonProcessor, __construct);
PHP_METHOD(SaxonProcessor, __destruct);

PHP_METHOD(SaxonProcessor, createAtomicValue);

PHP_METHOD(SaxonProcessor, createXdmMapValue);
PHP_METHOD(SaxonProcessor, createXdmArrayValue);
PHP_METHOD(SaxonProcessor, createQNameValue);

PHP_METHOD(SaxonProcessor, parseXmlFromString);
PHP_METHOD(SaxonProcessor, parseXmlFromFile);
PHP_METHOD(SaxonProcessor, parseXmlFromUri);
PHP_METHOD(SaxonProcessor, parseJsonFromString);
PHP_METHOD(SaxonProcessor, parseJsonFromFile);
PHP_METHOD(SaxonProcessor, setcwd);
PHP_METHOD(SaxonProcessor, attachCurrentThread);
PHP_METHOD(SaxonProcessor, detachCurrentThread);

PHP_METHOD(SaxonProcessor, setCatalog);
PHP_METHOD(SaxonProcessor, setCatalogFiles);
PHP_METHOD(SaxonProcessor, registerPHPFunctions);
PHP_METHOD(SaxonProcessor, getErrorMessage);
PHP_METHOD(SaxonProcessor, exceptionOccurred);
PHP_METHOD(SaxonProcessor, setConfigurationProperty);
PHP_METHOD(SaxonProcessor, clearConfigurationProperties);
PHP_METHOD(SaxonProcessor, newXslt30Processor);
PHP_METHOD(SaxonProcessor, newXQueryProcessor);
PHP_METHOD(SaxonProcessor, newXPathProcessor);
PHP_METHOD(SaxonProcessor, newSchemaValidator);
PHP_METHOD(SaxonProcessor, newDocumentBuilder);
PHP_METHOD(SaxonProcessor, version);
PHP_METHOD(SaxonProcessor, isSchemaAware);
PHP_METHOD(SaxonProcessor, release);
PHP_METHOD(SaxonProcessor, exceptionClear);
PHP_METHOD(SaxonProcessor, exceptionOccurred);
PHP_METHOD(SaxonProcessor, getErrorMessage);
PHP_METHOD(SaxonProcessor, EQNameToClarkName);
PHP_METHOD(SaxonProcessor, clarkNameToEQName);

PHP_METHOD(DocumentBuilder, __destruct);
PHP_METHOD(DocumentBuilder, setLineNumbering);
PHP_METHOD(DocumentBuilder, isLineNumbering);
PHP_METHOD(DocumentBuilder, setSchemaValidator);
PHP_METHOD(DocumentBuilder, getSchemaValidator);
PHP_METHOD(DocumentBuilder, setDTDValidation);
PHP_METHOD(DocumentBuilder, isDTDValidation);
PHP_METHOD(DocumentBuilder, setBaseUri);
PHP_METHOD(DocumentBuilder, getBaseUri);
PHP_METHOD(DocumentBuilder, parseXmlFromString);
PHP_METHOD(DocumentBuilder, parseXmlFromFile);
PHP_METHOD(DocumentBuilder, parseXmlFromUri);
PHP_METHOD(DocumentBuilder, exceptionOccurred);
PHP_METHOD(DocumentBuilder, exceptionClear);
PHP_METHOD(DocumentBuilder, getErrorMessage);
PHP_METHOD(DocumentBuilder, getErrorCode);

PHP_METHOD(Xslt30Processor, __destruct);
PHP_METHOD(Xslt30Processor, transformFileToFile);
PHP_METHOD(Xslt30Processor, transformFileToString);
PHP_METHOD(Xslt30Processor, transformFileToValue);
PHP_METHOD(Xslt30Processor, compileFromFile);
PHP_METHOD(Xslt30Processor, compileFromValue);
PHP_METHOD(Xslt30Processor, compileFromString);
PHP_METHOD(Xslt30Processor, compileFromStringAndSave);
PHP_METHOD(Xslt30Processor, compileFromFileAndSave);
PHP_METHOD(Xslt30Processor, compileFromAssociatedFile);
PHP_METHOD(Xslt30Processor, importPackage);
PHP_METHOD(Xslt30Processor, setJustInTimeCompilation);
PHP_METHOD(Xslt30Processor, setTargetEdition);
PHP_METHOD(Xslt30Processor, setRelocate);
PHP_METHOD(Xslt30Processor, setFastCompilation);
PHP_METHOD(Xslt30Processor, setXsltLanguageVersion);
PHP_METHOD(Xslt30Processor, setParameter);
PHP_METHOD(Xslt30Processor, clearParameters);
PHP_METHOD(Xslt30Processor, exceptionClear);
PHP_METHOD(Xslt30Processor, exceptionOccurred);
PHP_METHOD(Xslt30Processor, getErrorCode);
PHP_METHOD(Xslt30Processor, setcwd);

PHP_METHOD(XsltExecutable, __destruct);
PHP_METHOD(XsltExecutable, callFunctionReturningValue);
PHP_METHOD(XsltExecutable, callFunctionReturningString);
PHP_METHOD(XsltExecutable, callFunctionReturningFile);
PHP_METHOD(XsltExecutable, callTemplateReturningValue);
PHP_METHOD(XsltExecutable, callTemplateReturningString);
PHP_METHOD(XsltExecutable, callTemplateReturningFile);
PHP_METHOD(XsltExecutable, applyTemplatesReturningValue);
PHP_METHOD(XsltExecutable, applyTemplatesReturningString);
PHP_METHOD(XsltExecutable, applyTemplatesReturningFile);
PHP_METHOD(XsltExecutable, clone);
PHP_METHOD(XsltExecutable, transformFileToFile);
PHP_METHOD(XsltExecutable, transformFileToString);
PHP_METHOD(XsltExecutable, transformFileToValue);
PHP_METHOD(XsltExecutable, transformToString);
PHP_METHOD(XsltExecutable, transformToValue);
PHP_METHOD(XsltExecutable, transformToFile);
PHP_METHOD(XsltExecutable, setOutputFile);
PHP_METHOD(XsltExecutable, setResultAsRawValue);
PHP_METHOD(XsltExecutable, setParameter);
PHP_METHOD(XsltExecutable, setBaseOutputURI);
PHP_METHOD(XsltExecutable, setInitialMode);
PHP_METHOD(XsltExecutable, setInitialTemplateParameters);
PHP_METHOD(XsltExecutable, setInitialMatchSelection);
PHP_METHOD(XsltExecutable, setInitialMatchSelectionAsFile);
PHP_METHOD(XsltExecutable, setGlobalContextItem);
PHP_METHOD(XsltExecutable, setGlobalContextFromFile);
PHP_METHOD(XsltExecutable, setcwd);
PHP_METHOD(XsltExecutable, setProperty);
PHP_METHOD(XsltExecutable, clearParameters);
PHP_METHOD(XsltExecutable, clearProperties);
PHP_METHOD(XsltExecutable, exportStylesheet);
PHP_METHOD(XsltExecutable, exceptionClear);
PHP_METHOD(XsltExecutable, exceptionOccurred);
PHP_METHOD(XsltExecutable, checkForException);
PHP_METHOD(XsltExecutable, getErrorCode);
PHP_METHOD(XsltExecutable, getErrorMessage);
PHP_METHOD(XsltExecutable, setSaveXslMessage);
PHP_METHOD(XsltExecutable, getXslMessages);
PHP_METHOD(XsltExecutable, setCaptureResultDocuments);
PHP_METHOD(XsltExecutable, getResultDocuments);

// PHP_METHOD(XQueryProcesor,  __construct);
PHP_METHOD(XQueryProcesor, __destruct);
PHP_METHOD(XQueryProcessor, setQueryContent);
PHP_METHOD(XQueryProcessor, setContextItem);
PHP_METHOD(XQueryProcessor, setContextItemFromFile);
PHP_METHOD(XQueryProcessor, setParameter);
PHP_METHOD(XQueryProcessor, setProperty);
PHP_METHOD(XQueryProcessor, setLanguageVersion);
PHP_METHOD(XQueryProcessor, setStreaming);
PHP_METHOD(XQueryProcessor, isStreaming);
PHP_METHOD(XQueryProcessor, clearParameters);
PHP_METHOD(XQueryProcessor, clearProperties);
// PHP_METHOD(XQueryProcessor, setOutputFile);
PHP_METHOD(XQueryProcessor, runQueryToValue);
PHP_METHOD(XQueryProcessor, runQueryToString);
PHP_METHOD(XQueryProcessor, runQueryToFile);
PHP_METHOD(XQueryProcessor, setQueryFile);
PHP_METHOD(XQueryProcessor, setQueryBaseURI);
PHP_METHOD(XQueryProcessor, declareNamespace);
PHP_METHOD(XQueryProcessor, exceptionClear);
PHP_METHOD(XQueryProcessor, exceptionOccurred);
PHP_METHOD(XQueryProcessor, getErrorCode);
PHP_METHOD(XQueryProcessor, getErrorMessage);

// PHP_METHOD(XPathProcessor,  __construct);
PHP_METHOD(XPathProcessor, __destruct);
PHP_METHOD(XPathProcessor, setContextItem);
PHP_METHOD(XPathProcessor, setContextFile);
PHP_METHOD(XPathProcessor, setBaseURI);
PHP_METHOD(XPathProcessor, effectiveBooleanValue);
PHP_METHOD(XPathProcessor, evaluate);
PHP_METHOD(XPathProcessor, evaluateSingle);
PHP_METHOD(XPathProcessor, declareNamespace);
PHP_METHOD(XPathProcessor, setBackwardsCompatible);
PHP_METHOD(XPathProcessor, convertEnumPolicy);
PHP_METHOD(XPathProcessor, setUnprefixedElementMatchingPolicy);
PHP_METHOD(XPathProcessor, setCaching);
PHP_METHOD(XPathProcessor, setLanguageVersion);
PHP_METHOD(XPathProcessor, importSchemaNamespace);
PHP_METHOD(XPathProcessor, setParameter);
PHP_METHOD(XPathProcessor, setProperty);
PHP_METHOD(XPathProcessor, clearParameters);
PHP_METHOD(XPathProcessor, clearProperties);
PHP_METHOD(XPathProcessor, exceptionClear);
PHP_METHOD(XPathProcessor, exceptionOccurred);
PHP_METHOD(XPathProcessor, getErrorCode);
PHP_METHOD(XPathProcessor, getErrorMessage);

// PHP_METHOD(SchemaValidator,  __construct);
PHP_METHOD(SchemaValidator, __destruct);
PHP_METHOD(SchemaValidator, setSourceNode);
PHP_METHOD(SchemaValidator, setOutputFile);
PHP_METHOD(SchemaValidator, exportSchema);
PHP_METHOD(SchemaValidator, registerSchemaFromFile);
PHP_METHOD(SchemaValidator, registerSchemaFromString);
PHP_METHOD(SchemaValidator, validate);
PHP_METHOD(SchemaValidator, validateToNode);
PHP_METHOD(SchemaValidator, getValidationReport);
PHP_METHOD(SchemaValidator, setLax);
PHP_METHOD(SchemaValidator, registerSchemaFromNode);
PHP_METHOD(SchemaValidator, setParameter);
PHP_METHOD(SchemaValidator, setProperty);
PHP_METHOD(SchemaValidator, clearParameters);
PHP_METHOD(SchemaValidator, clearProperties);
PHP_METHOD(SchemaValidator, exceptionClear);
PHP_METHOD(SchemaValidator, exceptionOccurred);
PHP_METHOD(SchemaValidator, getErrorCode);
PHP_METHOD(SchemaValidator, getErrorMessage);

/*     ============== PHP Interface of   XdmValue =============== */

PHP_METHOD(XdmValue, __construct);
PHP_METHOD(XdmValue, __destruct);
PHP_METHOD(XdmValue, __toString);
PHP_METHOD(XdmValue, getHead);
PHP_METHOD(XdmValue, itemAt);
PHP_METHOD(XdmValue, size);
PHP_METHOD(XdmValue, addXdmItem);

/*     ============== PHP Interface of   XdmItem =============== */

PHP_METHOD(XdmItem, __construct);
PHP_METHOD(XdmItem, __destruct);
PHP_METHOD(XdmItem, __toString);
PHP_METHOD(XdmItem, getStringValue);
PHP_METHOD(XdmItem, isAtomic);
PHP_METHOD(XdmItem, isNode);
PHP_METHOD(XdmItem, getAtomicValue);
PHP_METHOD(XdmItem, getNodeValue);

/*     ============== PHP Interface of   XdmNode =============== */

PHP_METHOD(XdmNode, __construct);
PHP_METHOD(XdmNode, __destruct);
PHP_METHOD(XdmNode, __toString);
PHP_METHOD(XdmNode, getBaseURI);
PHP_METHOD(XdmNode, getStringValue);
PHP_METHOD(XdmNode, getNodeKind);
PHP_METHOD(XdmNode, getLocalName);
PHP_METHOD(XdmNode, getNodeName);
PHP_METHOD(XdmNode, isAtomic);
PHP_METHOD(XdmNode, getChildCount);
PHP_METHOD(XdmNode, getAttributeCount);
PHP_METHOD(XdmNode, getChildNode);
PHP_METHOD(XdmNode, getChildren);
PHP_METHOD(XdmNode, axisNodes);
PHP_METHOD(XdmNode, getParent);
PHP_METHOD(XdmNode, getAttributeNode);
PHP_METHOD(XdmNode, getAttributeNodes);
PHP_METHOD(XdmNode, getAttributeValue);
PHP_METHOD(XdmNode, getTypedValue);

/*     ============== PHP Interface of   XdmAtomicValue =============== */

PHP_METHOD(XdmAtomicValue, __construct);
PHP_METHOD(XdmAtomicValue, __destruct);
PHP_METHOD(XdmAtomicValue, __toString);
PHP_METHOD(XdmAtomicValue, getStringValue);
PHP_METHOD(XdmAtomicValue, getBooleanValue);
PHP_METHOD(XdmAtomicValue, getDoubleValue);
PHP_METHOD(XdmAtomicValue, getLongValue);
PHP_METHOD(XdmAtomicValue, getPrimitiveTypeName);
PHP_METHOD(XdmAtomicValue, isAtomic);

/*     ============== PHP Interface of   XdmFunctionItem =============== */
PHP_METHOD(XdmFunctionItem, __construct);
PHP_METHOD(XdmFunctionItem, __destruct);
PHP_METHOD(XdmFunctionItem, getName);
PHP_METHOD(XdmFunctionItem, getArity);
PHP_METHOD(XdmFunctionItem, getSystemFunction);
PHP_METHOD(XdmFunctionItem, call);

/*     ============== PHP Interface of   XdmMap =============== */

PHP_METHOD(XdmMap, __construct);
PHP_METHOD(XdmMap, __destruct);
PHP_METHOD(XdmMap, mapSize);
PHP_METHOD(XdmMap, get);
PHP_METHOD(XdmMap, put);
PHP_METHOD(XdmMap, remove);
PHP_METHOD(XdmMap, isEmpty);
PHP_METHOD(XdmMap, containsKey);
PHP_METHOD(XdmMap, keys);
// PHP_METHOD(XdmMap,  asMap);
// PHP_METHOD(XdmMap,  values);

/*     ============== PHP Interface of   XdmArray =============== */

PHP_METHOD(XdmArray, __construct);
PHP_METHOD(XdmArray, __destruct);
PHP_METHOD(XdmArray, get);
PHP_METHOD(XdmArray, put);
PHP_METHOD(XdmArray, addMember);
PHP_METHOD(XdmArray, concat);
// PHP_METHOD(XdmArray,  values);
PHP_METHOD(XdmArray, getArity);
PHP_METHOD(XdmArray, arrayLength);

#endif /* PHP_SAXON_H */
