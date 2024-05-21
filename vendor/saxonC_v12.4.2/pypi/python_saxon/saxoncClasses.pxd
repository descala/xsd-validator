# cython: language_level = 3

from libcpp cimport bool
from libcpp.string cimport string
from libcpp.map cimport map

cdef extern from "../../Saxon.C.API/CythonExceptionHandler.h":
  cdef void raise_py_error()


cdef extern from "../../Saxon.C.API/SaxonProcessor.h":

    cdef cppclass UnprefixedElementMatchingPolicy:
      pass

    cdef cppclass SaxonProcessor:
        SaxonProcessor(bool) except +raise_py_error
        SaxonProcessor(const char * configFile) except +raise_py_error
        bool license
        char * version()
        void release()

        # set the current working directory
        void setcwd(char* cwd)
        const char* getcwd()

        void attachCurrentThread() except +raise_py_error

        void detachCurrentThread()  except +raise_py_error

        @staticmethod
        void deleteString(const char * data);

        XdmValue ** createXdmValueArray(int len)

        void deleteXdmValueArray(XdmValue ** arr, int len)

        void deleteXdmAtomicValueArray(XdmAtomicValue ** arr, int len)

        XdmAtomicValue ** createXdmAtomicValueArray(int len)

        #SaxonProcessor * getProcessor()

        #Set a configuration property specific to the processor in use. 
        #Properties specified here are common across all the processors.
        void setConfigurationProperty(char * name, char * value)

        #Clear configuration properties specific to the processor in use. 
        void clearConfigurationProperties()

        bool isSchemaAware()

        const char * EQNameToClarkName(const char * name)

        const char * clarkNameToEQName(const char * name)

        const char * getResourcesDirectory()

        void setResourcesDirectory(const char* dir)

        Xslt30Processor * newXslt30Processor()    except +raise_py_error

        XQueryProcessor * newXQueryProcessor()  except +raise_py_error

        XPathProcessor * newXPathProcessor()   except +raise_py_error

        SchemaValidator * newSchemaValidator() except +raise_py_error

        DocumentBuilder * newDocumentBuilder() except +raise_py_error

        XdmAtomicValue * makeStringValue(const char* str1, const char* encoding)

        XdmAtomicValue * makeIntegerValue(int i)

        XdmAtomicValue * makeDoubleValue(double d)

        XdmAtomicValue * makeFloatValue(float)

        XdmAtomicValue * makeLongValue(long l)

        XdmAtomicValue * make_boolean_value(bool b)

        XdmAtomicValue * makeBooleanValue(bool b)

        XdmAtomicValue * makeQNameValue(const char* str)

        XdmAtomicValue * makeAtomicValue(const char* type, const char* value)


        XdmArray *makeArray(const char **input, int length)

        XdmArray *makeArray(short *input, int length)


        XdmArray *makeArray(int *input, int length)

        XdmArray *makeArray(long *input, int length)

        XdmArray *makeArray(bool *input, int length)


        XdmArray *makeArray(XdmValue ** values, int length)


        XdmMap *makeMap2(map[string, XdmValue *] dataMap)

        XdmMap *makeMap3(XdmAtomicValue ** keys, XdmValue ** values, int len_)

        void setCatalog(const char * filename)  except +raise_py_error

        void setCatalogFiles(const char ** filenames, int _len)  except +raise_py_error

        const char * getStringValue(XdmItem * item)

        XdmNode * parseXmlFromString(const char* source, const char* encoding, SchemaValidator * validator) except +raise_py_error

        XdmNode * parseXmlFromString(const char* source) except +raise_py_error

        XdmNode * parseXmlFromFile(const char* source, SchemaValidator * validator)  except +raise_py_error

        XdmNode * parseXmlFromUri(const char* source, SchemaValidator * validator)   except +raise_py_error

        XdmValue * parseJsonFromString(const char* source, const char* encoding) except +raise_py_error

        XdmValue * parseJsonFromFile(const char* source)  except +raise_py_error

        bool isSchemaAwareProcessor()

        bool exceptionOccurred()

        void exceptionClear()

        const char * getErrorMessage()


    cdef cppclass DocumentBuilder:
        DocumentBuilder() except +raise_py_error

        void setLineNumbering(bool option)

        bool isLineNumbering()

        void setSchemaValidator(SchemaValidator * validator)

        SchemaValidator * getSchemaValidator()


        void setDTDValidation(bool option)  except +raise_py_error

        bool isDTDValidation()

        void setBaseUri(const char* uri)  except +raise_py_error

        const char * getBaseUri()

        XdmNode* parseXmlFromString(const char * content, const char * encoding) except +raise_py_error

        XdmNode* parseXmlFromFile(const char * filename)  except +raise_py_error

        XdmNode * parseXmlFromUri(const char* source)  except +raise_py_error




    cdef cppclass Xslt30Processor:
        Xslt30Processor() except +raise_py_error
        # set the current working directory
        void setcwd(const char* cwd)

        # Set the output file of where the transformation result is sent
        void setOutputFile(const char* outfile)

        # Say whether just-in-time compilation of template rules should be used.
        void setJustInTimeCompilation(bool jit)

        void setXsltLanguageVersion(const char* version)

        void setFastCompilation(bool fast)

        void setTargetEdition(const char* edition)

        void setRelocatable(bool relocatable)

        void setResultAsRawValue(bool option)

        # Set the base output URI.
        void setBaseOutputURI(const char * baseURI)

        # Set the value of a stylesheet parameter
        void setParameter(const char* name, XdmValue*value)

        # Get a parameter value by name
        XdmValue* getParameter(const char* name)

        # Remove a parameter (name, value) pair from a stylesheet
        bool removeParameter(const char* name)

        XdmValue ** createXdmValueArray(int len)

        void deleteXdmValueArray(XdmValue** arr, int len)

        # Clear parameter values set
        void clearParameters(bool deleteValues=false)

        void importPackage(const char *packageFile)


        # Perform a one shot transformation. The result is returned as a string
        const char * transformFileToString(const char* sourcefile, const char* stylesheetfile)    except +raise_py_error

        # Perform a one shot transformation. The result are saved to file
        void transformFileToFile(const char* sourcefile, const char* stylesheetfile, const char* outputfile)   except +raise_py_error

        # Perform a one shot transformation. The result is returned as an XdmValue
        XdmValue * transformFileToValue(const char* sourcefile, const char* stylesheetfile)   except +raise_py_error

        # compile a stylesheet file.
        XsltExecutable * compileFromFile(const char* stylesheet)  except +raise_py_error

        # compile a stylesheet received as a string.
        XsltExecutable * compileFromString(const char* stylesheet, const char * encoding)   except +raise_py_error

        # Get the stylesheet associated via the xml-stylesheet processing instruction
        XsltExecutable * compileFromAssociatedFile(const char* sourceFile)    except +raise_py_error

        # Compile a stylesheet received as a string and save to an exported file (SEF).
        void compileFromStringAndSave(const char* stylesheet, const char* filename, const char * encoding)  except +raise_py_error

        # Compile a stylesheet received as a file and save to an exported file (SEF).
        void compileFromFileAndSave(const char* xslFilename, const char* filename)  except +raise_py_error

        # Compile a stylesheet received as an XdmNode. The compiled stylesheet is cached
        # and available for execution later.
        void compileFromXdmNodeAndSave(XdmNode * node, const char* filename)    except +raise_py_error

        # compile a stylesheet received as an XdmNode.
        XsltExecutable * compileFromXdmNode(XdmNode * node)   except +raise_py_error


        # Checks for pending exceptions without creating a local reference to the exception object
        bool exceptionOccurred()

        # Check for exception thrown.
        const char* checkException()

        # Clear any exception thrown
        void exceptionClear()

        # Get number of errors reported during execution or evaluate of stylesheet
        int exceptionCount()

        # Get the error message if there are any error
        const char * getErrorMessage()

        # Get the ith error code if there are any error
        const char * getErrorCode()




    cdef cppclass XsltExecutable:
        XsltExecutable() except +raise_py_error
        # set the current working directory
        void setcwd(const char* cwd)

        # Set the base output URI.
        void setBaseOutputURI(const char * baseURI)

        void setGlobalContextItem(XdmItem * value)

        # Set the source from file for the transformation.
        void setGlobalContextFromFile(const char * filename)

        void setInitialMode(const char * modeName)  except +raise_py_error

        void setCaptureResultDocuments(bool flag, bool rawResult)

        # The initial value to which templates are to be applied (equivalent to the <code>select</code> attribute of <code>xsl:apply-templates</code>)
        void setInitialMatchSelection(XdmValue * selection)     except +raise_py_error

        # The initial filename to which templates are to be applied (equivalent to the <code>select</code> attribute of <code>xsl:apply-templates</code>).
        void setInitialMatchSelectionAsFile(const char * filename)   except +raise_py_error

        # Set the output file of where the transformation result is sent
        void setOutputFile(const char* outfile)


        void setResultAsRawValue(bool option)

        map[string,XdmValue*]& getResultDocuments()  except +raise_py_error

        XsltExecutable *clone()

        # Produce a representation of the compiled stylesheet, in XML form, suitable for
        # distribution and reloading.
        void exportStylesheet(const char * filename)  except +raise_py_error

        # Set the value of a stylesheet parameter
        void setParameter(const char* name, XdmValue*value)

        # Get a parameter value by name
        XdmValue* getParameter(const char* name)

        # Remove a parameter (name, value) pair from a stylesheet
        bool removeParameter(const char* name)

        # Set a property specific to the processor in use.
        void setProperty(const char* name, const char* value)

        void setInitialTemplateParameters(map[string,XdmValue*] parameters, bool tunnel)

        XdmValue ** createXdmValueArray(int len)

        void deleteXdmValueArray(XdmValue** arr, int len)

        # Get a property value by name
        const char* getProperty(const char* name)

        # Get all parameters as a std::map
        map[string,XdmValue*]& getParameters()

        # Get all properties as a std::map
        map[string,string]& getProperties()

        # Clear parameter values set
        void clearParameters(bool deleteValues=false)

        # Clear property values set
        void clearProperties()

        # Get the messages written using the <code>xsl:message</code> instruction
        void setSaveXslMessage(bool show, const char* filename)  except +raise_py_error

        # Get the messages written using the xsl:message instruction
        XdmValue * getXslMessages()  except +raise_py_error

        # Perform a one shot transformation. The result is stored in the supplied outputfile.
        void transformFileToFile(const char* sourcefile, const char* outputfile)  except +raise_py_error

        # Perform a one shot transformation. The result is returned as a string
        const char * transformFileToString(const char* sourcefile)   except +raise_py_error

        # Perform a one shot transformation. The result is returned as an XdmValue
        XdmValue * transformFileToValue(const char* sourcefile)   except +raise_py_error

        # Invoke the stylesheet by applying templates to a supplied input sequence, Saving the results to file.
        void applyTemplatesReturningFile(const char* outfile)    except +raise_py_error

        # Invoke the stylesheet by applying templates to a supplied input sequence, Saving the results as serialized string.
        const char* applyTemplatesReturningString()  except +raise_py_error

        # Invoke the stylesheet by applying templates to a supplied input sequence, Saving the results as an XdmValue.
        XdmValue * applyTemplatesReturningValue()  except +raise_py_error

        # Invoke a transformation by calling a named template and save result to file.
        void callTemplateReturningFile(const char* templateName, const char* outfile)  except +raise_py_error

        # Invoke a transformation by calling a named template and return result as a string.
        const char* callTemplateReturningString(const char* templateName)   except +raise_py_error

        # Invoke a transformation by calling a named template and return result as an XdmValue.
        XdmValue* callTemplateReturningValue(const char* templateName)  except +raise_py_error

        # Call a public user-defined function in the stylesheet
        # Here we wrap the result in an XML document, and sending this document to a specified file
        void callFunctionReturningFile(const char* functionName, XdmValue ** arguments, int argument_length, const char* outfile)  except +raise_py_error

        # Call a public user-defined function in the stylesheet
        # Here we wrap the result in an XML document, and serialized this document to string value
        const char * callFunctionReturningString(const char* functionName, XdmValue ** arguments, int argument_length)   except +raise_py_error

        # Call a public user-defined function in the stylesheet
        # Here we wrap the result in an XML document, and return the document as an XdmVale
        XdmValue * callFunctionReturningValue(const char* functionName, XdmValue ** arguments, int argument_length)   except +raise_py_error

        # Execute transformation to string. Properties supplied in advance.
        const char * transformToString(XdmNode * source)   except +raise_py_error

        # Execute transformation to Xdm Value. Properties supplied in advance.
        XdmValue * transformToValue(XdmNode * source)    except +raise_py_error

        # Execute transformation to file. Properties supplied in advance.
        void transformToFile(XdmNode * source)   except +raise_py_error

        # Checks for pending exceptions without creating a local reference to the exception object
        bool exceptionOccurred()

        # Check for exception thrown.
        SaxonApiException* getException()

        # Get the error message if there are any error
        const char * getErrorMessage()

        # Clear any exception thrown
        void exceptionClear()

        # Get number of errors reported during execution or evaluate of stylesheet
        int exceptionCount()


    cdef cppclass SaxonApiException:
        SaxonApiException() except +raise_py_error


    cdef cppclass SchemaValidator:
        SchemaValidator() except +raise_py_error

        void setcwd(const char* cwd)

        void registerSchemaFromNode(XdmNode * node)    except +raise_py_error

        void registerSchemaFromFile(const char * xsd)   except +raise_py_error

        void registerSchemaFromString(const char * schemaStr)  except +raise_py_error

        void exportSchema(const char * fileName)  except +raise_py_error

        void setOutputFile(const char * outputFile)

        void validate(const char * sourceFile) except +raise_py_error
   
        XdmNode * validateToNode(const char * sourceFile) except +raise_py_error

        void setSourceNode(XdmNode * source)

        XdmNode* getValidationReport() except +raise_py_error

        void setParameter(const char * name, XdmValue*value)

        bool removeParameter(const char * name)

        void setProperty(const char * name, const char * value)

        void clearParameters()

        void clearProperties()

        bool exceptionOccurred()

        const char* checkException()

        void exceptionClear()

        int exceptionCount()

    
        const char * getErrorMessage()
     
        const char * getErrorCode()

        void setLax(bool l)

    cdef cppclass XPathProcessor:

        XPathProcessor() except +raise_py_error

        void setBaseURI(const char * uriStr)

        const char * getBaseURI()

        XdmValue * evaluate(const char * xpathStr, const char* encoding)  except +raise_py_error
   
        XdmItem * evaluateSingle(const char * xpathStr, const char* encoding)  except +raise_py_error

        void setUnprefixedElementMatchingPolicy(UnprefixedElementMatchingPolicy policy);

        UnprefixedElementMatchingPolicy getUnprefixedElementMatchingPolicy();

        UnprefixedElementMatchingPolicy convertEnumPolicy(int n);

        void setContextItem(XdmItem * item)
        
        void setcwd(const char* cwd)

        void setContextFile(const char * filename)

        void setLanguageVersion(const char * version)

        bool effectiveBooleanValue(const char * xpathStr, const char* encoding) except +raise_py_error

        void setParameter(const char * name, XdmValue*value)

        bool removeParameter(const char * name)

        void setProperty(const char * name, const char * value)

        void declareNamespace(const char *prefix, const char * uri)  except +raise_py_error

        void declareVariable(const char * name)

        void setBackwardsCompatible(bool option)

        void setCaching(bool caching)

        void importSchemaNamespace(const char * uri)

        void clearParameters()

        void clearProperties()

        bool exceptionOccurred()

        void exceptionClear()

        int exceptionCount()

        const char * getErrorMessage()

        const char * getErrorCode()

    cdef cppclass XQueryProcessor:
        XQueryProcessor() except +raise_py_error

        void setContextItem(XdmItem * value) except +raise_py_error

        void setOutputFile(const char* outfile)

        void setContextItemFromFile(const char * filename)

        void setLanguageVersion(const char * version)

        void setParameter(const char * name, XdmValue*value)

        bool removeParameter(const char * name)

        void setProperty(const char * name, const char * value)

        void clearParameters()

        void clearProperties()

        void setUpdating(bool updating)

        void setStreaming(bool option)

        void isStreaming()

        XdmValue * runQueryToValue() except +raise_py_error
        const char * runQueryToString() except +raise_py_error

        void executeQueryToFile(const char *infilename,const char *ofilename,const char *query, const char* encoding) except +raise_py_error

        XdmValue *executeQueryToValue(const char *infilename, const char *query, const char* encoding) except +raise_py_error

        const char *executeQueryToString(const char *infilename, const char *query, const char* encoding) except +raise_py_error

        void runQueryToFile() except +raise_py_error

        void declareNamespace(const char *prefix, const char * uri) except +raise_py_error

        void setQueryFile(const char* filename)

        void setQueryContent(const char* content)

        void setQueryBaseURI(const char * baseURI)

        void setcwd(const char* cwd)

        const char* checkException()

        bool exceptionOccurred()

        void exceptionClear()

        int exceptionCount()

        const char * getErrorMessage()

        const char * getErrorCode()


cdef extern from "../../Saxon.C.API/XdmValue.h":
    cdef cppclass XdmValue:
        XdmValue() except +raise_py_error

        void addXdmItem(XdmItem *val)
        #void releaseXdmValue()

        XdmItem * getHead()

        XdmItem * itemAt(int)

        int size()

        const char * toString()  except +raise_py_error

        void incrementRefCount()

        void decrementRefCount()

        int getRefCount()

        int getType()

cdef extern from "../../Saxon.C.API/XdmItem.h":
    cdef cppclass XdmItem(XdmValue):
        XdmItem() except +raise_py_error
        const char * getStringValue()
        bool isAtomic()

        bool isFunction()

        bool isNode()

        bool isMap()

        bool isArray()


cdef extern from "../../Saxon.C.API/XdmNode.h":

    cdef cppclass EnumXdmAxis:
      pass

    cdef cppclass XdmNode(XdmItem):
        bool isAtomic()

        int getNodeKind()

        const char * getNodeName()

        const char * getLocalName();

        XdmValue * getTypedValue()

        const char* getBaseUri()

        XdmNode* getParent()

        XdmNode *getChild(int i, bool cache);

        const char* getAttributeValue(const char *str)

        int getAttributeCount()

        XdmNode** getAttributeNodes()

        int axisNodeCount()

        XdmNode **axisNodes(EnumXdmAxis axis)

        EnumXdmAxis convertEnumXdmAxis(int n)

        XdmNode** getChildren()

        int getChildCount()



cdef extern from "../../Saxon.C.API/XdmAtomicValue.h":
    cdef cppclass XdmAtomicValue(XdmItem):
        XdmAtomicValue() except +raise_py_error

        const char * getPrimitiveTypeName()

        bool getBooleanValue()

        double getDoubleValue()

        long getLongValue()

        int getHashCode()


        

cdef extern from "../../Saxon.C.API/XdmFunctionItem.h":
    cdef cppclass XdmFunctionItem(XdmItem):
        const char* getName()

        int getArity()

        XdmFunctionItem * getSystemFunction(SaxonProcessor * processor, const char * name, int arity)

        XdmValue * call(SaxonProcessor * processor, XdmValue ** arguments, int argument_length) except +raise_py_error

        XdmValue ** createXdmValueArray(int len)




cdef extern from "../../Saxon.C.API/XdmMap.h":
    cdef cppclass XdmMap(XdmFunctionItem):
        int mapSize()

        XdmValue * get(XdmAtomicValue* key)

        XdmValue * get(const char * key)

        XdmValue * get(int key)

        XdmValue * get(double key)

        XdmValue *  get(long key)

        XdmMap * put(XdmAtomicValue * key, XdmValue * value)

        XdmMap * remove(XdmAtomicValue* key)

        list[XdmAtomicValue*] keySet()

        XdmAtomicValue** keys()

        map[string, XdmValue*]& asMap()

        bool isEmpty()

        bool containsKey(XdmAtomicValue* key)

        XdmValue ** createXdmValueArray(int len)

        list[XdmValue*] valuesAsList()

        XdmValue** values()



cdef extern from "../../Saxon.C.API/XdmArray.h":
    cdef cppclass XdmArray(XdmFunctionItem):

        int arrayLength()

        XdmValue* get(int n)

        XdmArray* put(int n, XdmValue * value)

        XdmArray* addMember(XdmValue* value)

        XdmArray* concat(XdmArray * value)

        XdmValue ** createXdmValueArray(int len)

        list[XdmValue *] asList()

        XdmValue ** values()

        int getArity()
