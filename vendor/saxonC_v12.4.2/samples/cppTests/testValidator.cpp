#include "../../Saxon.C.API/SaxonProcessor.h"
#include "../../Saxon.C.API/XdmNode.h"
#include "../../Saxon.C.API/XdmValue.h"
#include "CppTestUtils.h"

#include <string>

using namespace std;

void testValidator1(SaxonProcessor *processor, SchemaValidator *val,
                    sResultCount *sresult) {
  cout << endl
       << "testValidator1: Test Validate Schema from string - invalid doc"
       << endl;
  string invalid_xml =
      "<?xml version='1.0'?><request><a/><!--comment--></request>";
  const char *sch1 =
      "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' "
      "elementFormDefault='qualified' "
      "attributeFormDefault='unqualified'><xs:element "
      "name='request'><xs:complexType><xs:sequence><xs:element name='a' "
      "type='xs:string'/><xs:element name='b' "
      "type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = "
      "3'/></xs:complexType></xs:element></xs:schema>";
  XdmNode *input = nullptr;
  try {
    val->registerSchemaFromString(sch1);

    input = processor->parseXmlFromString(invalid_xml.c_str());
    val->setSourceNode(input);
    val->validate();
    sresult->failure++;
    sresult->failureList.push_back("testValidator1");
  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->success++;
  }
  if (input != nullptr) {
    delete input;
    input = nullptr;
  }
  val->clearParameters();
  val->clearProperties();
}

void testValidatorInParseXml(SaxonProcessor *processor, SchemaValidator *val,
                             sResultCount *sresult) {
  cout << endl
       << "testValidatorInParseXml: Test Validate Schema from string - invalid "
          "doc"
       << endl;
  string invalid_xml =
      "<?xml version='1.0'?><request><a/><!--comment--></request>";
  const char *sch1 =
      "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' "
      "elementFormDefault='qualified' "
      "attributeFormDefault='unqualified'><xs:element "
      "name='request'><xs:complexType><xs:sequence><xs:element name='a' "
      "type='xs:string'/><xs:element name='b' "
      "type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = "
      "3'/></xs:complexType></xs:element></xs:schema>";
  XdmNode *input = nullptr;
  try {
    val->registerSchemaFromString(sch1);

    input = processor->parseXmlFromString(invalid_xml.c_str(), nullptr, val);
    // val->setSourceNode(input);
    // val->validate();
    sresult->failure++;
    sresult->failureList.push_back("testValidator1");
  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->success++;
  }
  if (input != nullptr) {
    delete input;
    input = nullptr;
  }
}

void testValidator2(sResultCount *sresult) {
  SaxonProcessor *processor = new SaxonProcessor(true);
  processor->setConfigurationProperty("xsdversion", "1.1");
  SchemaValidator *val = processor->newSchemaValidator();

  cout << endl << "Test 2: Validate Schema from string" << endl;
  string invalid_xml =
      "<?xml version='1.0'?><request><a/><!--comment--></request>";
  const char *sch1 =
      "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' "
      "elementFormDefault='qualified' "
      "attributeFormDefault='unqualified'><xs:element "
      "name='request'><xs:complexType><xs:sequence><xs:element name='a' "
      "type='xs:string'/><xs:element name='b' "
      "type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = "
      "3'/></xs:complexType></xs:element></xs:schema>";

  string doc1 = "<Family "
                "xmlns='http://myexample/family'><Parent>John</"
                "Parent><Child>Alice</Child></Family>";

  XdmNode *input = nullptr;
  try {
    input = processor->parseXmlFromString(doc1.c_str());

  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->success++;
  }

  val->setSourceNode(input);

  try {

    val->registerSchemaFromString(sch1);

    val->validate();

    cout << endl << "Doc is valid!" << endl;
    sresult->failure++;
    sresult->failureList.push_back("testValidator2");
  } catch (SaxonApiException &e) {
    cout << endl << "Doc is not valid!" << endl;
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->success++;
  }
  if (input != nullptr) {
    delete input;
    input = nullptr;
  }
  delete val;
}

void testValidator3(SaxonProcessor *processor, SchemaValidator *val,
                    sResultCount *sresult) {
  processor->exceptionClear();
  val->clearParameters(true);
  val->clearProperties();
  cout << endl << "Test 3: Validate Schema from string" << endl;
  const char *sch1 =
      "<?xml version='1.0' encoding='UTF-8'?><schema "
      "targetNamespace='http://myexample/family' "
      "xmlns:fam='http://myexample/family' "
      "xmlns='http://www.w3.org/2001/XMLSchema'><element name='FamilyMember' "
      "type='string' /><element name='Parent' type='string' "
      "substitutionGroup='fam:FamilyMember'/><element name='Child' "
      "type='string' substitutionGroup='fam:FamilyMember'/><element "
      "name='Family'><complexType><sequence><element ref='fam:FamilyMember' "
      "maxOccurs='unbounded'/></sequence></complexType></element>  </schema>";
  try {
    val->registerSchemaFromString(sch1);
    val->setProperty("http://saxon.sf.net/feature/multipleSchemaImports", "on");
    val->validate("family.xml");
    cout << endl << "Doc1 is OK" << endl;
    sresult->failure++;
    sresult->failureList.push_back("testValidator3");
  } catch (SaxonApiException &e) {
    cout << endl << "Error: Doc reported as invalid!" << endl;
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->success++;
  }
}

void testValidator4(const char *cwd, sResultCount *sresult) {

  SaxonProcessor *processor = new SaxonProcessor(true);
  processor->setConfigurationProperty("xsdversion", "1.1");
  SchemaValidator *val = processor->newSchemaValidator();
  val->setcwd(cwd);
  val->clearParameters(true);
  val->clearProperties();
  cout << endl
       << "Test 4: Validate source file with schema file. i.e. family.xml and "
          "family.xsd"
       << endl;

  try {
    val->registerSchemaFromFile("../data/family-ext.xsd");

    val->registerSchemaFromFile("../data/family.xsd");
    val->validate("../data/family.xml");
    cout << endl << "Doc1 is OK" << endl;
    sresult->success++;
  } catch (SaxonApiException &e) {
    cout << endl << "Error: Doc reported as invalid!" << endl;
    const char *message = e.getMessage();
    const char *errorCode = e.getErrorCode();
    if (errorCode != nullptr) {
      cerr << "ErrorCode = " << errorCode << endl;
    }
    if (message != nullptr) {

      cerr << "Exception thrown = " << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testValidator4");
  }
  delete val;
  delete processor;
}

void testValidator4a(sResultCount *sresult) {
  SaxonProcessor *processor = new SaxonProcessor(true);
  processor->setConfigurationProperty("xsdversion", "1.1");
  SchemaValidator *val = processor->newSchemaValidator();
  val->clearParameters(true);
  val->clearProperties();
  cout << endl
       << "Test testValidator4a: Validate source file with schema file. i.e. "
          "family.xml and family.xsd to XdmNode"
       << endl;

  try {
    val->registerSchemaFromFile("../data/family-ext.xsd");
    val->registerSchemaFromFile("../data/family.xsd");
    XdmNode *node = val->validateToNode("../data/family.xml");

    const char *valueStr = node->toString();
    if (valueStr != nullptr) {
      cout << endl << "Doc1 is OK:" << valueStr << endl;
      operator delete((char *)valueStr);
    } else {
      cout << endl << "Error: Doc reported as valid!" << endl;
    }
    sresult->success++;
    delete node;
  } catch (SaxonApiException &e) {
    cout << endl << "Error: Doc reported as invalid!" << endl;
    const char *message = e.getMessage();
    const char *errorCode = e.getErrorCode();
    if (errorCode != nullptr) {
      cerr << "ErrorCode = " << errorCode << endl;
    }
    if (message != nullptr) {

      cerr << "Exception thrown = " << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testValidator4a");
  }

  delete val;
  delete processor;
}

void testValidator5(SaxonProcessor *processor, SchemaValidator *val,
                    sResultCount *sresult) {
  processor->exceptionClear();
  val->clearParameters(true);
  val->clearProperties();
  cout << endl << "Test 5: Validate Schema from string" << endl;
  string invalid_xml =
      "<?xml version='1.0'?><request><a/><!--comment--></request>";
  const char *sch1 =
      "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' "
      "elementFormDefault='qualified' "
      "attributeFormDefault='unqualified'><xs:element "
      "name='request'><xs:complexType><xs:sequence><xs:element name='a' "
      "type='xs:string'/><xs:element name='b' "
      "type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = "
      "3'/></xs:complexType></xs:element></xs:schema>";

  string doc1 = "<request "
                "xmlns='http://myexample/family'><Parent>John</"
                "Parent><Child1>Alice</Child1></request>";
  try {

    XdmNode *input = processor->parseXmlFromString(doc1.c_str());
    val->setProperty("xsdversion", "1.1");
    val->setParameter("node", (XdmValue *)input);

    val->registerSchemaFromString(sch1);

    val->setProperty("report-node", "true");

    val->setProperty("verbose", "true");
    val->validate();
    sresult->failure++;
    sresult->failureList.push_back("testValidator5");

    delete input;

  } catch (SaxonApiException &e) {
    cout << endl << "Error: Doc reported as invalid!" << endl;
    cout << endl
         << "Error: Validation Report is NULL - This should not be NULL. "
            "Probably no valid license file found."
         << endl;
    const char *message = e.getMessage();
    const char *errorCode = e.getErrorCode();
    if (errorCode != nullptr) {
      cerr << "ErrorCode = " << errorCode << endl;
    }
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    XdmNode *node = val->getValidationReport();
    const char *value = node->toString();
    if (value != nullptr) {
      cout << endl << "Validation Report: " << value << endl;
      sresult->success++;
      operator delete((char *)value);
    } else {
      cout << endl << "Validation Report value is NULL" << endl;
      sresult->failure++;
      sresult->failureList.push_back("testValidator5");
    }
    delete node;
  }
}

void testValidator6(SaxonProcessor *processor, SchemaValidator *val,
                    sResultCount *sresult) {
  processor->exceptionClear();
  val->clearParameters(true);
  val->clearProperties();
  cout << endl << "Test 6: Validate Schema from string and export" << endl;
  string invalid_xml =
      "<?xml version='1.0'?><request><a/><!--comment--></request>";
  const char *sch1 =
      "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' "
      "elementFormDefault='qualified' "
      "attributeFormDefault='unqualified'><xs:element "
      "name='request'><xs:complexType><xs:sequence><xs:element name='a' "
      "type='xs:string'/><xs:element name='b' "
      "type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = "
      "3'/></xs:complexType></xs:element></xs:schema>";

  string doc1 = "<request "
                "xmlns='http://myexample/family'><Parent>John</"
                "Parent><Child1>Alice</Child1></request>";
  try {
    XdmNode *input = processor->parseXmlFromString(doc1.c_str());

    val->setProperty("xsdversion", "1.1");

    val->registerSchemaFromString(sch1);
    val->exportSchema("exportedSchema.scm");
    cout << endl << "No errors found" << endl;
    sresult->success++;
    delete input;
  } catch (SaxonApiException &e) {
    cout << endl << "Error: Validation error found " << endl;
    const char *message = e.getMessage();
    const char *errorCode = e.getErrorCode();
    if (errorCode != nullptr) {
      cerr << "ErrorCode = " << errorCode << endl;
    }
    if (message != nullptr) {
      cerr << "Exception thrown = " << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testValidator5");
  }
}

int main(int argc, char *argv[]) {

  SaxonProcessor *processor = new SaxonProcessor(true);
  // setDebugMode(SaxonProcessor::sxn_environ->thread, 1);
  sResultCount *sresult = new sResultCount();
  cout << "Test: SchemaValidator with Saxon version=" << processor->version()
       << endl
       << endl;

  const char *cwd = nullptr;
  if (argc > 1) {
    cwd = argv[1];
  }
  if (cwd != nullptr) {
    processor->setcwd(cwd);
  } else {
    char buff[FILENAME_MAX]; // create string buffer to hold path
    GetCurrentDir(buff, FILENAME_MAX);
    processor->setcwd(buff);
    cwd = (const char *)buff;
  }

  cout << "CWD = " << cwd << endl;

  // processor->setConfigurationProperty("xsdversion", "1.1");

  SchemaValidator *validator = nullptr;

  try {
    validator = processor->newSchemaValidator();
  } catch (SaxonApiException &e) {
    cout << "Exception thrown when creating SchemaValidator message="
         << e.what() << endl;
    delete processor;
    return 0;
  }
  testValidator1(processor, validator, sresult);
  testValidatorInParseXml(processor, validator, sresult);
  testValidator2(sresult);

  testValidator3(processor, validator, sresult);
  processor->setConfigurationProperty(
      "http://saxon.sf.net/feature/multipleSchemaImports", "on");
  SchemaValidator *validator2 = processor->newSchemaValidator();
  testValidator4(cwd, sresult);
  testValidator4a(sresult);
  processor->setConfigurationProperty("xsdversion", "1.1");
  SchemaValidator *validator3 = processor->newSchemaValidator();
  testValidator5(processor, validator3, sresult);
  testValidator6(processor, validator3, sresult);

  std::cout << "\nTest Results - Number of tests= "
            << (sresult->success + sresult->failure)
            << ", Successes = " << sresult->success
            << ",  Failures= " << sresult->failure << std::endl;

  std::list<std::string>::iterator it;
  std::cout << "Failed tests:" << std::endl;
  // Make iterate point to beginning and increment it one by one till it reaches
  // the end of list.
  for (it = sresult->failureList.begin(); it != sresult->failureList.end();
       it++) {
    // Print the contents
    std::cout << it->c_str() << std::endl;
  }
  delete validator;
  delete validator2;
  delete validator3;

  delete processor;
  processor->release();
  delete sresult;
  return 0;
}
