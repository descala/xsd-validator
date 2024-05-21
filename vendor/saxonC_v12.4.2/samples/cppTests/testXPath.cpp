#include "../../Saxon.C.API/SaxonProcessor.h"
#include "../../Saxon.C.API/XdmItem.h"
#include "../../Saxon.C.API/XdmNode.h"
#include "../../Saxon.C.API/XdmValue.h"
#include "CppTestUtils.h"
#include <string>

using namespace std;

// Test case on the evaluate method in XPathProcessor. Here we test that we have
// more than one XdmItem.
void testXPathSingle(SaxonProcessor *processor, XPathProcessor *xpath,
                     sResultCount *sresult) {

  cout << endl << "Test testXPathSingle:" << endl;
  XdmNode *input =
      processor->parseXmlFromString("<out><person>text1</person><person>text2</"
                                    "person><person>text3</person></out>");

  xpath->setContextItem((XdmItem *)input);
  try {
    XdmItem *result = xpath->evaluateSingle("//person[1]");
    const char *messagei = result->getStringValue();
    cout << "Number of items=" << result->size() << endl;
    cout << "String Value of result=" << messagei << endl;
    sresult->success++;
    operator delete((char *)messagei);
    delete result;
  } catch (SaxonApiException &e) {
    cout << "Error Message = " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testXPathSingle");
  }

  xpath->clearParameters();
  xpath->clearProperties();
  delete input;
}

void testUnprefixedElementMatchingPolicy(SaxonProcessor *processor,
                                         XPathProcessor *xpath,
                                         sResultCount *sresult) {

  cout << endl << "Test testUnprefixedElementMatchingPolicy:" << endl;
  XdmNode *node = processor->parseXmlFromString(
      "<out xmlns:my='http://www.example.com/ns/various' "
      "xmlns:f='http://www.example.com/ns/various1' "
      "xmlns='http://www.example.com'><f:person>text1</"
      "f:person><f:person>text2</"
      "f:person><person>wrong person selected</person></out>");
  xpath->setContextItem((XdmItem *)node);
  try {

    XdmItem *result = xpath->evaluateSingle("//*:person[1]");
    if (result == nullptr) {
      sresult->failure++;
      sresult->failureList.push_back("testUnprefixedElementMatchingPolicy");
    } else {
      const char *resultStr = result->getStringValue();
      if (strcmp(resultStr, "incorrect") == 0) {
        cout << "Failed to find  //f:person[1] without prefix. See result "
                "found: "
             << resultStr << endl;
        delete result;
        operator delete((char *)resultStr);

        sresult->failure++;
        sresult->failureList.push_back("testUnprefixedElementMatchingPolicy");

      } else {
        const char *resultStr = result->getStringValue();
        cout << "String Value of result=" << resultStr << endl;
        sresult->success++;
        delete result;
        operator delete((char *)resultStr);
      }
    }
  } catch (SaxonApiException &e) {
    cout << "Error Message = " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testUnprefixedElementMatchingPolicy");
  }

  xpath->clearParameters();
  xpath->clearProperties();

  delete node;
}

// test nodeAxis
void testNodeAxis(SaxonProcessor *processor, XPathProcessor *xpath,
                  sResultCount *sresult) {

  cout << endl << "Test testNodeAxis:" << endl;
  XdmNode *node = processor->parseXmlFromString(
      "<out xmlns:my='http://www.example.com/ns/various' "
      "xmlns:f='http://www.example.com/ns/various1' "
      "xmlns='http://www.example.com'><person>text1</person><person>text2</"
      "person></out>");

  try {
    int childCountA = node->getChildCount();
    XdmNode **childrenA = node->getChildren();
    XdmNode *child = childrenA[0];
    XdmNode **children = child->axisNodes(EnumXdmAxis::CHILD);
    int childCount = child->axisNodeCount();
    //     cout<< "node type="<<((node->getChildren()[0]_->toString())<<endl;
    cout << " child count = " << childCount << endl;
    for (int i = 0; i < childCount; i++) {
      cout << "child-Node type = " << (children[i]->getType()) << endl;
      const char *childStr = children[i]->toString();
      cout << "child node:" << (childStr) << endl;
      operator delete((char *)childStr);
    }
    XdmNode **namespaces = child->axisNodes(EnumXdmAxis::NAMESPACE);
    int namespaceCount = child->axisNodeCount();

    cout << "namespace count=" << namespaceCount << endl;
    for (int i = 0; i < namespaceCount; i++) {
      if (namespaces[i]->getNodeName() != nullptr) {
        cout << "namespace name =" << (namespaces[i]->getNodeName()) << endl;
      }
      const char *namespaceStr = namespaces[i]->getStringValue();
      cout << "namespace value =" << (namespaceStr) << endl;
      operator delete((char *)namespaceStr);
    }
    for (int i = 0; i < childCount; i++) {
      delete children[i];
    }
    delete[] children;
    for (int i = 0; i < namespaceCount; i++) {
      delete namespaces[i];
    }
    for (int i = 0; i < childCountA; i++) {
      delete childrenA[i];
    }
    delete[] childrenA;
    delete[] namespaces;
  } catch (SaxonApiException &e) {
    cout << "Error Message = " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testNodeAxis");
  }

  xpath->clearParameters();
  xpath->clearProperties();

  delete node;
  sresult->success++;
}

// Test case on the evaluate method in XPathProcessor. Here we test that we have
// more than one XdmItem.
void testXPathValues(SaxonProcessor *processor, XPathProcessor *xpath,
                     sResultCount *sresult) {
  cout << endl << "Test testXPathValues:" << endl;
  xpath->clearParameters();
  xpath->clearProperties();
  try {
    XdmNode *input = processor->parseXmlFromString(
        "<out><person>text1</person><person>text2</person><person1>text3</"
        "person1></out>");
    if (input == nullptr) {

      sresult->failure++;
      sresult->failureList.push_back("testXPathValues");

      return;
    }

    XdmNode **children = input->getChildren();
    XdmNode **children0 = children[0]->getChildren();

    int num = children[0]->getChildCount();

    for (int i = 0; i < num; i++) {
      if (children0[i] == nullptr) {
        sresult->failure++;
        sresult->failureList.push_back("testXPathValues-1");
        return;
      }
      if (children0[i]->getNodeName() != nullptr) {
        cout << "node name:" << children0[i]->getNodeName() << endl;
      }
    }

    for (int i = 0; i < children[0]->getChildCount(); i++) {
      delete children0[i];
    }
    delete[] children0;

    for (int i = 0; i < input->getChildCount(); i++) {
      delete children[i];
    }

    delete[] children;

    xpath->setContextItem((XdmItem *)input);
    XdmValue *resultValues = xpath->evaluate("//person");
    if (resultValues == nullptr) {
      printf("result is null \n");

      sresult->failure++;
      sresult->failureList.push_back("testXPathValues");

    } else {
      cout << "Number of items=" << resultValues->size() << endl;
      bool nullFound = false;
      for (int i = 0; i < resultValues->size(); i++) {
        XdmItem *itemi = resultValues->itemAt(i);
        if (itemi == nullptr) {
          cout << "Item at position " << i << " should not be null" << endl;
          nullFound = true;
          break;
        }
        const char *itemiStr = itemi->getStringValue();
        cout << "Item at " << i << " =" << itemiStr << endl;
        operator delete((char *)itemiStr);
        delete itemi;
      }
      delete resultValues;
      if (!nullFound) {
        sresult->success++;
      } else {
        sresult->failure++;
        sresult->failureList.push_back("testXPathValues");
      }
    }
    delete input;
    xpath->clearParameters();
    xpath->clearProperties();
  } catch (SaxonApiException &e) {
    cout << "Exception found = " << e.what() << endl;
    sresult->failure++;
    sresult->failureList.push_back("testXPathValues");
  }
}

// Test case on the evaluate method in XPathProcessor. Here we test that we have
// morethan one XdmItem.
void testXPathAttrValues(SaxonProcessor *processor, XPathProcessor *xpath,
                         sResultCount *sresult) {
  cout << endl << "Test testXPathValues1:" << endl;
  xpath->clearParameters();
  xpath->clearProperties();
  try {
    XdmNode *input = processor->parseXmlFromString(
        "<out attr='valuex'><person attr1='value1' "
        "attr2='value2'>text1</person><person>text2</person><person1>text3</"
        "person1></out>");
    if (input == nullptr) {

      sresult->failure++;
      sresult->failureList.push_back("testXPathAttrValues");

      return;
    }

    // cout<<"Name of attr1= "<<input->getAttributeValue("attr")<<endl;

    xpath->setContextItem((XdmItem *)input);
    XdmItem *result = xpath->evaluateSingle("(//person)[1]");
    delete input;
    input = nullptr;
    if (result == nullptr) {
      printf("result is null \n");
    } else {
      XdmNode *nodeValue = (XdmNode *)result;
      cout << "Attribute Count= " << nodeValue->getAttributeCount() << endl;
      const char *attrVal = nodeValue->getAttributeValue("attr1");
      if (attrVal != nullptr) {
        cout << "Attribute value= " << attrVal << endl;
        operator delete((char *)attrVal);
      }

      XdmNode **attrNodes = nodeValue->getAttributeNodes();
      if (attrNodes == nullptr) {
        return;
      }

      const char *name1 = attrNodes[0]->getNodeName();
      if (name1 != nullptr) {
        cout << "Name of attr1= " << name1 << endl;
      }
      XdmNode *parent = attrNodes[0]->getParent();
      if (parent != nullptr) {
        cout << "Name of parent= " << parent->getNodeName() << endl;
      }
      XdmNode *parent1 = parent->getParent();
      if (parent1 != nullptr) {
        cout << "Name of parent= " << parent1->getNodeName() << endl;
        delete parent1;
      }
      sresult->success++;
      int attrSize = nodeValue->getAttributeCount();
      for (int i = 0; i < attrSize; i++) {
        delete attrNodes[i];
      }
      delete[] attrNodes;
      delete result;
    }

  } catch (SaxonApiException &e) {

    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;

    sresult->failure++;
    sresult->failureList.push_back("testXPathAttrValues");
  }
}

void testXPathValues2(SaxonProcessor *processor, XPathProcessor *xpath,
                      sResultCount *sresult) {

  cout << endl << "Test testXPathValues2:" << endl;
  try {
    XdmValue *resultValues = xpath->evaluate(
        "1, 'string', true(), parse-xml-fragment(string-join((1 to 3) ! "
        "('<item>' || . || '</item>')))/node(), array { 1 to 5 }, map { 'key1' "
        ": 1, 'key2' : 'foo' }");

    if (resultValues == nullptr) {
      printf("result is null \n");

      sresult->failure++;
      sresult->failureList.push_back("testXPathValues2");

    } else {
      cout << "Number of items=" << resultValues->size() << endl;
      const char *resultStr = resultValues->toString();
      if (resultStr != nullptr) {
        cout << "toString()=" << resultStr << endl;
        operator delete((char *)resultStr);
      }
    }
    delete resultValues;
  } catch (SaxonApiException &e) {

    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;

    sresult->failure++;
    sresult->failureList.push_back("testXPathAttrValues2");
  }
}

// Test case on the evaluate method in XPathProcessor. Here we test that we have
// morethan one XdmItem.
void testXPathOnFile(SaxonProcessor *processor, XPathProcessor *xpath,
                     sResultCount *sresult) {
  cout << endl << "testXPathOnFile: Test testXPath with file source:" << endl;
  xpath->clearParameters();
  xpath->clearProperties();
  xpath->setContextFile("../data/cat.xml");

  try {
    XdmValue *resultValues = xpath->evaluate("//person");

    if (resultValues == nullptr) {
      printf("result is null \n");

      sresult->failure++;
      sresult->failureList.push_back("testXPathOnFile");
    } else {
      cout << "Number of items=" << resultValues->size() << endl;
      for (int i = 0; i < resultValues->size(); i++) {
        XdmItem *itemi = resultValues->itemAt(i);
        if (itemi == nullptr) {
          cout << "Item at position " << i << " should not be null" << endl;
          break;
        }
        const char *itemiStr = itemi->getStringValue();
        cout << "Item at " << i << " =" << itemiStr << endl;
        operator delete((char *)itemiStr);
        delete itemi;
      }
    }
    delete resultValues;

  } catch (SaxonApiException &e) {

    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;

    sresult->failure++;
    sresult->failureList.push_back("testXPathOnFile");
  }
}

// Test case on the evaluate method in XPathProcessor. Here we test that we have
// morethan one XdmItem.
void testXPathOnFile2(XPathProcessor *xpath, sResultCount *sresult) {
  cout << endl << "Test testXPath with file source-2:" << endl;
  xpath->clearParameters();
  xpath->clearProperties();
  xpath->setContextFile("../data/cat.xml");
  try {
    XdmItem *result = xpath->evaluateSingle("//person[1]");

    if (result == nullptr) {
      printf("result is null \n");

      sresult->failure++;
      sresult->failureList.push_back("testXPathOnFile2");
      return;
    } else {
      cout << "Number of items=" << result->size() << endl;
      if (result->isAtomic()) {
        cout << "XdmItem is atomic - Error" << endl;
      } else {
        cout << "XdmItem is not atomic" << endl;
      }
      XdmNode *node = (XdmNode *)result;
      if (node->getNodeKind() == ELEMENT) {
        cout << "Result is a ELEMENT" << endl;
        cout << "Node name: " << node->getNodeName() << endl;
      } else {
        cout << "Node is of kind:" << node->getNodeKind() << endl;
      }
      const char *baseURI = node->getBaseUri();
      if (baseURI != nullptr) {
        cout << "baseURI of node: " << baseURI << endl;
      }
      sresult->success++;
    }
    delete result;

  } catch (SaxonApiException &e) {

    const char *message = e.getMessage();
    cout << "Error Message = " << message << endl;

    sresult->failure++;
    sresult->failureList.push_back("testXPathOnFile2");
  }
}

XdmValue *good(XPathProcessor *xpath, sResultCount *sresult, XdmNode *document,
               const char *expr) {
  try {
    xpath->setContextItem(document);
    XdmValue *result = xpath->evaluate(expr);
    sresult->success++;
    return result;
  } catch (SaxonApiException &e1) {
    return nullptr;
  }
}

void bad(const char *testName, XPathProcessor *xpath, sResultCount *sresult,
         XdmNode *document, const char *expr) {
  try {
    xpath->setContextItem(document);
    XdmValue *result = xpath->evaluate(expr);
    sresult->failure++;
    sresult->failureList.push_back(testName);
    delete result;
    return;
  } catch (SaxonApiException &e1) {
    sresult->success++;
  }
}

void runTest(const char *testName, const char *expr, const char *expectedResult,
             XPathProcessor *xpath, sResultCount *sresult, XdmNode *document) {
  cout << endl << "Test " << testName << endl;
  XdmValue *result = good(xpath, sresult, document, expr);
  const char *resultStr = result->toString();
  if (result != nullptr &&
      CppTestUtils::assertEquals(expectedResult, resultStr)) {
    sresult->success++;
    operator delete((char *)resultStr);
    delete result;
  } else {
    if (result != nullptr) {
      cout << "Failed result=" << result->toString() << endl;
    }
    sresult->failure++;
    sresult->failureList.push_back(testName);
  }
}

int main() {

  SaxonProcessor *processor = new SaxonProcessor(false);
  XPathProcessor *xpathProc = processor->newXPathProcessor();
  xpathProc->setLanguageVersion("3.1");
  sResultCount *sresult = new sResultCount();
  cout << endl
       << "Test: XPathProcessor with Saxon version=" << processor->version()
       << endl;
  testXPathSingle(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testUnprefixedElementMatchingPolicy(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testNodeAxis(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXPathValues(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXPathAttrValues(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXPathOnFile(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXPathOnFile2(xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  testXPathValues2(processor, xpathProc, sresult);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  XdmNode *document =
      processor->parseXmlFromString("<foo x='1'><bar/><baz/></foo>");
  runTest("testArith", "2+2", "4", xpathProc, sresult, document);
  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testIf", "if (//*) then 3 else 4", "3", xpathProc, sresult,
          document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testBang", "string-join((1 to 3)!(. + 1), '-')", "2-3-4", xpathProc,
          sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testFor", "string-join(for $i in 1 to 4 return $i, '-')", "1-2-3-4",
          xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testExist", "exists(//*)", "true", xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testConcat", "'abc' || 'def'", "abcdef", xpathProc, sresult,
          document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testLet", "let $x := 3 return $x + 1", "4", xpathProc, sresult,
          document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testInlineFunctions", "function($x){$x + 1}(3)", "4", xpathProc,
          sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  bad("testNoAnnotations", xpathProc, sresult, document,
      "%private function($x){$x + 1}(3)");

  cout << endl
       << "============================================================="
       << endl
       << endl;
  bad("testNoConstructors", xpathProc, sresult, document, "<a/>");

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testMaps", "map{1:'a'}?1", "a", xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testMapType", "map{1:'a'} instance of map(*)", "true", xpathProc,
          sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testMapArrays", "['1a','2a','3a','4a']?2", "2a", xpathProc, sresult,
          document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testArrayType", "['1a','2a','3a','4a'] instance of array(*)", "true",
          xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  bad("testNoWhere", xpathProc, sresult, document,
      "for $i in 1 to 10 where $i gt 3 return $i");

  cout << endl
       << "============================================================="
       << endl
       << endl;
  bad("testNoOrderBy", xpathProc, sresult, document,
      "for $i in 1 to 10 order by -$i return $i");

  cout << endl
       << "============================================================="
       << endl
       << endl;
  bad("testNoCurrent", xpathProc, sresult, document, "current()");

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testRound", "round(12.341, 2)", "12.34", xpathProc, sresult,
          document);

  // cout<<endl<<"============================================================="<<endl<<endl;
  // runTest("testGenerateId", "generate-id(/)", strlen() >
  // 0,xpathProc,sresult,document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testQFlag", "matches('quid', 'quod', 'q')", "false", xpathProc,
          sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testMatches", "matches('abcdef', '^\\p{IsBasicLatin}+$')", "true",
          xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testNoNonCapturingGroups", "replace('abcdef', '(?:abc)(def)', '$1')",
          "def", xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testMapFunctions",
          "Q{http://www.w3.org/2005/xpath-functions/map}get(Q{http://"
          "www.w3.org/2005/xpath-functions/map}entry('a', 'b'), 'a')",
          "b", xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testArrayFunctions",
          "Q{http://www.w3.org/2005/xpath-functions/array}flatten(Q{http://"
          "www.w3.org/2005/xpath-functions/array}append([], '12'))",
          "12", xpathProc, sresult, document);

  cout << endl
       << "============================================================="
       << endl
       << endl;
  runTest("testDefaultLanguage", "default-language()", "en", xpathProc, sresult,
          document);

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
  delete document;
  delete xpathProc;
  delete processor;

  processor->release();
  delete SaxonProcessor::sxn_environ;
  delete sresult;

#ifdef MEM_DEBUG
  SaxonProcessor::getInfo();
#endif
  return 0;
}
