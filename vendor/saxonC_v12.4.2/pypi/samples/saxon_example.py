import saxonche

with saxonche.PySaxonProcessor(license=True) as proc:
   
   print("Test Python")
   print(proc.version)
   #print(dir(proc))


   xdmAtomicval = proc.make_boolean_value(False)

   xsltproc = proc.new_xslt30_processor()
   document = proc.parse_xml(xml_text="<out><person>text1</person><person>text2</person><person>text3</person></out>")
   if(document != None):
       print('document object is none \n')
   xsltproc.set_jit_compilation(True)
   executable = xsltproc.compile_stylesheet(stylesheet_text="<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='2.0'>       <xsl:param name='values' select='(2,3,4)' /><xsl:output method='xml' indent='yes' /><xsl:template match='*'><output><xsl:value-of select='//person[1]'/><xsl:for-each select='$values' ><out><xsl:value-of select='. * 3'/></out></xsl:for-each></output></xsl:template></xsl:stylesheet>")
   if(executable == None):
      print('Executable is None\n')
      if(xsltproc.exception_occurred):
         print("Error message:"+ xsltproc.error_message)
         exit()
   executable.set_initial_match_selection(xdm_value=document)
   if(xsltproc.exception_occurred):
      print('exception occurred\n')
      print('Error message'+xsltproc.error_message)


   output2 = executable.apply_templates_returning_string()
   print(output2)
   print('test 0 \n')
   xml = """\
    <out>
        <person>text1</person>
        <person>text2</person>
        <person>text3</person>
    </out>"""
   xp = proc.new_xpath_processor()
    
   node = proc.parse_xml(xml_text=xml)
   print('test 1\n node='+node.string_value)
   xp.set_context(xdm_item=node)
   item = xp.evaluate_single('//person[1]')
   if isinstance(item,saxonche.PyXdmNode):
       print(item.string_value)

   value = proc.make_double_value(3.5)
   print(value.primitive_type_name)
   
   print("new test case")
   xml2 = """\
    <out>
        <person first-name='roger' surname='smith'>Roger Smith</person>
        <person>Chris</person>
        <person>George</person>
    </out>
    """

   node2 = proc.parse_xml(xml_text=xml2)
   print("node.node_kind="+ node2.node_kind_str)    
   print("node.size="+ str(node2.size))
   print('cp1\n')
   outNode = node2.children
   print("Number of children="+str(len(node2.children)))
   print('element name='+outNode[0].name)
   children = outNode[0].children
   print("Number of children at node '"+ outNode[0].name+"' ="+str(len(children)))
   print(*children, sep= ', ')
   attrs = children[1].attributes
   if len(attrs) == 2:
       print('Surname in attribute='+  attrs[1].string_value)




