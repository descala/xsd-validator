
//============================= SaxonProcessor

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonproc_construct, 0, 0, 0)
// the first argument to this is if this is a reference
// the second argument to this is the name
ZEND_ARG_INFO(0, license)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_setConfigurationProperty, 0, 0, 2)
// the first argument to this is if this is a reference
// the second argument to this is the name
ZEND_ARG_TYPE_INFO(0, name, IS_STRING, 0)
ZEND_ARG_TYPE_INFO(0, value, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_parseXmlFromString, 0, 0, 1)
// the first argument to this is if this is a reference
// the second argument to this is the name
ZEND_ARG_TYPE_INFO(0, value, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_createAtomicValue, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_parseXmlFromFile, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, filename, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_parseXmlFromUri, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, uri_str, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_setcwd, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, path, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_newXPathProcessor, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_newDocumentBuilder, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_newXslt30Processor, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_newXQueryProcessor, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_newSchemaValidator, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_setCatalog, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, filename, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_setCatalogFiles, 0, 0, 1)
ZEND_ARG_INFO(0, filenames)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_clarkNameToEQName, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, clarkname, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_EQNameToClarkName, 0, 0, 1)
ZEND_ARG_TYPE_INFO(0, eqname, IS_STRING, 0)
ZEND_END_ARG_INFO()

// ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_registerPHPFunctions,   0, 0, 1??)
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_version, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_isSchemaAware, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_release, 0, 0, 0)
ZEND_END_ARG_INFO()

//===============DocumentBuilder

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_setLineNumbering, 0, 0, 1)
ZEND_ARG_INFO(0, num)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_isLineNumbering, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_setSchemaValidator, 0, 0, 1)
ZEND_ARG_INFO(0, validator)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_getSchemaValidator, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_setDTDValidation, 0, 0, 1)
ZEND_ARG_INFO(0, dtdValidator)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_isDTDValidation, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_setBaseUri, 0, 0, 1)
ZEND_ARG_INFO(0, baseUri)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_getBaseUri, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_parseXmlFromString, 0, 0, 1)
ZEND_ARG_INFO(0, xml)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_parseXmlFromFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_parseXmlFromUri, 0, 0, 1)
ZEND_ARG_INFO(0, uri)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_docbuilder_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()

//===================== XsltExecutable

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callFunctionReturningValue, 0, 0, 2)
ZEND_ARG_INFO(0, function_name)
ZEND_ARG_INFO(0, arguments)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callFunctionReturningString, 0, 0, 2)
ZEND_ARG_INFO(0, function_name)
ZEND_ARG_INFO(0, arguments)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callFunctionReturningFile, 0, 0, 3)
ZEND_ARG_INFO(0, function_name)
ZEND_ARG_INFO(0, arguments)
ZEND_ARG_INFO(0, output_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callTemplateReturningValue, 0, 0, 1)
ZEND_ARG_INFO(0, template_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callTemplateReturningString, 0, 0, 1)
ZEND_ARG_INFO(0, template_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_callTemplateReturningFile, 0, 0, 2)
ZEND_ARG_INFO(0, template_name)
ZEND_ARG_INFO(0, output_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_applyTemplatesReturningValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_applyTemplatesReturningString, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_applyTemplatesReturningFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setInitialTemplateParameters, 0, 0, 1)
ZEND_ARG_INFO(0, parameters)
ZEND_ARG_INFO(0, tunnel)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setInitialMatchSelection, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setInitialMatchSelectionAsFile, 0, 0,
                       1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setGlobalContextItem, 0, 0, 1)
ZEND_ARG_INFO(0, item)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setGlobalContextFromFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setInitialMode, 0, 0, 1)
ZEND_ARG_INFO(0, mode_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformFileToFile, 0, 0, 0)
ZEND_ARG_INFO(0, source_file_name)
ZEND_ARG_INFO(0, output_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformFileToString, 0, 0, 1)
ZEND_ARG_INFO(0, source_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformFileToValue, 0, 0, 1)
ZEND_ARG_INFO(0, source_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformToString, 0, 0, 0)
ZEND_ARG_INFO(0, context)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformToValue, 0, 0, 0)
ZEND_ARG_INFO(0, context)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_transformToFile, 0, 0, 0)
ZEND_ARG_INFO(0, context)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setOutputFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setResultAsRawValue, 0, 0, 1)
ZEND_ARG_INFO(0, is_raw_value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setParameter, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setProperty, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setcwd, 0, 0, 1)
ZEND_ARG_INFO(0, cwd)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_clearParameters, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_clearProperties, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setSaveXslMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_exportStylesheet, 0, 0, 0)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_checkForException, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_setCaptureResultDocuments, 0, 0, 1)
ZEND_ARG_INFO(0, flag)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xe_getResultDocuments, 0, 0, 0)
ZEND_END_ARG_INFO()

//=============== Xslt30Processor

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_transformFileToFile, 0, 0, 3)
ZEND_ARG_INFO(0, source_file_name)
ZEND_ARG_INFO(0, stylesheet_file_name)
ZEND_ARG_INFO(0, output_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_transformFileToString, 0, 0, 2)
ZEND_ARG_INFO(0, source_file_name)
ZEND_ARG_INFO(0, stylesheet_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_transformFileToValue, 0, 0, 2)
ZEND_ARG_INFO(0, source_file_name)
ZEND_ARG_INFO(0, stylesheet_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromFile, 0, 0, 1)
ZEND_ARG_INFO(0, stylesheet_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromValue, 0, 0, 1)
ZEND_ARG_INFO(0, node)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromString, 0, 0, 1)
ZEND_ARG_INFO(0, xml_string)
ZEND_ARG_INFO(0, encoding_Str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromStringAndSave, 0, 0, 2)
ZEND_ARG_INFO(0, xml_string)
ZEND_ARG_INFO(0, output_file_name)
ZEND_ARG_INFO(0, encoding_Str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromFileAndSave, 0, 0, 2)
ZEND_ARG_INFO(0, file_name)
ZEND_ARG_INFO(0, output_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_compileFromAssociatedFile, 0, 0, 1)
ZEND_ARG_INFO(0, xml_file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setJustInTimeCompilation, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setTargetEdition, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_importPackage, 0, 0, 1)
ZEND_ARG_INFO(0, filename)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setRelocatable, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setFastCompilation, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setXsltLanguageVersion, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_setParameter, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_clearParameters, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xp_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

//================== SchemaValidator

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_setSourceNode, 0, 0, 1)
ZEND_ARG_INFO(0, node)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_setOutputFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_registerSchemaFromNode, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_validate, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_validateToNode, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_registerSchemaFromFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_registerSchemaFromString, 0, 0, 1)
ZEND_ARG_INFO(0, schema_string)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_getValidationReport, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_setLax, 0, 0, 0)
ZEND_ARG_INFO(0, lax)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_setParameter, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_setProperty, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_clearParameters, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_clearProperties, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_sval_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

//====================   XQueryProcessor

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
// ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor,  getErrorCode, 0, 0,
// 0)
// ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setQueryContent, 0, 0, 1)
ZEND_ARG_INFO(0, query)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setStreaming, 0, 0, 1)
ZEND_ARG_INFO(0, item)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_isStreaming, 0, 0, 0)
ZEND_ARG_INFO(0, item)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setContextItem, 0, 0, 1)
ZEND_ARG_INFO(0, item)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setContextItemFromFile, 0,
                       0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setParameter, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setProperty, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_clearParameters, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_clearProperties, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_runQueryToValue, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_runQueryToString, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_runQueryToFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setQueryFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setQueryBaseURI, 0, 0, 1)
ZEND_ARG_INFO(0, uri)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_declareNamespace, 0, 0, 2)
ZEND_ARG_INFO(0, prefix)
ZEND_ARG_INFO(0, namespacei)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_exceptionOccurred, 0, 0,
                       0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_XQueryProcessor_setLanguageVersion, 0, 0,
                       1)
ZEND_END_ARG_INFO()

//====================   XPathProcessor

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setContextItem, 0, 0, 1)
ZEND_ARG_INFO(0, context)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setContextFile, 0, 0, 1)
ZEND_ARG_INFO(0, file_name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_effectiveBooleanValue, 0, 0, 1)
ZEND_ARG_INFO(0, xpath)
ZEND_ARG_INFO(0, encoding_Str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_evaluate, 0, 0, 1)
ZEND_ARG_INFO(0, xpath)
ZEND_ARG_INFO(0, encoding_Str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setUnprefixedElementMatchingPolicy,
                       0, 0, 1)
ZEND_ARG_INFO(0, policy)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_evaluateSingle, 0, 0, 1)
ZEND_ARG_INFO(0, xpath)
ZEND_ARG_INFO(0, encoding_Str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setParameter, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setProperty, 0, 0, 2)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setLanguageVersion, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_clearParameters, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_clearProperties, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_exceptionOccurred, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_exceptionClear, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_getErrorCode, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_getErrorMessage, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_declareNamespace, 0, 0, 2)
ZEND_ARG_INFO(0, prefix)
ZEND_ARG_INFO(0, namespacex)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setBackwardsCompatible, 0, 0, 1)
ZEND_ARG_INFO(0, flag)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setCaching, 0, 0, 1)
ZEND_ARG_INFO(0, caching)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_importSchemaNamespace, 0, 0, 1)
ZEND_ARG_INFO(0, uri)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xpath_setBaseURI, 0, 0, 1)
ZEND_ARG_INFO(0, uri)
ZEND_END_ARG_INFO()

//======================= XdmValue

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_construct, 0, 0, 1)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmval_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_getHead, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_itemAt, 0, 0, 1)
ZEND_ARG_INFO(0, index)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_size, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmval_addXdmItem, 0, 0, 1)
ZEND_ARG_INFO(0, item)
ZEND_END_ARG_INFO()

//=======================  XdmItem

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmitem_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_getStringValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_isAtomic, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_isNode, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_getAtomicValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmitem_getNodeValue, 0, 0, 0)
ZEND_END_ARG_INFO()

//======================= XdmFunctionItem

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmfunc_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_getName, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_getArity, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_getSystemFunction, 0, 0, 3)
ZEND_ARG_INFO(0, proc)
ZEND_ARG_INFO(0, name)
ZEND_ARG_INFO(0, arity)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmfunc_call, 0, 0, 2)
ZEND_ARG_INFO(0, proc)
ZEND_ARG_INFO(0, arguments)
ZEND_END_ARG_INFO()

//======================= XdmNode

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmnode_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getBaseURI, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getStringValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getNodeKind, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getNodeName, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getLocalName, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_isAtomic, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getChildCount, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getAttributeCount, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_axisNodes, 0, 0, 1)
ZEND_ARG_INFO(0, axis)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getChildNode, 0, 0, 1)
ZEND_ARG_INFO(0, index)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getChildren, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getParent, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getAttributeNode, 0, 0, 1)
ZEND_ARG_INFO(0, index)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getAttributeNodes, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getAttributeValue, 0, 0, 0)
ZEND_ARG_INFO(0, name)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmnode_getTypedValue, 0, 0, 0)
ZEND_END_ARG_INFO()

//======================= XdmAtomicValue

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmatomic_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_getStringValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_isAtomic, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_getBooleanValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_getDoubleValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_getLongValue, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmatomic_getPrimitiveTypeName, 0, 0, 0)
ZEND_END_ARG_INFO()

//======================= XdmMap

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmmap_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_mapSize, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_get, 0, 0, 1)
ZEND_ARG_INFO(0, key)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_put, 0, 0, 2)
ZEND_ARG_INFO(0, key)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_isEmpty, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_containsKey, 0, 0, 1)
ZEND_ARG_INFO(0, key)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmmap_keys, 0, 0, 0)
ZEND_END_ARG_INFO()

//======================= XdmArray

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_construct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_destruct, 0, 0, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_saxonc_xdmarray_toString, 0, 0,
                                        IS_STRING, 0)
ZEND_END_ARG_INFO()
ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_get, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_put, 0, 0, 2)
ZEND_ARG_INFO(0, index)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_addMember, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_concat, 0, 0, 1)
ZEND_ARG_INFO(0, value)
ZEND_END_ARG_INFO()

// ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_values, 0, 0, 0)
// ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_getArity, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_saxonc_xdmarray_arrayLength, 0, 0, 0)
ZEND_END_ARG_INFO()
