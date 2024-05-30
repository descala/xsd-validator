"""@package saxonche
This documentation details the Python API for SaxonC, which has been written in cython for Python3.
SaxonC is produced by compiling the Java source code of Saxon to a native executable using GraalVM,
and adding APIs for C/C++, Python, and PHP.
SaxonC provides processing in XSLT 3.0, XQuery 3.1 and XPath 3.1, and Schema validation 1.0/1.1.
Main classes in SaxonC Python API: PySaxonProcessor, PyXslt30Processor, PyXsltExecutable, PyXQueryProcessor,
PySchemaValidator, PyXdmValue, PyXdmItem, PyXdmAtomicValue, PyXdmNode, PyXdmFunctionItem, PyXdmArray, and PyXdmMap."""
# distutils: language = c++
# distutils: sources = SaxonProcessor.cpp
# cython: language_level = 3

cimport saxoncClasses
from libcpp cimport bool
from libcpp.string cimport string
from libcpp.map cimport map
from cython.operator import dereference, postincrement
from os.path import isfile
import sys
import os
from enum import IntEnum

from libc.stdlib cimport free, malloc, realloc
from libc.string cimport memcpy

from cython import Py_ssize_t

from cpython.ref cimport PyObject

class PySaxonApiError(RuntimeError):
  pass

cdef public PyObject* pysaxonapierror = <PyObject*>PySaxonApiError


class XdmType(IntEnum):
    XDM_VALUE = 0
    XDM_ATOMIC_VALUE = 1
    XDM_NODE = 2
    XDM_FUNCTION_ITEM = 3
    XDM_MAP = 4
    XDM_ARRAY = 5
    XDM_EMPTY = 6
    XDM_ITEM = 7

class XdmNodeKind(IntEnum):
    ANCESTOR = 0
    ANCESTOR_OR_SELF = 1
    ATTRIBUTE = 2
    CHILD = 3
    DESCENDANT = 4
    DESCENDANT_OR_SELF = 5
    FOLLOWING = 6
    FOLLOWING_SIBLING = 7
    NAMESPACE = 8
    PARENT = 9
    PRECEDING = 10
    PRECEDING_SIBLING = 11
    SELF = 12



def create_xdm_dict(proc, mmap):
    """
    create_xdm_dict(proc, mmap)
    Function to create a dictionary of pairs of type (PyXdmAtomicValue, PyXdmValue) from primitive types
    Args:
        proc (PySaxonProcessor): PySaxonProcessor object required to create PyXdmValue objects from primitive types
        mmap (dict): The dict of key-value pairs to convert
    Returns:
        dict: Dictionary of (PyXdmAtomicValue, PyXdmValue) pairs
    Example:
        from saxonche import *
        with PySaxonProcessor(license=False) as saxonproc:
            mymap = {"a":saxonproc.make_integer_value(1), "b":saxonproc.make_integer_value(2),
                    "c":saxonproc.make_integer_value(3)}
            xdmdict = create_xdm_dict(saxonproc, mymap)
            map = saxonproc.make_map(xdmdict)
    Raises:
        PySaxonApiError: Failure in constructing the dict
    """
    xdmMap = {}
    xdmValue_ = None
    for (key, value) in mmap.items():
        if isinstance(key, str):
            xdmKey_ = proc.make_string_value(key)

            if isinstance(value, str):
                xdmValue_ = proc.make_sting_value(value)
            elif isinstance(value,int):
                xdmValue_ = proc.make_integer_value(value)
            elif isinstance(value,float):
                xdmValue_ = proc.make_integer_value(value)
            elif value in (True, False):
                xdmValue_ = proc.make_boolean_value(value)

            elif isinstance(value, PyXdmValue):
                xdmValue_ = value

            elif isinstance(value, PyXdmItem):
                xdmValue_ = value

            elif isinstance(value, PyXdmAtomicValue):
                xdmValue_ = value
            elif isinstance(value, PyXdmNode):
                xdmValue_ = value

            elif isinstance(value, PyXdmMap):
                xdmValue_ = value

            elif isinstance(value, PyXdmArray):
                xdmValue_ = value
            else:
                continue

            xdmMap[xdmKey_] = xdmValue_
        else:
                   raise Exception("Error in making Dictionary")

    return xdmMap

cdef char * make_c_str(str str_value, encoding='utf-8'):
            if str_value is None:
                return NULL
            else:
                py_string_string = str_value.encode(encoding) if str_value is not None else None
                c_string = py_string_string if str_value is not None else ""
                return c_string

cdef char * from_make_c_str(str str_value, encoding='utf-8'):
    if str_value is None:
        return NULL
    else:
        py_string_string = str_value.encode(encoding).decode('UTF-8') if str_value is not None else None
        c_string = py_string_string if str_value is not None else ""
        return c_string

cdef char * out_make_c_str(str str_value, encoding='utf-8'):
     if str_value is None:
         return NULL
     else:
         py_string_string = str_value.encode('UTF-8').decode(encoding) if str_value is not None else None
         c_string = py_string_string if str_value is not None else ""
         return c_string


cdef char * make_c_str2(str_value, encoding='utf-8'):
    cdef char         *line
    cdef Py_ssize_t   i
    cdef Py_ssize_t   length = 0
    cdef Py_ssize_t   incrlength
    cdef char         *out = <char *>malloc(1)  # Reallocate as needed

    py_string_string = str_value.encode(encoding) if str_value is not None else None
    line = py_string_string if str_value is not None else ""

    try:
        out[0] = b'\x00'.encode('ascii') # keep C-strings null-terminated
        incrlength = len(line)
        out = <char *>realloc(out, length + incrlength + 1)
        memcpy(out + length, line, incrlength)
        length += incrlength
        out[length] = '\x00'.encode('ascii')  # keep C-strings null-terminated
        return out  # autoconversion back to a Python string

    finally:
       free(out)


cdef str make_py_str(const char * c_value, encoding='utf-8'):
    try:
        ustring = c_value.decode(encoding) if c_value is not NULL else None
        return ustring
    except UnicodeError as ex:
        raise PySaxonApiError(ex)

cdef class PySaxonProcessor:
    """A PySaxonProcessor acts as a factory for generating XQuery, XPath, Schema and XSLT compilers.
    This class is itself the context that needs to be managed (i.e. allocation & release)
    Example:
        from saxonche import *
        with PySaxonProcessor(license=False) as proc:
            print("Test SaxonC on Python")
            print(proc.version)
            xdmAtomicval = proc.make_boolean_value(False)
            xslt30proc = proc.new_xslt30_processor()
    """
    cdef saxoncClasses.SaxonProcessor *thisptr      # hold a C++ instance which we're wrapping
    cdef bool _release  #  flag to indicate if this PySaxonProcessor should call release
    ##
    # The Constructor
    # @param license Flag that a license is to be used
    # @contextlib.contextmanager
    def __cinit__(self, config_file= None, license=False,  releasei=False):
        """
        __cinit__(self, config_file=None, license=False, releasei=False)
        The constructor.
        Args:
            config_file (str): Construct a Saxon processor based on a configuration file
            license(bool): Flag that a license is to be used. The Default is false.
        Raises:
            PySaxonApiError: Failure to create PySaxonProcessor
        """
        cdef const char * c_str = NULL
        cdef bool l = license
        self._release = releasei
        if config_file is not None:
            '''make_c_str(config_file)'''
            py_config_string = config_file.encode('UTF-8') if config_file is not None else None
            c_str = py_config_string if config_file is not None else ""
            if c_str is not NULL:
                self.thisptr = new saxoncClasses.SaxonProcessor(c_str)
                self.thisptr.setcwd(os.getcwd().encode('UTF-8'))
        else:
            try:
                self.thisptr = new saxoncClasses.SaxonProcessor(l)
                self.thisptr.setcwd(os.getcwd().encode('UTF-8'))
            except:
                raise Exception("Failed to create PySaxonProcessor object") from None

    def __dealloc__(self):
        """The destructor."""
        if self.thisptr is not NULL:
          del self.thisptr
          self.thisptr = NULL
        if self._release is True:
            self.thisptr.release()
    def __enter__(self):
      """enter method for use with the keyword 'with' context
      Deprecated. This may be removed in a later release. """
      return self

    def __exit__(self, exception_type, exception_value, traceback):
        """Deprecated. This method no longer does anything, and may be removed in a later release. """

        ''' if self.thisptr is not NULL:
          del self.thisptr
          self.thisptr = NULL        
        self.thisptr.release()'''


    property version:
        """
        Get the Saxon Version.
        Returns:
            str: The Saxon version
        """
        def __get__(self):
            cdef const char* c_string = self.thisptr.version()
            py_string_i = make_py_str(c_string)
            return py_string_i

    @property
    def attach_current_thread(self):
        self.thisptr.attachCurrentThread()

    @property
    def detach_current_thread(self):
        self.thisptr.detachCurrentThread()

    @property
    def cwd(self):
        """
        cwd(self)
        Property represents the current working directory
        """
        cdef const char* c_string = self.thisptr.getcwd()
        py_string_i = make_py_str(c_string)
        return py_string_i

    def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory
        Args:
            cwd (str): current working directory
        """
        cdef char * c_str_ = NULL
        '''make_c_str(cwd)'''
        py_cwd_string = cwd.encode('UTF-8') if cwd is not None else None
        c_str_ = py_cwd_string if cwd is not None else ""
        self.thisptr.setcwd(c_str_)
    def set_resources_directory(self, dir_):
        """
        set_resources_directory(self, dir_)
        Set the resources directory
        Args:
            dir_ (str): A string of the resources directory which Saxon will use
        """
        cdef char * c_str_ = NULL
        '''make_c_str(dir_)'''
        py_dir_string = dir_.encode('UTF-8') if dir_ is not None else None
        c_str_ = py_dir_string if dir_ is not None else ""
        self.thisptr.setResourcesDirectory(c_str_)
    @property
    def resources_directory(self):
        """
        resources_directory(self)
        Property represents the resources directory
        """
        cdef const char* c_string = self.thisptr.getResourcesDirectory()
        py_string_i = make_py_str(c_string)
        return py_string_i

    def set_configuration_property(self, name, value, encoding=None):
        """
        set_configuration_property(self, name, value, encoding=None)
        Set configuration property specific to the processor in use.
        Properties set here are common across all processors.
        Args:
            name (str): The name of the property
            value (str): The value of the property
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Example:
            'l': 'on' or 'off' - to enable the line number
        """
        cdef char * c_str_ = NULL
        '''make_c_str(name)'''
        if encoding is None:
            encoding = sys.getdefaultencoding()
            
        py_name_string = name.encode(encoding) if name is not None else None
        c_str_ = py_name_string if name is not None else ""
        cdef char * c_value_str_ = NULL
        '''make_c_str(value)'''
        py_value_string = value.encode(encoding) if value is not None else None
        c_value_str_ = py_value_string if value is not None else ""
        self.thisptr.setConfigurationProperty(c_str_, c_value_str_)

    def clear_configuration_properties(self):
        """
        clear_configuration_properties(self)
        Clear the configuration properties in use by the processor
        """
        self.thisptr.clearConfigurationProperties()

    @property
    def is_schema_aware(self):
        """
        is_schema_aware(self)
        Property to check if the processor is schema aware. A licensed SaxonC-EE product is schema aware
        Returns:
            bool: True if the processor is schema aware, or False otherwise
        """
        return self.thisptr.isSchemaAwareProcessor()

    def new_document_builder(self):
        """
        new_document_builder(self)
        Create a PyDocumentBuilder. A PyDocumentBuilder holds properties controlling how a Saxon document tree should
        be built, and provides methods to invoke the tree construction.
        Returns:
            PyDocumentBuilder: a newly created PyDocumentBuilder
        """
        cdef PyDocumentBuilder val = PyDocumentBuilder()
        val.thisdbptr = self.thisptr.newDocumentBuilder()
        return val

    def new_xslt30_processor(self):
        """
        new_xslt30_processor(self)
        Create a PyXslt30Processor. A PyXslt30Processor is used to compile and execute XSLT 3.0 stylesheets.
        Returns:
            PyXslt30Processor: a newly created PyXslt30Processor
        """
        cdef PyXslt30Processor val = PyXslt30Processor()
        val.thisxptr = self.thisptr.newXslt30Processor()
        return val
    def new_xquery_processor(self):
        """
        new_xquery_processor(self)
        Create a PyXqueryProcessor. A PyXQueryProcessor is used to compile and execute XQuery queries.
        Returns:
            PyXQueryProcessor: a newly created PyXQueryProcessor
        """
        cdef PyXQueryProcessor val = PyXQueryProcessor()
        val.thisxqptr = self.thisptr.newXQueryProcessor()
        return val
    def new_xpath_processor(self):
        """
        new_xpath_processor(self)
        Create a PyXPathProcessor. A PyXPathProcessor is used to compile and execute XPath expressions.
        Returns:
            PyXPathProcessor: a newly created XPathProcessor
        """
        cdef PyXPathProcessor val = PyXPathProcessor()
        val.thisxpptr = self.thisptr.newXPathProcessor()
        return val
    def new_schema_validator(self):
        """
        new_schema_validator(self)
        Create a PySchemaValidator which can be used to validate instance documents against the schema held by
        this processor.
        Returns:
            PySchemaValidator: a newly created PySchemaValidator
        """
        cdef PySchemaValidator val = PySchemaValidator()
        val.thissvptr = self.thisptr.newSchemaValidator()
        if val.thissvptr is NULL:
            raise Exception("Error: Saxon Processor is not licensed for schema processing!")
        return val



    def eqname_to_clark_name(self, name, encoding=None):
        """
        eqname_to_clark_name(self, name, encoding=None)
        Convert EQName string to clark name notation.
        Args:
            name (str): The URI in EQName notation: <code>Q{uri}local</code> if the name is in a namespace.
                For a name in no namespace, either of the forms <code>Q{}local</code> or simply <code>local</code>
                are accepted.
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: the URI inb clark notation
        """
        cdef char * c_str_
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_name_string = name.encode(encoding) if name is not None else None
        c_str_ = py_name_string if name is not None else ""
        cdef const char* c_string = self.thisptr.EQNameToClarkName(c_str_)
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

    def clark_name_to_eqname(self, name, encoding=None):
        """
        clark_name_to_eqname(self, name, encoding=None)
        Convert clark name string to EQName notation; i.e. the expanded name, as a string using the notation defined
        by the EQName production in XPath 3.0. If the name is in a namespace, the resulting string takes the form
        <code>Q{uri}local</code>. Otherwise, the value is the local part of the name.
        Args:
            name (str): The URI in Clark notation: <code>{uri}local</code> if the name is in a namespace,
                or simply <code>local</code> if not.
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: the expanded name, as a string using the notation defined by the EQName production in XPath 3.0.
        """
        cdef char * c_str_
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_name_string = name.encode(encoding) if name is not None else None
        c_str_ = py_name_string if name is not None else ""
        cdef const char* c_string = self.thisptr.clarkNameToEQName(c_str_)
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i


    def make_string_value(self, value, encoding = None):
        """
        make_string_value(self, value, encoding = None)
        Factory method. Unlike the constructor, this avoids creating a new StringValue in the case
        of a zero-length string (and potentially other strings, in future)
        Args:
            value (str): The String value. NULL is taken as equivalent to "".
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            PyXdmAtomicValue: The corresponding XDM string value
        """
        cdef char * c_str_
        cdef char * c_encoding_str_ = NULL
        py_encoding_string = None

        py_value_string = value.encode(encoding if encoding is not None else sys.getdefaultencoding()) if value is not None else None
        c_str_ = py_value_string if value is not None else ""

        if encoding is not None:
            py_encoding_string = encoding.encode('UTF-8') if encoding is not None else None
            c_encoding_str_ = py_encoding_string if value is not None else ""

        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeStringValue(c_str_, c_encoding_str_)

        return val
    
    def make_integer_value(self, value):
        """
        make_integer_value(self, value)
        Factory method: makes either an Int64Value or a BigIntegerValue depending on the value supplied
        Args:
            value (int): The supplied primitive integer value
        Returns:
            PyXdmAtomicValue: The corresponding XDM value which is a BigIntegerValue or Int64Value as appropriate
        """
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeIntegerValue(value)
        return val
    def make_double_value(self, value):
        """
        make_double_value(self, value)
        Factory method: makes a double value
        Args:
            value (double): The supplied primitive double value
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeDoubleValue(value)
        return val
    def make_float_value(self, value):
        """
        make_float_value(self, value)
        Factory method: makes a float value
        Args:
            value (float): The supplied primitive float value
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeFloatValue(value)
        return val
    def make_long_value(self, value):
        """
        make_long_value(self, value)
        Factory method: makes either an Int64Value or a BigIntegerValue depending on the value supplied
        Args:
            value (long): The supplied primitive long value
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeLongValue(value)
        return val
    def make_boolean_value(self, value):
        """
        make_boolean_value(self, value)
        Factory method: makes a PyXdmAtomicValue representing a boolean value
        Args:
            value (bool): True or False, to determine which boolean value is required
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        cdef bool c_b = value
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeBooleanValue(c_b)
        return val
    def make_qname_value(self, str_, encoding=None):
        """
        make_qname_value(self, str_, encoding=None)
        Create a QName XDM value from string representation in clark notation
        Args:
            str_ (str): The value given in a string form in clark notation {uri}local
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_value_string = str_.encode(encoding) if str_ is not None else None
        cdef char * c_str_ = py_value_string if str_ is not None else ""
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeQNameValue(c_str_)
        return val
    def make_atomic_value(self, value_type, value, encoding=None):
        """
        make_atomic_value(self, value_type, value, encoding=None)
        Create an XDM atomic value from string representation
        Args:
            value_type (str): Local name of a type in the XML Schema namespace
            value (str): The value given in a string form. In the case of a QName the value supplied must be
                in clark notation {uri}local.
            encoding (str): The encoding of the value_type. If not specified then the platform default encoding is used.
        Returns:
            PyXdmAtomicValue: The corresponding XDM value
        """
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_valueType_string = value_type.encode(encoding) if value_type is not None else None
        cdef char * c_valueType_string = py_valueType_string if value_type is not None else ""
        cdef PyXdmAtomicValue val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = val.thisvptr = self.thisptr.makeAtomicValue(c_valueType_string, value)
        if val.derivedaptr == NULL:
            del val
            return None

        return val

    def make_array(self, list values):
        """
        make_array(self, list values)
        Make a PyXdmArray whose members are from a list of PyXdmValues
        Args:
            values (list): List of PyXdmValues
        Returns:
            PyXdmArray: The corresponding value
        """
        cdef int len_ = len(values)
        cdef saxoncClasses.XdmValue ** argumentV = self.thisptr.createXdmValueArray(len_)
        cdef PyXdmArray newArray_ = None
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmItem ivalue_
        cdef PyXdmNode nvalue_
        cdef PyXdmArray aavalue_
        cdef PyXdmMap mvalue_
        cdef PyXdmFunctionItem fvalue_
        cdef PyXdmValue value_

        for x in range(len_):
          if isinstance(values[x], PyXdmValue):
            value_ = values[x]
            argumentV[x] = value_.thisvptr
          elif isinstance(values[x], PyXdmItem):
            ivalue_ = values[x]
            argumentV[x] = <saxoncClasses.XdmValue*>ivalue_.derivedptr
          elif isinstance(values[x], PyXdmAtomicValue):
            avalue_ = values[x]
            argumentV[x] = <saxoncClasses.XdmValue*> avalue_.derivedaptr
          elif isinstance(values[x], PyXdmNode):
            nvalue_ = values[x]
            argumentV[x] =  <saxoncClasses.XdmValue *>nvalue_.derivednptr
          elif isinstance(values[x], PyXdmArray):
            aavalue_ = values[x]
            argumentV[x] =  <saxoncClasses.XdmValue *>aavalue_.derivedaaptr
          elif isinstance(values[x], PyXdmMap):
            mvalue_ = values[x]
            argumentV[x] =  <saxoncClasses.XdmValue *>mvalue_.derivedmmptr
          else:
            raise Exception("Argument value at position " , x , " is not of type PyXdmValue. The following object found: ", type(values[x]))
          argumentV[x].incrementRefCount()

        newArray_ = PyXdmArray()
        newArray_.derivedaaptr = newArray_.derivedfptr = newArray_.derivedptr = newArray_.thisvptr =  self.thisptr.makeArray(argumentV, len_)
        if len_ > 0:
            self.thisptr.deleteXdmValueArray(argumentV, len_)
        if newArray_.derivedaaptr == NULL:
            del newArray_
            return None
        return newArray_



    def make_map(self, dict dataMap):
        """
        make_map(self, dict dataMap)
        Make a PyXdmMap from a dict type whose entries are key-value pairs of type (PyXdmAtomicValue, PyXdmValue).
        The factory method create_xdm_dict(proc, mmap) can be used to create pairs of type (PyXdmAtomicValue, PyXdmValue)
        from primitive types, which can then be used as input to this function make_map.
        Args:
            dataMap (dict): Dictionary of (PyXdmAtomicValue, PyXdmValue) pairs
        Returns:
            PyXdmMap: The corresponding value
        Example:
            mymap = {"a":saxonproc.make_integer_value(1), "b":saxonproc.make_integer_value(2),
                    "c":saxonproc.make_integer_value(3)}
            xdmdict = create_xdm_dict(saxonproc, mymap)
            map = saxonproc.make_map(xdmdict)
        """
        cdef int len_ = len(dataMap)
        cdef saxoncClasses.XdmValue ** c_values = self.thisptr.createXdmValueArray(len_)
        cdef saxoncClasses.XdmAtomicValue ** c_keys = self.thisptr.createXdmAtomicValueArray(len_)
        cdef PyXdmValue value_
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmAtomicValue key_
        cdef const char * c_key = NULL
        cdef char * c_key_str = NULL
        cdef PyXdmMap newMap_ = None
        cdef int i = 0
        '''global parametersDict
        if kwds is not None:
                parametersDict = kwds '''
        for (key, value) in dataMap.items():

            if isinstance(key, PyXdmAtomicValue):
                avalue_ = key
                c_keys[i]=avalue_.derivedaptr
                avalue_.derivedaptr.incrementRefCount()

                if isinstance(value, PyXdmValue) or isinstance(value, PyXdmAtomicValue) or isinstance(value, PyXdmItem) or isinstance(value, PyXdmNode) or isinstance(value, PyXdmMap) or isinstance(value, PyXdmArray) or isinstance(value, PyXdmFunctionItem):
                     value_ = value
                     c_values[i] = value_.thisvptr
                     value_.thisvptr.incrementRefCount()

                else:
                       raise Exception("Error in making PyXdmMap")

            else:
                 raise Exception("Error in the making of the PyXdmMap - wrong key type")
            i +=1

        if len_ == 0:
            return None

        newMap_ = PyXdmMap()
        newMap_.derivedmmptr = newMap_.derivedfptr = newMap_.derivedptr = newMap_.thisvptr =  self.thisptr.makeMap3(c_keys, c_values, len_)
        if len_ > 0:
            self.thisptr.deleteXdmAtomicValueArray(c_keys, len_)
            self.thisptr.deleteXdmValueArray(c_values, len_)
        if newMap_.derivedmmptr == NULL:
            return None
        return newMap_


    def make_map2(self, dict dataMap, encoding = None):
        """
        make_map2(self, dict dataMap, encoding = None)
        Make a PyXdmMap from a dict type whose entries are key-value pairs of type (str, PyXdmValue).
        Args:
            dataMap (dict): Dictionary of (str, PyXdmValue) pairs
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            PyXdmMap: The corresponding value
        """
        cdef map[string , saxoncClasses.XdmValue * ] c_dataMap
        cdef PyXdmValue value_
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmAtomicValue key_
        cdef const char * c_key = NULL
        cdef char * c_key_str = NULL
        cdef PyXdmMap newMap_ = None
        if encoding is None:
            encoding = sys.getdefaultencoding()
        '''global parametersDict
        if kwds is not None:
                parametersDict = kwds '''
        for (key, value) in dataMap.items():

            if isinstance(key, str):
                 key_str = key.encode(encoding)
                 py_key_str = key.encode(encoding) if key is not None else None
                 c_key_str = py_key_str if key_str is not None else ""
                 c_key = c_key_str


                 if isinstance(value, PyXdmValue):
                     value_ = value

                     c_dataMap[c_key] = <saxoncClasses.XdmValue *> value_.thisvptr
                 elif isinstance(value, PyXdmAtomicValue):

                     avalue_ = value

                     c_dataMap[c_key] = <saxoncClasses.XdmValue *> avalue_.derivedaptr


                 else:
                       raise Exception("Error in making PyXdmMap")

            else:
                 raise Exception("Error in the making of the PyXdmMap - wrong key type")




        if len(dataMap) == 0:
            return None

        newMap_ = PyXdmMap()
        newMap_.derivedmmptr = newMap_.derivedfptr = newMap_.derivedptr = newMap_.thisvptr =  self.thisptr.makeMap2(c_dataMap)
        if newMap_.derivedmmptr == NULL:
            return None
        return newMap_


    def set_catalog(self, str file_name):
        """
        set_catalog(self, str file_name)
        Set the XML catalog to be used in Saxon
        This method is now deprecated. Use set_catalog_files
        Args:
            file_name (str): The file name for the XML catalog
        """
        cdef const char * c_filename_string = NULL
        '''make_c_str(file_name)'''
        py_name_string = file_name.encode('UTF-8') if file_name is not None else None
        c_filename_string = py_name_string if file_name is not None else ""
        if c_filename_string is not NULL:
            self.thisptr.setCatalog(c_filename_string)

    def set_catalog_files(self, list file_names):
        """
        set_catalog_files(self, str file_name)
        Set the XML catalog files to be used in Saxon
        Args:
            file_names list: List of strings for the XML catalog file names
        """
        cdef const char * c_filename_string = NULL
        '''make_c_str(file_name)'''

        cdef int _len = len(file_names)
        cdef const char ** catalog_files_array = <const char**>malloc(_len * sizeof(char*))
        for x in range(_len):
            file_name = file_names[x]
            c_filename_string = NULL
            py_name_string = file_name.encode('UTF-8') if file_name is not None else None
            c_filename_string = py_name_string if file_name is not None else ""
            if c_filename_string is not NULL:
                catalog_files_array[x] = c_filename_string
            else:
                raise Exception("Found None catalog file")

        self.thisptr.setCatalogFiles(catalog_files_array, _len)
        free(catalog_files_array)


    def get_string_value(self, PyXdmItem item):
        """
        get_string_value(self, PyXdmItem item)
        Get the string value of the supplied PyXdmItem, as defined in the XPath data model
        Args:
            item (PyXdmItem): An XDM item
        Returns:
            str: The string value of this XDM item
        """
        cdef const char * c_string = self.thisptr.getStringValue(item.derivedptr)
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

    def parse_xml(self, **kwds):
        """
        parse_xml(self, **kwds)
        Parse a source XML document supplied as a lexical representation, source file or uri, and return it as an XDM node
        Args:
            **kwds: Possible keyword arguments: one of the following (xml_file_name|xml_text|xml_uri) is required.
            The keyword 'encoding' (str) can be used to specify the encoding used to decode the xml_text string
            (if not specified then the platform default encoding is used).
        Returns:
            PyXdmNode: The XDM node representation of the XML document
        Raises:
            Exception: Error if invalid use of keywords
        """
        py_error_message = "Error: parse_xml should contain exactly one of the following keyword arguments: (xml_file_name|xml_text|xml_uri)"
        if kwds.keys() >= {"xml_file_name", "xml_text"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"xml_file_name", "xml_uri"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"xml_text", "xml_uri"}:
            raise Exception(py_error_message)
        cdef PyXdmNode val = None
        cdef str py_value = None
        cdef char * c_xml_string = NULL
        cdef char * c_encoding_string = NULL
        encoding = None

        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string if py_encoding_string is not None else ""

        if "xml_text" in kwds:
          py_value = kwds["xml_text"]
          if py_value is None:
              raise Exception("XML text is None")
          '''c_xml_string = make_c_str(py_value)'''
          py_text_string = py_value.encode(encoding if encoding is not None else sys.getdefaultencoding()) if py_value is not None else None
          c_xml_string = py_text_string if py_value is not None else ""
          if c_xml_string == NULL:
              raise Exception("Error converting XML text")
          val = PyXdmNode()

          val.derivednptr =  val.derivedptr = val.thisvptr =self.thisptr.parseXmlFromString(c_xml_string, c_encoding_string, NULL)

          if val.derivednptr == NULL:
              return None
          val.derivednptr.incrementRefCount()

          return val
        elif "xml_file_name" in kwds:
          py_value  = kwds["xml_file_name"]

          '''if py_value  is None or isfile(py_value) == False or isfile(make_py_str(self.thisptr.getcwd())+"/"+py_value) == False:
            raise Exception("XML file does not exist")'''
          '''c_xml_string = make_c_str(py_value)'''
          py_value_string = py_value.encode('UTF-8') if py_value is not None else None
          c_xml_string = py_value_string if py_value is not None else ""
          val = PyXdmNode()
          val.derivednptr = val.derivedptr = val.thisvptr = self.thisptr.parseXmlFromFile(c_xml_string, NULL)
          val.derivednptr.incrementRefCount()
          if val.derivednptr is NULL:
              return None
          return val
        elif "xml_uri" in kwds:
          py_value = kwds["xml_uri"]
          py_uri_string = py_value.encode('UTF-8') if py_value is not None else None
          c_xml_string = py_uri_string if py_value is not None else ""
          val = PyXdmNode()
          val.derivednptr = val.derivedptr = val.thisvptr = self.thisptr.parseXmlFromUri(c_xml_string, NULL)
          if val.derivednptr is NULL:
              return None
          val.derivednptr.incrementRefCount()

          return val
        else:
           raise Exception(py_error_message)

    def parse_json(self, **kwds):
        """
        parse_json(self, **kwds)
        Parse a source JSON document supplied as a lexical representation or source file, and return it as an XDM value
        Args:
            **kwds: Possible keyword arguments: one of the following (json_file_name|json_text) is required.
            The keyword 'encoding' (str) can be used to specify the encoding used to decode the json_text string
            (if not specified then the platform default encoding is used).

        Returns:
            PyXdmValue: The XDM value representation of the JSON document
        Raises:
            Exception: Error if invalid use of keywords
        """
        py_error_message = "Error: parse_json should contain exactly one of the following keyword arguments: (json_file_name|json_text)"
        if kwds.keys() >= {"json_file_name", "json_text"}:
            raise Exception(py_error_message)
        cdef PyXdmValue val = None
        cdef str py_value = None
        cdef char * c_json_string = NULL
        cdef char * c_encoding_string = NULL
        cdef str encoding = None

        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode("UTF-8")
            c_encoding_string = py_encoding_string

        if "json_text" in kwds:
          py_value = kwds["json_text"]
          if py_value is None:
              raise Exception("JSON text is None")
          py_text_string = py_value.encode(encoding if encoding is not None else sys.getdefaultencoding()) if py_value is not None else None
          c_json_string = py_text_string if py_value is not None else ""
          if c_json_string == NULL:
              raise Exception("Error converting JSON text")
          val = PyXdmValue()
          val.thisvptr = self.thisptr.parseJsonFromString(c_json_string, c_encoding_string if encoding is not None else NULL)
          if val.thisvptr is NULL:
              return None
          val.thisvptr.incrementRefCount()
          return val
        elif "json_file_name" in kwds:
          py_value  = kwds["json_file_name"]
          py_value_string = py_value.encode('UTF-8') if py_value is not None else None
          c_json_string = py_value_string if py_value is not None else ""
          val = PyXdmValue()
          val.thisvptr = self.thisptr.parseJsonFromFile(c_json_string)
          if val.thisvptr is NULL:
              return None
          val.thisvptr.incrementRefCount()

          return val
        else:
           raise Exception(py_error_message)

    @property
    def exception_occurred(self):
        """
        exception_occurred(self)
        Property to check if an exception has occurred internally within SaxonC
        Returns:
            boolean: True if an exception has been reported; otherwise False
        """
        return self.thisptr.exceptionOccurred()

    def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown internally in SaxonC.
        """
        self.thisptr.exceptionClear()

    @property
    def error_message(self):
       """
       error_message(self)
       The PySaxonProcessor may have a number of errors reported against it. Get the error message
       if there are any errors.
       Returns:
           str: The message of the exception. Returns None if the exception does not exist.
       """
       cdef const char* c_string = self.thisptr.getErrorMessage()
       ustring = make_py_str(c_string)
       return ustring


cdef class PyDocumentBuilder:
    """
    A PyDocumentBuilder holds properties controlling how a Saxon document tree should be built, and
    provides methods to invoke the tree construction.
    This class has no public constructor. To construct a PyDocumentBuilder, use the factory method
    PySaxonProcessor.new_document_builder().
    """
    cdef saxoncClasses.DocumentBuilder *thisdbptr      # hold a C++ instance which we're wrapping
    def __cinit__(self):
       """Default constructor """
       self.thisdbptr = NULL
    def __dealloc__(self):
       if self.thisdbptr != NULL:
          del self.thisdbptr

    @property
    def line_numbering(self):
        """
        line_numbering(self)
        bool: true if line numbering is enabled
        """
        return self.thisdbptr.isLineNumbering()

    def set_line_numbering(self, value):
        """
        set_line_numbering(self, value)
        Set whether line and column numbering and is to be enabled for documents constructed using this
        PyDocumentBuilder. By default, line and column numbering is disabled.
        Args:
            value (bool): true if line numbers are to be maintained, false otherwise
        """
        cdef bool c_line
        c_line = value
        self.thisdbptr.setLineNumbering(c_line)


    @property
    def dtd_validation(self):
        """
        dtd_validation(self)
        bool: Ask whether DTD validation is to be applied to documents loaded using this PyDocumentBuilder
        """
        return self.thisdbptr.isDTDValidation()

    def set_dtd_validation(self, value):
        """
        set_dtd_validation(self, value)
        Set whether DTD validation should be applied to documents loaded using this PyDocumentBuilder.
        By default, no DTD validation takes place.
        Args:
            value (bool): true if DTD validation should be applied to loaded documents
        """
        cdef bool c_dtd
        c_dtd = value
        self.thisdbptr.setDTDValidation(c_dtd)

    def set_schema_validator(self, PySchemaValidator val):
       """
       set_schema_validator(self, PySchemaValidator val)
       Set the PySchemaValidator to be used. This determines whether schema validation is applied to an input
       document and whether type annotations in a supplied document are retained. If no PySchemaValidator is supplied,
       then schema validation does not take place.
       This option requires the schema-aware version of the Saxon product (SaxonC-EE).
       Since a PySchemaValidator is serially reusable but not thread-safe, using this method is not appropriate when
       the PyDocumentBuilder is shared between threads.
       Args:
           val (PySchemaValidator): the schema validator to be used
       """
       if val is None:
           self.thisdbptr.setSchemaValidator(NULL)
       else:
           self.thisdbptr.setSchemaValidator(val.thissvptr)


    def get_schema_validator(self):
       """
       get_schema_validator(self)
       Get the PySchemaValidator used to validate documents loaded using this PyDocumentBuilder
       Returns:
           PySchemaValidator: if one has been set; otherwise None.
       """
       cdef PySchemaValidator val = PySchemaValidator()
       val.thissvptr = self.thisdbptr.getSchemaValidator()
       if val.thissvptr is NULL:
           raise Exception("Error: Saxon Processor is not licensed for schema processing!")
       return val

    @property
    def base_uri(self):
       """
       base_uri(self)
       Get the base URI of documents loaded using this PyDocumentBuilder when no other URI is available.
       Returns:
           str: String value of the base URI to be used. This may be NULL if no value has been set.
       """
       cdef const char * c_string = self.thisdbptr.getBaseUri()
       py_string_i = make_py_str(c_string)
       return py_string_i

    def set_base_uri(self, base_uri):
       """
       set_base_uri(self, base_uri)
       Set the base URI of a document loaded using this PyDocumentBuilder. This is used for resolving any relative
       URIs appearing within the document, for example in references to DTDs and external entities. This information
       is required when the document is loaded from a source that does not provide an intrinsic URI, notably when
       loading from a String. The value is ignored when loading from a source that does have an intrinsic base URI.
       Args:
           base_uri (str): the base output URI
       """
       py_uri_string = base_uri.encode('UTF-8') if base_uri is not None else None
       cdef char * c_uri = py_uri_string if base_uri is not None else ""
       self.thisdbptr.setBaseUri(c_uri)

    def parse_xml(self, **kwds):
        """
        parse_xml(self, **kwds)
        Parse a source document supplied as a lexical representation, source file or uri, and return it as XDM node
        Args:
            **kwds: Possible keyword arguments: one of the following (xml_file_name|xml_text|xml_uri) is required.
            The keyword 'encoding' (str) can be used to specify the encoding used to decode the xml_text string
            (if not specified then the platform default encoding is used).
        Returns:
            PyXdmNode: The XDM node representation of the XML document
        Raises:
            Exception: Error if invalid use of keywords.
            PySaxonApiError: Error if failure to parse XML file or XML text
        """
        py_error_message = "Error: parse_xml should contain exactly one of the following keyword arguments: (xml_file_name|xml_text|xml_uri)"
        if kwds.keys() >= {"xml_file_name", "xml_text"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"xml_file_name", "xml_uri"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"xml_text", "xml_uri"}:
            raise Exception(py_error_message)
        cdef PyXdmNode val = None
        cdef py_value = None
        cdef char * c_xml_string = NULL
        cdef char * c_encoding_string = NULL
        encoding = None

        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string

        if "xml_text" in kwds:
          py_value = kwds["xml_text"]
          py_xml_text_string = py_value.encode(encoding if encoding is not None else sys.getdefaultencoding()) if py_value is not None else None
          c_xml_string = py_xml_text_string if py_value is not None else ""
          val = PyXdmNode()
          val.derivednptr = val.derivedptr = val.thisvptr = self.thisdbptr.parseXmlFromString(c_xml_string, c_encoding_string)
          val.derivednptr.incrementRefCount()
          return val
        elif "xml_file_name" in kwds:
          py_value = kwds["xml_file_name"]
          py_filename_string = py_value.encode('UTF-8') if py_value is not None else None
          '''if py_filename_string  is None or isfile(py_filename_string) == False:
            raise Exception("XML file does not exist")'''
          c_xml_string = py_filename_string if py_value is not None else ""
          val = PyXdmNode()
          val.derivednptr = val.derivedptr = val.thisvptr = self.thisdbptr.parseXmlFromFile(c_xml_string)
          val.derivednptr.incrementRefCount()
          return val
        elif "xml_uri" in kwds:
          py_value = kwds["xml_uri"]
          py_uri_string = py_value.encode('UTF-8') if py_value is not None else None
          c_xml_string = py_uri_string if py_value is not None else ""
          val = PyXdmNode()
          val.derivednptr = val.derivedptr = val.thisvptr = self.thisdbptr.parseXmlFromUri(c_xml_string)
          val.derivednptr.incrementRefCount()
          return val
        else:
           raise Exception(py_error_message)



parametersDict = None


cdef class PyXslt30Processor:
     """A PyXslt30Processor represents a factory to compile, load and execute stylesheets.
     It is possible to cache the context and the stylesheet in the PyXslt30Processor. """
     cdef saxoncClasses.Xslt30Processor *thisxptr      # hold a C++ instance which we're wrapping

     def __cinit__(self):
        """Default constructor """
        self.thisxptr = NULL
     def __dealloc__(self):
        if self.thisxptr != NULL:
           del self.thisxptr
     def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory.
        Args:
            cwd (str): current working directory
        """
        cdef char * c_cwd = NULL
        '''make_c_str(cwd)'''
        py_cwd_string = cwd.encode('UTF-8') if cwd is not None else None
        c_cwd = py_cwd_string if cwd is not None else ""
        self.thisxptr.setcwd(c_cwd)

     def set_jit_compilation(self, bool jit):
        """
        set_jit_compilation(self, bool jit)
        Say whether just-in-time compilation of template rules should be used.
        Args:
            jit (bool): True if just-in-time compilation is to be enabled. With this option enabled,
                static analysis of a template rule is deferred until the first time that the
                template is matched. This can improve performance when many template
                rules are rarely used during the course of a particular transformation; however,
                it means that static errors in the stylesheet will not necessarily cause the
                compile(Source) method to throw an exception (errors in code that is
                actually executed will still be notified but this may happen after the compile(Source)
                method returns). This option is enabled by default in SaxonC-EE, and is not available
                in SaxonC-HE or SaxonC-PE.
                Recommendation: disable this option unless you are confident that the
                stylesheet you are compiling is error-free.
        """
        cdef bool c_jit
        c_jit = jit
        self.thisxptr.setJustInTimeCompilation(c_jit)
        #else:
        #raise Warning("setJustInTimeCompilation: argument must be a boolean type. JIT not set")

     def set_parameter(self, name, PyXdmValue value, encoding = None):
        """
        set_parameter(self, name, PyXdmValue value, encoding = None)
        Set the value of a stylesheet parameter
        Args:
            name (str): the name of the stylesheet parameter, as a string. For a namespaced parameter use
                clark notation {uri}local
            value (PyXdmValue): the value of the stylesheet parameter, or NULL to clear a previously set value
            encoding (str): The encoding of the name string. If not specified then the platform default encoding is used.
        """
        cdef const char * c_str = NULL
        '''make_c_str(name)'''
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_name_string = name.encode(encoding) if name is not None else None
        c_str = py_name_string if name is not None else ""
        if value is None:
            return
        if c_str is not NULL:
            value.thisvptr.incrementRefCount()
            self.thisxptr.setParameter(c_str, value.thisvptr)

     def get_parameter(self, name, encoding=None):
        """
        get_parameter(self, name, encoding=None)
        Get a parameter value by a given name
        Args:
            name (str): The name of the stylesheet parameter
            encoding (str): The encoding of the name string. If not specified then the platform default encoding is used.
        Returns:
            PyXdmValue: The XDM value of the parameter
        """
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_name_string = name.encode(encoding) if name is not None else None
        cdef char * c_name = py_name_string if name is not None else ""
        cdef PyXdmValue val = PyXdmValue()
        val.thisvptr = self.thisxptr.getParameter(c_name)
        return val
     def remove_parameter(self, name, encoding=None):
        """
        remove_parameter(self, name, encoding=None)
        Remove the parameter given by name from the PyXslt30Processor. The parameter will not have any effect on the
        stylesheet if it has not yet been executed.
        Args:
            name (str): The name of the stylesheet parameter
            encoding (str): The encoding of the name string. If not specified then the platform default encoding is used.
        Returns:
            bool: True if the removal of the parameter has been successful, False otherwise.
        """
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_name_string = name.encode(encoding) if name is not None else None
        cdef char * c_name = py_name_string if name is not None else ""
        return self.thisxptr.removeParameter(c_name)

     def clear_parameters(self):
        """
        clear_parameter(self)
        Clear all parameters set on the processor for execution of the stylesheet
        """
        self.thisxptr.clearParameters()

     def import_package(self, str package_file_name):
         """
         import_package(self, package_file_name)
         Import a library package.  Calling this method makes the supplied package available for reference
         in the xsl:use-package declarations of subsequent compilations performed using this Xslt30Processor.
         Args:
             package_file_name (str): the file name of the package to be imported, which should be supplied
                as an SEF. If relative, the file name of the SEF is resolved against the cwd, which is set
                using the set_cwd method.

         Example:
            xsltproc = saxon_proc.new_xslt30_processor()
            xsltproc.import_package('test-package-001.pack')
            executable = xsltproc.compile_stylesheet(stylesheet_file="foo.xsl")
         """
         cdef char * c_package_file_name
         if package_file_name is not None and len(package_file_name) > 0:
             py_ta_string = package_file_name.encode('UTF-8') if package_file_name is not None else None
             c_package_file_name = py_ta_string if py_ta_string is not None else ""
             self.thisxptr.importPackage(c_package_file_name)



     def compile_stylesheet(self, **kwds):
        """
        compile_stylesheet(self, **kwds)
        Compile a stylesheet received as text, uri, as a node object, or as referenced in a specified XML document
        via the xml-stylesheet processing instruction. The term "compile" here indicates that the stylesheet is
        converted into an executable form. The compilation uses a snapshot of the properties of the PyXslt30Processor
        at the time this method is invoked. It is also possible to save the compiled stylesheet (SEF file) given the
        options 'save' and 'output_file'.
        Args:
            **kwds: Possible keyword arguments: one of stylesheet_text (str), stylesheet_file (str),
                associated_file (str) or stylesheet_node (PyXdmNode); save (bool) and output_file (str) can be used
                to save the exported stylesheet (SEF) to file; lang (str) can be used to set the XSLT (and XPath)
                language level to be supported by the processor (possible values: '3.0' and '4.0');
                fast_compile (bool) which requests fast compilation.
                The following additional keywords can be used with 'save': target (str) which sets the target edition
                under which the compiled stylesheet will be executed; and relocate (bool) which says whether the
                compiled stylesheet can be deployed to a different location, with a different base URI.
                The keyword 'encoding' (str) can be used with stylesheet_text to specify the encoding used to decode
                the string (if not specified then the platform default encoding is used).
        Returns:
            PyXsltExecutable: which represents the compiled stylesheet. The PyXsltExecutable is immutable
            and thread-safe; it may be used to run multiple transformations, in series or concurrently.
        Raises:
            PySaxonApiError: Error raised if the stylesheet contains static errors or if it cannot be read.
        Example:
            xsltproc = saxon_proc.new_xslt30_processor()
            1) executable = xsltproc.compile_stylesheet(stylesheet_text="<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='2.0'>
                                             <xsl:param name='values' select='(2,3,4)' /><xsl:output method='xml' indent='yes' />
                                             <xsl:template match='*'><output><xsl:value-of select='//person[1]'/>
                                             <xsl:for-each select='$values' >
                                               <out><xsl:value-of select='. * 3'/></out>
                                             </xsl:for-each></output></xsl:template></xsl:stylesheet>")
            2) executable = xsltproc.compile_stylesheet(stylesheet_file="test1.xsl", save=True, output_file="test1.sef", target="HE")
            3) executable = xsltproc.compile_stylesheet(associated_file="foo.xml")
        """
        py_error_message = "Error: compile_stylesheet should contain exactly one of the following keyword arguments: (associated_file|stylesheet_text|stylesheet_file|stylesheet_node)"
        cdef char * c_outputfile
        cdef char * c_stylesheet
        cdef char * c_encoding_string = NULL
        py_output_string = None
        py_stylesheet_string = None
        cdef PyXsltExecutable executable
        cdef saxoncClasses.XsltExecutable * cexecutable = NULL
        py_save = False
        cdef int option = 0
        cdef bool c_relocate
        cdef PyXdmNode py_xdmNode = None
        encoding = None

        if kwds.keys() >= {"associated_file", "stylesheet_text"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"associated_file", "stylesheet_file"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"associated_file", "stylesheet_node"}:
            raise Exception(py_error_message)
        if kwds.keys() >= {"stylesheet_text", "stylesheet_file"}:
          raise Exception(py_error_message)
        if kwds.keys() >= {"stylesheet_text", "stylesheet_node"}:
          raise Exception(py_error_message)
        if kwds.keys() >= {"stylesheet_node", "stylesheet_file"}:
          raise Exception(py_error_message)
        if "lang" in kwds:
          py_lang_string = kwds["lang"]
          py_ta_string = py_lang_string.encode('UTF-8') if py_lang_string is not None else None
          c_lang = py_ta_string if py_lang_string is not None else ""
          self.thisxptr.setXsltLanguageVersion(c_lang)

        py_encoding_string = None
        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string

        if "fast_compile" in kwds:
          py_fast_string = kwds["fast_compile"]
          py_ta_string = py_fast_string.encode('UTF-8') if py_fast_string is not None else None
          c_fast = py_ta_string if py_fast_string is not None else ""
          self.thisxptr.setFastCompilation(c_fast)

        if ("save" in kwds) and kwds["save"]==True:
          del kwds["save"]
          if "target" in kwds:
              py_target_string = kwds["target"]
              py_ta_string = py_target_string.encode('UTF-8') if py_target_string is not None else None
              c_target = py_ta_string if py_target_string is not None else ""
              self.thisxptr.setTargetEdition(c_target)

          if "relocate" in kwds:
              py_relocate = kwds["relocate"]
              c_relocate = py_relocate
              self.thisxptr.setRelocatable(c_relocate)

          if "output_file" not in kwds:
            raise Exception("output_file keyword argument is required for compile_stylesheet when save=True")
          py_output_string = kwds["output_file"]
          '''c_outputfile = make_c_str(py_output_string)'''
          py_output_sstring = py_output_string.encode('UTF-8') if py_output_string is not None else None
          c_outputfile = py_output_sstring if py_output_string is not None else ""
          if "stylesheet_text" in kwds:
            py_stylesheet_string = kwds["stylesheet_text"]

            '''c_stylesheet = make_c_str(py_stylesheet_string)'''
            py_s_string = py_stylesheet_string.encode(encoding if encoding is not None else sys.getdefaultencoding()) if py_stylesheet_string is not None else None
            c_stylesheet = py_s_string if py_stylesheet_string is not None else ""
            self.thisxptr.compileFromStringAndSave(c_stylesheet, c_outputfile, c_encoding_string)
          elif "stylesheet_file" in kwds:
            py_stylesheet_string = kwds["stylesheet_file"]
            '''if py_stylesheet_string  is None or isfile(py_stylesheet_string) == False:
              raise Exception("Stylesheet file does not exist")'''
            '''c_stylesheet = make_c_str(py_stylesheet_string)'''
            py__string = py_stylesheet_string.encode('UTF-8') if py_stylesheet_string is not None else None
            c_stylesheet = py__string if py_stylesheet_string is not None else ""
            self.thisxptr.compileFromFileAndSave(c_stylesheet, c_outputfile)
          elif "stylesheet_node" in kwds:
            py_xdmNode = kwds["stylesheet_node"]
            #if not isinstance(py_value, PyXdmNode):
              #raise Exception("stylesheet_node keyword argument is not of type PyXdmNode")
            #value = PyXdmNode(py_value)
            self.thisxptr.compileFromXdmNodeAndSave(py_xdmNode.derivednptr, c_outputfile)
          else:
            raise Exception(py_error_message)
        else:
          if "stylesheet_text" in kwds:
            py_stylesheet_string = kwds["stylesheet_text"]
            '''c_stylesheet = make_c_str(py_stylesheet_string)'''
            py__string = py_stylesheet_string.encode(encoding if encoding is not None else sys.getdefaultencoding()) if py_stylesheet_string is not None else None
            c_stylesheet = py__string if py_stylesheet_string is not None else ""

            executable = PyXsltExecutable()
            cexecutable =  self.thisxptr.compileFromString(c_stylesheet, c_encoding_string)
            if cexecutable is NULL:
                return None
            executable.thisxptr = cexecutable
            return executable
          elif "stylesheet_file" in kwds:
            py_stylesheet_string = kwds["stylesheet_file"]

            py__string = py_stylesheet_string.encode('UTF-8') if py_stylesheet_string is not None else None
            c_stylesheet = py__string if py_stylesheet_string is not None else ""

            '''TODO handle cwd or let java do the complete checking
            if py_stylesheet_string  is None or isfile(py_stylesheet_string) == False:
              raise Exception("Stylesheet file does not exist: "+ py_stylesheet_string)
            c_stylesheet = make_c_str(py_stylesheet_string)'''

            executable = PyXsltExecutable()
            cexecutable =  self.thisxptr.compileFromFile(c_stylesheet)
            if cexecutable is NULL:
                return None
            executable.thisxptr = cexecutable
            return executable
          elif "associated_file" in kwds:
            py_stylesheet_string = kwds["associated_file"]
            '''if py_stylesheet_string  is None or isfile(py_stylesheet_string) == False:
              raise Exception("Stylesheet file does not exist")
            c_stylesheet = make_c_str(py_stylesheet_string)'''

            py__string = py_stylesheet_string.encode('UTF-8') if py_stylesheet_string is not None else None
            c_stylesheet = py__string if py_stylesheet_string is not None else ""

            executable = PyXsltExecutable()
            cexecutable =  self.thisxptr.compileFromAssociatedFile(c_stylesheet)
            if cexecutable is NULL:
                return None
            executable.thisxptr = cexecutable
            return executable
          elif "stylesheet_node" in kwds:
            py_xdmNode = kwds["stylesheet_node"]
            #if not isinstance(py_value, PyXdmNode):
              #raise Exception("stylesheet_node keyword argument is not of type PyXdmNode")
            #value = PyXdmNode(py_value)
            executable = PyXsltExecutable()
            cexecutable =  self.thisxptr.compileFromXdmNode(py_xdmNode.derivednptr)
            if cexecutable is NULL:
                return None
            executable.thisxptr = cexecutable
            return executable
          else:
            raise Exception(py_error_message)

     def transform_to_string(self, **kwds):
        """
        transform_to_string(self, **kwds)
        Execute a transformation and return the result as a string. For a more elaborate API for transformation use the
        compile_stylesheet method to compile the stylesheet to a PyXsltExecutable, and use the methods of that class.
        Args:
            **kwds: Required keyword arguments: source_file (str) and stylesheet_file (str).
                Possible arguments: base_output_uri (str) which is used for resolving relative URIs in the href
                attribute of the xsl:result-document instruction. Also accept the keyword 'encoding' (str) to
                specify the encoding of the output string. This must match the encoding specified by xsl:output in
                the stylesheet. If not specified then the platform default encoding is used.
        Example:
            result = xsltproc.transform_to_string(source_file="cat.xml", stylesheet_file="test1.xsl")
        Raises:
            PySaxonApiError: Error raised if failure in XSLT transformation
        """
        cdef char * c_sourcefile = NULL
        cdef char * c_stylesheet = NULL
        cdef PyXdmNode node_ = None
        cdef py_value = None
        cdef py_value2 = None
        if len(kwds) == 0:
            raise Warning("Warning: transform_to_string should only contain the following keyword arguments: (source_file, stylesheet_file, base_output_uri, encoding)")

        if "source_file" in kwds:
            py_value2 = kwds["source_file"]
            '''c_sourcefile = make_c_str(py_value2)'''
            py_string_string2 = py_value2.encode('utf-8') if py_value2 is not None else None
            c_sourcefile = py_string_string2 if py_value2 is not None else ""

        if "base_output_uri" in kwds:
            py_value = kwds["base_output_uri"]
            '''c_base_output_uri = make_c_str(py_value)'''
            py_bstring_string = py_value.encode('utf-8') if py_value is not None else None
            c_base_output_uri = py_bstring_string if py_value is not None else ""
            self.thisxptr.setBaseOutputURI(c_base_output_uri)

        if "stylesheet_file" in kwds:
            py_value1 = kwds["stylesheet_file"]
            py_string_string = py_value1.encode('utf-8') if py_value1 is not None else None
            c_stylesheet = py_string_string if py_value1 is not None else ""
            '''make_c_str(py_value)'''

        encoding = sys.getdefaultencoding()
        if "encoding" in kwds:
            encoding = kwds["encoding"]
        cdef const char* c_string
        c_string = self.thisxptr.transformFileToString(c_sourcefile, c_stylesheet)
        py_string_i = make_py_str(c_string, encoding)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def transform_to_file(self, **kwds):
        """
        transform_to_file(self, **kwds)
        Execute a transformation with the result saved to file. For a more elaborate API for transformation use the
        compile_stylesheet method to compile the stylesheet to a PyXsltExecutable, and use the methods of that class.
        Args:
            **kwds: Required keyword arguments: source_file (str), stylesheet_file (str) and output_file (str).
                Possible argument: base_output_uri (str) which is used for resolving relative URIs in the href
                attribute of the xsl:result-document instruction.
        Example:
            xsltproc.transform_to_file(source_file="cat.xml", stylesheet_file="test1.xsl", output_file="result.xml")
        Raises:
            PySaxonApiError: Error raised if failure in XSLT transformation
        """
        cdef char * c_sourcefile = NULL
        cdef char * c_outputfile = NULL
        cdef char * c_base_output_uri = NULL
        cdef char * c_stylesheet = NULL
        cdef PyXdmNode node_ = None
        for key, value in kwds.items():
                if isinstance(value, str):
                        if key == "source_file":
                                py_sourcefile_string = value.encode('utf-8') if value is not None else None
                                c_sourcefile = py_sourcefile_string if value is not None else ""
                        elif key == "base_output_uri":
                                '''c_base_output_uri = make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_base_output_uri = py_string_string if value is not None else ""
                                self.thisxptr.setBaseOutputURI(c_base_output_uri)
                        elif key == "output_file":
                                '''c_outputfile = make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_outputfile = py_string_string if value is not None else ""
                        elif key == "stylesheet_file":
                                '''c_stylesheet = make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_stylesheet = py_string_string if value is not None else ""

        self.thisxptr.transformFileToFile(c_sourcefile, c_stylesheet, c_outputfile)

     def transform_to_value(self, **kwds):
        """
        transform_to_value(self, **kwds)
        Execute a transformation and return the result as a PyXdmValue object. For a more elaborate API for
        transformation use the compile_stylesheet method to compile the stylesheet to a PyXsltExecutable, and use
        the methods of that class.
        Args:
            **kwds: Required keyword arguments: source_file (str) and stylesheet_file (str).
                Possible argument: base_output_uri (str) which is used for resolving relative URIs in the href
                attribute of the xsl:result-document instruction.
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object
        Example:
            result = xsltproc.transform_to_value(source_file="cat.xml", stylesheet_file="test1.xsl")
        Raises:
            PySaxonApiError: Error raised if failure in XSLT transformation
        """
        cdef const char * c_sourcefile = NULL
        cdef char * c_stylesheet = NULL
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "source_file":
              '''c_sourcefile = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
            elif key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            elif key == "stylesheet_file":
               '''c_stylesheet = make_c_str(value)'''
               py_string_string = value.encode('utf-8') if value is not None else None
               c_stylesheet = py_string_string if value is not None else ""
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmFunctionItem fval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        xdmValue = self.thisxptr.transformFileToValue(c_sourcefile, c_stylesheet)
        if xdmValue is NULL:
            return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            return aaval
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            return val

     @property
     def exception_occurred(self):
        """
        exception_occurred(self)
        Property to check for pending exceptions without creating a local reference to the exception object
        Returns:
            boolean: True when there is an exception thrown; otherwise False
        """
        return self.thisxptr.exceptionOccurred()

     def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown
        """
        self.thisxptr.exceptionClear()

     @property
     def error_message(self):
        """
        error_message(self)
        A transformation may have a number of errors reported against it. This property returns an error message
        if there are any errors.
        Returns:
            str: The message of the exception. Returns None if the exception does not exist.
        """
        cdef const char* c_string = self.thisxptr.getErrorMessage()
        ustring = make_py_str(c_string)
        return ustring

     @property
     def error_code(self):
        """
        error_code(self)
        A transformation may have a number of errors reported against it. This property returns the error code if
        there are any errors.
        Returns:
            str: The error code associated with the exception. Returns None if the exception does not exist.
        """
        cdef const char* c_string = self.thisxptr.getErrorCode()
        ustring = make_py_str(c_string)
        return ustring





cdef class PyXsltExecutable:
     """A PyXsltExecutable represents the compiled form of a stylesheet.
     A PyXsltExecutable is created by using one of the compile methods on the PyXslt30Processor class. """
     cdef saxoncClasses.XsltExecutable *thisxptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        """Default constructor """
        self.thisxptr = NULL
     def __dealloc__(self):
        if self.thisxptr != NULL:
           del self.thisxptr
     def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory.
        Args:
            cwd (str): current working directory
        """
        cdef char * c_cwd = NULL
        '''make_c_str(cwd)'''
        py_string_string = cwd.encode('utf-8') if cwd is not None else None
        c_cwd = py_string_string if cwd is not None else ""
        self.thisxptr.setcwd(c_cwd)

     def clone(self):
         """
         clone(self)
         Create a clone object of this PyXsltExecutable object
         Returns:
             PyXsltExecutable: copy of this object
         """
         cdef PyXsltExecutable executable = PyXsltExecutable()
         executable.thisxptr = self.thisxptr.clone()
         return executable

     def set_initial_mode(self, name):
        """
        set_initial_mode(self, name)
        Set the initial mode for the transformation
        Args:
            name (str): the EQName of the initial mode. Two special values are recognized, in the
                reserved XSLT namespace:
                xsl:unnamed to indicate the mode with no name, and xsl:default to indicate the
                mode defined in the stylesheet header as the default mode.
                The value null also indicates the default mode (which defaults to the unnamed
                mode, but can be set differently in an XSLT 3.0 stylesheet).
        """
        cdef char * c_name = NULL
        '''make_c_str(name)'''
        py_string_string = name.encode('utf-8') if name is not None else None
        c_name = py_string_string if name is not None else ""
        self.thisxptr.setInitialMode(c_name)

     def set_base_output_uri(self, base_uri):
        """
        set_base_output_uri(self, base_uri)
        Set the base output URI. The default is the base URI of the principal output
        of the transformation. If a base output URI is supplied using this function then
        it takes precedence over any base URI defined in the principal output, and
        it may cause the base URI of the principal output to be modified in situ.
        The base output URI is used for resolving relative URIs in the 'href' attribute
        of the xsl:result-document instruction; it is accessible to XSLT stylesheet
        code using the XPath current-output-uri() function.
        Args:
            base_uri (str): the base output URI
        """
        cdef char * c_uri = NULL
        '''make_c_str(base_uri)'''
        py_string_string = base_uri.encode('utf-8') if base_uri is not None else None
        c_uri = py_string_string if base_uri is not None else ""
        self.thisxptr.setBaseOutputURI(c_uri)

     def set_global_context_item(self, **kwds):
        """
        set_global_context_item(self, **kwds)
        Set the global context item for the transformation.
        Args:
            **kwds: Possible keyword arguments: must be one of the following (file_name|xdm_item)
        Raises:
            Exception: Exception is raised if keyword argument is not one of file_name or xdm_item
                (providing a PyXdmItem).
        """
        py_error_message = "Error: set_global_context_item should contain exactly one of the following keyword arguments: (file_name|xdm_item)"
        if len(kwds) != 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source =  NULL
        cdef PyXdmItem xdm_item = None
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            '''c_source = make_c_str(py_value)'''
            py_string_string = py_value.encode('utf-8') if py_value is not None else None
            c_source = py_string_string if py_value is not None else ""
            self.thisxptr.setGlobalContextFromFile(c_source)
        elif "xdm_item" in kwds:
            if isinstance(kwds["xdm_item"], PyXdmItem):
                xdm_item = kwds["xdm_item"]
                self.thisxptr.setGlobalContextItem(xdm_item.derivedptr)
                xdm_item.derivedptr.incrementRefCount()
            else:
                raise Exception("xdm_item value must be of type PyXdmItem")
        else:
          raise Exception(py_error_message)
     def set_initial_match_selection(self, **kwds):
        """
        set_initial_match_selection(self, **kwds)
        The initial value to which templates are to be applied (equivalent to the select attribute of
        xsl:apply-templates).
        Args:
            **kwds: Possible keyword arguments: must be one of the following (file_name|xdm_value)
        Raises:
            Exception: Exception is raised if keyword argument is not one of file_name or xdm_value
                (providing a PyXdmValue).
        """
        py_error_message = "Error: set_initial_match_selection should contain exactly one of the following keyword arguments: (file_name|xdm_value)"
        if len(kwds) != 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source  = NULL
        cdef PyXdmValue xdm_value = None
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmItem ivalue_
        cdef PyXdmNode nvalue_
        cdef PyXdmValue value_
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            '''c_source = make_c_str(py_value)'''
            py_string_string = py_value.encode('utf-8') if py_value is not None else None
            c_source = py_string_string if py_value is not None else ""
            self.thisxptr.setInitialMatchSelectionAsFile(c_source)
        elif "xdm_value" in kwds:
            value = kwds["xdm_value"]
            if value is not None:

                if isinstance(value, PyXdmValue):
                    value_ = value
                    value_.thisvptr.incrementRefCount()
                    self.thisxptr.setInitialMatchSelection(value_.thisvptr)
                elif  isinstance(value, PyXdmItem):
                    ivalue_ = value
                    ivalue_.derivedptr.incrementRefCount()
                    self.thisxptr.setInitialMatchSelection(<saxoncClasses.XdmValue *>  ivalue_.derivedptr)
                elif  isinstance(value, PyXdmNode):
                    nvalue_ = value
                    nvalue_.derivednptr.incrementRefCount()
                    self.thisxptr.setInitialMatchSelection(<saxoncClasses.XdmValue *>  nvalue_.derivednptr)
                elif  isinstance(value, PyXdmAtomicValue):
                    avalue_ = value
                    avalue_.derivedaptr.incrementRefCount()
                    self.thisxptr.setInitialMatchSelection(<saxoncClasses.XdmValue *> avalue_.derivedaptr)
                else:
                    raise Exception("Supplied value is not of the right type")

     def set_output_file(self, output_file):
        """
        set_output_file(self, output_file)
        Set the output file where the output of the transformation will be sent
        Args:
            output_file (str): The output file supplied as a string
        """
        cdef char * c_outputfile =  NULL
        '''make_c_str(output_file)'''
        py_string_string = output_file.encode('utf-8') if output_file is not None else None
        c_outputfile = py_string_string if output_file is not None else ""
        self.thisxptr.setOutputFile(c_outputfile)

     def set_result_as_raw_value(self, bool is_raw):
        """
        set_result_as_raw_value(self, bool is_raw)
        Set true if the return type of callTemplate, applyTemplates and transform methods is to return PyXdmValue,
        otherwise return PyXdmNode object with root Document node
        Args:
            is_raw (bool): True if returning raw result, i.e. PyXdmValue, otherwise return PyXdmNode
        """
        cdef bool c_raw
        c_raw = is_raw
        self.thisxptr.setResultAsRawValue(c_raw)
        #else:
        #raise Warning("setJustInTimeCompilation: argument must be a boolean type. JIT not set")

     def set_capture_result_documents(self, bool value, bool raw_result=False):
        """
        set_capture_result_documents(self, bool value, bool raw_result)
        Enable the capture of the result document output into a dict. This overrides the default mechanism.
        If this option is enabled, then any document created using xsl:result-document is saved (as a PyXdmNode)
        in a dict object where it is accessible using the URI as a key. After the execution of the transformation
        a call on the get_result_documents method is required to get access to the result documents in the map.
        It is also possible to capture the result document as a raw result directly as a PyXdmValue, without
        constructing an XML tree, and without serialization. It corresponds to the serialization.
        Args:
            value (bool): true causes secondary result documents from the transformation to be saved in a map;
                false disables this option.
            raw_result (bool): true enables the handling of raw destination for result documents. If not supplied
                this can also be set on the set_result_as_raw_value method. The set_result_as_raw_value method
                has higher priority to this flag.
        """
        cdef bool c_value
        c_value = value
        cdef bool c_raw_result
        c_raw_result = raw_result
        self.thisxptr.setCaptureResultDocuments(c_value, c_raw_result)

     def get_result_documents(self):
         """
         get_result_documents(self)
         Return the secondary result documents resulting from the execution of the stylesheet. Null is
         returned if the user has not enabled this feature via the method set_capture_result_documents.
         Returns:
             dict [str, PyXdmValue]: Dict of the key-value pairs. Indexed by the absolute URI of each result
             document, and the corresponding value is a PyXdmValue object containing the result document (as
             an in-memory tree, without serialization).
         """
         cdef map[string , saxoncClasses.XdmValue * ] c_dataMap
         cdef dict p_dataMap = {}
         cdef PyXdmValue nval = None

         c_dataMap = self.thisxptr.getResultDocuments()

         cdef map[string , saxoncClasses.XdmValue * ].iterator it = c_dataMap.begin()
         cdef int size = c_dataMap.size()

         cdef str key_str
         while(it != c_dataMap.end()):
             c_xdmNode =  dereference(it).second
             nval = PyXdmValue()
             nval.thisvptr = <saxoncClasses.XdmValue*>c_xdmNode
             key_str = make_py_str(dereference(it).first.c_str())
             p_dataMap[key_str] =  nval
             postincrement(it)

         return p_dataMap

     def get_xsl_messages(self):
        """
        xsl_messages
        Get the messages written using the xsl:message instruction. Return NULL if the user has not
        enabled capturing of xsl:messages via the method set_save_xsl_message.


        :return: value (PyXdmValue):
        """
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        cdef PyXdmValue val = None
        xdmValue = self.thisxptr.getXslMessages()
        if xdmValue is NULL:
            return None
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            xdmValue.incrementRefCount()
            return val


     def set_parameter(self, name, value):
        """
        set_parameter(self, name, value)
        Set the value of a stylesheet parameter
        Args:
            name (str): the name of the stylesheet parameter, as a string. For a namespaced parameter use
                clark notation {uri}local
            value (PyXdmValue): the value of the stylesheet parameter, or NULL to clear a previously set value
        """
        cdef const char * c_str = NULL
        py_string_string = name.encode('utf-8') if name is not None else None
        c_str = py_string_string if name is not None else ""
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmItem ivalue_
        cdef PyXdmNode nvalue_
        cdef PyXdmValue value_
        if value is None:
            return
        if c_str is not NULL:
            if  isinstance(value, PyXdmAtomicValue):
                avalue_ = value
                avalue_.derivedaptr.incrementRefCount()
                self.thisxptr.setParameter(c_str, <saxoncClasses.XdmValue *> avalue_.derivedaptr)
            elif  isinstance(value, PyXdmNode):
                nvalue_ = value
                nvalue_.derivedaptr.incrementRefCount()
                self.thisxptr.setParameter(c_str, <saxoncClasses.XdmValue *>  nvalue_.derivednptr)
            elif  isinstance(value, PyXdmItem):
                ivalue_ = value
                ivalue_.derivedaptr.incrementRefCount()
                self.thisxptr.setParameter(c_str, <saxoncClasses.XdmValue *>  ivalue_.derivedptr)
            elif isinstance(value, PyXdmValue):
                value_ = value
                value_.thisvptr.incrementRefCount()
                self.thisxptr.setParameter(c_str, value_.thisvptr)

     def get_parameter(self, name):
        """
        get_parameter(self, name)
        Get a parameter value by a given name
        Args:
            name (str): The name of the stylesheet parameter
        Returns:
            PyXdmValue: The XDM value of the parameter
        """
        cdef char * c_name = NULL
        '''make_c_str(name)'''
        py_string_string = name.encode('utf-8') if name is not None else None
        c_name = py_string_string if name is not None else ""
        cdef PyXdmValue val = PyXdmValue()
        val.thisvptr = self.thisxptr.getParameter(c_name)
        return val
     def remove_parameter(self, name):
        """
        remove_parameter(self, name)
        Remove the parameter given by name from the PyXslt30Processor. The parameter will not have any effect on the
        stylesheet if it has not yet been executed.
        Args:
            name (str): The name of the stylesheet parameter
        Returns:
            bool: True if the removal of the parameter has been successful, False otherwise.
        """
        cdef char * c_name = NULL
        '''make_c_str(name)'''
        py_string_string = name.encode('utf-8') if name is not None else None
        c_name = py_string_string if name is not None else ""
        return self.thisxptr.removeParameter(c_name)
     def set_property(self, name, value):
        """
        set_property(self, name, value)
        Set a property specific to the processor in use.
        Args:
            name (str): The name of the property
            value (str): The value of the property
        Example:
            PyXsltExecutable: set serialization properties (names start with '!' e.g. name "!method" -> "xml")\r
            'o': output file name,\r
            'it': initial template,\r
            'im': initial mode,\r
            's': source as file name\r
            'm': switch on message listener for xsl:message instructions,\r
            'item'| 'node': source supplied as a PyXdmNode object,\r
            'extc': Set the native library to use with Saxon for extension functions written in C/C++/PHP\r
        """
        cdef char * c_name = NULL
        py_string_string = name.encode('utf-8') if name is not None else None
        c_name = py_string_string if name is not None else ""

        cdef char * c_value = NULL
        '''make_c_str(value)'''
        py_string_string = value.encode('utf-8') if value is not None else None
        c_value = py_string_string if value is not None else ""
        self.thisxptr.setProperty(c_name, c_value)

     def clear_parameters(self):
        """
        clear_parameter(self)
        Clear all parameters set on the processor for execution of the stylesheet
        """
        self.thisxptr.clearParameters()
     def clear_properties(self):
        """
        clear_properties(self)
        Clear all properties set on the processor
        """
        self.thisxptr.clearProperties()
     def set_initial_template_parameters(self, bool tunnel, dict parameters):
        """
        set_initial_template_parameters(self, bool tunnel, dict parameters)
        Set parameters to be passed to the initial template. These are used
        whether the transformation is invoked by applying templates to an initial source item,
        or by invoking a named template. The parameters in question are the xsl:param elements
        appearing as children of the xsl:template element.
        Args:
        	tunnel (bool): True if these values are to be used for setting tunnel parameters;
        	    False if they are to be used for non-tunnel parameters. The default is false.
            parameters (dict): the parameters to be used for the initial template supplied as key-value pairs.
        Example:
        	1) paramArr = {'a':saxonproc.make_integer_value(12), 'b':saxonproc.make_integer_value(5)}
               xsltproc.set_initial_template_parameters(False, paramArr)
            2) set_initial_template_parameters(False, {a:saxonproc.make_integer_value(12)})
        """
        cdef map[string, saxoncClasses.XdmValue * ] c_params
        cdef bool c_tunnel
        cdef string key_str
        c_tunnel = tunnel
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmNode nvalue_
        cdef PyXdmMap mvalue_
        cdef PyXdmArray arvalue_
        cdef PyXdmFunctionItem fvalue_
        cdef PyXdmItem ivalue_
        cdef PyXdmValue value_
        global parametersDict
        if parameters is not None:
                parametersDict = parameters
        for (key, value) in parameters.items():
                if isinstance(value, PyXdmAtomicValue):
                        avalue_ = value
                        key_str = key.encode('UTF-8')
                        avalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> avalue_.derivedptr
                elif isinstance(value, PyXdmNode):
                        nvalue_ = value
                        key_str = key.encode('UTF-8')
                        nvalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> nvalue_.derivedptr
                elif isinstance(value, PyXdmMap):
                        mvalue_ = value
                        key_str = key.encode('UTF-8')
                        mvalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> mvalue_.derivedptr
                elif isinstance(value, PyXdmArray):
                        arvalue_ = value
                        key_str = key.encode('UTF-8')
                        arvalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> arvalue_.derivedptr
                elif isinstance(value, PyXdmFunctionItem):
                        fvalue_ = value
                        key_str = key.encode('UTF-8')
                        fvalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> fvalue_.derivedptr
                elif isinstance(value, PyXdmItem):
                        ivalue_ = value
                        key_str = key.encode('UTF-8')
                        ivalue_.derivedptr.incrementRefCount()
                        c_params[key_str] = <saxoncClasses.XdmValue *> ivalue_.derivedptr
                elif isinstance(value, PyXdmValue):
                        value_ = value
                        key_str = key.encode('UTF-8')
                        value_.thisvptr.incrementRefCount()
                        c_params[key_str] = value_.thisvptr
                else:
                        raise Exception("Initial template parameters can only be of type PyXdmValue or its sub-types")
        if len(parameters) > 0:
            self.thisxptr.setInitialTemplateParameters(c_params, c_tunnel)

     def set_save_xsl_message(self, show, str file_name = None):
        """
        set_save_xsl_message(self, show, str file_name)
        Gives users the option to switch the xsl:message feature on or off. It is also possible
        to send the xsl:message outputs to file given by file name.
        Args:
            show (bool): Boolean to indicate if xsl:message should be outputted. Default (True) is on.
            file_name (str): The name of the file to send output
        """
        cdef char * c_file_name = NULL
        '''make_c_str(file_name)'''
        py_string_string = file_name.encode('utf-8') if file_name is not None else None
        c_file_name = py_string_string if file_name is not None else ""
        if file_name is None:
            self.thisxptr.setSaveXslMessage(show, NULL)
        else:
            self.thisxptr.setSaveXslMessage(show, c_file_name)

     def export_stylesheet(self, str file_name):
        """
        export_stylesheet(self, str file_name)
        Produce a representation of the compiled stylesheet, in XML form, suitable for
        distribution and reloading.
        Args:
            file_name (str): The name of the file where the compiled stylesheet is to be saved
        """
        cdef char * c_file_name = NULL
        '''make_c_str(file_name)'''
        py_string_string = file_name.encode('utf-8') if file_name is not None else None
        c_file_name = py_string_string if file_name is not None else ""
        self.thisxptr.exportStylesheet(c_file_name)


     def transform_to_string(self, **kwds):
        """
        transform_to_string(self, **kwds)
        Execute a transformation and return the result as a string.
        Args:
            **kwds: Possible keyword arguments: one of source_file (str) or xdm_node (PyXdmNode);
                base_output_uri (str) which is used for resolving relative URIs
                in the href attribute of the xsl:result-document instruction.
                Also accept the keyword 'encoding' (str) to specify the encoding of the output string. This must
                match the encoding specified by xsl:output in the stylesheet, or as specified using set_property()
                on this PyXsltExecutable. If not specified then the platform default encoding is used.
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error


        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.transform_to_string(source_file="cat.xml")
            2) executable.set_initial_match_selection(file_name="cat.xml")\r
               result = executable.transform_to_string()
            3) node = saxon_proc.parse_xml(xml_text="<in/>")\r
               result = executable.transform_to_string(xdm_node= node)
        """
        cdef char * c_sourcefile = NULL
        cdef const char * c_string = NULL
        cdef const char * c_base_output_uri = NULL
        cdef PyXdmNode xdm_node = None
        cdef saxoncClasses.XdmNode * derivednptr = NULL
        if kwds.keys() >= {"source_file", "xdm_node"}:
            raise Warning("Warning: transform_to_string should only contain one of the following keyword arguments: (source_file|xdm_node)")
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "source_file":
              c_sourcefile = NULL
              '''make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
            elif key == "base_output_uri":
              c_base_output_uri = NULL
              '''make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            else:
              raise Warning("Warning: transform_to_string should only contain the following keyword arguments: (source_file|xdm_node, base_output_uri)")
          elif key == "xdm_node":

            if isinstance(value, PyXdmNode):
                xdm_node = value
          else:
            raise Warning("Warning: transform_to_string should only contain the following keyword arguments: (source_file|xdm_node, base_output_uri)")
        encoding = sys.getdefaultencoding()
        if "encoding" in kwds:
            encoding = kwds["encoding"]
        if xdm_node is not None:
          c_string = self.thisxptr.transformToString(xdm_node.derivednptr)
          py_string_i = make_py_str(c_string, encoding)
          saxoncClasses.SaxonProcessor.deleteString(c_string)
          return py_string_i
        else:
          c_string = self.thisxptr.transformFileToString(c_sourcefile)
          py_string_i = make_py_str(c_string, encoding)
          saxoncClasses.SaxonProcessor.deleteString(c_string)
          return py_string_i

     def transform_to_file(self, **kwds):
        """
        transform_to_file(self, **kwds)
        Execute a transformation with the result saved to file. It is possible to specify the output file as an
        argument or using the set_output_file method.
        Args:
            **kwds: Possible keyword arguments: source_file (str) or xdm_node (PyXdmNode); output_file (str),
                and base_output_uri (str) which is used for resolving relative URIs in the href attribute of the
                xsl:result-document instruction.

        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) executable.transform_to_file(source_file="cat.xml", output_file="result.xml")
            2) executable.set_initial_match_selection("cat.xml")\r
               executable.set_output_file("result.xml")\r
               executable.transform_to_file()
            3) node = saxon_proc.parse_xml(xml_text="<in/>")\r
               executable.transform_to_file(output_file="result.xml", xdm_node= node)
        """
        cdef char * c_sourcefile = NULL
        cdef char * c_outputfile = NULL
        cdef char * c_stylesheet = NULL
        cdef char * c_base_output_uri = NULL
        cdef PyXdmNode node_ = None
        for key, value in kwds.items():
                if isinstance(value, str):
                        if key == "source_file":
                                c_sourcefile = NULL
                                '''make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_sourcefile = py_string_string if value is not None else ""
                        elif key == "base_output_uri":
                                c_base_output_uri = NULL
                                '''make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_base_output_uri = py_string_string if value is not None else ""
                                self.thisxptr.setBaseOutputURI(c_base_output_uri)
                        elif key == "output_file":
                                c_outputfile = NULL
                                '''make_c_str(value)'''
                                py_string_string = value.encode('utf-8') if value is not None else None
                                c_outputfile = py_string_string if value is not None else ""
                                self.thisxptr.setOutputFile(c_outputfile)

        if "xdm_node" in kwds:
            py_value = kwds["xdm_node"]
            if(isinstance(py_value, PyXdmNode)):
                node_ = py_value
                self.thisxptr.transformToFile(node_.derivednptr)
            else:
                raise Exception("Keyword argument 'xdm_node' is not of type PyXdmNode")

        else:
            self.thisxptr.transformFileToFile(c_sourcefile, NULL)

     def transform_to_value(self, **kwds):
        """
        transform_to_value(self, **kwds)
        Execute a transformation and return the result as a PyXdmValue object.
        Args:
            **kwds: Possible keyword arguments: source_file (str) or xdm_node (PyXdmNode);
                and base_output_uri (str) which is used for resolving relative URIs in the href attribute
                of the xsl:result-document instruction.
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            xslt30_proc = saxon_proc.new_xslt30_processor()
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.transform_to_value(source_file="cat.xml")
            2) executable.set_initial_match_selection("cat.xml")\r
               result = executable.transform_to_value()
            3) node = saxon_proc.parse_xml(xml_text="<in/>")\r
               result = executable.transform_to_value(xdm_node= node)
        """
        cdef const char * c_sourcefile = NULL
        cdef char * c_stylesheet = NULL
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "source_file":
              '''c_sourcefile = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
            elif key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)


        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmFunctionItem fval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        cdef PyXdmNode node_ = None

        if "xdm_node" in kwds:
            py_value = kwds["xdm_node"]
            if(isinstance(py_value, PyXdmNode)):
                node_ = py_value
                xdmValue = self.thisxptr.transformToValue(node_.derivednptr)
            else:
                raise Exception("Keyword argument 'xdm_node' is not of type PyXdmNode")

        else:
            xdmValue = self.thisxptr.transformFileToValue(c_sourcefile)
        if xdmValue is NULL:
            return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
            aval.thisvptr.incrementRefCount()
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
            nval.thisvptr.incrementRefCount()
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            xdmValue.incrementRefCount()
            return val


     def apply_templates_returning_value(self, **kwds):
        """
        apply_templates_returning_value(self, **kwds)
        Invoke the stylesheet by applying templates to a supplied input sequence, saving the results as a PyXdmValue.
        It is possible to specify the initial match selection either as an argument or using the
        set_initial_match_selection method. This method does not set the global context item for the transformation;
        if that is required, it can be done separately using the set_global_context_item method.
        Args:
            **kwds: Possible keyword arguments: source_file (str) or xdm_value (PyXdmValue) can be used to supply
                the initial match selection; and base_output_uri (str) which is used for resolving relative URIs
                in the href attribute of the xsl:result-document instruction.
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object

        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            xslt30_proc = saxon_proc.new_xslt30_processor()
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) executable.set_initial_match_selection(file_name="cat.xml")\r
               result = executable.apply_templates_returning_value()
            2) result = executable.apply_templates_returning_value(source_file="cat.xml")
        """
        cdef const char * c_sourcefile = NULL
        cdef PyXdmValue value_ = None
        cdef PyXdmItem valuei_ = None
        cdef PyXdmNode valuen_ = None
        cdef PyXdmAtomicValue valueav_ = None
        cdef PyXdmFunctionItem valuef_ = None
        cdef PyXdmMap valuem_ = None
        cdef PyXdmArray valuear_ = None
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "source_file":
              '''c_sourcefile = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
              self.thisxptr.setInitialMatchSelectionAsFile(c_sourcefile)
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
          elif key == "xdm_value" or key == "xdm_node":
              if isinstance(value, PyXdmValue):
                value_ = value
                self.thisxptr.setInitialMatchSelection(value_.thisvptr)
              elif isinstance(value, PyXdmItem):
                  valuei_ = value
                  self.thisxptr.setInitialMatchSelection(valuei_.derivedptr)
              elif isinstance(value, PyXdmNode):
                  valuen_ = value
                  self.thisxptr.setInitialMatchSelection(valuen_.derivednptr)
              elif isinstance(value, PyXdmAtomicValue):
                      valueav_ = value
                      self.thisxptr.setInitialMatchSelection(valueav_.derivedaptr)
              elif isinstance(value, PyXdmFunctionItem):
                      valuef_ = value
                      self.thisxptr.setInitialMatchSelection(valuef_.derivedfptr)
              elif isinstance(value, PyXdmMap):
                      valuem_ = value
                      self.thisxptr.setInitialMatchSelection(valuem_.derivedmmptr)
              elif isinstance(value, PyXdmArray):
                      valuear_ = value
                      self.thisxptr.setInitialMatchSelection(valuear_.derivedaaptr)
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmFunctionItem fval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        xdmValue = self.thisxptr.applyTemplatesReturningValue()
        if xdmValue is NULL:
            return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
            aval.thisvptr.incrementRefCount()
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
            nval.thisvptr.incrementRefCount()
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            return val
     def apply_templates_returning_string(self, **kwds):
        """
        apply_templates_returning_string(self, **kwds)
        Invoke the stylesheet by applying templates to a supplied input sequence, saving the results as a string.
        It is possible to specify the initial match selection either as an argument or using the
        set_initial_match_selection method. This method does not set the global context item for the transformation;
        if that is required, it can be done separately using the set_global_context_item method.
        Args:
            **kwds: Possible keyword arguments: source_file (str) or xdm_value (PyXdmValue) can be used to supply
                the initial match selection; and base_output_uri (str) which is used for resolving relative URIs
                in the href attribute of the xsl:result-document instruction.  Also accept the keyword 'encoding'
                (str) to specify the encoding of the output string. This must match the encoding specified by
                xsl:output in the stylesheet, or as specified using set_property() on this PyXsltExecutable. If
                not specified then the platform default encoding is used.
        Returns:
            str: Result of the transformation as a str value
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            xslt30_proc = saxon_proc.new_xslt30_processor()
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) executable.set_initial_match_selection(file_name="cat.xml")\r
               content = executable.apply_templates_returning_string()
			   print(content)
            2) node = saxon_proc.parse_xml(xml_text="<in/>")\r
               content = executable.apply_templates_returning_string(xdm_value=node)
			   print(content)
        """
        cdef const char * c_sourcefile = NULL
        cdef PyXdmValue value_ = None
        cdef PyXdmItem valuei_ = None
        cdef PyXdmNode valuen_ = None
        cdef PyXdmAtomicValue valueav_ = None
        cdef PyXdmFunctionItem valuef_ = None
        cdef PyXdmMap valuem_ = None
        cdef PyXdmArray valuear_ = None
        encoding = "UTF-8"

        for key, value in kwds.items():


          if isinstance(value, str):
            if key == "source_file":
              '''c_sourcefile = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
              self.thisxptr.setInitialMatchSelectionAsFile(c_sourcefile)
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            if "encoding" in kwds:
              encoding = kwds["encoding"]
                
          elif key == "xdm_value" or key == "xdm_node":
              if isinstance(value, PyXdmValue):
                value_ = value
                self.thisxptr.setInitialMatchSelection(value_.thisvptr)
              elif isinstance(value, PyXdmItem):
                  valuei_ = value
                  self.thisxptr.setInitialMatchSelection(valuei_.derivedptr)
              elif isinstance(value, PyXdmNode):
                  valuen_ = value
                  self.thisxptr.setInitialMatchSelection(valuen_.derivednptr)
              elif isinstance(value, PyXdmAtomicValue):
                      valueav_ = value
                      self.thisxptr.setInitialMatchSelection(valueav_.derivedaptr)
              elif isinstance(value, PyXdmFunctionItem):
                      valuef_ = value
                      self.thisxptr.setInitialMatchSelection(valuef_.derivedfptr)
              elif isinstance(value, PyXdmMap):
                      valuem_ = value
                      self.thisxptr.setInitialMatchSelection(valuem_.derivedmmptr)
              elif isinstance(value, PyXdmArray):
                      valuear_ = value
                      self.thisxptr.setInitialMatchSelection(valuear_.derivedaaptr)
        cdef const char* c_string  = self.thisxptr.applyTemplatesReturningString()
        py_string_i = make_py_str(c_string, encoding)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def apply_templates_returning_file(self, **kwds):
        """
        apply_templates_returning_file(self, **kwds)
        Invoke the stylesheet by applying templates to a supplied input sequence, saving the results to file.
        It is possible to specify the output file as an argument or using the set_output_file method.
        It is possible to specify the initial match selection either as an argument or using the
        set_initial_match_selection method. This method does not set the global context item for the transformation;
        if that is required, it can be done separately using the set_global_context_item method.
        Args:
            **kwds: Possible keyword arguments: source_file (str) or xdm_value (PyXdmValue) can be used to supply
                the initial match selection; output_file (str), and base_output_uri (str) which is used for
                resolving relative URIs in the href attribute of the xsl:result-document instruction.
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            executable.set_initial_match_selection(file_name="cat.xml")
            executable.apply_templates_returning_file(output_file="result.xml")
        """
        cdef const char * c_sourcefile = NULL
        cdef const char * c_outputfile = NULL
        cdef PyXdmValue value_ = None
        cdef PyXdmItem valuei_ = None
        cdef PyXdmNode valuen_ = None
        cdef PyXdmAtomicValue valueav_ = None
        cdef PyXdmFunctionItem valuef_ = None
        cdef PyXdmMap valuem_ = None
        cdef PyXdmArray valuear_ = None
        py_output_string = None
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "source_file":
              '''c_sourcefile = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_sourcefile = py_string_string if value is not None else ""
              self.thisxptr.setInitialMatchSelectionAsFile(c_sourcefile)
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            if key == "output_file":
              py_output_string = value.encode('UTF-8') if value is not None else None
              c_outputfile = py_output_string if value is not None else ""
          elif key == "xdm_value" or key == "xdm_node":
              if isinstance(value, PyXdmValue):
                value_ = value
                self.thisxptr.setInitialMatchSelection(value_.thisvptr)
              elif isinstance(value, PyXdmItem):
                  valuei_ = value
                  self.thisxptr.setInitialMatchSelection(valuei_.derivedptr)
              elif isinstance(value, PyXdmNode):
                  valuen_ = value
                  self.thisxptr.setInitialMatchSelection(valuen_.derivednptr)
              elif isinstance(value, PyXdmAtomicValue):
                      valueav_ = value
                      self.thisxptr.setInitialMatchSelection(valueav_.derivedaptr)
              elif isinstance(value, PyXdmFunctionItem):
                      valuef_ = value
                      self.thisxptr.setInitialMatchSelection(valuef_.derivedfptr)
              elif isinstance(value, PyXdmMap):
                      valuem_ = value
                      self.thisxptr.setInitialMatchSelection(valuem_.derivedmmptr)
              elif isinstance(value, PyXdmArray):
                      valuear_ = value
                      self.thisxptr.setInitialMatchSelection(valuear_.derivedaaptr)

        self.thisxptr.applyTemplatesReturningFile(c_outputfile)

     def call_template_returning_value(self, str template_name=None, **kwds):
        """
        call_template_returning_value(self, str template_name, **kwds)
        Invoke a transformation by calling a named template and return the result as a PyXdmValue.
        Args:
			template_name (str): The name of the template to invoke. If None is supplied then call the initial-template.
            **kwds: Possible keyword arguments: base_output_uri (str) which is used for resolving relative URIs in
                the href attribute of the xsl:result-document instruction.
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            xslt30_proc = saxon_proc.new_xslt30_processor()
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.call_template_returning_value("main")\r
            2) executable.set_global_context_item(file_name="cat.xml")\r
               result = executable.call_template_returning_value("main")
        """
        cdef const char * c_templateName = NULL
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)

        py_template_name_string = template_name.encode('UTF-8') if template_name is not None else None
        if template_name is not None:
            c_templateName = py_template_name_string
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmFunctionItem fval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        xdmValue = self.thisxptr.callTemplateReturningValue(c_templateName)
        if xdmValue is NULL:
            return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            return val
     def call_template_returning_string(self, str template_name=None, **kwds):
        """
        call_template_returning_string(self, str template_name, **kwds)
        Invoke a transformation by calling a named template and return the result as a string.
        Args:
			template_name (str): The name of the template to invoke. If None is supplied then call the initial-template.
            **kwds: Possible keyword arguments: base_output_uri (str) which is used for resolving relative URIs in
                the href attribute of the xsl:result-document instruction. Also accept the keyword 'encoding' (str)
                to specify the encoding of the output string. This must match the encoding specified by xsl:output
                in the stylesheet, or as specified using set_property() on this PyXsltExecutable. If not specified
                then the platform default encoding is used.
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.call_template_returning_string("main")
            2) executable.set_global_context_item(file_name="cat.xml")\r
               result = executable.call_template_returning_string("main")
            3) executable.set_global_context_item(file_name="cat.xml")\r
               result = executable.call_template_returning_string()
			   print(result)
        """
        cdef const char * c_templateName = NULL
        cdef const char* c_string = NULL
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)

        encoding = sys.getdefaultencoding()
        if "encoding" in kwds:
            encoding = kwds["encoding"]
        py_template_name_string = template_name.encode(encoding) if template_name is not None else None
        if template_name is not None:
            c_templateName = py_template_name_string

        c_string  = self.thisxptr.callTemplateReturningString(c_templateName)

        py_string_i = make_py_str(c_string, encoding)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def call_template_returning_file(self, str template_name=None, **kwds):
        """
        call_template_returning_file(self, str template_name, **kwds)
        Invoke a transformation by calling a named template with the result saved to file. It is possible to specify the
        output file as an argument or using the set_output_file method.
        Args:
			template_name (str): The name of the template to invoke. If None is supplied then call the initial-template.
            **kwds: Possible keyword arguments: output_file (str), and base_output_uri (str) which is used for
                resolving relative URIs in the href attribute of the xsl:result-document instruction.
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) executable.call_template_returning_file("main", output_file="result.xml")
            2) executable.set_global_context_item(file_name="cat.xml")\r
               executable.call_template_returning_file("main", output_file="result.xml")
            3) executable.set_global_context_item(file_name="cat.xml")\r
               executable.set_output_file("result.xml")\r
               executable.call_template_returning_file()
			   print(result)
        """
        cdef char * c_outputfile = NULL
        cdef const char * c_templateName = NULL
        py_output_string = None
        for key, value in kwds.items():
          if isinstance(value, str):

            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_string_string = value.encode('utf-8') if value is not None else None
              c_base_output_uri = py_string_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            if key == "output_file":
              py_output_string = value.encode('UTF-8') if value is not None else None
              c_outputfile = py_output_string if value is not None else ""
        py_template_name_string = template_name.encode('UTF-8') if template_name is not None else None
        if template_name is not None:
            c_templateName = py_template_name_string
        self.thisxptr.callTemplateReturningFile(c_templateName, c_outputfile)

     def call_function_returning_value(self, str function_name, list args, **kwds):
        """
        call_function_returning_value(self, str function_name, list args, **kwds)
        Invoke a transformation by calling a named function and return the result as a PyXdmValue.
        Args:
			function_name (str): The name of the function to invoke, in clark notation {uri}local
			args (list[PyXdmValue]): Pointer array of PyXdmValue objects - the values of the arguments to be supplied
			    to the function.
            **kwds: Possible keyword arguments: base_output_uri (str)
        Returns:
            PyXdmValue: Result of the transformation as a PyXdmValue object
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.call_function_returning_value("{http://localhost/example}func", [])
            2) executable.set_global_context_item(file_name="cat.xml")\r
               result = executable.call_function_returning_value("{http://localhost/test}add", [saxonproc.make_integer_value(2)])

        """
        cdef const char * c_functionName = NULL
        cdef PyXdmValue value_ = None
        for key, value in kwds.items():
          if isinstance(value, str):
              if key == "base_output_uri":
                '''c_base_output_uri = make_c_str(value)'''
                py_string_string = value.encode('utf-8') if value is not None else None
                c_base_output_uri = py_string_string if value is not None else ""
                self.thisxptr.setBaseOutputURI(c_base_output_uri)

        cdef int len_= 0;
        len_ = len(args)
        """ TODO handle memory when finished with XdmValues """
        cdef saxoncClasses.XdmValue ** argumentV = self.thisxptr.createXdmValueArray(len_)

        for x in range(len(args)):
          if isinstance(args[x], PyXdmValue):
            value_ = args[x]
            argumentV[x] = value_.thisvptr
            argumentV[x].incrementRefCount()
          else:
            raise Exception("Argument value at position " , x , " is not a PyXdmValue. The following object found: ", type(args[x]))
        '''c_functionName = make_c_str(function_name)'''
        py_function_string = function_name.encode('UTF-8') if function_name is not None else None
        c_functionName = py_function_string if function_name is not None else ""
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmFunctionItem fval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        xdmValue = self.thisxptr.callFunctionReturningValue(c_functionName, argumentV, len(args))
        if len_ > 0:
            self.thisxptr.deleteXdmValueArray(argumentV, len_)
        if xdmValue is NULL:
          return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
          aval = PyXdmAtomicValue()
          aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
          return aval
        elif type_ == XdmType.XDM_NODE:
          nval = PyXdmNode()
          nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
          return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
          val = PyXdmValue()
          val.thisvptr = xdmValue
          return val
     def call_function_returning_string(self, str function_name, list args, **kwds):
        """
        call_function_returning_string(self, str function_name, list args, **kwds)
        Invoke a transformation by calling a named function and return the result as a serialized string.
        Args:
			function_name (str): The name of the function to invoke, in clark notation {uri}local
			args (list[PyXdmValue]): Pointer array of PyXdmValue objects - the values of the arguments to be supplied
			    to the function.
            **kwds: Possible keyword arguments: base_output_uri (str). Also accept the keyword 'encoding' (str) to
                specify the encoding of the output string. This must match the encoding specified by xsl:output in
                the stylesheet, or as specified using set_property() on this PyXsltExecutable. If not specified
                then the platform default encoding is used.
        Returns:
            str: Result of the transformation as a str value
        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test1.xsl")
            1) result = executable.call_function_returning_string("{http://localhost/example}func", [])
            2) executable.set_global_context_item(file_name="cat.xml")\r
               result = executable.call_function_returning_string("{http://localhost/test}add", [saxonproc.make_integer_value(2)])
        """
        cdef const char * c_functionName = NULL
        cdef PyXdmValue value_ = None
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_s_string = value.encode('UTF-8') if value is not None else None
              c_base_output_uri = py_s_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)

        cdef int _len = len(args)
        """ TODO handle memory when finished with XdmValues """
        cdef saxoncClasses.XdmValue ** argumentV = self.thisxptr.createXdmValueArray(_len)
        for x in range(_len):
          if isinstance(args[x], PyXdmValue):
            value_ = args[x]
            argumentV[x] = value_.thisvptr
            value_.thisvptr.incrementRefCount()
          else:
            raise Exception("Argument value at position ",x," is not a PyXdmValue")
        '''c_functionName = make_c_str(function_name)'''
        py_s_string = function_name.encode('UTF-8') if function_name is not None else None
        c_functionName = py_s_string if function_name is not None else ""
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        cdef const char* c_string = self.thisxptr.callFunctionReturningString(c_functionName, argumentV, _len)
        if _len > 0:
            self.thisxptr.deleteXdmValueArray(argumentV, _len)
        encoding = sys.getdefaultencoding()
        if "encoding" in kwds:
            encoding = kwds["encoding"]
        py_string_i = make_py_str(c_string, encoding)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def call_function_returning_file(self, str function_name, list args, **kwds):
        """
        call_function_returning_file(self, str function_name, list args, **kwds)
        Invoke a transformation by calling a named function with the result saved to file. It is possible to specify
        the output file as an argument or using the set_output_file method.
        Args:
			function_name(str): The name of the function to invoke, in clark notation {uri}local
			args (list[PyXdmValue]): Pointer array of PyXdmValue objects - the values of the arguments to be supplied
			    to the function.
            **kwds: Possible keyword arguments: output_file (str) and base_output_uri (str)

        Raises:
            PySaxonApiError: Error raised in the event of a dynamic error

        Example:
            executable = xslt30_proc.compile_stylesheet(stylesheet_file="test2.xsl")
            1) executable.set_output_file("result.xml")
			   executable.call_function_returning_file("{http://localhost/example}func", [])
            2) executable.set_global_context_item(file_name="cat.xml")\r
               executable.call_function_returning_file("{http://localhost/test}add", [saxonproc.make_integer_value(2)], output_file="result.xml")
        """
        cdef const char * c_functionName = NULL
        cdef const char * c_outputfile = NULL
        cdef PyXdmValue value_ = None
        for key, value in kwds.items():
          if isinstance(value, str):
            if key == "base_output_uri":
              '''c_base_output_uri = make_c_str(value)'''
              py_s_string = value.encode('UTF-8') if value is not None else None
              c_base_output_uri = py_s_string if value is not None else ""
              self.thisxptr.setBaseOutputURI(c_base_output_uri)
            if key == "output_file":
              py_output_string = value.encode('UTF-8') if value is not None else None
              c_outputfile = py_output_string if value is not None else ""

        cdef int _len = len(args)
        """ TODO handle memory when finished with XdmValues """
        cdef saxoncClasses.XdmValue ** argumentV = self.thisxptr.createXdmValueArray(_len)
        for x in range(len(args)):
          if isinstance(args[x], PyXdmValue):
            value_ = args[x]
            argumentV[x] = value_.thisvptr
            value_.thisvptr.incrementRefCount()
          else:
            raise Exception("Argument value at position ",x," is not a PyXdmValue")
        '''c_functionName = make_c_str(function_name)'''
        py_s_string = function_name.encode('UTF-8') if function_name is not None else None
        c_functionName = py_s_string if function_name is not None else ""
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef saxoncClasses.XdmValue * xdmValue = NULL
        self.thisxptr.callFunctionReturningFile(c_functionName, argumentV, _len, c_outputfile)
        if _len > 0:
            self.thisxptr.deleteXdmValueArray(argumentV, _len)


     @property
     def exception_occurred(self):
        """
        exception_occurred(self)
        Property to check for pending exceptions without creating a local reference to the exception object
        Returns:
            boolean: True when there is a pending exception; otherwise False
        """
        return self.thisxptr.exceptionOccurred()

     def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown
        """
        self.thisxptr.exceptionClear()

     @property
     def error_message(self):
        """
        error_message(self)
        A transformation may have a number of errors reported against it. Get the error message if there are any errors
        Returns:
            str: The message of the exception. Returns None if the exception does not exist.
        """
        cdef const char* c_string = self.thisxptr.getErrorMessage()
        ustring = make_py_str(c_string)
        return ustring

        """def error_code(self):  """
        """                        
        error_code(self, index)
        A transformation may have a number of errors reported against it. Get the i'th error code if there are any errors
        Args:
            index (int): The i'th exception
        Returns:
            str: The error code associated with the i'th exception. Returns None if the i'th exception does not exist.
        """
        """cdef const char* c_string = self.thisxptr.getErrorCode()
        ustring = c_string.decode('UTF-8') if c_string is not NULL else None
        return ustring"""

cdef class PyXQueryProcessor:
     """A PyXQueryProcessor represents a factory to compile, load and execute queries. """
     cdef saxoncClasses.XQueryProcessor *thisxqptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        """
        __cinit__(self)
        Constructor for PyXQueryProcessor
        """
        self.thisxqptr = NULL
     def __dealloc__(self):
        """
        __dealloc__(self)
        """
        if self.thisxqptr != NULL:
           del self.thisxqptr
     def set_context(self, ** kwds):
        """
        set_context(self, **kwds)
        Set the initial context for the query
        Args:
            **kwds: Possible keyword arguments: file_name (str) or xdm_item (PyXdmItem)
        """
        py_error_message = "Error: set_context should contain exactly one of the following keyword arguments: (file_name|xdm_item)"
        if len(kwds) != 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source
        cdef PyXdmItem xdm_item = None
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            self.thisxqptr.setContextItemFromFile(c_source)
        elif "xdm_item" in kwds:
            xdm_item = kwds["xdm_item"]

            xdm_item = kwds["xdm_item"]

            if  isinstance(xdm_item, PyXdmItem):
                xdm_item.derivedptr.incrementRefCount()
            elif  isinstance(xdm_item, PyXdmNode):
                xdm_item.derivednptr.incrementRefCount()
            elif  isinstance(xdm_item, PyXdmAtomicValue):
                xdm_item.derivedaptr.incrementRefCount()

            self.thisxqptr.setContextItem(xdm_item.derivedptr)
        else:
          raise Exception(py_error_message)

     def set_streaming(self, bool option):
         """
         set_streaming(self, bool option)
         Say whether the query should be compiled and evaluated to use streaming. Option requires SaxonC-EE.
         Args:
             option (bool): if true, the compiler will attempt to compile a query to be capable of executing in
                streaming mode. If the query cannot be streamed, a compile-time exception is reported. In
                streaming mode, the source document is supplied as a stream, and no tree is built in memory.
                The default is false.
         """
         cdef bool c_option
         c_option = option
         return self.thisxqptr.setStreaming(c_option)

     def is_streaming(self):
         """
         is_streaming(self, bool option)
         Ask whether the streaming option has been set.
         Returns:
               true if the streaming option has been set.
         """
         return self.thisxqptr.isStreaming()

     def set_output_file(self, output_file):
        """
        set_output_file(self, output_file)
        Set the output file where the result is sent
        Args:
            output_file (str): Name of the output file
        """
        cdef const char * c_outfile = NULL
        py_value_string = output_file.encode('UTF-8') if output_file is not None else None
        c_outfile = py_value_string if output_file is not None else ""
        self.thisxqptr.setOutputFile(c_outfile)
     def set_parameter(self, name, PyXdmValue value):
        """
        set_parameter(self, name, PyXdmValue value)
        Set the value of a query parameter
        Args:
            name (str): the name of the stylesheet parameter, as a string. For a namespaced parameter use
                clark notation {uri}local
            value (PyXdmValue): the value of the query parameter, or NULL to clear a previously set value
        """
        cdef const char * c_str = NULL
        '''make_c_str(name)'''
        py_s_string = name.encode('UTF-8') if name is not None else None
        c_str = py_s_string if name is not None else ""
        if name is not None and value is not None:
            value.thisvptr.incrementRefCount()
            self.thisxqptr.setParameter(c_str, value.thisvptr)
     def remove_parameter(self, name):
        """
        remove_parameter(self, name)
        Remove the parameter given by name from the PyXQueryProcessor. The parameter will not have any effect on the
        query if it has not yet been executed.
        Args:
            name (str): The name of the query parameter
        Returns:
            bool: True if the removal of the parameter has been successful, False otherwise.
        """
        py_value_string = name.encode('UTF-8') if name is not None else None
        c_name = py_value_string if name is not None else ""
        self.thisxqptr.removeParameter(c_name)
     def set_property(self, name, str value):
        """
        set_property(self, name, str value)
        Set a property specific to the processor in use.
        Args:
            name (str): The name of the property
            value (str): The value of the property
        Example:
            PyXQueryProcessor: set serialization properties (names start with '!' i.e. name "!method" -> "xml")\r
            'o': output file name,\r
            'dtd': Possible values 'on' or 'off' to set DTD validation,\r
            'resources': directory to find Saxon data files,\r
            's': source as file name,\r
        """
        py_name_string = name.encode('UTF-8') if name is not None else None
        c_name = py_name_string if name is not None else ""
        py_value_string = value.encode('UTF-8') if value is not None else None
        c_value = py_value_string if value is not None else ""
        self.thisxqptr.setProperty(c_name, c_value)
     def clear_parameters(self):
        """
        clear_parameters(self)
        Clear all parameters set on the processor
        """
        self.thisxqptr.clearParameters()
     def clear_properties(self):
        """
        clear_properties(self)
        Clear all properties set on the processor
        """
        self.thisxqptr.clearProperties()
     def set_updating(self, updating):
        """
        set_updating(self, updating)
        Say whether the query is allowed to be updating. XQuery update syntax will be rejected during query compilation
        unless this flag is set. XQuery Update is supported only under SaxonC-EE.
        Args:
            updating (bool): true if the query is allowed to use the XQuery Update facility (requires SaxonC-EE).
                If set to false, the query must not be an updating query. If set to true, it may be either an
                updating or a non-updating query.
        """
        self.thisxqptr.setUpdating(updating)
     def run_query_to_value(self, ** kwds):
        """
        run_query_to_value(self, **kwds)
        Execute a query and return the result as a PyXdmValue object.
        Args:
            **kwds: Possible keyword arguments: input_file_name (str) or input_xdm_item (PyXdmItem) can be used to
                supply the input; query_file (str) or query_text (str) can be used to supply the query;
                lang (str) can be used to specify which version of XQuery should be used, options: '3.1' or '4.0'.
                Also accept the keyword 'encoding' (str) to specify the encoding of the query_text string
                is specified. If not specified then the platform default encoding is used.
        Returns:
            PyXdmValue: Output result as a PyXdmValue
        Raises:
            PySaxonApiError: Error if failure to run query
            Exception: Error if invalid use of keywords
        """
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmValue value_
        cdef PyXdmNode nval = None
        cdef PyXdmFunctionItem fval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmValue val = None
        cdef char * c_encoding_string = NULL
        cdef const char * c_content = NULL
        if not len(kwds) == 0:

            encoding = None
            py_encoding_string = None
            if "encoding" in kwds:
                encoding = kwds["encoding"]
                py_encoding_string = encoding.encode('UTF-8')
                c_encoding_string = py_encoding_string
            else:
                encoding = sys.getdefaultencoding()

            if "lang" in kwds:
                py_lang_string = kwds["lang"]
                py_ta_string = py_lang_string.encode('UTF-8') if py_lang_string is not None else None
                c_lang = py_ta_string if py_lang_string is not None else ""
                self.thisxqptr.setLanguageVersion(c_lang)

            if "input_file_name" in kwds:
                self.set_context(file_name=kwds["input_file_name"])
            elif "input_xdm_item" in kwds:
                self.set_context(xdm_item=(kwds["input_xdm_item"]))
            if "query_file" in kwds:
                self.set_query_file(kwds["query_file"])
            elif "query_text" in kwds:
                content = kwds["query_text"]
                if content is not None:
                    '''make_c_str(content)'''
                    py_s_string = content.encode(encoding) if content is not None else None
                    c_content = py_s_string if content is not None else ""

        cdef saxoncClasses.XdmValue * xdmValue = self.thisxqptr.executeQueryToValue(NULL, c_content, c_encoding_string)
        if xdmValue is NULL:
            return None
        cdef type_ = xdmValue.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmValue
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmValue
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmValue
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmValue
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmValue
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            val.thisvptr.incrementRefCount()
            return val
     def run_query_to_string(self, ** kwds):
        """
        run_query_to_string(self, **kwds)
        Execute a query and return the result as a string.
        Args:
            **kwds: Possible keyword arguments: input_file_name (str) or input_xdm_item (PyXdmItem) can be used to
                supply the input; query_file (str) or query_text (str) can be used to supply the query;
                lang (str) can be used to specify which version of XQuery should be used, options: '3.1' or '4.0'.
                Also accept the keyword 'encoding' (str) to specify the encoding of the query_text string
                is specified. If not specified then the platform default encoding is used.
        Returns:
            str: Output result as a string
        Raises:
            PySaxonApiError: Error if failure to run query
            Exception: Error if invalid use of keywords
        """
        cdef const char * c_string
        cdef char * c_encoding_string = NULL
        cdef const char * c_content = NULL
        content = None
        if len(kwds) == 0:
            c_string = self.thisxqptr.runQueryToString()
            py_string_i = make_py_str(c_string)
            saxoncClasses.SaxonProcessor.deleteString(c_string)
            return py_string_i

        encoding = None
        py_encoding_string = None
        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string
        else:
            encoding = sys.getdefaultencoding()

        if "lang" in kwds:
          py_lang_string = kwds["lang"]
          py_ta_string = py_lang_string.encode('UTF-8') if py_lang_string is not None else None
          c_lang = py_ta_string if py_lang_string is not None else ""
          self.thisxqptr.setLanguageVersion(c_lang)

        if "input_file_name" in kwds:
          self.set_context(file_name=kwds["input_file_name"])
        elif "input_xdm_item" in kwds:
          self.set_context(xdm_item=(kwds["input_xdm_item"]))
        if "query_file" in kwds:
          self.set_query_file(kwds["query_file"])
        elif "query_text" in kwds:
          content = kwds["query_text"]
          if content is not None:
              py_s_string = content.encode(encoding) if content is not None else None
              c_content = py_s_string if content is not None else ""

        c_string = self.thisxqptr.executeQueryToString(NULL, c_content, c_encoding_string)
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def run_query_to_file(self, ** kwds):
        """
        run_query_to_file(self, **kwds)
        Execute a query with the result saved to file.
        Args:
            **kwds: Possible arguments: output_file_name (str) to specify the output file, if
                omitted then the output file name needs to be supplied as a property;
                input_file_name (str) or input_xdm_item (PyXdmItem) can be used to supply
                the input; query_file (str) or query_text (str) can be used to supply the query;
                lang (str) can be used to specify which version of XQuery should be used,
                options: '3.1' or '4.0'.
                Also accept the keyword 'encoding' (str) to specify the encoding of the query_text string
                is specified. If not specified then the platform default encoding is used.
        Raises:
            PySaxonApiError: Error if failure to run query
            Exception: Error if invalid use of keywords
        """
        cdef char * c_encoding_string = NULL
        cdef const char * c_content = NULL
        if len(kwds) == 0:
          self.thisxqptr.runQueryToFile()

        encoding = None
        py_encoding_string = None
        if "encoding" in kwds:
            encoding = kwds["encoding"]
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string
        else:
            encoding = sys.getdefaultencoding()

        if "lang" in kwds:
          py_lang_string = kwds["lang"]
          py_ta_string = py_lang_string.encode('UTF-8') if py_lang_string is not None else None
          c_lang = py_ta_string if py_lang_string is not None else ""
          self.thisxqptr.setLanguageVersion(c_lang)
        if "input_file_name" in kwds:
          self.set_context(file_name=(kwds["input_file_name"]))
        elif "input_xdm_item" in kwds:
          self.set_context(xdm_item=(kwds["input_xdm_item"]))
        if "output_file_name" in kwds:
          self.set_output_file(kwds["output_file_name"])

        if "query_file" in kwds:
          self.set_query_file(kwds["query_file"])
        elif "query_text" in kwds:
            content = kwds["query_text"]
            if content is not None:
                '''make_c_str(content)'''
                py_s_string = content.encode(encoding) if content is not None else None
                c_content = py_s_string if content is not None else ""

        self.thisxqptr.executeQueryToFile(NULL, NULL, c_content, c_encoding_string)
     def declare_namespace(self, prefix, uri):
        """
        declare_namespace(self, prefix, uri)
        Declare a namespace binding as part of the static context for queries compiled using this processor.
        This binding may be overridden by a binding that appears in the query prolog.
        The namespace binding will form part of the static context of the query, but it will not be copied
        into result trees unless the prefix is actually used in an element or attribute name.
        Args:
            prefix (str): The namespace prefix. If the value is a zero-length string, this method sets the default
                namespace for elements and types.
            uri (str) : The namespace URI. It is possible to specify a zero-length string to "undeclare" a namespace;
                in this case the prefix will not be available for use, except in the case where the prefix is also a
                zero length string, in which case the absence of a prefix implies that the name is in no namespace.
        """
        cdef const char * c_prefix = NULL
        '''make_c_str(prefix)'''
        py_s_string = prefix.encode('UTF-8') if prefix is not None else None
        c_prefix = py_s_string if prefix is not None else ""

        cdef const char * c_uri = NULL
        '''make_c_str(uri)'''
        py_ss_string = uri.encode('UTF-8') if uri is not None else None
        c_uri = py_ss_string if uri is not None else ""
        self.thisxqptr.declareNamespace(c_prefix, c_uri)

     def set_query_file(self, file_name):
        """
        set_query_file(self, file_name)
        Supply the query as a file
        Args:
            file_name (str): The file name for the query
        """
        cdef const char * c_filename = NULL
        '''make_c_str(file_name)'''
        py_s_string = file_name.encode('UTF-8') if file_name is not None else None
        c_filename = py_s_string if file_name is not None else ""
        self.thisxqptr.setQueryFile(c_filename)

     def set_query_content(self, str content):
        """
        set_query_content(self, str content)
        Supply the query as a string
        Args:
            content (str): The query content supplied as a string
        """
        cdef const char * c_content = NULL
        if content is not None:
            '''make_c_str(content)'''
            py_s_string = content.encode('UTF-8') if content is not None else None
            c_content = py_s_string if content is not None else ""
            self.thisxqptr.setQueryContent(c_content)
     def set_query_base_uri(self, base_uri):
        """
        set_query_base_uri(self, base_uri)
        Set the static base URI for the query
        Args:
            base_uri (str): The static base URI; or None to indicate that no base URI is available
        """
        cdef const char * c_baseuri = NULL
        py_base_string = base_uri.encode('UTF-8') if base_uri is not None else None
        c_baseuri = py_base_string if base_uri is not None else ""
        self.thisxqptr.setQueryBaseURI(c_baseuri)
     def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory.
        Args:
            cwd (str): current working directory
        """
        py_cwd_string = cwd.encode('UTF-8') if cwd is not None else None
        c_cwd = py_cwd_string if cwd is not None else ""
        self.thisxqptr.setcwd(c_cwd)
     def check_exception(self):
        """
        check_exception(self)
        Check for exception thrown and get message of the exception.
        Returns:
            str: Returns the exception message if thrown otherwise returns None
        """
        return self.thisxqptr.checkException()

     @property
     def exception_occurred(self):
        """
        exception_occurred(self)
        Property to check for pending exceptions without creating a local reference to the exception object
        Returns:
            boolean: True when there is a pending exception; otherwise False
        """
        return self.thisxqptr.exceptionOccurred()

     def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown
        """
        self.thisxqptr.exceptionClear()

     @property
     def error_message(self):
        """
        error_message(self)
        A query may have a number of errors reported against it. This property returns an error message
        if there are any errors.
        Returns:
            str: The message of the exception. Returns None if the exception does not exist.
        """
        return make_py_str(self.thisxqptr.getErrorMessage())

     @property
     def error_code(self):
        """
        error_code(self)
        A query may have a number of errors reported against it. This property returns the error code
        if there are any errors.
        Returns:
            str: The error code associated with the exception. Returns None if the exception does not exist.
        """
        return make_py_str(self.thisxqptr.getErrorCode())

cdef class PyXPathProcessor:
     """A PyXPathProcessor represents a factory to compile, load and execute XPath expressions. """
     cdef saxoncClasses.XPathProcessor *thisxpptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        """
        __cinit__(self)
        Constructor for PyXPathProcessor
        """
        self.thisxpptr = NULL
     def __dealloc__(self):
        """
        __dealloc__(self)
        """
        if self.thisxpptr != NULL:
           del self.thisxpptr
     def evaluate(self, xpath_str, encoding = None):
        """
        evaluate(self, xpath_str)
        Evaluate an XPath expression supplied as a string
        Args:
            xpath_str (str): The XPath expression supplied as a string
            encoding (str): The encoding of the XPath string. Argument can be omitted or None.
                If not specified then the platform default encoding is used.
        Returns:
            PyXdmValue: the result of evaluating the XPath expression
        Raises:
            PySaxonApiError: Error if failure to evaluate XPath expression
        """
        cdef char * c_encoding_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        else :
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string if py_encoding_string is not None else ""
        py_value_string = xpath_str.encode(encoding) if xpath_str is not None else None
        c_xpath = py_value_string if xpath_str is not None else ""
        cdef PyXdmValue val = None
        cdef type_ = 0
        cdef saxoncClasses.XdmValue * xdmValue = self.thisxpptr.evaluate(c_xpath, c_encoding_string)
        if xdmValue == NULL:
            return None
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            return val

     def evaluate_single(self, xpath_str, encoding = None):
        """
        evaluate_single(self, xpath_str)
        Evaluate an XPath expression supplied as a string, returning a single item
        Args:
            xpath_str (str): The XPath expression supplied as a string
            encoding (str): The encoding of the XPath string. Argument can be omitted or None.
                If not specified then the platform default encoding is used.
        Returns:
            PyXdmItem: A single XDM item is returned. Returns None if the expression returns an empty sequence.
            If the expression returns a sequence of more than one item, any items after the first are ignored.
        Raises:
            PySaxonApiError: Error if failure to evaluate XPath expression
        """
        cdef PyXdmNode val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmMap mval = None
        cdef PyXdmArray aaval = None
        cdef PyXdmFunctionItem fval = None
        cdef const char * c_xpath = NULL
        cdef char * c_encoding_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        else :
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string if py_encoding_string is not None else ""
        py_s_string = xpath_str.encode(encoding) if xpath_str is not None else None
        c_xpath = py_s_string if xpath_str is not None else ""

        cdef saxoncClasses.XdmItem * xdmItem = self.thisxpptr.evaluateSingle(c_xpath, c_encoding_string)

        if xdmItem == NULL:
            return None
        cdef type_ = xdmItem.getType()
        if type_ == XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmItem
            aval.derivedptr.incrementRefCount()
            return aval
        elif type_ == XdmType.XDM_NODE:
            val = PyXdmNode()
            val.derivednptr = val.derivedptr = val.thisvptr = <saxoncClasses.XdmNode*>xdmItem
            val.derivedptr.incrementRefCount()
            return val
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
            fval = PyXdmFunctionItem()
            fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmItem
            fval.thisvptr.incrementRefCount()
            return fval
        elif type_ == XdmType.XDM_MAP:
            mval = PyXdmMap()
            mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmItem
            mval.thisvptr.incrementRefCount()
            return mval
        elif type_ == XdmType.XDM_ARRAY:
            aaval = PyXdmArray()
            aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmItem
            aaval.thisvptr.incrementRefCount()
            return aaval
        else:
            val = PyXdmItem()
            val.derivedptr = val.thisvptr = xdmItem
            val.derivedptr.incrementRefCount()
            return val

     def set_context(self, **kwds):
        """
        set_context(self, **kwds)
        Set the initial context for the XPath expression
        Args:
            **kwds: Possible keyword arguments: file_name (str) or xdm_item (PyXdmItem)
        """
        py_error_message = "Error: set_context should contain exactly one of the following keyword arguments: (file_name|xdm_item)"
        if len(kwds) != 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source
        cdef PyXdmItem xdm_item = None
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            self.thisxpptr.setContextFile(c_source)
        elif "xdm_item" in kwds:
            xdm_item = kwds["xdm_item"]

            if  isinstance(xdm_item, PyXdmItem):
                xdm_item.derivedptr.incrementRefCount()
            elif  isinstance(xdm_item, PyXdmNode):
                xdm_item.derivednptr.incrementRefCount()
            elif  isinstance(xdm_item, PyXdmAtomicValue):
                xdm_item.derivedaptr.incrementRefCount()

            self.thisxpptr.setContextItem(xdm_item.derivedptr)
        else:
          raise Exception(py_error_message)

     def set_language_version(self, value):
         """
         set_language_version(self, version)
         Say whether an XPath 2.0, XPath 3.0, XPath 3.1 or XPath 4.0 processor is required.
         Args:
             value (str): One of the values 1.0, 2.0, 3.0, 3.05, 3.1, 4.0.
         """
         py_value_string = value.encode('UTF-8') if value is not None else None
         cdef char * c_value = py_value_string if value is not None else ""
         self.thisxpptr.setLanguageVersion(c_value)


     def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory
        Args:
            cwd (str): current working directory
        """
        py_cwd_string = cwd.encode('UTF-8') if cwd is not None else None
        cdef char * c_cwd = py_cwd_string if cwd is not None else ""
        self.thisxpptr.setcwd(c_cwd)
     def effective_boolean_value(self, xpath_str, encoding = None):
        """
        effective_boolean_value(self, xpath_str)
        Evaluate the XPath expression, returning the effective boolean value of the result.
        Args:
            xpath_str (str): XPath expression supplied as a string
            encoding (str): The encoding of the XPath string. Argument can be omitted or None.
                If not specified then the platform default encoding is used.
        Returns:
            boolean: The result is a boolean value.
        Raises:
            PySaxonApiError: Error if failure to evaluate XPath expression
        """
        cdef char * c_encoding_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        else :
            py_encoding_string = encoding.encode('UTF-8')
            c_encoding_string = py_encoding_string if py_encoding_string is not None else ""

        py_value_string = xpath_str.encode(encoding) if xpath_str is not None else None
        c_xpath = py_value_string if xpath_str is not None else ""
        return self.thisxpptr.effectiveBooleanValue(c_xpath, c_encoding_string)
     def set_parameter(self, name, value):
        """
        set_parameter(self, name, value)
        Set the value of an XPath parameter
        Args:
            name (str): the name of the XPath parameter, as a string. For a namespaced parameter use
                clark notation {uri}local
            value (PyXdmValue): the value of the query parameter, or NULL to clear a previously set value
        """
        cdef char * c_str = NULL
        cdef PyXdmAtomicValue avalue_
        cdef PyXdmItem ivalue_
        cdef PyXdmNode nvalue_
        cdef PyXdmValue value_
        '''make_c_str(name)'''
        py_name_string = name.encode('utf-8') if name is not None else None
        c_str = py_name_string if name is not None else ""
        if c_str is not NULL:
            if isinstance(value, PyXdmValue):
                value_ = value
                value_.thisvptr.incrementRefCount()
                self.thisxpptr.setParameter(c_str, value_.thisvptr)
            elif  isinstance(value, PyXdmNode):
                nvalue_ = value
                nvalue_.derivednptr.incrementRefCount()
                self.thisxpptr.setParameter(c_str, <saxoncClasses.XdmValue *>  nvalue_.derivednptr)
            elif  isinstance(value, PyXdmAtomicValue):
                avalue_ = value
                avalue_.derivedaptr.incrementRefCount()
                self.thisxpptr.setParameter(c_str, <saxoncClasses.XdmValue *> avalue_.derivedaptr)
            elif  isinstance(value, PyXdmItem):
                ivalue_ = value
                ivalue_.derivedptr.incrementRefCount()
                self.thisxpptr.setParameter(c_str, <saxoncClasses.XdmValue *>  ivalue_.derivedptr)

            '''self.thisxpptr.setParameter(c_str, value.thisvptr)'''
     def remove_parameter(self, name):
        """
        remove_parameter(self, name)
        Remove the parameter given by name from the PyXPathProcessor. The parameter will not have any effect on the
        XPath if it has not yet been executed.
        Args:
            name (str): The name of the XPath parameter
        Returns:
            bool: True if the removal of the parameter has been successful, False otherwise.
        """
        self.thisxpptr.removeParameter(name)
     def set_property(self, name, value):
        """
        set_property(self, name, value)
        Set a property specific to the processor in use.
        Args:
            name (str): The name of the property
            value (str): The value of the property
        Example:
            PyXPathProcessor: set serialization properties (names start with '!' i.e. name "!method" -> "xml")\r
            'resources': directory to find Saxon data files,\r
            's': source as file name,\r
            'extc': Register native library to be used with extension functions
        """
        py_name_string = name.encode('UTF-8') if name is not None else None
        c_name = py_name_string if name is not None else ""
        py_value_string = value.encode('UTF-8') if value is not None else None
        c_value = py_value_string if value is not None else ""
        self.thisxpptr.setProperty(c_name, c_value)
     def declare_namespace(self, prefix, uri):
        """
        declare_namespace(self, prefix, uri)
        Declare a namespace binding as part of the static context for XPath expressions compiled using this processor
        Args:
            prefix (str): The namespace prefix. If the value is a zero-length string, this method sets the default
                namespace for elements and types.
            uri (uri): The namespace URI. It is possible to specify a zero-length string to "undeclare" a namespace;
                in this case the prefix will not be available for use, except in the case where the prefix is also a
                zero length string, in which case the absence of a prefix implies that the name is in no namespace.
        """
        py_prefix_string = prefix.encode('UTF-8') if prefix is not None else None
        c_prefix = py_prefix_string if prefix is not None else ""
        py_uri_string = uri.encode('UTF-8') if uri is not None else None
        c_uri = py_uri_string if uri is not None else ""
        self.thisxpptr.declareNamespace(c_prefix, c_uri)

     def set_unprefixed_element_matching_policy(self, policy):
         """
         set_unprefixed_element_matching_policy(self, int policy)
         Set the policy for matching unprefixed element names in XPath expressions.
         Possible int values: DEFAULT_NAMESPACE = 0, ANY_NAMESPACE = 1 or DEFAULT_NAMESPACE_OR_NONE = 2
         Args:
         policy (int): The policy to be used
         """
         self.thisxpptr.setUnprefixedElementMatchingPolicy(self.thisxpptr.convertEnumPolicy(policy))



     def declare_variable(self, str name):
        """
        declare_variable(self, str name)
        Declare a variable as part of the static context for XPath expressions compiled using this processor.
        It is an error for the XPath expression to refer to a variable unless it has been declared. This method
        declares the existence of the variable, but it does not bind any value to the variable; that is done later,
        when the XPath expression is evaluated. The variable is allowed to have any type (that is, the required
        type is item()*).
        Args:
        name (str): The name of the variable, as a string in clark notation
        """
        py_name_string = name.encode('UTF-8') if name is not None else None
        c_name = py_name_string if name is not None else ""
        self.thisxpptr.declareVariable(c_name)

     def set_backwards_compatible(self, option):
        """
        set_backwards_compatible(self, option)
        Say whether XPath 1.0 backwards compatibility mode is to be used
        Args:
            option (bool): true if XPath 1.0 backwards compatibility is to be enabled, false if it is to be disabled.
        """
        cdef bool c_option
        c_option = option
        self.thisxpptr.setBackwardsCompatible(c_option)

     def set_base_uri(self, base_uri):
       """
       set_base_uri(self, base_uri)
       Set the static base URI for XPath expressions compiled using this XPathCompiler.
       The base URI is part of the static context, and is used to resolve any relative URIs appearing within an XPath
       expression, for example a relative URI passed as an argument to the doc() function. If no
       static base URI is supplied, then the current working directory is used.
       Args:
           base_uri (str): the base output URI
       """
       py_uri_string = base_uri.encode('UTF-8') if base_uri is not None else None
       cdef char * c_uri = py_uri_string if base_uri is not None else ""
       self.thisxpptr.setBaseURI(c_uri)

     @property
     def base_uri(self):
       """
       get_base_uri(self)
       Get the static base URI for XPath expressions compiled using this XPathCompiler.
       The base URI is part of the static context, and is used to resolve any relative URIs appearing within an XPath
       expression, for example a relative URI passed as an argument to the doc() function. If no
       static base URI is supplied, then the current working directory is used.
       Returns:
           str: the base output URI as a string representation of the URI
       """
       cdef const char* c_string = NULL
       c_string = self.thisxpptr.getBaseURI()
       py_base_uri_string_value = make_py_str(c_string)
       return py_base_uri_string_value

     def set_caching(self, is_caching):
         """
         set_caching(self, is_caching)
         Say whether the compiler should maintain a cache of compiled expressions.
         Args:
         is_caching (bool): if set to true, caching of compiled expressions is enabled.
            If set to false, any existing cache is cleared, and future compiled expressions
            will not be cached until caching is re-enabled. The cache is also cleared
            (but without disabling future caching) if any method is called that changes the
            static context for compiling expressions, for example declare_variable() or
            declare_namespace().
         """
         cdef bool c_is_caching
         c_is_caching = is_caching
         self.thisxpptr.setCaching(c_is_caching)
     def import_schema_namespace(self, uri):
         """
         import_schema_namespace(self, uri)
         Import a schema namespace
         Args:
         uri (str): The schema namespace to be imported. To import declarations in a no-namespace schema,
            supply a zero-length string.
         """
         py_uri_string = uri.encode('UTF-8') if uri is not None else None
         c_name = py_uri_string if uri is not None else ""
         self.thisxpptr.importSchemaNamespace(c_name)
     def clear_parameters(self):
        """
        clear_parameter(self)
        Clear all parameters set on the processor
        """
        self.thisxpptr.clearParameters()
     def clear_properties(self):
        """
        clear_parameter(self)
        Clear all properties set on the processor
        """
        self.thisxpptr.clearProperties()

     @property
     def exception_occurred(self):
        """
        exception_occurred(self)
        Check if an exception has occurred internally within SaxonC
        Returns:
            boolean: True if an exception has been reported; otherwise False
        """
        return self.thisxpptr.exceptionOccurred()

     def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown
        """
        self.thisxpptr.exceptionClear()

     @property
     def error_message(self):
        """
        error_message(self)
        An expression may have a number of errors reported against it. This property returns the error message
        if there are any errors.
        Returns:
            str: The message of the exception. Returns None if the exception does not exist.
        """
        cdef const char * c_string = self.thisxpptr.getErrorMessage()
        py_string_i = make_py_str(c_string)
        return py_string_i

     @property
     def error_code(self):
        """
        error_code(self)
        An expression may have a number of errors reported against it. This property returns the error code
        if there are any errors.
        Returns:
            str: The error code associated with the exception. Returns None if the exception does not exist.
        """
        return make_py_str(self.thisxpptr.getErrorCode())

cdef class PySchemaValidator:
     """A PySchemaValidator represents a factory for validating instance documents against a schema."""

     cdef saxoncClasses.SchemaValidator *thissvptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        self.thissvptr = NULL
     def __dealloc__(self):
        if self.thissvptr != NULL:
           del self.thissvptr
     def set_cwd(self, cwd):
        """
        set_cwd(self, cwd)
        Set the current working directory
        Args:
            cwd (str): current working directory
        """
        py_cwd_string = cwd.encode('UTF-8') if cwd is not None else None
        cdef char * c_cwd = py_cwd_string if cwd is not None else ""
        self.thissvptr.setcwd(c_cwd)
     def register_schema(self, **kwds):
        """
        register_schema(self, **kwds)
        Register a schema supplied as file name, schema text, or XDM node
        Args:
            **kwds: Possible keyword arguments: must be one of the following (xsd_text|xsd_file|xsd_node)
        """
        py_error_message = "Error: register_schema should contain exactly one of the following keyword arguments: (xsd_text|xsd_file|xsd_node)"
        if len(kwds) != 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source

        if "xsd_text" in kwds:
            py_value = kwds["xsd_text"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            self.thissvptr.registerSchemaFromString(c_source)
        elif "xsd_file" in kwds:
            py_value = kwds["xsd_file"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            self.thissvptr.registerSchemaFromFile(c_source)
        elif "xsd_node" in kwds:
            xsd_node = kwds["xsd_node"]
            if isinstance(xsd_node, PyXdmNode):
                self.thissvptr.registerSchemaFromFile(xsd_node.derivednptr)
        else:
          raise Exception(py_error_message)
     def export_schema(self, file_name):
        """
        export_schema(self, file_name)
        Export a precompiled Schema Component Model containing all the components (except built-in components)
        that have been loaded
        Args:
            file_name (str): The file name that will be used for the saved SCM
        """
        py_value_string = file_name.encode('UTF-8') if file_name is not None else None
        c_source = py_value_string
        if file_name is not None:
            self.thissvptr.exportSchema(c_source)
        else:
            raise Warning("Unable to export the Schema. file_name has the value None")

     def set_output_file(self, output_file):
        """
        set_output_file(self, output_file)
        Set the name of the output file that will be used by the validator.
        Args:
            output_file (str): The output file name for use by the validator
        """
        py_value_string = output_file.encode('UTF-8') if output_file is not None else None
        c_source = py_value_string
        if output_file is not None:
            self.thissvptr.setOutputFile(c_source)
        else:
            raise Warning("Unable to set output_file. output_file has the value None")
     def validate(self, **kwds):
        """
        validate(self, **kwds)
        Validate an instance document by a registered schema.
        Args:
            **kwds: Possible keyword arguments: must be one of the following (file_name|xdm_node|xml_text).
                Specifies the source file to be validated. Allow None when source document is
                supplied using the set_source_node method
        Raises:
            Exception: Error if incorrect keyword used, options available: file_name|xdm_node|xml_text
            PySaxonApiError: if the source document is found to be invalid, or if error conditions occur
            that prevented validation from taking place (such as failure to read or parse the input document)
        """
        py_error_message = "Error: validate should contain exactly one of the following keyword arguments: (file_name|xdm_node|xml_text)"
        if len(kwds) > 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source
        cdef PyXdmNode xdm_node = None
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            self.thissvptr.validate(c_source)
        elif "xdm_node" in kwds:
            xdm_node = kwds["xdm_node"]
            if isinstance(xdm_node, PyXdmNode):
               self.thissvptr.setSourceNode(xdm_node.derivednptr)
               self.thissvptr.validate(NULL)
        else:
            self.thissvptr.validate(NULL)
     def validate_to_node(self, **kwds):
        """
        validate_to_node(self, **kwds)
        Validate an instance document by a registered schema, returning the validated document.
        Args:
            **kwds: Possible keyword arguments: must be one of the following (file_name|xdm_node|xml_text).
                Specifies the source file to be validated. Allow None when source document is supplied
                using the set_source_node method.
        Returns:
            PyXdmNode: The validated document returned to the calling program as a PyXdmNode
        Raises:
            Exception: Error if incorrect keyword used, options available: file_name|xdm_node|xml_text
            PySaxonApiError: if the source document is found to be invalid, or if error conditions occur
            that prevented validation from taking place (such as failure to read or parse the input document)
        """
        py_error_message = "Error: validate_to_node should contain exactly one of the following keyword arguments: (file_name|xdm_node|xml_text)"
        if len(kwds) > 1:
          raise Exception(py_error_message)
        cdef py_value = None
        cdef py_value_string = None
        cdef char * c_source
        cdef PyXdmNode xdm_node = None
        cdef PyXdmNode val = None
        cdef saxoncClasses.XdmNode * xdmNode = NULL
        if "file_name" in kwds:
            py_value = kwds["file_name"]
            py_value_string = py_value.encode('UTF-8') if py_value is not None else None
            c_source = py_value_string if py_value is not None else ""
            '''if isfile(py_value_string) == False:
                raise Exception("Source file with name "+py_value_string+" does not exist")'''
            xdmNode = self.thissvptr.validateToNode(c_source)
        elif "xdm_node" in kwds:
            xdm_node = kwds["xdm_node"]
            if isinstance(xdm_node, PyXdmNode):
                self.thissvptr.setSourceNode(xdm_node.derivednptr)
                xdmNode = self.thissvptr.validateToNode(NULL)
        else:
            xdmNode = self.thissvptr.validateToNode(NULL)

        if xdmNode == NULL:
            return None
        else:
            val = PyXdmNode()
            val.derivednptr = val.derivedptr = val.thisvptr =  xdmNode
            return val
     def set_source_node(self, PyXdmNode source):
        """
        set_source_node(self, PyXdmNode source)
        Set the source node for validation
        Args:
            source (PyXdmNode): the source node to be validated
        """
        self.thissvptr.setSourceNode(source.derivednptr)
     @property
     def validation_report(self):
        """
        validation_report(self)
        Get the validation report
        Returns:
            PyXdmNode: The Validation report result from the Schema validator
        Raises:
            PySaxonApiError: if the source document is found to be invalid, or if error conditions occur
            that prevented validation from taking place (such as failure to read or parse the input document)
        """
        cdef PyXdmNode val = None
        cdef saxoncClasses.XdmNode * xdmNode = NULL
        xdmNode = self.thissvptr.getValidationReport()
        if xdmNode == NULL:
            return None
        else:
            val = PyXdmNode()
            val.derivednptr = val.derivedptr = val.thisvptr = xdmNode
            return val
     def set_parameter(self, name, PyXdmValue value):
        """
        set_parameter(self, name, PyXdmValue value)
        Set the value of a parameter for the Schema validator
        Args:
            name (str): the name of the schema parameter, as a string. For a namespaced parameter use
                clark notation {uri}local
            value (PyXdmValue): the value of the parameter, or NULL to clear a previously set value
        """
        cdef const char * c_str = NULL
        '''make_c_str(name)'''
        py_name_string = name.encode('UTF-8') if name is not None else None
        c_str = py_name_string if name is not None else ""
        if c_str is not NULL:
            value.thisvptr.incrementRefCount()
            self.thissvptr.setParameter(c_str, value.thisvptr)
     def remove_parameter(self, name):
        """
        remove_parameter(self, name)
        Remove the parameter given by name from the PySchemaValidator. The parameter will not have any effect on the
        validation if it has not yet been executed.
        Args:
            name (str): The name of the schema parameter
        Returns:
            bool: True if the removal of the parameter has been successful, False otherwise.
        """
        cdef const char * c_str = NULL
        '''make_c_str(name)'''
        py_name_string = name.encode('UTF-8') if name is not None else None
        c_str = py_name_string if name is not None else ""
        if c_str is not NULL:
            self.thissvptr.removeParameter(c_str)

     def set_property(self, name, value, encoding = None):
        """
        set_property(self, name, value, encoding = None)
        Set a property specific to the processor in use.
        Args:
            name (str): The name of the property
            value (str): The value of the property
            encoding (str): The encoding of the name argument. Argument can be omitted or None.
                If not specified then the platform default encoding is used.
        Example:
            PySchemaValidator: set serialization properties (names start with '!' i.e. name "!method" -> "xml")\r
            'o': output file name,\r
            'dtd': Possible values 'on' or 'off' to set DTD validation,\r
            'resources': directory to find Saxon data files,\r
            's': source as file name,\r
            'string': Set the source as xml string for validation. Parsing will take place in the validate method\r
            'report-node': Boolean flag for validation reporting feature. Error validation failures are represented
                in an XML document and returned as a PyXdmNode object\r
            'report-file': Specify value as a file name string. This will switch on the validation reporting feature,
                which will be saved to the file in an XML format\r
            'verbose': boolean value which sets the verbose mode to the output in the terminal. Default is 'on'
            'element-type': Set the name of the required type of the top-level element of the document to be validated.
                The string should be in clark notation {uri}local\r
            'lax': Boolean to set the validation mode to strict (False) or lax ('True')
        """
        cdef const char * c_name = NULL
        '''make_c_str(name)'''

        if encoding is None:
            encoding = sys.getdefaultencoding()

        py_name_string = name.encode(encoding) if name is not None else None
        c_name = py_name_string if name is not None else ""

        cdef const char * c_value = NULL
        '''make_c_str(value)'''
        py_value_string = value.encode(encoding) if value is not None else None
        c_value = py_value_string if value is not None else ""
        if c_name is not NULL:
            if c_value is not NULL:
                self.thissvptr.setProperty(c_name, c_value)
     def clear_parameters(self):
        """
        clear_parameter(self)
        Clear all parameters set on the processor
        """
        self.thissvptr.clearParameters()
     def clear_properties(self):
        """
        clear_properties(self)
        Clear all properties set on the processor
        """
        self.thissvptr.clearProperties()

     @property
     def exception_occurred(self):
        """
        exception_occurred(self)
        Property to check if an exception has occurred internally within SaxonC
        Returns:
            boolean: True if an exception has been reported; otherwise False
        """
        return self.thissvptr.exceptionOccurred()

     def exception_clear(self):
        """
        exception_clear(self)
        Clear any exception thrown
        """
        self.thissvptr.exceptionClear()

     def get_error_message(self):
        """
        get_error_message(self)
        A validation may have a number of errors reported against it. Get the error message if there
        are any errors.
        Args:
        Returns:
            str: The message of the exception. Returns None if the exception does not exist.
        """
        return make_py_str(self.thissvptr.getErrorMessage())
     def get_error_code(self):
        """
        get_error_code(self)
        A validation may have a number of errors reported against it. Get the error code if there was an error.
        Args:
        Returns:
            str: The error code associated with the exception thrown. Returns None if the exception does not exist.
        """
        return make_py_str(self.thissvptr.getErrorCode())
     def set_lax(self, lax):
        """
        set_lax(self, lax)
        The validation mode may be either strict or lax. The default is strict; this method may be called to
        indicate that lax validation is required. With strict validation, validation fails if no element
        declaration can be located for the outermost element. With lax validation, the absence of an element
        declaration results in the content being considered valid.
        Args:
            lax (bool): True if validation is to be lax, False if it is to be strict
        """
        self.thissvptr.setLax(lax)
cdef class PyXdmValue:
     """A PyXdmValue represents a value in the XDM data model. A value is a sequence of zero or more items, each
     item being an atomic value, a node, or a function item. """
     cdef saxoncClasses.XdmValue *thisvptr      # hold a C++ instance which we're wrapping


     def __cinit__(self):
        """
        __cinit__(self)
        Constructor for PyXdmValue
        """
        if type(self) is PyXdmValue:
            self.thisvptr = new saxoncClasses.XdmValue()


     def __dealloc__(self):
        if type(self) is PyXdmValue and self.thisvptr != NULL:
            if self.thisvptr.getRefCount() < 1:
                del self.thisvptr
                self.thisvptr = NULL
            else:
                self.thisvptr.decrementRefCount()

     def add_xdm_item(self, PyXdmItem value):
        """
        add_xdm_item(self, PyXdmItem value)
        Add an item to the XDM sequence
        Args:
            value (PyXdmItem): The PyXdmItem object to add to the sequence
        """
        if value is not None:
            self.thisvptr.addXdmItem(value.derivedptr)
            value.derivedptr.incrementRefCount()

     @property
     def head(self):
        """
        head(self)
        Property to get the first item in the sequence
        Returns:
            PyXdmItem: The first item or None if the sequence is empty
        """

        cdef saxoncClasses.XdmItem * xdmItem = NULL
        xdmItem = self.thisvptr.getHead()

        if xdmItem is NULL:
            return None

        cdef PyXdmItem val = PyXdmItem()
        cdef type_ = xdmItem.getType()
        if type_== XdmType.XDM_ATOMIC_VALUE:
            aval = PyXdmAtomicValue()
            xdmItem.incrementRefCount()
            aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmItem
            return aval
        elif type_ == XdmType.XDM_NODE:
            nval = PyXdmNode()
            xdmItem.incrementRefCount()
            nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmItem
            return nval
        elif type_ == XdmType.XDM_FUNCTION_ITEM:
             fval = PyXdmFunctionItem()
             fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmItem
             fval.thisvptr.incrementRefCount()
             return fval
        elif type_ == XdmType.XDM_MAP:
             mval = PyXdmMap()
             mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmItem
             mval.thisvptr.incrementRefCount()
             return mval
        elif type_ == XdmType.XDM_ARRAY:
             aaval = PyXdmArray()
             aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmItem
             aaval.thisvptr.incrementRefCount()
             return aaval
        else:
            val = PyXdmItem()
            val.derivedptr = val.thisvptr = xdmItem
            val.derivedptr.incrementRefCount()
            return val

     def item_at(self, index):
        """
        item_at(self, index)
        Get the n'th item in the sequence, counting from zero.
        Args:
            index (int): the index of the item required, counting from zero
        Returns:
            PyXdmItem: The item at the specified index. This could be a PyXdmItem or any of its subclasses:
            PyXdmAtomicValue, PyXdmNode, PyXdmFunctionItem, PyXdmMap or PyXdmArray.
            If the item does not exist returns None.

        """
        cdef PyXdmValue val = None
        cdef PyXdmAtomicValue aval = None
        cdef PyXdmNode nval = None
        cdef PyXdmItem ival = None
        cdef type_ = None
        cdef saxoncClasses.XdmItem * xdmItem = NULL
        xdmItem = self.thisvptr.itemAt(index)
        if xdmItem == NULL:
            return None
        else :
            type_ = xdmItem.getType()
            xdmItem.incrementRefCount()
            if type_== XdmType.XDM_ATOMIC_VALUE:
                aval = PyXdmAtomicValue()
                aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>xdmItem
                return aval
            elif type_ == XdmType.XDM_NODE:
                nval = PyXdmNode()
                nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>xdmItem
                return nval
            elif type_ == XdmType.XDM_FUNCTION_ITEM:
                fval = PyXdmFunctionItem()
                fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>xdmItem
                fval.thisvptr.incrementRefCount()
                return fval
            elif type_ == XdmType.XDM_MAP:
                mval = PyXdmMap()
                mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>xdmItem
                mval.thisvptr.incrementRefCount()
                return mval
            elif type_ == XdmType.XDM_ARRAY:
                aaval = PyXdmArray()
                aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>xdmItem
                aaval.thisvptr.incrementRefCount()
                return aaval
            elif type_ == XdmType.XDM_EMPTY:
                return None
            else:
                ival = PyXdmItem()
                ival.thisvptr = xdmItem
                return ival
     @property
     def size(self):
        """
        size(self)
        Get the number of items in the sequence
        Returns:
            int: The count of items in the sequence
        """
        return self.thisvptr.size()
     def __repr__(self):
        """
        __repr__(self)
        The string representation of PyXdmItem
        """
        cdef const char* c_string = NULL
        c_string = self.thisvptr.toString()
        if c_string == NULL:
            raise Warning('Empty string returned')
        else:
            py_to_string = make_py_str(c_string)
            saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_to_string


     def __getitem__(self, index):
         """
         __getitem__(self, index)
         Implement the built-in subscript operator (i.e. square brackets []) to return the ith item in the sequence

         Returns:
            PyXdmItem: The item at the specified index. This could be a PyXdmItem or any of its subclasses:
            PyXdmAtomicValue, PyXdmNode, PyXdmFunctionItem, PyXdmMap or PyXdmArray.
            If the item does not exist returns None.
         """
         return self.item_at(index)


     def __str__(self):
        """
        __str__(self)
        The string representation of PyXdmItem
        """
        cdef const char* c_string = NULL
        c_string = self.thisvptr.toString()
        py_to_string = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_to_string

     def __iter__(self):
        """
        __iter__(self)
        Returns the Iterator object of PyXdmValue
        """
        return PyXdmValueIterator(self)
cdef class PyXdmValueIterator:
     """ Iterator class for PyXdmValue """
     cdef PyXdmValue _value
     cdef _index
     def __init__(self, value):
     # PyXdmValue object reference
        self._value = value
        # member variable to keep track of current index
        self._index = 0

     def __iter__(self):
         return self

     def __next__(self):
       """Returns the next value from PyXdmValue object's lists """
       if self._index < self._value.size :
           result = self._value.item_at(self._index)
           self._index +=1
           return result
       # End of Iteration
       raise StopIteration



cdef class PyXdmItem(PyXdmValue):
     """The class PyXdmItem represents an item in a sequence, as defined by the XDM data model.
     An item is either an atomic value, a node, or a function item."""
     cdef saxoncClasses.XdmItem *derivedptr      # hold a C++ instance which we're wrapping


     def __cinit__(self):
        """
         __cinit__(self)
         Constructor for PyXdmItem
        """
        if type(self) is PyXdmItem:
            self.derivedptr = self.thisvptr = new saxoncClasses.XdmItem()

     def __dealloc__(self):
        if type(self) is PyXdmItem and self.derivedptr != NULL:
            if self.derivedptr.getRefCount() < 1:
                del self.derivedptr
                self.derivedptr = self.thisvptr = NULL
            else:
                self.derivedptr.decrementRefCount()

        '''if type(self) is PyXdmItem:
            del self.derivedptr'''
     @property
     def string_value(self):
        """
        string_value(self)
        Property to get the string value of the PyXdmItem
        """
        cdef const char* c_string = NULL
        c_string = self.derivedptr.getStringValue()
        py_item_string_value = make_py_str(c_string)
        return py_item_string_value

     def get_string_value(self, encoding=None):
        """
        get_string_value(self, encoding=None)
        Property to get the string value of the item as defined in the XPath data model
        Args:
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: The string value of this node
        """
        cdef const char* c_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        c_string = self.derivedptr.getStringValue()
        py_item_string_value = make_py_str(c_string, encoding)
        return py_item_string_value

     def __repr__(self):
        c_string =  self.derivedptr.toString()
        py_item_to_string = make_py_str(c_string)
        return py_item_to_string

     def __str__(self):
        cdef const char* c_string = NULL
        c_string = self.derivedptr.toString()
        py_item_to_string = make_py_str(c_string)
        return py_item_to_string

     @property
     def is_atomic(self):
        """
        is_atomic(self)
        Property to check if the current PyXdmItem is an atomic value
        Returns:
            bool: True if the current item is an atomic value
        """
        return self.derivedptr.isAtomic()

     @property
     def is_node(self):
        """
        is_node(self)
        Property to check if the current PyXdmItem is a node
        Returns:
            bool: True if the current item is a node
        """
        return self.derivedptr.isNode()

     @property
     def is_function(self):
        """
        is_function(self)
        Property to check if the current PyXdmItem is a function item
        Returns:
            bool: True if the current item is a function item
        """
        return self.derivedptr.isFunction()

     @property
     def is_map(self):
        """
        is_map(self)
        Property to check if the current PyXdmItem is a map item
        Returns:
            bool: True if the current item is a map item
        """
        return self.derivedptr.isMap()

     @property
     def is_array(self):
        """
        is_array(self)
        Property to check if the current PyXdmItem is an array item
        Returns:
            bool: True if the current item is an array item
        """
        return self.derivedptr.isArray()

     def get_node_value(self):
        """
        get_node_value(self)
        Get the subclass PyXdmNode for this current PyXdmItem object if it is a node
        Returns:
            PyXdmNode: Subclass this object to PyXdmNode or error
        """
        cdef PyXdmNode val = None
        if self.is_node == False:
          raise Exception("The PyXdmItem is not a PyXdmNode therefore cannot be sub-classed to a PyXdmNode")
        val = PyXdmNode()
        val.derivednptr = val.derivedptr = <saxoncClasses.XdmNode*> self.derivedptr
        val.derivednptr.incrementRefCount()
        return val

     def get_map_value(self):
        """
        get_map_value(self)
        Get the subclass PyXdmMap for this current PyXdmItem object if it is a map item
        Returns:
            PyXdmNode: Subclass this object to PyXdmMap or error
        """
        cdef PyXdmMap val = None
        if self.is_map == False:
          raise Exception("The PyXdmItem is not a PyXdmMap therefore cannot be sub-classed to a PyXdmMap")
        val = PyXdmMap()
        val.derivedmmptr = val.derivedfptr = val.derivedptr = <saxoncClasses.XdmMap*> self.derivedptr
        val.derivednptr.incrementRefCount()
        return val

     def get_function_value(self):
        """
        get_function_value(self)
        Get the subclass PyXdmFunctionItem for this current PyXdmItem object if it is a function item
        Returns:
            PyXdmFunctionItem: Subclass this object to PyXdmFunctionItem or error
        """
        cdef PyXdmFunctionItem val = None
        if self.is_function == False:
          raise Exception("The PyXdmItem is not a PyXdmFunctionItem therefore cannot be sub-classed to a PyXdmFunctionItem")
        val = PyXdmFunctionItem()
        val.derivedfptr = val.derivedptr = <saxoncClasses.XdmFunctionItem*> self.derivedptr
        val.derivednptr.incrementRefCount()
        return val

     def get_array_value(self):
        """
        get_array_value(self)
        Get the subclass PyXdmArray for this current PyXdmItem object if it is an array item
        Returns:
            PyXdmArray: Subclass this object to PyXdmArray or error
        """
        cdef PyXdmArray val = None
        if self.is_array == False:
          raise Exception("The PyXdmItem is not a PyXdmArray therefore cannot be sub-classed to a PyXdmArray")
        val = PyXdmArray()
        val.derivedaaptr = val.derivedfptr = val.derivedptr = <saxoncClasses.XdmArray*> self.derivedptr
        val.derivednptr.incrementRefCount()
        return val

     @property
     def head(self):
        """
        head(self)
        Property to get the first item in the sequence represented by this PyXdmItem. Since a PyXdmItem is a sequence
        of length one, this returns the PyXdmItem itself.
        Returns:
            PyXdmItem: The PyXdmItem or None if the sequence is empty
        """
        return self
     def get_atomic_value(self):
        """
        get_atomic_value(self)
        Get the subclass PyXdmAtomicValue for this current PyXdmItem object if it is an atomic value
        Returns:
            PyXdmAtomicValue: Subclass this object to PyXdmAtomicValue or error
        """
        if self.is_atomic == False:
          raise Exception("The PyXdmItem is not a PyXdmAtomicValue")
        val = PyXdmAtomicValue()
        val.derivedaptr = val.derivedptr = <saxoncClasses.XdmAtomicValue*>self.derivedptr
        val.derivedaptr.incrementRefCount()
        return val
cdef class PyXdmNode(PyXdmItem):
     """This class represents a node in the XDM data model. A PyXdmNode is a PyXdmItem, and is therefore a
     PyXdmValue in its own right, and may also participate as one item within a sequence value.
     The PyXdmNode interface exposes basic properties of the node, such as its name, its string value, and
     its typed value.
     """
     cdef saxoncClasses.XdmNode *derivednptr      # hold a C++ instance which we're wrapping

     def __cinit__(self):
        """
         __cinit__(self)
         Constructor for PyXdmNode
        """
        self.derivednptr = self.derivedptr = self.thisvptr = NULL

     def __dealloc__(self):
        if type(self) is PyXdmNode and self.derivednptr != NULL:
                 if self.derivednptr.getRefCount() < 1:
                     del self.derivednptr
                     self.derivednptr = self.derivedptr = self.thisvptr = NULL
                 else:
                     self.derivednptr.decrementRefCount()

     @property
     def head(self):
        """
        head(self)
        Property to get the first item in the sequence represented by this PyXdmNode. Since a PyXdmItem is a sequence
        of length one, this returns the PyXdmNode itself.
        Returns:
            PyXdmNode: The PyXdmNode or None if the sequence is empty
        """
        return self

     @property
     def node_kind(self):
        """
        node_kind(self)
        Node kind property. 
        There are seven kinds of node: documents=9, elements = 1, attributes =2, text=3, comments = 8,
        processing-instructions = 7, and namespaces=13.
        Returns:
            int: an integer identifying the kind of node. These integer values are the same as those used in the DOM
        """
        cdef int kind
        return self.derivednptr.getNodeKind()
     @property
     def node_kind_str(self):
        """
        node_kind_str(self)
        Node kind property string. Returns one of the following: 'document', 'element', 'attribute', 'text', 'comment',
        'processing-instruction', 'namespace', 'unknown'.
        Returns:
            str: a string identifying the kind of node.
        """
        cdef str kind
        cdef int nk = self.derivednptr.getNodeKind()
        if nk == 9:
            return 'document'
        elif nk == 1:
            return 'element'
        elif nk == 2:
            return 'attribute'
        elif nk == 3:
            return 'text'
        elif nk == 8:
            return 'comment'
        elif nk == 7:
            return 'processing-instruction'
        elif nk == 13:
            return 'namespace'
        elif nk == 0:
            return 'unknown'
        else:
            raise ValueError('Unknown node kind: %d' % nk)

     @property
     def name(self):
        """
        name(self)
        Get the name of the node, as a string in the form of an EQName
        Returns:
            str: the name of the node. In the case of unnamed nodes (e.g. text and comment nodes) returns None
        """
        cdef const char* c_string = self.derivednptr.getNodeName()
        if c_string == NULL:
            return None
        else:
            py_string_i = make_py_str(c_string)
            return py_string_i

     @property
     def local_name(self):
        """
        local_name(self)
        Get the local name of the node, as a string
        Returns:
            str: the local name of the node. In the case of unnamed nodes (e.g. text and comment nodes) returns None
        """
        cdef const char* c_string = self.derivednptr.getLocalName()
        if c_string == NULL:
            return None
        else:
            py_string_i = make_py_str(c_string)
            return py_string_i

     @property
     def typed_value(self):
        """
        typed_value(self)
        Get the typed value of this node, as defined in the XPath data model
        Returns:
            PyXdmValue: the typed value. If the typed value is a single atomic value, this will be returned
            as an instance of PyXdmAtomicValue
        """
        cdef PyXdmValue val = None
        cdef saxoncClasses.XdmValue * xdmValue = self.derivednptr.getTypedValue()
        if xdmValue == NULL:
            return None
        else:
            val = PyXdmValue()
            val.thisvptr = xdmValue
            return val

     @property
     def base_uri(self):
        """
        base_uri(self)
        Base URI property. Get the Base URI for the node, that is, the URI used for resolving a relative URI
        contained in the node. This will be the same as the System ID unless xml:base has been used. Where the
        node does not have a base URI of its own, the base URI of its parent node is returned.
        Returns:
            str: String value of the base uri for this node. This may be NULL if the base URI is unknown,
                including the case where the node has no parent.
        """
        cdef const char* c_string = self.derivednptr.getBaseUri()
        py_string_i = make_py_str(c_string)
        return py_string_i

     @property
     def string_value(self):
        """
        string_value(self)
        Property to get the string value of the node as defined in the XPath data model
        Returns:
            str: The string value of this node
        """
        cdef const char* c_string = NULL
        c_string = self.derivednptr.getStringValue()
        py_node_string_value = make_py_str(c_string)
        return py_node_string_value

     def get_string_value(self, encoding=None):
        """
        get_string_value(self, encoding=None)
        Property to get the string value of the node as defined in the XPath data model
        Args:
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: The string value of this node
        """
        cdef const char* c_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        c_string = self.derivednptr.getStringValue()
        py_node_string_value = make_py_str(c_string, encoding)
        return py_node_string_value

     def __str__(self):
        """
        __str__(self)
        The string value of the node as returned by the toString method
        Returns:
            str: String value of this node
        """
        cdef const char* c_string = NULL
        c_string = self.derivednptr.toString()
        py_node_to_string = make_py_str(c_string)
        return py_node_to_string

     def to_string(self, encoding=None):
        """
        to_string(self, encoding=None)
        The string value of the node as returned by the toString method
        Args:
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: String value of this node
        """
        cdef const char* c_string = NULL
        c_string = self.derivednptr.toString()
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_node_to_string = make_py_str(c_string, encoding)
        return py_node_to_string

     def __getitem__(self, index):
        """
        __getitem__(self, index)
        Implement the built-in subscript operator (i.e. square brackets []) to return the ith child node of the current node

        Returns:
            PyXdmNode: The child node at the specified index.
            If the child node at the index does not exist returns None.
        """
        cdef PyXdmNode val = None
        cdef bool cache = False
        cdef saxoncClasses.XdmNode * node = NULL
        node =  self.derivednptr.getChild(index, cache)
        if node == NULL:
            return None
        else :
            val = PyXdmNode()
            val.derivednptr = val.derivedptr = val.thisvptr = node
            node.incrementRefCount()
            return val

     def __len__(self):
        """
        __len__(self)
        Implement the built-in function len() to return the count of child nodes from this current node.

        Returns:
            int: The count of child nodes
        """
        return self.derivednptr.getChildCount()

     def __repr__(self):
        """
        ___repr__(self)
        """
        cdef const char* c_string = NULL
        c_string = self.derivednptr.toString()
        py_node_to_string = make_py_str(c_string)
        return py_node_to_string

     def get_parent(self):
        """
        get_parent(self)
        Get the current node's parent. If it does not exist return None.
        Returns:
            PyXdmNode: The parent node as a PyXdmNode object, or otherwise None
        """
        cdef PyXdmNode val = None
        cdef saxoncClasses.XdmNode * node = NULL
        node = self.derivednptr.getParent()
        if node == NULL:
            return None
        else :
            val = PyXdmNode()
            val.derivednptr = val.derivedptr = val.thisvptr = node
            node.incrementRefCount()
            return val

     def get_attribute_value(self, name, encoding=None):
        """
        get_attribute_value(self, name, encoding=None)
        Get the value of a named attribute
        Args:
            name (str): the EQName of the required attribute
            encoding (str): The encoding of the name argument. Argument can be omitted or None.
                If not specified then the platform default encoding is used.
        """
        if encoding is None:
            encoding = sys.getdefaultencoding()
        py_value_string = name.encode(encoding) if name is not None else None
        cdef char * c_name = py_value_string if name is not None else ""

        cdef const char* c_string = self.derivednptr.getAttributeValue(c_name)
        if c_string == NULL:
            return None
        py_string_i = make_py_str(c_string, encoding)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     """@property
     def ref_count(self):
        return self.derivednptr.getRefCount()"""

     @property
     def attribute_count(self):
        """
        attribute_count(self)
        Get the number of attribute nodes on this node. If the node is not an element node then returns 0.
        Returns:
            int: The number of attribute nodes
        """
        return self.derivednptr.getAttributeCount()
     @property
     def attributes(self):
        """
        attribute_nodes(self)
        Get the attribute nodes of this node as a list of PyXdmNode objects
        Returns:
            list[PyXdmNode]: List of PyXdmNode objects
        """
        cdef list nodes = []
        cdef saxoncClasses.XdmNode **n
        cdef int count, i
        cdef PyXdmNode val = None
        count = self.derivednptr.getAttributeCount()
        if count > 0:
            n = self.derivednptr.getAttributeNodes()
            for i in range(count):
                val = PyXdmNode()
                val.derivednptr = val.derivedptr = val.thisvptr = n[i]
                val.derivednptr.incrementRefCount()
                nodes.append(val)
        return nodes

     def axis_nodes(self, int axis):
        """
        axis_nodes(self, int axis)
        Get the array of nodes reachable from this node via a given axis.
        Deprecated the argument type for axis will change from Saxon 13 to use the XdmNodeKind enum type
        Axis options are as follows: ANCESTOR = 0,
        ANCESTOR_OR_SELF = 1, ATTRIBUTE = 2, CHILD = 3,
        DESCENDANT  = 4, DESCENDANT_OR_SELF = 5, FOLLOWING = 6,
        FOLLOWING_SIBLING = 7, NAMESPACE = 8, PARENT = 9, PRECEDING = 10,
        PRECEDING_SIBLING = 11, SELF = 12
        Args:
            axis (int): Identifies which axis is to be navigated.
        Returns:
            list[PyXdmNode]: List of PyXdmNode objects
        """
        cdef list nodes = []
        cdef saxoncClasses.XdmNode **n
        cdef int count, i
        cdef PyXdmNode val = None
        n = self.derivednptr.axisNodes(self.derivednptr.convertEnumXdmAxis(axis))
        count = self.derivednptr.axisNodeCount()
        if count > 0:
            for i in range(count):
                val = PyXdmNode()
                val.derivednptr = val.derivedptr = val.thisvptr = n[i]
                val.derivednptr.incrementRefCount()
                nodes.append(val)
        return nodes

     @property
     def children(self):
        """
        children(self)
        Get the children of this node as a list of PyXdmNode objects
        Returns:
            list[PyXdmNode]: List of PyXdmNode objects
        """
        cdef list nodes = []
        cdef saxoncClasses.XdmNode **n
        cdef int count, i
        cdef PyXdmNode val = None
        count = self.derivednptr.getChildCount()
        if count > 0:
            n = self.derivednptr.getChildren()
            for i in range(count):
                val = PyXdmNode()
                val.derivednptr = val.derivedptr = val.thisvptr = n[i]
                val.derivednptr.incrementRefCount()
                nodes.append(val)
        return nodes
      # def getChildCount(self):

cdef class PyXdmAtomicValue(PyXdmItem):
     """
     The class PyXdmAtomicValue represents an item in an XPath sequence that is an atomic value. The value may
     belong to any of the 19 primitive types defined in XML Schema, or to a type derived from these primitive
     types, or the XPath type xs:untypedAtomic.
     """
     cdef saxoncClasses.XdmAtomicValue *derivedaptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        if type(self) is PyXdmAtomicValue:
            self.derivedaptr = self.derivedptr = self.thisvptr = new saxoncClasses.XdmAtomicValue()
     def __dealloc__(self):
        if type(self) is PyXdmAtomicValue and self.derivedaptr != NULL:
            if self.derivedaptr.getRefCount() < 1:
                del self.derivedaptr
            else:
                self.derivedaptr.decrementRefCount()


     @property
     def primitive_type_name(self):
        """
        primitive_type_name(self)
        Get the primitive type name of the PyXdmAtomicValue
        Returns:
            str: String of the primitive type name
        """
        ustring = make_py_str(self.derivedaptr.getPrimitiveTypeName())
        return ustring
     @property
     def boolean_value(self):
        """
        boolean_value(self)
        Get the boolean value of the PyXdmAtomicValue, converted using the XPath casting rules
        Returns:
            bool: the result of converting to a boolean
        """
        return self.derivedaptr.getBooleanValue()
     @property
     def double_value(self):
        """
        double_value(self)
        Get the double value of the PyXdmAtomicValue, converted using the XPath casting rules
        Returns:
            double: the result of converting to a double
        """

        return self.derivedaptr.getDoubleValue()
     @property
     def head(self):
        """
        head(self)
        Property to get the first item in the sequence represented by this PyXdmAtomicValue. Since a PyXdmItem
        is a sequence of length one, this returns the PyXdmAtomicValue itself.
        Returns:
            PyXdmAtomicValue: The PyXdmAtomicValue or None if the sequence is empty
        """
        return self

     @property
     def integer_value(self):
        """
        integer_value(self)
        Get the integer value of the PyXdmAtomicValue, converted using the XPath casting rules
        Returns:
            int: the result of converting to an integer
        """

        return self.derivedaptr.getLongValue()
     @property
     def string_value(self):
        """
        string_value(self)
        Get the string value of the PyXdmAtomicValue, converted using the XPath casting rules
        Returns:
            str: the result of converting to a string
        """
        ustring = make_py_str(self.derivedaptr.getStringValue())
        return ustring

     def get_string_value(self, encoding=None):
        """
        get_string_value(self, encoding=None)
        Property to get the string value of the atomic value as defined in the XPath data model
        Args:
            encoding (str): The encoding of the string. If not specified then the platform default encoding is used.
        Returns:
            str: The string value of this node
        """
        cdef const char* c_string = NULL
        if encoding is None:
            encoding = sys.getdefaultencoding()
        c_string = self.derivedaptr.getStringValue()
        py_item_string_value = make_py_str(c_string, encoding)
        return py_item_string_value


     def __int__(self):

         return self.integer_value



     def __str__(self):
        """
        __str__(self)
        The string value of the node as returned by the toString method
        Returns:
            str: String value of this node
        """
        cdef const char * c_string = self.derivedaptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def __repr__(self):
        """
        ___repr__(self)
        """
        cdef const char * c_string = self.derivedaptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def __hash__(self):
        return self.derivedaptr.getHashCode()

     def __eq__(self, other):
         if isinstance(other, int):
             return  self.integer_value == other
         elif  isinstance(other, float):
             return self.double_value == other
         elif  isinstance(other, str):
             return (self.string_value) == (other.string_value)
         elif  other  in (True, False):
             return self.boolean_value == other
         return False

     def __ne__(self, other):
        # Not strictly necessary, but to avoid having both x==y and x!=y
        # True at the same time
        return not(self == other)

cdef class PyXdmFunctionItem(PyXdmItem):
     """
     The class PyXdmFunctionItem represents a function item
     """
     cdef saxoncClasses.XdmFunctionItem *derivedfptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        if type(self) is PyXdmAtomicValue:
            self.derivedfptr = self.derivedptr = self.thisvptr = new saxoncClasses.XdmFunctionItem()
     def __dealloc__(self):
        if type(self) is PyXdmFunctionItem and self.derivedfptr != NULL:
            if self.derivedfptr.getRefCount() < 1:
                del self.derivedfptr
            else:
                self.derivedfptr.decrementRefCount()


     @property
     def name(self):
         """
         name(self)
         Get the name of the function
         Returns:
             str: The name of the function as an EQName
         """
         cdef const char * c_string = self.derivedfptr.getName()
         py_string_i = make_py_str(c_string)
         return py_string_i

     @property
     def arity(self):
         """
         arity(self)
         Get the arity of the function
         Returns:
             int: The arity of the function, that is, the number of arguments in the function's signature
         """
         return self.derivedfptr.getArity()

     def __repr__(self):
        cdef const char * c_string = self.derivedfptr.toString()
        try:
            py_string_i = make_py_str(c_string)
        finally:
            saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def __str__(self):
        cdef const char * c_string = self.derivedfptr.toString()
        try:
            py_string_i = make_py_str(c_string)
        finally:
            saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     @property
     def string_value(self):
        """
        string_value(self)
        Property to get the string value of the PyXdmFunctionItem
        Returns:
            str: String value of the function item
        """
        cdef const char * c_string = self.derivedfptr.getStringValue()
        py_string_i = make_py_str(c_string)
        return py_string_i


     def get_system_function(self, PySaxonProcessor proc, str name, arity, encoding=None):
         """
         get_system_function(self, PySaxonProcessor proc, str name, arity, encoding=None)
         Get a system function. This can be any function defined in XPath 3.1 functions and operators,
         including functions in the math, map, and array namespaces. It can also be a Saxon extension
         function, provided a licensed Processor is used.
         Args:
             proc (PySaxonProcessor): the Saxon processor
             name (str): the name of the requested function as an EQName or clark name
             arity (int): the arity of the requested function
             encoding (str): the encoding of the name string. If not specified then the platform default encoding is used.
         Returns:
             PyXdmFunctionItem: the requested function
         """
         cdef char * c_str = NULL
         cdef PyXdmFunctionItem func = None
         cdef saxoncClasses.XdmFunctionItem * c_func = NULL
         if proc is None:
             return None
         if encoding is None:
            encoding = sys.getdefaultencoding()
         py_name_string = name.encode(encoding) if name is not None else None
         c_name = py_name_string if name is not None else ""
         c_func = self.derivedfptr.getSystemFunction(proc.thisptr, c_name, arity)
         if c_func is NULL:
             return None
         func = PyXdmFunctionItem()
         func.derivedfptr = self.derivedptr = self.thisvptr = c_func
         return func


     def call(self, PySaxonProcessor proc, list args):
         """
         call(self, PySaxonProcessor proc, list args)
         Call the function
         Args:
             proc (PySaxonProcessor): the Saxon processor
             args (list): the values to be supplied as arguments to the function. The "function
                conversion rules" will be applied to convert the arguments to the required
                type when necessary.
         Returns:
             PyXdmValue: the result of calling the function
         """
         cdef int _len = len(args)
         cdef saxoncClasses.XdmValue ** argumentV = self.derivedfptr.createXdmValueArray(_len)
         cdef PyXdmValue ivalue_
         for x in range(_len):
           if isinstance(args[x], PyXdmValue):
             ivalue_ = args[x]
             argumentV[x] = ivalue_.thisvptr
             ivalue_.thisvptr.incrementRefCount()
           else:
             raise Exception("Argument value at position ",x," is not a PyXdmValue")
         '''c_functionName = make_c_str(function_name)'''
         cdef saxoncClasses.XdmValue * c_xdmValue = NULL
         cdef PyXdmAtomicValue avalue_
         cdef PyXdmValue value_
         cdef PyXdmAtomicValue aval = None
         cdef PyXdmNode nval = None
         cdef PyXdmFunctionItem fval = None
         cdef PyXdmMap mval = None
         cdef PyXdmArray aaval = None
         c_xdmValue = self.derivedfptr.call(proc.thisptr, argumentV, _len)
         if _len > 0:
             proc.thisptr.deleteXdmValueArray(argumentV, _len)
         if c_xdmValue == NULL:
             return None
         type_ = c_xdmValue.getType()
         if type_== XdmType.XDM_VALUE:
              value_ = PyXdmValue()
              value_.thisvptr = c_xdmValue
              value_.thisvptr.incrementRefCount()
              return value_
         if type_== XdmType.XDM_ATOMIC_VALUE:
              aval = PyXdmAtomicValue()
              aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>c_xdmValue
              aval.thisvptr.incrementRefCount()
              return aval
         elif type_ == XdmType.XDM_NODE:
              nval = PyXdmNode()
              nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>c_xdmValue
              nval.thisvptr.incrementRefCount()
              return nval
         elif type_ == XdmType.XDM_FUNCTION_ITEM:
              fval = PyXdmFunctionItem()
              fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>c_xdmValue
              fval.thisvptr.incrementRefCount()
              return fval
         elif type_ == XdmType.XDM_MAP:
              mval = PyXdmMap()
              mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>c_xdmValue
              mval.thisvptr.incrementRefCount()
              return mval
         elif type_ == XdmType.XDM_ARRAY:
              aaval = PyXdmArray()
              aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>c_xdmValue
              aaval.thisvptr.incrementRefCount()
              return aaval
         else:
              return None

cdef class PyXdmMap(PyXdmFunctionItem):
     """
     The class PyXdmMap represents a map item in the XDM data model. A map is a list of zero or more entries, each of
     which is a pair comprising a key (which is an atomic value) and a value (which is an arbitrary value).
     The map itself is an XDM item. A PyXdmMap is immutable.
     """
     cdef saxoncClasses.XdmMap *derivedmmptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        """
         __cinit__(self)
         Constructor for PyXdmMap
        """
        if type(self) is PyXdmMap:
            self.derivedmmptr = self.derivedfptr = self.derivedptr = self.thisvptr = new saxoncClasses.XdmMap()
     def __dealloc__(self):
        if type(self) is PyXdmMap and self.derivedfptr != NULL:
            if self.derivedfptr.getRefCount() < 1:
                del self.derivedfptr
                self.derivedmmptr = self.derivedfptr = self.derivedptr = self.thisvptr = NULL
            else:
                self.derivedfptr.decrementRefCount()



     def __repr__(self):
        cdef const char * c_string = self.derivedmmptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i


     def __str__(self):
        cdef const char * c_string = self.derivedmmptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     @property
     def map_size(self):
         """
         map_size(self)
         Get the number of entries in the map
         Returns:
             int: the number of entries in the map. (Note that the size() method returns 1 (one), because an XDM
             map is an item.)
         """
         return self.derivedmmptr.mapSize()

     def get(self, key, encoding=None):
         """
         get(self, key, encoding=None)
         Returns the value to which the specified key is mapped, or NULL if this map contains no mapping for the key.
         All keys in the PyXdmMap are of type PyXdmAtomicValue, but for convenience, this method also accepts keys of
         primitive type (str, int and float), which will be converted to PyXdmAtomicValue internally.
         Args:
             key: the key whose associated value is to be returned. The key supports the following types:
                PyXdmAtomicValue, str, int and float
             encoding (str): The encoding of the key, if supplied as a string. If not specified then the platform
                default encoding is used.
         Returns:
             PyXdmValue: the value to which the specified key is mapped, or NULL if this map contains no
             mapping for the key
         """
         cdef saxoncClasses.XdmValue * c_xdmValue = NULL
         cdef PyXdmAtomicValue avalue_
         cdef PyXdmValue value_
         cdef PyXdmAtomicValue aval = None
         cdef PyXdmNode nval = None
         cdef PyXdmFunctionItem fval = None
         cdef PyXdmMap mval = None
         cdef PyXdmArray aaval = None
         cdef int i_key
         cdef float k_key
         cdef str keyStr
         cdef type_ = 0
         cdef char * c_key_str = NULL

         if isinstance(key, PyXdmAtomicValue):
             avalue_ = key
             c_xdmValue = self.derivedmmptr.get(avalue_.derivedaptr)

         elif  isinstance(key, str):
             keyStr = key
             if encoding is None:
                 encoding = sys.getdefaultencoding()
             py_value_string = keyStr.encode(encoding) if keyStr is not None else None
             c_key_str = py_value_string if keyStr is not None else ""
             c_xdmValue = self.derivedmmptr.get(c_key_str)

         elif  isinstance(key, int):
             i_key = key
             c_xdmValue = self.derivedmmptr.get(i_key)

         elif isinstance(key, float):
             k_key = key
             c_xdmValue = self.derivedmmptr.get(k_key)
         else:
             return None

         if c_xdmValue is NULL:
             return None
         else:


             type_ = c_xdmValue.getType()
             if type_== XdmType.XDM_VALUE:
                 value_ = PyXdmValue()
                 value_.thisvptr = c_xdmValue
                 value_.thisvptr.incrementRefCount()
                 return value_
             if type_== XdmType.XDM_ATOMIC_VALUE:
                 aval = PyXdmAtomicValue()
                 aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>c_xdmValue
                 aval.thisvptr.incrementRefCount()
                 return aval
             elif type_ == XdmType.XDM_NODE:
                 nval = PyXdmNode()
                 nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>c_xdmValue
                 nval.thisvptr.incrementRefCount()
                 return nval
             elif type_ == XdmType.XDM_FUNCTION_ITEM:
                 fval = PyXdmFunctionItem()
                 fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>c_xdmValue
                 fval.thisvptr.incrementRefCount()
                 return fval
             elif type_ == XdmType.XDM_MAP:
                 mval = PyXdmMap()
                 mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>c_xdmValue
                 mval.thisvptr.incrementRefCount()
                 return mval
             elif type_ == XdmType.XDM_ARRAY:
                 aaval = PyXdmArray()
                 aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>c_xdmValue
                 aaval.thisvptr.incrementRefCount()
                 return aaval
             else:
                 return None

     def __iter__(self):
        """
        __iter__(self)
        Returns the Iterator object of PyXdmMap
        """
        return iter(self.keys())


     def put(self, PyXdmAtomicValue key, PyXdmValue value):
         """
         put(self, PyXdmAtomicValue key, PyXdmValue value)
         Create a new map containing an additional (key, value) pair. If there is an existing entry with
         the same key, it is replaced.
         Args:
             key (PyXdmAtomicValue): The key for the new map entry
             value (PyXdmValue): The value for the new map entry
         Returns:
             PyXdmMap: a new map containing the new entry. The original map is unchanged.
         """
         cdef PyXdmMap newmap_
         cdef saxoncClasses.XdmMap * c_xdmMap = NULL

         if key is None or value is None:
             return None

         c_xdmMap = self.derivedmmptr.put(key.derivedaptr, value.thisvptr)
         if c_xdmMap is NULL:
             return None
         newmap_ = PyXdmMap()
         newmap_.derivedmmptr = newmap_.derivedfptr = newmap_.derivedptr = newmap_.thisvptr = c_xdmMap
         return newmap_



     def remove(self, PyXdmAtomicValue key):
         """
         remove(self, PyXdmAtomicValue key)
         Create a new map in which the entry for a given key has been removed.
         Args:
             key (PyXdmAtomicValue): The key to be removed given as an PyXdmAtomicValue
         Returns:
             PyXdmMap: a map without the specified entry. The original map is unchanged.
         """
         cdef PyXdmMap newmap_
         cdef saxoncClasses.XdmMap * c_xdmMap = NULL

         if key is None:
             return None

         c_xdmMap = self.derivedmmptr.remove(key.derivedaptr)
         if c_xdmMap is NULL:
             return None
         newmap_ = PyXdmMap()
         newmap_.derivedmmptr = newmap_.derivedfptr = newmap_.derivedptr = newmap_.thisvptr = c_xdmMap
         return newmap_

     def keys(self):
         """
         keys(self)
         Get the keys in the PyXdmMap
         Returns:
             list[PyXdmAtomicValue]: List of PyXdmAtomicValue objects
         """
         """TODO: memory management for the array returned from C++"""
         cdef list p_values = []
         cdef saxoncClasses.XdmAtomicValue **c_values
         cdef PyXdmAtomicValue val = None
         cdef int count, i
         count = self.derivedmmptr.mapSize()
         if count > 0:
             c_values = self.derivedmmptr.keys()
             for i in range(count):
                 val = PyXdmAtomicValue()
                 val.derivedaptr = val.derivedptr = val.thisvptr = <saxoncClasses.XdmAtomicValue *>c_values[i]
                 val.thisvptr.incrementRefCount()
                 p_values.append(val)
         return p_values

     '''def map[string, XdmValue*]& asMap()'''

     @property
     def isEmpty(self):
         """
         isEmpty(self)
         Returns true if this map contains no key-value mappings.
         Returns:
             bool: true if this map contains no key-value mappings
         """
         self.derivedmmptr.isEmpty()

     def contains_key(self, PyXdmAtomicValue key):
         """
         contains_key(self, PyXdmAtomicValue key)
         Returns true if this map contains a mapping for the specified key.
         Args:
             key (PyXdmAtomicValue): key whose presence in this map is to be tested
         Returns:
             bool: true if this map contains a mapping for the specified key
         """
         if key is None:
             return None

         return self.derivedmmptr.containsKey(key.derivedaptr)

     @property
     def string_value(self):
        """
        string_value(self)
        Property to get the string value of the PyXdmMap
        Returns:
            str: String value of the map item
        """
        cdef const char * c_string = self.derivedmmptr.getStringValue()
        py_string_i = make_py_str(c_string)
        return py_string_i

     def values(self):
         """
         values(self)
         Get the values found in this map, that is, the value parts of the key-value pairs.
         Returns:
             list: List of the values found in this map.
         """
         """TODO: memory management for the array returned from C++"""
         cdef list p_values = []
         cdef saxoncClasses.XdmValue ** c_values
         cdef int count, i
         cdef PyXdmValue val = None
         cdef PyXdmAtomicValue aval = None
         cdef PyXdmNode nval = None
         cdef PyXdmFunctionItem fval = None
         cdef PyXdmMap mval = None
         cdef PyXdmArray aaval = None
         cdef type_ = 0
         count = self.derivedmmptr.mapSize()
         if count > 0:
             c_values = self.derivedmmptr.values()
             if c_values is NULL:
                 return None
             for i in range(count):

                 type_ = c_values[i].getType()
                 if type_== XdmType.XDM_VALUE:
                     val = PyXdmValue()
                     val.thisvptr = c_values[i]
                     val.thisvptr.incrementRefCount()
                     p_values.append(val)
                 if type_== XdmType.XDM_ATOMIC_VALUE:
                     aval = PyXdmAtomicValue()
                     aval.derivedaptr = aval.derivedptr = aval.thisvptr = <saxoncClasses.XdmAtomicValue *>c_values[i]
                     aval.thisvptr.incrementRefCount()
                     p_values.append(aval)
                 elif type_ == XdmType.XDM_NODE:
                     nval = PyXdmNode()
                     nval.derivednptr = nval.derivedptr = nval.thisvptr = <saxoncClasses.XdmNode*>c_values[i]
                     nval.thisvptr.incrementRefCount()
                     p_values.append(nval)
                 elif type_ == XdmType.XDM_FUNCTION_ITEM:
                     fval = PyXdmFunctionItem()
                     fval.derivedfptr = fval.derivedptr = fval.thisvptr = <saxoncClasses.XdmFunctionItem*>c_values[i]
                     fval.thisvptr.incrementRefCount()
                     p_values.append(fval)
                 elif type_ == XdmType.XDM_MAP:
                     mval = PyXdmMap()
                     mval.derivedmmptr = mval.derivedfptr = mval.derivedptr = mval.thisvptr = <saxoncClasses.XdmMap*>c_values[i]
                     mval.thisvptr.incrementRefCount()
                     p_values.append(mval)
                 elif type_ == XdmType.XDM_ARRAY:
                     aaval = PyXdmArray()
                     aaval.derivedaaptr = aaval.derivedfptr = aaval.derivedptr = aaval.thisvptr = <saxoncClasses.XdmArray*>c_values[i]
                     aaval.thisvptr.incrementRefCount()
                     p_values.append(aaval)


         return p_values



cdef class PyXdmArray(PyXdmFunctionItem):
     """
     The class PyXdmArray represents an array in the XDM data model. An array is a list of zero or more members,
     each of which is an arbitrary XDM value. The array itself is an XDM item. A PyXdmArray is immutable.
     """
     cdef saxoncClasses.XdmArray *derivedaaptr      # hold a C++ instance which we're wrapping
     def __cinit__(self):
        if type(self) is PyXdmArray:
            self.derivedaaptr = self.derivedfptr = self.derivedptr = self.thisvptr = new saxoncClasses.XdmArray()
     def __dealloc__(self):
        if type(self) is PyXdmArray and self.derivedaaptr != NULL:
            if self.derivedaaptr.getRefCount() < 1:
                del self.derivedaaptr
            else:
                self.derivedaaptr.decrementRefCount()



     def __repr__(self):
        cdef const char * c_string = self.derivedaaptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def __str__(self):
        cdef const char * c_string = self.derivedaaptr.toString()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def __iter__(self):
        """
        __iter__(self)
        Returns the Iterator object of PyXdmArray
        """
        return iter(self.as_list())

     @property
     def array_length(self):
         """
         array_length(self)
         Get the number of members in the array
         Returns:
             int: the number of members in the array. (Note that the size() method returns 1 (one),
             because an XDM array is an item.)
         """
         return self.derivedaaptr.arrayLength()

     @property
     def string_value(self):
        """
        string_value(self)
        Property to get the string value of the PyXdmArray
        Returns:
            str: String value of the array item
        """
        cdef const char * c_string = self.derivedaaptr.getStringValue()
        py_string_i = make_py_str(c_string)
        saxoncClasses.SaxonProcessor.deleteString(c_string)
        return py_string_i

     def get(self, int n):
         """
         get(self, int n)
         Get the n'th member in the array, counting from zero
         Args:
             n (int): the member that is required, counting the first member in the array as member zero
         Returns:
             PyXdmValue: the n'th member in the sequence making up the array, counting from zero
         """
         cdef saxoncClasses.XdmValue * c_xdmValue = NULL
         cdef PyXdmValue value_

         c_xdmValue = self.derivedaaptr.get(n)

         if c_xdmValue is NULL:
             return None
         else:
             value_ = PyXdmValue()
             value_.thisvptr = c_xdmValue
             return value_

     def put(self, int n, PyXdmValue value):
         """
         put(self, int n, PyXdmValue value)
         Create a new array in which one member is replaced with a new value.
         Args:
             n (int): n the position of the member that is to be replaced, counting the first member
                in the array as member zero
             value (PyXdmValue): the new value for this member
         Returns:
             PyXdmArray: a new array, the same length as the original, with one member replaced by a new value
         """
         cdef PyXdmArray newarr_
         cdef PyXdmAtomicValue avalue_
         cdef PyXdmItem ivalue_
         cdef PyXdmNode nvalue_
         cdef PyXdmValue value_
         cdef saxoncClasses.XdmArray * c_xdmArr = NULL
         cdef saxoncClasses.XdmValue * c_in_xdmValue = NULL

         if value is None or n<0:
             return None

         if isinstance(value, value):
             value_ = value
             c_xdmArr = self.derivedaaptr.put(n, value.thisvptr)
         elif  isinstance(value, PyXdmNode):
             nvalue_ = value
             c_in_xdmValue  = <saxoncClasses.XdmValue*>  nvalue_.derivednptr
             c_xdmArr = self.derivedaaptr.put(n, c_in_xdmValue)
         elif  isinstance(value, PyXdmAtomicValue):
             avalue_ = value
             c_in_xdmValue  = <saxoncClasses.XdmValue*> avalue_.derivedaptr
             c_xdmArr = self.derivedaaptr.put(n, c_in_xdmValue)
         elif  isinstance(value, PyXdmItem):
             ivalue_ = value
             c_in_xdmValue  = <saxoncClasses.XdmValue*>  ivalue_.derivedptr
             c_xdmArr = self.derivedaaptr.put(n, c_in_xdmValue)

         if c_xdmArr is NULL:
             return None
         newarr_ = PyXdmArray()
         newarr_.derivedaaptr = newarr_.derivedfptr = newarr_.derivedptr = newarr_.thisvptr = c_xdmArr
         return newarr_

     def add_member(self, value):
         """
         add_member(self, value)
         Append a new member to an array.
         Args:
             value (PyXdmValue): the new member
         Returns:
             PyXdmArray: a new array, one item longer than the original
         """

         cdef PyXdmArray newarr_
         cdef PyXdmAtomicValue avalue_
         cdef PyXdmItem ivalue_
         cdef PyXdmNode nvalue_
         cdef PyXdmValue value_
         cdef saxoncClasses.XdmArray * c_xdmArr = NULL

         if isinstance(value, PyXdmValue):
             value_ = value
             c_xdmArr = self.derivedaaptr.addMember(value_.thisvptr)
         elif  isinstance(value, PyXdmNode):
             nvalue_ = value
             c_xdmArr = self.derivedaaptr.addMember(<saxoncClasses.XdmValue*>  nvalue_.derivednptr)
         elif  isinstance(value, PyXdmAtomicValue):
             avalue_ = value
             c_xdmArr = self.derivedaaptr.addMember(<saxoncClasses.XdmValue*> avalue_.derivedaptr)
         elif  isinstance(value, PyXdmItem):
             ivalue_ = value
             c_xdmArr = self.derivedaaptr.addMember(<saxoncClasses.XdmValue*>  ivalue_.derivedptr)

         if c_xdmArr is NULL:
             return None
         newarr_ = PyXdmArray()
         newarr_.derivedaaptr = newarr_.derivedfptr = newarr_.derivedptr = newarr_.thisvptr = c_xdmArr
         return newarr_

     def concat(self, PyXdmArray value):
         """
         concat(self, PyXdmArray value)
         Concatenate another array to this array
         Args:
             value (PyXdmArray): the other array
         Returns:
             PyXdmArray: a new array, containing the members of this array followed by the members of the other array
         """
         cdef PyXdmArray newarr_

         cdef saxoncClasses.XdmArray * c_xdmArr = NULL

         c_xdmArr = self.derivedaaptr.concat(value.derivedaaptr)

         if c_xdmArr is NULL:
             return None
         newarr_ = PyXdmArray()
         newarr_.derivedaaptr = newarr_.derivedfptr = newarr_.derivedptr = newarr_.thisvptr = c_xdmArr
         return newarr_

     def as_list(self):
         """
         as_list(self)
         Get the members of the array in the form of a list.
         Returns:
             list: list of the members of this array
         """
         """
         TODO: handle memory management"""
         cdef list p_values = []
         cdef int count, i
         count = self.derivedaaptr.arrayLength()
         cdef saxoncClasses.XdmValue **c_values

         cdef PyXdmValue val = None
         if count > 0:
             c_values = self.derivedaaptr.values()
             for i in range(count):
                 val = PyXdmValue()
                 val.thisvptr = c_values[i]
                 val.thisvptr.incrementRefCount()
                 p_values.append(val)
         return p_values

     @property
     def arity(self):
         """
         arity(self)
         Get the arity of the function
         Returns:
             int: the arity of the function, that is, the number of arguments in the function's signature
         """
         return 1

     
_o=PySaxonProcessor(None, False, True)       # This is important to prevent Python calling release too early before all Saxon objects have been garbage collected!
