<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>SaxonC API design use cases</title>
    </head>
    <body>
<?php
            
           
function exampleSimple1($proc, $validator)
{
    echo '<b>exampleSimple1:</b><br/>';
    try {
        $validator->registerSchemaFromString("<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema' elementFormDefault='qualified' attributeFormDefault='unqualified'><xs:element name='request'><xs:complexType><xs:sequence><xs:element name='a' type='xs:string'/><xs:element name='b' type='xs:string'/></xs:sequence><xs:assert test='count(child::node()) = 3'/></xs:complexType></xs:element></xs:schema>");

        $xml = $proc->parseXmlFromString("<Family xmlns='http://myexample/family'><Parent>John</Parent><Child>Alice</Child></Family>");
        $validator->setSourceNode($xml);
        $validator->setProperty('report-node', 'true');
        $validator->validate();
        $node = $validator->getValidationReport();
        echo 'Validation Report:' . $node->getStringValue() . '<br/>';

        echo "Doc is valid";

    } catch(Exception $e){
        echo "Doc is not valid!";
        echo 'Caught validation exception: ',  $e->getMessage(), "\n";
    }

    $validator->clearParameters();
    $validator->clearProperties();

}
            
          
function exampleSimple2($proc, $validator)
{
    echo '<b>exampleSimple2:</b><br/>';
    try {
        $validator->registerSchemaFromString("<?xml version='1.0' encoding='UTF-8'?><schema targetNamespace='http://myexample/family' xmlns:fam='http://myexample/family' xmlns='http://www.w3.org/2001/XMLSchema'><element name='FamilyMember' type='string' /><element name='Parent' type='string' substitutionGroup='fam:FamilyMember'/><element name='Child' type='string' substitutionGroup='fam:FamilyMember'/><element name='Family'><complexType><sequence><element ref='fam:FamilyMember' maxOccurs='unbounded'/></sequence></complexType></element>  </schema>");


        //$proc->setProperty('base', '/');
        $validator->setProperty('report-node', 'true');
        $validator->registerSchemaFromFile("../data/family-ext.xsd");

        $validator->validate("xml/family.xml");
        $node = $validator->getValidationReport();
        if ($node != NULL) {

            echo 'Validation Report:' . $node->getStringValue() . '<br/>';
        } else {
            echo "Doc family.xml is valid!";
        }
    } catch(Exception $e) {
        echo "Doc is not valid!";
        echo 'Caught validation exception: ',  $e->getMessage(), "\n";

    }
    $validator->clearParameters();
    $validator->clearProperties();
}

 function exampleSimple3($proc, $validator)
 {
     echo '<b>exampleSimple3:</b><br/>';
     try {

         $validator->registerSchemaFromFile("../data/family-ext.xsd");
         $validator->registerSchemaFromFile("../data/family.xsd");


         $validator->setProperty('report-node', 'true');
         $validator->validate("xml/family.xml");
         if ($validator->exceptionOccurred()) {
             echo "Error: Doc is not valid!";
             $node = $validator->getValidationReport();
             echo 'Validation Report:' . $node->getStringValue() . '<br/>';
         } else {
             echo "Doc is valid!";
         }
         $validator->clearParameters();
         $validator->clearProperties();

     } catch (Exception $e) {
         echo 'Caught validation exception: ', $e->getMessage(), "\n";

     }
 }
		
	   //$var ='/usr/lib' ;
       //putenv("SAXONC_HOME=$var");
            
        $books_xml = "query/books.xml";
        $books_to_html_xq = "query/books-to-html.xq";
        $baz_xml = "xml/baz.xml";
        $cities_xml = "xml/cities.xml";
        $embedded_xml = "xml/embedded.xml";
        // current directory
        try {
            $proc = new Saxon\SaxonProcessor(true);
            $validator = $proc->newSchemaValidator();

            $version = $proc->version();
            echo '<b>PHP Schema Validation in SaxonC examples</b><br/>';
            echo 'Saxon Processor version: ' . $version;
            echo '<br/>';
            exampleSimple1($proc, $validator);

            echo '<br/>';
            exampleSimple2($proc, $validator);
            echo '<br/>';
            exampleSimple3($proc, $validator);

            unset($validator);
            unset($proc);

        }  catch (Exception $e) {
                 echo 'Failed to create SchemaValidator: ', $e->getMessage(), "\n";

             }
        ?>
    </body>
</html>
