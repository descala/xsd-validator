import urllib.parse

from saxonche import *
import os
import psutil
from Environment import Environment, Spec
from test_outcome import PyTestOutcome
from test_report import PyTestReport
import sys, getopt
from urllib.parse import urlparse
from os.path import abspath
from os.path import isfile
from datetime import datetime as date

process = psutil.Process()
start_memory = process.memory_info().rss

path = None
results_path = None
catalog = None
saxon_version = "12.4.2"

assert_set = set()

alwaysOn = {"feature/serialization", "feature/namespace_axis", "feature/dtd", "feature/built_in_derived_types"
    , "feature/higher_order_functions", "feature/remote_http", "feature/fn-transform-XSLT"
    , "available_documents", "default_calendar_in_date_formatting_functions",
            "supported_calendars_in_date_formatting_functions"
    , "maximum_number_of_decimal_digits", "default_output_encoding", "unparsed_text_encoding"
    , "feature/XPath_3.1", "feature/backwards_compatibility", "feature/HTML4", "feature/HTML5", "feature/XPath_3.1",
            "feature/dynamic_evaluation", "feature/schema_aware", "feature/disabling_output_escaping"}

alwaysOff = {"feature/xsl-stylesheet-processing-instruction",
             "ordinal_scheme_name", "recognize_id_as_uri_fragment", "feature/XML_1.1", "feature/dtd", "feature/HTML4",
             "feature/HTML5",
             "feature/streaming", "detect_accumulator_cycles"}
'''  should be set on alwaysOff testing for now: "feature/simple-uca-fallback", "feature/advanced-uca-fallback"'''
driver_proc = PySaxonProcessor(license=True)
'''driver_proc.set_configuration_property("http://saxon.sf.net/feature/licenseFileLocation",
                                       "/Users/ond1/work/development/git/private/saxon-license.lic")'''
driver_proc.set_cwd(os.getcwd())
cat_builder = None

xqueryproc = driver_proc.new_xquery_processor()

xpathProcForEnv = driver_proc.new_xpath_processor()

xpathProcForCompareNodes = driver_proc.new_xpath_processor()

xpathProcForCompareNodes.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")

schemaValidator = None
test_report = None

old_xsd_version = "1.1"
current_xsd_version = "1.1"

spec: Spec

globalEnvironments = {}
localEnvironments = {}
xpathProcForEnv.declare_namespace("", "http://www.w3.org/2010/09/qt-fots-catalog")
edition = "EE"
host_lang = "XQ30"
successes = 0
failures = 0
error = 0
not_run = 0
wrong_error_results = 0
debug = False

test_case_found = False

run_test = None
'''"streamable"'''
run_test_case_name = None
'''result-document-0206'''
run_assertion = None
'''serialization-matches'''
total_tests = 0
exceptionList = []


def process_spec(spec_str: str):
    if spec_str == "XP20":
        return Spec.XP20()
    elif spec_str == "XP30":
        return Spec.XP30()
    elif spec_str == "XP31":
        return Spec.XP31()
        
    elif spec_str == "XP40":
        return Spec.XP40()
                
    elif spec_str == "XQ10":
        return Spec.XQ10()
        
    elif spec_str == "XQ30":
        return Spec.XQ30()

    elif spec_str == "XQ31":
        return Spec.XQ31()

    elif spec_str == "XQ40":
        return Spec.XQ40()

    elif spec_str == "XT30":
        return Spec.XT30()
    else:
        raise Exception("The specific language must be one of the following: XP20, XP30, XP31, XP40, XQ10, XQ30, XQ31, XQ40, XT30")



def process_catalog(path: str, catalogi):
    att_name = None
    att_file = None
    global cat_builder
    global test_report
    global saxon_version
    global results_path
    global test_case_found
    global schemaValidator
    cat_builder = driver_proc.new_document_builder()
    xpc = driver_proc.new_xpath_processor()
    if os.getenv("SAXON_LICENSE_DIR")  is not None:
        driver_proc.set_configuration_property("http://saxon.sf.net/feature/licenseFileLocation",
                                       os.getenv("SAXON_LICENSE_DIR" + "/saxon-license.lic"))
    try:
        schemaValidator = driver_proc.new_schema_validator()
    except PySaxonApiError as ex:
        print("*** Failed to create PySchemaValidator :" + str(ex))

    '''xpc.set_lanaguage("3.1")'''
    if os.path.exists(catalogi):
        '''catalog_node = cat_builder.parse_xml(xml_file_name=catalogi)'''
        catalog_node = driver_proc.parse_xml(xml_file_name=catalogi)

        test_report.write_result_file_preamble(driver_proc, "xslt30", [])

        create_global_environment(catalog_node, xpc)

        '''TODO read_exceptions_file()'''
        xpathProcForEnv.set_context(xdm_item=catalog_node)
        xml = xpathProcForEnv.evaluate("//*:test-set")
        if xml is not None:
            print("<b>Test sets: " + str(xml.size) + "<b/> See <a href='#results'> Results here </a>")

            for i in range(xml.size):
                value = xml.item_at(i)
                if value is not None and value.is_node:
                    node = value.get_node_value()
                    if node is not None:
                        att_name = node.get_attribute_value("name")
                        att_file = node.get_attribute_value("file")
                        if run_test is not None and att_name != run_test or att_name in exceptionList:
                            continue
                        process_test_set(cat_builder, driver_proc, path + att_file)
                        if test_case_found:
                            break
                    else:
                        print("Node for test-set is None")
                else:
                    print("Value for test-set is NULL")
            print("Total number of tests: #" + str(total_tests))
            print("Result: " + str(successes) + " successes, " + str(failures) + " failures, " +
                  str(wrong_error_results) + " incorrect ErrorCode, " + str(not_run) + " not run")
            '''write resultpostamble'''
            if results_path is None:
                results_path = path
            test_report.write_result_file_postamble(driver_proc, results_path)
        else:
            print('Failed to open ' + catalogi)


def process_test_set(doc_builderi: PyDocumentBuilder, proci: PySaxonProcessor, test_set_file: str):
    global total_tests
    global localEnvironments
    global not_run
    global test_report
    global test_case_found

    localEnvironments.clear()
    if os.path.exists(test_set_file):

        test_set_xml = doc_builderi.parse_xml(xml_file_name=test_set_file)

        if test_set_xml is not None:
            create_local_environments(test_set_xml, xpathProcForEnv)
            test_set_nodes = test_set_xml.axis_nodes(3)
            child0 = None
            for x in test_set_nodes:
                if x.node_kind == 1:
                    child0 = x
                    break
            xpathProcForEnv.set_context(xdm_item=child0)
            envs = xpathProcForEnv.evaluate("//environment[@name]")

            dependencies = xpathProcForEnv.evaluate("//test-set/dependency")

            xpathProcForEnv.set_context(xdm_item=test_set_xml)
            test_cases = xpathProcForEnv.evaluate("//*:test-case")
            tcs_count = 0
            if test_cases is not None:
                tcs_count = test_cases.size
                total_tests += tcs_count

            if dependencies is not None:

                for ii in range(dependencies.size):
                    dep = dependencies.item_at(ii).get_node_value()
                    if not ensure_dependency_satisfied(dep, localEnvironments["default"]):
                        print("dependency failed at test set level")
                        test_report.start_test_set_element(child0, "dependency not satisfied")
                        not_run = not_run + tcs_count
                        return

            if envs is not None:
                for i in range(envs.size):
                    environment = Environment()
                    if dependencies is not None:

                        for ii in range(dependencies.size):
                            dep = dependencies.item_at(ii).get_node_value()
                            if not ensure_dependency_satisfied(dep, environment):
                                print("dependency failed at test set level XXXX")
                                return
                    env = envs.item_at(i)
                    process_environment(xpathProcForEnv, env.get_node_value(), spec, localEnvironments,
                                        environment)
            if child0 is None:
                print("Cannot find child node of test " + test_set_file)

                return None
            else:
                test_set_name = child0.get_attribute_value("name")
                '''if run_test is not None and test_set_name is not run_test:
                    return None'''
                ''' get environment'''

                '''print(test_set_file)
                    print("Test cases count = " + str(tcs_count))'''
                result = "NA"
                test_report.start_test_set_element(child0, None)

                for x, test_case in enumerate(test_cases):
                        if test_case.is_node:
                            test_casei = test_case.get_node_value()
                            test_case_name = test_casei.get_attribute_value("name")
                            if (run_test_case_name is None or test_case_name == run_test_case_name) and test_set_name not in exceptionList:
                                print("-s:" + test_set_name + " -t:" + test_case_name)
                                run_test_case(test_case, xpathProcForEnv)
                                if run_test_case_name is not None:
                                    test_case_found = True
                                    break
                        else:
                            print("Error test_case is not a node")




        else:
            print("Cannot find test " + test_set_file)


''', catalog_xpath_proci'''


def is_applicable_to_spec_version(value, spec):
    applicable = False
    if not (spec.short_spec_name in value):
        applicable = False
    elif spec.spec_and_version in value:
        applicable = True
    elif (spec.spec_and_version == "XQ30" or spec.spec_and_version == "XQ31" or spec.spec_and_version == "XQ40") and ("XQ10+" in value or "XQ30+" in value or "XQ31+" in value):
        applicable = True
    elif (spec.spec_and_version == "XP30" or spec.spec_and_version == "XP31" or spec.spec_and_version == "XP40") and ("XP20+" in value or "XP30+" in value or "XP31+" in value):
        applicable = True
    return applicable



def ensure_dependency_satisfied(dependency: PyXdmNode, env: Environment):
    global alwaysOn
    global spec
    global current_xsd_version
    global old_xsd_version
    ''' TODO the local_name property will be used in SaxonC 12.3 release '''
    typei = dependency.get_attribute_value("type")

    value = dependency.get_attribute_value("value")
    if value is None:
        value = "*"

    tv = typei + "/" + value

    inverse = "false" == dependency.get_attribute_value("satisfied")

    needed = "false" != dependency.get_attribute_value("satisfied")

    if typei in alwaysOn or tv in alwaysOn:
        '''print("dependency on")
        exit()'''
        return needed

    if typei in alwaysOff or tv in alwaysOff:
        '''print("dependency on")
        exit()'''
        return not needed

    if typei == "spec":
        return is_applicable_to_spec_version(value, spec)
    elif typei == "feature":
        if value == "XML_1.1":
            '''TODO handle XML 1.1 by logic to reset environment'''
            return False
        elif value == "serialization":
            return True
        elif value == "streaming-fallback":
            return False
        elif value == "advanced-uca-fallback":
            return False
        elif value == "simple-uca-fallback":
            return False
        elif value == "staticTyping":
            return inverse
        elif value == "collection-stability":
            return inverse
        elif value == "higher_order_functions":
            return not inverse
        else:
            '''Check this path'''
            return False
    elif typei == "year_component_values":
        if (value == "support year above 9999" or value == "support negative year"
                or value == "support year zero"):
            return True

    elif typei == "default-language":
        return ("en" == value) != inverse
    elif typei == "xsd-version":
        old_xsd_version = current_xsd_version
        if value == "1.0":
            env.proc.set_configuration_property("http://saxon.sf.net/feature/xsd-version", "1.0")
            current_xsd_version = "1.0"
            env.reset_actions.append(lambda x : x.set_configuration_property("http://saxon.sf.net/feature/xsd-version", old_xsd_version))
        elif value == "1.1":
            env.proc.set_configuration_property("http://saxon.sf.net/feature/xsd-version", "1.1")
            env.reset_actions.append(lambda x: x.set_configuration_property("http://saxon.sf.net/feature/xsd-version", old_xsd_version))
            current_xsd_version = "1.1"

        return True

    return True

def cwd_from_base_uri(base_uri: str):
    cwd = os.path.dirname(urlparse(base_uri).path)
    if os.path.isdir(cwd):
        return cwd
    raise IOError("Specified directory <%s> does not exist!" % cwd)

def process_environment(xpc: PyXPathProcessor, env: PyXdmNode, spec: Spec, environments_i: dict,
                        environment: Environment):
    environment.create_processors()
    xpc.set_context(xdm_item=env)
    name = env.get_attribute_value("name")
    if name is not None:
        print("Loading environment " + name)
        environments_i[name] = environment
        '''if name == "works-mod":
            print(env)
            exit(0)'''
    else:
        print("Loading environment without name")

    '''set the base URI if specified'''
    base_uri = str(env.base_uri)

    environment.proc.set_cwd(cwd_from_base_uri(base_uri))
    environment.xquery_proc.set_query_base_uri(base_uri)
    '''TODO There is a bug with the DocumentBuilder base_uri and cwd for the processor'''
    builder = environment.proc.new_document_builder()
    base = xpc.evaluate("//static-base-uri")
    if base is not None:
        for i in range(base.size):
            basei = base.item_at(i)
            uri = basei.get_node_value().get_attribute_value("uri")
            if uri is None or uri == "UNDEFINED":
                environment.xquery_proc.set_query_base_uri(None)
                environment.xpath_proc.set_base_uri(None)
            else:
                environment.xquery_proc.set_query_base_uri(uri)
                environment.xpath_proc.set_base_uri(uri)
                environment.base_uri = uri
                '''print("base-uri = " + uri)'''

    '''set any requested collations - TODO'''

    '''declare the requested namespaces - TODO'''

    decimal_formats = xpc.evaluate("decimal-format")
    if decimal_formats is not None:
        environment.param_decimal_declarations = ""

        for decimal_format in decimal_formats:
            if spec.short_spec_name == "XP":
                environment.usable = False
                break
            format_name = decimal_format.get_node_value().get_attribute_value("name")
            if format_name is not None:
                '''TODO fixup format_name as EQName'''
                environment.param_decimal_declarations = environment.param_decimal_declarations + "declare decimal-format Q{}" + format_name
            else:
                environment.param_decimal_declarations = environment.param_decimal_declarations + "declare default decimal-format "
            xpc.set_context(xdm_item=decimal_format)
            decimal_format_Atts = xpc.evaluate("@* except @name")

            for decimal_format_Att in decimal_format_Atts:
                propertyi = decimal_format_Att.local_name
                valuei = decimal_format_Att.string_value
                environment.param_decimal_declarations = environment.param_decimal_declarations + " " + (propertyi + "=\"" + valuei + "\" ")
            environment.param_decimal_declarations = environment.param_decimal_declarations + ";"


        xpc.set_context(xdm_item=env)

    '''declare any variable'''
    params = xpc.evaluate("param")

    if params is not None:
        environment.param_declarations = ""


        for parami in params:
            param_node = parami.get_node_value()
            var_name = param_node.get_attribute_value("name")
            source = param_node.get_attribute_value("source")

            parami_value = None

            if source is not None:
                source_doc = environment.source_docs[source]

                if source_doc is None:
                    print("**** Unknown source document " + source)

                parami_value = source_doc
            else:
                old_base = xpc.base_uri
                '''xpc.set_base_uri(env.base_uri)'''
                select = param_node.get_attribute_value("select")
                parami_value = xpc.evaluate(select)
                '''xpc.set_base_uri(old_base)'''

            is_static = True if param_node.get_attribute_value('static') is not None else False
            environment.xpath_proc.declare_variable(var_name)
            declared = True if param_node.get_attribute_value("declared") is not None else False

            if not declared:
                environment.param_declarations = environment.param_declarations + "declare variable $" + var_name + " external; "

            if not is_static:
                environment.params[var_name] = parami_value

            '''else:
                For XSLT we handle this in the xslt30 test suite driver - maybe move logic here
                environment.xslt_proc.set_parameter(var_name, parami_value)
                print("set " + var_name + " = " + str(parami_value))'''







    ns_nodes = xpc.evaluate("//namespace")
    if ns_nodes is not None:
        for i in range(ns_nodes.size):
            ns_node = ns_nodes.item_at(i)
            prefix = ns_node.get_node_value().get_attribute_value("prefix")
            uri = ns_node.get_node_value().get_attribute_value("uri")
            environment.xquery_proc.declare_namespace(prefix=prefix, uri=uri)
            environment.xpath_proc.declare_namespace(prefix=prefix, uri=uri)

    '''load the requested schema documents'''

    schema_validator = None

    try:
        schema_validator = environment.proc.new_schema_validator()
        schema_validator.set_cwd(cwd_from_base_uri(base_uri))
    except PySaxonApiError as ex:
        print("*** Failed to create PySchemaValidator :" + str(ex))

    ''' PyXdmNode.base_uri returns file:// - this will cause problems with resolving later.'''
    '''Create bug issue to remove the file:// internally TODO create bug issue '''



    schemas = xpc.evaluate("schema")
    validate_sources = False
    if schemas is not None and schema_validator is not None:
        print("schema found count=" + str(schemas.size))
        for i in range(schemas.size):
            schema = schemas.item_at(i).get_node_value()
            role = schema.get_attribute_value("role")
            xsd_version = schema.get_attribute_value("xsd-version")

            if xsd_version is not None:
                schema_validator.set_property("xsdversion", xsd_version)
            else:
                schema_validator.set_property("xsdversion", "1.0")

            if role != "secondary":
                href = schema.get_attribute_value("file")
                ns = schema.get_attribute_value("uri")

                if ns == "http://www.w3.org/2005/xpath-functions":
                    schema_validator.set_property("xsdversion", "1.1")

                if href is None:
                    try:
                        schema_validator.register_schema(xsd_file=ns)
                    except PySaxonApiError as ex:
                        print("*** Failed to load schema by URI: " + ns + " - " + str(ex))


                else:
                    try:
                        schema_validator.register_schema(xsd_file=href)
                    except PySaxonApiError as ex:
                        print("*** Failed to load schema by URI: " + href + " - " + str(ex))

                xpc.import_schema_namespace(str(ns))
                '''TODO create bug issue byte type require str for import_schema_namespace'''
                environment.xpath_proc.import_schema_namespace(str(ns))

                if role == "source-reference":
                    validate_sources = True
                '''if role == "stylesheet-import": '''

    stylesheets = xpc.evaluate("stylesheet[not(@role='secondary')]")
    if stylesheets is not None:
        stylesheet_file = ""
        try:
            for ii in range(stylesheets.size):
                sheet = stylesheets.item_at(ii).get_node_value()
                stylesheet_file = sheet.get_attribute_value("file")
                print(stylesheet_file)
                environment.xslt_proc.set_cwd(cwd_from_base_uri(base_uri))
                environment.sheet = environment.xslt_proc.compile_stylesheet(stylesheet_file=stylesheet_file)
        except PySaxonApiError as ex:
            print(ex)
            print("**** failure while compiling environment-defined stylesheet " + stylesheet_file)

    '''SchemaManager manager = environment.processor.getSchemaManager()
    boolean validateSources = loadSchemaDocuments(driver, xpc, env, environment, manager)'''

    '''load the requested source documents'''

    load_source_documents(xpc, env, environment, builder, schemaValidator, validate_sources)
    return environment


def load_source_documents(xpc: PyXPathProcessor, env: PyXdmNode, environment: Environment, builder: PyDocumentBuilder,
                          schema_validator: PySchemaValidator, validate_sources: bool):
    sources = xpc.evaluate("//source")
    if sources is not None:
        for i in range(sources.size):

            source = sources.item_at(i).get_node_value()
            raw_uri = source.get_attribute_value("uri")
            role = source.get_attribute_value("role")
            media_type = source.get_attribute_value("media-type")
            validation = source.get_attribute_value("validation")
            if validation is None:
                validation = "skip"
            streaming = source.get_attribute_value("streaming")

            if not validate_sources and validation == "skip":
                print('validation is skipped')
                '''builder.set_schema_validator(None)
                builder.set_schema_validator(None) 
                TODO this is a bug cannot set validator to None'''
            else:
                try:
                    schema_validatori = environment.proc.new_schema_validator()
                    schema_validatori.set_lax(validation == "lax")
                    builder.set_schema_validator(schema_validatori)
                except PySaxonApiError as ex:
                    print("*** Failed to create PySchemaValidator :" + str(ex))
            href = source.get_attribute_value("file")
            select = source.get_attribute_value("select")
            xinc = source.get_attribute_value("xinclude")
            content = None
            builder.set_line_numbering(True)

            try:
                if href is not None:
                    base_uri = source.base_uri
                    builder.set_base_uri(base_uri)
                    content = builder.parse_xml(xml_file_name=href)
                    environment.source_docs[href] = content
                else:
                    '''print(source)'''
                    builder.set_base_uri(source.base_uri)
                    xpc.set_context(xdm_item=source)
                    contenti = xpc.evaluate_single("string(content)")
                    content = builder.parse_xml(xml_text=contenti.string_value)

                    if href is None:
                        environment.source_docs["default"] = content
                    else:
                        environment.source_docs[href] = content
                if role is not None:
                    if "." == role:
                        if href is None:
                            environment.context_item = environment.source_docs["default"]
                        else:
                            environment.context_item = environment.source_docs[href]

                    '''else:'''

            except PySaxonApiError as ex:
                print("*** failed to build source document " + str(ex))


def create_global_environment(catalog: PyXdmNode, xpath_proc: PyXPathProcessor):
    global spec
    xpath_proc.set_context(xdm_item=catalog)
    xpath_proc.declare_namespace("", "http://www.w3.org/2010/09/qt-fots-catalog")
    environment = None
    nodes = xpath_proc.evaluate("//environment")
    if nodes is not None:
        environment = Environment()
        for env in nodes:
            process_environment(xpath_proc, env, spec, globalEnvironments, environment)


def create_local_environments(test_set_node: PyXdmNode, xpath_proc: PyXPathProcessor):
    localEnvironments.clear()
    environmenti = Environment()
    environmenti.create_processors()
    localEnvironments.update({"default": environmenti})

def get_named_parameters(proc: PySaxonProcessor, xpath_proc: PyXPathProcessor, node: PyXdmNode, get_static: bool, tunnel: bool):
        params = {}
        j = 1

        static_test = ""
        if get_static:
            static_test  = "[@static]"

        param_elements = xpath_proc.evaluate("param"+static_test)
        if param_elements is not None:
            for i in range(param_elements.size):

                param_i = param_elements.item_at(i).get_node_value()

                name = param_i.get_attribute_value("name")
                select = param_i.get_attribute_value("select")
                tunnelled = param_i.get_attribute_value("tunnel")
                as_i = param_i.get_attribute_value("as")

                required = tunnel == (tunnelled is not None and tunnelled == "yes")
                value = None
                if name is None:
                    print("*** No name for parameter " + str(j) + " in initial-template")
                    raise PySaxonApiError("*** No name for parameter " + str(j) + " in initial-template")
                try:
                    value = xpath_proc.evaluate(select)
                    i += 1
                    if value is None:
                        if os.getenv("SAXONC_DEBUG_FLAG") is not None:
                            print("Error in get_named_parameters - value is None")
                        continue
                except PySaxonApiError as ex:
                    print("*** Error evaluating parameter " + name + " in initial-template : " + print(ex))
                    continue
                '''if as_i is not None:
                    valuei = proc.make_atomic_value(str(as_i), str(value))
                    if required:
                        params[name] = valuei
                elif required:'''
                params[name] = value

        return params


def run_test_case(test_case_node: PyXdmNode, xpath_proc: PyXPathProcessor):
    global localEnvironments
    global successes
    global failures
    global not_run
    global test_report
    global wrong_error_results
    global path
    global host_lang
    global spec

    xpath_proc.set_context(xdm_item=test_case_node)
    test_name = test_case_node.get_attribute_value("name")
    dependencies = xpath_proc.evaluate("dependency")
    env_node = xpath_proc.evaluate_single("environment")
    test_queries = xpath_proc.evaluate("test")

    environment = Environment()
    if dependencies is not None:
        '''print("environment found !!!!")'''

        for i in range(dependencies.size):
            dep = dependencies.item_at(i).get_node_value()
            if not ensure_dependency_satisfied(dep, environment):
                not_run += 1
                test_report.write_test_case_element(test_name, "n/a", None)
                return

        ''' get environment for this testcase'''

    if env_node is not None:
        '''print(env_node)'''
        env_ref = env_node.get_node_value().get_attribute_value("ref")
        env_node_i = env_node.get_node_value()
        if env_ref is None:
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print('Creating new environment')
            environment = process_environment(xpath_proc, env_node_i, spec, globalEnvironments,
                                              environment)

        else:
            if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                print('env_Ref = ' + env_ref)
            try:
                environment = localEnvironments[env_ref]

            except KeyError as ex:
                try:
                    environment = globalEnvironments[env_ref]
                except KeyError as ex:
                    print("environment not found - should probably fail")
                    environment = process_environment(xpath_proc, env_node_i, spec, globalEnvironments,
                                                  environment)


        '''print(environment.source_docs.keys())'''

    else:
        environment.create_processors()

    if not environment.usable:
        test_report.write_test_case_element(str(test_name), "notRun", None)
        not_run += 1
        return


    xpath_proc.set_context(xdm_item=test_case_node)

    assertion = xpath_proc.evaluate_single("result/*[1]").get_node_value()

    '''print(test_case_node)'''
    if os.getenv("SAXONC_DEBUG_FLAG") is not None:
        print("Start memory:")
        print(start_memory)
        print("End memory:")
        print(process.memory_info().rss)
    if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
        print(test_case_node)


    environment.xpath_proc.set_backwards_compatible(False)
    '''Get config for XSLT Processor'''


    '''base_output_uri = ""
    if path is not None:
        base_output_uri = "file:/" + abspath(str(path) + "results/output.xml")        

    if output_uri is not None:
      
        base_output_uri = urllib.parse.urljoin(base_output_uri,
                                               str(output_uri.item_at(0).get_atomic_value().string_value))'''

    '''global_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                      False, False)

    static_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                         True, False)
    '''
    if os.getenv("SAXONC_DEBUG_FLAG") is not None:
        print(test_case_node.base_uri)
    '''print(test_case_node)'''


    errorResult = None
    result = None
    result_documents = {}
    outcome = PyTestOutcome()

    pos = 0
    try:
        for test_query in test_queries.item_at(pos):
            pos += 1
            xpath_proc.set_context(xdm_item=test_query)
            exp = None

            exp = str(xpath_proc.evaluate("if (@file) then unparsed-text(resolve-uri(@file, base-uri(.))) else string(.)"))

            if exp is not None:
                if "XP" == spec.short_spec_name or "XT" == spec.short_spec_name:
                    testxpc = environment.xpath_proc
                    testxpc.set_property("sa", "true")
                    testxpc.set_language_version(spec.version)
                    testxpc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
                    testxpc.declare_namespace("xs", "http://www.w3.org/2001/XMLSchema")
                    testxpc.declare_namespace("array", "http://www.w3.org/2005/xpath-functions/array")
                    testxpc.declare_namespace("map", "http://www.w3.org/2005/xpath-functions/map")
                    testxpc.set_base_uri(test_case_node.base_uri)

                    if len(environment.params) > 0:
                        for var_name in environment.params.keys():
                            testxpc.set_parameter(var_name, environment.params[var_name])

                    if environment.context_item is not None:
                        testxpc.set_context(xdm_item=environment.context_item)
                        result = testxpc.evaluate(exp)
                    else:
                        result = testxpc.evaluate(exp)
                    break
                elif "XQ" == spec.short_spec_name:
                    testxqc = environment.xquery_proc
                    testxqc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
                    testxqc.declare_namespace("xs", "http://www.w3.org/2001/XMLSchema")
                    testxqc.declare_namespace("array", "http://www.w3.org/2005/xpath-functions/array")
                    testxqc.declare_namespace("map", "http://www.w3.org/2005/xpath-functions/map")

                    if environment.param_decimal_declarations is not None \
                            and len(environment.param_decimal_declarations) > 0:
                        exp = environment.param_decimal_declarations + exp

                    if environment.param_declarations is not None and len(environment.param_declarations) > 0:
                        exp = environment.param_declarations + exp

                    if len(environment.params) > 0:
                        for var_name in environment.params.keys():
                            testxqc.set_parameter(var_name, environment.params[var_name])

                    if environment.context_item is not None:
                        testxqc.set_context(xdm_item=environment.context_item)
                    result = testxqc.run_query_to_value(query_text=exp)
                else:
                    test_report.write_test_case_element(str(test_name), "notRun", None)
                    not_run += 1


    except PySaxonApiError as ex:
        print(ex)
        errorResult = ex

    for func in environment.reset_actions:
        func(environment.proc)

    assert_xpc = environment.proc.new_xpath_processor()
    assert_xpc.set_property("sa", "true")
    assert_xpc.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")
    assert_xpc.declare_namespace("xs", "http://www.w3.org/2001/XMLSchema")
    assert_xpc.declare_namespace("math", "http://www.w3.org/2005/xpath-functions/math")
    assert_xpc.declare_namespace("map", "http://www.w3.org/2005/xpath-functions/map")
    assert_xpc.declare_namespace("array", "http://www.w3.org/2005/xpath-functions/array")
    assert_xpc.declare_namespace("j", "http://www.w3.org/2005/xpath-functions")
    assert_xpc.declare_namespace("file", "http://expath.org/ns/file")
    assert_xpc.declare_namespace("bin", "http://expath.org/ns/binary")
    assert_xpc.declare_variable("result")
    global assert_set
    '''TODO add method  - assert_xpc.set_base_uri(assertion.getBaseURI())'''
    if result is not None or outcome.serialized_result is not None:
        success = outcome.test_assertion(assertion, result, None, environment.proc, assert_xpc, xpath_proc,
                                         assert_set)
        if success:
            test_report.write_test_case_element(str(test_name), "pass", None)
            successes += 1
        else:
            test_report.write_test_case_element(str(test_name), "fail", None)
            failures += 1
        return
    elif errorResult is not None:
        success = outcome.test_assertion(assertion, None, errorResult, environment.proc, assert_xpc, xpath_proc,
                                         assert_set)
        if success:
            test_report.write_test_case_element(str(test_name), "pass", None)
            successes += 1
        elif assertion.get_attribute_value("code") is not None:
            test_report.write_test_case_element(str(test_name), "pass", "Wrong error code: " + str(errorResult))
            successes += 1
            wrong_error_results += 1
        else:
            '''test_report.write_test_case_element(str(test_name), "pass", "Wrong error code (maybe unknown): " + str(errorResult))
            successes += 1
            wrong_error_results += 1'''
            test_report.write_test_case_element(str(test_name), "fail", str(errorResult))
            failures += 1

        return
    test_report.write_test_case_element(str(test_name), "notRun", None)
    not_run += 1



def main(argv):
    global run_test
    global run_test_case_name
    global path
    global results_path
    global schemaValidator
    global host_lang
    global spec
    global test_report
    global saxon_version



    print("W3 QT3 Test Suite")
    print("(Python Test Harness. Version: 1.0. SaxonC Python API, Saxon product version:" + saxon_version + ")")

    diri = None
    spec = None

    if len(sys.argv) > 1:
        diri = ""
        try:
            diri = str(sys.argv[1])
        except TypeError as ex:
            print("Error test suite directory missing")
            print('qt3_test_suite_driver.py <testsuitedir> -l <lang> -t <testpattern> -s <testset> -o <resultdir>')
            sys.exit(2)

        print("Test suite directory = " + diri)

        argvv = argv[1:]

        try:
            opts, args = getopt.getopt(argvv, "ht:s:o:l:", ["testpattern", "testset", "resultdir", "lang"])
        except getopt.GetoptError:
            print('qt3_test_suite_driver.py <testsuitedir> -t <testpattern> -s <testset> -o <resultdir> -l <processor language>')
            sys.exit(2)
        print(opts)
        print(args)
        for opt, arg in opts:
            if opt == '-h':
                print('HELP: qt3_test_suite_driver.py -t <testpattern> -s <testset> -o <resultdir> -l <language>')
                sys.exit()
            elif opt in ("-t", "--testpattern"):
                run_test_case_name = arg
            elif opt in ("-s", "--testset"):
                run_test = arg
                print('Test set= ', run_test)
            elif opt in ("-o", "--resultdir"):
                results_path = arg

            elif opt in ("-l", "--lang"):
                host_lang = arg
                spec = process_spec(arg)
                test_report = PyTestReport("qt3", "http://www.w3.org/2012/08/qt-fots-results", spec.spec_and_version, driver_proc.version[7:9], saxon_version)

    '''dir = os.getcwd()'''
    if spec is None:
        print("lang option not given")
        sys.exit(2)

    path = diri + "/"
    catalog = path + "catalog.xml"

    process_catalog(path, catalog)


if __name__ == "__main__":
    main(sys.argv[1:])
