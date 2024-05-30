#include <fstream>
#include <iostream>

/*     ============== PHP Interface of XPath2.0/3.0  XPathProcessor
 * =============== */

zend_object_handlers xpathProcessor_object_handlers;

zend_class_entry *xpathProcessor_ce;

void xpathProcessor_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

void xpathProcessor_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

PHP_METHOD(XPathProcessor, __destruct) {

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));

  XPathProcessor *xpathProc = obj->xpathProcessor;
  if (xpathProc != nullptr) {
    delete xpathProc;
  }
}

zend_object *xpathProcessor_create_handler(zend_class_entry *type) {
  xpathProcessor_object *obj = (xpathProcessor_object *)ecalloc(
      1, sizeof(xpathProcessor_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std, type);

  object_properties_init(&obj->std, type);

  obj->std.handlers = &xpathProcessor_object_handlers;

  return &obj->std;
}

PHP_METHOD(XPathProcessor, setProperty) {
  XPathProcessor *xpathProcessor;
  char *name;
  char *value;
  size_t len1, len2;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &name, &len1, &value,
                            &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->setProperty(name, value);
  }
}

PHP_METHOD(XPathProcessor, setParameter) {

  XPathProcessor *xpathProcessor;
  char *name;
  zval *oth;
  size_t len1, len2;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &name, &len2, &oth) ==
      FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);
    // std::cout<<"test type:"<<(Z_OBJCE_P(oth)->name)<<std::endl;

    if (strcmp(objName, "Saxon\\XdmNode") == 0) {

      zend_object *vvobj = Z_OBJ_P(oth);
      xdmNode_object *ooth =
          (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));
      if (ooth != nullptr) {
        XdmNode *value = ooth->xdmNode;
        value->incrementRefCount();
        if (value != nullptr) {
          xpathProcessor->setParameter(name, (XdmValue *)value);
        }
      }
    } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {

      zend_object *vvobj = Z_OBJ_P(oth);
      xdmValue_object *ooth =
          (xdmValue_object *)((char *)vvobj - XtOffsetOf(xdmValue_object, std));
      if (ooth != nullptr) {
        XdmValue *value = ooth->xdmValue;
        value->incrementRefCount();
        if (value != nullptr) {

          xpathProcessor->setParameter(name, value);
        }
      }

    } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {

      zend_object *vvobj = Z_OBJ_P(oth);
      xdmAtomicValue_object *ooth =
          (xdmAtomicValue_object *)((char *)vvobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      if (ooth != nullptr) {
        XdmAtomicValue *value = ooth->xdmAtomicValue;
        value->incrementRefCount();
        if (value != nullptr) {
          xpathProcessor->setParameter(name, (XdmValue *)value);
        }
      }
    }
  }
}

PHP_METHOD(XPathProcessor, declareNamespace) {

  const char *prefixi = NULL;
  const char *ns = NULL;
  size_t len1, len2;
  XPathProcessor *xpathProcessor = nullptr;

  if (ZEND_NUM_ARGS() != 2) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &prefixi, &len1, &ns,
                            &len2) == FAILURE) {
    RETURN_NULL();
  }

  if (prefixi != NULL && ns != NULL) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xpathProcessor_object *obj =
        (xpathProcessor_object *)((char *)pobj -
                                  XtOffsetOf(xpathProcessor_object, std));

    xpathProcessor = obj->xpathProcessor;
    if (xpathProcessor != nullptr) {
      try {
        xpathProcessor->declareNamespace((len1 == 0 ? "" : prefixi),
                                         (len2 == 0 ? "" : ns));
      } catch (SaxonApiException &e) {
        zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
      }
    }
  }
}

PHP_METHOD(XPathProcessor, setBackwardsCompatible) {

  XPathProcessor *xpathProcessor;
  bool allow = false;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &allow) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->setBackwardsCompatible(allow);
  }
}

PHP_METHOD(XPathProcessor, setCaching) {
  XPathProcessor *xpathProcessor;
  bool isCaching = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &isCaching) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->setCaching(isCaching);
  }
}

PHP_METHOD(XPathProcessor, setLanguageVersion) {
  XPathProcessor *xpathProcessor;
  char *str;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &str, &str) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {

    if (str != nullptr) {
      xpathProcessor->setLanguageVersion(str);
    }
  }
}

PHP_METHOD(XPathProcessor, importSchemaNamespace) {
  char *name;
  size_t len1;
  XPathProcessor *xpathProcessor;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &name, &len1) == FAILURE) {
    RETURN_NULL();
  }
  if (name != nullptr) {
    zend_object *pobj = Z_OBJ_P(getThis());
    xpathProcessor_object *obj =
        (xpathProcessor_object *)((char *)pobj -
                                  XtOffsetOf(xpathProcessor_object, std));
    xpathProcessor = obj->xpathProcessor;
    xpathProcessor->importSchemaNamespace(name);
  }
}

PHP_METHOD(XPathProcessor, setUnprefixedElementMatchingPolicy) {
  long policy;
  XPathProcessor *xpathProcessor;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &policy) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->setUnprefixedElementMatchingPolicy(
        xpathProcessor->convertEnumPolicy((int)policy));
  }
}

PHP_METHOD(XPathProcessor, effectiveBooleanValue) {

  XPathProcessor *xpathProcessor;
  char *xpathStr;
  char *encoding = nullptr;
  zval *oth;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &xpathStr, &len1) ==
      FAILURE) {
    RETURN_BOOL(false);
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &xpathStr, &len1,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr && xpathStr != nullptr) {
    try {
      bool result = xpathProcessor->effectiveBooleanValue(xpathStr, encoding);
      RETURN_BOOL(result);
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(XPathProcessor, evaluate) {

  XPathProcessor *xpathProcessor;
  char *xpathStr;
  char *encoding = nullptr;
  zval *oth;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &xpathStr, &len1) ==
      FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &xpathStr, &len1,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr && xpathStr != nullptr) {
    try {
      XdmValue *node = xpathProcessor->evaluate(xpathStr, encoding);
      if (node != nullptr) {
        node->incrementRefCount();
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
          return;
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);

          if (node->getType() == XDM_NODE) {
            xdmNode_object *vobj =
                (xdmNode_object *)((char *)vvobj -
                                   XtOffsetOf(xdmNode_object, std));
            assert(vobj != nullptr);
            vobj->xdmNode = (XdmNode *)node;
            return;
          } else if (node->getType() == XDM_ATOMIC_VALUE) {
            xdmAtomicValue_object *vobj =
                (xdmAtomicValue_object *)((char *)vvobj -
                                          XtOffsetOf(xdmAtomicValue_object,
                                                     std));
            assert(vobj != nullptr);
            vobj->xdmAtomicValue = (XdmAtomicValue *)node;
            return;
          } else {
            xdmValue_object *vobj =
                (xdmValue_object *)((char *)vvobj -
                                    XtOffsetOf(xdmValue_object, std));
            assert(vobj != nullptr);
            vobj->xdmValue = node;
            return;
          }
        }
      }
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XPathProcessor, evaluateSingle) {
  XPathProcessor *xpathProcessor;
  char *xpathStr;
  char *encoding = nullptr;
  zval *oth;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &xpathStr, &len1) ==
      FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &xpathStr, &len1,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;

  if (xpathStr == nullptr) {
    RETURN_NULL();
    return;
  }

  if (xpathProcessor != nullptr) {
    try {
      XdmItem *node = xpathProcessor->evaluateSingle(xpathStr, encoding);
      if (node != nullptr) {
        node->incrementRefCount();
        if (object_init_ex(return_value, xdmItem_ce) != SUCCESS) {
          RETURN_NULL();
          return;
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmItem_object *vobj =
              (xdmItem_object *)((char *)vvobj -
                                 XtOffsetOf(xdmItem_object, std));
          assert(vobj != nullptr);
          vobj->xdmItem = node;
          return;
        }
      }

    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XPathProcessor, setContextItem) {

  XPathProcessor *xpathProcessor = nullptr;

  zval *oth = nullptr;
  // TODO this should be relaxed to accept item/atomic/node as well as Value

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &oth) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    if (Z_TYPE_P(oth) == IS_NULL) {
      xpathProcessor->setContextItem(nullptr);
      return;
    }
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);

    if (strcmp(objName, "Saxon\\XdmNode") == 0) {
      zend_object *vvobj = Z_OBJ_P(oth);
      xdmNode_object *ooth =
          (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));
      if (ooth != nullptr) {
        XdmNode *value = ooth->xdmNode;
        if (value != nullptr) {
          xpathProcessor->setContextItem((XdmItem *)value);
          value->incrementRefCount();
        }
      } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
        zend_object *vvobj = Z_OBJ_P(oth);
        xdmAtomicValue_object *ooth =
            (xdmAtomicValue_object *)((char *)vvobj -
                                      XtOffsetOf(xdmAtomicValue_object, std));
        if (ooth != nullptr) {
          XdmAtomicValue *value = ooth->xdmAtomicValue;
          if (value != nullptr) {

            xpathProcessor->setContextItem((XdmItem *)value);
            value->incrementRefCount();
          }
        }
      } else if (strcmp(objName, "Saxon\\XdmItem") == 0) {
        zend_object *vvobj = Z_OBJ_P(oth);
        xdmItem_object *ooth =
            (xdmItem_object *)((char *)vvobj - XtOffsetOf(xdmItem_object, std));
        if (ooth != nullptr) {
          XdmItem *value = ooth->xdmItem;
          if (value != nullptr) {

            xpathProcessor->setContextItem(value);
            value->incrementRefCount();
          }
        }
      }
    }
  }
}

PHP_METHOD(XPathProcessor, setBaseURI) {

  XPathProcessor *xpathProcessor;

  char *uriStr;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &uriStr, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {

    if (uriStr != nullptr) {

      xpathProcessor->setBaseURI(uriStr);
    }
  }
}

PHP_METHOD(XPathProcessor, setContextFile) {

  XPathProcessor *xpathProcessor;
  char *name;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &name, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {

    if (name != nullptr) {

      xpathProcessor->setContextFile(name);
    }
  }
}

PHP_METHOD(XPathProcessor, clearParameters) {
  XPathProcessor *xpathProcessor;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->clearParameters();
  }
}

PHP_METHOD(XPathProcessor, clearProperties) {
  XPathProcessor *xpathProcessor;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->clearProperties();
  }
}

PHP_METHOD(XPathProcessor, exceptionOccurred) {
  XPathProcessor *xpathProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    bool result = xpathProcessor->exceptionOccurred();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(XPathProcessor, getErrorCode) {
  XPathProcessor *xpathProcessor;
  long index;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    const char *errCode = xpathProcessor->getErrorCode();
    if (errCode != nullptr) {
      // char *str = estrdup(errCode);
      RETURN_STRING(errCode);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XPathProcessor, getErrorMessage) {
  XPathProcessor *xpathProcessor;
  long index;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    const char *errStr = xpathProcessor->getErrorMessage();
    if (errStr != nullptr) {
      // char *str = estrdup(errStr);
      RETURN_STRING(errStr);
    }
  }
  RETURN_NULL();
}
PHP_METHOD(XPathProcessor, exceptionClear) {
  XPathProcessor *xpathProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xpathProcessor_object *obj =
      (xpathProcessor_object *)((char *)pobj -
                                XtOffsetOf(xpathProcessor_object, std));
  xpathProcessor = obj->xpathProcessor;
  if (xpathProcessor != nullptr) {
    xpathProcessor->exceptionClear();
  }
}

zend_function_entry XPathProcessor_methods[] = {
    PHP_ME(XPathProcessor, __destruct, arginfo_saxonc_xpath_destruct,
           ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor, setContextItem,
                                   arginfo_saxonc_xpath_setContextItem,
                                   ZEND_ACC_PUBLIC)
        PHP_ME(
            XPathProcessor, setContextFile, arginfo_saxonc_xpath_setContextFile,
            ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor, effectiveBooleanValue,
                                    arginfo_saxonc_xpath_effectiveBooleanValue,
                                    ZEND_ACC_PUBLIC)
            PHP_ME(XPathProcessor, setUnprefixedElementMatchingPolicy,
                   arginfo_saxonc_xpath_setUnprefixedElementMatchingPolicy,
                   ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor, evaluate,
                                           arginfo_saxonc_xpath_evaluate,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(
                    XPathProcessor, evaluateSingle,
                    arginfo_saxonc_xpath_evaluateSingle,
                    ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor, setParameter,
                                            arginfo_saxonc_xpath_setParameter,
                                            ZEND_ACC_PUBLIC)
                    PHP_ME(
                        XPathProcessor, setProperty,
                        arginfo_saxonc_xpath_setProperty,
                        ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor,
                                                setLanguageVersion,
                                                arginfo_saxonc_xpath_setLanguageVersion,
                                                ZEND_ACC_PUBLIC)
                        PHP_ME(
                            XPathProcessor, clearParameters,
                            arginfo_saxonc_xpath_clearParameters,
                            ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor,
                                                    clearProperties,
                                                    arginfo_saxonc_xpath_clearProperties,
                                                    ZEND_ACC_PUBLIC)
                            PHP_ME(
                                XPathProcessor, exceptionOccurred,
                                arginfo_saxonc_xpath_exceptionOccurred,
                                ZEND_ACC_PUBLIC) PHP_ME(XPathProcessor,
                                                        exceptionClear,
                                                        arginfo_saxonc_xpath_exceptionClear,
                                                        ZEND_ACC_PUBLIC)
                                PHP_ME(XPathProcessor, getErrorCode,
                                       arginfo_saxonc_xpath_getErrorCode,
                                       ZEND_ACC_PUBLIC)
                                    PHP_ME(XPathProcessor, getErrorMessage,
                                           arginfo_saxonc_xpath_getErrorMessage,
                                           ZEND_ACC_PUBLIC)
                                        PHP_ME(
                                            XPathProcessor, declareNamespace,
                                            arginfo_saxonc_xpath_declareNamespace,
                                            ZEND_ACC_PUBLIC)
                                            PHP_ME(
                                                XPathProcessor,
                                                setBackwardsCompatible,
                                                arginfo_saxonc_xpath_setBackwardsCompatible,
                                                ZEND_ACC_PUBLIC)
                                                PHP_ME(
                                                    XPathProcessor, setCaching,
                                                    arginfo_saxonc_xpath_setCaching,
                                                    ZEND_ACC_PUBLIC)
                                                    PHP_ME(
                                                        XPathProcessor,
                                                        importSchemaNamespace,
                                                        arginfo_saxonc_xpath_importSchemaNamespace,
                                                        ZEND_ACC_PUBLIC)
                                                        PHP_ME(
                                                            XPathProcessor,
                                                            setBaseURI,
                                                            arginfo_saxonc_xpath_setBaseURI,
                                                            ZEND_ACC_PUBLIC){
                                                            nullptr, nullptr,
                                                            nullptr}};
