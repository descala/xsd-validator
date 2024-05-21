import xml.etree.ElementTree as ET
from saxonche import *

from datetime import datetime

now = datetime.now()

'''product = "SaxonC-HE"'''



class PyTestReport:
    result_root: ET.Element
    current_test_set: ET.Element
    test_driver_namespace = None
    test_driver = None
    language = None
    product = None
    version = None

    def __init__(self, td, ns, lang, p, v):
        self.result_root = None
        self.current_test_set = None
        self.test_driver_namespace = ns
        self.language = lang
        self.test_driver = td
        self.product = p
        self.version = v

    def write_result_file_preamble(self, proc: PySaxonProcessor, td, config: list):
        global product
        global version
        global test_driver
        test_driver = td
        '''product = proc.version[0:9]
        version = proc.version[10:14]'''
        current_time = now.strftime("%H:%M:%S")
        today = datetime.today()
        ET.register_namespace("", self.test_driver_namespace)
        self.result_root = ET.Element('test-suite-result', xmlns=self.test_driver_namespace)
        implementation = ET.SubElement(self.result_root, "implementation", name=self.product, version=self.version)
        ET.SubElement(implementation, "organization",  name="http://www.saxonica.com/", anonymous="false")
        ET.SubElement(implementation, "submitter", name="O'Neil Delpratt", email="oneil@saxonica.com")
        ET.SubElement(implementation, "configuration", timeRun=str(current_time), lang=self.language)
        ET.SubElement(self.result_root, "test-run", dateRun=str(datetime.today())[0:10], testsuiteVersion="3.0.1")

    def start_test_set_element(self, func_set_node: PyXdmNode, comment):
        value = func_set_node.get_attribute_value("name")
        self.current_test_set = ET.SubElement(self.result_root, "test-set", name=value)
        if comment is not None:
            self.current_test_set.set("comment", comment)

    def write_test_case_element(self, namei: str, result: str, comment):
        if self.current_test_set is not None:
            testcase = ET.SubElement(self.current_test_set, "test-case", name=namei, result=result)
            if comment is not None:
                testcase.set("comment", comment)
        else:
            print("Test report error: current test set not found")


    def write_result_file_postamble(self, proc: PySaxonProcessor, cwd: str):
        tree = ET.ElementTree(self.result_root)
        ET.indent(tree, space=" ", level=0)
        if not cwd.endswith('/'):
            cwd = cwd + '/'

        tree.write(cwd + self.product.lower() + 'c_' + self.test_driver + '_' + self.language + '.xml')

