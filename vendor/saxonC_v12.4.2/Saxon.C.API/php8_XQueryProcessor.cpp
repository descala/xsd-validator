
zend_object_handlers xqueryProcessor_object_handlers;
zend_class_entry *xqueryProcessor_ce;

/*     ============== XQuery10/30/31: PHP Interface of   XQueryProcessor
 * =============== */

void xqueryProcessor_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

void xqueryProcessor_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

zend_object *xqueryProcessor_create_handler(zend_class_entry *type) {

  xqueryProcessor_object *obj = (xqueryProcessor_object *)ecalloc(
      1, sizeof(xqueryProcessor_object) + zend_object_properties_size(type));
  zend_object_std_init(&obj->std, type);
  object_properties_init(&obj->std, type);
  obj->std.handlers = &xqueryProcessor_object_handlers;

  return &obj->std;
}

PHP_METHOD(XQueryProcessor, __destruct) {
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  XQueryProcessor *xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    delete xqueryProcessor;
  }
}

PHP_METHOD(XQueryProcessor, runQueryToValue) {
  XQueryProcessor *xqueryProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  xqueryProcessor = obj->xqueryProcessor;

  if (xqueryProcessor != nullptr) {
    try {
      XdmValue *node = xqueryProcessor->runQueryToValue();
      if (node != nullptr) {
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
          return;
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmValue_object *vobj =
              (xdmValue_object *)((char *)vvobj -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = node;
          return;
        }
      }
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XQueryProcessor, runQueryToString) {
  XQueryProcessor *xqueryProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;

  if (xqueryProcessor != nullptr) {
    try {
      const char *result = xqueryProcessor->runQueryToString();
      RETVAL_STRING(result);
      SaxonProcessor::deleteString(result);
      return;

    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XQueryProcessor, runQueryToFile) {

  char *ofilename;
  size_t len1 = 0;
  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &ofilename, &len1) ==
      FAILURE) {
    RETURN_NULL();
  }
  XQueryProcessor *xqueryProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));

  xqueryProcessor = obj->xqueryProcessor;

  if (xqueryProcessor != nullptr) {
    if (ofilename != nullptr) {
      xqueryProcessor->setOutputFile(ofilename);
    }
    try {
      xqueryProcessor->runQueryToFile();
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(XQueryProcessor, setQueryContent) {
  char *queryStr;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &queryStr, &len1) ==
      FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  if (queryStr != nullptr) {
    obj->xqueryProcessor->setProperty("qs", queryStr);
  }
}

PHP_METHOD(XQueryProcessor, setQueryFile) {
  char *fileName;
  size_t len1;
  XQueryProcessor *xqueryProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &fileName, &len1) ==
      FAILURE) {
    RETURN_NULL();
  }
  if (len1 > 0) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xqueryProcessor_object *obj =
        (xqueryProcessor_object *)((char *)pobj -
                                   XtOffsetOf(xqueryProcessor_object, std));
    xqueryProcessor = obj->xqueryProcessor;
    xqueryProcessor->setQueryFile(fileName);
  }
}

PHP_METHOD(XQueryProcessor, setQueryBaseURI) {
  char *base;
  size_t len1;
  XQueryProcessor *xqueryProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &base, &len1) == FAILURE) {
    RETURN_NULL();
  }
  if (len1 > 0) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xqueryProcessor_object *obj =
        (xqueryProcessor_object *)((char *)pobj -
                                   XtOffsetOf(xqueryProcessor_object, std));
    xqueryProcessor = obj->xqueryProcessor;
    xqueryProcessor->setQueryBaseURI(base);
  }
}

PHP_METHOD(XQueryProcessor, declareNamespace) {
  char *prefix;
  char *ns;
  size_t len1, len2;
  XQueryProcessor *xqueryProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &prefix, &len1, &ns,
                            &len2) == FAILURE) {
    RETURN_NULL();
  }
  if (len1 > 0 && len2 > 0) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xqueryProcessor_object *obj =
        (xqueryProcessor_object *)((char *)pobj -
                                   XtOffsetOf(xqueryProcessor_object, std));
    xqueryProcessor = obj->xqueryProcessor;
    try {
      xqueryProcessor->declareNamespace(prefix, ns);
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(XQueryProcessor, setStreaming) {
  XQueryProcessor *xqueryProcessor;
  bool isStreaming = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &isStreaming) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    xqueryProcessor->setStreaming(isStreaming);
  }
}

PHP_METHOD(XQueryProcessor, isStreaming) {
  XQueryProcessor *xqueryProcessor;
  char *xpathStr;
  zval *oth;
  size_t len1, myint;
  if (ZEND_NUM_ARGS() != 0) {
    RETURN_BOOL(false);
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {

    bool result = xqueryProcessor->isStreaming();
    RETURN_BOOL(result);
  }
}

PHP_METHOD(XQueryProcessor, setContextItem) {
  char *context;
  int len1;
  zval *oth;
  XQueryProcessor *xqueryProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &oth) == FAILURE) {
    RETURN_NULL();
  }
  if (oth != nullptr) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xqueryProcessor_object *obj =
        (xqueryProcessor_object *)((char *)pobj -
                                   XtOffsetOf(xqueryProcessor_object, std));
    xqueryProcessor = obj->xqueryProcessor;
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);

    if (strcmp(objName, "Saxon\\XdmNode") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmNode_object *ooth =
          (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));
      // xdmNode_object* ooth = (xdmNode_object*)Z_OBJ_P(oth TSRMLS_CC);
      if (ooth != nullptr) {
        XdmNode *value = ooth->xdmNode;
        if (value != nullptr) {
          xqueryProcessor->setContextItem((XdmItem *)value);

          return;
        }
      }
    } else if (strcmp(objName, "Saxon\\XdmItem") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmItem_object *ooth =
          (xdmItem_object *)((char *)vvobj - XtOffsetOf(xdmItem_object, std));
      if (ooth != nullptr) {
        XdmItem *value = ooth->xdmItem;
        if (value != nullptr) {
          xqueryProcessor->setContextItem(value);

          return;
        }
      }

    } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmAtomicValue_object *ooth =
          (xdmAtomicValue_object *)((char *)vvobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      if (ooth != nullptr) {
        XdmAtomicValue *value = ooth->xdmAtomicValue;
        if (value != nullptr) {

          xqueryProcessor->setContextItem((XdmItem *)value);

          return;
        }
      }
    }
  }
  // throw exception
}

PHP_METHOD(XQueryProcessor, setContextItemFromFile) {
  char *cfilename;
  size_t len1;
  XQueryProcessor *xqueryProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &cfilename, &len1) ==
      FAILURE) {
    RETURN_NULL();
  }
  if (cfilename != nullptr) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xqueryProcessor_object *obj =
        (xqueryProcessor_object *)((char *)pobj -
                                   XtOffsetOf(xqueryProcessor_object, std));
    xqueryProcessor = obj->xqueryProcessor;
    xqueryProcessor->setContextItemFromFile(cfilename);
  }
}

PHP_METHOD(XQueryProcessor, setProperty) {
  XQueryProcessor *xqueryProcessor;
  char *name;
  char *value;
  size_t len1, len2, myint;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &name, &len1, &value,
                            &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    xqueryProcessor->setProperty(name, value);
  }
}

PHP_METHOD(XQueryProcessor, setParameter) {

  XQueryProcessor *xqueryProcessor;
  char *name;
  zval *oth;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &name, &len2, &oth) ==
      FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    if (Z_TYPE_P(oth) == IS_NULL) {
      php_error(E_WARNING, "Error setting source value - value is nullptr");
      return;
    }
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);
    // std::cout<<"test type:"<<(Z_OBJCE_P(oth)->name)<<std::endl;
    // Z_ADDREF_P(oth);
    if (strcmp(objName, "Saxon\\XdmNode") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmNode_object *ooth =
          (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));
      if (ooth != nullptr) {
        XdmNode *value = ooth->xdmNode;
        if (value != nullptr) {
          xqueryProcessor->setParameter(name, (XdmValue *)value);
        }
      }
    } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmValue_object *ooth =
          (xdmValue_object *)((char *)vvobj - XtOffsetOf(xdmValue_object, std));
      if (ooth != nullptr) {
        XdmValue *value = ooth->xdmValue;
        if (value != nullptr) {

          xqueryProcessor->setParameter(name, value);
        }
      }

    } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmAtomicValue_object *ooth =
          (xdmAtomicValue_object *)((char *)vvobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      if (ooth != nullptr) {
        XdmAtomicValue *value = ooth->xdmAtomicValue;
        if (value != nullptr) {

          xqueryProcessor->setParameter(name, (XdmValue *)value);
        }
      }
    }
  }
}

PHP_METHOD(XQueryProcessor, setLanguageVersion) {
  XQueryProcessor *xqueryProcessor;
  char *str;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &str, &str) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {

    if (str != nullptr) {
      xqueryProcessor->setLanguageVersion(str);
    }
  }
}

PHP_METHOD(XQueryProcessor, clearParameters) {
  XQueryProcessor *xqueryProcessor;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    xqueryProcessor->clearParameters();
  }
}

PHP_METHOD(XQueryProcessor, clearProperties) {
  XQueryProcessor *xqueryProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    xqueryProcessor->clearProperties();
  }
}

PHP_METHOD(XQueryProcessor, exceptionOccurred) {
  XQueryProcessor *xqueryProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    bool result = xqueryProcessor->exceptionOccurred();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(XQueryProcessor, getErrorCode) {
  XQueryProcessor *xqueryProcessor;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    const char *errCode = xqueryProcessor->getErrorCode();
    if (errCode != nullptr) {
      // char *str = estrdup(errCode);
      RETURN_STRING(errCode);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XQueryProcessor, getErrorMessage) {
  XQueryProcessor *xqueryProcessor;
  long index;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &index) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    const char *errStr = xqueryProcessor->getErrorMessage();
    if (errStr != nullptr) {
      // char *str = estrdup(errStr);
      RETURN_STRING(errStr);
    }
  }
  RETURN_NULL();
}
PHP_METHOD(XQueryProcessor, exceptionClear) {
  XQueryProcessor *xqueryProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xqueryProcessor_object *obj =
      (xqueryProcessor_object *)((char *)pobj -
                                 XtOffsetOf(xqueryProcessor_object, std));
  xqueryProcessor = obj->xqueryProcessor;
  if (xqueryProcessor != nullptr) {
    xqueryProcessor->exceptionClear();
  }
}

zend_function_entry XQueryProcessor_methods[] = {
    PHP_ME(XQueryProcessor, __destruct, arginfo_saxonc_XQueryProcessor_destruct,
           ZEND_ACC_PUBLIC)
    // PHP_ME(XQueryProcessor,  getErrorCode,
    // arginfo_saxonc_XQueryProcessor_getErrorCode, ZEND_ACC_PUBLIC)
    PHP_ME(
        XQueryProcessor, setQueryContent,
        arginfo_saxonc_XQueryProcessor_setQueryContent,
        ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor, setStreaming,
                                arginfo_saxonc_XQueryProcessor_setStreaming,
                                ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor,
                                                        isStreaming,
                                                        arginfo_saxonc_XQueryProcessor_isStreaming,
                                                        ZEND_ACC_PUBLIC)
        PHP_ME(
            XQueryProcessor, setLanguageVersion,
            arginfo_saxonc_XQueryProcessor_setLanguageVersion,
            ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor, setContextItem,
                                    arginfo_saxonc_XQueryProcessor_setContextItem,
                                    ZEND_ACC_PUBLIC)
            PHP_ME(
                XQueryProcessor, setContextItemFromFile,
                arginfo_saxonc_XQueryProcessor_setContextItemFromFile,
                ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor, setParameter,
                                        arginfo_saxonc_XQueryProcessor_setParameter,
                                        ZEND_ACC_PUBLIC)
                PHP_ME(
                    XQueryProcessor, setProperty,
                    arginfo_saxonc_XQueryProcessor_setProperty,
                    ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor, clearParameters,
                                            arginfo_saxonc_XQueryProcessor_clearParameters,
                                            ZEND_ACC_PUBLIC)
                    PHP_ME(
                        XQueryProcessor, clearProperties,
                        arginfo_saxonc_XQueryProcessor_clearProperties,
                        ZEND_ACC_PUBLIC) PHP_ME(XQueryProcessor,
                                                runQueryToValue,
                                                arginfo_saxonc_XQueryProcessor_runQueryToValue,
                                                ZEND_ACC_PUBLIC)
                        PHP_ME(XQueryProcessor, runQueryToString,
                               arginfo_saxonc_XQueryProcessor_runQueryToString,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(
                                XQueryProcessor, runQueryToFile,
                                arginfo_saxonc_XQueryProcessor_runQueryToFile,
                                ZEND_ACC_PUBLIC)
                                PHP_ME(
                                    XQueryProcessor, setQueryFile,
                                    arginfo_saxonc_XQueryProcessor_setQueryFile,
                                    ZEND_ACC_PUBLIC)
                                    PHP_ME(
                                        XQueryProcessor, setQueryBaseURI,
                                        arginfo_saxonc_XQueryProcessor_setQueryBaseURI,
                                        ZEND_ACC_PUBLIC)
                                        PHP_ME(
                                            XQueryProcessor, declareNamespace,
                                            arginfo_saxonc_XQueryProcessor_declareNamespace,
                                            ZEND_ACC_PUBLIC)
                                            PHP_ME(
                                                XQueryProcessor,
                                                exceptionOccurred,
                                                arginfo_saxonc_XQueryProcessor_exceptionOccurred,
                                                ZEND_ACC_PUBLIC)
                                                PHP_ME(
                                                    XQueryProcessor,
                                                    exceptionClear,
                                                    arginfo_saxonc_XQueryProcessor_exceptionClear,
                                                    ZEND_ACC_PUBLIC)
                                                    PHP_ME(
                                                        XQueryProcessor,
                                                        getErrorCode,
                                                        arginfo_saxonc_XQueryProcessor_getErrorCode,
                                                        ZEND_ACC_PUBLIC)
                                                        PHP_ME(
                                                            XQueryProcessor,
                                                            getErrorMessage,
                                                            arginfo_saxonc_XQueryProcessor_getErrorMessage,
                                                            ZEND_ACC_PUBLIC){
                                                            nullptr, nullptr,
                                                            nullptr}};
