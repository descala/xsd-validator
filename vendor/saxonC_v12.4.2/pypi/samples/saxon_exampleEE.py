from saxonche import *

with PySaxonProcessor(license=True) as saxonproc2:
    trans = saxonproc2.new_xslt30_processor()

    source = "<?xml version='1.0'?>  <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform'  xmlns:xs='http://www.w3.org/2001/XMLSchema'  version='3.0' exclude-result-prefixes='#all'>  <xsl:import-schema><xs:schema><xs:element name='x' type='xs:int'/></xs:schema></xsl:import-schema>  <xsl:template name='main'>     <xsl:result-document validation='strict'>       <x>3</x>     </xsl:result-document>  </xsl:template>  </xsl:stylesheet>"

    executable = trans.compile_stylesheet(stylesheet_text=source)
    executable.set_property("!omit-xml-declaration", "yes")
    sw = executable.call_template_returning_string("main")
    print("Result=",sw)
