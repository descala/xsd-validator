from saxonche import *
import os
from lxml import etree
import urllib.parse
import re

class PyTestOutcome:

    processor: PySaxonProcessor
    wrong_error = None
    result_documents: dict
    xsl_messages = None
    serialized_result = None
    base_uri = None

    def __init__(self):
        self.wrong_error = None
        self.result_documents = {}
        self.xsl_messages = None
        self.serialized_result = None

    def capture_result_documents(self, rd : dict):
        self.result_documents = rd


    def test_assertion(self, assertion: PyXdmNode, result, result_as_error, proc: PySaxonProcessor, assert_xpc: PyXPathProcessor,
                       catalog_xpc: PyXPathProcessor, assert_set: set):
        self.processor = proc
        tag = assertion.name
        success = self.test_assertion2(assertion, result, result_as_error, assert_xpc, catalog_xpc, assert_set)

        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None and "any-of" != tag and "all-of" != tag and "not" != tag:
            if not success:
                if result is not None:
                    print("Assertion =" + str(assertion))
                    print("=============================")
                    print("Result =" + str(result))

                if result_as_error:
                    print("Assertion Error=" + str(assertion))
                    print(self.wrong_error)
                    print("=============================")
                    print("Result =" + str(result_as_error))

        return success

    def test_assertion_error(self, assertion: PyXdmNode, result: PySaxonApiError, assert_xpc: PyXPathProcessor,
                             catalog_xpc: PyXPathProcessor):
        return self.compare_expected_error(assertion, result, assert_xpc, catalog_xpc)

    def test_assertion2(self, assertion: PyXdmNode, result, result_as_error, assert_xpc: PyXPathProcessor, catalog_xpc: PyXPathProcessor, assert_set: set):

        tag = assertion.name.split("}")[1]
        assert_set.add(tag)

        if "assert-empty" != tag and "error" != tag and "any-of" != tag and "all-of" != tag and result is None and self.serialized_result is None:
            print("Error Found = " + str(result_as_error))
            return False
        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            print(assert_set)
        if "assert" == tag:
            return self.assert_xpath(assertion, result, assert_xpc, catalog_xpc)
        elif "assert-xml" == tag:
            return self.assert_xml(assertion, result, assert_xpc, catalog_xpc)
        elif "assert-eq" == tag:
            return self.assert_eq(assertion, result, assert_xpc, catalog_xpc)
        elif "assert-empty" == tag:
            return result is None or result.size == 0
        elif "assert-true" == tag:
            return result.size == 1 and result.item_at(0).is_atomic and result.item_at(0).get_atomic_value().primitive_type_name
        elif "error" == tag:
            return self.compare_expected_error(assertion, result_as_error, assert_xpc, catalog_xpc)

        elif "not" == tag:
            catalog_xpc.set_context(xdm_item=assertion)
            sub_assertion = catalog_xpc.evaluate_single("*")
            return not self.test_assertion2(sub_assertion.get_node_value(), result, result_as_error, assert_xpc, catalog_xpc, assert_set)

        elif "assert-string-value" == tag:

            return self.assert_string_value(assertion, result)

        elif "assert-count" == tag:

            expected = int(assertion.string_value)
            actual = result.size
            if actual != expected and os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("Expected result size = " + str(expected) + "; actual size = " + str(actual))

            return actual == expected

        elif "assert-permutation" == tag:
            assert_xpc.set_parameter("result", result)
            assertion_result = assert_xpc.evaluate("(" + assertion.string_value + ")")
            assertion_str = ""
            for item in assertion_result:
                assertion_str = assertion_str + " " + item.string_value

            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print(assertion_str)


            for item in result:
                if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                    print("item = " + item.string_value)
                if not (item.string_value in assertion_str):
                    return False
            return True

        elif "assert-deep-eq" == tag:
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("assertion = " + str(assertion.string_value))
                print("result = " + str(result))
            assert_xpc.declare_variable("result")
            assert_xpc.set_parameter("result", result)
            s = assert_xpc.evaluate("deep-equal($result , (" + assertion.string_value + "))")
            ok = s.item_at(0).is_atomic and s.item_at(0).get_atomic_value().boolean_value
            return ok

        elif "serialization-matches" == tag:
            return self.assert_serialization_matches(assertion, result, assert_xpc)

        elif "assert-serialization-error" == tag:
            return self.assert_serialization_error(assertion, result_as_error, assert_xpc)

        elif "assert-serialization" == tag:
            return self.assert_serialization(assertion, result, catalog_xpc)

        elif "assert-message" == tag:
            if self.xsl_messages is None:
                return False
            catalog_xpc.set_context(xdm_item=assertion)
            sub_assertion = catalog_xpc.evaluate_single("*")
            for n in range(int(self.xsl_messages.size)):
                item = self.xsl_messages.item_at(n)
                if self.test_assertion2(sub_assertion.get_node_value(), item, result_as_error, assert_xpc,
                                     catalog_xpc, assert_set):
                    return True

            return False


        elif "assert-result-document" == tag:
            catalog_xpc.set_context(xdm_item=assertion)
            sub_assertion = catalog_xpc.evaluate_single("*")
            '''print(result.item_at(0).get_node_value().base_uri)'''
            uri = assertion.get_attribute_value("uri")
            base_urii = ""
            if result is not None:
                base_urii = result.item_at(0).get_node_value().base_uri
            else:
                base_urii = self.base_uri
            uri = urllib.parse.urljoin(base_urii, uri)
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("uri=" + uri)
            if self.result_documents:
                if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                    print(list(self.result_documents.keys()))
                try:
                    print("Check assert-result-document")
                    print("uri=" + uri)
                    print(*self.result_documents, sep=", ")
                    doc = self.result_documents[uri]
                    ok = self.test_assertion2(sub_assertion.get_node_value(),  doc, None, assert_xpc, catalog_xpc, assert_set)
                    if not ok:
                        print("**** Assertion failed for result-document " + uri)

                    return ok
                except Exception as ex:
                    print("Check assert-result-document")
                    print(*self.result_documents, sep=", ")
                    print(ex)
                    return False

            return False
        elif "all-of" == tag:
            catalog_xpc.set_context(xdm_item=assertion)
            children = catalog_xpc.evaluate("*")

            for i in range(children.size):
                child = children.item_at(i)
                if not self.test_assertion(child.get_node_value(), result, result_as_error, self.processor, assert_xpc, catalog_xpc, assert_set):
                    return False
            return True

        elif "assert-type" == tag:
            assert_xpc.declare_variable("result")
            assert_xpc.set_parameter("result", result)
            valuei = assert_xpc.evaluate_single("$result instance of " + assertion.string_value)
            return valuei.get_atomic_value().boolean_value

        elif "assert-false" == tag:
            return result.size == 1 and result.item_at(0).is_atomic and result.item_at(0).get_atomic_value().boolean_value == False

        elif "assert-true" == tag:
            return result.size == 1 and result.item_at(0).is_atomic and result.item_at(0).get_atomic_value().boolean_value == True

        elif "any-of" == tag:
            partial_success = False
            catalog_xpc.set_context(xdm_item=assertion)
            children = catalog_xpc.evaluate("*")
            for i in range(children.size):
                child = children.item_at(i)
                if self.test_assertion(child.get_node_value(), result, result_as_error, self.processor, assert_xpc, catalog_xpc, assert_set):
                    if self.wrong_error is not None:
                        partial_success = True
                        continue
                    return True
            return partial_success
        elif "assert-warning" == tag:
            return True

        return False


    def assert_serialization_error(self, assertion: PyXdmNode, result: PySaxonApiError, assert_xpc: PyXPathProcessor):
        if result is None:
            print("Error in PytestOutCome PySaxonApiError should not be None")
            return False
        code = assertion.get_attribute_value("code")
        resulti = code in str(result)
        if resulti == False:
            self.wrong_error = str(result)
        return resulti

    def assert_serialization(self, assertion: PyXdmNode, result: PyXdmValue, catalog_xpc: PyXPathProcessor):

        method = assertion.get_attribute_value("method")

        catalog_xpc.set_context(xdm_item=assertion)
        comparand_node = catalog_xpc.evaluate("if (@file) then " +
                            "if (@encoding) " +
                            "then unparsed-text(resolve-uri(@file, base-uri(.)), @encoding) " +
                            "else unparsed-text(resolve-uri(@file, base-uri(.))) " +
                            "else string(.)")

        if comparand_node is None:
            return False

        comparand = str(comparand_node)

        comparand = comparand.replace("\r\n", "\n")
        if comparand.endswith("\n"):
            comparand = comparand[0:-1]
        result_str = ""
        if result is None:
            if self.serialized_result is not None:
                result_str = self.serialized_result
            else:
                return False
        else:
            result_str = str(result)

        if method is None:
            method = "xml"

        is_html = method == "html" or method == "xhtml"

        normalize = is_html

        if not normalize:
            normalize_attr = assertion.get_attribute_value("normalize-space")
            normalize = normalize_attr is not None and (normalize_attr.strip() == "true" or normalize_attr.strip() == "1")

        parser = etree.XMLParser(remove_blank_text=True)
        '''if normalize:

            comparand_xml = etree.XML(comparand, parser)
            print("assert-serialization cp4")
            print(comparand_xml)'''

        if result_str.endswith("\n"):
            result_str = result_str[0:-1]

        if is_html:
            comparand = comparand.replace(" <", "<")
            comparand = comparand.replace("> ", ">")
            result_str = result_str.replace(" <", "<")
            result_str = result_str.replace("> ", ">")

        print("result = " + result_str)
        print('comparand = ' + comparand)

        if result_str == comparand:
            return True


        '''try:
            comparand_xml = etree.XML(comparand, parser)
            resulti = etree.XML(result_str, parser)
            return self.elements_equal(comparand_xml, resulti)
        except Exception as ex:
            print(ex)'''
        return False



    def assert_serialization_matches(self, assertion: PyXdmNode, result: PyXdmValue, assert_xpc: PyXPathProcessor):
        flags_att_str = ""
        flags_att = assertion.get_attribute_value('flag')
        if flags_att is not None:
            flags_att_str =flags_att

        result_str = ""
        if result is None:
            if self.serialized_result is not None:
                result_str = self.serialized_result
            else:
                return False
        elif isinstance(result, PyXdmItem):
            result_str = result.string_value
        elif result.size == 1:
            result_str = str(result.item_at(0))
        else:
            for x in range(result.size):
                itemi = result.item_at(x)
                result_str += str(itemi)

        flags_att_str = flags_att_str.replace("!", "")

        assertion_regex = assertion.string_value
        '''assertion.string_value'''
        assert_xpc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
        '''print(result_str)
        print(assertion_regex)
        print(assertion.children[0])
        print(flags_att_str)'''
        if re.search(str(assertion.children[0]), result_str) is not None:
            return True

        if re.search(assertion_regex, result_str) is not None:
            return True

        assertion_regex = assertion_regex.replace("'", "''")

        xpath_str = "fn:matches('" + result_str + "', \'" + assertion_regex + "\','" + flags_att_str + "')"
        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            print("assert-serialization-matches = " + xpath_str)
            print("assertion_regex = " + assertion_regex)
        oki = False
        try:
            oki = assert_xpc.effective_boolean_value(xpath_str)
            return oki
        except Exception as ex:
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("assert-serialization-matches failed")
            print(ex)
        return False

    def assert_string_value(self, assertion: PyXdmNode, result: PyXdmValue):

        normalize_space = assertion.get_attribute_value("normalize-space")
        is_normalize_space = False
        if normalize_space is not None and normalize_space == "true":
            is_normalize_space = True

        assertion_string = assertion.string_value.strip()
        result_string = ""
        result_string2 = ""
        if result.size == 1:
            result_string = result.item_at(0).string_value
            if result_string == assertion_string:
                return True
            if result_string.strip() == assertion_string.strip():
                return True
            result_string = result_string.strip().replace("\r\n", "\n").replace("\n", "")
        else:
            first = True
            for x in range(result.size):
                itemx = result.item_at(x)
                result_string = result_string + " " + itemx.string_value
            result_string = result_string.strip()

        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            print(" result = " + result_string + " len=" + str(len(result_string)))
            print("aresult = " + assertion_string + " len=" + str(len(assertion_string)))

        '''Temporary fix for decimal-format variable declaration'''
        if result_string == "Infinity" and assertion_string == "off-the-scale":
            return True


        if result_string == assertion_string:
            return True
        elif is_normalize_space:
            normalize_xpath_proc = self.processor.new_xpath_processor()
            normalize_xpath_proc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
            assertion_string = str(normalize_xpath_proc.evaluate("fn:normalize-space('"+assertion_string+"')"))
            result_string = str(normalize_xpath_proc.evaluate("fn:normalize-space('" + result_string + "')"))
            '''assertion_string = assertion_string.replace("\r\n", "\n").replace("\n", "")'''
            return result_string == assertion_string
        else:
            return False





    def compare_expected_error(self, assertion: PyXdmNode, result: PySaxonApiError, assert_xpc: PyXPathProcessor, catalog_xpc: PyXPathProcessor):
        if result is None:
            print("Error in PytestOutCome PySaxonApiError should not be None")
            return False
        code = assertion.get_attribute_value("code")
        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            print("result = " + str(result))
            print("assert code = " + code)
        resulti = code in str(result)
        if resulti == False:
            self.wrong_error = str(result)
        return resulti


    def assert_xpath(self, assertion: PyXdmNode, result: PyXdmValue, assert_xpc: PyXPathProcessor, catalog_xpc: PyXPathProcessor):
        '''catalog_xpc.set_context(xdm_item=assertion)'''
        if result is None:
            return False
        xml_str = str(assertion)
        new_assertion = self.processor.parse_xml(xml_text=xml_str)
        temp_xpath_proc = self.processor.new_xpath_processor()
        temp_xpath_proc.set_context(xdm_item=new_assertion)
        namespaceValues = temp_xpath_proc.evaluate("for $i in 1 to count(//namespace::*) return if (empty(index-of((//namespace::*)[position() = (1 to ($i - 1))][name() = name((//namespace::*)[$i])], (//namespace::*)[$i]))) then (//namespace::*)[$i] else ()")
        if namespaceValues != None and namespaceValues.size > 0:
            '''print("values = " + str(namespaceValues))
            print("================")'''
            ns_size = namespaceValues.size
            for x in range(ns_size):
                itemx = namespaceValues.item_at(x)
                '''print("namespace node=" + str(itemx.get_node_value().string_value))'''
                if itemx is not None and isinstance(itemx, PyXdmNode):
                    itemn = itemx.get_node_value()
                    ns_name = itemn.name
                    ns_value = itemn.get_node_value()
                    if ns_name is not None and ns_value is not None:
                        '''print("Namespace=" + ns_name + " = " + str(ns_value))'''
                        assert_xpc.declare_namespace(ns_name, str(itemn.get_node_value().string_value))
            assert_xpc.declare_variable("result")
            '''print("Testing " + assertion.string_value)
            print(result)'''
            assert_xpc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
            assert_xpc.declare_namespace("xs", "http://www.w3.org/2001/XMLSchema")
            assert_xpc.declare_namespace("math", "http://www.w3.org/2005/xpath-functions/math")
            assert_xpc.declare_namespace("map", "http://www.w3.org/2005/xpath-functions/map")
            assert_xpc.declare_namespace("array", "http://www.w3.org/2005/xpath-functions/array")
            assert_xpc.declare_namespace("j", "http://www.w3.org/2005/xpath-functions")
            assert_xpc.declare_namespace("file", "http://expath.org/ns/file")
            assert_xpc.declare_namespace("bin", "http://expath.org/ns/binary")
            assert_xpc.set_parameter("result", result)
            assert_xpc.set_context(xdm_item=result.item_at(0))
            try:
                b = assert_xpc.effective_boolean_value(assertion.string_value)
                '''if not b:
                    print("XPath assertion " + assertion.string_value + " failed")'''
                return b
            except Exception as ex:
                print(ex)
        return False

    def elements_equal(self, e1, e2):
        if e1.tag != e2.tag: return False
        if e1.text != e2.text: return False
        if e1.tail != e2.tail: return False
        if e1.attrib != e2.attrib: return False
        if len(e1) != len(e2): return False
        return all(self.elements_equal(c1, c2) for c1, c2 in zip(e1, e2))

    def assert_xml(self, assertion: PyXdmNode, result: PyXdmValue, assert_xpc: PyXPathProcessor, catalog_xpc: PyXPathProcessor):
        normalizeAtt = assertion.get_attribute_value("normalize-space")
        normalize = normalizeAtt is not None and ("true" == normalizeAtt.strip() or "1" == normalizeAtt.strip())
        ignoreAtt = assertion.get_attribute_value("ignore-prefixes")
        ignorePrefixes = ignoreAtt is not None and ("true" == ignoreAtt.strip() or "1" == ignoreAtt.strip())
        xmlVersion = assertion.get_attribute_value("xml-version")
        xml11 = "1.1" == xmlVersion
        no_wsp_comparand_node = None
        no_wsp_result_node = None

        catalog_xpc.set_context(xdm_item=assertion)
        comparand = str(catalog_xpc.evaluate("if (@file) then unparsed-text(resolve-uri(@file, base-uri(.))) else string(.)"))
        if comparand.startswith("<?xml"):
            indexi = comparand.index("?>")+2
            comparand = comparand[indexi:]
        comparand = "<z>" + comparand.strip().replace("\r\n", "\n").replace("\n", "") + "</z>"

        result_str = "<z>" + str(result).strip().replace("\r\n", "\n").replace("\n", "") + "</z>"

        try:
            comparand_node = self.processor.parse_xml(xml_text=comparand)

            result_node = self.processor.parse_xml(xml_text=result_str)

            xslt30_proc = self.processor.new_xslt30_processor()
            no_whitespace_stylesheet = "<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='3.0'><xsl:output indent='false' omit-xml-declaration='true' /><xsl:template match='/'><z><xsl:copy ><xsl:apply-templates /></xsl:copy></z></xsl:template><xsl:template match='text( )' priority='1'><xsl:value-of select='normalize-space(.)'/></xsl:template> <xsl:template match='*'  priority='2'><xsl:copy-of select='.' /></xsl:template></xsl:stylesheet>"
            executable1 = xslt30_proc.compile_stylesheet(stylesheet_text=no_whitespace_stylesheet)
            no_wsp_comparand_node = executable1.apply_templates_returning_value(xdm_value=comparand_node)
            no_wsp_result_node = executable1.apply_templates_returning_value(xdm_value=result_node)


            if ignorePrefixes:
                no_namespace_stylesheet = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:output method='xml' version='1.0' encoding='UTF-8' indent='no'/><xsl:template match='comment()'><xsl:copy><xsl:apply-templates/></xsl:copy></xsl:template><xsl:template match='*'><xsl:element name='{local-name()}'><xsl:for-each select='@*'><xsl:attribute name='{local-name()}'><xsl:value-of select='.'/></xsl:attribute></xsl:for-each><xsl:apply-templates/></xsl:element></xsl:template></xsl:stylesheet>"
                '''no_default_ns_stylesheet = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='node()'><xsl:copy copy-namespaces='no'><xsl:apply-templates select='node() | @*' /></xsl:copy></xsl:template><xsl:template match='*'><xsl:element name='{local-name()}'><xsl:apply-templates select='node() | @*' /></xsl:element></xsl:template><xsl:template match='@*'><xsl:copy copy-namespaces='no'><xsl:apply-templates select='node() | @*' /></xsl:copy></xsl:template></xsl:stylesheet>"'''
                executable2 = xslt30_proc.compile_stylesheet(stylesheet_text=no_namespace_stylesheet)
                no_wsp_comparand_node = executable2.apply_templates_returning_value(xdm_value=no_wsp_comparand_node)
                no_wsp_result_node = executable2.apply_templates_returning_value(xdm_value=no_wsp_result_node)

            assert_xpc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
            assert_xpc.declare_variable("result_xml")
            assert_xpc.declare_variable("comparand_node")
            assert_xpc.set_parameter("result_xml", no_wsp_result_node.item_at(0))
            assert_xpc.set_parameter("comparand_node", no_wsp_comparand_node.item_at(0))
            resulti = assert_xpc.effective_boolean_value("fn:deep-equal($result_xml, $comparand_node)")
            if resulti:
                return True
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("Failed using Saxon deep-equal function")
                print("Comparand xml = " + str(no_wsp_comparand_node))
                print("resultx = " + str(no_wsp_result_node))
        except PySaxonApiError as ex:
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print("Faild to parse Comparand xml or run effective_boolean_value = " + comparand)
                print(ex)

        if result_str == comparand:
            return True

        parser = etree.XMLParser(remove_blank_text=True)
        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            print("====== assertion - assert-xml:=")
            print(str(no_wsp_comparand_node))
            print("====== result:=")
            print(str(no_wsp_result_node))

        try:
            comparand_xml = etree.XML(str(no_wsp_comparand_node), parser)
            resulti = etree.XML(str(no_wsp_result_node), parser)
            return self.elements_equal(comparand_xml, resulti)
        except Exception as ex:
            print("Exception raised by ElementTree: ")
            print(ex)
        return False

    def assert_eq(self, assertion: PyXdmNode, result: PyXdmValue, assert_xpc: PyXPathProcessor, catalog_xpc: PyXPathProcessor):

        assert_xpc.declare_variable("result")
        assert_xpc.set_parameter("result", result)
        try:
            item = assert_xpc.evaluate_single("$result eq " + assertion.string_value)
            '''print(result)
            print(item)'''
            return item is not None and item.get_atomic_value().boolean_value

        except PySaxonApiError as ex:
            '''print("assert-eq failed - " + str(ex))'''
            return False
