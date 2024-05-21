#include <sstream>
#include <stdio.h>

#include "../../Saxon.C.API/DocumentBuilder.h"
#include "../../Saxon.C.API/SaxonProcessor.h"
#include "../../Saxon.C.API/XdmArray.h"
#include "../../Saxon.C.API/XdmFunctionItem.h"
#include "../../Saxon.C.API/XdmItem.h"
#include "../../Saxon.C.API/XdmMap.h"
#include "../../Saxon.C.API/XdmNode.h"
#include "../../Saxon.C.API/XdmValue.h"
//#include "cppExtensionFunction.h"
#include "CppTestUtils.h"
#include <string>
#include <thread>

using namespace std;

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

/*char fname[] = "_nativeCall";
char funcParameters[] =
"(Ljava/lang/String;[Ljava/lang/Object;[Ljava/lang/String;)Ljava/lang/Object;";

JNINativeMethod cppMethods[] =
        {
                {
                        fname,
                        funcParameters,
                        (void *) &cppExtensionFunction::cppNativeCall
                }
        }; */

/*
 * Test transform to String. Source and stylesheet supplied as arguments
 */
void testApplyTemplatesString1(Xslt30Processor *trans, sResultCount *sresult) {

  cout << "Test: testApplyTemplatesString1:" << endl;
  //    trans->setupXslMessage(false);

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromFile("../data/test.xsl");
  } catch (SaxonApiException &e) {
    cerr << " Exception thrown=" << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString1");
  }
  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString1");
    cerr << "testApplyTemplatesString1 NULL found" << endl;
    if (trans->exceptionOccurred()) {
      cerr << "testApplyTemplatesString1 error: " << trans->getErrorMessage()
           << endl;
    }
    return;
  }
  try {
    executable->setInitialMatchSelectionAsFile("../data/cat.xml");
  } catch (SaxonApiException &e) {
    cerr << " Exception thrown=" << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString1");
    delete executable;
  }
  try {
    const char *output = executable->applyTemplatesReturningString();
    if (output == nullptr) {
      printf("result is null ====== FAIL ====== \n");
      sresult->failure++;
      fflush(stdout);
      sresult->failureList.push_back("testApplyTemplatesString1-0");
    } else if (string(output).find(string("<out>text2</out>")) !=
               std::string::npos) {
      printf("%s", output);
      printf("result is OK \n");
      sresult->success++;
      operator delete((char *)output);
    } else {
      printf("result is null ====== FAIL ====== \n");
      sresult->failure++;
      sresult->failureList.push_back("testApplyTemplatesString1-1");
      std::cout << "output=" << output << std::endl;
      operator delete((char *)output);
    }
    fflush(stdout);
    delete executable;
  } catch (SaxonApiException &e) {
    cerr << " Exception thrown=" << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString1");
    delete executable;
  }
}

/*
 * Test transform to String. Source and stylesheet supplied as arguments
 */
void testTransformToStringExtensionFunc(const char *cwd,
                                        SaxonProcessor *processor,
                                        Xslt30Processor *trans,
                                        sResultCount *sresult) {

  /*cout << endl << "Test: TransformToStringExtensionFunc:" << endl;

  bool nativeFound =
  processor->registerNativeMethods(SaxonProcessor::sxn_environ->env,
                                                      "com/saxonica/functions/extfn/cpp/NativeCall",
                                                      cppMethods,
  sizeof(cppMethods) / sizeof(cppMethods[0]));

  XsltExecutable * executable = trans->compileFromFile("testExtension.xsl");

  if(executable== nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("TransformToStringExtensionFunc");
      cerr << "TransformToStringExtensionFunc NULL found" << endl;
      if (trans->exceptionOccurred()) {
          cerr <<"TransformToStringExtensionFunc error: "<<
  trans->getErrorMessage() << endl;
      }
      return;
  }
  executable->setcwd(cwd);
  std::string libStr= cwd +  "cppExtensionFunction";
  executable->setProperty("extc",  libStr);

  if (nativeFound) {
      const char *output = executable->transformFileToString("../data/cat.xml");

      if (output == nullptr) {

          printf("result is null ====== FAIL ======  \n");
          sresult->failure++;
          sresult->failureList.push_back("testTransformToStringExtensionFunc");
      } else {
          sresult->success++;
          printf("result is OK \n");
      }
      fflush(stdout);
      delete output;
  } else {
      printf("native Class not found ====== FAIL ====== ");
      sresult->failure++;
      sresult->failureList.push_back("testTransformToStringExtensionFunc");
  }
  delete executable;*/
}

/*
 * Test transform to String. stylesheet supplied as argument. Source supplied as
 * XdmNode
 */
void testApplyTemplatesString2(SaxonProcessor *processor,
                               Xslt30Processor *trans, sResultCount *sresult) {

  cout << "Test: testApplyTemplatesString2:" << endl;
  XdmNode *input = nullptr;
  try {
    input = processor->parseXmlFromFile("../data/cat.xml");
  } catch (SaxonApiException &e) {
    cout << "Source document is null." << endl;
    cerr << " Exception thrown=" << e.what() << endl;

    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString2");
    return;
  }

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromFile("../data/test.xsl");
  } catch (SaxonApiException &e) {
    cerr << " Exception thrown=" << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString2");
  }

  try {
    executable->setInitialMatchSelection((XdmValue *)input);

    const char *output = executable->applyTemplatesReturningString();
    if (output == nullptr) {
      printf("result is null ====== FAIL ======  \n");
      sresult->failureList.push_back("testApplyTemplatesString2");
      sresult->failure++;
    } else {
      sresult->success++;
      printf("%s", output);
      printf("result is OK \n");
      operator delete((char *)output);
    }
  } catch (SaxonApiException &e) {
    cerr << " Exception thrown=" << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplatesString2");
  }
  fflush(stdout);
  delete input;
  delete executable;
}

/*
* Test transform to String. stylesheet supplied as argument. Source supplied as
XdmNode Should be error. Stylesheet file does not exist
*/
void testApplyTemplates2a_Error(SaxonProcessor *processor,
                                Xslt30Processor *trans, sResultCount *sresult) {

  cout << "Test: TransformToString2a_Error:" << endl;
  XdmNode *input = nullptr;

  try {

    input = processor->parseXmlFromFile("../data/cat.xml");

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplates2a_Error");
    cerr << "Error =" << e.what();
    return;
  }

  if (input == nullptr) {
    cout << "Source document is null. ====== FAIL ======" << endl;

    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplates2a_Error");
  }
  try {
    XsltExecutable *executable = trans->compileFromFile("test-error.xsl");

    sresult->failure++;
    sresult->failureList.push_back("testApplyTemplates2a_Error");
    fflush(stdout);

    delete executable;

  } catch (SaxonApiException &e) {
    printf("Expected result is null \n");
    sresult->success++;
    cerr << "Error =" << e.what();
  }
  delete input;
}

void testPackageExport(SaxonProcessor *processor, Xslt30Processor *trans,
                       sResultCount *sresult) {
  try {
    cout << "Test: testPackageExport:" << endl;
    trans->compileFromFileAndSave("../data/override-base-f-001.xsl",
                                  "../data/sandpit/test-package-001.pack");

    SaxonProcessor *processor2 = new SaxonProcessor(true);
    processor2->setcwd(processor->getcwd());
    Xslt30Processor *xc2 = processor2->newXslt30Processor();
    xc2->importPackage("../data/sandpit/test-package-001.pack");
    XsltExecutable *xe = xc2->compileFromFile("../data/override-f-001.xsl");
    const char *result = xe->callTemplateReturningString("main");
    if (result != nullptr) {
      cerr << "Result = " << result << endl;
      sresult->success++;
      operator delete((char *)result);
    } else {
      sresult->failure++;
      sresult->failureList.push_back("testPackageExport");
    }
    delete xe;
    delete xc2;
    delete processor2;
  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    const char *code = e.getErrorCode();
    if (code != nullptr) {
      cout << " error code =" << code << endl;
    }
    if (emessage != nullptr) {
      cout << " message = " << emessage << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testPackageExport");
    return;
  }
}

/*
* Test transform to String. stylesheet supplied as argument. Source supplied as
XdmNode Should be error. Source file does not exist
*/
void testTransformToString2b(SaxonProcessor *processor, Xslt30Processor *trans,
                             sResultCount *sresult) {

  cout << endl << "Test: TransformToString2b:" << endl;
  const char *result = nullptr;
  try {
    result = trans->transformFileToString("cat-error.xml", "test-error.xsl");

    operator delete((char *)result);

  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    const char *code = e.getErrorCode();
    cout << "Exception found: ";
    if (code != nullptr) {
      cout << " error code =" << code << endl;
    }
    if (emessage != nullptr) {
      cout << " message = " << emessage << endl;
    }
    sresult->success++;
    return;
  }

  sresult->failure++;
  sresult->failureList.push_back("testTransformToString2b");
  cerr << "testTransformToString2b NULL found" << endl;

  return;
}

/*
* Test transform to String. stylesheet supplied as argument. Source supplied as
xml string and integer parmater created and supplied
*/
void testTransformToString3(SaxonProcessor *processor, Xslt30Processor *trans,
                            sResultCount *sresult) {

  cout << endl << "Test: testTransformToString3" << endl;
  XdmNode *inputi = nullptr;
  try {
      inputi = processor->parseXmlFromString("<out><person>text1</person><person>text2</"
                                    "person><person>text3</person></out>");

  if (inputi == nullptr) {
    cout << "Source document inputi is null." << endl;
    if (trans->exceptionOccurred()) {
      cerr << "testTransformToString3 error: " << trans->getErrorMessage()
           << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testTransformToString3");

    return;
  }
  }
  catch (SaxonApiException &e) {
      const char *emessage = e.getMessage();
      const char *code = e.getErrorCode();
      cout << "Exception found: ";
      if (code != nullptr) {
        cout << " error code =" << code << endl;
      }
      if (emessage != nullptr) {
        cout << " message = " << emessage << endl;
      }
      sresult->failure++;
      sresult->failureList.push_back("testTransformToString3");
      return;
    }

  XdmAtomicValue *value1 = processor->makeIntegerValue(10);

  if (value1 == nullptr) {
    cout << "value1 is null." << endl;

    sresult->failure++;
    sresult->failureList.push_back("testTransformToString3");
    delete inputi;
    return;
  }
  XsltExecutable *executable = nullptr;
  try {
        executable = trans->compileFromFile("../data/test.xsl");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testTransformToString3");
    cerr << "testTransformToString3 NULL found" << endl;
    if (trans->exceptionOccurred()) {
      cerr << "testTransformToString3 error: " << trans->getErrorMessage()
           << endl;
    }
    delete value1;
    return;
  }

  executable->setParameter("numParam", (XdmValue *)value1);

  executable->setInitialMatchSelection((XdmNode *)inputi);
  const char *output = executable->applyTemplatesReturningString();
  if (output == nullptr) {
    printf("result is null ====== FAIL ====== \n");
    sresult->failureList.push_back("testTransformToString3");
  } else {
    printf("%s", output);
    printf("result is OK \n");
    operator delete((char *)output);
  }
  fflush(stdout);

  delete value1;
  delete inputi;
  inputi = nullptr;
  delete executable;
  }
    catch (SaxonApiException &e) {

         delete value1;
      delete inputi;
        const char *emessage = e.getMessage();
        const char *code = e.getErrorCode();
        cout << "Exception found: ";
        if (code != nullptr) {
          cout << " error code =" << code << endl;
        }
        if (emessage != nullptr) {
          cout << " message = " << emessage << endl;
        }
        sresult->failure++;
        sresult->failureList.push_back("testTransformToString3");
        return;
      }

}

/*
* Test transform to String. stylesheet supplied as argument. Source supplied as
xml string and integer parmater created and supplied
*/
void testTransformToString4(SaxonProcessor *processor, Xslt30Processor *trans,
                            sResultCount *sresult) {

  cout << "Test: testTransformToString4:" << endl;

  XdmNode *input = nullptr;

  try {
    input = processor->parseXmlFromString(
        "<out><person>text1</person><person>text2</person><person>text3</"
        "person></out>");

  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    const char *code = e.getErrorCode();
    cout << "Source document is null. ====== FAIL ====== " << endl;
    if (code != nullptr) {
      cout << " error code =" << code << endl;
    }
    if (emessage != nullptr) {
      cout << " message = " << emessage << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testTransformToString4");
    return;
  }

  if (input == nullptr) {
    cout << "Source document is null. ====== FAIL ====== " << endl;
    sresult->failure++;
    sresult->failureList.push_back("testTransformToString4");
    return;
  }

  try {
    XdmValue *values = new XdmValue();
    XdmAtomicValue *a1 = processor->makeIntegerValue(10);
    XdmAtomicValue *a2 = processor->makeIntegerValue(5);
    XdmAtomicValue *a3 = processor->makeIntegerValue(6);
    XdmAtomicValue *a4 = processor->makeIntegerValue(7);
    values->addXdmItem(a1);
    values->addXdmItem(a2);
    values->addXdmItem(a3);
    values->addXdmItem(a4);

    XdmNode *sheet = processor->parseXmlFromFile("../data/test2.xsl");
    if (sheet == nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("testTransformToString4");
      if (processor->exceptionOccurred()) {
        cerr << "testTransformToString4 error in compiling test2.xsl: "
             << processor->getErrorMessage() << endl;
      }
      delete input;
      delete values;
    }
    XsltExecutable *executable = trans->compileFromXdmNode(sheet);

    if (executable == nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("testTransformToString4");
      cerr << "testTransformToString4 NULL found" << endl;
      if (trans->exceptionOccurred()) {
        cerr << "testTransformToString4 error: " << trans->getErrorMessage()
             << endl;
      }
      delete values;
      return;
    }

    executable->setParameter("values", (XdmValue *)values);
    executable->setInitialMatchSelection((XdmNode *)input);
    const char *output = executable->applyTemplatesReturningString();
    if (output == nullptr) {
      printf("result is null \n");
      sresult->failure++;
      sresult->failureList.push_back("testTransformToString4");
    } else {
      printf("%s", output);
      printf("result is OK \n");
      operator delete((char *)output);
    }
    fflush(stdout);
    delete sheet;
    delete executable;
    delete input;
    delete values;
  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    const char *code = e.getErrorCode();
    if (code != nullptr) {
      cout << " error code =" << code << endl;
    }
    if (emessage != nullptr) {
      cout << " message = " << emessage << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testTransformToString4");
    return;
  }
}

void testTransformFromstring(SaxonProcessor *processor, Xslt30Processor *trans,
                             sResultCount *sresult) {
  cout << endl << "Test: testTransfromFromstring: " << endl;

  if (processor == nullptr) {
    cout << " processor is null" << endl;
    return;
  }
  XdmNode *input =
      processor->parseXmlFromString("<out><person>text1</person><person>text2</"
                                    "person><person>text3</person></out>");

  if (input == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testTransformFromstring");
    cerr << "testTransformFromstring NULL found" << endl;
    return;
  }

  XsltExecutable *executable = trans->compileFromString(
      "<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' "
      "version='2.0'>       <xsl:param name='values' select='(2,3,4)' "
      "/><xsl:output method='xml' indent='yes' /><xsl:template "
      "match='*'><output><xsl:for-each select='$values' ><out><xsl:value-of "
      "select='. * "
      "3'/></out></xsl:for-each></output></xsl:template></xsl:stylesheet>");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testTransformFromstring");
    cerr << "testTransformFromstring NULL found" << endl;
    if (trans->exceptionOccurred()) {
      cerr << "testTransformFromstring error: " << trans->getErrorMessage()
           << endl;
    }
    delete input;
    return;
  }

  const char *output = executable->transformToString((XdmNode *)input);
  if (output == nullptr) {
    printf("result is null ====== FAIL ====== \n");
    sresult->failure++;
    sresult->failureList.push_back("testTransformFromString");
    if (trans->exceptionOccurred()) {
      cerr << "testTransformFromstring error: " << trans->getErrorMessage()
           << endl;
    }
  } else {
    printf("%s", output);
    printf("result is OK \n");
    sresult->success++;
    delete output;
  }
  fflush(stdout);
  delete input;
  delete executable;
}

// Test case has error in the stylesheet
void testTransformFromstring2Err(SaxonProcessor *processor,
                                 Xslt30Processor *trans,
                                 sResultCount *sresult) {
  cout << endl << "Test: testTransfromFromstring2-Error:" << endl;

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromString(
        "<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' "
        "version='2.0'>       <xsl:param name='values' select='(2,3,4)' "
        "/><xsl:output method='xml' indent='yes' fail='no' /><xsl:template "
        "match='*'><output><xsl:for-each select1='$values' ><out><xsl:value-of "
        "select1='. * "
        "3'/></out></xsl:for-each></output></xsl:template></xsl:stylesheet>");

  } catch (SaxonApiException &e) {
    sresult->success++;

    const char *smessages = e.getCombinedStaticErrorMessages();
    const char *ecmessage = e.getMessageWithErrorCode();
    cerr << "Static Error count: " << e.staticErrorCount() << endl;
    if (smessages != nullptr) {
      cerr << "Static Error expected: " << smessages << endl;
      cerr << "Test other exception methods: " << e.getMessage() << endl;
    } else {
      cerr << "Static Errors is null: " << endl;
    }
    if (ecmessage != nullptr) {
      cerr << "Static Error with error code expected: " << ecmessage << endl;
    } else {
      cerr << "Static Errors with error code is null: " << endl;
    }

    const char *systemID = e.getSystemId();
    if (systemID != nullptr) {
      cerr << "system ID for Exception =  " << systemID << endl;
    }

    return;
  }

  sresult->failure++;
  sresult->failureList.push_back("testTransfromFromstring2-Error");
  delete executable;
}

void testTrackingOfValueReference(SaxonProcessor *processor,
                                  Xslt30Processor *trans,
                                  sResultCount *sresult) {

  cout << endl << "Test: TrackingOfValueReference:" << endl;
  ostringstream test;
  ostringstream valStr;
  ostringstream name;
  for (int i = 0; i < 10; i++) {
    test << "v" << i;
    valStr << "<out><person>text1</person><person>text2</person><person>text3</"
              "person><value>"
           << test.str() << "</value></out>";
    name << "value" << i;

    XdmValue *values =
        (XdmValue *)processor->parseXmlFromString(valStr.str().c_str());
    // cout<<"Name:"<<name.str()<<",
    // Value:"<<values->getHead()->getStringValue()<<endl;
    trans->setParameter(name.str().c_str(), values);
    test.str("");
    valStr.str("");
    name.str("");

    if (values == nullptr) {
      cerr << "TrackingOfValueReference failed to create XdmNode object"
           << endl;
      sresult->failure++;
      sresult->failureList.push_back("TrackingOfValueReference");
      return;
    }
  }

  std::map<std::string, XdmValue *> parMap = trans->getParameters();
  if (parMap.size() > 0) {
    // cout << "Parameter size: " << parMap.size() << endl;
    // cout << "Parameter size: " << parMap.size()<< endl;//",
    // Value:"<<trans->getParameters()["value0"]->getHead()->getStringValue()<<endl;
    ostringstream name1;
    for (int i = 0; i < 10; i++) {
      name1 << "sparam:value" << i;
      cout << " i:" << i << " Map size:" << parMap.size() << ", ";
      XdmValue *valuei = parMap[name1.str()];
      if (valuei != nullptr) {
        cout << name1.str();
        const char *resulti = valuei->itemAt(0)->getStringValue();
        if (valuei->itemAt(0) != nullptr)
          cout << "= " << resulti;
        cout << endl;
        delete resulti;

      } else {
        sresult->failure++;
        std::cerr << "trackingValueReference ====== FAIL ======" << std::endl;
        sresult->failureList.push_back("testTrackingOfValueReference");
        return;
      }
      name1.str("");
    }
  }
  if (parMap.size() > 0) {
    cerr << "Deleting map" << endl;
    trans->clearParameters(true);
  }
  sresult->success++;
}

/*Test case should be error.*/
void testTrackingOfValueReferenceError(SaxonProcessor *processor,
                                       Xslt30Processor *trans,
                                       sResultCount *sresult) {
  trans->clearParameters();

  cout << endl << "Test: TrackingOfValueReference-Error:" << endl;
  cout << "Parameter Map size: " << (trans->getParameters().size()) << endl;
  ostringstream test;
  ostringstream valStr;
  ostringstream name;
  try {
    for (int i = 0; i < 2; i++) {
      test << "v" << i;
      valStr << "<out><person>text1</person><person>text2</"
                "person><person>text3</person><value>"
             << test.str() << "<value></out>";
      name << "value" << i;

      XdmValue *values =
          (XdmValue *)processor->parseXmlFromString(valStr.str().c_str());
      if (values == nullptr) {
        cerr << "values NULL ====== FAIL =======" << endl;
        processor->exceptionClear();
      } else {
        trans->setParameter(name.str().c_str(), values);
      }
      test.str("");
      valStr.str("");
      name.str("");
    }
    std::map<std::string, XdmValue *> parMap = trans->getParameters();
    cout << "Parameter Map size: " << parMap.size() << endl;

  } catch (SaxonApiException &e) {

    std::cerr << "Success: Exception thrown " << e.getMessageWithErrorCode()
              << endl;

    const char *systemID = e.getSystemId();
    if (systemID != nullptr) {
      cerr << "system ID for Exception =  " << systemID << endl;
    }
    sresult->success++;
    return;
  }

  sresult->failure++;
  sresult->failureList.push_back("testTrackingOfValueReferenceError");
}

void testValidation(Xslt30Processor *trans, sResultCount *sresult) {
  trans->clearParameters();

  XsltExecutable *executable = trans->compileFromString(
      "<?xml version='1.0'?><xsl:stylesheet "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'                 "
      "xmlns:xs='http://www.w3.org/2001/XMLSchema' version='3.0' "
      "exclude-result-prefixes='#all'>     "
      "<xsl:import-schema><xs:schema><xs:element name='x' "
      "type='xs:int'/></xs:schema></xsl:import-schema> <xsl:template "
      "name='main'>          <xsl:result-document validation='strict'> "
      "<x>3</x>   </xsl:result-document>    </xsl:template>    "
      "</xsl:stylesheet>");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testValidation");
    if (trans->exceptionOccurred()) {
      cerr << "Error message: " << trans->getErrorMessage() << endl;
    }
    trans->exceptionClear();
    return;
  }

  const char *rootValue = executable->callTemplateReturningString("main");

  if (rootValue == nullptr) {
    std::cout << "NULL found" << std::endl;
    sresult->failure++;
    sresult->failureList.push_back("testValidation");
    return;

  } else {
    std::cout << "Result=" << rootValue << endl;
    sresult->success++;
    operator delete((char *)rootValue);
  }
  delete executable;
}

void testContext2NotRootNamedTemplate(SaxonProcessor *saxonproc,
                                      Xslt30Processor *trans,
                                      sResultCount *sresult) {
  trans->clearParameters();

  cout << endl << "Test: testContext2NotRootNamedTemplate " << endl;
  XdmNode *input_ = saxonproc->parseXmlFromString("<doc><e>text</e></doc>");
  XsltExecutable *executable = trans->compileFromString(
      "<xsl:stylesheet version='3.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable name='x' "
      "select='.'/><xsl:template match='/'>errorA</xsl:template><xsl:template "
      "name='main'>[<xsl:value-of "
      "select='$x'/>]</xsl:template></xsl:stylesheet>");
  executable->setGlobalContextItem(input_);
  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testContext2NotRootNamedTemplate");
    if (trans->exceptionOccurred()) {
      cerr << "Error message: " << trans->getErrorMessage() << endl;
    }
    trans->exceptionClear();
    return;
  }

  executable->setGlobalContextItem(input_);
  XdmValue *result = executable->callTemplateReturningValue("main");
  if (result == nullptr) {
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    sresult->failure++;
    sresult->failureList.push_back("testContext2NotRootNamedTemplate");
    return;
  }
  XdmItem *item1 = result->getHead();
  const char *resultStr = item1->getStringValue();

  cerr << "result = " << resultStr << std::endl;

  operator delete((char *)resultStr);
  resultStr = nullptr;

  const char *result2Str = nullptr;
  result2Str = executable->callTemplateReturningString("main");
  if (result2Str == nullptr) {
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    sresult->failure++;
    sresult->failureList.push_back("testContext2NotRootNamedTemplate");
    return;
  }

  cerr << "result2 = " << result2Str << std::endl;
  operator delete((char *)result2Str);
  delete item1;
  item1 = nullptr;
  delete result;
  result = nullptr;
  delete input_;
  delete executable;
}

void testXdmNodeOutput(Xslt30Processor *trans, sResultCount *sresult) {

  std::cout << "testXdmNodeOutput" << std::endl;
  XsltExecutable *executable = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "name='go'><a/></xsl:template></xsl:stylesheet>");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testXdmNodeOutput");
    if (trans->exceptionOccurred()) {
      cerr << "Error message: " << trans->getErrorMessage() << endl;
    }
    trans->exceptionClear();
    return;
  }

  XdmValue *rootValue = executable->callTemplateReturningValue("go");
  if (rootValue == nullptr) {
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    sresult->failure++;
    sresult->failureList.push_back("testXdmNodeOutput-0.0");
    delete executable;
    return;
  }
  XdmItem *rootItem = rootValue->getHead();
  if (rootItem == nullptr) {

    cout << "Result is null ====== FAIL ====== " << endl;
    sresult->failure++;
    sresult->failureList.push_back("testXdmNodeOutput-0");
    delete rootValue;
    delete executable;
    return;
  }
  XdmNode *root = (XdmNode *)rootItem;
  if (root->getNodeKind() == DOCUMENT) {
    cout << "Result is a Document" << endl;
  } else {
    cout << "Node is of kind:" << root->getNodeKind() << endl;
  }
  const char *result = nullptr;
  result = executable->callTemplateReturningString("go");
  if (string(result).find(string("<a/>")) != std::string::npos) {
    sresult->success++;
  } else {
    // TODO - this test case prints the XML declaration. Check if this correct
    sresult->failure++;
    cout << "testXdmNodeOutputAndString ======= FAIL========" << endl;
    sresult->failureList.push_back("testXdmNodeOutput");
  }
  if (result != nullptr) {
    operator delete((char *)result);
  }
  delete rootItem;
  delete rootValue;
  delete executable;
}

void exampleSimple1(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "ExampleSimple1 taken from PHP:" << endl;

  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile("../php/xsl/foo.xsl");
  } catch (SaxonApiException &e) {
    cerr << "Failed - Exception thrown = " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple1");
    return;
  }

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple1");
    cerr << "exampleSimple1 NULL found" << endl;
    if (proc->exceptionOccurred()) {
      cerr << "exampleSimple1 error: " << proc->getErrorMessage() << endl;
    }
    return;
  }
  executable->setInitialMatchSelectionAsFile("../php/xml/foo.xml");
  const char *result = executable->applyTemplatesReturningString();
  if (result != NULL) {
    cout << result << endl;
    sresult->success++;
    operator delete((char *)result);
  } else {
    cout << "Result is null ====== FAIL ====== " << endl;
    sresult->failureList.push_back("exampleSimple1");
    sresult->failure++;
  }
  proc->clearParameters();
  delete executable;
}

void exampleSimple1Err(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "ExampleSimple1Err taken from PHP:" << endl;
  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile("err.xsl");
  } catch (SaxonApiException &e) {
    const char *errorCode = e.getErrorCode();
    const char *emessage = e.what();
    cerr << "Exception as expected: ";
    if (errorCode != nullptr) {
      cerr << "ErrorCode = " << errorCode << endl;
    }
    if (emessage != nullptr) {
      cerr << " " << emessage << endl;
    }
    sresult->success++;
    return;
  }

  sresult->failure++;
  sresult->failureList.push_back("exampleSimple1Err");
  if (executable != nullptr) {
    delete executable;
  }
}

void exampleSimple2(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "<b>exampleSimple2:</b><br/>" << endl;
  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile("../php/xsl/foo.xsl");
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple2");
    cerr << "exampleSimple2 exception thrown" << endl;
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "exampleSimple2 error: " << emessage << endl;
    }
    return;
  }

  executable->setInitialMatchSelectionAsFile("../php/xml/foo.xml");
  const char *filename = "output1.xml";
  executable->setOutputFile(filename);
  try {
    executable->applyTemplatesReturningFile("../output1.xml");
  } catch (SaxonApiException &e) {
    cout << e.getMessage() << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple2");
    delete executable;
    return;
  }

  if (CppTestUtils::exists("../output1.xml")) {
    cout << "The file $filename exists" << endl;
    remove("../output1.xml");
    sresult->success++;
  } else {
    cout << "The file " << filename << " does not exist" << endl;

    sresult->failure++;
    sresult->failureList.push_back("exampleSimple2");
  }

  delete executable;
}

void exampleTransformToFile(SaxonProcessor *sproc, Xslt30Processor *proc,
                            sResultCount *sresult) {
  cout << "<b>exampleTransformToFile:</b><br/>" << endl;

  XdmNode *xmlfile = nullptr;
  try {
    xmlfile = sproc->parseXmlFromFile("../php/xml/foo.xml");
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToFile");
    const char *errorMessage = e.what();
    if (errorMessage != nullptr) {
      cerr << "exampleTransformToFile error: " << errorMessage << endl;
    }
    return;
  }
  if (xmlfile == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToFile");
    cerr << "exampleTransformToFile NULL found" << endl;
    if (sproc->exceptionOccurred()) {
      const char *errorMessage = sproc->getErrorMessage();
      if (errorMessage != nullptr) {
        cerr << "exampleTransformToFile error: " << errorMessage << endl;
      }
    }

    return;
  }
  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile("../php/xsl/foo.xsl");
  } catch (SaxonApiException &e) {
    if (proc->exceptionOccurred()) {
      cerr << "exampleTransformToFile error: " << e.what() << endl;
    }
  }
  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToFile");
    cerr << "exampleTransformToFile NULL found" << endl;

    return;
  }

  const char *filename = "../output2.xml";
  executable->setInitialMatchSelectionAsFile("../php/xml/foo.xml");
  executable->setOutputFile(filename);
  executable->transformToFile(xmlfile);

  if (CppTestUtils::exists("../output2.xml")) {
    cout << "The file output2.xml exists" << endl;
    remove("../output2.xml");
    sresult->success++;
  } else {
    cout << "The file " << filename << " does not exist" << endl;
    if (executable->exceptionOccurred()) {
      cout << proc->getErrorMessage() << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToFile");
  }
  delete xmlfile;
  delete executable;
}

void exampleTransformToString(SaxonProcessor *sproc, Xslt30Processor *proc,
                              sResultCount *sresult) {
  cout << "<b>exampleTransformToString:</b><br/>" << endl;

  XdmNode *xmlfile = nullptr;
  try {
    xmlfile = sproc->parseXmlFromString("<xml><value>5</value></xml>");
  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToString");
    cerr << "exampleTransformToFile NULL found" << endl;
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "exampleTransformToFile error: " << emessage << endl;
    }
    delete emessage;
    return;
  }

  XsltExecutable *executable = nullptr;

  try {
    executable = proc->compileFromString(
        "<xsl:stylesheet xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" "
        "version=\"2.0\">\n"
        "  <xsl:output method=\"xml\" encoding=\"utf-8\" standalone=\"yes\" "
        "indent=\"yes\"/>\n"
        "\n"
        "  <xsl:template match=\"/\">\n"
        "    <xsl:message>producing sheet</xsl:message>\n"
        "    <xsl:result-document href=\"output.xml\">\n"
        "      <result>\n"
        "        <value>You put a <xsl:value-of "
        "select=\"/xml/value\"/></value>\n"
        "      </result>\n"
        "    </xsl:result-document>\n"
        "  </xsl:template>\n"
        "</xsl:stylesheet>");

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToString");
    cerr << "exampleTransformToString NULL found" << endl;

    cerr << "exampleTransformToString error: " << e.what() << endl;
    return;
  }

  string baseURI = string("file://") + sproc->getcwd();
  cerr << "baseURI = " << baseURI << endl;
  executable->setBaseOutputURI(baseURI.c_str());

  executable->setInitialMatchSelection(xmlfile);
  executable->setGlobalContextItem(xmlfile);
  const char *result = nullptr;
  try {
    executable->setSaveXslMessage(true);
    result = executable->transformToString();
    XdmValue *messages = executable->getXslMessages();
    const char *xslMessagesStr = messages->toString();
    cerr << "xsl:messages = " << xslMessagesStr << std::endl;
    ;
    delete messages;
    delete xslMessagesStr;
  } catch (SaxonApiException &e) {
    cerr << "exampleTransformToString: exception thrown" << endl;
    cout << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToString");
    return;
  }

  if (result == nullptr) {

    cerr << "exampleTransformToString: result is NULL" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleTransformToString");
  } else {
    cout << "exampleTransformToString = " << result << endl;
    if (CppTestUtils::exists("../output.xml")) {
      cout << "The file output.xml exists" << endl;
      remove("output.xml");
      sresult->success++;
    } else {
      cout << "The file output.xml does not exist." << endl;

      sresult->failure++;
      sresult->failureList.push_back("exampleTransformToString");
    }
  }
  delete result;
  delete xmlfile;
  delete executable;
}

void exampleSimple3(SaxonProcessor *saxonProc, Xslt30Processor *proc,
                    sResultCount *sresult) {
  cout << "<b>exampleSimple3:</b><br/>" << endl;
  proc->clearParameters();

  XdmNode *xdmNode =
      saxonProc->parseXmlFromString("<doc><b>text value of out</b></doc>");


  XsltExecutable *executable = nullptr;

  try {
    executable = proc->compileFromFile("../php/xsl/foo.xsl");
  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    cout << "Error message=" << message << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple3");

    return;
  }

  if (executable == nullptr) {
    cout << "executable is NULL" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleSimple3");
    return;
  }

  executable->setInitialMatchSelection((XdmNode *)xdmNode);
  sresult->success++;
  delete xdmNode;
  delete executable;
}

void exampleSimple3aError(SaxonProcessor *saxonProc, Xslt30Processor *proc,
                          sResultCount *sresult) {
  cout << "<b>exampleSimple3aError:</b><br/>" << endl;

  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile(nullptr);
  } catch (SaxonApiException &e) {
    cout << "Expected failure of test exampleSimple3aError:" << endl;
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Exception success = " << message << endl;
    }
    sresult->success++;
    return;
  }

  sresult->failure++;
  sresult->failureList.push_back("exampleSimple3aError");
  delete executable;
  return;
}

void exampleParam(SaxonProcessor *saxonProc, Xslt30Processor *proc,
                  sResultCount *sresult) {
  cout << "Test: ExampleParam" << endl;
  proc->exceptionClear();
  XsltExecutable *executable = nullptr;
  try {
    executable = proc->compileFromFile("php/xsl/foo.xsl");
    executable->setInitialMatchSelectionAsFile("php/xml/foo.xml");
  } catch (SaxonApiException &e) {
    cout << "Expected failure of test exampleParam:" << endl;
    const char *message = e.getMessage();

    if (message != nullptr) {
      cout << "Exception message = " << message << endl;
    }

    sresult->success++;
    return;
  }

  if (executable == nullptr) {
    cout << "executable is NULL" << endl;

    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    return;
  }

  XdmAtomicValue *xdmvalue = saxonProc->makeStringValue("Hello to you");
  if (xdmvalue != nullptr) {
    executable->setParameter("a-param", (XdmValue *)xdmvalue);
  } else {
    cout << "Xdmvalue is NULL - ====== FAIL =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    delete executable;
    return;
  }
  const char *result = nullptr;
  try {
    result = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Exception thrown ======= fail =====" << endl;
    cerr << "Error: " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }
    delete executable;
    return;
  }

  if (result != nullptr) {
    cout << "Output:" << result << endl;
    sresult->success++;
    operator delete((char *)result);
  } else {
    cout << "Result is NULL<br/>  ======= fail-1 =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");

    delete executable;
    return;
  }

  // proc->clearParameters();
  // unset($result);
  // echo 'again with a no parameter value<br/>';

  executable->setProperty("!indent", "yes");
  const char *result2 = nullptr;

  try {
    result2 = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Result2 is NULL<br/>  ======= fail =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }
    delete xdmvalue;
    delete executable;
    return;
  }

  if (result2 != nullptr) {
    cout << "Result2 output= " << result2 << endl;
    sresult->success++;
    operator delete((char *)result2);
  } else {
    cout << "Result2 is NULL<br/>  ======= fail =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    delete xdmvalue;
    delete executable;
    return;
  }

  //  unset($result);
  // echo 'again with no parameter and no properties value set. This should fail
  // as no contextItem set<br/>';
  // delete xdmvalue;
  // executable->clearParameters();

  XdmAtomicValue *xdmValue2 = saxonProc->makeStringValue("goodbye to you");

  if (xdmValue2 == nullptr) {
    cout << "Xdmvalue is NULL - ====== FAIL =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    delete executable;
    delete xdmvalue;
    return;
  }

  executable->setParameter("a-param", (XdmValue *)xdmValue2);
  delete xdmvalue;

  const char *result3 = nullptr;

  try {
    result3 = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Error in result ===== FAIL =======" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }
  }
  if (result3 != nullptr) {
    cout << "Output =" << result3 << endl;

    sresult->success++;
    operator delete((char *)result3);

  } else {
    cout << "Error in result ===== FAIL-1 =======" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
  }
  delete xdmValue2;
  delete executable;
}

// test parameter and properties maps where we update key, value pair.
void exampleParam2(SaxonProcessor *saxonProc, Xslt30Processor *proc,
                   sResultCount *sresult) {
  cout << "\nExampleParam:</b><br/>" << endl;
  XsltExecutable *executable = proc->compileFromFile("php/xsl/foo.xsl");
  executable->setInitialMatchSelectionAsFile("php/xml/foo.xml");

  XdmAtomicValue *xdmvalue = saxonProc->makeStringValue("Hello to you");
  XdmAtomicValue *xdmvalue2i = saxonProc->makeStringValue("Hello from me");
  if (xdmvalue != NULL) {

    executable->setParameter("a-param", (XdmValue *)xdmvalue);
    executable->setParameter("a-param", (XdmValue *)xdmvalue2i);

  } else {
    cout << "Xdmvalue is null - ====== FAIL =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam-1");
  }
  const char *result = nullptr;

  try {
    result = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Result is NULL<br/>  ======= fail =====" << endl;
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("exampleParam-2");
    return;
  }

  if (result != NULL) {
    string sresulti = string(result);
    if (sresulti.compare("Hello from me") == 0) {
      cout << "Output:" << result << endl;
      sresult->success++;
      operator delete((char *)result);
    } else {
      cout << "Result is " << result << " <br/> ======= fail ===== " << endl;
      sresult->failure++;
      sresult->failureList.push_back("exampleParam-2");
    }
  } else {
    cout << "Result is NULL<br/>  ======= fail-1 =====" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam-2");
  }

  // proc->clearParameters();
  // unset($result);
  // echo 'again with a no parameter value<br/>';

  executable->setProperty("!indent", "no");
  executable->setProperty("!indent", "yes");
  const char *result2 = nullptr;
  try {
    result2 = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Error in result ===== FAIL =======" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
    return;
  }

  executable->clearProperties();

  if (result2 != nullptr) {
    cout << result2 << endl;
    sresult->success++;
    operator delete((char *)result2);
  }

  //  unset($result);
  // echo 'again with no parameter and no properties value set. This should fail
  // as no contextItem set<br/>';
  XdmAtomicValue *xdmValue2 = saxonProc->makeStringValue("goodbye to you");
  executable->setParameter("a-param", (XdmValue *)xdmValue2);

  const char *result3 = nullptr;

  try {
    result3 = executable->applyTemplatesReturningString();
  } catch (SaxonApiException &e) {
    cout << "Error in result ===== FAIL =======" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
  }
  if (result3 != nullptr) {
    cout << "Output =" << result3 << endl;

    sresult->success++;
    operator delete((char *)result3);
  } else {
    cout << "Error in result ===== FAIL 1=======" << endl;
    sresult->failure++;
    sresult->failureList.push_back("exampleParam");
  }
}

/* XMarkbench mark test q12.xsl with just-in-time=true*/
void xmarkTest1(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "Test: xmarkTest1 - XMarkbench mark test q12.xsl (JIT=true):" << endl;

  proc->setJustInTimeCompilation(true);

  XdmValue *result = nullptr;

  try {
    result = proc->transformFileToValue("../data/xmark100k.xml", "../data/q12.xsl");
  } catch (SaxonApiException &e) {
    printf("Exception thrown \nCheck For errors:");
    sresult->failure++;
    sresult->failureList.push_back("xmarkTest1");
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << proc->getErrorMessage() << endl;
    } else {
      cerr << "Message is nullptr" << endl;
    }
    return;
  }
  if (result != nullptr && !proc->exceptionOccurred()) {
    cout << "XdmNode returned" << endl;
    sresult->success++;
    delete result;
  } else {
    printf("result is null ");
    sresult->failure++;
    sresult->failureList.push_back("xmarkTest1");
  }
  proc->setJustInTimeCompilation(false);
}

/* XMarkbench mark test q12.xsl with just-in-time=true*/
void xmarkTest2(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "Test: xmarkTest2 - XMarkbench mark test q12.xsl (JIT=true):" << endl;

  proc->setJustInTimeCompilation(true);

  XdmValue *result = nullptr;
  try {
    result = proc->transformFileToValue("../data/xmark100k.xml", "../data/q12.xsl");
  } catch (SaxonApiException &e) {
    printf("Exception thrown \nCheck For errors:");
    sresult->failure++;
    sresult->failureList.push_back("xmarkTest2");
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << message << endl;
    }
  }
  if (result != nullptr && !proc->exceptionOccurred()) {
    cout << "XdmNode returned" << endl;
    sresult->success++;
    delete result;

  } else {
    printf("result is null \nCheck For errors:");
    sresult->failure++;
    sresult->failureList.push_back("xmarkTest2");
  }

  proc->setJustInTimeCompilation(false);
}

/* XMarkbench mark test q12.xsl with just-in-time=true*/
void exampleSimple_xmark(Xslt30Processor *proc, sResultCount *sresult) {
  cout << "exampleSimple_xmark test - test q12.xsl:" << endl;

  proc->setJustInTimeCompilation(true);

  XdmValue *result = nullptr;
  try {
    result = proc->transformFileToValue("../data/xmark100k.xml", "../data/q12.xsl");
  } catch (SaxonApiException &e) {
    printf("Result is null \nCheck For errors:");
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << message << endl;
    }

    sresult->failure++;
    sresult->failureList.push_back("exampleSimple_xmark");
  }

  if (result != nullptr) {
    cout << "XdmNode returned" << endl;
    sresult->success++;
    delete result;
  } else {
    printf("Result is null \nCheck For errors:");

    sresult->failure++;
    sresult->failureList.push_back("exampleSimple_xmark");
  }
  proc->clearParameters();
  proc->setJustInTimeCompilation(false);
}

/*
 * Test saving nd loading a Xslt package
 */
void testPackage1(Xslt30Processor *trans, sResultCount *sresult) {

  cout << endl << "Test: testPackage1 - Saving and loading Packages:" << endl;
  trans->clearParameters();

  try {
    trans->compileFromFileAndSave("../data/test.xsl", "test1.sef");
    const char *output =
        trans->transformFileToString("../data/cat.xml", "test1.sef");

    if (output == nullptr) {
      printf("result is null \n");
      sresult->failure++;
      sresult->failureList.push_back("testPackage1-1");

    } else {
      printf("%s", output);
      printf("result is OK \n");
      sresult->success++;
    }
    fflush(stdout);
    delete output;

  } catch (SaxonApiException &e) {
    printf("testPackage1 failed - Exception thrown \n");
    const char *message = e.getMessage();
    if (message != NULL) {
      cout << "Exception message =" << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testPackage1");
  }
}

/*
 * Test saving and loading a Xslt package
 */
void testPackage1a(Xslt30Processor *trans, sResultCount *sresult) {

  cout << endl << "Test: testPackage1a" << endl;
  trans->clearParameters();

  try {
    trans->compileFromFileAndSave("../data/test.xsl", "test1a.sef");
  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error message =" << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testPackage1a");
    return;
  }

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromFile("test1.sef");

    executable->setInitialMatchSelectionAsFile("../data/cat.xml");
    const char *output = executable->applyTemplatesReturningString();

    printf("%s", output);
    printf("result is OK \n");
    sresult->success++;
    operator delete((char *)output);

    fflush(stdout);
    delete executable;

  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error message =" << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testPackage1a");

    return;
  }
}

/*
 * Test saving and loading a Xslt package
 */
void testPackage2_Error(Xslt30Processor *trans, sResultCount *sresult) {

  cout << endl << "Test: testPackage2_Error:" << endl;

  const char *stylesheet =
      "<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' "
      "version='2.0'>       <xsl:param name='values' select='(2,3,4)' "
      "/><xsl:output method='xml' indent='yes' /><xsl:template "
      "match='*'><output><xsl:for-each select='$values' ><out><xsl:value-of "
      "select='. * "
      "3'/></out><xsl:for-each></output></xsl:template><xsl:stylesheet>";
  try {
    trans->compileFromStringAndSave(stylesheet, "test2.sef");
  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error message =" << message << endl;
    }
    sresult->success++;
    return;
  }

  cout << "Test failed - no error message produced" << endl;

  sresult->failure++;
  sresult->failureList.push_back("testPackage2_Error");
}

void testCallFunction(SaxonProcessor *proc, Xslt30Processor *trans,
                      sResultCount *sresult) {

  const char *source =
      "<?xml version='1.0'?> <xsl:stylesheet "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform' "
      "xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:f='http://localhost/' "
      "version='3.0'> <xsl:function name='f:add' visibility='public'>    "
      "<xsl:param name='a'/><xsl:param name='b'/> <xsl:sequence select='$a + "
      "$b'/></xsl:function></xsl:stylesheet>";
  cout << endl << "Test: testCallFunction:" << endl;

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromString(source);
  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }

    sresult->failure++;
    sresult->failureList.push_back("testCallFunction");
    return;
  }

  XdmValue **valueArray = new XdmValue *[2];

  valueArray[0] = (XdmValue *)(proc->makeIntegerValue(2));
  valueArray[1] = (XdmValue *)(proc->makeIntegerValue(3));
  XdmValue *v = nullptr;
  try {
    v = executable->callFunctionReturningValue("{http://localhost/}add",
                                               valueArray, 2);
    XdmItem *head1 = v->getHead();
    if (v != nullptr && head1 != nullptr && (head1)->isAtomic() &&
        ((XdmAtomicValue *)(head1))->getLongValue() == 5) {
      sresult->success++;
      delete head1;
      head1 = nullptr;
      delete v;

    } else {

      cout << "testCallFunction ======= FAIL -1 ======" << endl;

      sresult->failure++;
      sresult->failureList.push_back("testCallFunction");
    }
    delete valueArray[0];
    delete valueArray[1];
    delete[] valueArray;
    delete executable;

  } catch (SaxonApiException &e) {

    cout << "testCallFunction ======= FAIL ======" << endl;

    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "Error: " << emessage << endl;
    }

    sresult->failure++;
    sresult->failureList.push_back("testCallFunction");

    return;
  }
}

void testInitialTemplate(SaxonProcessor *proc, Xslt30Processor *trans,
                         sResultCount *sresult) {

  const char *source =
      "<?xml version='1.0'?>  <xsl:stylesheet "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  "
      "xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  "
      "<xsl:template match='*'>     <xsl:param name='a' as='xs:double'/>     "
      "<xsl:param name='b' as='xs:float'/>     <xsl:sequence select='., $a + "
      "$b'/>  </xsl:template>  </xsl:stylesheet>";
  cout << endl << "Test:testInitialTemplate" << endl;
  XsltExecutable *executable = trans->compileFromString(source);
  if (executable == nullptr) {
    if (trans->exceptionOccurred()) {
      cout << "Error: " << trans->getErrorMessage() << endl;
    }
    return;
  }
  XdmNode *node = proc->parseXmlFromString("<e/>");
  executable->setResultAsRawValue(false);
  std::map<std::string, XdmValue *> parameterValues;

  XdmAtomicValue *a1 = proc->makeIntegerValue(12);
  XdmAtomicValue *a2 = proc->makeIntegerValue(5);
  ;
  parameterValues["a"] = a1;
  parameterValues["b"] = a2;
  executable->setInitialTemplateParameters(parameterValues, false);
  executable->setInitialMatchSelection(node);
  XdmValue *result = executable->applyTemplatesReturningValue();
  if (result != nullptr) {
    XdmItem *itemResult = result->getHead();
    const char *resultStr = itemResult->getStringValue();
    sresult->success++;
    cout << "Result=" << resultStr << endl;
    delete result;
    delete itemResult;
    delete resultStr;
  } else {
    sresult->failure++;
    sresult->failureList.push_back("testInitialTemplate");
  }
  delete executable;
  delete a1;
  delete a2;
  delete node;
  parameterValues.clear();
}

void testResultDocumentAsMap(SaxonProcessor *proc, Xslt30Processor *trans,
                             sResultCount *sresult) {

  cout << endl << "Test: testResultDocumentAsMap:" << endl;

  XdmNode *inputDoc = proc->parseXmlFromString("<a>b</a>");

  XsltExecutable *executable = nullptr;
  try {
    executable = trans->compileFromString(
        "<xsl:stylesheet version='3.0' "
        "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
        "match='a'><xsl:result-document href='out.xml'><e>f</e> "
        "</xsl:result-document> <xsl:result-document "
        "href='out2.xml'><e>hello</e> "
        "</xsl:result-document></xsl:template></xsl:stylesheet>");

    executable->setCaptureResultDocuments(true);
    executable->setInitialMatchSelection(inputDoc);
    XdmValue *result = executable->applyTemplatesReturningValue();
    std::map<std::string, XdmValue *> &mmap = executable->getResultDocuments();

    if (mmap.size() == 2) {
      sresult->success++;
      map<string, XdmValue *>::iterator it;

      for (it = mmap.begin(); it != mmap.end(); it++) {
        const char *docStr = (it->second)->toString();
        cout << "Result doc: " << docStr << endl;
        operator delete((char *)docStr);
        delete (it->second);
      }
      mmap.clear();

    } else {
      sresult->failure++;
      sresult->failureList.push_back("testResultDocumentAsMap");
    }

    delete result;
    delete inputDoc;
    delete executable;
    return;

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testResultDocumentAsMap");
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error: " << message << endl;
    }
  }
}

void testResolveUri(SaxonProcessor *proc, Xslt30Processor *trans,
                    sResultCount *sresult) {
  cout << endl << "Test: testResolveUri:" << endl;

  XsltExecutable *executable = nullptr;

  try {
    executable = trans->compileFromString(
        "<xsl:stylesheet version='3.0' "
        "xmlns:xsl='http://www.w3.org/1999/XSL/Transform' "
        "xmlns:xs='http://www.w3.org/2001/XMLSchema' "
        "xmlns:err='http://www.w3.org/2005/xqt-errors'><xsl:template "
        "name='go'><xsl:try><xsl:variable name='uri' as='xs:anyURI' "
        "select=\"resolve-uri('notice trailing space /out.xml')\"/> "
        "<xsl:message select='$uri'/><xsl:result-document "
        "href='{$uri}'><out/></xsl:result-document><xsl:catch><xsl:sequence "
        "select=\"'$err:code: ' || $err:code  || ', $err:description: ' || "
        "$err:description\"/></xsl:catch></xsl:try></xsl:template></"
        "xsl:stylesheet>");

    XdmValue *value = executable->callTemplateReturningValue("go");

    if (value == nullptr || executable->exceptionOccurred()) {

      sresult->failure++;
      sresult->failureList.push_back("testResolveUri");
    } else {
      XdmItem *item1 = value->itemAt(0);
      if (item1 != nullptr) {
        const char *svalue = item1->getStringValue();
        if (svalue != nullptr) {
          cout << "testResolveUri = " << svalue << endl;
          delete svalue;
          svalue = nullptr;
          sresult->success++;
        }
        delete item1;
      } else {
        cout << "Error: testResolveUri item is nullptr " << endl;
        sresult->failure++;
        sresult->failureList.push_back("testResolveUri");
      }

      delete value;
    }

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testResolveUri");
    const char *message = e.getMessage();
    if (message != nullptr) {
      cout << "Error: " << message << endl;
    }
  }
  delete executable;
}

void testContextNotRoot(SaxonProcessor *proc, Xslt30Processor *trans,
                        sResultCount *sresult) {
  cout << endl << "Test: testContextNotRoot" << endl;

  XdmNode *node = proc->parseXmlFromString("<doc><e>text</e></doc>");

  XsltExecutable *executable = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable name='x' "
      "select='.'/><xsl:template match='/'>errorA</xsl:template><xsl:template "
      "match='e'>[<xsl:value-of "
      "select='name($x)'/>]</xsl:template></xsl:stylesheet>");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRoot");
    if (trans->exceptionOccurred()) {
      cout << "Error: " << trans->getErrorMessage() << endl;
    }
    return;
  }

  executable->setGlobalContextItem(node);
  int childCount = node->getChildCount();
  if (node != nullptr && childCount > 0) {
    XdmNode **eNodeL1 = node->getChildren();
    if (eNodeL1 != nullptr) {
      XdmNode **eNodeChildren = eNodeL1[0]->getChildren();
      if (eNodeChildren != nullptr) {
        int childCount2 = eNodeL1[0]->getChildCount();
        XdmNode *eNode = eNodeChildren[0];
        const char *eNodeStr = nullptr;
        eNodeStr = eNode->toString();
        if (eNodeStr != nullptr) {
          cout << "Node content = " << eNodeStr << endl;
          delete eNodeStr;
        }
        executable->setInitialMatchSelection(eNode);
        const char *result = executable->applyTemplatesReturningString();

        if (result == nullptr) {

          cout << "testContextNotRoot ======= FAIL ======" << endl;
          if (executable->exceptionOccurred()) {
            SaxonApiException *exception = executable->getException();
            cerr << "Error: " << exception->getMessage() << endl;
            delete exception;
          }
          sresult->failure++;
          sresult->failureList.push_back("testContextNotRoot");

        } else {

          cout << "testContextNotRoot = " << result << endl;
          sresult->success++;
          operator delete((char *)result);
        }
        for (int i = 0; i < childCount2; i++) {
          delete eNodeChildren[i];
          eNodeChildren[i] = nullptr;
        }
        delete[] eNodeChildren;
        eNodeChildren = nullptr;
      }
      for (int i = 0; i < childCount; i++) {
        delete eNodeL1[i];
        eNodeL1[i] = nullptr;
      }
      delete[] eNodeL1;
      eNodeL1 = nullptr;
    }
  } else {
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRoot");
  }

  delete executable;
  delete node;
}

void testContextNotRootNamedTemplate(SaxonProcessor *proc,
                                     Xslt30Processor *trans,
                                     sResultCount *sresult) {
  cout << endl << "Test: testContextNotRootNamedTemplate" << endl;

  XdmNode *node = proc->parseXmlFromString("<doc><e>text</e></doc>");

  if (node == nullptr) {
    if (proc->exceptionOccurred()) {
      const char *message = proc->getErrorMessage();
      if (message != nullptr) {
        cerr << "Error: " << message << endl;
      }
    }
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRootNamedTemplate");
    return;
  }

  XsltExecutable *executable = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable name='x' "
      "select='.'/><xsl:template match='/'>errorA</xsl:template><xsl:template "
      "name='main'>[<xsl:value-of "
      "select='name($x)'/>]</xsl:template></xsl:stylesheet>");

  if (executable == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRootNamedTemplate");
    if (trans->exceptionOccurred()) {
      cout << "Error: " << trans->getErrorMessage() << endl;
    }
    delete node;
    return;
  }

  executable->setGlobalContextItem(node);
  const char *result = executable->callTemplateReturningString("main");

  if (result == nullptr) {

    cout << "testContextNotRootNameTemplate ======= FAIL ======" << endl;
    if (executable->exceptionOccurred()) {
      SaxonApiException *exception = executable->getException();
      cerr << "Error: " << exception->getMessage() << endl;
      delete exception;
    }
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRootNamedTemplate");
  } else {

    cout << "testContextNotRoot = " << result << endl;
    sresult->success++;
    operator delete((char *)result);
  }
  delete node;
  delete executable;
}

void testContextNotRootNamedTemplateValue(SaxonProcessor *proc,
                                          Xslt30Processor *trans,
                                          sResultCount *sresult) {
  cout << endl << "Test: testContextNotRootNamedTemplateValue" << endl;

  XdmNode *node = nullptr;
  node = proc->parseXmlFromString("<doc><e>text</e></doc>");

  if (node == nullptr) {

    sresult->failure++;
    sresult->failureList.push_back("testContextNotRootNamedTemplateValue");
    return;
  }
  XsltExecutable *executable = nullptr;
  try {

    executable = trans->compileFromString(
        "<xsl:stylesheet version='2.0' "
        "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable "
        "name='x' select='.'/><xsl:template "
        "match='/'>errorA</xsl:template><xsl:template "
        "name='main'>[<xsl:value-of "
        "select='name($x)'/>]</xsl:template></xsl:stylesheet>");

    if (executable == nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("testContentNotRootNamedTemplateValue");

      delete node;
      return;
    }

    executable->setGlobalContextItem(node);
    XdmValue *result = executable->callTemplateReturningValue("main");

    if (result == nullptr) {

      cout << "testCallFunction ======= FAIL ======" << endl;

      sresult->failure++;
      sresult->failureList.push_back("testContextNotRootNamedTemplateValue");
    } else {
      XdmItem *item1 = result->getHead();
      const char *item1Str = item1->getStringValue();
      cout << "testContextNotRoot = " << item1Str << endl;
      sresult->success++;
      delete item1Str;
      delete item1;
      item1 = nullptr;
      item1Str = nullptr;
      delete result;
      result = nullptr;
    }

    delete node;
    delete executable;

  } catch (SaxonApiException &e) {
    cout << "Error: " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testContextNotRootNamedTemplateValue");
    if (node != nullptr) {
      delete node;
    }
    if (executable != nullptr) {
      delete executable;
    }
  }
}

void testCallSystemFunction(SaxonProcessor *proc, sResultCount *sresult) {

  cout << endl << "Test: testCallSystemFunction" << endl;

  XdmFunctionItem *fi = XdmFunctionItem::getSystemFunction(
      proc, "{http://www.w3.org/2005/xpath-functions}parse-json", 1);
  if (fi == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testCallSystemFunction");
    return;
  }

  XdmValue **xdmValue = new XdmValue *[1];
  xdmValue[0] = new XdmValue();
  xdmValue[0]->addXdmItem(proc->makeStringValue("[1,2,3]"));
  XdmValue *result = fi->call(proc, xdmValue, 1);

  if (result != nullptr) {

    std::cerr << "Result = " << result->toString() << "Size =" << result->size()
              << endl;
    if (result->size() == 1) {
      XdmItem *item = result->getHead();
      if (item != nullptr) {
        try {
          const char *itemStr = item->getStringValue();
          if (itemStr != nullptr) {
            cout << "testCallSystemFunction - should not pass here = "
                 << itemStr << endl;
            sresult->failure++;
            sresult->failureList.push_back("testCallSystemFunction");
            delete itemStr;
          }
        } catch (SaxonApiException &e) {
          cout << "Check exception is thrown: " << e.what() << endl;
        }
        cout << "item->getType() = " << (item->getType()) << endl;
        if (item->getType() == XDM_ARRAY) {
          sresult->success++;
          XdmArray *array = (XdmArray *)item;
          int arraySize = array->arrayLength();
          for (int i = 0; i < arraySize; i++) {
            XdmValue *avalue = array->get(i);
            if (avalue != nullptr) {
              XdmItem *aitem = avalue->getHead();
              const char *aitemStr = aitem->getStringValue();
              std::cout << "Array item  =" << aitemStr << std::endl;
              delete aitemStr;
              delete aitem;
              delete avalue;
            }
          }
        } else {
          sresult->failure++;
          sresult->failureList.push_back("testCallSystemFunctionA");
        }

        delete item;
        delete result;
        delete xdmValue[0];
        delete[] xdmValue;
        delete fi;
        return;
      }

    } else {
      sresult->failure++;
      sresult->failureList.push_back("testCallSystemFunction");
    }
  }
  delete xdmValue[0];
  delete[] xdmValue;
  delete fi;
  sresult->failure++;
  sresult->failureList.push_back("testCallSystemFunction");
}

void testPipeline(SaxonProcessor *proc, sResultCount *sresult) {
  cout << endl << "Test: testPipeline" << endl;

  Xslt30Processor *trans = proc->newXslt30Processor();
  if (trans == nullptr) {
    cout << "Error: Xslt30Processor is null - maybe unclean state of JNI"
         << endl;
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");
    return;
  }
  XsltExecutable *stage1 = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "match='/'><a><xsl:copy-of "
      "select='.'/></a></xsl:template></xsl:stylesheet>");

  if (stage1 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");

    cout << "Stage 1 Error - exit method " << endl;
    delete trans;
    return;
  }

  XdmNode *inn = proc->parseXmlFromString("<z/>");

  XsltExecutable *stage2 = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "match='/'><a><xsl:copy-of "
      "select='.'/></a></xsl:template></xsl:stylesheet>");

  if (stage2 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");
    cout << "Stage 2 Error - exit method " << endl;
    delete stage1;
    delete trans;
    delete inn;
    return;
  }

  XsltExecutable *stage3 = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "match='/'><a><xsl:copy-of "
      "select='.'/></a></xsl:template></xsl:stylesheet>");

  if (stage3 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");
    cout << "Stage 3 Error - exit method " << endl;
    delete stage1;
    delete stage2;
    delete trans;
    delete inn;
    return;
  }

  XsltExecutable *stage4 = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "match='/'><a><xsl:copy-of "
      "select='.'/></a></xsl:template></xsl:stylesheet>");

  if (stage4 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");
    cout << "Stage 4 Error - exit method " << endl;
    delete stage1;
    delete stage2;
    delete stage3;
    delete trans;
    delete inn;
    return;
  }

  XsltExecutable *stage5 = trans->compileFromString(
      "<xsl:stylesheet version='2.0' "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template "
      "match='/'><a><xsl:copy-of "
      "select='.'/></a></xsl:template></xsl:stylesheet>");

  if (stage5 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");

    cout << "Stage 5     Error - exit method " << endl;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete trans;
    delete inn;
    return;
  }

  stage1->setProperty("!indent", "no");
  stage1->setInitialMatchSelection(inn);

  XdmValue *d1 = stage1->applyTemplatesReturningValue();
  if (d1 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline");

    cout << "Stage d1 Error - exit method " << endl;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete trans;
    delete inn;
    return;
  }

  XdmItem *d11 = d1->getHead();
  if (d11 == nullptr) {

    cout << "d11 is NULL\n" << endl;
    sresult->failure++;
    sresult->failureList.push_back("testPipeline-1");
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete d1;
    delete inn;
    delete trans;
    return;
  }
  const char *data = d11->toString();

  if (data != nullptr) {
    cout << "d1 result=" << data << endl;
    operator delete((char *)data);
    data = nullptr;
  } else {

    cout << "d1 result Error - toString is NULL" << endl;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete d1;
    delete d11;
    delete inn;
    delete trans;
    return;
  }
  stage2->setProperty("!indent", "no");
  stage2->setInitialMatchSelection(d11);
  XdmValue *d2 = stage2->applyTemplatesReturningValue();
  if (d2 == nullptr) {
    cout << "ERROR-11\n" << endl;
    sresult->failure++;
    sresult->failureList.push_back("testPipeline-2");

    cout << "Stage d2 Error - exit method " << endl;
    delete d1;
    delete inn;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete trans;
    return;
  } else {
    const char *data2 = d2->toString();
    cout << "d2 result=" << data2 << endl;
    operator delete((char *)data2);
    data2 = nullptr;
  }
  delete d11;
  stage3->setProperty("!indent", "no");
  stage3->setInitialMatchSelection(d2);
  XdmValue *d3 = stage3->applyTemplatesReturningValue();
  if (d3 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline-3");

    cout << "Stage d3 Error - exit method " << endl;
    delete d1;
    delete d2;
    delete inn;

    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete trans;
    return;
  }
  stage4->setProperty("!indent", "no");
  stage4->setInitialMatchSelection(d3);
  XdmValue *d4 = stage4->applyTemplatesReturningValue();
  if (d4 == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline-4");

    cout << "Stage d4 Error - exit method " << endl;
    delete d3;
    delete d2;
    delete d1;
    delete inn;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete trans;
    return;
  }
  stage5->setProperty("!indent", "no");
  stage5->setInitialMatchSelection(d4);
  const char *sw = stage5->applyTemplatesReturningString();
  if (sw == nullptr) {
    sresult->failure++;
    sresult->failureList.push_back("testPipeline-5");

    cout << "Stage sw Error - exit method " << endl;
    delete stage1;
    delete stage2;
    delete stage3;
    delete stage4;
    delete stage5;
    delete trans;
    delete d4;
    delete d3;
    delete d2;
    delete d1;
    delete inn;
    return;
  }
  cout << sw << endl;
  cout << "testPipeline = " << sw << endl;
  sresult->success++;
  delete stage1;
  stage1 = nullptr;

  delete stage2;
  stage2 = nullptr;

  delete stage3;
  stage3 = nullptr;

  delete stage4;
  stage4 = nullptr;

  delete stage5;
  stage5 = nullptr;

  delete trans;
  trans = nullptr;

  operator delete((char *)sw);
  sw = nullptr;

  delete d4;
  d4 = nullptr;

  delete d3;
  d3 = nullptr;

  delete d2;
  d2 = nullptr;

  delete d1;
  d1 = nullptr;

  delete inn;
  inn = nullptr;
}

void testCatalog(const char *cwd, SaxonProcessor *proc, sResultCount *sresult) {

#ifdef MEM_DEBUG
  SaxonProcessor::getInfo();
#endif
  cout << endl << "Test: testCatalog" << endl;
  bool trace = false;
  proc->setcwd(cwd);
  XsltExecutable *executable = nullptr;
  Xslt30Processor *trans = nullptr;
  const char **catalogFiles = nullptr;
  try {
    catalogFiles = new const char *[1] { "../data/catalog.xml" };

    proc->setCatalogFiles(catalogFiles, 1);

    trans = proc->newXslt30Processor();

    executable = trans->compileFromFile("../data/example.xsl");

    executable->setInitialMatchSelectionAsFile("../data/example.xml");

    const char *result = executable->applyTemplatesReturningString();

    if (result != NULL) {
      std::cerr << "testCatalog result= " << result << std::endl;
      operator delete((char *)result);
      sresult->success++; // TODO - check the results more carefully
    } else {
      sresult->failure++;
      sresult->failureList.push_back("testCatalog-1");
    }
    if (executable != nullptr) {
      delete executable;
    }
    executable = nullptr;
    if (trans != nullptr) {
      delete trans;
    }
    trans = nullptr;

    delete[] catalogFiles;
    catalogFiles = nullptr;

  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "exception-proc=" << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testCatalog");
    if (executable != nullptr) {
      delete executable;
      executable = nullptr;
    }

    if (trans != nullptr) {
      delete trans;
    }
    if (catalogFiles != nullptr) {
      delete[] catalogFiles;
      catalogFiles = nullptr;
    }
  }
}

void testCatalog2(const char *cwd, SaxonProcessor *proc,
                  sResultCount *sresult) {

#ifdef MEM_DEBUG
  SaxonProcessor::getInfo();
#endif
  cout << endl << "Test: testCatalog2" << endl;
  bool trace = false;
  proc->setcwd(cwd);
  XsltExecutable *executable = nullptr;
  XsltExecutable *executable2 = nullptr;
  Xslt30Processor *trans = nullptr;
  const char **catalogFiles = nullptr;
  try {
    catalogFiles =
        new const char *[2] { "../data/catalog.xml", "../data/catalog2.xml" };

    proc->setCatalogFiles(catalogFiles, 2);
    proc->setcwd(cwd);
    trans = proc->newXslt30Processor();

    trans->setcwd(cwd);

    executable2 = trans->compileFromFile("http://example.com/books.xsl");

    executable2->setInitialMatchSelectionAsFile("../data/books.xml");
    executable2->setGlobalContextFromFile("../data/books.xml");

    XdmValue *resultValue = executable2->applyTemplatesReturningValue();
    if (resultValue != nullptr) {
      XdmItem *item1 = resultValue->getHead();
      const char *result2 = item1->getStringValue();
      std::cerr << "testCatalog result= " << result2 << std::endl;
      delete result2;
      delete item1;
      sresult->success++; // TODO - check the results more carefully
      delete resultValue;
    } else {
      sresult->failure++;
      sresult->failureList.push_back("testCatalog2-1");
    }
    delete executable2;
    delete[] catalogFiles;
    catalogFiles = nullptr;
    if (trans != nullptr) {
      delete trans;
    }
    trans = nullptr;

  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "exception-proc=" << message << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testCatalog2");

    if (executable2 != nullptr) {
      delete executable2;
      executable2 = nullptr;
    }

    if (trans != nullptr) {
      delete trans;
    }

    if (catalogFiles != nullptr) {
      delete[] catalogFiles;
      catalogFiles = nullptr;
    }
  }
}

void testCatalogError(const char *cwd, SaxonProcessor *proc,
                      sResultCount *sresult) {

#ifdef MEM_DEBUG
  SaxonProcessor::getInfo();
#endif
  cout << endl << "Test: testCatalogError" << endl;
  bool trace = false;
  proc->setcwd(cwd);
  XsltExecutable *executable = nullptr;
  Xslt30Processor *trans = nullptr;
  const char **catalogFiles = nullptr;
  try {
    catalogFiles = new const char *[1] { "../data/catalog-err.xml" };

    proc->setCatalogFiles(catalogFiles, 1);

    trans = proc->newXslt30Processor();

    executable = trans->compileFromFile("../data/example.xsl");

    executable->setInitialMatchSelectionAsFile("../data/example.xml");

    const char *result = executable->applyTemplatesReturningString();

    if (result != NULL) {
      std::cerr << "testCatalog result= " << result << std::endl;
      operator delete((char *)result);
      sresult->failureList.push_back("testCatalogError");
    } else {

      sresult->failureList.push_back("testCatalog-err-1");
    }
    sresult->failure++;
    if (executable != nullptr) {
      delete executable;
    }
    executable = nullptr;
    if (trans != nullptr) {
      delete trans;
    }
    trans = nullptr;

    delete[] catalogFiles;
    catalogFiles = nullptr;

  } catch (SaxonApiException &e) {
    const char *message = e.getMessage();
    if (message != nullptr) {
      cerr << "Expected exception-proc=" << message << endl;
    }
    sresult->success++;

    if (executable != nullptr) {
      delete executable;
      executable = nullptr;
    }

    if (trans != nullptr) {
      delete trans;
    }
    if (catalogFiles != nullptr) {
      delete[] catalogFiles;
      catalogFiles = nullptr;
    }
  }
}

void testSaxSourceNoSystemId(SaxonProcessor *proc, DocumentBuilder *builder,
                             sResultCount *sresult) {

  cout << endl << "Test: testSaxSourceNoSystemId" << endl;
  // DocumentBuilder * builder = proc->newDocumentBuilder();
  try {
    XdmNode *d = builder->parseXmlFromString("<doc/>");

    if (d != nullptr) {
      if (d->getBaseUri() != nullptr) {
        std::cout << "BaseUri:" << d->getBaseUri() << endl;
      }
      delete d;
      sresult->success++;
    }
    delete builder;
  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "exception=" << emessage << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back("testSaxSourceNoSystemId");
  }
}

void testSaxSource(SaxonProcessor *proc, sResultCount *sresult) {

  cout << endl << "Test: testSaxSource" << endl;
  DocumentBuilder *builder = proc->newDocumentBuilder();
  builder->setBaseUri("https://www.example.com");
  XdmNode *d = builder->parseXmlFromString("<doc/>");
  fflush(stdout);
  if (d != nullptr) {
    if (d->getBaseUri() != nullptr) {
      std::cout << "BaseUri:" << d->getBaseUri() << endl;
    }
    delete d;
    sresult->success++;
  } else {
    sresult->failure++;
    sresult->failureList.push_back("testSaxSource");
  }

  delete builder;
}

void testSaxSourceDTDValidation(SaxonProcessor *proc, sResultCount *sresult) {
  std::string validXML = "<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>";
  std::string invalidXML = "<!DOCTYPE a [<!ELEMENT a (b+)>]><a/>";
  cout << endl << "Test: testSaxSourceDTDValidation" << endl;
  DocumentBuilder *builder = proc->newDocumentBuilder();
  builder->setDTDValidation(true);
  XdmNode *d = nullptr;
  try {
    d = builder->parseXmlFromString(validXML.c_str());

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testSaxSourceDTDValidation");
  }
  if (d != nullptr) {
    delete d;

  } else {

    sresult->failure++;
    sresult->failureList.push_back("testSaxSourceDTDValidation-1");
    delete builder;
    return;
  }
  try {
    d = builder->parseXmlFromString(invalidXML.c_str());
    sresult->failure++;
    sresult->failureList.push_back("testSaxSourceDTDValidation-2");
    delete d;
    delete builder;
    return;
  } catch (SaxonApiException &e) {
    builder->exceptionClear();
  }

  try {
    builder->setDTDValidation(false);
    d = builder->parseXmlFromString(invalidXML.c_str());

    delete d;
    sresult->success++;

  } catch (SaxonApiException &e) {
    sresult->failure++;
    sresult->failureList.push_back("testSaxSourceDTDValidation-3");
  }

  delete builder;
  return;
}

void testAssociatedError(SaxonProcessor *proc, Xslt30Processor *trans,
                         sResultCount *sresult) {
  try {
    cerr << endl << "testAssociatedError test" << endl;
    XsltExecutable *executable =
        trans->compileFromAssociatedFile("data-error/trax/xml/foo.xml");
    sresult->failure++;
    sresult->failureList.push_back("testAssociatedError");
  } catch (SaxonApiException &e) {
    const char *emessage = e.getMessage();
    if (emessage != nullptr) {
      cerr << "exception=" << emessage << endl;
    } else {
      cerr << "exception is nullptr" << endl;
      sresult->failure++;
      sresult->failureList.push_back("testAssociatedError");
      return;
    }
    sresult->success++;
  }
}

void testUTF8StringTemplate(SaxonProcessor *proc, Xslt30Processor *trans,
                            sResultCount *sresult) {

  const char *source =
      "<?xml version='1.0' encoding='UTF8'?>  <xsl:stylesheet "
      "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  "
      "xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  "
      "<xsl:template match='*'>     <xsl:sequence select='&apos;تيست&apos;'/>  "
      "</xsl:template>  </xsl:stylesheet>";
  cout << endl << "Test:testUTF8StringTemplate" << endl;
  XsltExecutable *executable = trans->compileFromString(source);
  if (executable == nullptr) {
    if (trans->exceptionOccurred()) {
      cout << "Error: " << trans->getErrorMessage() << endl;
    }
    return;
  }
  const char *_in = "<?xml version='1.0' encoding='UTF8'?><e>تيست</e>";
  XdmNode *node = proc->parseXmlFromString(_in);
  executable->setResultAsRawValue(false);
  std::map<std::string, XdmValue *> parameterValues;

  executable->setInitialTemplateParameters(parameterValues, false);
  executable->setInitialMatchSelection(node);
  XdmValue *result = executable->applyTemplatesReturningValue();
  if (result != nullptr) {
    sresult->success++;
    cout << "Input=" << _in;
    XdmItem *head = result->getHead();
    const char *headStr = head->getStringValue();
    const char *nodeStr = node->toString();
    cout << "Result=" << headStr << endl << nodeStr << endl;
    delete result;
    operator delete((char *)headStr);
    operator delete((char *)nodeStr);
    delete head;
  } else {
    sresult->failure++;
    sresult->failureList.push_back("testUTF8StringTemplate");
  }
  delete executable;
  delete node;
  parameterValues.clear();
}

static int NUM_THREADS = 10;

void RunThread(XsltExecutable *executable, int tid,
               const std::string filename) {
  /*JavaVMAttachArgs att_arg;
  att_arg.version = JNI_VERSION_1_2;
  att_arg.name = NULL;
  att_arg.group = NULL;*/

  // SaxonProcessor::sxn_environ->jvm->AttachCurrentThread((void**)&SaxonProcessor::sxn_environ->env,
  // NULL);
  cerr << endl << "RunThread cp0,  THEAD ID=" << tid << endl;
  fflush(stderr);
  fflush(stdout);

  if (executable != nullptr) {
    executable->setInitialMatchSelectionAsFile(filename.c_str());

    cerr << "RunThread cp1" << endl;

    const char *result = nullptr;
    result = executable->applyTemplatesReturningString();
    if (result != nullptr) {
      cout << " Result from THREAD ID: " << tid << ", " << result << endl;
      operator delete((char *)result);
    } else {
      cerr << " ===== Failed in THREAD ID: " << tid << endl;
    }
    delete executable;
  } else {
    cerr << "XsltExecutable is nullptr" << endl;
  }

  //  (   SaxonProcessor::sxn_environ->jvm)->DetachCurrentThread();
}

void testThreads(SaxonProcessor *processor, Xslt30Processor *trans,
                 sResultCount *sresult) {

  std::vector<std::string> s = {"../data/xmark100k.xml", "../data/xmark1.xml",
                                "../data/xmark4.xml", "../data/xmark10.xml"};

  std::vector<std::thread> threads;

  for (int i = 0; i < s.size(); i++) {

    XsltExecutable *executable = trans->compileFromFile("../data/q12.xsl");
    if (executable == nullptr) {
      continue;
    }
    threads.push_back(std::thread(RunThread, executable, i, s[i]));
  }

  for (auto &th : threads) {
    th.join();
    cerr << "testThreads cp1 - loop" << endl;
  }
}

int main(int argc, char *argv[]) {

  const char *cwd = nullptr;
  if (argc > 1) {
    cwd = argv[1];
  }
  int check = 0;

  SaxonProcessor *processor = new SaxonProcessor(true);
  // setDebugMode(SaxonProcessor::sxn_environ->thread, 1);

  cout << "Test: Xslt30Processor with Saxon version=" << processor->version()
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

  if (processor->isSchemaAwareProcessor()) {

    std::cerr << "Processor is Schema Aware" << std::endl;
  } else {
    std::cerr << "Processor is not Schema Aware" << std::endl;
  }

  sResultCount *sresult = new sResultCount();

  Xslt30Processor *trans = processor->newXslt30Processor();

  if (trans == nullptr) {
    if (processor->exceptionOccurred()) {
      cout << "Error message: " << processor->getErrorMessage() << endl;
    }
    return -1;
  }
  // testValidation(trans,sresult);

  testInitialTemplate(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple1Err(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testAssociatedError(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple1(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple_xmark(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple2(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleTransformToFile(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleTransformToString(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testUTF8StringTemplate(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testPackageExport(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple3(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleSimple3aError(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testApplyTemplatesString1(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testApplyTemplatesString2(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testApplyTemplates2a_Error(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTransformToString4(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testCatalog(cwd, processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testCatalog2(cwd, processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testCatalogError(cwd, processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTransformToString2b(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTransformToString3(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTransformFromstring(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTransformFromstring2Err(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTrackingOfValueReference(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testTrackingOfValueReferenceError(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testPackage1(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testPackage1a(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testPackage2_Error(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testXdmNodeOutput(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  exampleParam(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  xmarkTest1(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  xmarkTest2(trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testCallFunction(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testResolveUri(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testResultDocumentAsMap(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testContextNotRoot(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testContextNotRootNamedTemplate(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testContextNotRootNamedTemplateValue(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testPipeline(processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  try {
    DocumentBuilder *builder = processor->newDocumentBuilder();
    testSaxSourceNoSystemId(processor, builder, sresult);
  } catch (SaxonApiException &e) {
    cerr << e.what() << endl;
  }

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testSaxSource(processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testSaxSourceDTDValidation(processor, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testContext2NotRootNamedTemplate(processor, trans, sresult);

  cout << endl
       << "============================================================="
       << endl
       << endl;

  testCallSystemFunction(processor, sresult);

  fflush(stdout);

  // Available in PE and EE
  testTransformToStringExtensionFunc(cwd, processor, trans, sresult);

  // processor->release();
  // return 0;

  fflush(stdout);

  Xslt30Processor *trans2 = processor->newXslt30Processor();

  testApplyTemplatesString1(trans2, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;

  // testThreads (processor, trans2, sresult);

  delete trans;
  delete trans2;
  delete processor;
  processor->release();
  delete SaxonProcessor::sxn_environ;

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
