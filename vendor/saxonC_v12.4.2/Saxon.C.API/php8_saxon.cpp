#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php8_saxon.h"

#ifdef COMPILE_DL_SAXON
extern "C" {
ZEND_GET_MODULE(saxon)
}
#endif

/* JNINativeMethod phpMethods[] =
{
    {
         "_phpCall",
         "(Ljava/lang/String;[Ljava/lang/Object;[Ljava/lang/String;)Ljava/lang/Object;",
         (void *)&phpNativeCall
    }
};*/

zend_object_handlers saxonProcessor_object_handlers;

zend_object_handlers xdmValue_object_handlers;
zend_object_handlers xdmItem_object_handlers;
zend_object_handlers xdmNode_object_handlers;
zend_object_handlers xdmAtomicValue_object_handlers;
zend_object_handlers xdmFunctionItem_object_handlers;
zend_object_handlers xdmMap_object_handlers;
zend_object_handlers xdmArray_object_handlers;

zend_class_entry *saxonProcessor_ce;

zend_class_entry *xdmValue_ce;
zend_class_entry *xdmItem_ce;
zend_class_entry *xdmNode_ce;
zend_class_entry *xdmAtomicValue_ce;
zend_class_entry *xdmFunctionItem_ce;
zend_class_entry *xdmMap_ce;
zend_class_entry *xdmArray_ce;

zend_class_entry *xsltExecutable_ce;

#include "php8_SchemaValidator.cpp"
#include "php8_DocumentBuilder.cpp"
#include "php8_XPathProcessor.cpp"
#include "php8_XQueryProcessor.cpp"
#include "php8_Xslt30Processor.cpp"
#include "php8_XsltExecutable.cpp"

void SaxonProcessor_free_storage(zend_object *object) {

  // std::cerr<<"_free_Storage called php-saxonProc"<<std::endl;

  saxonProcessor_object *obj;

  obj = (saxonProcessor_object *)((char *)object -
                                  XtOffsetOf(saxonProcessor_object, std));

  SaxonProcessor *saxonProc = obj->saxonProcessor;
  if (saxonProc != nullptr) {
    // SaxonProcessor::release();
    delete saxonProc;
  }
  zend_object_std_dtor(object);
}

void SaxonProcessor_destroy_storage(zend_object *pobj) {

  // php_error(E_WARNING,"_destroy_Storage called php-saxonProc");
  //   saxonProcessor_object *obj;
  // zend_object* pobj = Z_OBJ_P(getThis());
  /*  saxonProcessor_object * obj = (saxonProcessor_object *)((char *)pobj -
     XtOffsetOf(saxonProcessor_object, std));

     SaxonProcessor * saxonProc= obj->saxonProcessor;
     if(saxonProc != nullptr) {
         SaxonProcessor::release();
         delete saxonProc;
     }*/

  zend_objects_destroy_object(pobj);
}

zend_object *saxonProcessor_create_handler(zend_class_entry *type) {
  zval *tmp;
  zend_object retval;
  saxonProcessor_object *obj = (saxonProcessor_object *)ecalloc(
      1, sizeof(saxonProcessor_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &saxonProcessor_object_handlers;

  return &obj->std;
}

PHP_METHOD(SaxonProcessor, __construct) {
  if (ZEND_NUM_ARGS() > 2) {
    WRONG_PARAM_COUNT;
  }

  char *cwdi = nullptr;
  bool license = false;
  size_t len1;
  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "b", &license) == FAILURE) {
    RETURN_NULL();
  }

  if (ZEND_NUM_ARGS() > 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "bs", &license, &cwdi, &len1) ==
          FAILURE) {
    RETURN_NULL();
  }

  zval *object = getThis();
  SaxonProcessor *saxonProc = nullptr;
  zend_object *zobj = Z_OBJ_P(object);

  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)zobj -
                                XtOffsetOf(saxonProcessor_object, std));

  saxonProc = new SaxonProcessor(license);

  obj->saxonProcessor = saxonProc;
  // std::cerr<<"SaxonProcessorConstructor cp1"<<std::endl;
  if (cwdi == nullptr) {
// std::cerr<<"SaxonProcessorConstructor cp1-1"<<std::endl;
#if !(defined(__linux__) || (defined(__APPLE__) && defined(__MACH__)))
    TCHAR s[256];

    // --
    DWORD a = GetCurrentDirectory(256, s);
    const size_t newsize = wcslen(s) * 2;
    char *cwd = new char[newsize];
    wcstombs_s(0, cwd, newsize, s, _TRUNCATE);
    // -- code above returns the apache installation directory as the CWD

    char *cwd2;

    // php_error(E_WARNING,cwd2);

    saxonProc->setcwd(cwd);

    delete[] cwd;
#else
    char cwd[256];

    VCWD_GETCWD(cwd, sizeof(cwd));
    if (cwd != nullptr) {
      saxonProc->setcwd(cwd);
    }
#endif
    delete cwdi;

  } else {
    saxonProc->setcwd(cwdi);
  }
}

PHP_METHOD(SaxonProcessor, __destruct) {
  // php_error(E_WARNING,"__destruct called php-saxonProc");
  // std::cerr<<"__destruct call saxonProc"<<std::endl;
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  SaxonProcessor *saxonProc = obj->saxonProcessor;
  if (saxonProc != nullptr) {
    // SaxonProcessor::release();
    // delete saxonProc;
  }
}

PHP_METHOD(SaxonProcessor, release) {
  // php_error(E_WARNING,"__destruct called php-saxonProc");
  //   std::cerr<<"__destruct call saxonProc"<<std::endl;
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  SaxonProcessor *saxonProc = obj->saxonProcessor;
  if (saxonProc != nullptr) {
    SaxonProcessor::release();
  }
}

PHP_METHOD(SaxonProcessor, createXdmMapValue) {
  SaxonProcessor *proc = nullptr;
  HashTable *arr_hash;

  zval *items_zval;
  zval *val;
  long num_key;
  XdmValue **arguments = nullptr;
  XdmAtomicValue **c_keys = nullptr;
  int argument_length = 0;
  zend_string *key;

  if (ZEND_NUM_ARGS() != 3) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "a", &items_zval) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  SaxonProcessor *saxonProc = obj->saxonProcessor;
  arr_hash = Z_ARRVAL_P(items_zval);
  argument_length = zend_hash_num_elements(arr_hash);

  arguments = new XdmValue *[argument_length];
  c_keys = new XdmAtomicValue *[argument_length];

  if (saxonProc != nullptr) {
    ZEND_HASH_FOREACH_KEY_VAL(arr_hash, num_key, key, val) {

      if (key != NULL) {
        const char *c_key = ZSTR_VAL(key);
        c_keys[num_key] = saxonProc->makeStringValue(c_key);

      } else {
        c_keys[num_key] = saxonProc->makeIntegerValue(num_key);
      }

      if (Z_TYPE_P(val) != IS_NULL) {
        const char *objName = ZSTR_VAL(Z_OBJCE_P(val)->name);

        if (strcmp(objName, "Saxon\\XdmNode") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmNode_object *nobj =
              (xdmNode_object *)((char *)ooth -
                                 XtOffsetOf(xdmNode_object, std));
          if (nobj != nullptr) {
            XdmValue *value = (XdmValue *)nobj->xdmNode;
            arguments[num_key] = value;
          }
        } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmAtomicValue_object *nobj =
              (xdmAtomicValue_object *)((char *)ooth -
                                        XtOffsetOf(xdmAtomicValue_object, std));
          if (nobj != nullptr) {
            XdmValue *value = (XdmValue *)nobj->xdmAtomicValue;
            arguments[num_key] = value;
          }
        } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmValue_object *nobj =
              (xdmValue_object *)((char *)ooth -
                                  XtOffsetOf(xdmValue_object, std));
          if (nobj != nullptr) {
            XdmValue *value = nobj->xdmValue;
            arguments[num_key] = value;
          }
        } else { // TODO error warning}
        }
      } else {
        // TODO error warning
      }
    }
    ZEND_HASH_FOREACH_END();

    XdmMap *result = saxonProc->makeMap3(c_keys, arguments, argument_length);

    if (result != nullptr) {
      result->incrementRefCount();
      if (object_init_ex(return_value, xdmMap_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmMap_object *vobj =
            (xdmMap_object *)((char *)vvobj - XtOffsetOf(xdmMap_object, std));
        assert(vobj != nullptr);
        vobj->xdmMap = result;
        return;
      }
    } else {
      RETURN_NULL();
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, createXdmArrayValue) {
  SaxonProcessor *proc = nullptr;
  HashTable *arr_hash;

  zval *items_zval;
  zval *val;
  long num_key;
  XdmValue **arguments = nullptr;
  int argument_length = 0;
  zend_string *key;

  if (ZEND_NUM_ARGS() != 3) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "a", &items_zval) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  SaxonProcessor *saxonProc = obj->saxonProcessor;
  arr_hash = Z_ARRVAL_P(items_zval);
  argument_length = zend_hash_num_elements(arr_hash);

  arguments = new XdmValue *[argument_length];

  if (saxonProc != nullptr) {
    ZEND_HASH_FOREACH_KEY_VAL(arr_hash, num_key, key, val) {
      if (Z_TYPE_P(val) != IS_NULL) {
        const char *objName = ZSTR_VAL(Z_OBJCE_P(val)->name);

        if (strcmp(objName, "Saxon\\XdmNode") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmNode_object *nobj =
              (xdmNode_object *)((char *)ooth -
                                 XtOffsetOf(xdmNode_object, std));
          if (nobj != nullptr) {
            XdmValue *value = (XdmValue *)nobj->xdmNode;
            arguments[num_key] = value;
          }
        } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmAtomicValue_object *nobj =
              (xdmAtomicValue_object *)((char *)ooth -
                                        XtOffsetOf(xdmAtomicValue_object, std));
          if (nobj != nullptr) {
            XdmValue *value = (XdmValue *)nobj->xdmAtomicValue;
            arguments[num_key] = value;
          }
        } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {
          zend_object *ooth = Z_OBJ_P(val);
          xdmValue_object *nobj =
              (xdmValue_object *)((char *)ooth -
                                  XtOffsetOf(xdmValue_object, std));
          if (nobj != nullptr) {
            XdmValue *value = nobj->xdmValue;
            arguments[num_key] = value;
          }
        } else { // TODO error warning}
        }
      } else {
        // TODO error warning
      }
    }
    ZEND_HASH_FOREACH_END();

    XdmArray *result = saxonProc->makeArray(arguments, argument_length);

    if (result != nullptr) {
      result->incrementRefCount();
      if (object_init_ex(return_value, xdmArray_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmArray_object *vobj =
            (xdmArray_object *)((char *)vvobj -
                                XtOffsetOf(xdmArray_object, std));
        assert(vobj != nullptr);
        vobj->xdmArray = result;
        return;
      }
    } else {
      RETURN_NULL();
    }
  }
}

PHP_METHOD(SaxonProcessor, EQNameToClarkName) {
  SaxonProcessor *saxonProcessor;
  char *eqname;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &eqname, &len1) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    const char *qname = saxonProcessor->EQNameToClarkName(eqname);
    if (qname != NULL) {
      // char *str = estrdup(errStr);
      RETURN_STRING(qname);
    }
  }

  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, clarkNameToEQName) {
  SaxonProcessor *saxonProcessor;
  char *clname;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &clname, &len1) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    const char *qname = saxonProcessor->clarkNameToEQName(clname);
    if (qname != NULL) {
      // char *str = estrdup(errStr);
      RETVAL_STRING(qname);
      SaxonProcessor::deleteString(qname);
      return;
    }
  }

  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, createQNameValue) {
  SaxonProcessor *saxonProcessor;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    XdmAtomicValue *qname = saxonProcessor->makeQNameValue(source);
    if (qname != nullptr) {

      if (object_init_ex(return_value, xdmAtomicValue_ce) != SUCCESS) {
        RETURN_NULL();
      } else {

        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmAtomicValue_object *vobj =
            (xdmAtomicValue_object *)((char *)vvobj -
                                      XtOffsetOf(xdmAtomicValue_object, std));

        assert(vobj != nullptr);
        qname->incrementRefCount();
        vobj->xdmAtomicValue = qname;
        return;
      }
    } else {
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, attachCurrentThread) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    saxonProcessor->attachCurrentThread();
    return;
  }
  return;
}
PHP_METHOD(SaxonProcessor, detachCurrentThread) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    saxonProcessor->detachCurrentThread();
    return;
  }
  return;
}

PHP_METHOD(SaxonProcessor, isSchemaAware) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    if (saxonProcessor->isSchemaAwareProcessor()) {
      RETURN_TRUE;
    }
  }
  RETURN_FALSE;
}

PHP_METHOD(SaxonProcessor, setCatalog) {
  SaxonProcessor *saxonProcessor;
  char *catalogFile;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &catalogFile, &len) ==
      FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    if (catalogFile != nullptr) {
      try {
        saxonProcessor->setCatalog(catalogFile);
      } catch (SaxonApiException &e) {
             zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
      }
    }
  }
}

PHP_METHOD(SaxonProcessor, setCatalogFiles) {
  SaxonProcessor *saxonProcessor;
  zval *items_zval;
  size_t len;
  HashTable *arr_hash;

  zval *val;
  long num_key;
  int argument_length = 0;
  zend_string *key;
  int i = 0;

  const char **catalogFiles = nullptr;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "a", &items_zval) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    arr_hash = Z_ARRVAL_P(items_zval);
    argument_length = zend_hash_num_elements(arr_hash);

    catalogFiles = new const char *[argument_length];

    ZEND_HASH_FOREACH_KEY_VAL(arr_hash, num_key, key, val) {
      if (Z_TYPE_P(val) == IS_STRING) {
        catalogFiles[i] = Z_STRVAL_P(val);

        i++;
      } else {
        // TODO error warning
      }
    }
    ZEND_HASH_FOREACH_END();

    if (catalogFiles != nullptr) {
      try {
        saxonProcessor->setCatalogFiles(catalogFiles, argument_length);
        delete[] catalogFiles;
      } catch (SaxonApiException &e) {
             zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
      }
    }
  }
}

PHP_METHOD(SaxonProcessor, setcwd) {
  SaxonProcessor *saxonProcessor;
  char *cwdStr;
  size_t len;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &cwdStr, &len) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    if (cwdStr != nullptr) {
      saxonProcessor->setcwd(cwdStr);
    }
  }
}

PHP_METHOD(SaxonProcessor, parseJsonFromString) {
  SaxonProcessor *saxonProcessor;
  char *source;
  char *encoding = nullptr;
  size_t len1, len2;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &source, &len1,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    XdmValue *value = saxonProcessor->parseJsonFromString(source, encoding);
    if (value != nullptr) {
      if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        value->incrementRefCount();
        zend_object *vobj = Z_OBJ_P(return_value);
        xdmValue_object *xdmVObj =
            (xdmValue_object *)((char *)vobj -
                                XtOffsetOf(xdmValue_object, std));
        assert(xdmVObj != nullptr);

        xdmVObj->xdmValue = value;
      }
    } else {
      if (obj->saxonProcessor->exceptionOccurred()) {
        // TODO throw exception
      }
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, parseJsonFromFile) {
  SaxonProcessor *saxonProcessor;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {

    XdmNode *node = saxonProcessor->parseXmlFromFile(source);
    if (node != nullptr) {

      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {

        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmNode_object *vobj =
            (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));

        assert(vobj != nullptr);
        node->incrementRefCount();
        vobj->xdmNode = node;
        return;
      }
    } else {
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, parseXmlFromString) {
  SaxonProcessor *saxonProcessor;
  SchemaValidator *validator = nullptr;
  zval *oth = nullptr;
  char *source;
  char *encoding = nullptr;
  size_t len1, len2;

  if (ZEND_NUM_ARGS() > 3) {
    WRONG_PARAM_COUNT;
  }

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &source, &len1,
                                   &oth) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 3 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "szs", &source, &len1, &oth,
                                   &encoding, &len2) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    if (oth != nullptr && Z_TYPE_P(oth) != IS_NULL) {
      zend_object *vvobj = Z_OBJ_P(oth);

      schemaValidator_object *ooth =
          (schemaValidator_object *)((char *)pobj -
                                     XtOffsetOf(schemaValidator_object, std));
      if (ooth != nullptr) {
        validator = ooth->schemaValidator;
      }
    }

    XdmNode *node =
        saxonProcessor->parseXmlFromString(source, encoding, validator);
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
      if (obj->saxonProcessor->exceptionOccurred()) {
        // TODO throw exception
      }
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, parseXmlFromFile) {
  SaxonProcessor *saxonProcessor;
  SchemaValidator *validator = nullptr;
  zval *oth = nullptr;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &source, &len1,
                                   &oth) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    if (oth != nullptr && Z_TYPE_P(oth) != IS_NULL) {
      zend_object *vvobj = Z_OBJ_P(oth);

      schemaValidator_object *ooth =
          (schemaValidator_object *)((char *)pobj -
                                     XtOffsetOf(schemaValidator_object, std));
      if (ooth != nullptr) {
        validator = ooth->schemaValidator;
      }
    }
    XdmNode *node = saxonProcessor->parseXmlFromFile(source, validator);
    if (node != nullptr) {

      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {

        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmNode_object *vobj =
            (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));

        assert(vobj != nullptr);
        node->incrementRefCount();
        vobj->xdmNode = node;
        return;
      }
    } else {
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, parseXmlFromUri) {
  SaxonProcessor *saxonProcessor;
  SchemaValidator *validator = nullptr;
  zval *oth = nullptr;
  char *source;
  size_t len1;

  if (ZEND_NUM_ARGS() == 1 &&
      zend_parse_parameters(ZEND_NUM_ARGS(), "s", &source, &len1) == FAILURE) {
    RETURN_NULL();
  } else if (ZEND_NUM_ARGS() == 2 &&
             zend_parse_parameters(ZEND_NUM_ARGS(), "sz", &source, &len1,
                                   &oth) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    if (oth != nullptr && Z_TYPE_P(oth) != IS_NULL) {
      zend_object *vvobj = Z_OBJ_P(oth);

      schemaValidator_object *ooth =
          (schemaValidator_object *)((char *)pobj -
                                     XtOffsetOf(schemaValidator_object, std));
      if (ooth != nullptr) {
        validator = ooth->schemaValidator;
      }
    }
    XdmNode *node = saxonProcessor->parseXmlFromUri(source, validator);
    if (node != nullptr) {

      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      } else {

        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmNode_object *vobj =
            (xdmNode_object *)((char *)vvobj - XtOffsetOf(xdmNode_object, std));

        assert(vobj != nullptr);
        node->incrementRefCount();
        vobj->xdmNode = node;
        return;
      }
    } else {
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, createAtomicValue) {
  XdmAtomicValue *xdmValue = nullptr;
  SaxonProcessor *proc;
  char *source;
  int len1;
  zval *zvalue;
  bool bVal;
  char *sVal;
  int len;
  long iVal;
  double dVal;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &zvalue) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  proc = obj->saxonProcessor;
  assert(proc != nullptr);
  if (proc != nullptr) {
    switch (Z_TYPE_P(zvalue)) {
    case IS_FALSE:
      xdmValue = proc->makeBooleanValue(false);
    case IS_TRUE:
      xdmValue = proc->makeBooleanValue(true);
      break;
    case IS_LONG:
      iVal = Z_LVAL_P(zvalue);
      xdmValue = proc->makeIntegerValue((int)iVal);
      break;
    case IS_STRING:
      sVal = Z_STRVAL_P(zvalue);
      len = Z_STRLEN_P(zvalue);

      xdmValue = proc->makeStringValue((const char *)sVal);
      // efree(sVal);
      break;
    case IS_NULL:
      xdmValue = new XdmAtomicValue();
      break;
    case IS_DOUBLE:
      dVal = (double)Z_DVAL_P(zvalue);
      xdmValue = proc->makeDoubleValue((double)iVal);
      break;
    case IS_ARRAY:
      // TODO: Should not be expected. Do this some other way
      // break;
    case IS_OBJECT:
      // TODO: implement this
      // break;
    default:
      obj = nullptr;
      zend_throw_exception(zend_ce_exception,
                           "unknown type specified in XdmValue", 0);
      RETURN_NULL();
    }
    // std::cerr<<"createAtomicValue cp0 -========================="<<std::endl;
    if (xdmValue == nullptr) {
      RETURN_NULL();
    }
    if (object_init_ex(return_value, xdmAtomicValue_ce) != SUCCESS) {
      RETURN_NULL();
    } else {
      // struct xdmAtomicValue_object* vobj = (struct xdmAtomicValue_object
      // *)Z_OBJ_P(return_value);
      zend_object *vvobj = Z_OBJ_P(return_value);
      xdmAtomicValue_object *vobj =
          (xdmAtomicValue_object *)((char *)vvobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      assert(vobj != nullptr);
      xdmValue->incrementRefCount();
      vobj->xdmAtomicValue = xdmValue;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, newDocumentBuilder) {
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  SaxonProcessor *proc;
  DocumentBuilder *documentBuilder = nullptr;

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  assert(obj != nullptr);
  proc = obj->saxonProcessor;
  assert(proc != nullptr);
  if (proc != nullptr) {
    if (object_init_ex(return_value, documentBuilder_ce) != SUCCESS) {
      RETURN_NULL();
    } else {

      zend_object *vvobj = Z_OBJ_P(return_value);
      documentBuilder_object *vobj =
          (documentBuilder_object *)((char *)vvobj -
                                     XtOffsetOf(documentBuilder_object, std));
      assert(vobj != nullptr);
      documentBuilder = proc->newDocumentBuilder();
      if (documentBuilder == nullptr) {
        RETURN_NULL();
      }
      vobj->documentBuilder = documentBuilder;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, newXPathProcessor) {
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  SaxonProcessor *proc;
  XPathProcessor *xpathProcessor = nullptr;

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  assert(obj != nullptr);
  proc = obj->saxonProcessor;
  assert(proc != nullptr);
  if (proc != nullptr) {
    if (object_init_ex(return_value, xpathProcessor_ce) != SUCCESS) {
      RETURN_NULL();
    } else {
      // struct xpathProcessor_object* vobji = (struct xpathProcessor_object
      // *)Z_OBJ_P(return_value TSRMLS_CC);
      zend_object *vvobj = Z_OBJ_P(return_value);
      xpathProcessor_object *vobj =
          (xpathProcessor_object *)((char *)vvobj -
                                    XtOffsetOf(xpathProcessor_object, std));
      assert(vobj != nullptr);
      xpathProcessor = proc->newXPathProcessor();
      if (xpathProcessor == nullptr) {
        RETURN_NULL();
      }
      vobj->xpathProcessor = xpathProcessor;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, newXslt30Processor) {
  // std::cerr<<"SaxonProcessor newXslt30proc point 1"<<std::endl;
  //  php_error(E_WARNING,"new xslt30Proc 1");
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  SaxonProcessor *proc;
  Xslt30Processor *xslt30Processor = nullptr;

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  // saxonProcessor_object *obj = (saxonProcessor_object *)Z_OBJ_P(getThis());
  assert(obj != nullptr);
  proc = obj->saxonProcessor;

  assert(proc != nullptr);
  if (proc != nullptr) {
    if (object_init_ex(return_value, xslt30Processor_ce) != SUCCESS) {
      RETURN_NULL();
    } else {
      xslt30Processor = proc->newXslt30Processor();
      if (xslt30Processor == nullptr) {
        RETURN_NULL();
      }
      zend_object *vobj = Z_OBJ_P(return_value);
      xslt30Processor_object *xproc_object =
          (xslt30Processor_object *)((char *)vobj -
                                     XtOffsetOf(xslt30Processor_object, std));
      assert(vobj != nullptr);

      xproc_object->xslt30Processor = xslt30Processor;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, newXQueryProcessor) {

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  SaxonProcessor *proc;
  XQueryProcessor *xqueryProcessor = nullptr;
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  proc = obj->saxonProcessor;
  assert(proc != nullptr);
  if (proc != nullptr) {
    if (object_init_ex(return_value, xqueryProcessor_ce) != SUCCESS) {
      RETURN_NULL();
    } else {
      xqueryProcessor = proc->newXQueryProcessor();
      zend_object *vvobj = Z_OBJ_P(return_value);
      xqueryProcessor_object *vobj =
          (xqueryProcessor_object *)((char *)vvobj -
                                     XtOffsetOf(xqueryProcessor_object, std));
      assert(vvobj != nullptr);

      vobj->xqueryProcessor = xqueryProcessor;
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, newSchemaValidator) {

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  SaxonProcessor *proc;
  SchemaValidator *schemaValidator = nullptr;

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  assert(obj != nullptr);
  proc = obj->saxonProcessor;
  assert(proc != nullptr);
  if (proc != nullptr) {
    if (object_init_ex(return_value, schemaValidator_ce) != SUCCESS) {
      RETURN_NULL();
    } else {
      // struct schemaValidator_object* vobj = (struct schemaValidator_object
      // *)Z_OBJ_P(return_value TSRMLS_CC);
      zend_object *vvobj = Z_OBJ_P(return_value);
      schemaValidator_object *vobj =
          (schemaValidator_object *)((char *)vvobj -
                                     XtOffsetOf(schemaValidator_object, std));
      assert(vobj != nullptr);
      try {
        schemaValidator = proc->newSchemaValidator();
        if (schemaValidator == nullptr) {
            RETURN_NULL();
        }
        vobj->schemaValidator = schemaValidator;
      } catch (SaxonApiException &e) {
         zend_throw_exception(zend_ce_exception, e.getMessageWithErrorCode(), 0);
      }
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(SaxonProcessor, version) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    const char *verStr = saxonProcessor->version();
    RETURN_STRING(verStr);
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, exceptionOccurred) {
  SaxonProcessor *saxonProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != NULL) {
    bool result = saxonProcessor->exceptionOccurred();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(SaxonProcessor, getErrorMessage) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != NULL) {
    const char *errStr = saxonProcessor->getErrorMessage();
    if (errStr != NULL) {
      // char *str = estrdup(errStr);
      RETURN_STRING(errStr);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(SaxonProcessor, exceptionClear) {
  SaxonProcessor *saxonProcessor;
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));
  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    saxonProcessor->exceptionClear();
  }
}

PHP_METHOD(SaxonProcessor, setConfigurationProperty) {
  SaxonProcessor *saxonProcessor;
  char *name;
  char *value;
  size_t len1, len2;
  if (ZEND_NUM_ARGS() != 2) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "ss", &name, &len1, &value,
                            &len2) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr && name != nullptr && value != nullptr) {
    saxonProcessor->setConfigurationProperty(name, value);
  }
}

PHP_METHOD(SaxonProcessor, clearConfigurationProperties) {
  SaxonProcessor *saxonProcessor;

  if (ZEND_NUM_ARGS() != 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *pobj = Z_OBJ_P(getThis());
  saxonProcessor_object *obj =
      (saxonProcessor_object *)((char *)pobj -
                                XtOffsetOf(saxonProcessor_object, std));

  saxonProcessor = obj->saxonProcessor;
  if (saxonProcessor != nullptr) {
    saxonProcessor->clearConfigurationProperties();
  }
}
/*
PHP_METHOD(SaxonProcessor, registerPHPFunctions)
{
    SaxonProcessor *saxonProcessor;
    char * libName = nullptr;
    size_t len1;
 //std::cerr<<"checkpoint in registerPHPFunction start"<<std::endl;
    if (ZEND_NUM_ARGS()!= 1) {
        WRONG_PARAM_COUNT;
    }

    if (zend_parse_parameters(ZEND_NUM_ARGS() , "s", &libName, &len1) ==
FAILURE) { RETURN_NULL();
    }

    zend_object* pobj = Z_OBJ_P(getThis());
    saxonProcessor_object * obj = (saxonProcessor_object *)((char *)pobj -
XtOffsetOf(saxonProcessor_object, std));

    saxonProcessor = obj->saxonProcessor;
    if (saxonProcessor != nullptr && libName != nullptr) {
        saxonProcessor->setConfigurationProperty("extc", libName);
    }
saxonProcessor->registerNativeMethods(SaxonProcessor::sxn_environ->env,
"com/saxonica/functions/extfn/cpp/PHPFunctionSet$PHPFunction", phpMethods,
sizeof(phpMethods) / sizeof(phpMethods[0]));

} */

/*enum saxonTypeEnum
{
        enumNode,
        enumString,
        enumInteger,
        enumDouble,
        enumFloat,
        enumBool,
        enumArrXdmValue
};*/

/*
jobject JNICALL phpNativeCall
        (JNIEnv *env, jobject object, jstring funcName, jobjectArray arguments,
jobjectArray argTypes){ JNIEnv *senv = SaxonProcessor::sxn_environ->env; char
*nativeString = (char *)senv->GetStringUTFChars(funcName, NULL);
    //std::string nativeString2 = std::string(nativeString);
    if(nativeString == NULL) {
        return NULL;
    }
    int nativeStrLen = strlen(nativeString);
    //std::cerr<<"phpNative called. nativeString="<<nativeString<<",
length="<<nativeStrLen<<std::endl; zval function_name; zval retval;

    int argLength = 0;
    zval  *  params;
    if(arguments != NULL) {
        argLength = (int)senv->GetArrayLength(arguments);
        //(*params) = (zval**)malloc(sizeof(zval*) * argLength);
        params =  new zval[argLength];
    } else {
        params = NULL;
    }
    std::map<std::string, saxonTypeEnum> typeMap;
    typeMap["node"] = enumNode;
    typeMap["string"] = enumString;
    typeMap["integer"] = enumInteger;
    typeMap["double"] = enumDouble;
    typeMap["float"] = enumFloat;
    typeMap["boolean"] = enumBool;
    typeMap["[xdmvalue"] = enumArrXdmValue;
    sxnc_value* sresult = (sxnc_value *)malloc(sizeof(sxnc_value));

    SaxonProcessor * nprocessor = new SaxonProcessor(true); //processor object
created for XdmNode jclass xdmValueForCppClass =
lookForClass(SaxonProcessor::sxn_environ->env,
"net/sf/saxon/option/cpp/XdmValueForCpp"); jmethodID procForNodeMID =
SaxonProcessor::sxn_environ->env->GetStaticMethodID(xdmValueForCppClass,
"getProcessor", "(Ljava/lang/Object;)Lnet/sf/saxon/s9api/Processor;");

    for(int i=0; i<argLength;i++){
        jstring argType = (jstring)senv->GetObjectArrayElement(argTypes, i);
        jobject argObj = senv->GetObjectArrayElement(arguments, i);

        const char * str = senv->GetStringUTFChars(argType,NULL);
        const char *stri = NULL;
        double dnumber = 0;
        long lnumber = 0;
        bool bvalue = false;
        float fnumber = 0;



        struct xdmNode_object* vobj;
        zend_object* zend_vobj;
        XdmNode * node = NULL;
        std::map<std::string, saxonTypeEnum>::iterator it = typeMap.find(str);
        if (it != typeMap.end()){
            switch (it->second)
            {
                case enumNode:
                    //std::cerr<<"enumNode path - cp0 -
phpNtiveCall"<<std::endl; if(!nprocessor->proc){ nprocessor->proc =
(jobject)SaxonProcessor::sxn_environ->env->CallStaticObjectMethod(xdmValueForCppClass,
procForNodeMID, argObj);
                    }
                    if (object_init_ex(&params[i], xdmNode_ce) != SUCCESS) {
                        //error

                        //php_error(E_WARNING,"error phpNative xdmNode creation
failed"); break;
                    }
                    node = new XdmNode(argObj);

                    //MAKE_STD_ZVAL(php_argv[i]._val);
                    zend_vobj = Z_OBJ_P(&params[i]);
                    vobj = (xdmNode_object *)((char *)zend_vobj -
XtOffsetOf(xdmNode_object, std)); assert (vobj != NULL);

                    vobj->xdmNode = node;
                    break;
                case enumString:
                    //sresult->xdmvalue = argObj;
                    stri = stringValue(SaxonProcessor::sxn_environ, argObj);
                    //stri = getStringValue(SaxonProcessor::sxn_environ,
*sresult);
                    //stri = senv->GetStringUTFChars((jstring)argObj, 0);
                    //ZVAL_STRING(php_argv[i]._val);
                    ZVAL_STRING(&params[i], stri);
                    break;
                case enumInteger:
                    sresult->xdmvalue = argObj;
                    lnumber = getLongValue(SaxonProcessor::sxn_environ,
*sresult, 0);

                    //MAKE_STD_ZVAL(php_argv[i]._val);
                    ZVAL_LONG(&params[i], lnumber);
                    break;
                case enumDouble:
                    sresult->xdmvalue = argObj;
                    dnumber = getDoubleValue(SaxonProcessor::sxn_environ,
*sresult, 0); //MAKE_STD_ZVAL(php_argv[i]._val); ZVAL_DOUBLE(&params[i],
dnumber); break; case enumFloat: sresult->xdmvalue = argObj; fnumber =
getFloatValue(SaxonProcessor::sxn_environ, *sresult, 0);
                    //MAKE_STD_ZVAL(php_argv[i]._val);
                    ZVAL_DOUBLE(&params[i], fnumber);
                    break;
                case enumBool:
                    sresult->xdmvalue = argObj;
                    bvalue = getBooleanValue(SaxonProcessor::sxn_environ,
*sresult);
                    //MAKE_STD_ZVAL(php_argv[i]._val);
                    ZVAL_BOOL(&params[i], bvalue);
                    break;
                case enumArrXdmValue:
                    //TODO - not currently supported
                    argLength--;
                    break;
            }
            senv->ReleaseStringUTFChars(argType, str);
        }

    }


    free(sresult);


    zval *argvv = NULL;
    zval* callOnObj = NULL;
    //MAKE_STD_ZVAL(function_name);
    //nativeString[nativeStrLen] = '\0';

    ZVAL_STRING(&function_name, nativeString);
    zend_error(E_ERROR, "user-function not implemented in PHP8");
    if(call_user_function_ex(CG(function_table), (zval*)callOnObj,
&function_name, &retval, argLength, params, 0, NULL) != SUCCESS)
    {
        zend_error(E_ERROR, "Function call failed");
    }

    if(Z_TYPE(retval) ==0){
        zend_error(E_ERROR, "Function returned null");
    }

    char * sVal = NULL;
    int len = 0;
    jobject obj = NULL;
//TODO handle XdmValue wrapped object
    const char * objName = NULL;
    xdmNode_object* ooth = NULL;
    zend_object* zend_vobj2;
    bool bVal;
    switch (Z_TYPE_P(&retval)) {
        case IS_FALSE:
                obj= booleanValue(SaxonProcessor::sxn_environ, false);
                break;
        case IS_TRUE:
            obj= booleanValue(SaxonProcessor::sxn_environ, true);
            break;

        case IS_LONG:
            obj= longValue(SaxonProcessor::sxn_environ, Z_LVAL_P(&retval));
            break;
        case IS_STRING:
            sVal = Z_STRVAL_P(&retval);
            len = Z_STRLEN_P(&retval);
            obj = getJavaStringValue(SaxonProcessor::sxn_environ,estrndup(sVal,
len)); break; break; case IS_NULL:

            break;
        case IS_DOUBLE:
            obj = doubleValue(SaxonProcessor::sxn_environ,
(double)Z_DVAL_P(&retval)); break;

        case IS_ARRAY:
            //break;
        case IS_OBJECT:

            objName =ZSTR_VAL(Z_OBJCE_P(&retval)->name);


            if(strcmp(objName, "Saxon\\XdmNode")==0) {

                zend_vobj2 =  Z_OBJ_P(&retval);
                ooth = (xdmNode_object *)((char *)zend_vobj2 -
XtOffsetOf(xdmNode_object, std));

                if(ooth != NULL) {
                    obj = ooth->xdmNode->getUnderlyingValue();
                }
            }
            break;
        default:
            obj = NULL;
            zend_throw_exception(zend_ce_exception, "Unknown type specified in
extension function", 0);
    }

    delete nprocessor;
    zval_ptr_dtor(&retval);
    return obj;
} */

/*     ============== PHP Interface of   XdmValue =============== */
void xdmValue_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

zend_object *xdmValue_create_handler(zend_class_entry *type) {
  zval *tmp;
  zend_object retval;
  xdmValue_object *obj = (xdmValue_object *)ecalloc(
      1, sizeof(xdmValue_object) + zend_object_properties_size(type));
  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xdmValue_object_handlers;

  return &obj->std;
}

void XdmValue_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

PHP_METHOD(XdmValue, __construct) {
  XdmValue *xdmValue = nullptr;
  bool bVal;
  char *sVal;
  int len;
  long iVal;
  double dVal;
  zval *zvalue;

  SaxonProcessor *proc = nullptr;
  // xdmValue_object *obj = (xdmValue_object *) Z_OBJ_P(getThis() TSRMLS_CC);
  /*if (zend_parse_parameters(ZEND_NUM_ARGS() , "z",&zvalue) == SUCCESS) {
      switch (Z_TYPE_P(zvalue)) {
          case IS_FALSE:
          case IS_TRUE:
              bVal = Z_BVAL_P(zvalue);
              xdmValue = new XdmValue(bVal);
              obj = (xdmValue_object *)Z_OBJ_P(getThis() TSRMLS_CC);
              obj->xdmValue = xdmValue;
          break;
          case IS_LONG:
              iVal = Z_LVAL_P(zvalue);
              xdmValue = new XdmValue((int)iVal);
              obj = (xdmValue_object *)Z_OBJ_P(getThis() TSRMLS_CC);
              obj->xdmValue = xdmValue;
          break;
          case IS_STRING:
              sVal = Z_STRVAL_P(zvalue);
              len = Z_STRLEN_P(zvalue);
              xdmValue = new XdmValue("string", sVal);
              obj = (xdmValue_object *)Z_OBJ_P(getThis() TSRMLS_CC);
              obj->xdmValue = xdmValue;
          break;
          case IS_NULL:
              xdmValue = new XdmValue();
              obj = (xdmValue_object *)Z_OBJ_P(getThis() TSRMLS_CC);
              obj->xdmValue = xdmValue;
          break;
          case IS_DOUBLE:
              // TODO: implement this
              //index = (long)Z_DVAL_P(zvalue);
          //break;
          case IS_ARRAY:
          //break;
          case IS_OBJECT:
          //break;
          default:
              obj = nullptr;
              zend_throw_exception(zend_exception_get_default(TSRMLS_C),
  "unknown type specified in XdmValue", 0 TSRMLS_CC);
      }
  }*/
}

PHP_METHOD(XdmValue, __destruct) {

  // std::cerr<<"php_xdmValue  destruct"<<std::endl;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  XdmValue *xdmValue = obj->xdmValue;
  if (xdmValue != nullptr) {
    xdmValue->decrementRefCount();
    if (xdmValue->getRefCount() < 1) {
      delete xdmValue;
      xdmValue = nullptr;
    } /*else {
       xdmValue->decrementRefCount();
   }    */
  }
}

PHP_METHOD(XdmValue, __toString) {
  XdmValue *xdmValue;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  xdmValue = obj->xdmValue;
  if (xdmValue != nullptr) {
    const char *value = xdmValue->toString();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmValue, getHead) {
  XdmValue *xdmValue;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  xdmValue = obj->xdmValue;
  if (xdmValue != nullptr) {
    XdmItem *item = xdmValue->getHead();
    if (item != nullptr) {
      if (object_init_ex(return_value, xdmItem_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        item->incrementRefCount();
        zend_object *oobj = Z_OBJ_P(return_value);
        xdmItem_object *vobj =
            (xdmItem_object *)((char *)oobj - XtOffsetOf(xdmItem_object, std));
        assert(vobj != nullptr);
        vobj->xdmItem = item;
      }
    } else {
      RETURN_NULL();
    }

  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmValue, itemAt) {
  XdmValue *xdmValue;

  long index;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &index) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  xdmValue = obj->xdmValue;
  if (xdmValue != nullptr) {
    XdmItem *item = xdmValue->itemAt((unsigned int)index);

    if (item != nullptr) {

      if (object_init_ex(return_value, xdmItem_ce) != SUCCESS) {
        RETURN_NULL();
        return;
      } else {
        item->incrementRefCount();
        zend_object *oobj = Z_OBJ_P(return_value);
        xdmItem_object *vobj =
            (xdmItem_object *)((char *)oobj - XtOffsetOf(xdmItem_object, std));

        assert(vobj != nullptr);
        vobj->xdmItem = item;
        return;
      }
    }

  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmValue, size) {
  XdmValue *xdmValue;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  xdmValue = obj->xdmValue;
  int sizei = 0;
  if (xdmValue != nullptr) {
    sizei = xdmValue->size();
  }
  RETURN_LONG(sizei);
}

PHP_METHOD(XdmValue, addXdmItem) {
  XdmValue *xdmValue = nullptr;
  zval *oth = nullptr;

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &oth) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmValue_object *obj =
      (xdmValue_object *)((char *)oobj - XtOffsetOf(xdmValue_object, std));
  xdmValue = obj->xdmValue;
  if (xdmValue != nullptr) {
    const char *objName = ZSTR_VAL(Z_OBJCE_P(oth)->name);
    // std::cout<<"test type:"<<(Z_OBJCE_P(oth)->name)<<std::endl;

    if (strcmp(objName, "Saxon\\XdmNode") == 0) {
      zend_object *nobj = Z_OBJ_P(oth);
      xdmNode_object *ooth =
          (xdmNode_object *)((char *)nobj - XtOffsetOf(xdmNode_object, std));
      if (ooth != nullptr) {
        XdmNode *value = ooth->xdmNode;
        if (value != nullptr) {
          xdmValue->addXdmItem((XdmItem *)value);
          value->incrementRefCount();
          return;
        }
      }
    } else if (strcmp(objName, "Saxon\\XdmItem") == 0) {
      zend_object *iobj = Z_OBJ_P(oth);
      xdmItem_object *ooth =
          (xdmItem_object *)((char *)iobj - XtOffsetOf(xdmItem_object, std));
      if (ooth != nullptr) {
        XdmItem *value = ooth->xdmItem;
        if (value != nullptr) {
          xdmValue->addXdmItem(value);
          value->incrementRefCount();
          return;
        }
      }

    } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
      zend_object *aobj = Z_OBJ_P(oth);
      xdmAtomicValue_object *ooth =
          (xdmAtomicValue_object *)((char *)aobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      if (ooth != nullptr) {
        XdmAtomicValue *value = ooth->xdmAtomicValue;
        if (value != nullptr) {
          xdmValue->addXdmItem((XdmItem *)value);
          value->incrementRefCount();
          return;
        }
      }

    } else {
      // TODO exception
    }
  }
}

/*     ============== PHP Interface of   XdmItem =============== */

void xdmItem_free_storage(zend_object *object) { zend_object_std_dtor(object); }

zend_object *xdmItem_create_handler(zend_class_entry *type) {
  zval *tmp;
  zend_object retval;
  xdmItem_object *obj = (xdmItem_object *)ecalloc(
      1, sizeof(xdmItem_object) + zend_object_properties_size(type));

  object_properties_init(&obj->std, type);
  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */

  obj->std.handlers = &xdmItem_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmItem, __construct) {
  XdmItem *xdmItem = nullptr;
  bool bVal;
  char *sVal;
  int len;
  long iVal;
  double dVal;
  zval *zvalue;

  SaxonProcessor *proc = nullptr;

  zval *object = getThis();

  zend_object *zobj = Z_OBJ_P(object);

  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  // saxonProc =  obj->saxonProcessor;
}

void XdmItem_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

PHP_METHOD(XdmItem, __destruct) {
  // std::cerr<<"php_item  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));

  XdmItem *xdmItem = obj->xdmItem;

  if (xdmItem != nullptr) {
    xdmItem->decrementRefCount();
    if (xdmItem->getRefCount() < 1) {
      delete xdmItem;
      xdmItem = nullptr;
    } /*else {
       xdmItem->decrementRefCount();
   }   */
  }
}

PHP_METHOD(XdmItem, getStringValue) {
  XdmItem *xdmItem;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);
  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;

  if (xdmItem != nullptr) {
    const char *value = xdmItem->getStringValue();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    }
  }
  RETURN_NULL();
}

/* {{{ __toString()
   Returns the string content */
PHP_METHOD(XdmItem, __toString) {
  XdmItem *xdmItem;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmItem_object *obj =
      (xdmItem_object *)((char *)oobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;
  if (xdmItem != nullptr) {
    const char *value = xdmItem->toString();
    if (value != nullptr) {
      RETURN_STRING(value);
    } else {
      RETURN_NULL();
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmItem, isAtomic) {
  XdmItem *xdmItem;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;

  if (xdmItem != nullptr) {
    bool isAtomic = xdmItem->isAtomic();
    RETURN_BOOL(isAtomic);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(XdmItem, isNode) {
  XdmItem *xdmItem;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;

  if (xdmItem != nullptr && xdmItem->getType() == XDM_NODE) {
    RETURN_TRUE;
  }
  RETURN_FALSE;
}

PHP_METHOD(XdmItem, getAtomicValue) {
  XdmItem *xdmItem;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;

  if (xdmItem != nullptr) {
    if (!xdmItem->isAtomic()) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmAtomicValue_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {
      xdmItem->incrementRefCount();
      // Z_ADDREF_P(return_value);
      zend_object *zobj = Z_OBJ_P(return_value);
      xdmAtomicValue_object *vobj =
          (xdmAtomicValue_object *)((char *)zobj -
                                    XtOffsetOf(xdmAtomicValue_object, std));
      // struct xdmAtomicValue_object* vobj = (struct xdmAtomicValue_object
      // *)Z_OBJ_P(return_value TSRMLS_CC);
      assert(vobj != nullptr);
      vobj->xdmAtomicValue = (XdmAtomicValue *)xdmItem;
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmItem, getNodeValue) {
  XdmItem *xdmItem;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmItem_object *obj =
      (xdmItem_object *)((char *)zobj - XtOffsetOf(xdmItem_object, std));
  xdmItem = obj->xdmItem;

  if (xdmItem != nullptr) {
    if (xdmItem->isAtomic()) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {
      // struct xdmNode_object* vobj = (struct xdmNode_object
      // *)Z_OBJ_P(return_value TSRMLS_CC);
      xdmItem->incrementRefCount();
      zend_object *zobj = Z_OBJ_P(return_value);
      xdmNode_object *vobj =
          (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
      assert(vobj != nullptr);
      vobj->xdmNode = (XdmNode *)xdmItem;

      return;
    }
  }
  RETURN_NULL();
}

/*     ============== PHP Interface of   XdmNode =============== */

void xdmNode_free_storage(zend_object *object) { zend_object_std_dtor(object); }

zend_object *xdmNode_create_handler(zend_class_entry *type) {
  zval *tmp;
  zend_object retval;
  xdmNode_object *obj = (xdmNode_object *)ecalloc(
      1, sizeof(xdmNode_object) + zend_object_properties_size(type));
  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);
  obj->std.handlers = &xdmNode_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmNode, __construct) {
  // xdmNode_object *obj = (xdmNode_object *) Z_OBJ_P(getThis() TSRMLS_CC);
}

void XdmNode_destroy_storage(zend_object *object) {

  zend_objects_destroy_object(object);
}

PHP_METHOD(XdmNode, __destruct) {
  // std::cerr<<"php_node  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));

  if (obj != nullptr) {
    XdmNode *xdmNode = obj->xdmNode;
    if (xdmNode != nullptr) {
      xdmNode->decrementRefCount();
      if (xdmNode->getRefCount() < 1) {
        delete xdmNode;
        xdmNode = nullptr;
      } /*else {
          xdmNode->decrementRefCount();
          }*/
    }
  }
}

PHP_METHOD(XdmNode, getStringValue) {
  XdmNode *xdmNode;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    const char *value = xdmNode->getStringValue();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    }
  }
  RETURN_NULL();
}

/* {{{ __toString()
   Returns the string content */
PHP_METHOD(XdmNode, __toString) {
  XdmNode *xdmNode;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)oobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;
  if (xdmNode != nullptr) {
    const char *value = xdmNode->toString();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmNode, getTypedValue) {
  XdmNode *xdmNode;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    XdmValue *typedValue = xdmNode->getTypedValue();
    if (typedValue == nullptr) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {
      typedValue->incrementRefCount();

      zend_object *zobj = Z_OBJ_P(return_value);
      xdmValue_object *vobj =
          (xdmValue_object *)((char *)zobj - XtOffsetOf(xdmValue_object, std));
      assert(vobj != nullptr);
      vobj->xdmValue = typedValue;
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getNodeName) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    const char *valueStr = xdmNode->getNodeName();
    if (valueStr != nullptr) {
      // char *str = estrdup(valueStr);
      RETURN_STRING(valueStr);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getLocalName) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    const char *valueStr = xdmNode->getLocalName();
    if (valueStr != nullptr) {
      // char *str = estrdup(valueStr);
      RETURN_STRING(valueStr);
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getBaseURI) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    const char *valueStr = xdmNode->getBaseUri();
    if (valueStr != nullptr) {
      RETURN_STRING(valueStr);
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getNodeKind) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  int nodeKind = 0;
  if (xdmNode != nullptr) {
    nodeKind = xdmNode->getNodeKind();
  }
  RETURN_LONG(nodeKind);
}

PHP_METHOD(XdmNode, isAtomic) { RETURN_FALSE; }

PHP_METHOD(XdmNode, getChildCount) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  int nodeChildCount = 0;
  if (xdmNode != nullptr) {
    nodeChildCount = xdmNode->getChildCount();
  }
  RETURN_LONG(nodeChildCount);
}

PHP_METHOD(XdmNode, getAttributeCount) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  int nodeAttrCount = 0;
  if (xdmNode != nullptr) {
    nodeAttrCount = xdmNode->getAttributeCount();
  }
  RETURN_LONG(nodeAttrCount);
}

PHP_METHOD(XdmNode, getChildNode) {
  long indexi;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &indexi) == FAILURE) {
    RETURN_NULL();
  }

  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    int count = xdmNode->getChildCount();
    if (count == 0) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {

      if (indexi >= 0 && indexi < count) {

        XdmNode *childNode = xdmNode->getChild(indexi, false);

        if (childNode != nullptr) {

          childNode->incrementRefCount();
          zend_object *zobj = Z_OBJ_P(return_value);
          xdmNode_object *vobj =
              (xdmNode_object *)((char *)zobj -
                                 XtOffsetOf(xdmNode_object, std));
          assert(vobj != nullptr);
          vobj->xdmNode = childNode;
          return;
        }
      }
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getChildren) {
  zval retval;
  /*long indexi;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &indexi) == FAILURE) {
    RETURN_NULL();
  } */

  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    int count = xdmNode->getChildCount();
    if (count > 0) {

      XdmNode **childNodes = xdmNode->getChildren(false);

      if (childNodes != nullptr) {
        ///// creating PHP array
        zend_array *ret = zend_new_array(count);
        zend_ulong idx = 0;

        for (int i = 0; i < count; i++) {
          XdmNode *cNode = childNodes[i];
          cNode->incrementRefCount();
          if (object_init_ex(&retval, xdmNode_ce) != SUCCESS) {
            RETURN_NULL();
          }
          zend_object *zobj = Z_OBJ_P(&retval);
          xdmNode_object *vobj =
              (xdmNode_object *)((char *)zobj -
                                 XtOffsetOf(xdmNode_object, std));
          assert(vobj != nullptr);
          vobj->xdmNode = cNode;
          zend_hash_index_add(ret, idx, &retval);
          idx++;
        }
        delete[] childNodes;
        RETVAL_ARR(ret);
        return;
      }
      /// end of creating PHP array
    }
  }

  RETURN_NULL();
}

PHP_METHOD(XdmNode, axisNodes) {
  long axisValue;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &axisValue) == FAILURE) {
    RETURN_NULL();
  }

  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    int count = xdmNode->getChildCount();
    if (count == 0) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {

      if (axisValue > 0) {

        XdmNode **nodes =
            xdmNode->axisNodes(xdmNode->convertEnumXdmAxis(axisValue));
        int axisCount = xdmNode->axisNodeCount();

        if (axisCount > 0 && nodes != nullptr) {
          XdmValue *resultValue = new XdmValue();
          for (int i = 0; i < axisCount; i++) {
            nodes[i]->incrementRefCount();
            resultValue->addXdmItem(nodes[i]);
          }
          zend_object *zobj = Z_OBJ_P(return_value);
          xdmValue_object *vobj =
              (xdmValue_object *)((char *)zobj -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = resultValue;
          return;
        }
      }
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getParent) {
  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    XdmNode *parent = xdmNode->getParent();
    if (parent == nullptr) {
      RETURN_NULL();
      return;
    }
    if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
      RETURN_NULL();
      return;
    } else {
      parent->incrementRefCount();
      // struct xdmNode_object* vobj = (struct xdmNode_object
      // *)Z_OBJ_P(return_value TSRMLS_CC);
      zend_object *zobj = Z_OBJ_P(return_value);
      xdmNode_object *vobj =
          (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
      assert(vobj != nullptr);
      vobj->xdmNode = parent;
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getAttributeNode) {
  zval *retval;
  long indexi = 0;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &indexi) == FAILURE) {
    RETURN_NULL();
  }

  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    int count = xdmNode->getAttributeCount();
    if (count > 0 && indexi < count) {

      XdmNode **attNodes = xdmNode->getAttributeNodes();
      XdmNode *attNode = attNodes[indexi];

      attNode->incrementRefCount();
      if (object_init_ex(return_value, xdmNode_ce) != SUCCESS) {
        RETURN_NULL();
      }
      zend_object *zobj = Z_OBJ_P(return_value);
      xdmNode_object *vobj =
          (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
      assert(vobj != nullptr);
      vobj->xdmNode = attNode;
      for (int i = 0; i < count; i++) {
        if (indexi != i) {
          delete attNodes[i];
        }
      }
      delete[] attNodes;
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getAttributeNodes) {
  zval retval;
  /*if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &indexi) == FAILURE) {
    RETURN_NULL();
  }*/

  XdmNode *xdmNode;
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;

  if (xdmNode != nullptr) {
    int count = xdmNode->getAttributeCount();
    if (count > 0) {
      ///// creating PHP array
      XdmNode **attNodes = xdmNode->getAttributeNodes();
      if (attNodes != nullptr) {
        zend_array *ret = zend_new_array(count);
        zend_ulong idx = 0;

        for (int i = 0; i < count; i++) {
          XdmNode *attNode = attNodes[i];
          attNode->incrementRefCount();
          if (object_init_ex(&retval, xdmNode_ce) != SUCCESS) {
            RETURN_NULL();
          }
          zend_object *zobj = Z_OBJ_P(&retval);
          xdmNode_object *vobj =
              (xdmNode_object *)((char *)zobj -
                                 XtOffsetOf(xdmNode_object, std));
          assert(vobj != nullptr);
          vobj->xdmNode = attNode;
          zend_hash_index_add(ret, idx, &retval);
          idx++;
        }
        delete[] attNodes;
        RETVAL_ARR(ret);
        return;
      }
      /// end of creating PHP array
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmNode, getAttributeValue) {
  char *name;
  long len1;
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &name, &len1) == FAILURE) {
    RETURN_NULL();
  }
  XdmNode *xdmNode; // c++ object
  zend_object *zobj = Z_OBJ_P(getThis());
  xdmNode_object *obj =
      (xdmNode_object *)((char *)zobj - XtOffsetOf(xdmNode_object, std));
  xdmNode = obj->xdmNode;
  if (xdmNode != nullptr && name != nullptr) {

    const char *value = xdmNode->getAttributeValue(name);
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    }
  }
  RETURN_NULL();
}

/*     ============== PHP Interface of   XdmAtomicValue =============== */

void xdmAtomicValue_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

void XdmAtomicValue_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

zend_object *xdmAtomicValue_create_handler(zend_class_entry *type) {

  xdmAtomicValue_object *obj = (xdmAtomicValue_object *)ecalloc(
      1, sizeof(xdmAtomicValue_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xdmAtomicValue_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmAtomicValue, __construct) {
  /* XdmAtomicValue *xdmValue = nullptr;
   bool bVal;
   char * sVal;
   int len;
   long iVal;
   double dVal;
   zval *zvalue;*/

  // xdmAtomicValue_object *obj = (xdmAtomicValue_object *) Z_OBJ_P(getThis()
  // TSRMLS_CC);
}

PHP_METHOD(XdmAtomicValue, __destruct) {
  // std::cerr<<"php_atomicValue  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));

  XdmAtomicValue *xdmValue = obj->xdmAtomicValue;
  if (xdmValue != nullptr) {
    xdmValue->decrementRefCount();
    if (xdmValue->getRefCount() < 1) {
      delete xdmValue;
      xdmValue = nullptr;
    } else {
      // xdmValue->decrementRefCount();
    }
  }
}

PHP_METHOD(XdmAtomicValue, getBooleanValue) {
  XdmAtomicValue *xdmAtomicValue;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;

  bool resultb = false;
  if (xdmAtomicValue != nullptr) {
    resultb = xdmAtomicValue->getBooleanValue();
  }
  RETURN_BOOL(resultb);
}

PHP_METHOD(XdmAtomicValue, getDoubleValue) {
  XdmAtomicValue *xdmAtomicValue;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;

  double resultb = 0;
  if (xdmAtomicValue != nullptr) {
    resultb = xdmAtomicValue->getDoubleValue();
  }
  RETURN_DOUBLE(resultb);
}

PHP_METHOD(XdmAtomicValue, getLongValue) {
  XdmAtomicValue *xdmAtomicValue;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;

  long result = 0;
  if (xdmAtomicValue != nullptr) {
    result = xdmAtomicValue->getLongValue();
  }
  RETURN_LONG(result);
}

PHP_METHOD(XdmAtomicValue, getStringValue) {
  XdmAtomicValue *xdmAtomicValue;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;

  SaxonProcessor *saxonProc;
  zend_object *zzobj = Z_OBJ_P(getThis());

  saxonProcessor_object *obj2 =
      (saxonProcessor_object *)((char *)zzobj -
                                XtOffsetOf(xdmAtomicValue_object, std));

  saxonProc = obj2->saxonProcessor;

  if (xdmAtomicValue != nullptr) {
    const char *value = xdmAtomicValue->getStringValue();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    }
  }
  RETURN_NULL();
}

PHP_METHOD(XdmAtomicValue, getPrimitiveTypeName) {
  XdmAtomicValue *xdmAtomicValue;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)zobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;

  if (xdmAtomicValue != nullptr) {
    const char *valueStr = xdmAtomicValue->getPrimitiveTypeName();
    if (valueStr != nullptr) {
      // char *str = estrdup(valueStr);
      RETURN_STRING(valueStr);
    }
  }
  RETURN_NULL();
}

/* {{{ __toString()
   Returns the string content */
PHP_METHOD(XdmAtomicValue, __toString) {
  XdmAtomicValue *xdmAtomicValue;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmAtomicValue_object *obj =
      (xdmAtomicValue_object *)((char *)oobj -
                                XtOffsetOf(xdmAtomicValue_object, std));
  xdmAtomicValue = obj->xdmAtomicValue;
  if (xdmAtomicValue != nullptr) {
    const char *value = xdmAtomicValue->getStringValue();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmAtomicValue, isAtomic) { RETURN_TRUE; }

/*     ============== PHP Interface of   XdmFunctionItem =============== */

void xdmFunctionItem_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

void XdmFunctionItem_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

zend_object *xdmFunctionItem_create_handler(zend_class_entry *type) {

  xdmFunctionItem_object *obj = (xdmFunctionItem_object *)ecalloc(
      1, sizeof(xdmFunctionItem_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xdmFunctionItem_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmFunctionItem, __construct) {
  /* XdmAtomicValue *xdmValue = nullptr;
   bool bVal;
   char * sVal;
   int len;
   long iVal;
   double dVal;
   zval *zvalue;*/

  // xdmAtomicValue_object *obj = (xdmAtomicValue_object *) Z_OBJ_P(getThis()
  // TSRMLS_CC);
}

PHP_METHOD(XdmFunctionItem, __destruct) {
  // std::cerr<<"php_atomicValue  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)zobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));

  XdmFunctionItem *xdmValue = obj->xdmFunctionItem;
  if (xdmValue != nullptr) {
    xdmValue->decrementRefCount();
    if (xdmValue->getRefCount() < 1) {
      delete xdmValue;
      xdmValue = nullptr;
    } else {
      // xdmValue->decrementRefCount();
    }
  }
}

PHP_METHOD(XdmFunctionItem, __toString) {
  XdmFunctionItem *xdmFunctionItem;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)oobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));
  xdmFunctionItem = obj->xdmFunctionItem;
  if (xdmFunctionItem != nullptr) {
    const char *value = xdmFunctionItem->toString();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmFunctionItem, getName) {
  XdmFunctionItem *xdmFunctionItem;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)oobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));
  xdmFunctionItem = obj->xdmFunctionItem;
  if (xdmFunctionItem != nullptr) {
    const char *value = xdmFunctionItem->getName();
    if (value != nullptr) {
      RETURN_STRING(value);
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmFunctionItem, getArity) {
  XdmFunctionItem *xdmFunctionItem;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)oobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));
  xdmFunctionItem = obj->xdmFunctionItem;
  if (xdmFunctionItem != nullptr) {
    int value = xdmFunctionItem->getArity();
    RETURN_LONG(value);
  } else {
    RETURN_LONG(-1);
  }
}

PHP_METHOD(XdmFunctionItem, getSystemFunction) {

  XdmFunctionItem *xdmFunctionItem;
  char *functionName = nullptr;
  zval *proc_zval;
  SaxonProcessor *proc = nullptr;
  size_t len1;

  long arity;

  if (ZEND_NUM_ARGS() != 3) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "zsl", &proc_zval, &functionName,
                            &len1, &arity) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)oobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));
  xdmFunctionItem = obj->xdmFunctionItem;

  if (xdmFunctionItem != nullptr) {
    if (Z_TYPE_P(proc_zval) == IS_NULL) {
    }
    zend_object *ooth = Z_OBJ_P(proc_zval);
    saxonProcessor_object *nobj =
        (saxonProcessor_object *)((char *)ooth -
                                  XtOffsetOf(saxonProcessor_object, std));
    if (nobj != nullptr) {
      proc = (SaxonProcessor *)nobj->saxonProcessor;
      XdmFunctionItem *result =
          xdmFunctionItem->getSystemFunction(proc, functionName, arity);

      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmFunctionItem_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *ooth = Z_OBJ_P(return_value);

          xdmFunctionItem_object *vobj =
              (xdmFunctionItem_object *)((char *)ooth -
                                         XtOffsetOf(xdmFunctionItem_object,
                                                    std));
          assert(vobj != nullptr);
          vobj->xdmFunctionItem = result;
          return;
        }
      }
    }
  }

  RETURN_NULL();
}

PHP_METHOD(XdmFunctionItem, call) {
  XdmFunctionItem *xdmFunctionItem;
  char *functionName = nullptr;
  zval *proc_zval;
  SaxonProcessor *proc = nullptr;
  HashTable *arr_hash;

  zval *arguments_zval;
  zval *val;
  long num_key;
  XdmValue **arguments = nullptr;
  int argument_length = 0;
  zend_string *key;

  if (ZEND_NUM_ARGS() != 3) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "za", &proc_zval,
                            &arguments_zval) == FAILURE) {
    RETURN_NULL();
  }
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmFunctionItem_object *obj =
      (xdmFunctionItem_object *)((char *)oobj -
                                 XtOffsetOf(xdmFunctionItem_object, std));
  xdmFunctionItem = obj->xdmFunctionItem;

  if (xdmFunctionItem != nullptr) {

    zend_object *ooth = Z_OBJ_P(proc_zval);
    saxonProcessor_object *nobj =
        (saxonProcessor_object *)((char *)ooth -
                                  XtOffsetOf(saxonProcessor_object, std));
    if (nobj != nullptr) {
      proc = (SaxonProcessor *)nobj->saxonProcessor;

      arr_hash = Z_ARRVAL_P(arguments_zval);
      argument_length = zend_hash_num_elements(arr_hash);

      arguments = new XdmValue *[argument_length];
      ZEND_HASH_FOREACH_KEY_VAL(arr_hash, num_key, key, val) {
        if (Z_TYPE_P(val) != IS_NULL) {
          const char *objName = ZSTR_VAL(Z_OBJCE_P(val)->name);

          if (strcmp(objName, "Saxon\\XdmNode") == 0) {
            zend_object *ooth = Z_OBJ_P(val);
            xdmNode_object *nobj =
                (xdmNode_object *)((char *)ooth -
                                   XtOffsetOf(xdmNode_object, std));
            if (nobj != nullptr) {
              XdmValue *value = (XdmValue *)nobj->xdmNode;
              arguments[num_key] = value;
            }
          } else if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
            zend_object *ooth = Z_OBJ_P(val);
            xdmAtomicValue_object *nobj =
                (xdmAtomicValue_object *)((char *)ooth -
                                          XtOffsetOf(xdmAtomicValue_object,
                                                     std));
            if (nobj != nullptr) {
              XdmValue *value = (XdmValue *)nobj->xdmAtomicValue;
              arguments[num_key] = value;
            }
          } else if (strcmp(objName, "Saxon\\XdmValue") == 0) {
            zend_object *ooth = Z_OBJ_P(val);
            xdmValue_object *nobj =
                (xdmValue_object *)((char *)ooth -
                                    XtOffsetOf(xdmValue_object, std));
            if (nobj != nullptr) {
              XdmValue *value = nobj->xdmValue;
              arguments[num_key] = value;
            }
          } else { // TODO error warning}
          }
        } else {
          // TODO error warning
        }
      }
      ZEND_HASH_FOREACH_END();

      XdmValue *result =
          xdmFunctionItem->call(proc, arguments, argument_length);

      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *ooth = Z_OBJ_P(return_value);

          xdmValue_object *vobj =
              (xdmValue_object *)((char *)ooth -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = result;
          return;
        }
      }
    }
  }

  RETURN_NULL();
}

/*     ============== PHP Interface of   XdmMap =============== */

void xdmMap_free_storage(zend_object *object) { zend_object_std_dtor(object); }

void XdmMap_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

zend_object *xdmMap_create_handler(zend_class_entry *type) {

  xdmMap_object *obj = (xdmMap_object *)ecalloc(
      1, sizeof(xdmMap_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xdmMap_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmMap, __construct) {
  /* XdmAtomicValue *xdmValue = nullptr;
   bool bVal;
   char * sVal;
   int len;
   long iVal;
   double dVal;
   zval *zvalue;*/

  // xdmAtomicValue_object *obj = (xdmAtomicValue_object *) Z_OBJ_P(getThis()
  // TSRMLS_CC);
}

PHP_METHOD(XdmMap, __destruct) {
  // std::cerr<<"php_atomicValue  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmMap_object *obj =
      (xdmMap_object *)((char *)zobj - XtOffsetOf(xdmMap_object, std));

  XdmMap *xdmmap = obj->xdmMap;
  if (xdmmap != nullptr) {
    xdmmap->decrementRefCount();
    if (xdmmap->getRefCount() < 1) {
      delete xdmmap;
      xdmmap = nullptr;
    } else {
      // xdmValue->decrementRefCount();
    }
  }
}

PHP_METHOD(XdmMap, __toString) {
  XdmMap *xdmMap;
  // zend_string *str;

  if (zend_parse_parameters_none() == FAILURE) {
    RETURN_THROWS();
  }
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {
    const char *value = xdmMap->toString();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_EMPTY_STRING();
    }
  } else {
    RETURN_EMPTY_STRING();
  }
}

PHP_METHOD(XdmMap, mapSize) {
  XdmMap *xdmMap;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {
    int value = xdmMap->mapSize();
    RETURN_LONG(value);
  } else {
    RETURN_LONG(-1);
  }
}

PHP_METHOD(XdmMap, get) {
  XdmMap *xdmMap = nullptr;
  XdmValue *result = nullptr;
  zval *key_zval = nullptr;
  long lkey = -1;
  char *skey = nullptr;
  size_t len1;

  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }
  if (zend_parse_parameters(ZEND_NUM_ARGS(), "s", &skey, &len1) == FAILURE) {
    if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &key_zval) == FAILURE) {

      if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &lkey) == FAILURE) {

        RETURN_NULL();
      }
    }
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {
    if (key_zval != nullptr) {

      const char *objName = ZSTR_VAL(Z_OBJCE_P(key_zval)->name);

      if (strcmp(objName, "Saxon\\XdmAtomicValue") == 0) {
        zend_object *nobj = Z_OBJ_P(key_zval);

        xdmAtomicValue_object *ooth =
            (xdmAtomicValue_object *)((char *)nobj -
                                      XtOffsetOf(xdmAtomicValue_object, std));
        if (ooth != nullptr) {

          XdmAtomicValue *value = ooth->xdmAtomicValue;

          if (value != nullptr) {

            result = xdmMap->get(value); // call back to C++ API
            if (result != nullptr) {
              result->incrementRefCount();
              if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
                RETURN_NULL();
              } else {
                zend_object *vvobj = Z_OBJ_P(return_value);
                xdmValue_object *vobj =
                    (xdmValue_object *)((char *)vvobj -
                                        XtOffsetOf(xdmValue_object, std));
                assert(vobj != nullptr);
                vobj->xdmValue = result;
                return;
              }
            } else {
              RETURN_NULL();
            }
          }
        }
      } else {
        RETURN_NULL();
      }

    } else if (lkey != -1) {
      result = xdmMap->get(lkey);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmValue_object *vobj =
              (xdmValue_object *)((char *)vvobj -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = result;
          return;
        }
      } else {
        RETURN_NULL();
      }

    } else if (skey != nullptr) {
      result = xdmMap->get(skey);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmValue_object *vobj =
              (xdmValue_object *)((char *)vvobj -
                                  XtOffsetOf(xdmValue_object, std));
          assert(vobj != nullptr);
          vobj->xdmValue = result;
          return;
        }
      } else {
        RETURN_NULL();
      }

    } else {

      RETURN_NULL();
    }
  }
}

PHP_METHOD(XdmMap, put) {
  XdmMap *xdmMap;
  zval *key_zval = nullptr;
  zval *value_zval = nullptr;
  long lkey = -1;
  char *skey = nullptr;
  size_t len1;

  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "zz", &key_zval, &value_zval) ==
      FAILURE) {
    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {
    zend_object *kobj = Z_OBJ_P(key_zval);
    XdmAtomicValue *c_key = nullptr;
    XdmValue *c_value = nullptr;
    xdmAtomicValue_object *ooth =
        (xdmAtomicValue_object *)((char *)kobj -
                                  XtOffsetOf(xdmAtomicValue_object, std));
    if (ooth != nullptr) {
      c_key = ooth->xdmAtomicValue;
    }

    zend_object *vobj = Z_OBJ_P(value_zval);

    xdmAtomicValue_object *vooth =
        (xdmAtomicValue_object *)((char *)vobj -
                                  XtOffsetOf(xdmAtomicValue_object, std));
    if (vooth != nullptr) {
      c_value = vooth->xdmAtomicValue;
    }

    if (c_value != nullptr && c_key != nullptr) {
      XdmMap *result = xdmMap->put(c_key, c_value);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmMap_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmMap_object *vobj =
              (xdmMap_object *)((char *)vvobj - XtOffsetOf(xdmMap_object, std));
          assert(vobj != nullptr);
          vobj->xdmMap = result;
          return;
        }
      }
    }

  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmMap, isEmpty) {
  XdmMap *xdmMap;
  if (ZEND_NUM_ARGS() > 0) {
    WRONG_PARAM_COUNT;
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {
    bool result = xdmMap->isEmpty();
    RETURN_BOOL(result);
  }
  RETURN_BOOL(false);
}

PHP_METHOD(XdmMap, containsKey) {
  XdmMap *xdmMap;
  zval *key_zval = nullptr;
  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", &key_zval) == FAILURE) {
    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmMap_object *obj =
      (xdmMap_object *)((char *)oobj - XtOffsetOf(xdmMap_object, std));
  xdmMap = obj->xdmMap;
  if (xdmMap != nullptr) {

    zend_object *kobj = Z_OBJ_P(key_zval);
    XdmAtomicValue *c_key = nullptr;
    xdmAtomicValue_object *ooth =
        (xdmAtomicValue_object *)((char *)kobj -
                                  XtOffsetOf(xdmAtomicValue_object, std));
    if (ooth != nullptr) {
      c_key = ooth->xdmAtomicValue;
      bool result = xdmMap->containsKey(c_key);
      RETURN_BOOL(result);
    }
  }
  RETURN_BOOL(false);
}
/*
TODO implement these methods
*/
PHP_METHOD(XdmMap, keys) {}

/*PHP_METHOD(XdmMap, values)
{


} */

/*     ============== PHP Interface of   XdmArray =============== */

void xdmArray_free_storage(zend_object *object) {
  zend_object_std_dtor(object);
}

void XdmArray_destroy_storage(zend_object *object) {
  zend_objects_destroy_object(object);
}

zend_object *xdmArray_create_handler(zend_class_entry *type) {

  xdmArray_object *obj = (xdmArray_object *)ecalloc(
      1, sizeof(xdmArray_object) + zend_object_properties_size(type));

  zend_object_std_init(&obj->std,
                       type); /* take care of the zend_object also ! */
  object_properties_init(&obj->std, type);

  obj->std.handlers = &xdmArray_object_handlers;

  return &obj->std;
}

PHP_METHOD(XdmArray, __construct) {
  /* XdmAtomicValue *xdmValue = nullptr;
   bool bVal;
   char * sVal;
   int len;
   long iVal;
   double dVal;
   zval *zvalue;*/

  // xdmAtomicValue_object *obj = (xdmAtomicValue_object *) Z_OBJ_P(getThis()
  // TSRMLS_CC);
}

PHP_METHOD(XdmArray, __destruct) {
  // std::cerr<<"php_atomicValue  destruct"<<std::endl;
  zval *object = getThis();
  zend_object *zobj = Z_OBJ_P(object);

  xdmArray_object *obj =
      (xdmArray_object *)((char *)zobj - XtOffsetOf(xdmArray_object, std));

  XdmArray *xdmArray = obj->xdmArray;
  if (xdmArray != nullptr) {
    xdmArray->decrementRefCount();
    if (xdmArray->getRefCount() < 1) {
      delete xdmArray;
      xdmArray = nullptr;
    } else {
      // xdmValue->decrementRefCount();
    }
  }
}

PHP_METHOD(XdmArray, __toString) {
  XdmArray *xdmArray;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (xdmArray != nullptr) {
    const char *value = xdmArray->toString();
    if (value != nullptr) {
      RETVAL_STRING(value);
      SaxonProcessor::deleteString(value);
      return;
    } else {
      RETURN_NULL();
    }
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(XdmArray, get) {
  XdmArray *xdmArray = nullptr;
  long lkey = -1;

  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "l", &lkey) == FAILURE) {

    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (xdmArray != nullptr && lkey != -1) {
    XdmValue *result = xdmArray->get(lkey);
    if (result != nullptr) {
      result->incrementRefCount();
      if (object_init_ex(return_value, xdmValue_ce) != SUCCESS) {
        RETURN_NULL();
      } else {
        zend_object *vvobj = Z_OBJ_P(return_value);
        xdmValue_object *vobj =
            (xdmValue_object *)((char *)vvobj -
                                XtOffsetOf(xdmValue_object, std));
        assert(vobj != nullptr);
        vobj->xdmValue = result;
        return;
      }
    } else {
      RETURN_NULL();
    }

  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(XdmArray, put) {
  XdmArray *xdmArray;
  long lkey = -1;
  zval *value_zval = nullptr;

  if (ZEND_NUM_ARGS() != 2) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "lz", &lkey, value_zval) ==
      FAILURE) {

    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (lkey != -1 && value_zval != nullptr) {
    zend_object *vobj = Z_OBJ_P(value_zval);

    xdmValue_object *vooth =
        (xdmValue_object *)((char *)vobj - XtOffsetOf(xdmValue_object, std));
    if (vooth != nullptr) {
      XdmValue *c_value = vooth->xdmValue;

      XdmArray *result = xdmArray->put(lkey, c_value);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmArray_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmArray_object *vobj =
              (xdmArray_object *)((char *)vvobj -
                                  XtOffsetOf(xdmArray_object, std));
          assert(vobj != nullptr);
          vobj->xdmArray = result;
          return;
        }
      } else {
        RETURN_NULL();
      }
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(XdmArray, addMember) {
  XdmArray *xdmArray;
  long lkey = -1;
  zval *value_zval = nullptr;

  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", value_zval) == FAILURE) {

    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (lkey != -1 && value_zval != nullptr) {
    zend_object *vobj = Z_OBJ_P(value_zval);

    xdmValue_object *vooth =
        (xdmValue_object *)((char *)vobj - XtOffsetOf(xdmValue_object, std));
    if (vooth != nullptr) {
      XdmValue *c_value = vooth->xdmValue;

      XdmArray *result = xdmArray->put(lkey, c_value);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmArray_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmArray_object *vobj =
              (xdmArray_object *)((char *)vvobj -
                                  XtOffsetOf(xdmArray_object, std));
          assert(vobj != nullptr);
          vobj->xdmArray = result;
          return;
        }
      } else {
        RETURN_NULL();
      }
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(XdmArray, concat) {
  XdmArray *xdmArray;
  long lkey = -1;
  zval *value_zval = nullptr;

  if (ZEND_NUM_ARGS() != 1) {
    WRONG_PARAM_COUNT;
  }

  if (zend_parse_parameters(ZEND_NUM_ARGS(), "z", value_zval) == FAILURE) {

    RETURN_NULL();
  }

  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (lkey != -1 && value_zval != nullptr) {
    zend_object *vobj = Z_OBJ_P(value_zval);

    xdmArray_object *vooth =
        (xdmArray_object *)((char *)vobj - XtOffsetOf(xdmArray_object, std));
    if (vooth != nullptr) {
      XdmArray *c_value = vooth->xdmArray;

      XdmArray *result = xdmArray->concat(c_value);
      if (result != nullptr) {
        result->incrementRefCount();
        if (object_init_ex(return_value, xdmArray_ce) != SUCCESS) {
          RETURN_NULL();
        } else {
          zend_object *vvobj = Z_OBJ_P(return_value);
          xdmArray_object *vobj =
              (xdmArray_object *)((char *)vvobj -
                                  XtOffsetOf(xdmArray_object, std));
          assert(vobj != nullptr);
          vobj->xdmArray = result;
          return;
        }
      } else {
        RETURN_NULL();
      }
    }
  } else {

    RETURN_NULL();
  }
}

PHP_METHOD(XdmArray, getArity) {
  XdmArray *xdmArray = nullptr;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (xdmArray != nullptr) {
    int value = xdmArray->getArity();
    RETURN_LONG(value);
  } else {
    RETURN_LONG(-1);
  }
}

PHP_METHOD(XdmArray, arrayLength) {
  XdmArray *xdmArray = nullptr;
  zend_object *oobj = Z_OBJ_P(getThis());
  xdmArray_object *obj =
      (xdmArray_object *)((char *)oobj - XtOffsetOf(xdmArray_object, std));
  xdmArray = obj->xdmArray;
  if (xdmArray != nullptr) {
    int value = xdmArray->arrayLength();
    RETURN_LONG(value);
  } else {
    RETURN_LONG(-1);
  }
}

/*PHP_ME(XdmArray,  values,      nullptr, ZEND_ACC_PUBLIC) */

/*void php_saxonc_initialize(void){
   if(SaxonProcessor::jvmCreatedCPP == 0){
        SaxonProcessor::jvmCreatedCPP=1;
        SaxonProcessor::sxn_environ= (sxnc_environment
*)malloc(sizeof(sxnc_environment));

    SaxonProcessor::sxn_environ->myDllHandle = loadDefaultDll ();

    initDefaultJavaRT (SaxonProcessor::sxn_environ);
    }
} */

// =============================================================

zend_function_entry SaxonProcessor_methods[] = {
    PHP_ME(SaxonProcessor, __construct, arginfo_saxonproc_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR) PHP_ME(SaxonProcessor, __destruct,
                                                   arginfo_saxonc_destruct,
                                                   ZEND_ACC_PUBLIC)
        PHP_ME(SaxonProcessor, createAtomicValue,
               arginfo_saxonc_createAtomicValue,
               ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor, parseXmlFromString,
                                       arginfo_saxonc_parseXmlFromString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(SaxonProcessor, parseXmlFromFile,
                   arginfo_saxonc_parseXmlFromFile,
                   ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor, parseXmlFromUri,
                                           arginfo_saxonc_parseXmlFromUri,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(SaxonProcessor, setcwd, arginfo_saxonc_setcwd,
                       ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor,
                                               newXPathProcessor,
                                               arginfo_saxonc_newXPathProcessor,
                                               ZEND_ACC_PUBLIC)
                    PHP_ME(
                        SaxonProcessor, newDocumentBuilder,
                        arginfo_saxonc_newDocumentBuilder,
                        ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor,
                                                newXslt30Processor,
                                                arginfo_saxonc_newXslt30Processor,
                                                ZEND_ACC_PUBLIC)
                        PHP_ME(SaxonProcessor, newXQueryProcessor,
                               arginfo_saxonc_newXQueryProcessor,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(
                                SaxonProcessor, newSchemaValidator,
                                arginfo_saxonc_newSchemaValidator,
                                ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor,
                                                        setCatalog,
                                                        arginfo_saxonc_setCatalog,
                                                        ZEND_ACC_PUBLIC)
                                PHP_ME(SaxonProcessor, setCatalogFiles,
                                       arginfo_saxonc_setCatalogFiles,
                                       ZEND_ACC_PUBLIC)
                                    PHP_ME(
                                        SaxonProcessor,
                                        setConfigurationProperty,
                                        arginfo_saxonc_setConfigurationProperty,
                                        ZEND_ACC_PUBLIC)
    // PHP_ME(SaxonProcessor,  registerPHPFunctions,      nullptr,
    // ZEND_ACC_PUBLIC)
    PHP_ME(SaxonProcessor, version, arginfo_saxonc_version, ZEND_ACC_PUBLIC)
        PHP_ME(SaxonProcessor, isSchemaAware, arginfo_saxonc_isSchemaAware,
               ZEND_ACC_PUBLIC) PHP_ME(SaxonProcessor, EQNameToClarkName,
                                       arginfo_saxonc_EQNameToClarkName,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(SaxonProcessor, clarkNameToEQName,
                   arginfo_saxonc_clarkNameToEQName, ZEND_ACC_PUBLIC)
                PHP_ME(SaxonProcessor, exceptionOccurred,
                       arginfo_saxonc_isSchemaAware, ZEND_ACC_PUBLIC)
                    PHP_ME(SaxonProcessor, getErrorMessage,
                           arginfo_saxonc_exceptionOccurred, ZEND_ACC_PUBLIC)
                        PHP_ME(SaxonProcessor, exceptionClear,
                               arginfo_saxonc_exceptionClear, ZEND_ACC_PUBLIC)
                            PHP_ME(SaxonProcessor, release,
                                   arginfo_saxonc_release,
                                   ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

zend_function_entry xdmValue_methods[] = {
    PHP_ME(XdmValue, __construct, arginfo_saxonc_xdmval_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmValue, __destruct, arginfo_saxonc_xdmval_destruct,
               ZEND_ACC_PUBLIC)
            PHP_ME(XdmValue, __toString, arginfo_saxonc_xdmval_toString,
                   ZEND_ACC_PUBLIC)
                PHP_ME(XdmValue, getHead, arginfo_saxonc_xdmval_getHead,
                       ZEND_ACC_PUBLIC)
                    PHP_ME(XdmValue, itemAt, arginfo_saxonc_xdmval_itemAt,
                           ZEND_ACC_PUBLIC)
                        PHP_ME(XdmValue, size, arginfo_saxonc_xdmval_size,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(XdmValue, addXdmItem,
                                   arginfo_saxonc_xdmval_addXdmItem,
                                   ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

zend_function_entry xdmItem_methods[] = {
    PHP_ME(XdmItem, __construct, arginfo_saxonc_xdmitem_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmItem, __destruct, arginfo_saxonc_xdmitem_destruct,
               ZEND_ACC_PUBLIC) PHP_ME(XdmItem, __toString,
                                       arginfo_saxonc_xdmitem_toString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmItem, getStringValue,
                   arginfo_saxonc_xdmitem_getStringValue, ZEND_ACC_PUBLIC)
                PHP_ME(XdmItem, isAtomic, arginfo_saxonc_xdmitem_isAtomic,
                       ZEND_ACC_PUBLIC)
                    PHP_ME(XdmItem, isNode, arginfo_saxonc_xdmitem_isNode,
                           ZEND_ACC_PUBLIC)
                        PHP_ME(XdmItem, getAtomicValue,
                               arginfo_saxonc_xdmitem_getAtomicValue,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(XdmItem, getNodeValue,
                                   arginfo_saxonc_xdmitem_getNodeValue,
                                   ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

zend_function_entry xdmNode_methods[] = {
    PHP_ME(XdmNode, __construct, arginfo_saxonc_xdmnode_construct,
           ZEND_ACC_PUBLIC |
               ZEND_ACC_CTOR) PHP_ME(XdmNode, __destruct,
                                     arginfo_saxonc_xdmnode_destruct,
                                     ZEND_ACC_PUBLIC)
        PHP_ME(XdmNode, __toString, arginfo_saxonc_xdmnode_toString,
               ZEND_ACC_PUBLIC) PHP_ME(XdmNode, getBaseURI,
                                       arginfo_saxonc_xdmnode_getBaseURI,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmNode, getStringValue,
                   arginfo_saxonc_xdmnode_getStringValue,
                   ZEND_ACC_PUBLIC) PHP_ME(XdmNode, getNodeKind,
                                           arginfo_saxonc_xdmnode_getNodeKind,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(
                    XdmNode, getNodeName, arginfo_saxonc_xdmnode_getNodeName,
                    ZEND_ACC_PUBLIC) PHP_ME(XdmNode, getLocalName,
                                            arginfo_saxonc_xdmnode_getLocalName,
                                            ZEND_ACC_PUBLIC)
                    PHP_ME(
                        XdmNode, isAtomic, arginfo_saxonc_xdmnode_isAtomic,
                        ZEND_ACC_PUBLIC) PHP_ME(XdmNode, getChildCount,
                                                arginfo_saxonc_xdmnode_getChildCount,
                                                ZEND_ACC_PUBLIC)

                        PHP_ME(XdmNode, axisNodes,
                               arginfo_saxonc_xdmnode_axisNodes,
                               ZEND_ACC_PUBLIC)

                            PHP_ME(
                                XdmNode, getAttributeCount,
                                arginfo_saxonc_xdmnode_getAttributeCount,
                                ZEND_ACC_PUBLIC) PHP_ME(XdmNode, getChildNode,
                                                        arginfo_saxonc_xdmnode_getChildNode,
                                                        ZEND_ACC_PUBLIC)
                                PHP_ME(XdmNode, getChildren,
                                       arginfo_saxonc_xdmnode_getChildren,
                                       ZEND_ACC_PUBLIC)
                                    PHP_ME(XdmNode, getParent,
                                           arginfo_saxonc_xdmnode_getParent,
                                           ZEND_ACC_PUBLIC)
                                        PHP_ME(
                                            XdmNode, getAttributeNode,
                                            arginfo_saxonc_xdmnode_getAttributeNode,
                                            ZEND_ACC_PUBLIC)
                                            PHP_ME(
                                                XdmNode, getAttributeNodes,
                                                arginfo_saxonc_xdmnode_getAttributeNodes,
                                                ZEND_ACC_PUBLIC)
                                                PHP_ME(
                                                    XdmNode, getAttributeValue,
                                                    arginfo_saxonc_xdmnode_getAttributeValue,
                                                    ZEND_ACC_PUBLIC)
                                                    PHP_ME(
                                                        XdmNode, getTypedValue,
                                                        arginfo_saxonc_xdmnode_getTypedValue,
                                                        ZEND_ACC_PUBLIC){
                                                        nullptr, nullptr,
                                                        nullptr}};

zend_function_entry xdmAtomicValue_methods[] = {
    PHP_ME(XdmAtomicValue, __construct, arginfo_saxonc_xdmatomic_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmAtomicValue, __destruct, arginfo_saxonc_xdmatomic_destruct,
               ZEND_ACC_PUBLIC) PHP_ME(XdmAtomicValue, __toString,
                                       arginfo_saxonc_xdmatomic_toString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmAtomicValue, getStringValue,
                   arginfo_saxonc_xdmatomic_getStringValue,
                   ZEND_ACC_PUBLIC) PHP_ME(XdmAtomicValue, isAtomic,
                                           arginfo_saxonc_xdmatomic_isAtomic,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(XdmAtomicValue, getBooleanValue,
                       arginfo_saxonc_xdmatomic_getBooleanValue,
                       ZEND_ACC_PUBLIC)
                    PHP_ME(XdmAtomicValue, getDoubleValue,
                           arginfo_saxonc_xdmatomic_getDoubleValue,
                           ZEND_ACC_PUBLIC)
                        PHP_ME(XdmAtomicValue, getLongValue,
                               arginfo_saxonc_xdmatomic_getLongValue,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(
                                XdmAtomicValue, getPrimitiveTypeName,
                                arginfo_saxonc_xdmatomic_getPrimitiveTypeName,
                                ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

zend_function_entry xdmFunctionItem_methods[] = {
    PHP_ME(XdmFunctionItem, __construct, arginfo_saxonc_xdmfunc_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmFunctionItem, __destruct, arginfo_saxonc_xdmfunc_destruct,
               ZEND_ACC_PUBLIC) PHP_ME(XdmFunctionItem, __toString,
                                       arginfo_saxonc_xdmfunc_toString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmFunctionItem, getName, arginfo_saxonc_xdmfunc_getName,
                   ZEND_ACC_PUBLIC) PHP_ME(XdmFunctionItem, getArity,
                                           arginfo_saxonc_xdmfunc_getArity,
                                           ZEND_ACC_PUBLIC)
                PHP_ME(XdmFunctionItem, getSystemFunction,
                       arginfo_saxonc_xdmfunc_getSystemFunction,
                       ZEND_ACC_PUBLIC)
                    PHP_ME(XdmFunctionItem, call, arginfo_saxonc_xdmfunc_call,
                           ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

zend_function_entry xdmMap_methods[] = {
    PHP_ME(XdmMap, __construct, arginfo_saxonc_xdmmap_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmMap, __destruct, arginfo_saxonc_xdmmap_destruct,
               ZEND_ACC_PUBLIC) PHP_ME(XdmMap, __toString,
                                       arginfo_saxonc_xdmmap_toString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmMap, mapSize, arginfo_saxonc_xdmmap_mapSize,
                   ZEND_ACC_PUBLIC)
                PHP_ME(XdmMap, get, arginfo_saxonc_xdmmap_get, ZEND_ACC_PUBLIC)
                    PHP_ME(XdmMap, put, arginfo_saxonc_xdmmap_put,
                           ZEND_ACC_PUBLIC)
                        PHP_ME(XdmMap, isEmpty, arginfo_saxonc_xdmmap_isEmpty,
                               ZEND_ACC_PUBLIC)
                            PHP_ME(XdmMap, containsKey,
                                   arginfo_saxonc_xdmmap_containsKey,
                                   ZEND_ACC_PUBLIC)
                                PHP_ME(XdmMap, keys, arginfo_saxonc_xdmmap_keys,
                                       ZEND_ACC_PUBLIC)
    /*PHP_ME(XdmMap,  asMap,      arginfo_saxonc_xdmmap_asMap, ZEND_ACC_PUBLIC)
    PHP_ME(XdmMap,  values,      arginfo_saxonc_xdmmap_values,
    ZEND_ACC_PUBLIC)*/
    {nullptr, nullptr, nullptr}};

zend_function_entry xdmArray_methods[] = {
    PHP_ME(XdmArray, __construct, arginfo_saxonc_xdmarray_construct,
           ZEND_ACC_PUBLIC | ZEND_ACC_CTOR)
        PHP_ME(XdmArray, __destruct, arginfo_saxonc_xdmarray_destruct,
               ZEND_ACC_PUBLIC) PHP_ME(XdmArray, __toString,
                                       arginfo_saxonc_xdmarray_toString,
                                       ZEND_ACC_PUBLIC)
            PHP_ME(XdmArray, get, arginfo_saxonc_xdmarray_get, ZEND_ACC_PUBLIC)
                PHP_ME(XdmArray, put, arginfo_saxonc_xdmarray_put,
                       ZEND_ACC_PUBLIC)
                    PHP_ME(XdmArray, addMember,
                           arginfo_saxonc_xdmarray_addMember, ZEND_ACC_PUBLIC)
                        PHP_ME(XdmArray, concat, arginfo_saxonc_xdmarray_concat,
                               ZEND_ACC_PUBLIC)
    // PHP_ME(XdmArray,  values,      arginfo_saxonc_xdmarray_values,
    // ZEND_ACC_PUBLIC)
    PHP_ME(XdmArray, getArity, arginfo_saxonc_xdmarray_getArity,
           ZEND_ACC_PUBLIC)
        PHP_ME(XdmArray, arrayLength, arginfo_saxonc_xdmarray_arrayLength,
               ZEND_ACC_PUBLIC){nullptr, nullptr, nullptr}};

PHP_MINIT_FUNCTION(saxon) {

  // php_saxonc_initialize(); - commented out code which causes PHP to hang see
  // bug issue #4371

  zend_class_entry ce;
  INIT_CLASS_ENTRY(ce, "Saxon\\SaxonProcessor", SaxonProcessor_methods);
  saxonProcessor_ce = zend_register_internal_class(&ce);
  saxonProcessor_ce->create_object = saxonProcessor_create_handler;
  memcpy(&saxonProcessor_object_handlers, zend_get_std_object_handlers(),
         sizeof(saxonProcessor_object_handlers)); // zend_object_handlers
  saxonProcessor_object_handlers.offset =
      XtOffsetOf(saxonProcessor_object, std);
  saxonProcessor_object_handlers.free_obj = SaxonProcessor_free_storage;
  saxonProcessor_object_handlers.dtor_obj = SaxonProcessor_destroy_storage;

  // saxonProcessor_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\DocumentBuilder", DocumentBuilder_methods);
  documentBuilder_ce = zend_register_internal_class(&ce);
  documentBuilder_ce->create_object = documentBuilder_create_handler;
  memcpy(&documentBuilder_object_handlers, zend_get_std_object_handlers(),
         sizeof(documentBuilder_object_handlers));
  documentBuilder_object_handlers.offset =
      XtOffsetOf(documentBuilder_object, std);
  documentBuilder_object_handlers.free_obj = DocumentBuilder_free_storage;
  documentBuilder_object_handlers.dtor_obj = DocumentBuilder_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XSLT30Processor", Xslt30Processor_methods);
  xslt30Processor_ce = zend_register_internal_class(&ce);
  xslt30Processor_ce->create_object = xslt30Processor_create_handler;
  memcpy(&xslt30Processor_object_handlers, zend_get_std_object_handlers(),
         sizeof(xslt30Processor_object_handlers));
  xslt30Processor_object_handlers.offset =
      XtOffsetOf(xslt30Processor_object, std);
  xslt30Processor_object_handlers.free_obj = Xslt30Processor_free_storage;
  xslt30Processor_object_handlers.dtor_obj = Xslt30Processor_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XSLTExecutable", XsltExecutable_methods);
  xsltExecutable_ce = zend_register_internal_class(&ce);
  xsltExecutable_ce->create_object = xslt30Processor_create_handler;
  memcpy(&xsltExecutable_object_handlers, zend_get_std_object_handlers(),
         sizeof(xsltExecutable_object_handlers));
  xsltExecutable_object_handlers.offset =
      XtOffsetOf(xsltExecutable_object, std);
  xsltExecutable_object_handlers.free_obj = XsltExecutable_free_storage;
  xsltExecutable_object_handlers.dtor_obj = XsltExecutable_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XQueryProcessor", XQueryProcessor_methods);
  xqueryProcessor_ce = zend_register_internal_class(&ce);
  xqueryProcessor_ce->create_object = xqueryProcessor_create_handler;
  memcpy(&xqueryProcessor_object_handlers, zend_get_std_object_handlers(),
         sizeof(xqueryProcessor_object_handlers));
  xqueryProcessor_object_handlers.offset =
      XtOffsetOf(xqueryProcessor_object, std);
  xqueryProcessor_object_handlers.free_obj = xqueryProcessor_free_storage;
  xqueryProcessor_object_handlers.dtor_obj = xqueryProcessor_destroy_storage;

  // xqueryProcessor_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\XPathProcessor", XPathProcessor_methods);
  xpathProcessor_ce = zend_register_internal_class(&ce);
  xpathProcessor_ce->create_object = xpathProcessor_create_handler;
  memcpy(&xpathProcessor_object_handlers, zend_get_std_object_handlers(),
         sizeof(xpathProcessor_object_handlers));
  xpathProcessor_object_handlers.offset =
      XtOffsetOf(xpathProcessor_object, std);
  xpathProcessor_object_handlers.free_obj = xpathProcessor_free_storage;
  xpathProcessor_object_handlers.dtor_obj = xpathProcessor_destroy_storage;
  // xpathProcessor_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\SchemaValidator", SchemaValidator_methods);
  schemaValidator_ce = zend_register_internal_class(&ce);
  schemaValidator_ce->create_object = schemaValidator_create_handler;
  memcpy(&schemaValidator_object_handlers, zend_get_std_object_handlers(),
         sizeof(schemaValidator_object_handlers));
  schemaValidator_object_handlers.offset =
      XtOffsetOf(schemaValidator_object, std);
  schemaValidator_object_handlers.free_obj = schemaValidator_free_storage;
  schemaValidator_object_handlers.dtor_obj = schemaValidator_destroy_storage;
  // schemaValidator_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmValue", xdmValue_methods);
  xdmValue_ce = zend_register_internal_class(&ce);
  xdmValue_ce->create_object = xdmValue_create_handler;
  memcpy(&xdmValue_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmValue_object_handlers));
  xdmValue_object_handlers.offset = XtOffsetOf(xdmValue_object, std);
  xdmValue_object_handlers.free_obj = xdmValue_free_storage;
  xdmValue_object_handlers.dtor_obj = XdmValue_destroy_storage;
  // xdmValue_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmItem", xdmItem_methods);
  xdmItem_ce = zend_register_internal_class(&ce);
  xdmItem_ce->create_object = xdmItem_create_handler;
  memcpy(&xdmItem_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmItem_object_handlers));
  xdmItem_object_handlers.offset = XtOffsetOf(xdmItem_object, std);
  xdmItem_object_handlers.free_obj = xdmItem_free_storage;
  xdmItem_object_handlers.dtor_obj = XdmItem_destroy_storage;
  // xdmItem_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmNode", xdmNode_methods);
  xdmNode_ce = zend_register_internal_class(&ce);
  xdmNode_ce->create_object = xdmNode_create_handler;
  memcpy(&xdmNode_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmNode_object_handlers));
  xdmNode_object_handlers.offset = XtOffsetOf(xdmNode_object, std);
  xdmNode_object_handlers.free_obj = xdmNode_free_storage;
  xdmNode_object_handlers.dtor_obj = XdmNode_destroy_storage;

  // xdmNode_object_handlers.clone_obj = nullptr;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmAtomicValue", xdmAtomicValue_methods);
  xdmAtomicValue_ce = zend_register_internal_class(&ce);
  xdmAtomicValue_ce->create_object = xdmAtomicValue_create_handler;
  memcpy(&xdmAtomicValue_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmAtomicValue_object_handlers));
  xdmAtomicValue_object_handlers.offset =
      XtOffsetOf(xdmAtomicValue_object, std);
  xdmAtomicValue_object_handlers.free_obj = xdmAtomicValue_free_storage;
  xdmAtomicValue_object_handlers.dtor_obj = XdmAtomicValue_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmFunctionItem", xdmFunctionItem_methods);
  xdmFunctionItem_ce = zend_register_internal_class(&ce);
  xdmFunctionItem_ce->create_object = xdmFunctionItem_create_handler;
  memcpy(&xdmFunctionItem_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmFunctionItem_object_handlers));
  xdmFunctionItem_object_handlers.offset =
      XtOffsetOf(xdmFunctionItem_object, std);
  xdmFunctionItem_object_handlers.free_obj = xdmFunctionItem_free_storage;
  xdmFunctionItem_object_handlers.dtor_obj = XdmFunctionItem_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmMap", xdmMap_methods);
  xdmMap_ce = zend_register_internal_class(&ce);
  xdmMap_ce->create_object = xdmMap_create_handler;
  memcpy(&xdmMap_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmMap_object_handlers));
  xdmMap_object_handlers.offset = XtOffsetOf(xdmMap_object, std);
  xdmMap_object_handlers.free_obj = xdmMap_free_storage;
  xdmMap_object_handlers.dtor_obj = XdmMap_destroy_storage;

  INIT_CLASS_ENTRY(ce, "Saxon\\XdmArray", xdmArray_methods);
  xdmArray_ce = zend_register_internal_class(&ce);
  xdmArray_ce->create_object = xdmArray_create_handler;
  memcpy(&xdmArray_object_handlers, zend_get_std_object_handlers(),
         sizeof(xdmArray_object_handlers));
  xdmArray_object_handlers.offset = XtOffsetOf(xdmArray_object, std);
  xdmArray_object_handlers.free_obj = xdmArray_free_storage;
  xdmArray_object_handlers.dtor_obj = XdmArray_destroy_storage;

  // REGISTER_INI_ENTRIES();
  return SUCCESS;
}

PHP_MINFO_FUNCTION(saxon) {
  php_info_print_table_start();
  php_info_print_table_header(2, "saxonc", "enabled");
  php_info_print_table_row(2, "SaxonC API version", "12.4.2");
  php_info_print_table_end();
  DISPLAY_INI_ENTRIES();
}

PHP_MSHUTDOWN_FUNCTION(saxon) {
  // std::cerr<<"MSHUTDOWN called -start"<<std::endl;
  // SaxonProcessor *  proc = new SaxonProcessor();
  SaxonProcessor::release();
  // delete proc;
  UNREGISTER_INI_ENTRIES();

  return SUCCESS;
}

PHP_RSHUTDOWN_FUNCTION(saxon) {
  // std::cerr<<"RSHUTDOWN called -start"<<std::endl;
  //    SaxonProcessor::release();
  return SUCCESS;
}

PHP_RINIT_FUNCTION(saxon) {
  // SaxonProcessor::release();
  // std::cerr<<"RINIT called -start"<<std::endl;
  return SUCCESS;
}

zend_module_entry saxon_module_entry = {
#if ZEND_MODULE_API_NO >= 20010901
    STANDARD_MODULE_HEADER,
#endif
    PHP_SAXON_EXTNAME,
    nullptr,              /* Functions */
    PHP_MINIT(saxon),     /* MINIT */
    PHP_MSHUTDOWN(saxon), /* MSHUTDOWN */
    nullptr,              /* RINIT */
    nullptr,              /* RSHUTDOWN */
    PHP_MINFO(saxon),     /* MINFO */
#if ZEND_MODULE_API_NO >= 20010901
    PHP_SAXON_EXTVER,
#endif
    STANDARD_MODULE_PROPERTIES};

#ifdef COMPILE_DL_SAXONC
#ifdef ZTS
ZEND_TSRMLS_CACHE_DEFINE()
#endif
ZEND_GET_MODULE(saxonc)
#endif
