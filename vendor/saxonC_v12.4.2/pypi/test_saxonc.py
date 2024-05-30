from tempfile import mkstemp
import pytest
from saxonche import *
import os
from os.path import isfile
from datetime import datetime as date

'''pytest --data-dir=[path/data]  test_saxonc.py'''


@pytest.fixture
def saxonproc():
    return PySaxonProcessor()

@pytest.fixture
def data_dir(pytestconfig):
    return pytestconfig.getoption("--data-dir")

def test_create_bool():
    """Create SaxonProcessor object with a boolean argument"""
    sp1 = PySaxonProcessor(license=True)
    sp2 = PySaxonProcessor(license=False)
    assert isinstance(sp1, PySaxonProcessor)
    assert isinstance(sp2, PySaxonProcessor)
'''@pytest.mark.skip('Error: SaxonDll.processor is nullptr in constructor(configFile)')'''
def test_create_config():
    """Create SaxonProcessor object with a configuration file argument"""
    conf_xml = b"""\
    <configuration xmlns="http://saxon.sf.net/ns/configuration" edition="HE">

      <xslt
        initialMode=""
        initialTemplate=""
        messageReceiver=""
        outputUriResolver=""
        schemaAware="false"
        staticErrorListener=""
        staticUriResolver=""
        styleParser=""
        version="3.0">
      </xslt>
      <xquery
        allowUpdate="true"
        constructionMode="preserve"
       defaultElementNamespace=""
       defaultFunctionNamespace="http://www.w3.org/2005/xpath-functions"
        emptyLeast="true"
        inheritNamespaces="true"
        preserveBoundarySpace="false"
        preserveNamespaces="true"
        requiredContextItemType="document-node()"
        schemaAware="false"
        staticErrorListener=""
        version="3.1"
        />
    </configuration>
    """
    try:
        fd, fname = mkstemp(suffix='.xml')
        os.write(fd, conf_xml)
        os.close(fd)
        if not os.path.exists(fname):
            raise IOError('%s does not exist' % fname)
        with open(fname, 'r') as f:
            print(f.read())
        sp = PySaxonProcessor(config_file=fname)
        assert isinstance(sp, PySaxonProcessor)
    except Exception as err:
        print(err)
        assert False
    finally:
        os.unlink(fname)
def test_create_procs():
    """Create XPathProcessor, XsltProcessor from SaxonProcessor object"""
    sp = PySaxonProcessor()
    xp = sp.new_xpath_processor()
    xsl30 = sp.new_xslt30_processor()
    assert isinstance(xp, PyXPathProcessor)
    assert isinstance(xsl30, PyXslt30Processor)
def test_version():
    """SaxonProcessor version string content"""
    sp = PySaxonProcessor()
    ver = sp.version

    assert ver.startswith('SaxonC-HE')
    assert ver.endswith('from Saxonica')
def test_version2():
    """SaxonProcessor version string content"""
    try:
        sp = PySaxonProcessor(license=True)
        assert sp is not None
        ver = sp.version

        assert ver.startswith('SaxonC-EE')
        assert ver.endswith('from Saxonica')
    except Exception as err:
        print("Error: ", err)


def test_schema_aware1(saxonproc):
    assert saxonproc.is_schema_aware == False

def test_icu_lib():
    saxonproc = PySaxonProcessor(license=True)
    print(saxonproc.version)
    xqc = saxonproc.new_xquery_processor()
    xqc.set_query_content("format-date(current-date(),'[FNn]','de',(),())")
    result = xqc.run_query_to_value()
    print("format-date(current-date(),'[FNn]','de',(),()) => " + str(result.head))
    assert str(result.head) in "Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag, Sonntag"

    xqc.set_query_content("format-integer(33,'[Ww]')")
    result2 = xqc.run_query_to_value()
    print("format-integer(33,'[Ww]') => " + str(result2))
    assert '0033' in str(result2)


    xqc.set_query_content("format-integer(33,'Ww')")
    result5 = xqc.run_query_to_value()
    print("format-integer(33,'Ww') => "+str(result5))
    assert 'Thirty Three' in str(result5)

    xqc.set_query_content("format-integer(33,'Ww','de')")
    result6 = xqc.run_query_to_value()
    print("format-integer(33,'Ww','de') => "+str(result6))
    assert 'Drei\xadund\xaddreißig' in str(result6)

    xqc.set_query_content("format-integer(33,'Ww','cs')")
    result7 = xqc.run_query_to_value()
    print("format-integer(33,'Ww','cs') => "+str(result7))
    assert 'Třicet Tři' in str(result7)



def test_icu_lib_HE():
    saxonproc = PySaxonProcessor()
    print(saxonproc.version)
    xqc = saxonproc.new_xquery_processor()
    xqc.set_query_content("format-date(current-date(),'[FNn]','de',(),())")
    result = xqc.run_query_to_value()
    print("format-date(current-date(),'[FNn]','de',(),()) => " + str(result))
    day = date.today().strftime("%A")
    assert '[Language: en]'+day in str(result)

    xqc.set_query_content("format-integer(33,'[Ww]')")
    result2 = xqc.run_query_to_value()
    print("format-integer(33,'[Ww]') => " + str(result2))
    assert '0033' in str(result2)

    xqc.set_query_content("format-integer(33,'Ww')")
    result5 = xqc.run_query_to_value()
    print("format-integer(33,'Ww') => "+str(result5))
    assert 'Thirty Three' in str(result5)

    xqc.set_query_content("format-integer(33,'Ww','de')")
    result6 = xqc.run_query_to_value()
    print("format-integer(33,'Ww','de') => "+str(result6))
    assert 'Thirty Three' in str(result6)

    xqc.set_query_content("format-integer(33,'Ww','cs')")
    result7 = xqc.run_query_to_value()
    print("format-integer(33,'Ww','cs') => "+str(result7))

    assert 'Thirty Three' in str(result7)


def test_schema_aware2():
    ''' This unit test requires a valid license - SaxonCEE '''
    try:
        sp = PySaxonProcessor(license=True)
        assert sp.is_schema_aware == True
    except Exception as err:
            print("Error: ", err)

'''PyXsltProcessor test cases '''
def test_xslt30_processor(data_dir):
    sp = PySaxonProcessor()
    xsltproc = sp.new_xslt30_processor()
    xmlFile = os.path.join(data_dir, "cat.xml")
    node_ = sp.parse_xml(xml_file_name=xmlFile)
    assert node_ is not None
    executable = xsltproc.compile_stylesheet(stylesheet_text="<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='2.0'>       <xsl:param name='values' select='(2,3,4)' /><xsl:output method='xml' indent='yes' /><xsl:template match='*'><output><xsl:value-of select='//person[1]'/><xsl:for-each select='$values' ><out><xsl:value-of select='. * 3'/></out></xsl:for-each></output></xsl:template></xsl:stylesheet>")
    assert executable is not None
    output2 = executable.apply_templates_returning_string(xdm_value=node_)

    assert output2 is not None
    assert 'text1' in output2




def test_Xslt_from_file1(saxonproc, data_dir):
    xsltproc = saxonproc.new_xslt30_processor()
    xmlFile = os.path.join(data_dir, "cat.xml")
    result = xsltproc.transform_to_string(source_file=xmlFile, stylesheet_file=os.path.join(data_dir, "test.xsl"))
    assert result is not None
    print(result)
    assert 'text3' in result

def test_Xslt_from_file2(saxonproc, data_dir):
    xsltproc = saxonproc.new_xslt30_processor()
    xmlFile = os.path.join(data_dir, "cat.xml")
    result = xsltproc.transform_to_string(source_file=os.path.join(data_dir, "cat.xml"), stylesheet_file=os.path.join(data_dir, "test.xsl"))
    assert result is not None
    assert 'text3' in result

def test_Xslt_from_file_error(saxonproc, data_dir):
    xsltproc = saxonproc.new_xslt30_processor()
    try:
        result = xsltproc.transform_to_value(source_file=os.path.join(data_dir, "cat.xml"), stylesheet_file=os.path.join(data_dir, "test-error.xsl"))
        assert result is None
    except Exception as err:
        print("Error: ", err)
        assert True

def test_xslt_parameter(saxonproc, data_dir):
    input_ = saxonproc.parse_xml(xml_text="<out><person>text1</person><person>text2</person><person>text3</person></out>")
    value1 = saxonproc.make_integer_value(10)
    trans = saxonproc.new_xslt30_processor()
    trans.set_parameter("numParam",value1)
    assert value1 is not None
    executable = trans.compile_stylesheet(stylesheet_file=os.path.join(data_dir, "test.xsl"))
    executable.set_initial_match_selection(xdm_value=input_)
    output_ = executable.apply_templates_returning_string()
    assert output_ is not None
    assert 'text2' in output_

def test_catalog(saxonproc, data_dir):
    try:
        catalog_files = [os.path.join(data_dir, "catalog.xml"), os.path.join(data_dir, "catalog2.xml")]
        saxonproc.set_catalog_files(catalog_files)
        trans = saxonproc.new_xslt30_processor()

        executable = trans.compile_stylesheet(stylesheet_file="http://example.com/books.xsl")
        executable.set_initial_match_selection(file_name=os.path.join(data_dir, "books.xml"))
        executable.set_global_context_item(file_name=os.path.join(data_dir, "books.xml"))
        output_ = executable.apply_templates_returning_string()
        assert output_ is not None
    except Exception as e:
            print(e)
            assert False

def testUTF8(saxonproc):
    node = saxonproc.parse_xml(xml_text="<doc><e>تيست</e></doc>", encoding="UTF-8")
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='e'>UTF8-تيست: <xsl:value-of select='.'/></xsl:template></xsl:stylesheet>", encoding="UTF-8")
    assert node is not None
    assert isinstance(node, PyXdmNode)
    assert len(node.children)>0
    eNode = node.children[0].children[0]
    assert eNode is not None
    executable.set_global_context_item(xdm_item=node)
    executable.set_initial_match_selection(xdm_value=eNode)
    executable.set_property("!encoding", "UTF-8")
    result = executable.apply_templates_returning_string()
    assert result is not None
    assert "UTF8-تيست: تيست" in result
    
'''PyXslt30Processor test cases '''
def testContextNotRoot(saxonproc):
    node = saxonproc.parse_xml(xml_text="<doc><e>text</e></doc>")
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable name='x' select='.'/><xsl:template match='/'>errorA</xsl:template><xsl:template match='e'>[<xsl:value-of select='name($x)'/>]</xsl:template></xsl:stylesheet>")
    assert node is not None
    assert isinstance(node, PyXdmNode)
    assert len(node.children)>0
    eNode = node.children[0].children[0]
    assert eNode is not None
    executable.set_global_context_item(xdm_item=node)
    executable.set_initial_match_selection(xdm_value=eNode)
    result = executable.apply_templates_returning_string()
    assert result is not None
    assert "[" in result

def testResolveUri(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:err='http://www.w3.org/2005/xqt-errors'><xsl:template name='go'><xsl:try><xsl:variable name='uri' as='xs:anyURI' select=\"resolve-uri('notice trailing space /out.xml')\"/> <xsl:message select='$uri'/><xsl:result-document href='{$uri}'><out/></xsl:result-document><xsl:catch><xsl:sequence select=\"'$err:code: ' || $err:code  || ', $err:description: ' || $err:description\"/></xsl:catch></xsl:try></xsl:template></xsl:stylesheet>")
    value = executable.call_template_returning_value("go")
    assert value is not None
    item = value.head
    print("WHAT IS CODE")
    print(item.string_value)
    assert "code" in item.string_value
def testEmbeddedStylesheet(saxonproc, data_dir):
    trans = saxonproc.new_xslt30_processor()
    input_ = saxonproc.parse_xml(xml_file_name=os.path.join(data_dir, "books.xml"))
    path = "/processing-instruction(xml-stylesheet)[matches(.,'type\\s*=\\s*[''\"\"]text/xsl[''\" \"]')]/replace(., '.*?href\\s*=\\s*[''\" \"](.*?)[''\" \"].*', '$1')"

    print(os.path.join(data_dir, "books.xml"))

    assert input_ is not None

    xPathProcessor = saxonproc.new_xpath_processor()
    xPathProcessor.set_context(xdm_item=input_)
    hrefval = xPathProcessor.evaluate_single(path)

    assert hrefval is not None
    href = hrefval.string_value
    print("href="+href)
    assert href != ""
    styles_dir = data_dir
    executable = trans.compile_stylesheet(stylesheet_file=os.path.join(styles_dir, href))

    assert executable is not None
    assert isinstance(input_, PyXdmNode)
    executable.set_global_context_item(xdm_item=input_)
    node = executable.apply_templates_returning_value(xdm_value=input_)
    assert node is not None


def testNodeAxis(saxonproc, data_dir):
    node_ = saxonproc.parse_xml(xml_text="<out xmlns:my='http://www.example.com/ns/various' xmlns:f='http://www.example.com/ns/various1' xmlns='http://www.example.com'><person>text1</person><person>text2</person></out>")
    child = node_.children[0]
    assert child is not None
    namespaces = child.axis_nodes(8)

    assert len(namespaces) > 0

    for ns in namespaces:
        uri_str = ns.string_value
        ns_prefix = ns.name

        if ns_prefix is not None:
            print("xmlns:" + ns_prefix + "='" + uri_str + "'")
        else:
            print("xmlns uri=" + uri_str + "'")



def testCollection(saxonproc, data_dir):
    xq = saxonproc.new_xquery_processor()
    xq.set_query_base_uri('file:////' + os.path.join(data_dir, "trax/xml/"))
    xq.set_query_content("collection('?select=*.xml')")
    r = xq.run_query_to_value()
    assert r is not None



def testXquery_40_functions():
    proc = PySaxonProcessor(license=True)
    proc.set_configuration_property('http://saxon.sf.net/feature/allowSyntaxExtensions', 'on')
    xquery_processor = proc.new_xquery_processor()
    result = xquery_processor.run_query_to_value(query_text = 'xquery version "4.0"; parse-html("<p>This is paragraph 1.<p>This is paragraph 2.")', lang= '4.0')
    assert "paragraph" in str(result)

def testXquery_40_functions_error():
    try:
        proc = PySaxonProcessor(license=True)
        proc.set_configuration_property('http://saxon.sf.net/feature/allowSyntaxExtensions', 'on')
        xquery_processor = proc.new_xquery_processor()
        result = xquery_processor.run_query_to_value(query_text = 'xquery version "4.0"; parse-html("<p>This is paragraph 1.<p>This is paragraph 2.")', lang= '3.0')
        assert False
    except Exception:
        assert True


def testContext2NotRootNamedTemplate(saxonproc):
        trans = saxonproc.new_xslt30_processor()
        input_ = saxonproc.parse_xml(xml_text="<doc><e>text</e></doc>")
        executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:variable name='x' select='.'/><xsl:template match='/'>errorA</xsl:template><xsl:template name='main'>[<xsl:value-of select='$x'/>]</xsl:template></xsl:stylesheet>")

        assert executable is not None
        executable.set_global_context_item(xdm_item=input_)
        result = executable.call_template_returning_value("main")

        assert result is not None
        print(result.head.string_value)
        assert "[text]" in result.head.string_value

        result2 = executable.call_template_returning_string("main")

        print(result2)
        assert result2 is not None
        assert "text" in result2


def testNamedTemplateDefault(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    input_ = saxonproc.parse_xml(xml_text="<doc><e>text</e></doc>")
    executable = trans.compile_stylesheet(stylesheet_text = '''
     <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      version="3.0"
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      exclude-result-prefixes="#all"
      expand-text="yes">
    
      <xsl:output method="html" indent="yes" html-version="5"/>
    
      <xsl:template match="/" name="xsl:initial-template">
        <html>
          <head>
            <title>Test</title>
          </head>
          <body>
            <h1>Test</h1>
            <ol>
              <xsl:iterate select="1 to 5">
                <li>Item {.}</li>
              </xsl:iterate>
            </ol>
          </body>
        </html>
        <xsl:comment>Run with {system-property('xsl:product-name')} {system-property('xsl:product-version')} {system-property('Q{http://saxon.sf.net/}platform')}</xsl:comment>
      </xsl:template>
    
    </xsl:stylesheet>
            
             ''')

    assert executable is not None

    result = executable.call_template_returning_string(None)

    assert result is not None
    assert "Item 3" in result


def testCaseVariantFileLoads(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    input_ = saxonproc.parse_xml(xml_text="<doc><e>text</e></doc>")
    executable = trans.compile_stylesheet(stylesheet_text = '''
     <xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" expand-text="yes" 
         xmlns:p="urn:pentecom" xmlns:xs="http://www.w3.org/2001/XMLSchema"
         exclude-result-prefixes="p xs">
         <xsl:output indent="yes"/>
         <xsl:strip-space elements="*"/>
         
         <xsl:mode on-no-match="shallow-copy"/>
         
         <!--only compiles with ;j (java flavor) added to flag-->
         <xsl:template match="text()[matches(.,'f?ool','i')]"/>
         
     </xsl:stylesheet>''')
    assert executable is not None



def testNamedTemplateToFileDefault(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    trans.set_cwd(os.getcwd()+'/')
    input_ = saxonproc.parse_xml(xml_text="<doc><e>text</e></doc>")
    executable = trans.compile_stylesheet(stylesheet_text = '''
     <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      version="3.0"
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      exclude-result-prefixes="#all"
      expand-text="yes">
    
      <xsl:output method="html" indent="yes" html-version="5"/>
    
      <xsl:template match="/" name="xsl:initial-template">
        <html>
          <head>
            <title>Test</title>
          </head>
          <body>
            <h1>Test</h1>
            <ol>
              <xsl:iterate select="1 to 5">
                <li>Item {.}</li>
              </xsl:iterate>
            </ol>
          </body>
        </html>
        <xsl:comment>Run with {system-property('xsl:product-name')} {system-property('xsl:product-version')} {system-property('Q{http://saxon.sf.net/}platform')}</xsl:comment>
      </xsl:template>
    
    </xsl:stylesheet>
            
             ''')
    assert executable is not None

    executable.call_template_returning_file(output_file="result_For_call_template.xml")
    assert isfile("result_For_call_template.xml") == True


def testUseAssociated(saxonproc, data_dir):
    try:
        trans = saxonproc.new_xslt30_processor()
        foo_xml = os.path.join(data_dir, "trax/xml/foo.xml")
        executable = trans.compile_stylesheet(associated_file=foo_xml)
        assert executable is not None
        executable.set_initial_match_selection(file_name=foo_xml)
        result = executable.apply_templates_returning_string()
        assert result is not None
    except Exception as e:
        print(e)
        assert False


def testnullptrStylesheet(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    try:
        result = trans.transform_to_string()
        assert result is None
    except Exception:
        assert True

def testXdmDestination1(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template name='go'><a/></xsl:template></xsl:stylesheet>")
    root = executable.call_template_returning_value("go")
    assert isinstance(root, PyXdmValue)
    assert root is not None
    assert root.head is not None
    assert root.head.is_atomic == False
    node  = root.head
    assert node is not None
    assert isinstance(node, PyXdmNode)
    assert node.node_kind == 9

def testXdmDestinationWithItemSeparator(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    stylesheetStr = "<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template name='go'><xsl:comment>A</xsl:comment><out/><xsl:comment>Z</xsl:comment></xsl:template><xsl:output method='xml' item-separator='§'/></xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=stylesheetStr, encoding="UTF-8")
    root = executable.call_template_returning_value("go")
    node  = root.head

    assert "<!--A-->§<out/>§<!--Z-->" == node.__str__()
    assert node.node_kind == 9

def testPipeline(saxonproc):
    stage1 = saxonproc.new_xslt30_processor()
    xsl = "<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='/'><a><xsl:copy-of select='.'/></a></xsl:template></xsl:stylesheet>"
    xml = "<z/>"
    executable1 = stage1.compile_stylesheet(stylesheet_text=xsl)
    in_ = saxonproc.parse_xml(xml_text=xml)
    stage2 = saxonproc.new_xslt30_processor()
    executable2 = stage2.compile_stylesheet(stylesheet_text=xsl)
    stage3 = saxonproc.new_xslt30_processor()
    executable3 = stage3.compile_stylesheet(stylesheet_text=xsl)
    stage4 = saxonproc.new_xslt30_processor()
    executable4 = stage4.compile_stylesheet(stylesheet_text=xsl)
    stage5 = saxonproc.new_xslt30_processor()
    executable5 = stage5.compile_stylesheet(stylesheet_text=xsl)
    assert in_ is not None
    executable1.set_property("!omit-xml-declaration", "yes")
    executable1.set_property("!indent", "no")
    executable1.set_initial_match_selection(xdm_value=in_)
    d1 = executable1.apply_templates_returning_value()
    assert d1 is not None
    executable2.set_property("!omit-xml-declaration", "yes")
    executable2.set_property("!indent", "no")
    executable2.set_initial_match_selection(xdm_value=d1)
    d2 = executable2.apply_templates_returning_value()
    assert d2 is not None
    executable3.set_property("!omit-xml-declaration", "yes")
    executable3.set_property("!indent", "no")
    executable3.set_initial_match_selection(xdm_value=d2)
    d3 = executable3.apply_templates_returning_value()
    assert d3 is not None
    executable4.set_property("!omit-xml-declaration", "yes")
    executable4.set_property("!indent", "no")
    executable4.set_initial_match_selection(xdm_value=d3)
    d4 = executable4.apply_templates_returning_value()
    assert d3 is not None
    executable5.set_property("!indent", "no")
    executable5.set_property("!omit-xml-declaration", "yes")
    executable5.set_initial_match_selection(xdm_value=d4)
    sw = executable5.apply_templates_returning_string()
    assert sw is not None
    assert "<a><a><a><a><a><z/></a></a></a></a></a>" in sw

def testPipelineShort(saxonproc):

    xsl = "<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='/'><a><xsl:copy-of select='.'/></a></xsl:template></xsl:stylesheet>"
    xml = "<z/>"
    stage1 = saxonproc.new_xslt30_processor()
    stage2 = saxonproc.new_xslt30_processor()
    executable1 = stage1.compile_stylesheet(stylesheet_text=xsl)
    executable2 = stage2.compile_stylesheet(stylesheet_text=xsl)
    executable1.set_property("!omit-xml-declaration", "yes")
    executable2.set_property("!omit-xml-declaration", "yes")
    in_ = saxonproc.parse_xml(xml_text=xml)
    assert in_ is not None
    executable1.set_initial_match_selection(xdm_value=in_)
    out = executable1.apply_templates_returning_value()
    assert out is not None
    executable2.set_initial_match_selection(xdm_value=out)
    sw = executable2.apply_templates_returning_string()
    assert "<a><a><z/></a></a>" in sw

def testCallFunction(saxonproc):

    source = "<?xml version='1.0'?><xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  xmlns:f='http://localhost/'  version='3.0'>  <xsl:function name='f:add' visibility='public'>    <xsl:param name='a'/><xsl:param name='b'/>   <xsl:sequence select='$a + $b'/></xsl:function>  </xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=source)
    paramArr = [saxonproc.make_integer_value(2), saxonproc.make_integer_value(3)]
    v = executable.call_function_returning_value("{http://localhost/}add", paramArr)
    assert isinstance(v.head, PyXdmItem)
    assert v.head.is_atomic
    assert v.head.get_atomic_value().integer_value ==5
    trans.clear_parameters()


def testCallFunctionArgConversion(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?><xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:f='http://localhost/'  version='3.0'>  <xsl:function name='f:add' visibility='public'> <xsl:param name='a' as='xs:double'/>  <xsl:param name='b' as='xs:double'/>  <xsl:sequence select='$a + $b'/> </xsl:function> </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    v = executable.call_function_returning_value("{http://localhost/}add", [saxonproc.make_integer_value(2), saxonproc.make_integer_value(3)])
    assert isinstance(v.head, PyXdmItem)
    assert v.head.is_atomic
    assert v.head.get_atomic_value().double_value == 5.0e0
    ''' assert ("double", $v.head.get_atomic_value()->getPrimitiveTypeName()
    '''
def testCallFunctionWrapResults(saxonproc):

    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?><xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema'  xmlns:f='http://localhost/'  version='3.0'> <xsl:param name='x' as='xs:integer'/>  <xsl:param name='y' select='.+2'/>  <xsl:function name='f:add' visibility='public'>  <xsl:param name='a' as='xs:double'/> <xsl:param name='b' as='xs:double'/> <xsl:sequence select='$a + $b + $x + $y'/> </xsl:function> </xsl:stylesheet>"
    executable= trans.compile_stylesheet(stylesheet_text=source)
    assert executable is not None
    executable.set_property("!omit-xml-declaration", "yes")
    x = saxonproc.make_integer_value(30)
    executable.set_parameter("x",  x)
    item = saxonproc.make_integer_value(20)
    executable.set_global_context_item(xdm_item=item)
    arg1 = saxonproc.make_integer_value(2)
    arg2 =  saxonproc.make_integer_value(3)
    sw = executable.call_function_returning_string("{http://localhost/}add", [arg1, arg2])
    assert sw is not None
    assert "57" in sw
    trans.clear_parameters()




def testCallFunctionArgInvalid(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:f='http://localhost/'  version='2.0'><xsl:function name='f:add'> <xsl:param name='a' as='xs:double'/>  <xsl:param name='b' as='xs:double'/>  <xsl:sequence select='$a + $b'/> </xsl:function> </xsl:stylesheet>"
    try:
        executable = trans.compile_stylesheet(stylesheet_text=source)
        argArr = [saxonproc.make_integer_value(2), saxonproc.make_integer_value(3)]
        v = executable.call_function_returning_value("{http://localhost/}add", argArr)
    except  Exception as err:
        assert "Cannot invoke function add#2 externally" in str(err)


def testCallNamedTemplateWithTunnelParams(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?> <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema' version='3.0'>  <xsl:template name='t'> <xsl:call-template name='u'/>  </xsl:template>  <xsl:template name='u'> <xsl:param name='a' as='xs:double' tunnel='yes'/>  <xsl:param name='b' as='xs:float' tunnel='yes'/>   <xsl:sequence select='$a + $b'/> </xsl:template> </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    executable.set_property("tunnel", "true")
    aVar = saxonproc.make_double_value(12)
    paramArr = {"a":aVar, "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(True, paramArr)
    sw = executable.call_template_returning_string("t")
    assert sw is not None
    assert "17" in sw

def testCallNamedTemplateWithTunnelParams2(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?> <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema' version='3.0'>  <xsl:template name='t'> <xsl:call-template name='u'/>  </xsl:template>  <xsl:template name='u'> <xsl:param name='a' as='xs:double' tunnel='yes'/>  <xsl:param name='b' as='xs:float' tunnel='yes'/>   <xsl:sequence select='$a + $b'/> </xsl:template> </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    executable.set_property("tunnel", "true")
    aVar = saxonproc.make_double_value(12)
    executable.set_initial_template_parameters(True, {"a":aVar, "b":saxonproc.make_integer_value(5)})
    sw = executable.call_template_returning_string("t")
    assert sw is not None
    assert "17" in sw

def testCallTemplateRuleWithParams(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?> <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'> <xsl:template match='*'>  <xsl:param name='a' as='xs:double'/>  <xsl:param name='b' as='xs:float'/>  <xsl:sequence select='name(.), $a + $b'/> </xsl:template>  </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(False, paramArr)
    in_ = saxonproc.parse_xml(xml_text="<e/>")
    executable.set_initial_match_selection(xdm_value=in_)
    sw = executable.apply_templates_returning_string()
    sw is not None
    assert "e 17" in sw

def testApplyTemplatesToXdm(saxonproc):
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  <xsl:template match='*'>     <xsl:param name='a' as='xs:double'/>     <xsl:param name='b' as='xs:float'/>     <xsl:sequence select='., $a + $b'/>  </xsl:template>  </xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(False, paramArr)
    executable.set_result_as_raw_value(True)
    in_put = saxonproc.parse_xml(xml_text="<e/>")
    executable.set_initial_match_selection(xdm_value=in_put)
    result = executable.apply_templates_returning_value()
    assert result is not None
    assert result.size == 2
    first = result.item_at(0)
    assert first.is_atomic == False
    assert "e" in first.get_node_value().name
    second = result.item_at(1)
    assert second.is_atomic
    assert second.get_atomic_value().double_value == 17.0

def testItemAtDownCast(saxonproc):
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  <xsl:template match='*'>     <xsl:param name='a' as='xs:double'/>     <xsl:param name='b' as='xs:float'/>     <xsl:sequence select='., $a + $b'/>  </xsl:template>  </xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(False, paramArr)
    executable.set_result_as_raw_value(True)
    in_put = saxonproc.parse_xml(xml_text="<e/>")
    executable.set_initial_match_selection(xdm_value=in_put)
    result = executable.apply_templates_returning_value()
    assert result is not None
    assert result.size == 2
    first = result.item_at(0)
    assert first.is_atomic == False
    assert isinstance(first, PyXdmNode)
    assert "e" in first.name
    second = result.item_at(1)
    assert isinstance(second, PyXdmAtomicValue)
    assert second.double_value == 17.0

def testResultDocument1(saxonproc):
    inputDoc = saxonproc.parse_xml(xml_text="<a>b</a>")
    assert inputDoc is not None
    xsl = "<xsl:stylesheet version='3.0'  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'> <xsl:template match='a'>   <c>d</c> </xsl:template> <xsl:template match='whatever'>   <xsl:result-document href='out.xml'>     <e>f</e>   </xsl:result-document> </xsl:template></xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=xsl)
    assert executable is not None

    executable.set_initial_match_selection(xdm_value=inputDoc)
    xdmValue = executable.apply_templates_returning_value()
    assert xdmValue.size == 1



def testResultDocumentAsMap(saxonproc):
    inputDoc = saxonproc.parse_xml(xml_text="<a>b</a>")
    assert inputDoc is not None
    xsl = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='a'><xsl:result-document href='out.xml'><e>f</e> </xsl:result-document> <xsl:result-document href='out2.xml'><e>hello</e> </xsl:result-document></xsl:template></xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=xsl)
    assert executable is not None
    executable.set_capture_result_documents(True)
    executable.set_initial_match_selection(xdm_value=inputDoc)
    executable.apply_templates_returning_value()

    rdocs_map = executable.get_result_documents()
    assert rdocs_map is not None
    assert len(rdocs_map) == 2
    keysList = [*rdocs_map.keys()]
    assert  keysList[0].endswith('out.xml')
    assert  keysList[1].endswith('out2.xml')
    assert isinstance(rdocs_map[keysList[0]].head, PyXdmNode)
    assert  'hello' in rdocs_map[keysList[1]].head.string_value

def testParseJson(saxonproc):
    json1 = """{ "test" : "This is a test. Price is higher than 25 €. " }"""

    try:
        parsed_json1 = saxonproc.parse_json(json_text=json1)
        print(parsed_json1)
        assert True
    except PySaxonApiError as e:
        print(e.message)
        assert False
    except Exception as e:
        print(e)
        assert False

def testParseJsonWithEncoding(saxonproc):
    json1 = """{ "test" : "This is a test. Price is higher than 25 €. " }"""

    try:
        parsed_json1 = saxonproc.parse_json(json_text=json1, encoding="UTF-8")
        print(parsed_json1)
        assert True
    except PySaxonApiError as e:
        print(e.message)
        assert False
    except Exception as e:
        print(e)
        assert False



def testParseJsonFunction(saxonproc):
    json1 = """{ "test" : "This is a test. Price is higher than 25 €. " }"""


    parse_json_fn = PyXdmFunctionItem().get_system_function(saxonproc, '{http://www.w3.org/2005/xpath-functions}parse-json', 1)

    try:
        parsed_json1 = parse_json_fn.call(saxonproc, [saxonproc.make_string_value(json1, encoding="UTF-8")])
        print(parsed_json1)
        assert True
    except PySaxonApiError as e:
        print(e.message)
        assert False

                                                                               

def testResultDocumentWitJson(saxonproc):
    inputDoc = saxonproc.parse_xml(xml_text="<a>b</a>")
    assert inputDoc is not None
    xsl = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template match='a'><xsl:result-document href='result-1.json' method='json'><xsl:sequence select='map { \"value\" : \"foo\" }'/></xsl:result-document></xsl:template></xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=xsl)
    assert executable is not None
    executable.set_capture_result_documents(True, True)
    executable.set_initial_match_selection(xdm_value=inputDoc)
    executable.apply_templates_returning_value()

    rdocs_map = executable.get_result_documents()
    assert rdocs_map is not None
    assert len(rdocs_map) == 1
    keysList = [*rdocs_map.keys()]
    assert  keysList[0].endswith('result-1.json')
    assert isinstance(rdocs_map[keysList[0]].head, PyXdmMap)

    
def testApplyTemplatesToFile(saxonproc):
    xsl = "<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>  <xsl:template match='a'> <c>d</c>  </xsl:template></xsl:stylesheet>"
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text=xsl)
    inputDoc = saxonproc.parse_xml(xml_text="<a>b</a>")
    inputDoc is not None
    executable.set_cwd('.')
    executable.set_output_file("output123.xml")
    executable.set_initial_match_selection(xdm_value=inputDoc)
    executable.apply_templates_returning_file(output_file="output123.xml")
    assert isfile("output123.xml") == True


'''@pytest.mark.skip('Error: Test can only run with a license file present')'''
def test_CallTemplateWithResultValidation(data_dir):
    try:
        saxonproc2 =  PySaxonProcessor(license=True)
        saxonproc2.set_cwd(files_dir)
        trans = saxonproc2.new_xslt30_processor()
        source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0' exclude-result-prefixes='#all'>  <xsl:import-schema><xs:schema><xs:element name='x' type='xs:int'/></xs:schema></xsl:import-schema>  <xsl:template name='main'>     <xsl:result-document validation='strict'>       <x>3</x>     </xsl:result-document>  </xsl:template>  </xsl:stylesheet>"

        executable = trans.compile_stylesheet(stylesheet_text=source)
        if executable is not None:

            trans.exception_clear
            assert executable is not None
            executable.set_property("!omit-xml-declaration", "yes")
            sw = executable.call_template_returning_string("main")

            assert sw is not None
            assert "<x>3</x>" == sw
        else:
            print(trans.error_message)
    except  Exception as err:
        print("Error: ", err)


def testXdmValueToString(saxonproc):
        xdm_value = PyXdmValue()

        xdm_value.add_xdm_item(saxonproc.make_string_value('foo'))

        print(xdm_value)

        xdm_value.add_xdm_item(saxonproc.make_string_value('bar'))

        print(xdm_value)
        assert True

def testXdmValueToString2(saxonproc):
        xdm_value = PyXdmValue()
        avalue = saxonproc.make_string_value('foo')
        xdm_value.add_xdm_item(avalue)

        print(xdm_value)

        avalue2 = saxonproc.make_string_value('bar')
        xdm_value.add_xdm_item(avalue2)

        print(xdm_value)
        assert True


def testCallTemplateNoParamsRaw(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    executable = trans.compile_stylesheet(stylesheet_text="<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'><xsl:template name='xsl:initial-template'><xsl:sequence select='42'/></xsl:template></xsl:stylesheet>")
    executable.set_result_as_raw_value(True)
    result = executable.call_template_returning_value()
    assert result is not None
    assert result.head is not None
    assert result.head.is_atomic == True
    assert result.head.get_atomic_value().integer_value == 42

def testCallNamedTemplateWithParamsRaw(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  <xsl:template name='t'>     <xsl:param name='a' as='xs:double'/>     <xsl:param name='b' as='xs:float'/>     <xsl:sequence select='$a+1, $b+1'/>  </xsl:template>  </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_result_as_raw_value(True)
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    print(paramArr)
    executable.set_initial_template_parameters(False, paramArr)
    val = executable.call_template_returning_value("t")
    assert val is not None
    print(val)
    assert val.size == 2
    assert val.item_at(0).is_atomic
    assert val.item_at(0).get_atomic_value().integer_value == 13
    assert val.item_at(1).get_atomic_value().integer_value == 6

def testApplyTemplatesRaw(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  <xsl:template match='*'>     <xsl:param name='a' as='xs:double'/>     <xsl:param name='b' as='xs:float'/>     <xsl:sequence select='., $a + $b'/>  </xsl:template>  </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    node = saxonproc.parse_xml(xml_text="<e/>")
    executable.set_result_as_raw_value(True)
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(False, paramArr)
    executable.set_initial_match_selection(xdm_value=node)
    result = executable.apply_templates_returning_value()
    assert result is not None
    assert result.size ==2
    first = result.item_at(0)
    assert first is not None
    assert first.is_atomic == False
    assert first.get_node_value().name == "e"
    second = result.item_at(1)
    assert second is not None
    assert second.is_atomic
    assert second.get_atomic_value().double_value == 17.0

def testApplyTemplatesToSerializer(saxonproc):
    trans = saxonproc.new_xslt30_processor()
    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0'>  <xsl:output method='text' item-separator='~~'/>  <xsl:template match='.'>     <xsl:param name='a' as='xs:double'/>     <xsl:param name='b' as='xs:float'/>     <xsl:sequence select='., $a + $b'/>  </xsl:template>  </xsl:stylesheet>"
    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    executable.set_result_as_raw_value(True)
    paramArr = {"a":saxonproc.make_integer_value(12), "b":saxonproc.make_integer_value(5)}
    executable.set_initial_template_parameters(False, paramArr)

    executable.set_initial_match_selection(xdm_value=saxonproc.make_integer_value(16))
    sw = executable.apply_templates_returning_string()
    assert "16~~17" == sw


''' PyXQueryProcessor '''
def test_return_document_node(saxonproc):
    node = saxonproc.parse_xml(xml_text='<foo/>')
    assert node is not None
    xqc = saxonproc.new_xquery_processor()
    xqc.set_query_content('document{.}')
    xqc.set_context(xdm_item=node)
    result = xqc.run_query_to_value()
    if isinstance(result, PyXdmNode):
        assert result.node_kind == DOCUMENT

def testxQuery1(saxonproc, data_dir):
    query_proc = saxonproc.new_xquery_processor()
    query_proc.set_cwd(os.getcwd())
    query_proc.clear_properties()
    query_proc.clear_parameters()
    xmlFile = os.path.join(data_dir, "cat.xml")
    query_proc.set_property("s", xmlFile)
    query_proc.set_property("qs", "<out>{count(/out/person)}</out>")
    result = query_proc.run_query_to_string()
    assert result is not None
    print(result)

    print(os.getcwd())
    query_proc.run_query_to_file(output_file_name="catOutput.xml")
    assert os.path.exists("catOutput.xml")
    node = saxonproc.parse_xml(xml_file_name='catOutput.xml')
    assert node is not None
    xp = saxonproc.new_xpath_processor()
    xp.set_context(xdm_item=node)
    assert xp.effective_boolean_value("/out/text()=3")
    if os.path.exists('catOutput.xml'):
        os.remove("catOutput.xml")

def testxQuery2(saxonproc, data_dir):
    query_proc = saxonproc.new_xquery_processor()
    query_proc.set_cwd(os.getcwd()+'/')
    saxonproc.set_cwd(os.getcwd()+'/')
    query_proc.clear_properties()
    query_proc.clear_parameters()
    xmlFile = os.path.join(data_dir, "cat.xml")
    query_proc.set_property("s", xmlFile)
    query_proc.set_property("qs", "<out>{count(/out/person)}</out>")
    result = query_proc.run_query_to_string()
    assert result is not None
    print(result)

    print(os.getcwd())
    query_proc.run_query_to_file(output_file_name="catOutput2.xml")
    assert os.path.exists("catOutput2.xml")
    builder = saxonproc.new_document_builder()

    node = builder.parse_xml(xml_file_name='catOutput2.xml')
    assert node is not None
    xp = saxonproc.new_xpath_processor()
    xp.set_context(xdm_item=node)
    assert xp.effective_boolean_value("/out/text()=3")
    if os.path.exists('catOutput2.xml'):
        os.remove("catOutput2.xml")

def testxQuery_encoding1(saxonproc, data_dir):
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <salary>3000 €</salary>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    query_proc = saxonproc.new_xquery_processor()
    query_proc.set_cwd(os.getcwd()+'/')
    node = saxonproc.parse_xml(xml_text=xml, encoding="UTF-8")
    result = query_proc.run_query_to_value(input_xdm_item=node, query_text="/out/salary/text() = '3000 €'", encoding="UTF-8")
    assert result.head.get_atomic_value().boolean_value
    print(result)

def test_default_namespace(saxonproc):
    query_proc = saxonproc.new_xquery_processor()
    query_proc.declare_namespace("", "http://one.uri/")
    node = saxonproc.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar/></foo>")
    query_proc.set_context(xdm_item=node)
    query_proc.set_query_content("/foo")
    value = query_proc.run_query_to_value()
    assert value.size == 1

def test_document_builder(saxonproc):
    builder = saxonproc.new_document_builder()
    builder.set_base_uri("file:/tmp")
    node = builder.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar/></foo>")
    assert node is not None
    assert node.base_uri == "file:/tmp"

def test_default_namespace2(saxonproc):
    query_proc = saxonproc.new_xquery_processor()
    query_proc.declare_namespace("", "http://one.uri/")
    node = saxonproc.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar/></foo>")
    value = query_proc.run_query_to_value(input_xdm_item=node, query_text="/foo")
    assert value.size == 1

def test_XQuery_line_number():
    ''' No license file given therefore result will return None'''
    try:
        proc = PySaxonProcessor(license=True)
        proc.set_configuration_property("l", "on")
        query_proc = proc.new_xquery_processor()

        query_proc.set_property("s", "cat.xml")
        query_proc.declare_namespace("saxon","http://saxon.sf.net/")
        query_proc.set_property("qs", "saxon:line-number(doc('cat.xml')/out/person[1])")
        result = query_proc.run_query_to_string()
        assert result == None
    except  Exception as err:
        print("Error: ", err)

def testReusability(saxonproc):
    queryproc = saxonproc.new_xquery_processor()
    queryproc.clear_properties()
    queryproc.clear_parameters()
    input_ =  saxonproc.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar xmlns='http://two.uri'>12</bar></foo>")
    queryproc.declare_namespace("", "http://one.uri/")
    queryproc.set_query_content("declare variable $p as xs:boolean external; exists(/foo) = $p")
    queryproc.set_context(xdm_item=input_)
    value1 = saxonproc.make_boolean_value(True)
    queryproc.set_parameter("p",value1)
    result = queryproc.run_query_to_value()
    item = result.head
    assert result is not None
    assert item.is_atomic
    assert item.boolean_value
    queryproc.clear_parameters()
    queryproc.clear_properties()

    queryproc.declare_namespace("", "http://two.uri")
    queryproc.set_query_content("declare variable $p as xs:integer external; /*/bar + $p")

    queryproc.set_context(xdm_item=input_)
    value2 = saxonproc.make_long_value(6)
    queryproc.set_parameter("p",value2)

    result2 = queryproc.run_query_to_value()
    item2 = result2.head
    assert item2.integer_value == 18


def testQueryKeyWords(saxonproc, data_dir):
    queryproc = saxonproc.new_xquery_processor()
    queryproc.clear_properties()
    queryproc.clear_parameters()
    input_ =  saxonproc.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar xmlns='http://two.uri'>12</bar></foo>")
    queryproc.declare_namespace("", "http://one.uri/")
    value1 = saxonproc.make_boolean_value(True)
    queryproc.set_parameter("p",value1)
    foo_file = os.path.join(data_dir, "foo.xq")
    result = queryproc.run_query_to_value(query_file=foo_file, input_xdm_item=input_)
    item = result.head
    assert result is not None
    assert item.is_atomic
    assert item.boolean_value
    queryproc.clear_parameters()
    queryproc.clear_properties()

def testQueryKeyWords_string(saxonproc, data_dir):
    queryproc = saxonproc.new_xquery_processor()
    queryproc.clear_properties()
    queryproc.clear_parameters()
    input_ =  saxonproc.parse_xml(xml_text="<foo xmlns='http://one.uri/'><bar xmlns='http://two.uri'>12</bar></foo>")
    queryproc.declare_namespace("", "http://one.uri/")
    value1 = saxonproc.make_boolean_value(True)
    queryproc.set_parameter("p",value1)
    foo_file = os.path.join(data_dir, "foo.xq")
    result = queryproc.run_query_to_string(query_file=foo_file, input_xdm_item=input_)
    assert result is not None
    queryproc.clear_parameters()
    queryproc.clear_properties()

def test_make_string_value(saxonproc):
    xdm_string_value = saxonproc.make_string_value('text1')

    print(xdm_string_value)
    xquery_processor = saxonproc.new_xquery_processor()
    xquery_processor.set_parameter('s1', xdm_string_value)
    result = xquery_processor.run_query_to_value(query_text = 'declare variable $s1 external; $s1')
    item1 = result.head

    assert result is not None
    assert isinstance(item1, PyXdmAtomicValue)
    assert item1.string_value == "text1"

"""PyXPathProcessor test cases"""
def test_xpath_proc(saxonproc, data_dir):
    sp = saxonproc
    xp = saxonproc.new_xpath_processor()
    xmlFile = os.path.join(data_dir, "cat.xml")
    assert isfile(xmlFile)
    xp.set_context(file_name=xmlFile)
    assert xp.effective_boolean_value('count(//person) = 3')
    assert not xp.effective_boolean_value("/out/person/text() = 'text'")

def test_xpath_proc_http(saxonproc, data_dir):
    sp = saxonproc
    xp = saxonproc.new_xpath_processor()
    xmlFile = os.path.join(data_dir, "cat.xml")
    assert isfile(xmlFile)
    xp.set_context(file_name=xmlFile)
    result = xp.evaluate_single("doc('https://www.w3schools.com/xml/note.xml')")
    assert 'Jani' in result.string_value

def test_atomic_values():
    sp = PySaxonProcessor()
    value = sp.make_double_value(3.5)
    boolVal = value.boolean_value
    assert boolVal == True
    assert value.string_value == '3.5'
    assert value.double_value == 3.5
    assert value.integer_value == 3
    primValue = value.primitive_type_name
    assert primValue == 'Q{http://www.w3.org/2001/XMLSchema}double'

def test_node_list():
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()

    node = sp.parse_xml(xml_text=xml)
    outNode = node.children[0]
    children = outNode.children
    personData = str(children)
    assert ('<person att1' in personData)

def test_parse_xml_file1(data_dir):
    sp = PySaxonProcessor()

    node = sp.parse_xml(xml_file_name=os.path.join(data_dir, "cat.xml"))
    outNode = node.children[0]
    assert outNode.name == 'out'

def test_node():
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()

    node = sp.parse_xml(xml_text=xml)
    assert node.node_kind == 9
    assert node.size == 1
    outNode = node.children[0]
    assert outNode.name == 'out'
    assert outNode.node_kind == 1
    children = outNode.children
    attrs = children[1].attributes
    assert len(attrs) == 2
    assert children[1].get_attribute_value('att2') == 'value2'
    assert 'value2' in attrs[1].string_value

def test_evaluate():
        xml = """\
        <out>
            <person att1='value1' att2='value2'>text1</person>
            <person>text2</person>
            <person>text3</person>
        </out>
        """
        sp = PySaxonProcessor()
        xp = sp.new_xpath_processor()

        node = sp.parse_xml(xml_text=xml)
        assert isinstance(node, PyXdmNode)
        xp.set_context(xdm_item=node)
        value = xp.evaluate('//person')
        assert isinstance(value, PyXdmValue)
        assert value.size == 3

def test_evaluate_encoding():
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <salary>3000 €</salary>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()
    xp = sp.new_xpath_processor()

    node = sp.parse_xml(xml_text=xml)
    assert isinstance(node, PyXdmNode)
    xp.set_context(xdm_item=node)
    value = xp.evaluate('//salary', encoding="UTF-8")
    assert isinstance(value, PyXdmValue)
    assert value.head.get_string_value(encoding="UTF-8") == "3000 €"

def test_xdm_value_iter():
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()
    xp = sp.new_xpath_processor()
    node = sp.parse_xml(xml_text=xml)
    assert isinstance(node, PyXdmNode)
    xp.set_context(xdm_item=node)
    value = xp.evaluate('//person')
    assert value.size == 3
    for item in value:
        assert isinstance(item, PyXdmItem)

def test_xdm_value_iter2():
    xml = """\
    <out>
        <person att1='value1' att2='value2'>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()
    xp = sp.new_xpath_processor()
    node = sp.parse_xml(xml_text=xml)
    assert isinstance(node, PyXdmNode)
    xp.set_context(xdm_item=node)
    value = xp.evaluate('//person')
    assert value.size == 3
    for item in value:
        assert 'text' in item.string_value

def test_single():
    xml = """\
    <out>
        <person>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>
    """
    sp = PySaxonProcessor()
    xp = sp.new_xpath_processor()

    node = sp.parse_xml(xml_text=xml)
    assert isinstance(node, PyXdmNode)
    xp.set_context(xdm_item=node)
    item = xp.evaluate_single('//person[1]')
    assert isinstance(item, PyXdmItem)
    assert item.size == 1
    assert not item.is_atomic
    assert item.__str__() == '<person>text1</person>'

def test_declare_variable_value1(saxonproc):
    mystr = 'This is a test.'
    xdm_string_value = saxonproc.make_string_value(mystr)
    assert 'This is a test.' in xdm_string_value.string_value
    xpath_processor = saxonproc.new_xpath_processor()
    xpath_processor.declare_variable("s1")
    xpath_processor.set_parameter('s1', xdm_string_value)
    result = xpath_processor.evaluate('$s1')
    assert result is not None
    item = result.head
    assert 'test.' in item.string_value

def test_declare_variable_value2(saxonproc):
    try:
        s1 = 'This is a test.'
        xdm_string_value = saxonproc.make_string_value(s1)
        xpath_processor = saxonproc.new_xpath_processor()
        result = xpath_processor.evaluate('$s1')
        assert result is None
    except Exception as err:
        assert 'No value has been supplied for variable $s1' in str(err)

def test_packages(data_dir):
    sp = PySaxonProcessor(license=True)
    xsl = """\
    <xsl:package name = \"package-002.xsl\" package-version = \"2.1.0.5\"
    version = \"3.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">
    <xsl:param name='c' select='2'/>
    <xsl:mode/>
    <xsl:template match='/'>
    <out><xsl:apply-templates/></out>
    </xsl:template>
    <xsl:template match='/*'>
    <in><xsl:value-of select='name()'/></in>
    </xsl:template>
    </xsl:package>
    """
    xsltproc = sp.new_xslt30_processor()
    xsltproc.compile_stylesheet(stylesheet_text=xsl, save=True, output_file='package02.xsltpack')
    xsltproc = None
    xsltproc2 = sp.new_xslt30_processor()
    xsltproc2.transform_to_string(source_file=os.path.join(data_dir, "books.xml"), stylesheet_file="package02.xsltpack")

@pytest.mark.skip('Error: SaxonDll.processor is nullptr in constructor(configFile)')
def test_add_packages(data_dir):
    sp = PySaxonProcessor(config_file=os.path.join(data_dir, "config_file.xml"))
    assert sp is not None
    assert isinstance(sp, PySaxonProcessor)
    xsl = sp.new_xslt30_processor()
    result = xsl.transform_to_string(source_file=os.path.join(data_dir, "package-00.xml"), stylesheet_file=os.path.join(data_dir, "package-019.xsl"))

    assert result is not None
    assert 'You found me!' in result

"""Test case should be run last to test release() """
def test_apply():
    with PySaxonProcessor(license=False) as proc:
        xsltproc = proc.new_xslt30_processor()
        document = proc.parse_xml(xml_text="<out><person>text1</person><person>text2</person><person>text3</person></out>")

        executable = xsltproc.compile_stylesheet(stylesheet_text="<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='2.0'>       <xsl:param name='values' select='(2,3,4)' /><xsl:output method='xml' indent='yes' /><xsl:template match='*'><output><xsl:value-of select='//person[1]'/><xsl:for-each select='$values' ><out><xsl:value-of select='. * 3'/></out></xsl:for-each></output></xsl:template></xsl:stylesheet>")
        executable.set_initial_match_selection(xdm_value=document)
        executable.set_global_context_item(xdm_item=document)
        output2 = executable.apply_templates_returning_string()
        assert output2 is not None
        assert output2.startswith('<?xml version="1.0" encoding="UTF-8"?>\n<output>text1<out>6</out')



def testMapOperations(saxonproc):

        mymap = {saxonproc.make_string_value("a"):saxonproc.make_integer_value(1), saxonproc.make_string_value("b"):saxonproc.make_integer_value(2),
                 saxonproc.make_string_value("c"):saxonproc.make_integer_value(3)}
        map =saxonproc.make_map(mymap)
        assert map is not None
        print(map.values())
        assert map.map_size == 3


def testMapOperations2(saxonproc):

        mymap = {"a":saxonproc.make_integer_value(1), "b":saxonproc.make_integer_value(2),
                 "c":saxonproc.make_integer_value(3)}

        xdmdict = create_xdm_dict(saxonproc, mymap)
        map =saxonproc.make_map(xdmdict)
        assert map is not None
        print(map.values())
        assert map.map_size == 3


def testMapOperations3(saxonproc):

        thisdict = {"a":1, "b":2,"c":5}
        xdmdict = create_xdm_dict(saxonproc, thisdict)
        xdm_map =saxonproc.make_map(xdmdict)
        assert xdm_map is not None
        print(xdm_map.values())
        assert xdm_map.map_size == 3



def testMapValues(saxonproc):

    mymap = {"a":saxonproc.make_integer_value(1), "b":saxonproc.make_integer_value(2), "c":saxonproc.make_integer_value(5)}
    xdmdict = create_xdm_dict(saxonproc, mymap)
    map =saxonproc.make_map(xdmdict)
    assert map is not None
    assert map.map_size == 3
    mapList = map.values()
    assert len(mapList) == 3
    print(mapList)
    item = mapList[2].head
    assert isinstance(item, PyXdmAtomicValue)
    assert item.integer_value == 5


def testXdmArray1(saxonproc):

    list1 = [1,2,3]

    xdmValueList1 = [saxonproc.make_integer_value(i) for i in list1]


    xdmArray1 = saxonproc.make_array(xdmValueList1)

    assert xdmArray1 is not None
    assert isinstance(xdmArray1, PyXdmArray)

    assert xdmArray1.array_length == 3



def testMapPutOperations(saxonproc):

    mymap = {saxonproc.make_string_value("a"):saxonproc.make_integer_value(1)}
    map =saxonproc.make_map(mymap)
    assert map is not None
    map1= map.put(saxonproc.make_string_value("b"), saxonproc.make_integer_value(2))
    assert map1 is not None
    map2 = map1.put(saxonproc.make_string_value("c"), saxonproc.make_integer_value(3))
    assert map2 is not None
    assert map2.map_size == 3

def testConversionFromPythonMap(saxonproc):
    mymap = {saxonproc.make_string_value("a"):saxonproc.make_integer_value(1), saxonproc.make_string_value("b"):saxonproc.make_integer_value(2), saxonproc.make_string_value("c"):saxonproc.make_integer_value(3)}
    map =saxonproc.make_map(mymap)
    assert map is not None
    assert map.map_size == 3
    bKey = saxonproc.make_string_value("b")
    dVar = map.get(bKey)
    assert dVar is not None
    print(dVar)
    assert dVar.head == 2

    cKey = saxonproc.make_string_value("c")
    dKey = saxonproc.make_string_value("d")
    map = map.remove(cKey)
    map = map.remove(dKey)
    map = map.put( saxonproc.make_string_value("a"), saxonproc.make_integer_value(4))
    assert map.map_size == 2
    aVar =   map.get("a")
    assert aVar is not None
    aVar.head.integer_value == 4


def testArrayFromList(saxonproc):
    list1 = [1,2,3]

    xdmValueList1 = [saxonproc.make_integer_value(i) for i in list1]

    assert xdmValueList1 is not None

    xdmArray1 = saxonproc.make_array(xdmValueList1)

    assert xdmArray1 is not None
    assert isinstance(xdmArray1, PyXdmArray)

    assert xdmArray1.array_length == 3
    list1FromXdmArray = xdmArray1.as_list()

    assert list1FromXdmArray is not None
    assert len(list1FromXdmArray) == 3
    assert isinstance(list1FromXdmArray[0].head.get_atomic_value(), PyXdmAtomicValue)
    assert list1FromXdmArray[0].head.get_atomic_value().integer_value == 1
    assert list1FromXdmArray[1].head.get_atomic_value().integer_value == 2


def testMapAsFunction():
    with PySaxonProcessor(license=False) as saxonproc:
        mymap = {"a":saxonproc.make_integer_value(1), "b":saxonproc.make_integer_value(2), "c":saxonproc.make_integer_value(3)}
        xdmdict = create_xdm_dict(saxonproc, mymap)
        map =saxonproc.make_map(xdmdict)

        assert map is not None
        cVar = saxonproc.make_string_value("c")
        result = map.call(saxonproc, [cVar])
        assert result is not None
        item = result.head
        assert isinstance(item, PyXdmAtomicValue)

        assert item.integer_value == 3
        assert item.integer_value == 3


def testMapAsQueryParameter():

    with PySaxonProcessor(license=False) as saxonproc:
        mymap = {saxonproc.make_string_value("a"):saxonproc.make_integer_value(1), saxonproc.make_string_value("b"):saxonproc.make_integer_value(2), saxonproc.make_string_value("c"):saxonproc.make_integer_value(3)}
        map =saxonproc.make_map(mymap)
        assert map is not None

        query = """\
        declare namespace m='http://www.w3.org/2005/xpath-functions/map';declare variable $a as map(*) external; m:size($a)
        """
        query_proc = saxonproc.new_xquery_processor()
        query_proc.set_query_content(query)
        query_proc.set_parameter("a", map)
        result = query_proc.run_query_to_value()
        assert result is not None
        assert result.head.integer_value == 3


def testMapAsQueryResult():
    with PySaxonProcessor(license=False) as proc:
        query = "map{1:2, 2:3, 3:4}"
        query_proc = proc.new_xquery_processor()
        query_proc.set_query_content(query)
        result = query_proc.run_query_to_value()

        dvar = result.head
        assert isinstance(dvar, PyXdmMap)

        assert dvar.map_size == 3

def testMap2():

    with PySaxonProcessor(license=False) as proc:
        query = "map{1:2, 2:3, 3:4}"
        query_proc = proc.new_xquery_processor()
        query_proc.set_query_content(query)
        result = query_proc.run_query_to_value()
        assert result is not None
        print(result)
        assert isinstance(result, PyXdmValue)
        mmVar = result.head
        assert mmVar is not None
        assert isinstance(mmVar, PyXdmMap)

        assert mmVar.map_size == 3

        avar = mmVar.get(3)
        assert avar is not None
        assert avar.head.integer_value == 4







