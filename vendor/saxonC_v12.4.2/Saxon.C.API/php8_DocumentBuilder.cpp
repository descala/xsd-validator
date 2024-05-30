//#include "php_DocumentBuilder.h"

zend_object_handlers documentBuilder_object_handlers;
zend_class_entry *documentBuilder_ce;

/*     ============== XSLT30: PHP Interface of  DocumentBuilder class
 * =============== */

void DocumentBuilder_free_storage(zend_object *object) {

  zend_object_std_dtor(object);
}

void DocumentBuilder_destroy_storage(zend_object *object) {
  documentBuilder_object *obj;

  zend_objects_destroy_object(object);
}

zend_object *documentBuilder_create_handler(zend_class_entry *type) {
  documentBuilder_object *obj = (documentBuilder_object *)ecalloc(
      1, sizeof(documentBuilder_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std, type);
  object_properties_init(&obj->std, type);

  obj->std.handlers = &documentBuilder_object_handlers;

  return &obj->std;
}

PHP_METHOD(DocumentBuilder, __destruct) {
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));

  DocumentBuilder *documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    delete documentBuilder;
  }
}

PHP_METHOD(DocumentBuilder, setLineNumbering) {
  DocumentBuilder *documentBuilder;
  bool isLineNo = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &isLineNo) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    documentBuilder->setLineNumbering(isLineNo);
  }
}

PHP_METHOD(DocumentBuilder, isLineNumbering) {
  DocumentBuilder *documentBuilder;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    if (documentBuilder->isLineNumbering()) {
      RETURN_TRUE;
    }
  }
  RETURN_FALSE;
}

PHP_METHOD(DocumentBuilder, setSchemaValidator) {
  DocumentBuilder *documentBuilder;

  zval *oth;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &oth) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    zend_object *ooth = Z_OBJ_P(oth);
    schemaValidator_object *vobj =
        (schemaValidator_object *)((char *)ooth -
                                   XtOffsetOf(schemaValidator_object, std));
    if (vobj != NULL) {
      SchemaValidator *schemaValidator1 = vobj->schemaValidator;
      if (schemaValidator1 != NULL) {
        documentBuilder->setSchemaValidator(schemaValidator1);
      }
    }
  }
}

PHP_METHOD(DocumentBuilder, getSchemaValidator) {
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  DocumentBuilder *documentBuilder;
  SchemaValidator *schemaValidator = nullptr;

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  assert(obj != nullptr);
  documentBuilder = obj->documentBuilder;
  assert(documentBuilder != nullptr);
  if (documentBuilder != nullptr) {
    if (object_init_ex(return_value, schemaValidator_ce) != SUCCESS) {
      RETURN_NULL();
    } else {

      zend_object *vvobj = Z_OBJ_P(return_value);
      schemaValidator_object *vobj =
          (schemaValidator_object *)((char *)vvobj -
                                     XtOffsetOf(schemaValidator_object, std));
      assert(vobj != nullptr);
      schemaValidator = documentBuilder->getSchemaValidator();
      if (schemaValidator == nullptr) {
        RETURN_NULL();
      }
      vobj->schemaValidator = schemaValidator;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(DocumentBuilder, setDTDValidation) {
  DocumentBuilder *documentBuilder;
  bool dtd = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &dtd) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    documentBuilder->setDTDValidation(dtd);
  }
}

PHP_METHOD(DocumentBuilder, isDTDValidation) {
  DocumentBuilder *documentBuilder;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    if (documentBuilder->isDTDValidation()) {
      RETURN_TRUE;
    }
  }
  RETURN_FALSE;
}

PHP_METHOD(DocumentBuilder, setBaseUri) {
  DocumentBuilder *documentBuilder;
  char *baseUri;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &baseUri, &len1) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    documentBuilder->setBaseUri(baseUri);
  }
}

PHP_METHOD(DocumentBuilder, getBaseUri) {
  DocumentBuilder *documentBuilder;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {
    const char *baseUri = documentBuilder->getBaseUri();
    if (baseUri != nullptr) {
      RETURN_STRING(baseUri);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(DocumentBuilder, parseXmlFromString) {
  DocumentBuilder *documentBuilder;
  char *encoding = nullptr;
  char *source;
  size_t len1, len2;

  if (ZEND_NUM_ARGS() > 2) {
    WRONG_PARAM_COUNT;
  }

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &source, &len1,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  assert(obj != nullptr);
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {

    XdmNode *node = documentBuilder->parseXmlFromString(source, encoding);
    if (node != nullptr) {
      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        node->incrementRefCount();
        zend_object *vobj = Z_OBJ_P(return_value);
        xdmNode_object *xdmNObj =
            (xdmNode_object *)((char *)vobj - XtOffsetOf(xdmNode_object, std));
        assert(xdmNObj != nullptr);

        xdmNObj->xdmNode = node;
      }
    } else {
      if (documentBuilder->exceptionOccurred()) {
        SaxonApiException *exception = documentBuilder->getException();
        if (exception != nullptr) {
          zend_throw_exception(zend_ce_exception, exception->getMessage(), 0);
        }
      }
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(DocumentBuilder, parseXmlFromFile) {
  DocumentBuilder *documentBuilder;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() > 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  assert(obj != nullptr);
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr && source != nullptr) {

    XdmNode *node = documentBuilder->parseXmlFromFile(source);
    if (node != nullptr) {
      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        node->incrementRefCount();
        zend_object *vobj = Z_OBJ_P(return_value);
        xdmNode_object *xdmNObj =
            (xdmNode_object *)((char *)vobj - XtOffsetOf(xdmNode_object, std));
        assert(xdmNObj != nullptr);

        xdmNObj->xdmNode = node;
      }
    } else {
      if (documentBuilder->exceptionOccurred()) {
        SaxonApiException *exception = documentBuilder->getException();
        if (exception != nullptr) {
          zend_throw_exception(zend_ce_exception, exception->getMessage(), 0);
        }
      }
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(DocumentBuilder, parseXmlFromUri) {
  DocumentBuilder *documentBuilder;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() > 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  assert(obj != nullptr);
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != nullptr) {

    XdmNode *node = documentBuilder->parseXmlFromUri(source);
    if (node != nullptr) {
      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        node->incrementRefCount();
        zend_object *vobj = Z_OBJ_P(return_value);
        xdmNode_object *xdmNObj =
            (xdmNode_object *)((char *)vobj - XtOffsetOf(xdmNode_object, std));
        assert(xdmNObj != nullptr);

        xdmNObj->xdmNode = node;
      }
    } else {
      if (documentBuilder->exceptionOccurred()) {
        SaxonApiException *exception = documentBuilder->getException();
        if (exception != nullptr) {
          zend_throw_exception(zend_ce_exception, exception->getMessage(), 0);
        }
      }
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(DocumentBuilder, exceptionOccurred) {
  DocumentBuilder *documentBuilder;
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  documentBuilder = obj->documentBuilder;
  if (documentBuilder != NULL) {
    bool result = documentBuilder->exceptionOccurred();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(DocumentBuilder, getErrorCode) {
  DocumentBuilder *documentBuilder;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != NULL) {
    const char *errCode = documentBuilder->getErrorCode();
    if (errCode != NULL) {
      // char *str = estrdup(errCode);
      RETURN_STRING(errCode);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(DocumentBuilder, getErrorMessage) {
  DocumentBuilder *documentBuilder;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != NULL) {
    const char *errStr = documentBuilder->getErrorMessage();
    if (errStr != NULL) {
      // char *str = estrdup(errStr);
      RETURN_STRING(errStr);
    }
  }
  RETURN_NULL();
}
PHP_METHOD(DocumentBuilder, exceptionClear) {
  DocumentBuilder *documentBuilder;
  zend_object *pobj = Z_OBJ_P(getThis());
  documentBuilder_object *obj =
      (documentBuilder_object *)((char *)pobj -
                                 XtOffsetOf(documentBuilder_object, std));
  documentBuilder = obj->documentBuilder;
  if (documentBuilder != NULL) {
    documentBuilder->exceptionClear();
  }
}

// =============================================================

zend_function_entry DocumentBuilder_methods[] = {
    PHP_ME(DocumentBuilder, __destruct, arginfo_saxonc_docbuilder_destruct,
           ZEND_ACC_PUBLIC) PHP_ME(DocumentBuilder, setLineNumbering,
                                   arginfo_saxonc_docbuilder_setLineNumbering,
                                   ZEND_ACC_PUBLIC)
        PHP_ME(
            DocumentBuilder, isLineNumbering,
            arginfo_saxonc_docbuilder_isLineNumbering,
            ZEND_ACC_PUBLIC) PHP_ME(DocumentBuilder, setSchemaValidator,
                                    arginfo_saxonc_docbuilder_setSchemaValidator,
                                    ZEND_ACC_PUBLIC)
            PHP_ME(
                DocumentBuilder, getSchemaValidator,
                arginfo_saxonc_docbuilder_getSchemaValidator,
                ZEND_ACC_PUBLIC) PHP_ME(DocumentBuilder, setDTDValidation,
                                        arginfo_saxonc_docbuilder_setDTDValidation,
                                        ZEND_ACC_PUBLIC)
                PHP_ME(
                    DocumentBuilder, isDTDValidation,
                    arginfo_saxonc_docbuilder_isDTDValidation,
                    ZEND_ACC_PUBLIC) PHP_ME(DocumentBuilder, setBaseUri,
                                            arginfo_saxonc_docbuilder_setBaseUri,
                                            ZEND_ACC_PUBLIC)
                    PHP_ME(
                        DocumentBuilder, getBaseUri,
                        arginfo_saxonc_docbuilder_getBaseUri,
                        ZEND_ACC_PUBLIC) PHP_ME(DocumentBuilder,
                                                parseXmlFromString,
                                                arginfo_saxonc_docbuilder_parseXmlFromString,
                                                ZEND_ACC_PUBLIC)
                        PHP_ME(DocumentBuilder, parseXmlFromFile,
                               arginfo_saxonc_docbuilder_parseXmlFromFile,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(DocumentBuilder, parseXmlFromUri,
                                   arginfo_saxonc_docbuilder_parseXmlFromUri,
                                   ZEND_ACC_PUBLIC)
                                PHP_ME(
                                    DocumentBuilder, exceptionOccurred,
                                    arginfo_saxonc_docbuilder_exceptionOccurred,
                                    ZEND_ACC_PUBLIC)
                                    PHP_ME(
                                        DocumentBuilder, exceptionClear,
                                        arginfo_saxonc_docbuilder_exceptionClear,
                                        ZEND_ACC_PUBLIC)
                                        PHP_ME(
                                            DocumentBuilder, getErrorMessage,
                                            arginfo_saxonc_docbuilder_getErrorMessage,
                                            ZEND_ACC_PUBLIC)
                                            PHP_ME(
                                                DocumentBuilder, getErrorCode,
                                                arginfo_saxonc_docbuilder_getErrorCode,
                                                ZEND_ACC_PUBLIC){
                                                nullptr, nullptr, nullptr}};
