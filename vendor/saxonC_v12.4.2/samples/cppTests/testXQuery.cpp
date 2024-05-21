
#include "../../Saxon.C.API/SaxonProcessor.h"
#include "../../Saxon.C.API/XdmArray.h"
#include "../../Saxon.C.API/XdmAtomicValue.h"
#include "../../Saxon.C.API/XdmFunctionItem.h"
#include "../../Saxon.C.API/XdmItem.h"
#include "../../Saxon.C.API/XdmMap.h"
#include "../../Saxon.C.API/XdmNode.h"
#include "../../Saxon.C.API/XdmValue.h"
#include "CppTestUtils.h"
#include <string>

using namespace std;

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

/*
 * Test1:
 */
void testxQuery1(SaxonProcessor *processor, XQueryProcessor *queryProc,
                 sResultCount *sresult) {
  cout << endl << "Test testXQuery1:" << endl;
  queryProc->clearParameters();
  queryProc->clearProperties();
  queryProc->setProperty("s", "../data/cat.xml");

  queryProc->setProperty("qs", "<out>{count(/out/person)}</out>");

  const char *result = nullptr;

  try {
    result = queryProc->runQueryToString();
    cout << "Result :" << result << endl;
    sresult->success++;
    delete result;
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testXQuery1-1");
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }
  }

  try {
    queryProc->executeQueryToFile(nullptr, "catOutput.xml", nullptr);
    if (CppTestUtils::exists("catOutput.xml")) {
      cout << "The file catOutput.xml exists" << endl;
      sresult->success++;
      remove("catOutput.xml");
    } else {
      sresult->failure++;
      sresult->failureList.push_back("testXQuery1-2");
      cout << "The file catOutput.xml does not exist" << endl;
    }
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testXQuery1-3");
    cout << "Exception throw = " << e.what() << endl;
  }

  queryProc->clearParameters();
  queryProc->clearProperties();
}

void testxQuery_ICU(SaxonProcessor *processor, XQueryProcessor *queryProc,
                    sResultCount *sresult) {
  cout << endl << "Test testXQuery_ICU:" << endl;
  queryProc->clearParameters();
  queryProc->clearProperties();

  queryProc->setProperty("qs", "format-integer(33,'Ww','cs')");

  const char *result = nullptr;
  try {
    result = queryProc->runQueryToString();
    cout << "Result :" << result << endl;
    sresult->success++;
    delete result;

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testXQuery_ICU");

    cerr << "Error: " << e.getMessage() << endl;
    cerr << "Error code: " << e.getErrorCode() << endl;
  }

  queryProc->clearParameters();
  queryProc->clearProperties();
}

void testxQueryError(XQueryProcessor *queryProc, sResultCount *sresult) {
  cout << endl << "Test testXQueryError-Test:" << endl;
  queryProc->clearParameters();
  queryProc->clearProperties();
  // queryProc->setProperty("s", "cat.xml");

  queryProc->setProperty("qs", "<out>{count(/out/person)}</out>");
  try {
    queryProc->executeQueryToFile(nullptr, "catOutput.xml", nullptr);
    sresult->failure++;
    sresult->failureList.push_back("testXQueryError");
  } catch (SaxonApiException &e) {
    cout << "Test success " << endl;
    sresult->success++;
    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;
  }

  queryProc->clearParameters();
  queryProc->clearProperties();
}

void testXQueryError2(SaxonProcessor *processor, XQueryProcessor *queryProc,
                      sResultCount *sresult) {
  cout << endl << "Test testXQueryError-test2:" << endl;
  queryProc->clearProperties();
  queryProc->clearParameters();
  queryProc->setProperty("s", "data/cat.xml");

  queryProc->setProperty("qs", "<out>{count(/out/person)}<out>");

  const char *result = nullptr;
  try {
    result = queryProc->runQueryToString();
    cout << "Result :" << result << endl;
    delete result;
    sresult->failure++;
    sresult->failureList.push_back("testXQueryError2");
  } catch (SaxonApiException &e) {
    sresult->success++;
    cout << "Exception found. " << endl;
    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;
  }

  queryProc->clearProperties();
  queryProc->clearParameters();
}

void testDefaultNamespace(SaxonProcessor *processor, XQueryProcessor *queryProc,
                          sResultCount *sresult) {
  cout << endl << "Test testDefaultNamespace:" << endl;
  queryProc->clearProperties();
  queryProc->clearParameters();
  queryProc->declareNamespace("", "http://one.uri/");

  XdmNode *input = processor->parseXmlFromString(
      "<foo xmlns='http://one.uri/'><bar/></foo>");

  if (input == nullptr) {
    cout << "Source document is null." << endl;
    sresult->failure++;
    sresult->failureList.push_back("testDefaultNamespace");
    return;
  }

  queryProc->setContextItem((XdmItem *)input);
  queryProc->setQueryContent("/foo");

  XdmValue *value = nullptr;
  try {
    value = queryProc->runQueryToValue();
    if (value != nullptr && value->size() == 1) {
      sresult->success++;
      cout << "Test1: Result is ok size is " << value->size() << endl;
      delete value;
    } else {
      sresult->failure++;
      sresult->failureList.push_back("testDefaultNamespace");
    }
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testDefaultNamespace");
    cout << "Exception found. " << endl;
    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;

    return;
  }
  queryProc->clearProperties();
  queryProc->clearParameters();
  delete input;
}

// Test that the XQuery compiler can compile two queries without interference
void testReusability(SaxonProcessor *processor, sResultCount *sresult) {
  cout << endl << "Test test XQuery reusability:" << endl;
  XQueryProcessor *queryProc2 = processor->newXQueryProcessor();

  queryProc2->clearProperties();
  queryProc2->clearParameters();

  XdmNode *input =
      processor->parseXmlFromString("<foo xmlns='http://one.uri/'><bar "
                                    "xmlns='http://two.uri'>12</bar></foo>");

  if (input == nullptr) {
    cout << "testReusability failure - Source document is null." << endl;
    if (processor->exceptionOccurred()) {
      cerr << processor->getErrorMessage() << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testReusability");
    return;
  }

  queryProc2->declareNamespace("", "http://one.uri/");
  queryProc2->setQueryContent(
      "declare variable $p as xs:boolean external; exists(/foo) = $p");

  queryProc2->setContextItem((XdmItem *)input);

  XdmAtomicValue *value1 = processor->makeBooleanValue(true);
  queryProc2->setParameter("p", (XdmValue *)value1);
  XdmValue *val = queryProc2->runQueryToValue();

  if (val != nullptr) {
    if (((XdmItem *)val->itemAt(0))->isAtomic()) {
      sresult->success++;
      cout << "Test1: Result is atomic" << endl;
      XdmAtomicValue *atomic = (XdmAtomicValue *)val->itemAt(0);
      bool result1 = atomic->getBooleanValue();
      cout << "Test2: Result value=" << (result1 == true ? "true" : "false")
           << endl;
      cout << "PrimitiveTypeName of  atomic=" << atomic->getPrimitiveTypeName()
           << endl;
    } else {
      cerr << "failure in testReusability-1" << endl;
      sresult->failure++;
      sresult->failureList.push_back("testReusability");
    }
    delete val;
  } else {
    if (queryProc2->exceptionOccurred()) {
      cerr << "failure in testReusability-1" << endl;
      sresult->failure++;
      sresult->failureList.push_back("testReusability-1");
      SaxonApiException *exception = queryProc2->getException();
      if (exception != nullptr) {
        cout << "Exception found. " << endl;
        const char *message = queryProc2->getErrorMessage();
        cout << "Error Message = " << message << endl;
        queryProc2->exceptionClear();
      }
    }

    return;
  }

  XQueryProcessor *queryProc3 = processor->newXQueryProcessor();
  queryProc3->declareNamespace("", "http://two.uri");
  queryProc3->setQueryContent(
      "declare variable $p as xs:integer external; /*/bar + $p");

  queryProc3->setContextItem((XdmItem *)input);

  XdmAtomicValue *value2 = processor->makeIntegerValue(6);
  cout << "PrimitiveTypeName of  value2=" << value2->getPrimitiveTypeName()
       << endl;
  queryProc3->setParameter("p", (XdmValue *)value2);

  XdmValue *val2 = queryProc3->runQueryToValue();

  if (val2 != nullptr) {
    const char *valStr = (val2->itemAt(0))->getStringValue();

    cout << "XdmValue size=" << val2->size() << ", " << valStr << endl;
    if (((XdmItem *)val2->itemAt(0))->isAtomic()) {
      sresult->success++;
      cout << "Test3: Result is atomic" << endl;
      XdmAtomicValue *atomic2 = (XdmAtomicValue *)(val2->itemAt(0));
      long result2 = atomic2->getLongValue();
      cout << "Result value=" << result2 << endl;
      cout << "PrimitiveTypeName of  atomic2="
           << atomic2->getPrimitiveTypeName() << endl;
    }
    operator delete((char *)valStr);
    delete val2;
  } else {
    if (queryProc3->exceptionOccurred()) {
      cerr << "failure in testReusability-2" << endl;
      sresult->failure++;
      sresult->failureList.push_back("testReusability-2");
      SaxonApiException *exception = queryProc3->getException();
      if (exception != nullptr) {
        cout << "Exception found. " << endl;
        const char *message = queryProc3->getErrorMessage();
        cout << "Error Message = " << message << endl;
        queryProc3->exceptionClear();
      }
    }
    delete value1;
    delete value2;
    delete queryProc2;
    delete queryProc3;
    return;
  }

  delete value1;
  delete value2;
  delete input;
  delete queryProc2;
  delete queryProc3;
}

// Test requirement of license file - Test should fail
void testXQueryLineNumberError(const char *cwd, sResultCount *sresult) {
  cout << endl << "Test testXQueryLineNumberError:" << endl;
  SaxonProcessor *processor = new SaxonProcessor(false);
  XQueryProcessor *queryProc = processor->newXQueryProcessor();
  if (queryProc == nullptr) {
    cout << "Test testXQueryLineNumberError failed to create XQueryProcessor"
         << endl;

    sresult->failure++;
    sresult->failureList.push_back("testXQueryLineNumberError");
    return;
  }
  queryProc->clearProperties();
  queryProc->clearParameters();
  if (cwd != nullptr) {
    queryProc->setcwd(cwd);
  }
  queryProc->setProperty("s", "../data/cat.xml");

  queryProc->setProperty("qs", "saxon:line-number((//person)[1])");
  const char *result = nullptr;
  try {
    result = queryProc->runQueryToString();
    if (result != nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("testXQueryLineNumberError");

      cout << "Result :" << result << endl;
      operator delete((char *)result);
    }
  } catch (SaxonApiException &e) {
    sresult->success++;
    cout << "Exception found. " << endl;
    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;
  }

  queryProc->clearProperties();
  queryProc->clearParameters();
}

// Test requirement of license file - Test should succeed
void testXQueryLineNumber(const char *cwd, sResultCount *sresult) {
  SaxonProcessor *processor = new SaxonProcessor(true);
  processor->setcwd(cwd);
  processor->setConfigurationProperty("l", "on");
  XQueryProcessor *queryProc = processor->newXQueryProcessor();
  cout << endl << "testXQueryLineNumber:" << endl;
  cout << "cwd = " << processor->getcwd() << endl;
  string baseURI = string("file://") + processor->getcwd();
  cerr << " BaseURI=" << baseURI.c_str() << endl;
  queryProc->setQueryBaseURI(baseURI.c_str());

  // queryProc->setProperty("s", "data/cat.xml");
  queryProc->declareNamespace("saxon", "http://saxon.sf.net/");

  queryProc->setProperty("qs", "saxon:line-number(doc('data/cat.xml')/out/"
                               "person[1])"); /// out/person[1]
  try {
    const char *result = queryProc->runQueryToString();
    cout << "Result :" << result << endl;
    sresult->success++;

    operator delete((char *)result);

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testXQueryLineNumber");
    cout << "Exception found." << endl;
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error Message = " << message << endl;
    }
  }

  delete queryProc;
  delete processor;
}

int main(int argc, char *argv[]) {

  const char *cwd = nullptr;
  if (argc > 1) {
    cwd = argv[1];
  }

  SaxonProcessor *processor = new SaxonProcessor(false);

  cout << "Test: XQueryProcessor with Saxon version=" << processor->version()
       << endl
       << endl;

  if (cwd != nullptr) {
    processor->setcwd(cwd);
  } else {
    char buff[FILENAME_MAX]; // create string buffer to hold path
    GetCurrentDir(buff, FILENAME_MAX);
    processor->setcwd(buff);
    cwd = (const char *)buff;
  }

  cout << "CWD = " << cwd << endl;

  XQueryProcessor *query = processor->newXQueryProcessor();

  sResultCount *sresult = new sResultCount();

  testxQuery1(processor, query, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testxQueryError(query, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testXQueryError2(processor, query, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  testDefaultNamespace(processor, query, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  testReusability(processor, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXQueryLineNumberError(cwd, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXQueryLineNumber(cwd, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  testxQuery_ICU(processor, query, sresult);

  delete query;

  delete processor;
  processor->release();

  cout << endl
       << "======================== Test Results ========================"
       << endl
       << endl;

  std::cout << "\nTest Results - Number of tests= "
            << (sresult->success + sresult->failure)
            << ", Successes = " << sresult->success
            << ",  Failures= " << sresult->failure << std::endl;

  std::list<std::string>::iterator it;
  std::cout << "Failed tests:" << std::endl;
  // Make iterate point to beginning and increment it one by one until it
  // reaches the end of list.
  for (it = sresult->failureList.begin(); it != sresult->failureList.end();
       it++) {
    // Print the contents
    std::cout << it->c_str() << std::endl;
  }

  delete sresult;

#ifdef MEM_DEBUG
  SaxonProcessor::getInfo();
#endif
  return 0;
}
