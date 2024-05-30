import urllib.parse

from saxonche import *
import os
import psutil
from Environment import Environment
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

xsltproc = driver_proc.new_xslt30_processor()

xpathProcForEnv = driver_proc.new_xpath_processor()

xpathProcForCompareNodes = driver_proc.new_xpath_processor()

xpathProcForCompareNodes.declare_namespace("fn", "http://www.w3.org/2005/xpath-functions")

schemaValidator = None
test_report = PyTestReport("xslt30", "http://www.w3.org/2012/11/xslt30-test-results", "XT30",driver_proc.version[:8], saxon_version)

globalEnvironments = {}
localEnvironments = {}
xpathProcForEnv.declare_namespace("", "http://www.w3.org/2012/10/xslt-test-catalog")
edition = "EE"
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
exceptionList = ['unicode-90', 'validation-1601']
'''number-5018 number-2806 number-5014 number-5029'''

def cwd_from_base_uri(base_uri: str):
    cwd = os.path.dirname(urlparse(base_uri).path)
    if os.path.isdir(cwd):
        return cwd
    raise IOError("Specified directory <%s> does not exist!" % cwd)

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
    if os.getenv("SAXON_LICENSE_DIR") is not None:
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

        if run_test is None:
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
            child0 = test_set_xml.children[0]
            xpathProcForEnv.set_context(xdm_item=child0)
            envs = xpathProcForEnv.evaluate("//environment[@name]")

            if envs is not None:
                for i in range(envs.size):
                    env = envs.item_at(i)
                    process_environment(xpathProcForEnv, env.get_node_value(), "spec", localEnvironments,
                                        localEnvironments['default'])
            if child0 is None:
                print("Cannot find child node of test " + test_set_file)

                return None
            else:
                test_set_name = child0.get_attribute_value("name")
                '''if run_test is not None and test_set_name is not run_test:
                    return None'''
                ''' get environment'''

                '''check dependencies'''

                xpathProcForEnv.set_context(xdm_item=test_set_xml)
                test_cases = xpathProcForEnv.evaluate("//*:test-case")
                dependencies = xpathProcForEnv.evaluate("/*:test-set/*:dependencies/*")

                if dependencies is not None:

                    for i in range(dependencies.size):
                        dep = dependencies.item_at(i).get_node_value()

                        if not ensure_dependency_satisfied(dep, localEnvironments['default']):
                            print("dependency failed at test set level XXXX")
                            return

                if test_cases is not None:
                    tcs_count = test_cases.size
                    total_tests += tcs_count

                    '''print(test_set_file)
                    print("Test cases count = " + str(tcs_count))'''
                    result = "NA"
                    test_report.start_test_set_element(child0, None)

                    for x, test_case in enumerate(test_cases):
                        if test_case.is_node:
                            test_casei = test_case.get_node_value()
                            test_case_name = test_casei.get_attribute_value("name")
                            if (
                                    run_test_case_name is None or test_case_name == run_test_case_name) and test_set_name not in exceptionList:
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


def ensure_dependency_satisfied(dependency: PyXdmNode, env: Environment):
    global alwaysOn
    ''' TODO the local_name property will be used in SaxonC 12.3 release '''
    typei = dependency.name.split("}")[1]

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
        return value == "XSLT30" or value == "XSLT20+" or value == "XSLT30+" or value == "XSLT10+"
    elif typei == "feature":
        if value == "XML_1.1":
            '''TODO handle XML 1.1 by logic to reset environment'''
            return False
        elif value == "streaming-fallback":
            return False
        elif value == "advanced-uca-fallback":
            return False
        elif value == "simple-uca-fallback":
            return False
        elif value == "higher_order_functions":
            return not inverse
        else:
            '''Check this path'''
            return False
    elif typei == "year_component_values":
        if (value == "support year above 9999" or value == "support negative year"
                or value == "support year zero"):
            return True

    return True


def process_environment(xpc: PyXPathProcessor, env: PyXdmNode, spec: str, environments_i: dict,
                        default_environment: Environment):
    environment = Environment()
    environment.create_processors()
    xpc.set_context(xdm_item=env)
    name = env.get_attribute_value("name")
    if name is not None:
        print("Loading environment " + name)
        environments_i[name] = environment
    else:
        print("Loading environment without name")

    '''set the base URI if specified'''
    base_uri = str(env.base_uri)
    environment.proc.set_cwd(cwd_from_base_uri(base_uri))
    builder = environment.proc.new_document_builder()
    base = xpc.evaluate("//static-base-uri")
    if base is not None:
        for i in range(base.size):
            basei = base.item_at(i)
            uri = basei.get_node_value().get_attribute_value("uri")
            if uri is None or uri == "UNDEFINED":
                environment.xquery_proc.set_query_base_uri(None)
            else:
                environment.xquery_proc.set_query_base_uri(uri)
                environment.base_uri = uri
                '''print("base-uri = " + uri)'''

    '''set any requested collations - TODO'''

    '''declare the requested namespaces - TODO'''

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
    sources = xpc.evaluate("source")
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
    xpath_proc.set_context(xdm_item=catalog)

    nodes = xpath_proc.evaluate("//environment")
    if nodes is not None:
        for env in nodes:
            process_environment(xpath_proc, env, globalEnvironments, localEnvironments['default'])


def create_local_environments(test_set_node: PyXdmNode, xpath_proc: PyXPathProcessor):
    localEnvironments.clear()
    environmenti = Environment()
    environmenti.create_processors()
    localEnvironments.update({"default": environmenti})


def get_named_parameters(proc: PySaxonProcessor, xpath_proc: PyXPathProcessor, node: PyXdmNode, get_static: bool,
                         tunnel: bool):
    params = {}
    j = 1

    static_test = ""
    if get_static:
        static_test = "[@static]"

    param_elements = xpath_proc.evaluate("param" + static_test)
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

    xpath_proc.set_context(xdm_item=test_case_node)
    test_name = test_case_node.get_attribute_value("name")
    dependencies = xpath_proc.evaluate("dependencies/*")
    env_node = xpath_proc.evaluate_single("environment")
    test_input_node = xpath_proc.evaluate_single("test")

    spec_att = 'XSLT10+'
    if dependencies is not None:
        '''print("environment found !!!!")'''

        for i in range(dependencies.size):
            dep = dependencies.item_at(i).get_node_value()
            if not ensure_dependency_satisfied(dep, localEnvironments['default']):
                not_run += 1
                test_report.write_test_case_element(test_name, "n/a", None)
                return

        ''' get environment for this testcase'''

    if env_node is not None:
        '''print(env_node)'''
        env_ref = env_node.get_node_value().get_attribute_value("ref")
        environment = None
        env_node_i = env_node.get_node_value()
        if env_ref is None:
            if os.getenv("SAXONC_DEBUG_FLAG") is not None:
                print('Creating new environment')
            environment = process_environment(xpath_proc, env_node_i, "spec", globalEnvironments,
                                              localEnvironments['default'])
        else:
            if os.getenv("SAXONC_DEBUG_FLAG") is not None:
                print('env_Ref = ' + env_ref)
            environment = localEnvironments[env_ref]

        '''print(environment.source_docs.keys())'''

    else:
        environment = Environment()
        environment.create_processors()

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

    xpath_proc.set_context(xdm_item=test_input_node)
    '''Get config for XSLT Processor'''
    stylesheet = xpath_proc.evaluate_single("stylesheet[not(@role = 'secondary')]")
    principle_package = xpath_proc.evaluate_single("package[(@role = 'principal')]")
    used_package = xpath_proc.evaluate_single("package[(@role = 'secondary')]")
    output_uri = xpath_proc.evaluate_single("string(output/@file)")
    serialize_check = xpath_proc.evaluate_single("string(output/@serialize)")
    base_output_uri = ""
    if path is not None:
        base_output_uri = "file:/" + abspath(str(path) + "results/output.xml")
        '''print(base_output_uri)'''

    if output_uri is not None:
        '''print(base_output_uri)
        print(str(output_uri.item_at(0).get_atomic_value().string_value))'''
        base_output_uri = urllib.parse.urljoin(base_output_uri,
                                               str(output_uri.item_at(0).get_atomic_value().string_value))

    initial_mode = xpath_proc.evaluate_single("initial-mode")
    initial_template = xpath_proc.evaluate_single("initial-template")
    initial_function = xpath_proc.evaluate_single("initial-function")

    global_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                         False, False)

    static_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                         True, False)

    if os.getenv("SAXONC_DEBUG_FLAG") is not None:
        print(test_case_node.base_uri)
    '''print(test_case_node)'''

    initial_match_selection = None
    initial_mode_name = None
    if initial_mode is not None:
        initial_mode_name = initial_mode.get_node_value().get_attribute_value("name")
        select = initial_mode.get_node_value().get_attribute_value("select")
        if select is not None:
            '''print(select)'''
            environment.xpath_proc.clear_properties()
            environment.xpath_proc.set_cwd(cwd_from_base_uri(initial_mode.get_node_value().base_uri))
            try:
                initial_match_selection = environment.xpath_proc.evaluate(select)
            except PySaxonApiError as ex:
                errorResult = ex

                '''TODO this is not currently working  - try set base-uri on XPathProcessor'''
                test_report.write_test_case_element(str(test_name), "fail", str(ex))
                failures += 1
                return

    'TODO - the base_uri contains file:/// the resolving of stylesheet does not work with file:'
    environment.xslt_proc.set_cwd(cwd_from_base_uri(test_case_node.base_uri))
    environment.xslt_proc.set_jit_compilation(False)
    errorResult = None
    result = None
    result_documents = {}
    outcome = PyTestOutcome()

    try:
        for key in static_params:
            environment.xslt_proc.set_parameter(key, static_params[key])

        if os.getenv("SAXONC_DEBUG_FLAG") is not None:
            if used_package is not None:
                print("WARNING - Import package currently not supported!")

        if stylesheet is not None:
            file_name = stylesheet.get_node_value().get_attribute_value("file")
            environment.sheet = environment.xslt_proc.compile_stylesheet(stylesheet_file=file_name)
        elif principle_package is not None:
            if used_package is not None:
                print('used Package = ' + str(used_package.size))
                for z in range(used_package.size):
                    p_node = used_package.item_at(z).get_node_value()
                    p_file_name = p_node.get_attribute_value("file")
                    p_secondary_output_file = p_file_name[-4]
                    environment.xslt_proc.compile_stylesheet(stylesheet_file=p_file_name, save=True,
                                                             output_file=p_secondary_output_file)
                    environment.xslt_proc.import_package(p_secondary_output_file)
                    if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
                        print("package file name=" + p_file_name + ", and sef filename = " + p_secondary_output_file)

            file_name = principle_package.get_node_value().get_attribute_value("file")
            if file_name != "":
                output_file = (file_name[-4] + "_created_from_test_driver.sef")
                environment.xslt_proc.compile_stylesheet(stylesheet_file=file_name, save=True, output_file=output_file)
                environment.sheet = environment.xslt_proc.compile_stylesheet(stylesheet_file=output_file)

        if environment.sheet is None:
            print("Environment not is a clean state")
            return

        for key in global_params:
            environment.sheet.set_parameter(key, global_params[key])

        environment.sheet.set_capture_result_documents(True)
        environment.sheet.set_save_xsl_message(True, None)

        if environment.context_item is not None:
            '''print(environment.context_item)'''
            environment.sheet.set_global_context_item(xdm_item=environment.context_item)

        if initial_template is not None or initial_mode_name is not None:
            '''TODO check for params - set to tunnel'''
            print("")
        if initial_mode_name is not None:
            environment.sheet.set_initial_mode(initial_mode_name)
        if initial_template is not None:
            init_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                               False, False)
            tunnel_params = get_named_parameters(environment.proc, xpath_proc, test_input_node.get_node_value(),
                                                 False, True)
            environment.sheet.set_initial_template_parameters(False, init_params)
            environment.sheet.set_initial_template_parameters(True, tunnel_params)
            if serialize_check is not None and str(serialize_check) == "yes":
                outcome.serialized_result = environment.sheet.call_template_returning_string(
                    initial_template.get_node_value().get_attribute_value("name"), base_output_uri=base_output_uri)
                outcome.base_uri = base_output_uri
            else:
                result = environment.sheet.call_template_returning_value(
                    initial_template.get_node_value().get_attribute_value("name"), base_output_uri=base_output_uri)

        elif initial_function is not None:
            initial_function_node = initial_function.get_node_value()
            initial_function_name = initial_function_node.get_attribute_value("name")
            '''check for namespace'''
            namespace_uri = ""
            if ":" in initial_function_name:
                initial_function_name_split = initial_function_name.split(':')
                prefix = initial_function_name_split[0]
                namespaces = initial_function_node.axis_nodes(8)
                for ns in namespaces:
                    uri_str = ns.string_value
                    ns_prefix = ns.name

                    if ns_prefix is not None and prefix == ns_prefix:
                        initial_function_name = "{" + uri_str + "}" + initial_function_name_split[1]

                initial_function_name = initial_function_name

            attributes = initial_function_node.attributes

            children = initial_function_node.children
            if children is not None:
                for x in children:
                    nodex = x.item_at(0).get_node_value()
                    print(nodex)
                    if nodex.name == "param":
                        exit()
            if serialize_check is not None and str(serialize_check) == "yes":
                outcome.serialized_result = environment.sheet.call_function_returning_string(initial_function_name, [])
                outcome.base_uri = base_output_uri
            else:
                result = environment.sheet.call_function_returning_value(initial_function_name, [])
        elif environment.context_item is not None:
            if serialize_check is not None and str(serialize_check) == "yes":
                outcome.serialized_result = environment.sheet.apply_templates_returning_string(
                    xdm_value=environment.context_item,
                    base_output_uri=base_output_uri)
                outcome.base_uri = base_output_uri
            else:
                result = environment.sheet.apply_templates_returning_value(xdm_value=environment.context_item,
                                                                           base_output_uri=base_output_uri)
        else:
            if serialize_check is not None and str(serialize_check) == "yes":
                outcome.serialized_result = environment.sheet.call_template_returning_string(
                    base_output_uri=base_output_uri)
                outcome.base_uri = base_output_uri
            else:
                result = environment.sheet.call_template_returning_value(base_output_uri=base_output_uri)
        outcome.result_documents = environment.sheet.get_result_documents()
        outcome.xsl_messages = environment.sheet.get_xsl_messages()
        '''print(environment.sheet.get_xsl_messages())'''
        '''print('Result = ' + str(result))'''

        if os.getenv("SAXONC_TESTSUITE_DEBUG") is not None:
            if result is not None:
                print("Result = " + str(result))
            elif outcome.serialized_result is not None:
                print("Serialized Result = " + outcome.serialized_result)
            else:
                print("No result available")



    except PySaxonApiError as ex:
        print(ex)
        errorResult = ex

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
            test_report.write_test_case_element(str(test_name), "pass",
                                                "Wrong error code (maybe unknown): " + str(errorResult))
            successes += 1
            wrong_error_results += 1
            '''test_report.write_test_case_element(str(test_name), "fail", str(errorResult))
            failures += 1'''

        return
    test_report.write_test_case_element(str(test_name), "notRun", None)
    not_run += 1


def main(argv):
    global run_test
    global run_test_case_name
    global path
    global results_path
    global schemaValidator
    global saxon_version

    print("W3 XSLT 3.0 Test Suite")
    print("(Python Test Harness. Version: 1.0. SaxonC Python API, Saxon product version:" + saxon_version + ")")

    diri = None

    if len(sys.argv) > 1:
        diri = str(sys.argv[1])
        print("Test suite directory = " + diri)

        argvv = argv[1:]

        try:
            opts, args = getopt.getopt(argvv, "ht:s:o:", ["testpattern", "testset", "resultdir"])
        except getopt.GetoptError:
            print('xslt30_test_suite_driver.py -t <testpattern> -s <testset> -o <resultdir>')
            sys.exit(2)

        for opt, arg in opts:
            if opt == '-h':
                print('HELP: xslt30_test_suite_driver.py -t <testpattern> -s <testset> -o <resultdir>')
                sys.exit()
            elif opt in ("-t", "--testpattern"):
                run_test_case_name = arg
            elif opt in ("-s", "--testset"):
                run_test = arg
                print('Test set= ', run_test)

            elif opt in ("-o", "--resultdir"):
                results_path = arg

    '''dir = os.getcwd()'''
    path = diri + "/xslt30-test/"
    catalog = path + "catalog.xml"

    process_catalog(path, catalog)


if __name__ == "__main__":
    main(sys.argv[1:])