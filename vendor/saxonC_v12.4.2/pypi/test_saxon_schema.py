from tempfile import mkstemp
import pytest
from saxoncee import *
import os
from os.path import isfile


@pytest.fixture
def saxonproc2():
    return PySaxonProcessor(license=True)

@pytest.fixture
def data_dir():
    return "../../samples/data/"

def testValidator2(saxonproc2):
    saxonproc2.set_cwd('.')
    saxonproc2.set_configuration_property("xsdversion", "1.1")
    val = saxonproc2.new_schema_validator()
    assert val is not None
    print(type(val))
    print(val.exception_occurred)
    invalid_xml = "<?xml version='1.0'?><request><a/><!--comment--></request>"
    sch1 = "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' elementFormDefault='qualified' attributeFormDefault='unqualified'><xs:element name='request'><xs:complexType><xs:sequence><xs:element name='a' type='xs:string'/><xs:element name='b' type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = 3'/></xs:complexType></xs:element></xs:schema>"
    input_ = saxonproc2.parse_xml(xml_text=invalid_xml)
    assert input_ is not None
    print(type(input_))
    val.set_source_node(input_)
    val.register_schema(xsd_text=sch1)
    val.validate()
    assert val.exception_occurred
    val.exception_clear()


def testValdiator3(data_dir, saxonproc2):
    saxonproc2.set_configuration_property("xsdversion", "1.1")
    val = saxonproc2.new_schema_validator()
    
    val.register_schema(xsd_file=data_dir + "family-ext.xsd")

    val.register_schema(xsd_file=data_dir + "family.xsd")
    val.validate(file_name=data_dir + "family.xml")
    nodea = val.validation_report
    if val.exception_occurred:
        print(val.get_error_message())
    assert not val.exception_occurred
    assert nodea is None
    val.exception_clear()

def testExportSchema(saxonproc2):
    saxonproc2.set_cwd('.')
    saxonproc2.set_configuration_property("xsdversion", "1.1")
    val = saxonproc2.new_schema_validator()
    assert val is not None
    print(type(val))
    print(val.exception_occurred)
    sch1 = "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' elementFormDefault='qualified' attributeFormDefault='unqualified'><xs:element name='request'><xs:complexType><xs:sequence><xs:element name='a' type='xs:string'/><xs:element name='b' type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = 3'/></xs:complexType></xs:element></xs:schema>"
    val.register_schema(xsd_text=sch1)
    val.export_schema("exportedSchema.scm")
    assert os.path.exists("exportedSchema.scm")


def testExportSchema2(saxonproc2):
    saxonproc2.set_configuration_property("xsdversion", "1.1")
    val = saxonproc2.new_schema_validator()

    val.register_schema(xsd_file="exportedSchema.scm")

    invalid_xml = "<?xml version='1.0'?><request><a/><!--comment--></request>"
    input_ = saxonproc2.parse_xml(xml_text=invalid_xml)
    assert input_ is not None
    print(type(input_))
    val.set_source_node(input_)
    val.validate()
    assert val.exception_occurred

def testValidatorReport(saxonproc2):
    saxonproc2.set_cwd('.')
    saxonproc2.set_configuration_property("xsdversion", "1.1")
    val = saxonproc2.new_schema_validator()
    val.set_property('report-node', "true");
    assert val is not None
    
    invalid_xml = "<?xml version='1.0'?><request><a/><!--comment--></request>"
    sch1 = "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' elementFormDefault='qualified' attributeFormDefault='unqualified'><xs:element name='request'><xs:complexType><xs:sequence><xs:element name='a' type='xs:string'/><xs:element name='b' type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = 3'/></xs:complexType></xs:element></xs:schema>"
    input_ = saxonproc2.parse_xml(xml_text=invalid_xml)
    assert input_ is not None

    val.set_source_node(input_)
    val.register_schema(xsd_text=sch1)
    val.validate()

    report = val.validation_report
    assert 'validation-report' in str(report)
    assert val.exception_occurred



def release(saxonproc):
   saxonproc.release()
