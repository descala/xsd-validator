<?php
/*error_reporting(E_ALL|E_STRICT);
ini_set('display_errors', 'on');*/
//ini_set('MAX_EXECUTION_TIME', '-1');
set_time_limit(300);
/*$root = pathinfo($_SERVER['SCRIPT_FILENAME']);
define('BASE_FOLDER', basename($root['dirname']));
define('SITE_ROOT', realpath(dirname(__FILE__)));
define('SITE_URL', 'http://' . $_SERVER['HTTP_HOST'] . '/' . BASE_FOLDER);


echo 'BASE_FOLDER' . basename($root['dirname']);
echo '<br/>';
echo 'SITE_ROOT' . realpath(dirname(__FILE__));
echo '<br/>';
echo 'SITE_URL' . 'http://' . $_SERVER['HTTP_HOST'] . '/' . BASE_FOLDER;
echo '<br/>';
*/

//$path1 = "/media/ond1/c8f4c380-ed5d-4791-b60d-90df7fd39798/work/git/xslt30-test/";
//$path = "/media/ond1/c8f4c380-ed5d-4791-b60d-90df7fd39798/work/git/";

$path = __DIR__ . "/xslt30-test/";
$catalog = $path . "catalog.xml";
$saxon_version = "";

$proc = new Saxon\SaxonProcessor(true);
$proc->setConfigurationProperty("http://saxon.sf.net/feature/licenseFileLocation", "/usr/lib/saxon-license.lic");
$proc->setcwd("");

$xsltproc = $proc->newXslt30Processor();

$xpathProcForEnv = $proc->newXPathProcessor();

$xpathProcForCompareNodes = $proc->newXPathProcessor();
$xpathProcForCompareNodes->declareNamespace("fn","http://www.w3.org/2005/xpath-functions");


$schemaValidator = $proc->newSchemaValidator();



$xpathProcForEnv->declareNamespace("", "http://www.w3.org/2012/10/xslt-test-catalog");
//$xpathProcForEnv->setBaseURI($path);
/*$start = microtime(true);
              $proc->setSourceFile("cat.xml");
                $proc->importStylesheetFile("test.xsl");
                $result = $proc->transformToValue();
 $end = microtime(true); */

$pass = 0;
$fail = 0;
$error =0;
$notrun = 0;
$run_test = "streamable";
$run_test_case = null;//"result-document-0206";
$run_assertion = null; //"serialization-matches";
$total_tests = 0;
$exceptionList = "number-5018 number-2806 number-5014 number-5029";


function test_set_files($catalog)
{
    global $proc;
    global $xpathProcForEnv;
    $array = array();
    $attName;
    $attFile;

    if (file_exists($catalog)) {
        //$xmlV = $proc->parseXmlFromFile($catalog);//simplexml_load_file($catalog);
        //$xpathProcForEnv->setContextItem($xmlV);
        $xpathProcForEnv->setContextFile($catalog);

        $xml = $xpathProcForEnv->evaluate("//*:test-set");

        if ($xml != NULL) {
            //foreach ($xml->{'test-set'} as $value) {
            for ($i = 0; $i < $xml->size(); $i++) {
                $value = $xml->itemAt($i);
//	echo "________________".$value->attributes()->name."_________".$value->attributes()->file;
                
                if ($value != NULL && $value->isNode()) {
                    $node = $value->getNodeValue();

                    if ($node != NULL) {
                        $attName = $node->getAttributeValue("name");
                        $attFile = $node->getAttributeValue("file");
                        $array["" . $attName] = $attFile;
                    } else {
                        error_log("Node for test-set is NULL");
                    }
                    unset($node);
                } else {
                    error_log("Value for test-set is NULL");

                }
                unset($value);
            }

        }
    } else {
        exit('Failed to open ' . $catalog);
    }
	error_log("checkpoint 1");
    return $array;
}

function check_dependency($xml)
{
    error_log("check_dependency".$xml);
    if($xml != null ) {           //&& $xml->size() > 0s
        error_log("dependency_count=".$xml->size());
        $xmlNode = $xml->itemAt(0)->getNodeValue();
        error_log("check_depend=".$xmlNode);

        $count = $xmlNode->getChildCount();
        error_log("dependency_child=".$count);


        //$inverse = "false".equals(dependency.attribute("satisfied"));
        //$needed = !"false".equals(dependency.attribute("satisfied"));

        for ($i = 0; $i < $count; $i++) {
            $child = $xmlNode->getChildNode($i);
            error_log("NodeKind=".$child->getNodeKind().", check_depend child=".$xmlNode->getChildNode($i)->getNodeKind(). "child=".$xmlNode->getChildNode($i));
            if ($child != null && $child->getNodeKind() == 1) {
                $var1 = $child->getLocalName();
                error_log("check_depend var1=".$var1. " value=".$child->getAttributeValue('value')."feature result=".($child->getAttributeValue('value')=="schema_aware"));
                switch ($var1) {
                    case "year_component_values":
                        if($child->getAttributeValue('value') == "support negative year")  {
                            //return true;
                            continue;
                        }  else {
                            //if value = 'support year zero' then set schema_aware and return true
                            unset($xmlNode);
                            unset($child);
                            return false;
                        }

                    case "feature":
                        $attrStr = $child->getAttributeValue('value');
                        if ($attrStr == "schema_aware" or $attrStr == "namespace_axis" or $attrStr == "serialization" or $attrStr == "dtd" or $attrStr == "fn-transform-XSLT" or $attrStr == "available_documents" or $attrStr == "XPath_3.1" or
                        $attrStr == "higher_order_functions" or $attrStr == "HTML4" or $attrStr == "HTML5" or $attrStr == "backwards_compatibility" or $attrStr == "unparsed_text_encoding" or $attrStr == "built_in_derived_types" or 
                        $attrStr == "assertSerializationMatches" or $attrStr == "default_output_encoding" or $attrStr == "maximum_number_of_decimal_digits" or $attrStr == "supported_calendars_in_date_formatting_functions" or
                        $attrStr == "default_calendar_in_date_formatting_functions" or $attrStr == "disabling_output_escaping") {
                            //return true;
                            continue;
                        } elseif ($attrStr == "streaming") {
                            error_log("check_DependencyXX returning false");
                            //unset($xmlNode);
                            //unset($child);
                            continue;
                            //break;
                        } else {
                            error_log("check_DependencyXX returning false");
                            return false;
                        }
                    case "spec":
                        if ($child->getAttributeValue('value')== "XSLT30" or $child->getAttributeValue('value')== "XSLT20+" or $child->getAttributeValue('value')== "XSLT30+" or $child->getAttributeValue('value')== "XSLT10+") {
                           //true
                            continue;
                        } else {
                            error_log("check_DependencyXX returning false");
                            unset($xmlNode);
                            unset($child);
                            return false;
                        }
                    

                }
            }
            unset($child);
        }
    }
    unset($xmlNode);
    return true;
}

function parse_environment($xml, $path)
{
    global $proc;
    global $xpathProcForEnv;
    global $schemaValidator;
    $validateSources = false;
    $array = array();
    if($xpathProcForEnv == null) {
        return $array;
    }
    
    $xpathProcForEnv->setContextItem($xml);
    $envValues = $xpathProcForEnv->evaluate("//*:test-set/*:environment");

    
    if($envValues == null) {
        return $array;
    }

    $count = $envValues->size();
    for ($i = 0; $i < $count; $i++) {

        $value = $envValues->itemAt($i);
        if( $value->isNode()) {

            $nodeii = $value->getNodeValue();
            if ($nodeii == null) {
                echo "environment node is null";
                continue;


            }

            $envName = $nodeii->getAttributeValue("name");
            $newarray = array();
            $newarray["" . $envName] = array();
            /*if($envName == "as-16") {
            error_log("env node=".$nodeii.",   \nenvName BBBB1= ".$envName);
            }  */

            //$array["" . $envName] = array();
            $xpathProcForEnv2 = $proc->newXPathProcessor();
            if($xpathProcForEnv == null) {
                return $array;
            }
            $xpathProcForEnv2->clearParameters();
            $xpathProcForEnv2->clearProperties();
            $xpathProcForEnv2->setContextItem($nodeii);

            $schemas = $xpathProcForEnv2->evaluate("./*:schema");

            if($schemas != null) {
                $sscount = $schemas->size();
                for ($j = 0; $j < $sscount; $j++) {
                    $valuej = $schemas->itemAt($j);
                    if ($valuej == null) {
                        continue;
                    }

                    if ($valuej->isNode()) {
                        $nodej = $valuej->getNodeValue();
                        /*if($envName == "as-16") {
                            error_log("size=".$scount.", sources for env node=" . $envName . ",   \nenvName CCCCC1= " . $nodej. "size = ".$scount);
                        }     */

                        $role = $nodej->getAttributeValue("role");

                        if ($role != "secondary") {
                            $href = $nodej->getAttributeValue("file");
                            $ns = $nodej->getAttributeValue("uri");

                            if ($href == null) {


                            } else {
                                error_log("registering_schema=" . $path . $href);
                                if($schemaValidator == null) {
                                    error_log("schemavalidator null cp0");

                                }
                                $schemaValidator->registerSchemaFromFile($path . $href);


                            }
                            if ($ns == null) {
                                $ns = "";
                            }
                            $xpathProcForEnv->importSchemaNamespace($ns);

                        }
                    }

                    if ($role == "source-reference") {
                        $validateSources = true;
                    }
                    if ($role == "stylesheet-import") {
                        //environment.xsltCompiler.setSchemaAware(true);
                    }


                }


            }



            $sources = $xpathProcForEnv2->evaluate("./*:source");
            $envStylesheets = $xpathProcForEnv2->evaluateSingle("./*:stylesheet");
            $scount = 0;
            if($sources != null) {
                $scount = $sources->size();
                $newarray["sources"][] = array(); //$newarray["" . $envName]["sources"] = array();


                for ($j = 0; $j < $scount; $j++) {
                    $valuej = $sources->itemAt($j);
                    if ($valuej == null) {

                        continue;

                    }
                    if ($valuej->isNode()) {
                        $nodej = $valuej->getNodeValue();
                        /*if($envName == "as-16") {
                            error_log("size=".$scount.", sources for env node=" . $envName . ",   \nenvName CCCCC1= " . $nodej. "size = ".$scount);
                        }     */
                        $rawuri = $nodej->getAttributeValue("uri");
                        $role = $nodej->getAttributeValue("role");
                        $validation = $nodej->getAttributeValue("validation");
                        if ($validation == null) {
                              $validation = "skip";
                        }
                        //$file = $nodej->getAttributeValue("file");
                        if ("." == $role) {
                            $href = $nodej->getAttributeValue("file");
                            if ($href == null) {
                                $xpathProcForEnv->clearParameters();
                                $xpathProcForEnv->clearProperties();
                                $xpathProcForEnv->setContextItem($nodej);
                                $sourceContent = $xpathProcForEnv->evaluateSingle("string(content)");
                                $newarray["sources"][".content"] = $sourceContent->getStringValue();
                                //$array["" . $envName]["sources"][".content"] = $sourceContent->getStringValue();


                            } else {
                                $newarray["sources"][".file"] = $href;
                                $streaming = $nodej->getAttributeValue("streaming");
                                if($streaming != null and $streaming == "true") {
                                    $newarray["sources"]["streaming"] = "true";
                                }
                                //$array["" . $envName]["sources"][".file"] = $href;

                            }
                            unset($nodej);

                        }  elseif ($rawuri != null) {
                            //$array["" . $envName]["sources"][$rawuri] = $rawuri;
                            $newarray["sources"][".file"] = $rawuri;
                            if($streaming != null and $streaming == "true") {
                                $newarray["sources"]["streaming"] = "true";
                            }
                        } elseif($validateSources == true) {
                            $newarray["sources"]["validation"] = $validation;

                        }

                    }
                }


            }


            if($envStylesheets != null) {
                $envStylesheet = $envStylesheets->getNodeValue();
                if($envStylesheet != null) {
                    $newarray["stylesheet"] = $envStylesheet->getAttributeValue("file");
                }
                unset($envStylesheet);

            }

           // if($envName == "as-01b") {
                //error_log("Create env for " . $envName . " dump=" . print_r($newarray, TRUE));
                $array["" . $envName] = $newarray;
                error_log(" Whole dump=" . print_r($array, TRUE));
           // }
        }
        unset($value);
       unset($nodeii);
    }
    echo "<br/>";
    echo "<br/>";
     //Test

    //$testArraySize = count($array);
    /*error_log("TEST ARRAY ITEMS YYYYYY1");
    foreach ( $array as $var ) {
        error_log("Array item".print_r($var, TRUE)."\n");
        error_log("\n");
        error_log("\n");
    }   */


    return $array;
}

function test_case($test_set)
{
    global $proc;
    global $xpathProcForEnv;
    global $run_test;
    global $run_test_case;
    global $total_tests;
    global $notrun;
    global $exceptionList;
    $env = null;
    $xml = null;
    $test_path = pathinfo($test_set)['dirname'] . "/";

    $result = null;
    if (file_exists($test_set)) {
        $xml = $proc->parseXmlFromFile($test_set);

        if($xml == null) {
            echo "Cannot find test " . $test_set . "\n";
            if ($proc->exceptionOccurred() && $proc->getErrorMessage() != null) {
                echo " error: " . $proc->getErrorMessage();
            }
            return;
        }

        $child0 = $xml->getChildNode(0);
        if($child0 == null) {
                echo "Cannot find child node of test " . $test_set . "\n";
                if ($proc->exceptionOccurred() && $proc->getErrorMessage() != null) {
                        echo " error: " . $proc->getErrorMessage();
                }
               return;
        }
        $test_set_name = $child0->getAttributeValue("name");
        if($run_test != null && $test_set_name != $run_test) {
            return;
        }
         

        $env = parse_environment($xml, $test_path);



        echo "<table border='1' style='width:60%'>
<tr>
  <th>Test Case Name </th>
  <th style='width:80%'>Result </th>
</tr>";

        $t_dep = getNodeFromXPath($xml, "./*:test-set/*:dependencies");

        $check = check_dependency($t_dep);
        
        $testCases = $xpathProcForEnv->evaluate("//*:test-case");
        if ($check and   $testCases != null) {

            $countTC = $testCases->size();
            $total_tests += $countTC;
            for ($x = 0; $x < $countTC; $x++) {
                $value = $testCases->itemAt($x);
                if($value->isNode()) {
                    $nodex = $value->getNodeValue();
                    $testCaseName = $nodex->getAttributeValue("name");
                    echo "<tr><td>$testCaseName</td>";

                    if(($run_test_case == null || $run_test_case == $testCaseName) && strpos($exceptionList, $testCaseName) == false) {
                        $result = run_test_case($nodex, $env, $test_path);
                    }  else {
                        $result = "Not run";

                    }

                    echo "<td>" . $result . "<br/></td>";
                    echo "</tr>";
                    //$test = $value->{'test'}->{'stylesheet'};
                    //echo "____test:".$test_path."tests".$test->attributes()->file;
                }
            }

        } else {
            echo "<tr><td>No tests run</td><td></td></tr>";
            if($testCases != null) {
                $notrun = $notrun + $testCases->size();
            }
        }
        echo "</table>";

    } else {
        exit('Failed to open ' . $test_set);
    }
    $env = null;
    unset($env);
}

function getNodeFromXPath($node, $xpath) {
    global $xpathProcForEnv;
    if($xpathProcForEnv == NULL) {
        return NULL;
    }
    $xpathProcForEnv->clearParameters();
    $xpathProcForEnv->clearProperties();
    if($node != null) {
        $xpathProcForEnv->setContextItem($node);
    }
      $result = $xpathProcForEnv->evaluate($xpath);
      return $result;

}



 function setFlags($inFlags){
        $flags = 0x01;
        for ($i = 0; $i < strlen($inFlags); $i++) {
            $c = $inFlags[$i];
            switch ($c) {
                case 'd':
                    $flags |= 0x01;
                    break;
                case 'm':
                    $flags |= 0x08;
                    break;
                case 'i':
                    $flags |= 0x02;
                    break;
                case 's':
                    $flags |= 0x20;
                    break;
                case 'x':
                    $flags |= 0x04;  // note, this enables comments as well as whitespace
                    break;
                case 'u':
                    $flags |= 0x40;
                    break;
                case 'q':
                    $flags |= 0x10;
                    break;
                case 'c':
                    $flags |= 0x80;
                    break;
                default:
                    throw new Exception("Invalid character '" + c + "' in regular expression flags");
            }
        }
        return $flags;
    }


function getSingleNodeFromXPath($node, $xpath) {
    global $xpathProcForEnv;
    if($xpathProcForEnv == NULL) {
        return NULL;
    }
    $xpathProcForEnv->clearParameters();
    $xpathProcForEnv->clearProperties();
    if($node != null) {
        $xpathProcForEnv->setContextItem($node);
    }

      $result = $xpathProcForEnv->evaluateSingle($xpath);
      return $result;

}



function effectiveBooleanValue($node, $xpath) {
    global $xpathProcForEnv;
    if($xpathProcForEnv == NULL) {
        return NULL;
    }
    $xpathProcForEnv->clearParameters();
    $xpathProcForEnv->clearProperties();
    if($node != null) {
        $xpathProcForEnv->setContextItem($node);
    }

      $result = $xpathProcForEnv->effectiveBooleanValue($xpath);
      return $result;

}

$C0WHITE = array(
            false, false, false, false, false, false, false, false,  // 0-7
            false, true, true, false, false, true, false, false,     // 8-15
            false, false, false, false, false, false, false, false,  // 16-23
            false, false, false, false, false, false, false, false,  // 24-31
            true);                                                    // 32;

function containsWhitespace(string $value) {
        for ($i = strlen($value) - 1; $i >= 0; ) {
            $c = value[$i--];
            if ($c <= 32 && C0WHITE[$c]) {
                return true;
            }
        }
        return false;
    }

function collapseWhitespace(string $in) {
    if (!containsWhitespace($in)) {
        return $in;
    }
        $len = strlen($in);
        $sb = "";
        $inWhitespace = true;
        $i = 0;
        for (; $i < $len; $i++) {
            $c = $in[$i];
            switch ($c) {
                case '\n':
                case '\r':
                case '\t':
                case ' ':
                    if ($inWhitespace) {
                        // remove the whitespace
                    } else {
                        $sb .= ' ';
                        $inWhitespace = true;
                    }
                    break;
                default:
                    $sb .= c;
                    $inWhitespace = false;
                    break;
            }
        }
        $nlen = strlen($sb);
        if ($nlen > 0 && $sb[$nlen - 1] == ' ') {
            $sb = substr($sb, 0, $nlen - 1);
        }
        return $sb;
    }

    function startsWith($haystack, $needle) {
        return substr_compare($haystack, $needle, 0, strlen($needle)) === 0;
    }
    function endsWith($haystack, $needle) {
        return substr_compare($haystack, $needle, -strlen($needle)) === 0;
    }



    function testAssertion($baseUri, $assert, $result, $resultDocMap, $errorCode) {
    //global $xpathProcForAssertions;

    global $proc;
    global $xpathProcForCompareNodes;


    $xpathProcForAssertions = $proc->newXPathProcessor();
    if($xpathProcForAssertions == NULL) {
        error_log("XPathProc not created");
        return false;
    }

    
    /*$xpathProcForAssertions->declareNamespace("fn", "http://www.w3.org/2005/xpath-functions");
    $xpathProcForAssertions->declareNamespace("xs", "http://www.w3.org/2001/XMLSchema");
    $xpathProcForAssertions->declareNamespace("math", "http://www.w3.org/2005/xpath-functions/math");
    $xpathProcForAssertions->declareNamespace("map", "http://www.w3.org/2005/xpath-functions/map");
    $xpathProcForAssertions->declareNamespace("array", "http://www.w3.org/2005/xpath-functions/array");
    $xpathProcForAssertions->declareNamespace("j", "http://www.w3.org/2005/xpath-functions");*/

    $xpathProcForAssertions2 = $proc->newXPathProcessor();
    if($xpathProcForAssertions2 == NULL) {
        error_log("XPathProc2 not created");
        return false;
    }

   //$aSize = $asserts->size();
   //for($i=0; $i < $aSize; $i++) {

       //$item = $asserts->itemAt($i)->getNodeValue();//getNodeFromXPath($asserts->itemAt($i)->getNodeValue(), "//result");
      // if($asserts->itemAt(0)->isNode())  {
          // $assert =  $asserts->itemAt($i)->getNodeValue();
           $xpathProcForAssertions->setBaseURI($assert->getBaseURI());
           //error_log("chck result=".$assert);

       $assertName = $assert->getLocalName(); // substr($assert->getNodeName(), strpos($assert->getNodeName(), "}")+1);
           //error_log("localName=".$assertName.", assertxx=".$assert);

    if ($assertName == "error") {
        error_log("error check!!!! ");
            if($errorCode == null) {
                $errorCode = "";
            }
            $aErrorCode = $assert->getAttributeValue("code");
            if ($aErrorCode == $errorCode) {
                return true;
            } else {
                error_log("Test failed but not with the correct error code, assert=".$aErrorCode . " Actual error code=".$errorCode);
                 return true;
            }

        

    }

    if($result == null) {
        error_log("Result is NULL");
        return false;
    }

    if($assertName == "assert-xml") {
            error_log("Entered assert-xml");
            $file = $assert->getAttributeValue("file");
            $xpathProcForAssertions->setContextItem($assert);

            $comparandNode = $xpathProcForAssertions->evaluateSingle("if (@file) then unparsed-text(resolve-uri(@file, base-uri(.))) else string(.)");
            $message = $xpathProcForAssertions->getErrorMessage();
            if($message != null || $comparandNode == null) {
                error_log("ERRORXXX=" . $message);
                return false;
            }
            $comparand = $comparandNode.'';
            //error_log("comparand=".$comparandNode);
            if (strpos($comparand, "<?xml") === 0) {
                $index = strpos($comparand, "?>");
                error_log("Error=       ".$index);
                $comparand = substr($comparand, $index + 2);
            }
            $comparand = trim($comparand);

            $comparand =  str_replace(array("\r\n"), '', $comparand);
            $comparandi = str_replace(array(' ', "\n", "\t", "\r"), '', $comparand);
            $resultStr =  $result->itemAt(0)->getNodeValue();
            $resultStri =  str_replace(array(' ', "\n", "\t", "\r"), '', $resultStr);
            

            //error_log("XXXXXX comparand=" . $comparand . ", result = " . $resultStri);

            if ($comparandi == $resultStri) {
                error_log("assert-xml-1: " . $comparand . "\n Outcome:" . $result);
                return true;
            } else if($resultStr == "" or $resultStr == null or $comparand == null or $comparand == ""){
                return false;
            } else {
                error_log("assert-xml with deep-equal cp0 ");
                $comparandNodei = $proc->parseXmlFromString($comparand);
                $resultNodei = $proc->parseXmlFromString($resultStr);

                if($comparandNodei == null or $resultNodei == null) {
                    return false;
                }
                error_log("assert-xml with deep-equal: " . $comparandNodei . "\n Outcome:" . $resultNodei);
                return compareNodes($comparandNodei, $resultNodei);
            }

        } elseif ($assertName == "assert") {
        $xpathProcForAssertions->clearParameters();
        $xpathProcForAssertions->clearProperties();
        if ($result != null && $result->size() == 1) {


            $item = $result->itemAt(0);
            //error_log("itemYYYYYY= ".$item->getNodeValue());

            $xpathProcForAssertions2->setContextItem($item);

            $namespaceValues = $xpathProcForAssertions2->evaluate("for \$i in 1 to count(//namespace::*) return if (empty(index-of((//namespace::*)[position() = (1 to (\$i - 1))][name() = name((//namespace::*)[\$i])], (//namespace::*)[\$i]))) then (//namespace::*)[\$i] else ()");

            $xpathProcForAssertions->clearParameters();
            $xpathProcForAssertions->clearProperties();

            if ($namespaceValues != null && $namespaceValues->size() > 0) {
                for ($j = 0; $j < $namespaceValues->size(); $j++) {
                    $item = $namespaceValues->itemAt($j);
                    if ($item->isNode()) {
                        $nsNode = $item->getNodeValue();
                        if ($nsNode != null) {
                            $nsName = $nsNode->getNodeName();
                            error_log("Namespace=" . $nsName . " = " . $nsNode->getStringValue());

                            if ($nsName != null) {
                                // $xpathProcForAssertions->declareNamespace($nsName, $nsNode->getStringValue());
                            }

                        }

                    }
                }


            }

            $xpathProcForAssertions->setContextItem($result->itemAt(0));
            $xpath = $assert->getChildNode(0)->getStringValue();

            //error_log("xpath=".$xpath. ", XXXXXX result=" . $result->itemAt(0));
            $check = $xpathProcForAssertions->effectiveBooleanValue($xpath);
            $testResult = $xpathProcForAssertions->evaluateSingle("/out");

            // error_log(", XXXXXX testResult=" . $testResult);

            if ($check == false) {
                return "assert: " . $xpath . "\n OutcomeXXY:" . $result->itemAt(0);
            }
            return true;


        } else {
            error_log("FAIL - assertion with multiple results not handled yet");
            return false;

        }


    } elseif ($assertName == "assert-true") {
         //if (isException()) {
        //            return false;
        //        } else {
        //            return result.value.size() == 1 &&
        //                    result.value.itemAt(0).isAtomicValue() &&
        //                    ((XdmAtomicValue) result.value.itemAt(0)).getPrimitiveTypeName().equals(QName.XS_BOOLEAN) &&
        //                    ((XdmAtomicValue) result.value.itemAt(0)).getBooleanValue();
        //        }
        if ($result->size() == 1 and $result->itemAt(0)->isAtomic()) {
            error_log("assert-true = ".  $result->itemAt(0)->getAtomicValue->getPrimitiveTypeName());
        }
        return ($result->size() == 1 and $result->itemAt(0)->isAtomic() and $result->itemAt(0)->getAtomicValue->getPrimitiveTypeName() == "XS_BOOLEAN" and $result->itemAt(0)->getAtomicValue->getBooleanValue());


    }  elseif ($assertName == "assert-false") {
        if ($result->size() == 1 and $result->itemAt(0)->isAtomic()) {
            error_log("assert-false = ".  $result->itemAt(0)->getAtomicValue->getPrimitiveTypeName());
        }
        return ($result->size() == 1 and $result->itemAt(0)->isAtomic() and $result->itemAt(0)->getAtomicValue->getPrimitiveTypeName() == "XS_BOOLEAN" and !$result->itemAt(0)->getAtomicValue->getBooleanValue());



    } elseif ($assertName == "assert-string-value") {
         $resultString = "";
         $assertionString = $assert->getStringValue();
         if(is_a($result, "Saxon\XdmItem")) {
             $resultString = $result->getStringValue();
         } elseif($result->size() == 1) {
             $resultString = $result->itemAt(0)->getStringValue();
         }else{
             $iSize = $result->size();
             for($i = 0; $i < $iSize; $i++) {
                 $resultString .= $result->itemAt(0)->getStringValue();
             }
         }
        $normalizeAtt = true;
         $normalizeAttStr = $assert->getAttributeValue("normalize-space");
         if($normalizeAttStr != null) {
             if($normalizeAttStr == "true" or $normalizeAttStr == "1") {
                 $assertionString = collapseWhitespace($assertionString);
                 $resultString = collapseWhitespace($resultString);
             }
         }
        if ($resultString == $assertionString) {
            return true;
        } else {
            return false;
        }

    } elseif ($assertName == "assert-result-document") {
  
        //                 XdmNode subAssertion = (XdmNode) catalogXpc.evaluateSingle("*", assertion);
        
        $xpathProcForAssertions->clearParameters();
        $xpathProcForAssertions->clearProperties();
        $xpathProcForAssertions->setContextItem($assert);
        $subAssertion = $xpathProcForAssertions->evaluateSingle("*");

        $uri =  $baseUri.$assert->getAttributeValue("uri");
        if(!file_exists($uri)) {
            error_log("**** Invalid output uri ". $uri + "Now checking ResultMap" );
            //return false;
        }
        $resultDoc = $resultDocMap->get($uri); //$proc->parseXmlFromFile($uri);
        if($resultDoc == null) {
            error_log("**** Could not find document ". $uri );
            error_log("**** Keys= ". $resultDocMap->keys() );
                    return false;

        } else {
            error_log("**** Result document: ". $resultDoc);
        }
        $ok = testAssertion($baseUri, $subAssertion, $resultDoc, $resultDocMap, $errorCode);

        if(!$ok) {
          error_log("**** Assertion failed for result-document " . $uri);
        }
        unlink($uri);
        return ok;
        
                return ok;
        
        
    }elseif ($assertName == "serialization-matches") {

        //                   String flagsAtt = assertion.attribute("flags");
        $flagsAtt = $assert->getAttributeValue("flag");
        if ($flagsAtt == null) {
            $flagsAtt = "";
        }
        //
        $regex = $assert->getStringValue();

        $resultString = "";

        if(is_a($result, "Saxon\XdmItem")) {
            $resultString = $result->getStringValue();
        } elseif($result->size() == 1) {
            $resultString = $result->itemAt(0)->getStringValue();
        }else{
            $iSize = $result->size();
            for($i = 0; $i < $iSize; $i++) {
                $resultString .= $result->itemAt(0)->getStringValue();
            }
        }

        $assertionRegex = $assert->getStringValue();
        $flagsAtt = str_replace("!", "", $flagsAtt);
        $matches = null;

        $xpathProcForCompareNodes->clearParameters();
        $xpathProcForCompareNodes->clearProperties();

        $ok1 = $xpathProcForCompareNodes->effectiveBooleanValue("fn:matches('".$resultString."', '".$assertionRegex."','".$flagsAtt."')");


        //$ok1 = preg_match($assertionRegex,$resultString, $matches, setFlags($flagsAtt));
        if($ok1) {
            return true;
        } else {
            error_log("serialization-matches error in preg_match");

            return false;
        }

        //                   List<String> warnings = new ArrayList<>(1);
        //                   try {
        //                       String principalSerializedResult = result.serialization;
        //                       if (principalSerializedResult == null) {
        //                           driver.println("No serialized result available!");
        //                           return false;
        //                       }
        //                       RegularExpression re = xpath.getProcessor().getUnderlyingConfiguration().compileRegularExpression(
        //                               regex, flagsAtt, "XP30", warnings);
        //                       if (re.containsMatch(principalSerializedResult)) {
        //                           return true;
        //                       } else {
        //                           driver.println("Serialized result:");
        //                           driver.println(principalSerializedResult);
        //                           return false;
        //                       }


    }elseif ($assertName == "assert-serialization") {

        
        $method = $assert->getAttributeValue("method");
        if ($method == null) {
            $method = "xml";
        }
        $resultString = "";
        if(is_a($result, "Saxon\XdmItem")) {
            $resultString = $result->getStringValue();
        } elseif($result->size() == 1) {
            $resultString = $result->itemAt(0)->getStringValue();
        }else{
            $iSize = $result->size();
            for($i = 0; $i < $iSize; $i++) {
                $resultString .= $result->itemAt(0)->getStringValue();
            }
        }
        $xpathProcForAssertions2->clearParameters();
        $xpathProcForAssertions2->clearProperties();
        $xpathProcForAssertions2->setContextItem($assert);

        $comparand = $xpathProcForAssertions2->evaluate("if (@file) then " .
                                                "if (@encoding) " .
                                                "then unparsed-text(resolve-uri(@file, base-uri(.)), @encoding) " .
                                                "else unparsed-text(resolve-uri(@file, base-uri(.))) " .
                                                "else string(.)");
        $comparand =  str_replace(array("\r\n"), "\n", $comparand);
        if (endsWith($comparand, "\n")) {
            $comparand = substr($comparand, 0, strlen($comparand) - 1);
        }

        /*if ($resultString == null) {
            if (is_a($result, "Saxon\XdmItem")) {
                $resultString = ((XdmItem) result . value).getStringValue();
            }
        }                     */

        $xpathProcForAssertions->clearParameters();
        $xpathProcForAssertions->clearProperties();


        $isHtml = $method == "html" or $method == "xhtml";
        $normalize = $isHtml;
        if (!$normalize) {
            $normalizeAtt = $assert->getAttributeValue("normalize-space");
            $normalize = $normalizeAtt != null and (trim($normalizeAtt) == "true" or trim($normalizeAtt) == "1");
        }
        if ($normalize) {
            $comparand = collapseWhitespace($comparand);
            $resultString = collapseWhitespace($resultString);
        } else if (endsWith($resultString, "\n")) {
            $resultString = substr($resultString, 0, strlen($resultString) - 1);
        }
        if ($isHtml) {
            // should really do this only for block-level elements
            $comparand = str_replace(" <", "<", $comparand);
            $comparand = str_replace("> ", ">", $comparand);
            $resultString = str_replace(" <", "<", $resultString);
            $resultString = str_replace("> ", ">", $resultString);
        }
        if ($resultString  == $comparand) {
            return true;
        } else {
            return false;
        }

    }elseif ($assertName == "all-of") {
        $jasserts = getNodeFromXPath($assert, "*");
        //$jNode = $jasserts->itemAt(0)->getNodeValue();
        $jSize = $jasserts->size();
        for ($j = 0; $j < $jSize; $j++) {
            if (!testAssertion($baseUri, $jasserts->itemAt($j)->getNodeValue(), $result, $resultDocMap, $errorCode)) {
                return false;

            }

        }

        return true;

    }elseif ($assertName == "any-of") {
            $jasserts = getNodeFromXPath($assert, "*");
            //$jNode = $jasserts->itemAt(0)->getNodeValue();
            $jSize = $jasserts->size();
            for ($j = 0; $j < $jSize; $j++) {
                if (testAssertion($baseUri, $jasserts->itemAt($j)->getNodeValue(), $result, $resultDocMap, $errorCode)) {
                    return true;

                }

            }

            return true;

        }
        
            
    //    }
       
  // }
   error_log("testAssertion is false - not found assertion");
   return false;
    
}

function compareNodes($node1, $node2) {
    global $proc;
    global $xpathProcForCompareNodes;

    if($node1 == null or $node2 != null){
        return false;
    }
     if($node1->getChildCount() != $node1->getChildCount() and $node1->getNodeKind() != $node2->getNodeKind() and $node1->getAttributeCount() != $node2->getAttributeCount()) {
         return false;
     } else {

         if ($xpathProcForCompareNodes == NULL) {
             error_log("compareNodes Error: XPAth proc is null");
             return false;
         }
         $xpathProcForCompareNodes->clearParameters();
         $xpathProcForCompareNodes->clearProperties();

         $xpathProcForCompareNodes->setParameter("node1", $node1);
         $xpathProcForCompareNodes->setParameter("node2", $node2);
         $result = $xpathProcForCompareNodes->effectiveBooleanValue('fn:deep-equal($node1, $node2)');
         $xpathProcForCompareNodes->clearParameters();
         $xpathProcForCompareNodes->clearProperties();
         return $result;

     }




}


function run_test_case($testcase, $env, $path)
{
    global $proc;
    global $xsltproc;
    global $xpathProcForEnv;
    global $schemaValidator;
    global $pass;
    global $fail;
    global $notrun;
    global $run_assertion;
    $serializationDeclared = false;
    $assertsSerial = false;
    $errorCode  = null;
    $foundStylesheet = false;
    $xsltproc->clearParameters();
    $reultDocMap = null;
    $result = null;
    $errorTest = FALSE;
    $t_env = getNodeFromXPath($testcase, "./*:environment");

    $testDirValue = $proc->createAtomicValue(strval($path));
    $env_embedded_file = NULL;
    $t_env_ref = null;
    if($t_env != null) {

        $t_env_ref = $t_env->itemAt(0)->getNodeValue()->getAttributeValue("ref");
        if($t_env_ref == NULL) {
           $env_embedded_file = getSingleNodeFromXPath($t_env->itemAt(0)->getNodeValue(), "./source[@role='.']/@file");
        }
         error_log("TEST CASE t_env_ref = ".$t_env_ref);
        


    }
    $t_dep = getNodeFromXPath($testcase, "./*:dependencies");
    $checkDependency = check_dependency($t_dep);//check_dependency($testcase->dependencies);
    
    if ($checkDependency) {
        //error_log("TEST CASE checkpoint 1 - LLLLLl ");
        $testElem = getSingleNodeFromXPath($testcase, "./*:test");

         //error_log("TEST ELEMENT :".$testcase);
        $testStylesheet = null;

        if ($testElem != null) {
            //error_log("TEST CASE checkpoint 2 - LLLLLl ");
            $test = null;

            $asserts = getNodeFromXPath($testcase, "./*:result/child::*");

            $assertsSerial = effectiveBooleanValue($asserts, "exists(//descendant-or-self::*[assert-serialization or assert-serialization-error or serialization-matches])");

            //exists(/assert[s or x or p]) or  exists(//assert/child::*/s)


            if($t_env_ref!= null && array_key_exists($t_env_ref , $env)) {
                //error_log("envvvalue:". print_r($env[$t_env_ref . ""], TRUE));
                if(array_key_exists("stylesheet", $env[$t_env_ref . ""])) {
                    error_log("Entered stylesheet!");
                    $test =  $path. $env[$t_env_ref . ""]["stylesheet"];
                    $foundStylesheet = true;
                }

            }
            if(!$foundStylesheet) {
                $testStylesheet = getSingleNodeFromXPath($testElem->getNodeValue(), "./*:stylesheet");
                if($testStylesheet != null) {
                    $test = $path . $testStylesheet->getNodeValue()->getAttributeValue("file");
                    $foundStylesheet = true;
                }
            }

            $outputElem = getSingleNodeFromXPath($testElem->getNodeValue(), "./output");
            if($outputElem != null) {
                $serializeOpt = $path . $outputElem->getNodeValue()->getAttributeValue("serialize");
                if($serializeOpt == "yes") {
                    $serializationDeclared = true;
                    
                }
            }

            if ($foundStylesheet) {
                $resultSerialized = $serializationDeclared or $assertsSerial;
                
                //echo "Test case=" . $test;
                if ($test != null && file_exists($test)) {
                    try {

                        //if ($t_env != null) {
                                if($testElem->getNodeValue() == null) {
                                    error_log("$testElem->getNodeValue() is null");
                                }
                                $result = NULL;
                                $paramVar = getNodeFromXPath($testElem->getNodeValue(), "./*:param");

                                if($paramVar != null) {
                                    $paramCount = $paramVar->size();
                                    for($p = 0; $p < $paramCount;$p++) {
                                        $paramNode =  $paramVar->itemAt($p)->getNodeValue();
                                        $pValue = $paramNode->getAttributeValue("select");
                                        $pStatic = $paramNode->getAttributeValue("static");
                                        $pName = $paramNode->getAttributeValue("name");

                                        error_log("static parameters=". $pName. ", pValue=".$pValue);

                                        if($pStatic == "yes" and $pValue != null and $pValue != null) {
                                            $rValue = getNodeFromXPath(null, $pValue);
                                            error_log("rValue=". $rValue);
                                            if($rValue != null) {
                                                $xsltproc->setParameter($pName, $rValue);
                                            } else {
                                                error_log("Error: Could not set static parameter - cp0");
                                            }
                                        } else {
                                            error_log("Error: Could not set static parameter");
                                        }
                                    }
                                    
                                }

                               // error_log("before apply stylesheet:".$test);
                  
                                $executable = $xsltproc->compileFromFile($test);
                                $executable->setCaptureResultDocuments(true);
                                if($executable == null) {

                                    $fail++;
                                    if($xsltproc->getErrorMessage() == NULL) {
                                        return "FAIL - executable is NULL";
                                    } else {
                                        return "FAIL - ".$xsltproc->getErrorMessage();

                                    }
                                }

                                if($resultSerialized == True) {
                                    $executable->setSaveResultDocument(True);
                                } 


                       //error_log("envvvalue2:". print_r($env, TRUE));
                       // error_log("t_env_ref = ".$t_env_ref);
                        $input = null;
                        if($t_env_ref != null && array_key_exists($t_env_ref , $env)) {
                           // error_log("env[t_env_ref] value:" . print_r($env[$t_env_ref . ""], TRUE));
                            if(array_key_exists("sources", $env[$t_env_ref . ""])) {
                                if(array_key_exists(".file", $env[$t_env_ref . ""]["sources"])) {

                                    $input = $path. $env[$t_env_ref . ""]["sources"][".file"];
                                    $cNode = null;
                                    if(array_key_exists("validation", $env[$t_env_ref . ""]["sources"])) {
                                         $validation = $env[$t_env_ref . ""]["sources"]["validation"];
                                         if($schemaValidator != null && $validation != "skip") {
                                             error_log("using schemaValidator in parseXml!!");
                                             //$schemaValidator->
                                             $cNode = $proc->parseXmlFromFile($input, $schemaValidator);

                                         }

                                    }
                                    if($cNode == null) {
                                        $cNode = $proc->parseXmlFromFile($input);
                                    }
                                    $executable->setInitialMatchSelection($cNode);
                                    $executable->setGlobalContextItem($cNode);


                                } elseif (array_key_exists(".content", $env[$t_env_ref . ""]["sources"])) {
                                    $input = $env[$t_env_ref . ""]["sources"][".content"];
                                    //error_log(".content = ".$input);
                                    $cNode = null;
                                    if(array_key_exists("validation", $env[$t_env_ref . ""]["sources"])) {
                                         $validation = $env[$t_env_ref . ""]["sources"]["validation"];
                                         if($schemaValidator != null && $validation != "skip") {
                                             error_log("using schemaValidator in parseXml!!");
                                             $cNode = $proc->parseXmlFromString($input, $schemaValidator);

                                         }

                                    }
                                    if($cNode == null) {
                                        $cNode = $proc->parseXmlFromString($input);
                                    }

                                    if($cNode != null) {
                                        $executable->setInitialMatchSelection($cNode);
                                        $executable->setGlobalContextItem($cNode);

                                    }

                                }


                            }


                        } elseif ($env_embedded_file != NULL) {

                              $executable->setGlobalContextFromFile($env_embedded_file);
                              $executable->setInitialMatchSelectionAsFile($env_embedded_file);
                        }


                                //$init_templateV = getNodeFromXPath($testElem->getNodeValue(), "./initial-template");
                                if ($executable == NULL) {
                                    error_log("Executable is null on the following file: " . $test);
                                    $result = NULL;
                                    $errorCode = $xsltproc->getErrorCode();
                                    //return "FAIL Error:".$xsltproc->getErrorMessage();
                                } else {

                                    $init_template = getSingleNodeFromXPath($testElem->getNodeValue(), "./*:initial-template");
                                    
                                    $init_mode = getSingleNodeFromXPath($testElem->getNodeValue(), "./*:initial-mode");
                                    
                                    $nit_function = getSingleNodeFromXPath($testElem->getNodeValue(), "./*:initial-function");





                                    
                                    

                                    /*
                                     *
                                     *
                                     *         Optional<XdmNode> initialMode = testInput.select(child("initial-mode")).asOptionalNode();
                                             Optional<XdmNode> initialFunction = testInput.select(child("initial-function")).asOptionalNode();
                                             Optional<XdmNode> initialTemplate = testInput.select(child("initial-template")).asOptionalNode();

                                            
                                QName initialFunctionName = getQNameAttribute(xpath, testInput, path("initial-function", "@name"));

                                    TODO check for output@ file
                                     * 
                                     */
                                    if($t_env_ref != null) {
                                        if(array_key_exists("sources", $env[$t_env_ref . ""])) {
                                            if(array_key_exists(".file", $env[$t_env_ref . ""]["sources"])) {
                                                $input = $path . $env[$t_env_ref . ""]["sources"][".file"];    //TODO this needs a array access check
                                                error_log("file:" . $input);
                                                if ($input != null) {
                                                    error_log("input file: " . $input);
                                                    $executable->setGlobalContextFromFile($input);
                                                    $executable->setInitialMatchSelectionAsFile($input);
                                                }
                                            }
                                        }
                                    }

                                    if ($init_template != null ) {


                                        $init_node = $init_template->getNodeValue();

                                        error_log("init_node: ".$init_node->getAttributeValue("name"));
                                        $init_name = $init_node->getAttributeValue("name");

                                        if($init_name == "xsl:initial-template") {
                                            $init_name =  "{http://www.w3.org/1999/XSL/Transform}initial-template";
                                        }

                                        $result = $executable->callTemplateReturningValue($init_name);
                                        $resultDocMap = $executable->getResultDocuments();
                                    } elseif ($init_mode != null) {

                                        $initialModeName = $init_mode->getNodeValue()->getAttributeValue("name");
                                        $modeSelect = $init_mode->getNodeValue()->getAttributeValue("select");
                                        $executable->setInitialMode($initialModeName);

                                        if ($modeSelect != null) {
                                            $initialMatchSelection = getNodeFromXPath(null, $modeSelect."");
                                            $result = $executable->setInitialMatchSelection($initialMatchSelection);
                                        }

                                        $result = $executable->applyTemplatesReturningValue();  //$executable->transformToValue()

                                        if($result == null) {

                                            echo "Error:".$executable->getErrorMessage();
                                        }
                                        $resultDocMap = $executable->getResultDocuments();

                                    }else {


                                         error_log("Running applyTemplatesReturningValue");


                                        /*if($input == null) {
                                            $fail++;
                                            return FAIL;
                                        } */
                                        $result = $executable->applyTemplatesReturningValue();
                                        $resultDocMap = $executable->getResultDocuments();
                                    }
                                }

                                if ($result == NULL ) {
                                    $executable->checkForException();

                                }

                                if ($result == NULL && $executable->getErrorMessage() != NULL) {
                                    //$executable->checkForException();
                                    error_log('Error: ' . $executable->getErrorMessage() );
                                    /*$result = "";
                                     $fail++;
                                    return "FAIL";                                                */
                                }

                                //error_log("Result:". $result->size());
                                //error_log("Result-node value:". $result->itemAt(0)->getNodeValue());



                                /*if($testcase->attributes()->{'name'}=='import-0502b'){
                                     echo "result:".$result;
                                     echo "assert:".($asserts->asXML());
                                    exit('import-0502b');
                                }*/
                                if ($asserts == NULL) {
                                    error_log("NULL FOUND IN ASSERT1 = ". $testcase);
                                    if ($proc->exceptionOccurred()) {
                                        error_log(" assert exception: " . $proc->getErrorMessage());

                                    }
                                    $fail++;

                                    return "FAIL ASSERT";
                                }
                                if($run_assertion != null and $asserts->itemAt(0)->getNodeValue()->getLocalName() != $run_assertion) {
                                    $notrun++;
                                    return "Not Run";

                                }
                                $outcome = testAssertion($path, $asserts->itemAt(0)->getNodeValue(), $result, $resultDocMap, $errorCode);


                                if (!$outcome) {
                                    error_log("Assert:" . $outcome);
                                    error_log("Assert:" . ($asserts));
                                    //error_log( "OutCome:" . ($result));

                                    $fail++;
                                    return "FAIL";
                                }

                                $pass++;
                                return "PASS";


                           /* $xsltproc->exceptionClear();
                            $init_template = $testcase->{'test'}->{'initial-template'};
                            echo "Test data=" . $test;
                            $executable = $xsltproc->compileFromFile($test);
                            if ($executable == null) {
                                return "executable is NULL";
                            }
                            if ($init_template) {
                                $executable->setProperty('it', strval($testcase->{'test'}->{'initial-template'}->attributes()->{'name'}));
                            }
                            $result = $executable->transformToString();
                            if ($result == NULL) {


                                $result = "";

                                $result = "<out>";

                                $errC = $executable->getErrorCode();
                                if ($errC != NULL) {
                                    $result = $result . $errC . " ";
                                }
                                $result = $result . "</out>";
                            }



                        $asserts = $testcase->{'result'};
                        $xdmValue = $proc->parseString('' . $asserts->asXML());

                        if ($xdmValue == NULL) {
                            error_log(" assert exception: " . $proc->getErrorMessage(0));
                            return "NO ASSERTION";
                        }
                        $proc->setParameter('', 'assertion', $xdmValue);
                        $resulti = $proc->parseString('' . $result);
                        if ($resulti == NULL) {
                            return "NULL result";
                        }
                        $outcomeExecutable = $xsltproc->compileFromFile("TestOutcome.xsl");
                        $outcomeExecutable->setParameter('', 'result', $resulti);
                        $outcomeExecutable->setParameter('', 'testDir', $testDirValue);
                        //$outcomeExecutable->setProperty('it', 'main');
                        $outcome = $outcomeExecutable->callTemplateReturningString("main");
                        $proc->clear();
                        if ($outcome == NULL) {
                            echo "Assert:" . ($asserts->asXML());

                            $result = "<out>";

                            $errC = $proc->getErrorMessage();
                            if ($errC != NULL) {
                                $result = $result . $errC . " ";
                            }
                            $result = $result . "</out>";


                            echo "Error count: " . ($result);

                            return "false";
                        }
                        $proc->clear();
                        if ($outcome == FALSE) {
                            $resulti = '|| Assertion: ' . ($asserts->asXML()) . '|||| result: ' . $resulti . ' ||| ';
                            return 'assert-Error: ' . $outcome;
                        }

                        return $outcome . '';
                            */

                    } catch (Exception $ex) {
                        

                        $errMessage = $xsltproc->getErrorMessage();
                        if($errorCode == null) {
                            $errorCode = $xsltproc->getErrorCode();
                        }
                        //echo "exception cp12".$errMessage;

                        $asserts = getNodeFromXPath($testcase, "./*:result/child::*");
                        if($run_assertion != null and $asserts->itemAt(0)->getNodeValue()->getLocalName() != $run_assertion) {
                            $notrun++;
                            unset($asserts);
                            return "Not Run";

                        }
                        $resultDocMap = NULL;


                        $outcome = testAssertion($path, $asserts->itemAt(0)->getNodeValue(), $result, $resultDocMap, $errorCode);
                        if (!$outcome) {
                            $fail++;
                            unset($asserts);
                            unset($outcome);
                            return "Fail - error: " . $ex->getMessage();
                        } else {
                            $pass++;
                            unset($asserts);
                            return "PASS";
                        }
                    }

                } else {
                    $fail++;
                    return $test . " not found";
                }

            }


        }

    }
    $notrun++;
    return "Not Run";
}


$saxon_version = $proc->version();
echo "<a name='top'></a>";
echo "<h1>W3 XSLT 3.0 Test Suite</h1>
<h4>(PHP Test Harness. Version: 2.0. SaxonC PHP Extension, Saxon product version: $saxon_version)</h4>
<br/>";
$testFiles = test_set_files($catalog);
echo "<b>Test sets: " . count($testFiles) . "<b/> See <a href='#results'> Results here </a>";

echo "<table border='1'>
<tr>
  <th>Test Name </th>
  <th>File Name </th>
  <th> #Test cases </th>
</tr>";
$numberOfTests = 0;
foreach ($testFiles as $key => $test_set) {
    $testSet_xml = simplexml_load_file($path . $test_set);
    echo "<tr>";
    echo "<td><a href='#" . $key . "'>" . $key . "</a></td>";
    echo "<td>" . $test_set . "</td>";
    $numberOfTests += count($testSet_xml->{'test-case'});
    echo "<td>" . count($testSet_xml->{'test-case'}) . "</td>";
    echo "</tr>";
}
echo "</table>";

echo "<br/><br/><b>Number of tests: ".$numberOfTests."</b><br/>";

foreach ($testFiles as $key => $test_set) {
    echo "<div style='width:70%'><h4><a name='" . $key . "'>" . $key . "</a></h4></div><div style='width:30%;float:right'><a href='#top'>Back to top</a></div>";
    //if ($key == 'as') {   //copy-of
    echo "<b>".$path.$test_set."</b>";
    test_case($path . $test_set);
   // }
}
echo "<br/>";
//$test1 = $proc->xsltApplyStylesheet("cat.xml","test.xsl");


//echo $proc->transformToString();
echo "<a name='results'>";
echo "<b>Results</b><br/>";
echo "# Success:".$pass. " #Failures: ".$fail." Not run: ". $notrun;

//$proc->release();

?>
