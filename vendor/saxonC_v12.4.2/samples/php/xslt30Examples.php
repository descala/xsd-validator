<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>SaxonC API design use cases</title>
</head>
<body>
<?php

function userFunction1()
{

    echo("userspace function called with no paramXXX\n");

}

// define a user space function
function userFunction($param, $param2)
{

    echo("userspace function called with two paramXXX\n");
    if (is_numeric($param2)) {
        echo("userspace function called cp1\n");
        echo("Param3 = " . $param2);
    }

    if (is_a($param2, "Saxon\\XdmNode")) {
        echo("userspace function called cp2\n");
        /*$proc = new Saxon\SaxonProcessor(true);
        $xpath = $proc->newXPathProcessor();
        $xpath->setContextItem($param3);
                $value = $xpath->evaluate("(//*)");*/
        $value = $param2->getStringValue();
        if ($value != null) {
            echo("XdmNode value= " . $value);
            return $param2;
        } else {
            echo("XdmNode value is null!!!");
        }
    }
    echo("userspace function called cp3\n");
    $resulti = "Result of userFunction+" . $param;

    return $resulti;
}

function userFunctionExample($saxon, $proc, $xmlfile, $xslFile)
{
    echo '<b>userFunctionExample:</b><br/>';
    global $resultg;

    $proc->setProperty("extc", "/path-to-module/saxon");
    $saxon->registerPHPFunction("/path-to-module/saxon");

    $executable = $proc->compileFromFile($xslFile);
    $executable->setInitialMatchSelectionAsFile($xmlfile);

    $result = $executable->transformToString();
    if ($result != null) {
        echo 'Output=======:' . $result;
    } else {
        echo "Result is null";
    }

    $executable->clearParameters();
    $executable->clearProperties();

}

/* simple example to show transforming to string */
function exampleSimple1($saxonproc, $proc, $xmlfile, $xslFile)
{
    echo '<b>exampleSimple1:</b><br/>';
    try {
        $executable = $proc->compileFromFile($xslFile);
        if ($executable != null) {
            $inputNode = $saxonproc->parseXmlFromFile($xmlfile);
            if ($inputNode != null) {
                $result = $executable->transformToString($inputNode);
                if ($result != null) {

                    echo 'Output:' . $result;
                } else {
                    echo "Result is null";
                }
                // $executable->clearParameters();
                $executable->clearProperties();
            }
        }
    } catch(Exception $e) {
        echo "Exception".$e->getMessage();
    }
}

/* simple example to show transforming to file */
function exampleSimple2($proc, $xmlFile, $xslFile)
{
    echo '<b>exampleSimple2:</b><br/>';
    try {
        $executable = $proc->compileFromFile($xslFile);
        $filename = "output1.xml";
        //$executable->setOutputFile($filename); //This test use to test the use of setOutFile and setting of  transformFileToFile($xmlFile, null).
        // PHP no longer supports the passing of null
        $executable->transformFileToFile($xmlFile, $filename);

        if (file_exists($filename)) {
            echo "The file $filename exists";
            unlink($filename);
        } else {
            echo "The file $filename does not exist";
        }
        $executable->clearParameters();
        $executable->clearProperties();
    } catch(Exception $e) {
        echo "Exception".$e->getMessage();
    }
}

/* simple example to show importing a document as string and stylesheet as a string */
function catalogTest($saxonProc)
{
    echo '<b>catalogTest:</b><br/>';
    //$proc->clearParameters();
    try {
        $catalogFiles = array("../data/catalog.xml", "../data/catalog2.xml");
        $saxonProc->setCatalogFiles($catalogFiles);
        //$saxonProc->setcwd("../");
        $trans = $saxonProc->newXslt30Processor();
        $executable = $trans->compileFromFile("http://example.com/books.xsl");

        $executable->setInitialMatchSelectionAsFile("../data/books.xml");
        $executable->setGlobalContextFromFile("../data/books.xml");

        $result = $executable->applyTemplatesReturningString();
        echo '<b>catalogTest</b>:<br/>';
        if ($result != null) {
            echo 'Output:' . $result;
        } else {
            echo "Result is null";
        }

        $executable->clearParameters();
        $executable->clearProperties();

    } catch(Exception $e) {
        echo "Exception".$e->getMessage();
    }
}



function exampleLoopVar($saxonProc, $proc, $xml, $xslt)
{
    $params = array(
        "testparam1" => "testvalue1",
        "testparam2" => "testvalue2",
        "testparam3" => "testvalue3",
    );
    echo '<b>exampleLoopVar:</b><br/>';

    $executable = $proc->compileFromFile($xslt);
    if($executable == null) {
        echo "executable is null";
        return;
    }
    $executable->setInitialMatchSelectionAsFile($xml);

    foreach ($params as $name => $value) {
        echo "==== loop itr =====\n";
        $xdmValue = $saxonProc->createAtomicValue(strval($value));
        if ($xdmValue != null) {
            $executable->setParameter($name, $xdmValue);
        } else {
            echo "Xdmvalue is null";
        }
        //unset($xdmValue);
    }
    try {
        $result = $executable->applyTemplatesReturningString();
        if ($result != null) {
            echo 'Output:' . $result;
        }
    } catch (Exception $e) {
        echo "Exception".$e->getMessage();

    }

   $executable->clearParameters();
    $executable->clearProperties();
}


function exampleParam($saxonProc, $proc, $xmlFile, $xslFile)
{
    echo "\n", '<b>ExampleParam ======================:</b><br/>';

    try {
        $executable = $proc->compileFromFile($xslFile);
        if ($executable == null) {
            echo "executable is null";
            return;
        }
        $executable->setInitialMatchSelectionAsFile($xmlFile);
        $xdmvalue = $saxonProc->createAtomicValue(strval("Hello to you"));
        if ($xdmvalue != null) {
            echo "Name of Class ", get_class($xdmvalue), "\n";
            $str = $xdmvalue->getStringValue();
            if ($str != null) {
                echo "XdmValue:" . $str;
            }
            $executable->setParameter('a-param', $xdmvalue);
        } else {
            echo "Xdmvalue is null";
        }
        $result = $executable->applyTemplatesReturningString();
        if ($result != null) {
            echo 'Output:' . $result . "<br/>";
        } else {
            echo "Result is NULL<br/>";
        }

        $executable->clearParameters();
        //unset($result);
        echo 'again with a no parameter value<br/>';
        $executable->setProperty('!indent', 'yes');
        $result = $executable->applyTemplatesReturningString();
        $executable->clearParameters();
        $executable->clearProperties();

        echo $result;
        echo '<br/>';
        //  unset($result);
        echo 'again with no parameter and no properties value set. This should fail as no contextItem set<br/>';
        $xdmvalue = $saxonProc->createAtomicValue(strval("goodbye to you"));
        $executable->setParameter('a-param', $xdmvalue);

        $result = $executable->applyTemplatesReturningString();

        if ($result != null) {
            echo 'Output =' . $result;
        }


        $executable->clearParameters();
        $executable->clearProperties();
    } catch (Exception $e) {
        echo "Exception".$e->getMessage();
    }
}


function exampleXMLFilterChain($proc, $xmlFile, $xsl1File, $xsl2File, $xsl3File)
{
    echo '====== <b>XML Filter Chain using setSource</b><br/> =======';

    try {
        $executable = $proc->compileFromFile($xsl1File);
        $executable->setInitialMatchSelectionAsFile($xmlFile);

        $xdmValue1 = $executable->applyTemplatesReturningValue();

        $executable2 = $proc->compileFromFile($xsl2File);

        $executable2->setInitialMatchSelection($xdmValue1);

        unset($xdmValue1);
        $xdmValue1 = $executable2->applyTemplatesReturningValue();


        $executable3 = $proc->compileFromFile($xsl3File);
        $executable3->setInitialMatchSelection($xdmValue1);
        $result = $executable3->applyTemplatesReturningValue();
        if ($result != null) {
            echo 'Output:' . $result;
        } else {
            echo 'Result is null';

        }
        $executable3->clearParameters();
        $executable3->clearProperties();
    } catch (Exception $e) {
        echo "Exception: ".$e->getMessage();
    }
}

function exampleXMLFilterChain2($saxonProc, $proc, $xmlFile, $xsl1File, $xsl2File, $xsl3File)
{
    echo '<b>exampleXMLFilterChain2: XML Filter Chain using Parameters</b><br/>';
    try {
        $xdmNode = $saxonProc->parseXmlFromFile($xmlFile);

        if ($xdmNode == NULL) {
            echo "source node is NULL";
            return;
        }


        $executable = $proc->compileFromFile($xsl1File);
        if ($executable == null) {

            return;
        }
        //$executable->setParameter('node', $xdmNode);
        $executable->setInitialMatchSelection($xdmNode);
        $xdmValue1 = $executable->applyTemplatesReturningValue();
        if ($xdmValue1 == null) {
            echo '<b>XML Filter Chain using using Parameters is NULL</b><br/>';

            $proc->clearParameters();
            return;
        }

        // $proc->clearParameters();

        $executable2 = $proc->compileFromFile($xsl2File);

        $executable2->setInitialMatchSelection($xdmValue1);
        echo "After xdmValue1";
        $xdmValue2 = $executable2->applyTemplatesReturningValue();
        if ($executable2->exceptionOccurred()) {
            //$errCode = $proc->getErrorCode();
            $errMessage = $executable2->getErrorMessage();
            echo 'Expected error:  Message=' . $errMessage;

            $executable2->exceptionClear();
        }
        $executable2->clearParameters();

        $executable3 = $proc->compileFromFile($xsl3File);
        $executable3->setParameter('node', $xdmValue2);
        $executable3->setInitialMatchSelection($xdmValue2);
        echo "After setParameter xdmVaue2 \n";
        $result = $executable3->applyTemplatesReturningValue();
        echo "After result ";
        if ($result != null) {
            echo 'Output:' . $result;
        } else {
            echo 'Result is null';

        }
        $executable3->clearParameters();
        $executable3->clearProperties();
    } catch (Exception $e) {
         echo "Exception: ".$e->getMessage();
     }
}

/* simple example to detect and handle errors from a transformation */
function exampleError1($proc, $xmlFile, $xslFile)
{
    echo '<br/><b>exampleError1:</b><br/>';

    try {
        $executable = $proc->compileFromFile($xslFile);
        $executable->setInitialMatchSelectionAsFile($xmlFile);
            $result = $executable->transformToString();
            if ($result != NULL) {

                echo $result;

            }

            $proc->clearParameters();
    }catch (Exception $ex)  {
        echo "Expected Exception: ".$ex->getMessage();
        return;

    }


}


/* simple example to test transforming without an stylesheet */
function exampleError2($proc, $xmlFile, $xslFile)
{
    echo '<b>exampleError2:</b><br/>';

    try {
        $executable = $proc->compileFromFile($xslFile);
        $executable->setInitialMatchSelectionAsFile($xmlFile);
           $result = $executable->transformToString();

           echo $result;
           $executable->clearParameters();
           $executable->clearProperties();
    }catch (Exception $ex)  {
            echo "Expected Exception: ".$ex->getMessage();
            return;

        }


}


function testCallFunction($proc, $trans)
{


    echo "Test: testCallFunction:";
    try {
        $valueArray = array($proc->createAtomicValue((int)2), $proc->createAtomicValue((int)3));
        $executable = $trans->compileFromFile("CallFunctionExample.xsl");

        $v = $executable->callFunctionReturningValue("{http://localhost/}add", $valueArray);
        if ($v != NULL) {

            $item = $v->getHead();
            if ($item != NULL) {
                if ($item->isAtomic() && ($item->getAtomicValue()->getLongValue() == 5)) {
                    echo "Result is true";
                } else {
                    echo "Result is false" . $item->getAtomicValue()->getLongValue();
                }

            } else {
                echo "Item is NULL";
                echo $v;
            }
        } else {

            echo "Value is null";


            echo "testCallFunction ======= FAIL ======";
        }
    } catch(Exception $ex) {
        echo "Exception: ".$ex->getMessage();
        return;
    }

}



function testCallTemplate1($proc, $trans)
{


    echo "Test: testCallTemplate1:";
    try {
        $executable = $trans->compileFromFile("xsl/addition.xsl");
        if (!$trans->exceptionOccurred()) {

            $a = $proc->createAtomicValue((int)2);

            $b = $proc->createAtomicValue((int)3);

            $valueArray = array("a" => $a, "b" => $b);

            //$valueArray["a"] = $a;
            //$valueArray["b"] = $b;
            $executable = $trans->compileFromFile("xsl/addition.xsl");

            $executable->setProperty("omit-xml-declaration", "true");

            $executable->setInitialTemplateParameters($valueArray);

            $v = $executable->callTemplateReturningValue("t");

            if ($v != NULL) {

                $item = $v->getHead();
                if ($item != NULL) {

                    if ($item->isNode() && ($item->getStringValue() == 5)) {  //($item->getAtomicValue()->getLongValue() == 5)) {
                        echo "Result is true";
                    }

                } else {
                    echo "Item is NULL";
                    echo $v;
                }

            } else {

                echo "Value is null";


                echo "testCallTemplate ======= FAIL ======";
            }
            $executable->clearParameters();
        } else {

            echo "Error found in stylesheet";
        }
    } catch(Exception $ex) {
        echo "Exception: ".$ex->getMessage();
        return;
    }


}


function testPerformance()
{

// output current PID and number of threads
    $pid = getmypid();
    $child_threads = trim(`ls /proc/{$pid}/task | wc -l`);

    echo "<pre>";
    echo "Process ID :$pid" . PHP_EOL;
    echo "Number of threads: $child_threads" . PHP_EOL;
    echo str_repeat("-", 20) . PHP_EOL;

    $sax = new Saxon\SaxonProcessor(false);
    unset($sax);
    // output number of threads again
    $child_threads = trim(`ls /proc/{$pid}/task | wc -l`) . PHP_EOL;
    echo "Number of threads: $child_threads" . PHP_EOL;


}


     $foo_xml = "xml/foo.xml";
     $foo_xsl = "xsl/foo.xsl";
     $baz_xml = "xml/baz.xml";
     $baz_xsl = "xsl/baz.xsl";
     $foo2_xsl = "xsl/foo2.xsl";
     $foo3_xsl = "xsl/foo3.xsl";
     $err_xsl = "xsl/err.xsl";
     $err1_xsl = "xsl/err1.xsl";
     $text_xsl = "xsl/text.xsl";
     $cities_xml = "xml/cities.xml";
     $embedded_xml = "xml/embedded.xml";
     $multidoc_xsl = "xsl/multidoc.xsl";
     $identity_xsl = "  xsl/identity.xsl";

     $saxonProc = new Saxon\SaxonProcessor(true);

     $version = $saxonProc->version();
     echo 'Saxon Processor version: '.$version;
     echo '<br/>';
     if($saxonProc->isSchemaAware()) {
        echo 'Processor is schema aware';
     } else {
        echo 'Processor is not schema aware';

     }

     $proc = $saxonProc->newXslt30Processor();

    echo '<br/>';
    testCallFunction($saxonProc, $proc);
    echo '<br/>';
    testCallTemplate1($saxonProc, $proc);
    echo '<br/>';
    exampleSimple1($saxonProc, $proc, $foo_xml, $foo_xsl);
    echo '<br/>';
    catalogTest($saxonProc);
    echo '<br/>';
    exampleSimple2($proc, "xml/foo.xml", $foo_xsl);
    echo '<br/>';
    catalogTest($saxonProc, $proc);
    echo '<br/>';
    exampleLoopVar($saxonProc, $proc, $foo_xml, $foo_xsl);
    exampleParam($saxonProc, $proc, $foo_xml, $foo_xsl);
    exampleError1($proc, $foo_xml, $err_xsl);
    echo '<br/>';
    exampleError2($proc, $foo_xml, $err1_xsl);
    echo '<br/>';
    exampleXMLFilterChain($proc, $foo_xml, $foo_xsl, $foo2_xsl, $foo3_xsl);
    echo '<br/>';
    exampleXMLFilterChain2($saxonProc, $proc, $foo_xml, $foo_xsl, $foo2_xsl, $foo3_xsl);
    echo '<br/>';
    unset($proc);
    unset($saxonproc);
    testPerformance();


?>
</body>
</html>
