import time

from saxonche import *


saxonproc = PySaxonProcessor(license=True)

trans = saxonproc.new_xslt30_processor()

executable = trans.compile_stylesheet(stylesheet_file='../../samples/data/caffo/Transform2Streamable.xslt')
if executable is None:
    print('executable is None. Error'+ trans.error_message)
    exit()
t0 = time.time()
for x in range(1, 10):
    val = executable.apply_templates_returning_value(source_file="../../samples/data/caffo/Input.xml")

    if executable.exception_occurred and val is None:
        print(executable.error_message)
        exit()
        
t1 = time.time()

total = t1-t0

print('Time ='+str(total/10) + 'ms')







