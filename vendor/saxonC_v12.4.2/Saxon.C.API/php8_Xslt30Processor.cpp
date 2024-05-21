//#include "php_Xslt30Processor.h"

zend_object_handlers xslt30Processor_object_handlers;

zend_class_entry *xslt30Processor_ce;

/*     ============== XSLT30: PHP Interface of  Xslt30Processor class
 * =============== */

void Xslt30Processor_free_storage(zend_object *object) {

  zend_object_std_dtor(object);
}

void Xslt30Processor_destroy_storage(zend_object *object) {
  xslt30Processor_object *obj;

  zend_objects_destroy_object(object);
}

zend_object *xslt30Processor_create_handler(zend_class_entry *type) {

  xslt30Processor_object *obj = (xslt30Processor_object *)ecalloc(
      1, sizeof(xslt30Processor_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std, type);
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xslt30Processor_object_handlers;

  return &obj->std;
}

PHP_METHOD(Xslt30Processor, __destruct) {
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));

  Xslt30Processor *xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    delete xslt30Processor;
  }
}

PHP_METHOD(Xslt30Processor, clearParameters) {
  Xslt30Processor *xslt30Processor;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    xslt30Processor->clearParameters();
  }
}

PHP_METHOD(Xslt30Processor, transformFileToFile) {
  Xslt30Processor *xsltProcessor;
  char *outfileName;
  char *infilename;
  char *styleFileName;
  size_t len1, len2, len3;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "sss", &infilename, &len1,
                            &styleFileName, &len2, &outfileName,
                            &len3) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xsltProcessor = obj->xslt30Processor;

  if (xsltProcessor != nullptr) {
    try {
      xsltProcessor->transformFileToFile(infilename, styleFileName,
                                         outfileName);
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(Xslt30Processor, transformFileToString) {
  Xslt30Processor *xslt30Processor;
  char *infilename = nullptr;
  char *styleFileName = nullptr;
  size_t len1, len2;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &infilename, &len1,
                            &styleFileName, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;

  if (xslt30Processor != nullptr) {
    try {
      const char *result =
          xslt30Processor->transformFileToString(infilename, styleFileName);
      if (result != nullptr) {
        RETVAL_STRING(result);
        SaxonProcessor::deleteString(result);
        return;
      }
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(Xslt30Processor, transformFileToValue) {
  Xslt30Processor *xslt30Processor;
  char *infilename = nullptr;
  char *styleFileName = nullptr;
  size_t len1, len2;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &infilename, &len1,
                            &styleFileName, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;

  if (xslt30Processor != nullptr) {
    try {
      XdmValue *node =
          xslt30Processor->transformFileToValue(infilename, styleFileName);
      if (node != nullptr) {
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *ooth = Z_OBJ_P(return_value);
          xdmValue_object *vobj =
              (xdmValue_object *)((char *)ooth -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = node;
        }
      }
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(Xslt30Processor, setParameter) {

  Xslt30Processor *xslt30Processor;
  char *name;
  zval *oth;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &name, &len2, &oth) ==
      FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    if (Z_TYPE_P(oth) == IS_NULL) {
      php_error(E_WARNING, "Error setting source value - value is null");
      return;
    }
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);
    if (strcmp(objName, "Saxon\\XdmNode") == 0) {
      zend_object *ooth = Z_OBJ_P(oth);
      xdmNode_object *nobj =
          (xdmNode_object *)((char *)ooth - XtOffsetOf(xdmNode_object, std));
      if (nobj != NULL) {
        XdmNode *value = nobj->xdmNode;
        if (value != NULL) {
          xslt30Processor->setParameter(name, (XdmValue *)value);
          value->incrementRefCount();
        }
      }
    } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {
      zend_object *ooth = Z_OBJ_P(oth);
      xdmValue_object *vobj =
          (xdmValue_object *)((char *)ooth - XtOffsetOf(xdmValue_object, std));
      if (vobj != NULL) {
        XdmValue *value = vobj->xdmValue;
        if (value != NULL) {

          xslt30Processor->setParameter(name, value);
          value->incrementRefCount();
        }
      }

    } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
      zend_object *ooth = Z_OBJ_P(oth);
      xdmAtomicValue_object *aobj =
          (xdmAtomicValue_object *)((char *)ooth -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      if (aobj != NULL) {
        XdmAtomicValue *value = aobj->xdmAtomicValue;
        if (value != NULL) {

          xslt30Processor->setParameter(name, (XdmValue *)value);
          value->incrementRefCount();
        }
      }
    }
  }
}

PHP_METHOD(Xslt30Processor, compileFromFile) {
  Xslt30Processor *xslt30Processor = nullptr;
  char *name = nullptr;
  size_t len1;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &name, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    try {
      XsltExecutable *executable = xslt30Processor->compileFromFile(name);
      if (executable != nullptr) {
        if (object_init_ex(return_value, xsltExecutable_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *ooth = Z_OBJ_P(return_value);
          xsltExecutable_object *vobj =
              (xsltExecutable_object *)((char *)ooth -
                                        XtOffsetOf(xsltExecutable_object, std));
          assert(vobj != nullptr);
          vobj->xsltExecutable = executable;
        }
      }
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(Xslt30Processor, compileFromAssociatedFile) {
  Xslt30Processor *xslt30Processor;
  char *name = nullptr;
  size_t len1;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &name, &len1) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;

  if (xslt30Processor != nullptr) {
    try {
      XsltExecutable *executable =
          xslt30Processor->compileFromAssociatedFile(name);
      zend_object *ooth = Z_OBJ_P(return_value);
      xsltExecutable_object *vobj =
          (xsltExecutable_object *)((char *)ooth -
                                    XtOffsetOf(xsltExecutable_object, std));
      assert(vobj != nullptr);
      vobj->xsltExecutable = executable;
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(Xslt30Processor, compileFromString) {
  Xslt30Processor *xslt30Processor;
  char *stylesheetStr;
  char *encodingStr = nullptr;
  size_t len1, len2, myint;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &stylesheetStr, &len1) ==
          FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &stylesheetStr, &len1,
                                   &encodingStr, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    try {
      XsltExecutable *executable =
          xslt30Processor->compileFromString(stylesheetStr, encodingStr);

      if (object_init_ex(return_value, xsltExecutable_ce) != SUCCESS) {
        RETURN_NULL();
      } else {

        zend_object *ooth = Z_OBJ_P(return_value);
        xsltExecutable_object *vobj =
            (xsltExecutable_object *)((char *)ooth -
                                      XtOffsetOf(xsltExecutable_object, std));

        assert(vobj != nullptr);

        vobj->xsltExecutable = executable;
      }

    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(Xslt30Processor, compileFromStringAndSave) {
  Xslt30Processor *xslt30Processor;
  char *stylesheetStr;
  char *filename = nullptr;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &stylesheetStr, filename,
                            &len1, &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    try {
      xslt30Processor->compileFromStringAndSave(stylesheetStr, filename);
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(Xslt30Processor, compileFromFileAndSave) {
  Xslt30Processor *xslt30Processor;
  char *stylesheetFilename = nullptr;
  char *filename = nullptr;
  size_t len1, len2, myint;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &stylesheetFilename,
                            filename, &len1, &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    try {
      xslt30Processor->compileFromStringAndSave(stylesheetFilename, filename);
    } catch (SaxonApiException &e) {
      zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
    }
  }
}

PHP_METHOD(Xslt30Processor, compileFromValue) {
  Xslt30Processor *xslt30Processor;
  zval *oth;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "O", &oth, xdmValue_ce) ==
      FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    zend_object *vvobj = Z_OBJ_P(oth);
    xdmValue_object *ooth =
        (xdmValue_object *)((char *)vvobj - XtOffsetOf(xdmValue_object, std));
    if (ooth != nullptr) {
      XdmValue *value = ooth->xdmValue;
      if (value != nullptr && value->size() == 1 &&
          (value->getHead())->getType() == 3) {
        try {
          XsltExecutable *executable = xslt30Processor->compileFromXdmNode(
              (XdmNode *)(value->getHead()));
          if (executable != nullptr) {
            if (object_init_ex(return_value, xsltExecutable_ce) != SUCCESS) {
              RETURN_NULL();
            } else {
              zend_object *ooth = Z_OBJ_P(return_value);
              xsltExecutable_object *vobj =
                  (xsltExecutable_object *)((char *)ooth -
                                            XtOffsetOf(xsltExecutable_object,
                                                       std));
              assert(vobj != nullptr);
              vobj->xsltExecutable = executable;
            }
          }
        } catch (SaxonApiException &e) {
          zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(),
                               0);
        }
      } else {
        zend_throw_exception(zend_ce_exception, "XdmValue is not an XdmNode",
                             0);
      }
    }
  }
}

PHP_METHOD(Xslt30Processor, setJustInTimeCompilation) {
  Xslt30Processor *xslt30Processor;
  bool jit = false;
  size_t len1;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &jit) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    xslt30Processor->setJustInTimeCompilation(jit);
  }
}

PHP_METHOD(Xslt30Processor, importPackage) {
  Xslt30Processor *xslt30Processor;
  char *str;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &str, &str) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {

    if (str != nullptr) {
      xslt30Processor->importPackage(str);
    }
  }
}

PHP_METHOD(Xslt30Processor, setTargetEdition) {
  Xslt30Processor *xslt30Processor;
  char *str;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &str, &str) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {

    if (str != nullptr) {
      xslt30Processor->setTargetEdition(str);
    }
  }
}

PHP_METHOD(Xslt30Processor, setRelocatable) {
  Xslt30Processor *xslt30Processor;
  bool relocate = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &relocate) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    xslt30Processor->setRelocatable(relocate);
  }
}

PHP_METHOD(Xslt30Processor, setFastCompilation) {
  Xslt30Processor *xslt30Processor;
  bool fast = false;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "b", &fast) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {
    xslt30Processor->setFastCompilation(fast);
  }
}

PHP_METHOD(Xslt30Processor, setXsltLanguageVersion) {
  Xslt30Processor *xslt30Processor;
  char *str;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &str, &str) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {

    if (str != nullptr) {
      xslt30Processor->setXsltLanguageVersion(str);
    }
  }
}

PHP_METHOD(Xslt30Processor, setcwd) {
  Xslt30Processor *xslt30Processor;
  char *cwdStr;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &cwdStr, &len) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != nullptr) {

    if (cwdStr != nullptr) {
      xslt30Processor->setcwd(cwdStr);
    }
  }
}

PHP_METHOD(Xslt30Processor, exceptionOccurred) {
  Xslt30Processor *xslt30Processor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    bool result = xslt30Processor->exceptionOccurred();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(Xslt30Processor, getErrorCode) {
  Xslt30Processor *xslt30Processor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    const char *errCode = xslt30Processor->getErrorCode();
    if (errCode != NULL) {
      // char *str = estrdup(errCode);
      RETURN_STRING(errCode);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(Xslt30Processor, getErrorMessage) {
  Xslt30Processor *xslt30Processor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    const char *errStr = xslt30Processor->getErrorMessage();
    if (errStr != NULL) {
      // char *str = estrdup(errStr);
      RETURN_STRING(errStr);
    }
  }
  RETURN_NULL();
}
PHP_METHOD(Xslt30Processor, exceptionClear) {
  Xslt30Processor *xslt30Processor;
  zend_object *pobj = Z_OBJ_P(getThis());
  xslt30Processor_object *obj =
      (xslt30Processor_object *)((char *)pobj -
                                 XtOffsetOf(xslt30Processor_object, std));
  xslt30Processor = obj->xslt30Processor;
  if (xslt30Processor != NULL) {
    xslt30Processor->exceptionClear();
  }
}

zend_function_entry Xslt30Processor_methods[] = {
    PHP_ME(Xslt30Processor, __destruct, arginfo_saxonc_xp_destruct,
           ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor, transformFileToFile,
                                   arginfo_saxonc_xp_transformFileToFile,
                                   ZEND_ACC_PUBLIC)
        PHP_ME(Xslt30Processor, transformFileToString,
               arginfo_saxonc_xp_transformFileToString,
               ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor, transformFileToValue,
                                       arginfo_saxonc_xp_transformFileToValue,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(Xslt30Processor, compileFromFile,
                   arginfo_saxonc_xp_compileFromFile,
                   ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor, compileFromValue,
                                           arginfo_saxonc_xp_compileFromValue,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(
                    Xslt30Processor, compileFromString,
                    arginfo_saxonc_xp_compileFromString,
                    ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor,
                                            compileFromStringAndSave,
                                            arginfo_saxonc_xp_compileFromStringAndSave,
                                            ZEND_ACC_PUBLIC)
                    PHP_ME(
                        Xslt30Processor, compileFromFileAndSave,
                        arginfo_saxonc_xp_compileFromFileAndSave,
                        ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor,
                                                compileFromAssociatedFile,
                                                arginfo_saxonc_xp_compileFromAssociatedFile,
                                                ZEND_ACC_PUBLIC)
                        PHP_ME(
                            Xslt30Processor, setJustInTimeCompilation,
                            arginfo_saxonc_xp_setJustInTimeCompilation,
                            ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor,
                                                    setRelocatable,
                                                    arginfo_saxonc_xp_setRelocatable,
                                                    ZEND_ACC_PUBLIC)
                            PHP_ME(Xslt30Processor, setFastCompilation,
                                   arginfo_saxonc_xp_setFastCompilation,
                                   ZEND_ACC_PUBLIC)
                                PHP_ME(
                                    Xslt30Processor, setXsltLanguageVersion,
                                    arginfo_saxonc_xp_setXsltLanguageVersion,
                                    ZEND_ACC_PUBLIC) PHP_ME(Xslt30Processor,
                                                            setTargetEdition,
                                                            arginfo_saxonc_xp_setTargetEdition,
                                                            ZEND_ACC_PUBLIC)
                                    PHP_ME(Xslt30Processor, importPackage,
                                           arginfo_saxonc_xp_importPackage,
                                           ZEND_ACC_PUBLIC)
                                        PHP_ME(Xslt30Processor, setParameter,
                                               arginfo_saxonc_xp_setParameter,
                                               ZEND_ACC_PUBLIC)
                                            PHP_ME(
                                                Xslt30Processor,
                                                clearParameters,
                                                arginfo_saxonc_xp_clearParameters,
                                                ZEND_ACC_PUBLIC)
                                                PHP_ME(
                                                    Xslt30Processor,
                                                    exceptionOccurred,
                                                    arginfo_saxonc_xp_exceptionOccurred,
                                                    ZEND_ACC_PUBLIC)
                                                    PHP_ME(
                                                        Xslt30Processor,
                                                        exceptionClear,
                                                        arginfo_saxonc_xp_exceptionClear,
                                                        ZEND_ACC_PUBLIC)
                                                        PHP_ME(
                                                            Xslt30Processor,
                                                            getErrorCode,
                                                            arginfo_saxonc_xp_getErrorCode,
                                                            ZEND_ACC_PUBLIC)
                                                            PHP_ME(
                                                                Xslt30Processor,
                                                                getErrorMessage,
                                                                arginfo_saxonc_xp_getErrorMessage,
                                                                ZEND_ACC_PUBLIC){
                                                                nullptr,
                                                                nullptr,
                                                                nullptr}};
