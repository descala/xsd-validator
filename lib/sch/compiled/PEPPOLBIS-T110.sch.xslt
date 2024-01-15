<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                 xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                 xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                 xmlns:saxon="http://saxon.sf.net/"
                 xmlns:schold="http://www.ascc.net/xml/schematron"
                 xmlns:u="utils"
                 xmlns:ubl="urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2"
                 xmlns:xhtml="http://www.w3.org/1999/xhtml"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema"
                 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                 version="2.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
   <xsl:param name="archiveDirParameter"/>
   <xsl:param name="archiveNameParameter"/>
   <xsl:param name="fileNameParameter"/>
   <xsl:param name="fileDirParameter"/>
   <xsl:variable name="document-uri">
      <xsl:value-of select="document-uri(/)"/>
   </xsl:variable>
   <!--PHASES-->
   <!--PROLOG-->
   <xsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                method="xml"
                omit-xml-declaration="no"
                standalone="yes"
                indent="yes"/>
   <!--XSD TYPES FOR XSLT2-->
   <!--KEYS AND FUNCTIONS-->
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:gln"
              as="xs:boolean">
      <param name="val"/>
      <variable name="length" select="string-length($val) - 1"/>
      <variable name="digits"
                 select="reverse(for $i in string-to-codepoints(substring($val, 0, $length + 1)) return $i - 48)"/>
      <variable name="weightedSum"
                 select="sum(for $i in (0 to $length - 1) return $digits[$i + 1] * (1 + ((($i + 1) mod 2) * 2)))"/>
      <value-of select="(10 - ($weightedSum mod 10)) mod 10 = number(substring($val, $length + 1, 1))"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:slack"
              as="xs:boolean">
      <param name="exp" as="xs:decimal"/>
      <param name="val" as="xs:decimal"/>
      <param name="slack" as="xs:decimal"/>
      <value-of select="xs:decimal($exp + $slack) &gt;= $val and xs:decimal($exp - $slack) &lt;= $val"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:cat2str">
      <param name="cat"/>
      <value-of select="concat(normalize-space($cat/cbc:ID), '-', round(xs:decimal($cat/cbc:Percent) * 1000000))"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:mod11"
              as="xs:boolean">
      <param name="val"/>
      <variable name="length" select="string-length($val) - 1"/>
      <variable name="digits"
                 select="reverse(for $i in string-to-codepoints(substring($val, 0, $length + 1)) return $i - 48)"/>
      <variable name="weightedSum"
                 select="sum(for $i in (0 to $length - 1) return $digits[$i + 1] * (($i mod 6) + 2))"/>
      <value-of select="number($val) &gt; 0 and (11 - ($weightedSum mod 11)) mod 11 = number(substring($val, $length + 1, 1))"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:checkCodiceIPA"
              as="xs:boolean">
      <param name="arg" as="xs:string?"/>
      <variable name="allowed-characters">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789</variable>
      <sequence select="if ( (string-length(translate($arg, $allowed-characters, '')) = 0) and (string-length($arg) = 6) ) then true() else false()"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:addPIVA"
              as="xs:integer">
      <param name="arg" as="xs:string"/>
      <param name="pari" as="xs:integer"/>
      <variable name="tappo"
                 select="if (not($arg castable as xs:integer)) then 0 else 1"/>
      <variable name="mapper"
                 select="if ($tappo = 0) then 0 else                    ( if ($pari = 1)                     then ( xs:integer(substring('0246813579', ( xs:integer(substring($arg,1,1)) +1 ) ,1)) )                     else ( xs:integer(substring($arg,1,1) ) )                   )"/>
      <sequence select="if ($tappo = 0) then $mapper else ( xs:integer($mapper) + u:addPIVA(substring(xs:string($arg),2), (if($pari=0) then 1 else 0) ) )"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:checkCF"
              as="xs:boolean">
      <param name="arg" as="xs:string?"/>
      <sequence select="   if ( (string-length($arg) = 16) or (string-length($arg) = 11) )      then    (    if ((string-length($arg) = 16))     then    (     if (u:checkCF16($arg))      then     (      true()     )     else     (      false()     )    )    else    (     if(($arg castable as xs:integer)) then true() else false()       )   )   else   (    false()   )   "/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:checkCF16"
              as="xs:boolean">
      <param name="arg" as="xs:string?"/>
      <variable name="allowed-characters">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz</variable>
      <sequence select="     if (  (string-length(translate(substring($arg,1,6), $allowed-characters, '')) = 0) and         (substring($arg,7,2) castable as xs:integer) and        (string-length(translate(substring($arg,9,1), $allowed-characters, '')) = 0) and        (substring($arg,10,2) castable as xs:integer) and         (substring($arg,12,3) castable as xs:string) and        (substring($arg,15,1) castable as xs:integer) and         (string-length(translate(substring($arg,16,1), $allowed-characters, '')) = 0)      )      then true()     else false()     "/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:checkPIVA"
              as="xs:integer">
      <param name="arg" as="xs:string?"/>
      <sequence select="     if (not($arg castable as xs:integer))       then 1      else ( u:addPIVA($arg,xs:integer(0)) mod 10 )"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:checkPIVAseIT"
              as="xs:boolean">
      <param name="arg" as="xs:string"/>
      <variable name="paese" select="substring($arg,1,2)"/>
      <variable name="codice" select="substring($arg,3)"/>
      <sequence select="       if ( $paese = 'IT' or $paese = 'it' )    then    (     if ( ( string-length($codice) = 11 ) and ( if (u:checkPIVA($codice)!=0) then false() else true() ))     then      (      true()     )     else     (      false()     )    )    else    (     true()    )      "/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:mod97-0208"
              as="xs:boolean">
      <param name="val"/>
      <variable name="checkdigits" select="substring($val,9,2)"/>
      <variable name="calculated_digits"
                 select="xs:string(97 - (xs:integer(substring($val,1,8)) mod 97))"/>
      <value-of select="number($checkdigits) = number($calculated_digits)"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
              xmlns:xi="http://www.w3.org/2001/XInclude"
              name="u:abn"
              as="xs:boolean">
      <param name="val"/>
      <value-of select="( ((string-to-codepoints(substring($val,1,1)) - 49) * 10) + ((string-to-codepoints(substring($val,2,1)) - 48) * 1) + ((string-to-codepoints(substring($val,3,1)) - 48) * 3) + ((string-to-codepoints(substring($val,4,1)) - 48) * 5) + ((string-to-codepoints(substring($val,5,1)) - 48) * 7) + ((string-to-codepoints(substring($val,6,1)) - 48) * 9) + ((string-to-codepoints(substring($val,7,1)) - 48) * 11) + ((string-to-codepoints(substring($val,8,1)) - 48) * 13) + ((string-to-codepoints(substring($val,9,1)) - 48) * 15) + ((string-to-codepoints(substring($val,10,1)) - 48) * 17) + ((string-to-codepoints(substring($val,11,1)) - 48) * 19)) mod 89 = 0 "/>
   </function>
   <!--DEFAULT RULES-->
   <!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-select-full-path">
      <xsl:apply-templates select="." mode="schematron-get-full-path"/>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">
            <xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>*:</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>[namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="preceding"
                     select="count(preceding-sibling::*[local-name()=local-name(current())                                   and namespace-uri() = namespace-uri(current())])"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="@*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>@*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>' and namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-2-->
   <!--This mode can be used to generate prefixed XPath for humans-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-2">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-3-->
   <!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-3">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="parent::*">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: GENERATE-ID-FROM-PATH -->
   <xsl:template match="/" mode="generate-id-from-path"/>
   <xsl:template match="text()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
   </xsl:template>
   <xsl:template match="comment()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.@', name())"/>
   </xsl:template>
   <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
   </xsl:template>
   <!--MODE: GENERATE-ID-2 -->
   <xsl:template match="/" mode="generate-id-2">U</xsl:template>
   <xsl:template match="*" mode="generate-id-2" priority="2">
      <xsl:text>U</xsl:text>
      <xsl:number level="multiple" count="*"/>
   </xsl:template>
   <xsl:template match="node()" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>n</xsl:text>
      <xsl:number count="node()"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="string-length(local-name(.))"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="translate(name(),':','.')"/>
   </xsl:template>
   <!--Strip characters-->
   <xsl:template match="text()" priority="-1"/>
   <!--SCHEMA SETUP-->
   <xsl:template match="/">
      <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                               title="Rules for PEPPOL Order Agreement transaction 3.1"
                               schemaVersion="iso">
         <xsl:comment>
            <xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
         </xsl:comment>
         <svrl:ns-prefix-in-attribute-values uri="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                                              prefix="cbc"/>
         <svrl:ns-prefix-in-attribute-values uri="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                                              prefix="cac"/>
         <svrl:ns-prefix-in-attribute-values uri="urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2"
                                              prefix="ubl"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/2001/XMLSchema" prefix="xs"/>
         <svrl:ns-prefix-in-attribute-values uri="utils" prefix="u"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M18"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M19"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M20"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M21"/>
      </svrl:schematron-output>
   </xsl:template>
   <!--SCHEMATRON PATTERNS-->
   <svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Rules for PEPPOL Order Agreement transaction 3.1</svrl:text>
   <!--PATTERN -->
   <!--RULE -->
   <xsl:template match="//*[not(*) and not(normalize-space())]"
                  priority="1000"
                  mode="M18">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="//*[not(*) and not(normalize-space())]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-COMMON-R001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST not contain empty elements.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M18"/>
   <xsl:template match="@*|node()" priority="-2" mode="M18">
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <!--PATTERN -->
   <!--RULE -->
   <xsl:template match="/*" priority="1011" mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@*:schemaLocation)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@*:schemaLocation)">
               <xsl:attribute name="id">PEPPOL-COMMON-R003</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document SHOULD not contain schema location.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:IssueDate | cbc:DueDate | cbc:TaxPointDate | cbc:StartDate | cbc:EndDate | cbc:ActualDeliveryDate"
                  priority="1010"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:IssueDate | cbc:DueDate | cbc:TaxPointDate | cbc:StartDate | cbc:EndDate | cbc:ActualDeliveryDate"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(string(.) castable as xs:date) and (string-length(.) = 10)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(string(.) castable as xs:date) and (string-length(.) = 10)">
               <xsl:attribute name="id">PEPPOL-COMMON-R030</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>A date must be formatted YYYY-MM-DD.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0088'] | cac:PartyIdentification/cbc:ID[@schemeID = '0088'] | cbc:CompanyID[@schemeID = '0088']"
                  priority="1009"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0088'] | cac:PartyIdentification/cbc:ID[@schemeID = '0088'] | cbc:CompanyID[@schemeID = '0088']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="matches(normalize-space(), '^[0-9]+$') and u:gln(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="matches(normalize-space(), '^[0-9]+$') and u:gln(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R040</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>GLN must have a valid format according to GS1 rules.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0192'] | cac:PartyIdentification/cbc:ID[@schemeID = '0192'] | cbc:CompanyID[@schemeID = '0192']"
                  priority="1008"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0192'] | cac:PartyIdentification/cbc:ID[@schemeID = '0192'] | cbc:CompanyID[@schemeID = '0192']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="matches(normalize-space(), '^[0-9]{9}$') and u:mod11(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="matches(normalize-space(), '^[0-9]{9}$') and u:mod11(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R041</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Norwegian organization number MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0208'] | cac:PartyIdentification/cbc:ID[@schemeID = '0208'] | cbc:CompanyID[@schemeID = '0208']"
                  priority="1007"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0208'] | cac:PartyIdentification/cbc:ID[@schemeID = '0208'] | cbc:CompanyID[@schemeID = '0208']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="matches(normalize-space(), '^[0-9]{10}$') and u:mod97-0208(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="matches(normalize-space(), '^[0-9]{10}$') and u:mod97-0208(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R043</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Belgian enterprise number MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0201'] | cac:PartyIdentification/cbc:ID[@schemeID = '0201'] | cbc:CompanyID[@schemeID = '0201']"
                  priority="1006"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0201'] | cac:PartyIdentification/cbc:ID[@schemeID = '0201'] | cbc:CompanyID[@schemeID = '0201']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="u:checkCodiceIPA(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="u:checkCodiceIPA(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R044</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>IPA Code (Codice Univoco Unità Organizzativa) must be stated in the correct format</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0210'] | cac:PartyIdentification/cbc:ID[@schemeID = '0210'] | cbc:CompanyID[@schemeID = '0210']"
                  priority="1005"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0210'] | cac:PartyIdentification/cbc:ID[@schemeID = '0210'] | cbc:CompanyID[@schemeID = '0210']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="u:checkCF(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="u:checkCF(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R045</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax Code (Codice Fiscale) must be stated in the correct format</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '9907']"
                  priority="1004"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '9907']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="u:checkCF(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="u:checkCF(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R046</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax Code (Codice Fiscale) must be stated in the correct format</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0211'] | cac:PartyIdentification/cbc:ID[@schemeID = '0211'] | cbc:CompanyID[@schemeID = '0211']"
                  priority="1003"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0211'] | cac:PartyIdentification/cbc:ID[@schemeID = '0211'] | cbc:CompanyID[@schemeID = '0211']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="u:checkPIVAseIT(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="u:checkPIVAseIT(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R047</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Italian VAT Code (Partita Iva) must be stated in the correct format</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '9906']"
                  priority="1002"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '9906']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="u:checkPIVAseIT(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="u:checkPIVAseIT(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R048</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Italian VAT Code (Partita Iva) must be stated in the correct format</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0007'] | cac:PartyIdentification/cbc:ID[@schemeID = '0007'] | cbc:CompanyID[@schemeID = '0007']"
                  priority="1001"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0007'] | cac:PartyIdentification/cbc:ID[@schemeID = '0007'] | cbc:CompanyID[@schemeID = '0007']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(normalize-space()) = 10 and string(number(normalize-space())) != 'NaN'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="string-length(normalize-space()) = 10 and string(number(normalize-space())) != 'NaN'">
               <xsl:attribute name="id">PEPPOL-COMMON-R049</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Swedish organization number MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0151'] | cac:PartyIdentification/cbc:ID[@schemeID = '0151'] | cbc:CompanyID[@schemeID = '0151']"
                  priority="1000"
                  mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:EndpointID[@schemeID = '0151'] | cac:PartyIdentification/cbc:ID[@schemeID = '0151'] | cbc:CompanyID[@schemeID = '0151']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="matches(normalize-space(), '^[0-9]{11}$') and u:abn(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="matches(normalize-space(), '^[0-9]{11}$') and u:abn(normalize-space())">
               <xsl:attribute name="id">PEPPOL-COMMON-R050</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Australian Business Number (ABN) MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M19"/>
   <xsl:template match="@*|node()" priority="-2" mode="M19">
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--PATTERN -->
   <xsl:variable name="cleas"
                  select="tokenize('0002 0007 0009 0037 0060 0088 0096 0097 0106 0130 0135 0142 0151 0183 0184 0188 0190 0191 0192 0193 0195 0196 0198 0199 0200 0201 0202 0204 0208 0209 0210 0211 0212 0213 0215 0216 0221 0230 9901 9910 9913 9914 9915 9918 9919 9920 9922 9923 9924 9925 9926 9927 9928 9929 9930 9931 9932 9933 9934 9935 9936 9937 9938 9939 9940 9941 9942 9943 9944 9945 9946 9947 9948 9949 9950 9951 9952 9953 9957 9959', '\s')"/>
   <xsl:variable name="clISO4217"
                  select="tokenize('AED AFN ALL AMD ANG AOA ARS AUD AWG AZN BAM BBD BDT BGN BHD BIF BMD BND BOB BOV BRL BSD BTN BWP BYN BZD CAD CDF CHE CHF CHW CLF CLP CNY COP COU CRC CUC CUP CVE CZK DJF DKK DOP DZD EGP ERN ETB EUR FJD FKP GBP GEL GHS GIP GMD GNF GTQ GYD HKD HNL HRK HTG HUF IDR ILS INR IQD IRR ISK JMD JOD JPY KES KGS KHR KMF KPW KRW KWD KYD KZT LAK LBP LKR LRD LSL LYD MAD MDL MGA MKD MMK MNT MOP MRU MUR MVR MWK MXN MXV MYR MZN NAD NGN NIO NOK NPR NZD OMR PAB PEN PGK PHP PKR PLN PYG QAR RON RSD RUB RWF SAR SBD SCR SDG SEK SGD SHP SLL SOS SRD SSP STN SVC SYP SZL THB TJS TMT TND TOP TRY TTD TWD TZS UAH UGX USD USN UYI UYU UZS VEF VND VUV WST XAF XAG XAU XBA XBB XBC XBD XCD XDR XOF XPD XPF XPT XSU XTS XUA YER ZAR ZMW ZWL', '\s')"/>
   <xsl:variable name="clTrueFalse" select="tokenize('true false', '\s')"/>
   <xsl:variable name="clUNCL7161"
                  select="tokenize('AA AAA AAC AAD AAE AAF AAH AAI AAS AAT AAV AAY AAZ ABA ABB ABC ABD ABF ABK ABL ABN ABR ABS ABT ABU ACF ACG ACH ACI ACJ ACK ACL ACM ACS ADC ADE ADJ ADK ADL ADM ADN ADO ADP ADQ ADR ADT ADW ADY ADZ AEA AEB AEC AED AEF AEH AEI AEJ AEK AEL AEM AEN AEO AEP AES AET AEU AEV AEW AEX AEY AEZ AJ AU CA CAB CAD CAE CAF CAI CAJ CAK CAL CAM CAN CAO CAP CAQ CAR CAS CAT CAU CAV CAW CD CG CS CT DAB DAD DL EG EP ER FAA FAB FAC FC FH FI GAA HAA HD HH IAA IAB ID IF IR IS KO L1 LA LAA LAB LF MAE MI ML NAA OA PA PAA PC PL RAB RAC RAD RAF RE RF RH RV SA SAA SAD SAE SAI SG SH SM SU TAB TAC TT TV V1 V2 WH XAA YY ZZZ', '\s')"/>
   <xsl:variable name="clUNCL1001"
                  select="tokenize('1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 1999 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 481 482 483 484 485 486 487 488 489 490 491 493 494 495 496 497 498 499 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 550 551 552 553 554 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 610 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742 743 744 745 746 747 748 749 750 751 760 761 763 764 765 766 770 775 780 781 782 783 784 785 786 787 788 789 790 791 792 793 794 795 796 797 798 799 810 811 812 820 821 822 823 824 825 830 833 840 841 850 851 852 853 855 856 860 861 862 863 864 865 870 890 895 896 901 910 911 913 914 915 916 917 925 926 927 929 930 931 932 933 934 935 936 937 938 940 941 950 951 952 953 954 955 960 961 962 963 964 965 966 970 971 972 974 975 976 977 978 979 990 991 995 996 998', '\s')"/>
   <xsl:variable name="clUNCL7143"
                  select="tokenize('AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ CC CG CL CR CV DR DW EC EF EMD EN FS GB GN GS HS IB IN IS IT IZ MA MF MN MP NB ON PD PL PO PV QS RC RN RU RY SA SG SK SN SRS SRT SRU SRV SRW SRX SRY SRZ SS SSA SSB SSC SSD SSE SSF SSG SSH SSI SSJ SSK SSL SSM SSN SSO SSP SSQ SSR SSS SST SSU SSV SSW SSX SSY SSZ ST STA STB STC STD STE STF STG STH STI STJ STK STL STM STN STO STP STQ STR STS STT STU STV STW STX STY STZ SUA SUB SUC SUD SUE SUF SUG SUH SUI SUJ SUK SUL SUM TG TSN TSO TSP TSQ TSR TSS TST TSU UA UP VN VP VS VX ZZZ', '\s')"/>
   <xsl:variable name="clUNECERec20"
                  select="tokenize('10 11 13 14 15 20 21 22 23 24 25 27 28 33 34 35 37 38 40 41 56 57 58 59 60 61 74 77 80 81 85 87 89 91 1I 2A 2B 2C 2G 2H 2I 2J 2K 2L 2M 2N 2P 2Q 2R 2U 2X 2Y 2Z 3B 3C 4C 4G 4H 4K 4L 4M 4N 4O 4P 4Q 4R 4T 4U 4W 4X 5A 5B 5E 5J A10 A11 A12 A13 A14 A15 A16 A17 A18 A19 A2 A20 A21 A22 A23 A24 A26 A27 A28 A29 A3 A30 A31 A32 A33 A34 A35 A36 A37 A38 A39 A4 A40 A41 A42 A43 A44 A45 A47 A48 A49 A5 A53 A54 A55 A56 A59 A6 A68 A69 A7 A70 A71 A73 A74 A75 A76 A8 A84 A85 A86 A87 A88 A89 A9 A90 A91 A93 A94 A95 A96 A97 A98 A99 AA AB ACR ACT AD AE AH AI AK AL AMH AMP ANN APZ AQ AS ASM ASU ATM AWG AY AZ B1 B10 B11 B12 B13 B14 B15 B16 B17 B18 B19 B20 B21 B22 B23 B24 B25 B26 B27 B28 B29 B3 B30 B31 B32 B33 B34 B35 B4 B41 B42 B43 B44 B45 B46 B47 B48 B49 B50 B52 B53 B54 B55 B56 B57 B58 B59 B60 B61 B62 B63 B64 B66 B67 B68 B69 B7 B70 B71 B72 B73 B74 B75 B76 B77 B78 B79 B8 B80 B81 B82 B83 B84 B85 B86 B87 B88 B89 B90 B91 B92 B93 B94 B95 B96 B97 B98 B99 BAR BB BFT BHP BIL BLD BLL BP BPM BQL BTU BUA BUI C0 C10 C11 C12 C13 C14 C15 C16 C17 C18 C19 C20 C21 C22 C23 C24 C25 C26 C27 C28 C29 C3 C30 C31 C32 C33 C34 C35 C36 C37 C38 C39 C40 C41 C42 C43 C44 C45 C46 C47 C48 C49 C50 C51 C52 C53 C54 C55 C56 C57 C58 C59 C60 C61 C62 C63 C64 C65 C66 C67 C68 C69 C7 C70 C71 C72 C73 C74 C75 C76 C78 C79 C8 C80 C81 C82 C83 C84 C85 C86 C87 C88 C89 C9 C90 C91 C92 C93 C94 C95 C96 C97 C99 CCT CDL CEL CEN CG CGM CKG CLF CLT CMK CMQ CMT CNP CNT COU CTG CTM CTN CUR CWA CWI D03 D04 D1 D10 D11 D12 D13 D15 D16 D17 D18 D19 D2 D20 D21 D22 D23 D24 D25 D26 D27 D29 D30 D31 D32 D33 D34 D36 D41 D42 D43 D44 D45 D46 D47 D48 D49 D5 D50 D51 D52 D53 D54 D55 D56 D57 D58 D59 D6 D60 D61 D62 D63 D65 D68 D69 D73 D74 D77 D78 D80 D81 D82 D83 D85 D86 D87 D88 D89 D91 D93 D94 D95 DAA DAD DAY DB DBM DBW DD DEC DG DJ DLT DMA DMK DMO DMQ DMT DN DPC DPR DPT DRA DRI DRL DT DTN DWT DZN DZP E01 E07 E08 E09 E10 E12 E14 E15 E16 E17 E18 E19 E20 E21 E22 E23 E25 E27 E28 E30 E31 E32 E33 E34 E35 E36 E37 E38 E39 E4 E40 E41 E42 E43 E44 E45 E46 E47 E48 E49 E50 E51 E52 E53 E54 E55 E56 E57 E58 E59 E60 E61 E62 E63 E64 E65 E66 E67 E68 E69 E70 E71 E72 E73 E74 E75 E76 E77 E78 E79 E80 E81 E82 E83 E84 E85 E86 E87 E88 E89 E90 E91 E92 E93 E94 E95 E96 E97 E98 E99 EA EB EQ F01 F02 F03 F04 F05 F06 F07 F08 F10 F11 F12 F13 F14 F15 F16 F17 F18 F19 F20 F21 F22 F23 F24 F25 F26 F27 F28 F29 F30 F31 F32 F33 F34 F35 F36 F37 F38 F39 F40 F41 F42 F43 F44 F45 F46 F47 F48 F49 F50 F51 F52 F53 F54 F55 F56 F57 F58 F59 F60 F61 F62 F63 F64 F65 F66 F67 F68 F69 F70 F71 F72 F73 F74 F75 F76 F77 F78 F79 F80 F81 F82 F83 F84 F85 F86 F87 F88 F89 F90 F91 F92 F93 F94 F95 F96 F97 F98 F99 FAH FAR FBM FC FF FH FIT FL FNU FOT FP FR FS FTK FTQ G01 G04 G05 G06 G08 G09 G10 G11 G12 G13 G14 G15 G16 G17 G18 G19 G2 G20 G21 G23 G24 G25 G26 G27 G28 G29 G3 G30 G31 G32 G33 G34 G35 G36 G37 G38 G39 G40 G41 G42 G43 G44 G45 G46 G47 G48 G49 G50 G51 G52 G53 G54 G55 G56 G57 G58 G59 G60 G61 G62 G63 G64 G65 G66 G67 G68 G69 G70 G71 G72 G73 G74 G75 G76 G77 G78 G79 G80 G81 G82 G83 G84 G85 G86 G87 G88 G89 G90 G91 G92 G93 G94 G95 G96 G97 G98 G99 GB GBQ GDW GE GF GFI GGR GIA GIC GII GIP GJ GL GLD GLI GLL GM GO GP GQ GRM GRN GRO GV GWH H03 H04 H05 H06 H07 H08 H09 H10 H11 H12 H13 H14 H15 H16 H18 H19 H20 H21 H22 H23 H24 H25 H26 H27 H28 H29 H30 H31 H32 H33 H34 H35 H36 H37 H38 H39 H40 H41 H42 H43 H44 H45 H46 H47 H48 H49 H50 H51 H52 H53 H54 H55 H56 H57 H58 H59 H60 H61 H62 H63 H64 H65 H66 H67 H68 H69 H70 H71 H72 H73 H74 H75 H76 H77 H79 H80 H81 H82 H83 H84 H85 H87 H88 H89 H90 H91 H92 H93 H94 H95 H96 H98 H99 HA HAD HBA HBX HC HDW HEA HGM HH HIU HKM HLT HM HMO HMQ HMT HPA HTZ HUR IA IE INH INK INQ ISD IU IUG IV J10 J12 J13 J14 J15 J16 J17 J18 J19 J2 J20 J21 J22 J23 J24 J25 J26 J27 J28 J29 J30 J31 J32 J33 J34 J35 J36 J38 J39 J40 J41 J42 J43 J44 J45 J46 J47 J48 J49 J50 J51 J52 J53 J54 J55 J56 J57 J58 J59 J60 J61 J62 J63 J64 J65 J66 J67 J68 J69 J70 J71 J72 J73 J74 J75 J76 J78 J79 J81 J82 J83 J84 J85 J87 J90 J91 J92 J93 J95 J96 J97 J98 J99 JE JK JM JNT JOU JPS JWL K1 K10 K11 K12 K13 K14 K15 K16 K17 K18 K19 K2 K20 K21 K22 K23 K26 K27 K28 K3 K30 K31 K32 K33 K34 K35 K36 K37 K38 K39 K40 K41 K42 K43 K45 K46 K47 K48 K49 K50 K51 K52 K53 K54 K55 K58 K59 K6 K60 K61 K62 K63 K64 K65 K66 K67 K68 K69 K70 K71 K73 K74 K75 K76 K77 K78 K79 K80 K81 K82 K83 K84 K85 K86 K87 K88 K89 K90 K91 K92 K93 K94 K95 K96 K97 K98 K99 KA KAT KB KBA KCC KDW KEL KGM KGS KHY KHZ KI KIC KIP KJ KJO KL KLK KLX KMA KMH KMK KMQ KMT KNI KNM KNS KNT KO KPA KPH KPO KPP KR KSD KSH KT KTN KUR KVA KVR KVT KW KWH KWN KWO KWS KWT KWY KX L10 L11 L12 L13 L14 L15 L16 L17 L18 L19 L2 L20 L21 L23 L24 L25 L26 L27 L28 L29 L30 L31 L32 L33 L34 L35 L36 L37 L38 L39 L40 L41 L42 L43 L44 L45 L46 L47 L48 L49 L50 L51 L52 L53 L54 L55 L56 L57 L58 L59 L60 L63 L64 L65 L66 L67 L68 L69 L70 L71 L72 L73 L74 L75 L76 L77 L78 L79 L80 L81 L82 L83 L84 L85 L86 L87 L88 L89 L90 L91 L92 L93 L94 L95 L96 L98 L99 LA LAC LBR LBT LD LEF LF LH LK LM LN LO LP LPA LR LS LTN LTR LUB LUM LUX LY M1 M10 M11 M12 M13 M14 M15 M16 M17 M18 M19 M20 M21 M22 M23 M24 M25 M26 M27 M29 M30 M31 M32 M33 M34 M35 M36 M37 M38 M39 M4 M40 M41 M42 M43 M44 M45 M46 M47 M48 M49 M5 M50 M51 M52 M53 M55 M56 M57 M58 M59 M60 M61 M62 M63 M64 M65 M66 M67 M68 M69 M7 M70 M71 M72 M73 M74 M75 M76 M77 M78 M79 M80 M81 M82 M83 M84 M85 M86 M87 M88 M89 M9 M90 M91 M92 M93 M94 M95 M96 M97 M98 M99 MAH MAL MAM MAR MAW MBE MBF MBR MC MCU MD MGM MHZ MIK MIL MIN MIO MIU MKD MKM MKW MLD MLT MMK MMQ MMT MND MNJ MON MPA MQD MQH MQM MQS MQW MRD MRM MRW MSK MTK MTQ MTR MTS MTZ MVA MWH N1 N10 N11 N12 N13 N14 N15 N16 N17 N18 N19 N20 N21 N22 N23 N24 N25 N26 N27 N28 N29 N3 N30 N31 N32 N33 N34 N35 N36 N37 N38 N39 N40 N41 N42 N43 N44 N45 N46 N47 N48 N49 N50 N51 N52 N53 N54 N55 N56 N57 N58 N59 N60 N61 N62 N63 N64 N65 N66 N67 N68 N69 N70 N71 N72 N73 N74 N75 N76 N77 N78 N79 N80 N81 N82 N83 N84 N85 N86 N87 N88 N89 N90 N91 N92 N93 N94 N95 N96 N97 N98 N99 NA NAR NCL NEW NF NIL NIU NL NM3 NMI NMP NPT NT NTU NU NX OA ODE ODG ODK ODM OHM ON ONZ OPM OT OZA OZI P1 P10 P11 P12 P13 P14 P15 P16 P17 P18 P19 P2 P20 P21 P22 P23 P24 P25 P26 P27 P28 P29 P30 P31 P32 P33 P34 P35 P36 P37 P38 P39 P40 P41 P42 P43 P44 P45 P46 P47 P48 P49 P5 P50 P51 P52 P53 P54 P55 P56 P57 P58 P59 P60 P61 P62 P63 P64 P65 P66 P67 P68 P69 P70 P71 P72 P73 P74 P75 P76 P77 P78 P79 P80 P81 P82 P83 P84 P85 P86 P87 P88 P89 P90 P91 P92 P93 P94 P95 P96 P97 P98 P99 PAL PD PFL PGL PI PLA PO PQ PR PS PTD PTI PTL PTN Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21 Q22 Q23 Q24 Q25 Q26 Q27 Q28 Q29 Q30 Q31 Q32 Q33 Q34 Q35 Q36 Q37 Q38 Q39 Q40 Q41 Q42 Q3 QA QAN QB QR QTD QTI QTL QTR R1 R9 RH RM ROM RP RPM RPS RT S3 S4 SAN SCO SCR SEC SET SG SIE SM3 SMI SQ SQR SR STC STI STK STL STN STW SW SX SYR T0 T3 TAH TAN TI TIC TIP TKM TMS TNE TP TPI TPR TQD TRL TST TTS U1 U2 UB UC VA VLT VP W2 WA WB WCD WE WEB WEE WG WHR WM WSD WTT X1 YDK YDQ YRD Z11 Z9 ZP ZZ X1A X1B X1D X1F X1G X1W X2C X3A X3H X43 X44 X4A X4B X4C X4D X4F X4G X4H X5H X5L X5M X6H X6P X7A X7B X8A X8B X8C XAA XAB XAC XAD XAE XAF XAG XAH XAI XAJ XAL XAM XAP XAT XAV XB4 XBA XBB XBC XBD XBE XBF XBG XBH XBI XBJ XBK XBL XBM XBN XBO XBP XBQ XBR XBS XBT XBU XBV XBW XBX XBY XBZ XCA XCB XCC XCD XCE XCF XCG XCH XCI XCJ XCK XCL XCM XCN XCO XCP XCQ XCR XCS XCT XCU XCV XCW XCX XCY XCZ XDA XDB XDC XDG XDH XDI XDJ XDK XDL XDM XDN XDP XDR XDS XDT XDU XDV XDW XDX XDY XEC XED XEE XEF XEG XEH XEI XEN XFB XFC XFD XFE XFI XFL XFO XFP XFR XFT XFW XFX XGB XGI XGL XGR XGU XGY XGZ XHA XHB XHC XHG XHN XHR XIA XIB XIC XID XIE XIF XIG XIH XIK XIL XIN XIZ XJB XJC XJG XJR XJT XJY XKG XKI XLE XLG XLT XLU XLV XLZ XMA XMB XMC XME XMR XMS XMT XMW XMX XNA XNE XNF XNG XNS XNT XNU XNV XO1 XO2 XO3 XO4 XO5 XO6 XO7 XO8 XO9 XOA XOB XOC XOD XOE XOF XOG XOH XOI XOK XOJ XOL XOM XON XOP XOQ XOR XOS XOV XOW XOT XOU XOX XOY XOZ XP1 XP2 XP3 XP4 XPA XPB XPC XPD XPE XPF XPG XPH XPI XPJ XPK XPL XPN XPO XPP XPR XPT XPU XPV XPX XPY XPZ XQA XQB XQC XQD XQF XQG XQH XQJ XQK XQL XQM XQN XQP XQQ XQR XQS XRD XRG XRJ XRK XRL XRO XRT XRZ XSA XSB XSC XSD XSE XSH XSI XSK XSL XSM XSO XSP XSS XST XSU XSV XSW XSX XSY XSZ XT1 XTB XTC XTD XTE XTG XTI XTK XTL XTN XTO XTR XTS XTT XTU XTV XTW XTY XTZ XUC XUN XVA XVG XVI XVK XVL XVO XVP XVQ XVN XVR XVS XVY XWA XWB XWC XWD XWF XWG XWH XWJ XWK XWL XWM XWN XWP XWQ XWR XWS XWT XWU XWV XWW XWX XWY XWZ XXA XXB XXC XXD XXF XXG XXH XXJ XXK XYA XYB XYC XYD XYF XYG XYH XYJ XYK XYL XYM XYN XYP XYQ XYR XYS XYT XYV XYW XYX XYY XYZ XZA XZB XZC XZD XZF XZG XZH XZJ XZK XZL XZM XZN XZP XZQ XZR XZS XZT XZU XZV XZW XZX XZY XZZ', '\s')"/>
   <xsl:variable name="clISO3166"
                  select="tokenize('AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW 1A XI', '\s')"/>
   <xsl:variable name="clImage"
                  select="tokenize('PRODUCT_IMAGE TRADE_ITEM_DESCRIPTION', '\s')"/>
   <xsl:variable name="clICD"
                  select="tokenize('0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 0020 0021 0022 0023 0024 0025 0026 0027 0028 0029 0030 0031 0032 0033 0034 0035 0036 0037 0038 0039 0040 0041 0042 0043 0044 0045 0046 0047 0048 0049 0050 0051 0052 0053 0054 0055 0056 0057 0058 0059 0060 0061 0062 0063 0064 0065 0066 0067 0068 0069 0070 0071 0072 0073 0074 0075 0076 0077 0078 0079 0080 0081 0082 0083 0084 0085 0086 0087 0088 0089 0090 0091 0093 0094 0095 0096 0097 0098 0099 0100 0101 0102 0104 0105 0106 0107 0108 0109 0110 0111 0112 0113 0114 0115 0116 0117 0118 0119 0120 0121 0122 0123 0124 0125 0126 0127 0128 0129 0130 0131 0132 0133 0134 0135 0136 0137 0138 0139 0140 0141 0142 0143 0144 0145 0146 0147 0148 0149 0150 0151 0152 0153 0154 0155 0156 0157 0158 0159 0160 0161 0162 0163 0164 0165 0166 0167 0168 0169 0170 0171 0172 0173 0174 0175 0176 0177 0178 0179 0180 0183 0184 0185 0186 0187 0188 0189 0190 0191 0192 0193 0194 0195 0196 0197 0198 0199 0200 0201 0202 0203 0204 0205 0206 0207 0208 0209 0210 0211 0212 0213 0214 0215 0216 0217 0218 0219 0220 0221 0222 0223 0224 0225 0226 0227 0228 0229 0230', '\s')"/>
   <xsl:variable name="clMimeCode"
                  select="tokenize('application/pdf image/png image/jpeg image/tiff application/acad application/dwg drawing/dwg application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.oasis.opendocument.spreadsheet', '\s')"/>
   <xsl:variable name="clUNCL5189"
                  select="tokenize('41 42 60 62 63 64 65 66 67 68 70 71 88 95 100 102 103 104 105', '\s')"/>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse" priority="1270" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="/ubl:OrderResponse"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:CustomizationID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CustomizationID">
               <xsl:attribute name="id">PEPPOL-T110-B00101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CustomizationID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ProfileID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ProfileID">
               <xsl:attribute name="id">PEPPOL-T110-B00102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ProfileID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B00103</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IssueDate"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IssueDate">
               <xsl:attribute name="id">PEPPOL-T110-B00104</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:IssueDate' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:OrderReference"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:OrderReference">
               <xsl:attribute name="id">PEPPOL-T110-B00105</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:OrderReference' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:SellerSupplierParty"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:SellerSupplierParty">
               <xsl:attribute name="id">PEPPOL-T110-B00106</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:SellerSupplierParty' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:BuyerCustomerParty"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:BuyerCustomerParty">
               <xsl:attribute name="id">PEPPOL-T110-B00107</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:BuyerCustomerParty' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:OrderLine"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:OrderLine">
               <xsl:attribute name="id">PEPPOL-T110-B00108</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:OrderLine' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@*:schemaLocation)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@*:schemaLocation)">
               <xsl:attribute name="id">PEPPOL-T110-B00109</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST not contain schema location.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:CustomizationID"
                  priority="1269"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:CustomizationID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:ProfileID" priority="1268" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:ProfileID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:bis:order_agreement:3'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:bis:order_agreement:3'">
               <xsl:attribute name="id">PEPPOL-T110-B00301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ProfileID' MUST contain value 'urn:fdc:peppol.eu:poacc:bis:order_agreement:3'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:ID" priority="1267" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:SalesOrderID"
                  priority="1266"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:SalesOrderID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:IssueDate" priority="1265" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:IssueDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:IssueTime" priority="1264" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:IssueTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:Note" priority="1263" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:Note"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:DocumentCurrencyCode"
                  priority="1262"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:DocumentCurrencyCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO4217 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clISO4217 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B00901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cbc:CustomerReference"
                  priority="1261"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cbc:CustomerReference"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderReference"
                  priority="1260"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B01101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderReference/cbc:ID"
                  priority="1259"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderReference/*"
                  priority="1258"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B01102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorDocumentReference"
                  priority="1257"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorDocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B01301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorDocumentReference/cbc:ID"
                  priority="1256"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorDocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorDocumentReference/*"
                  priority="1255"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorDocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B01302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference"
                  priority="1254"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B01501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cbc:ID"
                  priority="1253"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cbc:DocumentType"
                  priority="1252"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cbc:DocumentType"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment"
                  priority="1251"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"
                  priority="1250"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@mimeCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@mimeCode">
               <xsl:attribute name="id">PEPPOL-T110-B01901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'mimeCode' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@mimeCode) or (some $code in $clMimeCode satisfies $code = @mimeCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@mimeCode) or (some $code in $clMimeCode satisfies $code = @mimeCode)">
               <xsl:attribute name="id">PEPPOL-T110-B01902</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Mime code (IANA Subset)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@filename"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@filename">
               <xsl:attribute name="id">PEPPOL-T110-B01903</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'filename' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference"
                  priority="1249"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:URI"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:URI">
               <xsl:attribute name="id">PEPPOL-T110-B02201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:URI' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"
                  priority="1248"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/*"
                  priority="1247"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B02202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/*"
                  priority="1246"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/cac:Attachment/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B01801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AdditionalDocumentReference/*"
                  priority="1245"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AdditionalDocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B01502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Contract" priority="1244" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Contract"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B02401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Contract/cbc:ID"
                  priority="1243"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Contract/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Contract/*"
                  priority="1242"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Contract/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B02402</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty"
                  priority="1241"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Party"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Party">
               <xsl:attribute name="id">PEPPOL-T110-B02601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Party' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party"
                  priority="1240"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:EndpointID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:EndpointID">
               <xsl:attribute name="id">PEPPOL-T110-B02701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:EndpointID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:PartyLegalEntity"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:PartyLegalEntity">
               <xsl:attribute name="id">PEPPOL-T110-B02702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:PartyLegalEntity' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID"
                  priority="1239"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="id">PEPPOL-T110-B02801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'schemeID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $cleas satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $cleas satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B02802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Electronic Address Scheme (EAS)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification"
                  priority="1238"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B03001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"
                  priority="1237"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B03101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress"
                  priority="1236"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T110-B03301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Country' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName"
                  priority="1235"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"
                  priority="1234"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName"
                  priority="1233"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone"
                  priority="1232"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
                  priority="1231"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine"
                  priority="1230"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"
                  priority="1229"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country"
                  priority="1228"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T110-B04101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:IdentificationCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
                  priority="1227"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B04201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Country codes (ISO 3166-1:Alpha2)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/*"
                  priority="1226"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B04102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/*"
                  priority="1225"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B03302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity"
                  priority="1224"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:RegistrationName"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:RegistrationName">
               <xsl:attribute name="id">PEPPOL-T110-B04301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:RegistrationName' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"
                  priority="1223"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"
                  priority="1222"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B04501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/*"
                  priority="1221"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B04302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact"
                  priority="1220"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Name"
                  priority="1219"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Telephone"
                  priority="1218"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Telephone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"
                  priority="1217"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/*"
                  priority="1216"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/cac:Contact/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B04701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/*"
                  priority="1215"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B02703</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:SellerSupplierParty/*"
                  priority="1214"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:SellerSupplierParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B02602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty"
                  priority="1213"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Party"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Party">
               <xsl:attribute name="id">PEPPOL-T110-B05101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Party' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party"
                  priority="1212"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:EndpointID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:EndpointID">
               <xsl:attribute name="id">PEPPOL-T110-B05201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:EndpointID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:PartyLegalEntity"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:PartyLegalEntity">
               <xsl:attribute name="id">PEPPOL-T110-B05202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:PartyLegalEntity' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID"
                  priority="1211"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="id">PEPPOL-T110-B05301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'schemeID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $cleas satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $cleas satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B05302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Electronic Address Scheme (EAS)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification"
                  priority="1210"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B05501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
                  priority="1209"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B05601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress"
                  priority="1208"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T110-B05801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Country' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName"
                  priority="1207"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"
                  priority="1206"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName"
                  priority="1205"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone"
                  priority="1204"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
                  priority="1203"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine"
                  priority="1202"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"
                  priority="1201"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country"
                  priority="1200"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T110-B06601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:IdentificationCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
                  priority="1199"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B06701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Country codes (ISO 3166-1:Alpha2)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/*"
                  priority="1198"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B06602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/*"
                  priority="1197"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B05802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity"
                  priority="1196"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:RegistrationName"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:RegistrationName">
               <xsl:attribute name="id">PEPPOL-T110-B06801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:RegistrationName' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"
                  priority="1195"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"
                  priority="1194"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B07001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/*"
                  priority="1193"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B06802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/*"
                  priority="1192"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B05203</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact"
                  priority="1191"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:Name"
                  priority="1190"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:Telephone"
                  priority="1189"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:Telephone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:ElectronicMail"
                  priority="1188"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/cbc:ElectronicMail"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/*"
                  priority="1187"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/cac:DeliveryContact/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B07201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:BuyerCustomerParty/*"
                  priority="1186"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:BuyerCustomerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B05102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty"
                  priority="1185"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party"
                  priority="1184"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification"
                  priority="1183"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B07801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
                  priority="1182"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B07901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyName"
                  priority="1181"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B08101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyName/cbc:Name"
                  priority="1180"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/*"
                  priority="1179"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B07701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OriginatorCustomerParty/*"
                  priority="1178"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OriginatorCustomerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B07601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty"
                  priority="1177"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party"
                  priority="1176"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification"
                  priority="1175"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B08501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
                  priority="1174"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B08601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyName"
                  priority="1173"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B08801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name"
                  priority="1172"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/*"
                  priority="1171"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B08401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AccountingCustomerParty/*"
                  priority="1170"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AccountingCustomerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B08301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery" priority="1169" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod"
                  priority="1168"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:StartDate"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:StartDate">
               <xsl:attribute name="id">PEPPOL-T110-B09101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:StartDate' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate"
                  priority="1167"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartTime"
                  priority="1166"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndDate"
                  priority="1165"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndTime"
                  priority="1164"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/*"
                  priority="1163"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B09102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty"
                  priority="1162"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyIdentification"
                  priority="1161"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B09701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyIdentification/cbc:ID"
                  priority="1160"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B09801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyName"
                  priority="1159"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B10001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyName/cbc:Name"
                  priority="1158"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress"
                  priority="1157"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:StreetName"
                  priority="1156"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:AdditionalStreetName"
                  priority="1155"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:CityName"
                  priority="1154"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:PostalZone"
                  priority="1153"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:CountrySubentity"
                  priority="1152"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:AddressLine"
                  priority="1151"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:AddressLine/cbc:Line"
                  priority="1150"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country"
                  priority="1149"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T110-B11001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:IdentificationCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
                  priority="1148"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B11101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Country codes (ISO 3166-1:Alpha2)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country/*"
                  priority="1147"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B11002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/*"
                  priority="1146"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/cac:PostalAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B10201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/*"
                  priority="1145"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/cac:DeliveryParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B09601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:Delivery/*"
                  priority="1144"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:Delivery/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B09001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms"
                  priority="1143"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cbc:ID"
                  priority="1142"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cbc:SpecialTerms"
                  priority="1141"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cbc:SpecialTerms"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation"
                  priority="1140"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B11501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cbc:ID"
                  priority="1139"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address"
                  priority="1138"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:StreetName"
                  priority="1137"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:AdditionalStreetName"
                  priority="1136"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:CityName"
                  priority="1135"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:PostalZone"
                  priority="1134"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:CountrySubentity"
                  priority="1133"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:AddressLine"
                  priority="1132"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"
                  priority="1131"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country"
                  priority="1130"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T110-B12501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:IdentificationCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country/cbc:IdentificationCode"
                  priority="1129"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B12601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Country codes (ISO 3166-1:Alpha2)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country/*"
                  priority="1128"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B12502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/*"
                  priority="1127"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/cac:Address/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B11701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/*"
                  priority="1126"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/cac:DeliveryLocation/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B11502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:DeliveryTerms/*"
                  priority="1125"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:DeliveryTerms/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B11201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge"
                  priority="1124"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ChargeIndicator"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ChargeIndicator">
               <xsl:attribute name="id">PEPPOL-T110-B12701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ChargeIndicator' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Amount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Amount">
               <xsl:attribute name="id">PEPPOL-T110-B12702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Amount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxCategory"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxCategory">
               <xsl:attribute name="id">PEPPOL-T110-B12703</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:TaxCategory' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:ChargeIndicator"
                  priority="1123"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:ChargeIndicator"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clTrueFalse satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clTrueFalse satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B12801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Boolean indicator (openPEPPOL)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:AllowanceChargeReasonCode"
                  priority="1122"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:AllowanceChargeReasonCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clUNCL5189 satisfies $code = normalize-space(text())) or (some $code in $clUNCL7161 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clUNCL5189 satisfies $code = normalize-space(text())) or (some $code in $clUNCL7161 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B12901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Allowance reason codes (UNCL5189 subset)' or 'Charge reason code (UNCL7161)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:AllowanceChargeReason"
                  priority="1121"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:AllowanceChargeReason"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:MultiplierFactorNumeric"
                  priority="1120"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:MultiplierFactorNumeric"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:Amount"
                  priority="1119"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:Amount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B13201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B13202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cbc:BaseAmount"
                  priority="1118"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cbc:BaseAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B13401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B13402</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory"
                  priority="1117"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B13601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxScheme"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxScheme">
               <xsl:attribute name="id">PEPPOL-T110-B13602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:TaxScheme' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cbc:ID"
                  priority="1116"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cbc:Percent"
                  priority="1115"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cbc:Percent"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme"
                  priority="1114"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B13901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme/cbc:ID"
                  priority="1113"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme/*"
                  priority="1112"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/cac:TaxScheme/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B13902</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/*"
                  priority="1111"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/cac:TaxCategory/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B13603</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge/*"
                  priority="1110"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B12704</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal" priority="1109" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:TaxAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:TaxAmount">
               <xsl:attribute name="id">PEPPOL-T110-B14101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:TaxAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cbc:TaxAmount"
                  priority="1108"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cbc:TaxAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B14201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B14202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal"
                  priority="1107"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:TaxableAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:TaxableAmount">
               <xsl:attribute name="id">PEPPOL-T110-B14401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:TaxableAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:TaxAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:TaxAmount">
               <xsl:attribute name="id">PEPPOL-T110-B14402</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:TaxAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxCategory"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxCategory">
               <xsl:attribute name="id">PEPPOL-T110-B14403</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:TaxCategory' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount"
                  priority="1106"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B14501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B14502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount"
                  priority="1105"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B14701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B14702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory"
                  priority="1104"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B14901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxScheme"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxScheme">
               <xsl:attribute name="id">PEPPOL-T110-B14902</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:TaxScheme' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID"
                  priority="1103"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:Percent"
                  priority="1102"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:Percent"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReason"
                  priority="1101"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReason"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme"
                  priority="1100"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B15301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"
                  priority="1099"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/*"
                  priority="1098"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B15302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/*"
                  priority="1097"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B14903</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/*"
                  priority="1096"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B14404</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal/*"
                  priority="1095"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B14102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal"
                  priority="1094"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:LineExtensionAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:LineExtensionAmount">
               <xsl:attribute name="id">PEPPOL-T110-B15501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:LineExtensionAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:TaxExclusiveAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:TaxExclusiveAmount">
               <xsl:attribute name="id">PEPPOL-T110-B15502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:TaxExclusiveAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:TaxInclusiveAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:TaxInclusiveAmount">
               <xsl:attribute name="id">PEPPOL-T110-B15503</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:TaxInclusiveAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:PayableAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:PayableAmount">
               <xsl:attribute name="id">PEPPOL-T110-B15504</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:PayableAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:LineExtensionAmount"
                  priority="1093"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B15601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B15602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"
                  priority="1092"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B15801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B15802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"
                  priority="1091"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B16001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B16002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"
                  priority="1090"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B16201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B16202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"
                  priority="1089"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B16401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B16402</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PrepaidAmount"
                  priority="1088"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PrepaidAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B16601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B16602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PayableRoundingAmount"
                  priority="1087"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PayableRoundingAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B16801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B16802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PayableAmount"
                  priority="1086"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/cbc:PayableAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B17001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B17002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:LegalMonetaryTotal/*"
                  priority="1085"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:LegalMonetaryTotal/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B15505</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine" priority="1084" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:LineItem"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:LineItem">
               <xsl:attribute name="id">PEPPOL-T110-B17201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:LineItem' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem"
                  priority="1083"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B17301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Quantity"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Quantity">
               <xsl:attribute name="id">PEPPOL-T110-B17302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Quantity' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Price"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Price">
               <xsl:attribute name="id">PEPPOL-T110-B17303</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Price' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Item"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Item">
               <xsl:attribute name="id">PEPPOL-T110-B17304</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:Item' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:ID"
                  priority="1082"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:Note"
                  priority="1081"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:Note"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:Quantity"
                  priority="1080"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:Quantity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@unitCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@unitCode">
               <xsl:attribute name="id">PEPPOL-T110-B17601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'unitCode' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)">
               <xsl:attribute name="id">PEPPOL-T110-B17602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Recommendation 20, including Recommendation 21 codes - prefixed with X (UN/ECE)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:LineExtensionAmount"
                  priority="1079"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cbc:LineExtensionAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B17801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B17802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery"
                  priority="1078"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cbc:Quantity"
                  priority="1077"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cbc:Quantity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@unitCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@unitCode">
               <xsl:attribute name="id">PEPPOL-T110-B18101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'unitCode' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)">
               <xsl:attribute name="id">PEPPOL-T110-B18102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Recommendation 20, including Recommendation 21 codes - prefixed with X (UN/ECE)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod"
                  priority="1076"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:StartDate"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:StartDate">
               <xsl:attribute name="id">PEPPOL-T110-B18301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:StartDate' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate"
                  priority="1075"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartTime"
                  priority="1074"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndDate"
                  priority="1073"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndTime"
                  priority="1072"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:EndTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/*"
                  priority="1071"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/cac:PromisedDeliveryPeriod/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B18302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/*"
                  priority="1070"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Delivery/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B18001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price"
                  priority="1069"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:PriceAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:PriceAmount">
               <xsl:attribute name="id">PEPPOL-T110-B18801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:PriceAmount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:PriceAmount"
                  priority="1068"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:PriceAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B18901</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B18902</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:BaseQuantity"
                  priority="1067"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:BaseQuantity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)">
               <xsl:attribute name="id">PEPPOL-T110-B19101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Recommendation 20, including Recommendation 21 codes - prefixed with X (UN/ECE)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:PriceType"
                  priority="1066"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cbc:PriceType"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge"
                  priority="1065"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ChargeIndicator"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ChargeIndicator">
               <xsl:attribute name="id">PEPPOL-T110-B19401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ChargeIndicator' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Amount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Amount">
               <xsl:attribute name="id">PEPPOL-T110-B19402</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Amount' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:ChargeIndicator"
                  priority="1064"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:ChargeIndicator"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'false'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="normalize-space(text()) = 'false'">
               <xsl:attribute name="id">PEPPOL-T110-B19501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ChargeIndicator' MUST contain value 'false'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:Amount"
                  priority="1063"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:Amount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B19601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B19602</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:BaseAmount"
                  priority="1062"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/cbc:BaseAmount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@currencyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
               <xsl:attribute name="id">PEPPOL-T110-B19801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'currencyID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or (some $code in $clISO4217 satisfies $code = @currencyID)">
               <xsl:attribute name="id">PEPPOL-T110-B19802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Currency codes (ISO 4217)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/*"
                  priority="1061"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/cac:AllowanceCharge/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B19403</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/*"
                  priority="1060"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Price/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B18802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item"
                  priority="1059"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B20001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cbc:Description"
                  priority="1058"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cbc:Description"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cbc:Name"
                  priority="1057"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification"
                  priority="1056"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B20301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification/cbc:ID"
                  priority="1055"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification/*"
                  priority="1054"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:BuyersItemIdentification/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B20302</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification"
                  priority="1053"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B20501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification/cbc:ID"
                  priority="1052"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification/*"
                  priority="1051"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:SellersItemIdentification/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B20502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification"
                  priority="1050"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B20701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification/cbc:ID"
                  priority="1049"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="id">PEPPOL-T110-B20801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'schemeID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T110-B20802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 6523 ICD list'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification/*"
                  priority="1048"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:StandardItemIdentification/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B20702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference"
                  priority="1047"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B21001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:ID"
                  priority="1046"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:DocumentTypeCode"
                  priority="1045"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:DocumentTypeCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clUNCL1001 satisfies $code = normalize-space(text())) or (some $code in $clImage satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(some $code in $clUNCL1001 satisfies $code = normalize-space(text())) or (some $code in $clImage satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T110-B21201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Document name code, full list (UNCL1001)' or 'Image code (openPEPPOL)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:DocumentType"
                  priority="1044"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cbc:DocumentType"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment"
                  priority="1043"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"
                  priority="1042"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@mimeCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@mimeCode">
               <xsl:attribute name="id">PEPPOL-T110-B21501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'mimeCode' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@mimeCode) or (some $code in $clMimeCode satisfies $code = @mimeCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@mimeCode) or (some $code in $clMimeCode satisfies $code = @mimeCode)">
               <xsl:attribute name="id">PEPPOL-T110-B21502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Mime code (IANA Subset)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@filename"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@filename">
               <xsl:attribute name="id">PEPPOL-T110-B21503</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'filename' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference"
                  priority="1041"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"
                  priority="1040"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference/*"
                  priority="1039"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/cac:ExternalReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B21801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/*"
                  priority="1038"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/cac:Attachment/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B21401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/*"
                  priority="1037"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ItemSpecificationDocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B21002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification"
                  priority="1036"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"
                  priority="1035"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@listID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@listID">
               <xsl:attribute name="id">PEPPOL-T110-B22101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'listID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@listID) or (some $code in $clUNCL7143 satisfies $code = @listID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@listID) or (some $code in $clUNCL7143 satisfies $code = @listID)">
               <xsl:attribute name="id">PEPPOL-T110-B22102</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Item type identification code (UNCL7143)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification/*"
                  priority="1034"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:CommodityClassification/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B22001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions"
                  priority="1033"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ActionCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ActionCode">
               <xsl:attribute name="id">PEPPOL-T110-B22501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ActionCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions/cbc:ActionCode"
                  priority="1032"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions/cbc:ActionCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'CT'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="normalize-space(text()) = 'CT'">
               <xsl:attribute name="id">PEPPOL-T110-B22601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ActionCode' MUST contain value 'CT'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions/*"
                  priority="1031"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:TransactionConditions/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B22502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory"
                  priority="1030"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B22701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxScheme"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxScheme">
               <xsl:attribute name="id">PEPPOL-T110-B22702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:TaxScheme' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cbc:ID"
                  priority="1029"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent"
                  priority="1028"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme"
                  priority="1027"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B23001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme/cbc:ID"
                  priority="1026"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme/*"
                  priority="1025"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cac:TaxScheme/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B23002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/*"
                  priority="1024"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B22703</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty"
                  priority="1023"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B23201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Value"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Value">
               <xsl:attribute name="id">PEPPOL-T110-B23202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Value' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:Name"
                  priority="1022"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:NameCode"
                  priority="1021"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:NameCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@listID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@listID">
               <xsl:attribute name="id">PEPPOL-T110-B23401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'listID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:Value"
                  priority="1020"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:Value"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:ValueQuantity"
                  priority="1019"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:ValueQuantity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@unitCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@unitCode">
               <xsl:attribute name="id">PEPPOL-T110-B23701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'unitCode' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@unitCode) or (some $code in $clUNECERec20 satisfies $code = @unitCode)">
               <xsl:attribute name="id">PEPPOL-T110-B23702</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'Recommendation 20, including Recommendation 21 codes - prefixed with X (UN/ECE)'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:ValueQualifier"
                  priority="1018"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/cbc:ValueQualifier"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/*"
                  priority="1017"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:AdditionalItemProperty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B23203</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate"
                  priority="1016"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B24001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:CertificateTypeCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CertificateTypeCode">
               <xsl:attribute name="id">PEPPOL-T110-B24002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CertificateTypeCode' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:CertificateType"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CertificateType">
               <xsl:attribute name="id">PEPPOL-T110-B24003</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CertificateType' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:IssuerParty"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:IssuerParty">
               <xsl:attribute name="id">PEPPOL-T110-B24004</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:IssuerParty' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:ID"
                  priority="1015"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:CertificateTypeCode"
                  priority="1014"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:CertificateTypeCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'NA'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="normalize-space(text()) = 'NA'">
               <xsl:attribute name="id">PEPPOL-T110-B24201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CertificateTypeCode' MUST contain value 'NA'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:CertificateType"
                  priority="1013"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:CertificateType"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:Remarks"
                  priority="1012"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cbc:Remarks"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty"
                  priority="1011"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:PartyName"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:PartyName">
               <xsl:attribute name="id">PEPPOL-T110-B24501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:PartyName' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/cac:PartyName"
                  priority="1010"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T110-B24601</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:Name' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/cac:PartyName/cbc:Name"
                  priority="1009"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/*"
                  priority="1008"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:IssuerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B24502</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference"
                  priority="1007"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T110-B24801</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference/cbc:ID"
                  priority="1006"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference/*"
                  priority="1005"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/cac:DocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B24802</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/*"
                  priority="1004"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/cac:Certificate/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B24005</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/*"
                  priority="1003"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B20002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/*"
                  priority="1002"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/cac:LineItem/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B17305</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:OrderLine/*"
                  priority="1001"
                  mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:OrderLine/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B17202</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/*" priority="1000" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="/ubl:OrderResponse/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-B00110</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document MUST NOT contain elements not part of the data model.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M20"/>
   <xsl:template match="@*|node()" priority="-2" mode="M20">
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--PATTERN -->
   <xsl:variable name="taxCategoryPercents"
                  select="for $cat in /ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory return u:cat2str($cat)"/>
   <xsl:variable name="taxCategories"
                  select="for $cat in /ubl:OrderResponse/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory return normalize-space($cat/cbc:ID)"/>
   <xsl:variable name="documentCurrencyCode"
                  select="/ubl:OrderResponse/cbc:DocumentCurrencyCode"/>
   <!--RULE -->
   <xsl:template match="cbc:CustomizationID" priority="1014" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="cbc:CustomizationID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="starts-with(normalize-space(.), 'urn:fdc:peppol.eu:poacc:trns:order_agreement:3')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="starts-with(normalize-space(.), 'urn:fdc:peppol.eu:poacc:trns:order_agreement:3')">
               <xsl:attribute name="id">PEPPOL-T110-R030</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Specification identifier SHALL start with the value 'urn:fdc:peppol.eu:poacc:trns:order_agreement:3'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:Item" priority="1013" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="cac:Item"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(cac:StandardItemIdentification/cbc:ID) or  (cac:SellersItemIdentification/cbc:ID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(cac:StandardItemIdentification/cbc:ID) or (cac:SellersItemIdentification/cbc:ID)">
               <xsl:attribute name="id">PEPPOL-T110-R002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Each item in an Order agreement line SHALL be identifiable by either "item sellers identifier" or "item standard identifier"</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:Amount | cbc:TaxAmount | cbc:TaxableAmount | cbc:LineExtensionAmount | cbc:PriceAmount | cbc:BaseAmount | cac:LegalMonetaryTotal/cbc:*"
                  priority="1012"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cbc:Amount | cbc:TaxAmount | cbc:TaxableAmount | cbc:LineExtensionAmount | cbc:PriceAmount | cbc:BaseAmount | cac:LegalMonetaryTotal/cbc:*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@currencyID) or @currencyID = $documentCurrencyCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(@currencyID) or @currencyID = $documentCurrencyCode">
               <xsl:attribute name="id">PEPPOL-T110-R004</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All amounts SHALL have same currency code as document currency</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ancestor::node()/local-name() = 'Price' or string-length(substring-after(., '.')) &lt;= 2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="ancestor::node()/local-name() = 'Price' or string-length(substring-after(., '.')) &lt;= 2">
               <xsl:attribute name="id">PEPPOL-T110-R013</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Elements of data type amount cannot have more than 2 decimals (I.e. all amounts except unit price amounts)</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:TaxTotal/cac:TaxSubtotal" priority="1011" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:TaxTotal/cac:TaxSubtotal"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(round(cac:TaxCategory/xs:decimal(cbc:Percent)) = 0 and (round(xs:decimal(cbc:TaxAmount)) = 0)) or (round(cac:TaxCategory/xs:decimal(cbc:Percent)) != 0 and (xs:decimal(cbc:TaxAmount) = round(xs:decimal(cbc:TaxableAmount) * (cac:TaxCategory/xs:decimal(cbc:Percent) div 100) * 10 * 10) div 100 )) or (not(exists(cac:TaxCategory/xs:decimal(cbc:Percent))) and (round(xs:decimal(cbc:TaxAmount)) = 0))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(round(cac:TaxCategory/xs:decimal(cbc:Percent)) = 0 and (round(xs:decimal(cbc:TaxAmount)) = 0)) or (round(cac:TaxCategory/xs:decimal(cbc:Percent)) != 0 and (xs:decimal(cbc:TaxAmount) = round(xs:decimal(cbc:TaxableAmount) * (cac:TaxCategory/xs:decimal(cbc:Percent) div 100) * 10 * 10) div 100 )) or (not(exists(cac:TaxCategory/xs:decimal(cbc:Percent))) and (round(xs:decimal(cbc:TaxAmount)) = 0))">
               <xsl:attribute name="id">PEPPOL-T110-R024</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>TAX category tax amount = TAX category taxable amount  x (TAX category rate  / 100), rounded to two decimals.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:TaxTotal[cac:TaxSubtotal]"
                  priority="1010"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:TaxTotal[cac:TaxSubtotal]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(xs:decimal(child::cbc:TaxAmount)= round((sum(cac:TaxSubtotal/xs:decimal(cbc:TaxAmount)) * 10 * 10)) div 100) or not(cac:TaxSubtotal)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(xs:decimal(child::cbc:TaxAmount)= round((sum(cac:TaxSubtotal/xs:decimal(cbc:TaxAmount)) * 10 * 10)) div 100) or not(cac:TaxSubtotal)">
               <xsl:attribute name="id">PEPPOL-T110-R025</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>If TAX breakdown is present, the order agreement TAX total amount  = Σ TAX category tax amount.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:TaxSubtotal/cac:TaxCategory[not(cbc:TaxExemptionReason)]"
                  priority="1009"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:TaxSubtotal/cac:TaxCategory[not(cbc:TaxExemptionReason)]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="contains( ' S Z L M ',concat(' ',normalize-space(cbc:ID),' '))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="contains( ' S Z L M ',concat(' ',normalize-space(cbc:ID),' '))">
               <xsl:attribute name="id">PEPPOL-T110-R028</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>A TAX breakdown with TAX Category codes E, AE, K, G or O SHALL have a TAX exemption reason text </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:TaxSubtotal/cac:TaxCategory[cbc:TaxExemptionReason]"
                  priority="1008"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:TaxSubtotal/cac:TaxCategory[cbc:TaxExemptionReason]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="contains( ' E AE O K G ',concat(' ',normalize-space(cbc:ID),' '))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="contains( ' E AE O K G ',concat(' ',normalize-space(cbc:ID),' '))">
               <xsl:attribute name="id">PEPPOL-T110-R029</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>A TAX breakdown with TAX Category codes S, Z, L and M SHALL NOT have a TAX exemption reason text </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:AllowanceCharge/cac:TaxCategory | cac:Item/cac:ClassifiedTaxCategory"
                  priority="1007"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:AllowanceCharge/cac:TaxCategory | cac:Item/cac:ClassifiedTaxCategory"/>
      <xsl:variable name="category" select="u:cat2str(.)"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:Percent) or not(//cac:TaxTotal) or (some $cat in $taxCategoryPercents satisfies $cat = $category)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:Percent) or not(//cac:TaxTotal) or (some $cat in $taxCategoryPercents satisfies $cat = $category)">
               <xsl:attribute name="id">PEPPOL-T110-R026</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax category rates MUST match provided tax categories on document level when such exists.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//cac:TaxTotal) or (some $cat in $taxCategories satisfies $cat = cbc:ID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(//cac:TaxTotal) or (some $cat in $taxCategories satisfies $cat = cbc:ID)">
               <xsl:attribute name="id">PEPPOL-T110-R027</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax categories MUST match provided tax categories on document level when such exists.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Percent or (normalize-space(cbc:ID)='O')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="cbc:Percent or (normalize-space(cbc:ID)='O')">
               <xsl:attribute name="id">PEPPOL-T110-R019</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Each Tax Category SHALL have a TAX category rate, except if the order is not subject to TAX.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(normalize-space(cbc:ID)='S') or (cbc:Percent) &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(normalize-space(cbc:ID)='S') or (cbc:Percent) &gt; 0">
               <xsl:attribute name="id">PEPPOL-T110-R020</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>When TAX category code is "Standard rated" (S) the TAX rate SHALL be greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:LegalMonetaryTotal" priority="1006" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:LegalMonetaryTotal"/>
      <xsl:variable name="lineExtensionAmount"
                     select="xs:decimal(if (cbc:LineExtensionAmount) then cbc:LineExtensionAmount else 0)"/>
      <xsl:variable name="allowanceTotalAmount"
                     select="xs:decimal(if (cbc:AllowanceTotalAmount) then cbc:AllowanceTotalAmount else 0)"/>
      <xsl:variable name="chargeTotalAmount"
                     select="xs:decimal(if (cbc:ChargeTotalAmount) then cbc:ChargeTotalAmount else 0)"/>
      <xsl:variable name="taxExclusiveAmount"
                     select="xs:decimal(if (cbc:TaxExclusiveAmount) then cbc:TaxExclusiveAmount else 0)"/>
      <xsl:variable name="taxInclusiveAmount"
                     select="xs:decimal(if (cbc:TaxInclusiveAmount) then cbc:TaxInclusiveAmount else 0)"/>
      <xsl:variable name="payableRoundingAmount"
                     select="xs:decimal(if (cbc:PayableRoundingAmount) then cbc:PayableRoundingAmount else 0)"/>
      <xsl:variable name="payableAmount"
                     select="xs:decimal(if (cbc:PayableAmount) then cbc:PayableAmount else 0)"/>
      <xsl:variable name="prepaidAmount"
                     select="xs:decimal(if (cbc:PrepaidAmount) then cbc:PrepaidAmount else 0)"/>
      <xsl:variable name="taxTotal"
                     select="xs:decimal(if (/ubl:OrderResponse/cac:TaxTotal/cbc:TaxAmount) then (/ubl:OrderResponse/cac:TaxTotal/cbc:TaxAmount) else 0)"/>
      <xsl:variable name="allowanceTotal"
                     select="round(sum(/ubl:OrderResponse/cac:AllowanceCharge[cbc:ChargeIndicator='false']/cbc:Amount/xs:decimal(.))* 10 * 10) div 100"/>
      <xsl:variable name="chargeTotal"
                     select="round(sum(/ubl:OrderResponse/cac:AllowanceCharge[cbc:ChargeIndicator='true']/cbc:Amount/xs:decimal(.)) * 10 * 10) div 100"/>
      <xsl:variable name="lineExtensionTotal"
                     select="round(sum(//cac:OrderLine/cac:LineItem/cbc:LineExtensionAmount/xs:decimal(.)) * 10 * 10) div 100"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(//cac:OrderLine) = count(//cac:LineItem/cbc:LineExtensionAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="count(//cac:OrderLine) = count(//cac:LineItem/cbc:LineExtensionAmount)">
               <xsl:attribute name="id">PEPPOL-T110-R014</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>If document totals is provided, all order agreement lines SHALL have a line extension amount</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:PayableAmount) or cbc:PayableAmount &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:PayableAmount) or cbc:PayableAmount &gt;= 0">
               <xsl:attribute name="id">PEPPOL-T110-R005</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total amount for payment SHALL NOT be negative, if expected total amount for payment is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="$lineExtensionAmount &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="$lineExtensionAmount &gt;= 0">
               <xsl:attribute name="id">PEPPOL-T110-R006</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total amount for payment SHALL NOT be negative, if expected total amount for payment is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:LineExtensionAmount) or $lineExtensionAmount = $lineExtensionTotal"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:LineExtensionAmount) or $lineExtensionAmount = $lineExtensionTotal">
               <xsl:attribute name="id">PEPPOL-T110-R007</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total sum of line amounts SHALL equal the sum of the order line amounts at order line level, if total sum of line amounts is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:ChargeTotalAmount) or $chargeTotalAmount = $chargeTotal"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:ChargeTotalAmount) or $chargeTotalAmount = $chargeTotal">
               <xsl:attribute name="id">PEPPOL-T110-R008</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total sum of charges at document level SHALL be equal to the sum of charges at document level, if total sum of charges at document level is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:AllowanceTotalAmount) or $allowanceTotalAmount = $allowanceTotal"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:AllowanceTotalAmount) or $allowanceTotalAmount = $allowanceTotal">
               <xsl:attribute name="id">PEPPOL-T110-R009</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total sum of allowance at document level SHALL be equal to the sum of allowance amounts at document level, if total sum of allowance at document level is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:TaxExclusiveAmount) or $taxExclusiveAmount = $lineExtensionAmount + $chargeTotalAmount - $allowanceTotalAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:TaxExclusiveAmount) or $taxExclusiveAmount = $lineExtensionAmount + $chargeTotalAmount - $allowanceTotalAmount">
               <xsl:attribute name="id">PEPPOL-T110-R010</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax exclusive amount SHALL equal the sum of line amount plus total charge amount at document level less total allowance amount at document level if tax exclusive amount is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="$taxInclusiveAmount = $taxExclusiveAmount + $taxTotal"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="$taxInclusiveAmount = $taxExclusiveAmount + $taxTotal">
               <xsl:attribute name="id">PEPPOL-T110-R011</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Tax inclusive amount SHALL equal tax exclusive amount plus total tax amount.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:PayableAmount) or $payableAmount = $taxInclusiveAmount - $prepaidAmount + $payableRoundingAmount"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:PayableAmount) or $payableAmount = $taxInclusiveAmount - $prepaidAmount + $payableRoundingAmount">
               <xsl:attribute name="id">PEPPOL-T110-R012</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Total amount for payment SHALL be equal to the tax inclusive amount minus the prepaid amount plus rounding amount</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge[cbc:MultiplierFactorNumeric and not(cbc:BaseAmount)]"
                  priority="1005"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge[cbc:MultiplierFactorNumeric and not(cbc:BaseAmount)]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-R015</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Allowance/charge base amount SHALL be provided when allowance/charge percentage is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge[not(cbc:MultiplierFactorNumeric) and cbc:BaseAmount]"
                  priority="1004"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge[not(cbc:MultiplierFactorNumeric) and cbc:BaseAmount]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T110-R016</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Allowance/charge percentage SHALL be provided when allowance/charge base amount is provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderResponse/cac:AllowanceCharge"
                  priority="1003"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="/ubl:OrderResponse/cac:AllowanceCharge"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(cbc:MultiplierFactorNumeric and cbc:BaseAmount) or u:slack(if (cbc:Amount) then cbc:Amount else 0, (xs:decimal(cbc:BaseAmount) * xs:decimal(cbc:MultiplierFactorNumeric)) div 100, 0.02)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="not(cbc:MultiplierFactorNumeric and cbc:BaseAmount) or u:slack(if (cbc:Amount) then cbc:Amount else 0, (xs:decimal(cbc:BaseAmount) * xs:decimal(cbc:MultiplierFactorNumeric)) div 100, 0.02)">
               <xsl:attribute name="id">PEPPOL-T110-R017</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Allowance/charge amount SHALL equal base amount * percentage/100 if base amount and percentage exists</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="exists(cbc:AllowanceChargeReason) or exists(cbc:AllowanceChargeReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="exists(cbc:AllowanceChargeReason) or exists(cbc:AllowanceChargeReasonCode)">
               <xsl:attribute name="id">PEPPOL-T110-R018</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Each document level allowance SHALL have an allowance reason text or an allowance reason code.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="number(cbc:Amount) &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="number(cbc:Amount) &gt;= 0">
               <xsl:attribute name="id">PEPPOL-T110-R021</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Document level allowance or charge amounts SHALL NOT be negative.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:Price" priority="1002" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="cac:Price"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="number(cbc:PriceAmount) &gt;=0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="number(cbc:PriceAmount) &gt;=0">
               <xsl:attribute name="id">PEPPOL-T110-R001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Each order agreement line item net price SHALL not be negative
		</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(cac:AllowanceCharge/cbc:BaseAmount) &gt;= 0 or not(exists(cac:AllowanceCharge/cbc:BaseAmount))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="(cac:AllowanceCharge/cbc:BaseAmount) &gt;= 0 or not(exists(cac:AllowanceCharge/cbc:BaseAmount))">
               <xsl:attribute name="id">PEPPOL-T110-R022</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The Item gross price SHALL NOT be negative.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="number(cac:AllowanceCharge/cbc:Amount) &gt;= 0 or not(exists(cac:AllowanceCharge/cbc:Amount))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="number(cac:AllowanceCharge/cbc:Amount) &gt;= 0 or not(exists(cac:AllowanceCharge/cbc:Amount))">
               <xsl:attribute name="id">PEPPOL-T110-R023</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Allowance or charge price amounts SHALL NOT be negative.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:AllowanceCharge[cbc:ChargeIndicator = 'false']/cbc:AllowanceChargeReasonCode"
                  priority="1001"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:AllowanceCharge[cbc:ChargeIndicator = 'false']/cbc:AllowanceChargeReasonCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="    some $code in $clUNCL5189    satisfies normalize-space(text()) = $code"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="some $code in $clUNCL5189 satisfies normalize-space(text()) = $code">
               <xsl:attribute name="id">PEPPOL-T110-CL001</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Reason code MUST be according to subset of UNCL 5189 D.16B.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cac:AllowanceCharge[cbc:ChargeIndicator = 'true']/cbc:AllowanceChargeReasonCode"
                  priority="1000"
                  mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        context="cac:AllowanceCharge[cbc:ChargeIndicator = 'true']/cbc:AllowanceChargeReasonCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="    some $code in $clUNCL7161    satisfies normalize-space(text()) = $code"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="some $code in $clUNCL7161 satisfies normalize-space(text()) = $code">
               <xsl:attribute name="id">PEPPOL-T110-CL002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Reason code MUST be according to UNCL 7161 D.16B.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M21"/>
   <xsl:template match="@*|node()" priority="-2" mode="M21">
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
</xsl:stylesheet>
