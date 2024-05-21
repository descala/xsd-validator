import threading

from saxonc import *

from random import randint
from time import sleep

class myThread (threading.Thread):
    def __init__(self, threadID, name, counter, node, saxon_proc):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.counter = counter
        self.name = name
        self.node = node
        self.saxon_proc = saxon_proc
        self.xslt30_processor = saxon_proc.new_xslt30_processor()
        self.xslt30_processor.set_cwd('.')

    def run(self):
        print ("Starting " + self.name)
        run_transform(self.name, self.counter, self.node, self.xslt30_processor, self.saxon_proc)
        print ("Exiting " + self.name)

def run_transform(threadName, counter, node, xslt30_processor, saxon_proc):
    sheet_file = "threading-example/sheet-samples/sheet{}.xsl".format(counter)
    result_file = "threading-example/result-{}.xml".format(counter)
    print('Transforming with', sheet_file, 'to', result_file)

    xslt_executable = xslt30_processor.compile_stylesheet(stylesheet_file = sheet_file)
    if xslt_executable is not None:
        xslt_executable.apply_templates_returning_file(xdm_value = node, output_file = result_file)
    else:
        print(xslt30_processor.error_message)
    '''sleep(randint(10,100))'''
    '''saxon_proc.detach_current_thread'''


with PySaxonProcessor(license = False) as saxon_proc:

    xdm_node = saxon_proc.parse_xml(xml_file_name = 'threading-example/input-samples/sample-1.xml')
    if xdm_node is None:
        print(saxon_proc.error_message)
        exit()
    # Create new threads
    thread1 = myThread(1, "Thread-1", 1, xdm_node, saxon_proc)
    thread2 = myThread(2, "Thread-2", 2, xdm_node, saxon_proc)
    thread3 = myThread(3, "Thread-3", 3, xdm_node, saxon_proc)
    
    # Start new Threads
    thread1.start()
    thread2.start()
    thread3.start()
    thread1.join()
    thread2.join()
    thread3.join()
    print ("Exiting Main Thread")
