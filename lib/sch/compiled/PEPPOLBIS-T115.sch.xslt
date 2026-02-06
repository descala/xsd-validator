<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:schold="http://www.ascc.net/xml/schematron"
                xmlns:u="utils"
                xmlns:ubl="urn:oasis:names:specification:ubl:schema:xsd:OrderCancellation-2"
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
      <sequence select="(10 - ($weightedSum mod 10)) mod 10 = number(substring($val, $length + 1, 1))"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
             xmlns:xi="http://www.w3.org/2001/XInclude"
             name="u:slack"
             as="xs:boolean">
      <param name="exp" as="xs:decimal"/>
      <param name="val" as="xs:decimal"/>
      <param name="slack" as="xs:decimal"/>
      <sequence select="xs:decimal($exp + $slack) &gt;= $val and xs:decimal($exp - $slack) &lt;= $val"/>
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
      <sequence select="number($val) &gt; 0 and (11 - ($weightedSum mod 11)) mod 11 = number(substring($val, $length + 1, 1))"/>
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
      <sequence select="number($checkdigits) = number($calculated_digits)"/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
             xmlns:xi="http://www.w3.org/2001/XInclude"
             name="u:abn"
             as="xs:boolean">
      <param name="val"/>
      <sequence select="( ((string-to-codepoints(substring($val,1,1)) - 49) * 10) + ((string-to-codepoints(substring($val,2,1)) - 48) * 1) + ((string-to-codepoints(substring($val,3,1)) - 48) * 3) + ((string-to-codepoints(substring($val,4,1)) - 48) * 5) + ((string-to-codepoints(substring($val,5,1)) - 48) * 7) + ((string-to-codepoints(substring($val,6,1)) - 48) * 9) + ((string-to-codepoints(substring($val,7,1)) - 48) * 11) + ((string-to-codepoints(substring($val,8,1)) - 48) * 13) + ((string-to-codepoints(substring($val,9,1)) - 48) * 15) + ((string-to-codepoints(substring($val,10,1)) - 48) * 17) + ((string-to-codepoints(substring($val,11,1)) - 48) * 19)) mod 89 = 0 "/>
   </function>
   <function xmlns="http://www.w3.org/1999/XSL/Transform"
             xmlns:xi="http://www.w3.org/2001/XInclude"
             name="u:checkSEOrgnr"
             as="xs:boolean">
      <param name="number" as="xs:string"/>
      <choose>
         <when test="not(matches($number, '^\d+$'))">
            <sequence select="false()"/>
         </when>
         <otherwise>
            <variable name="mainPart" select="substring($number, 1, 9)"/>
            <variable name="checkDigit" select="substring($number, 10, 1)"/>
            <variable name="sum" as="xs:integer">
               <sequence select="xs:integer(sum(       for $pos in 1 to string-length($mainPart) return         if ($pos mod 2 = 1)         then (number(substring($mainPart, string-length($mainPart) - $pos + 1, 1)) * 2) mod 10 +           (number(substring($mainPart, string-length($mainPart) - $pos + 1, 1)) * 2) idiv 10         else number(substring($mainPart, string-length($mainPart) - $pos + 1, 1))      ))"/>
            </variable>
            <variable name="calculatedCheckDigit" select="(10 - $sum mod 10) mod 10"/>
            <sequence select="$calculatedCheckDigit = number($checkDigit)"/>
         </otherwise>
      </choose>
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
                              title="Rules for Peppol Order Cancellation transaction 3.0"
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
         <svrl:ns-prefix-in-attribute-values uri="urn:oasis:names:specification:ubl:schema:xsd:OrderCancellation-2"
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
   <svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Rules for Peppol Order Cancellation transaction 3.0</svrl:text>
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
   <xsl:template match="/*" priority="1013" mode="M19">
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
                 priority="1012"
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
                 priority="1011"
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
                 priority="1010"
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
   <xsl:template match="cbc:EndpointID[@schemeID = '0184'] | cac:PartyIdentification/cbc:ID[@schemeID = '0184'] | cbc:CompanyID[@schemeID = '0184']"
                 priority="1009"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="cbc:EndpointID[@schemeID = '0184'] | cac:PartyIdentification/cbc:ID[@schemeID = '0184'] | cbc:CompanyID[@schemeID = '0184']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0)                or               (string-length(string()) = 8) and (string-length(translate(substring(string(), 1, 8),'1234567890', '')) = 0)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0) or (string-length(string()) = 8) and (string-length(translate(substring(string(), 1, 8),'1234567890', '')) = 0)">
               <xsl:attribute name="id">PEPPOL-COMMON-R042</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Danish organization number (CVR) MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0096'] | cac:PartyIdentification/cbc:ID[@schemeID = '0096'] | cbc:CompanyID[@schemeID = '0096']"
                 priority="1008"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="cbc:EndpointID[@schemeID = '0096'] | cac:PartyIdentification/cbc:ID[@schemeID = '0096'] | cbc:CompanyID[@schemeID = '0096']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(string-length(string()) = 10) and (string-length(translate(substring(string(), 1, 10),'1234567890', '')) = 0)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(string-length(string()) = 10) and (string-length(translate(substring(string(), 1, 10),'1234567890', '')) = 0)">
               <xsl:attribute name="id">PEPPOL-COMMON-R052</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Danish chamber of commerce number (P) MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0198'] | cac:PartyIdentification/cbc:ID[@schemeID = '0198'] | cbc:CompanyID[@schemeID = '0198']"
                 priority="1007"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="cbc:EndpointID[@schemeID = '0198'] | cac:PartyIdentification/cbc:ID[@schemeID = '0198'] | cbc:CompanyID[@schemeID = '0198']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0)">
               <xsl:attribute name="id">PEPPOL-COMMON-R053</xsl:attribute>
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Danish ERSTORG number (SE) MUST be stated in the correct format.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:EndpointID[@schemeID = '0208'] | cac:PartyIdentification/cbc:ID[@schemeID = '0208'] | cbc:CompanyID[@schemeID = '0208']"
                 priority="1006"
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
                 priority="1005"
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
                 priority="1004"
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
                 priority="1003"
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
                 priority="1002"
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
   <xsl:template match="cbc:EndpointID[@schemeID = '0007'] | cac:PartyIdentification/cbc:ID[@schemeID = '0007'] | cbc:CompanyID[@schemeID = '0007']"
                 priority="1001"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="cbc:EndpointID[@schemeID = '0007'] | cac:PartyIdentification/cbc:ID[@schemeID = '0007'] | cbc:CompanyID[@schemeID = '0007']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(normalize-space()) = 10 and string(number(normalize-space())) != 'NaN' and u:checkSEOrgnr(normalize-space())"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(normalize-space()) = 10 and string(number(normalize-space())) != 'NaN' and u:checkSEOrgnr(normalize-space())">
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
                 select="tokenize('0002 0007 0009 0037 0060 0088 0096 0097 0106 0130 0135 0142 0151 0177 0183 0184 0188 0190 0191 0192 0193 0195 0196 0198 0199 0200 0201 0202 0204 0208 0209 0210 0211 0212 0213 0215 0216 0218 0221 0230 0235 9910 9913 9914 9915 9918 9919 9920 9922 9923 9924 9925 9926 9927 9928 9929 9930 9931 9932 9933 9934 9935 9936 9937 9938 9939 9940 9941 9942 9943 9944 9945 9946 9947 9948 9949 9950 9951 9952 9953 9957 9959 0147 0154 0158 0170 0194 0203 0205 0217 0225 0240 0244', '\s')"/>
   <xsl:variable name="clISO3166"
                 select="tokenize('AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW 1A XI', '\s')"/>
   <xsl:variable name="clICD"
                 select="tokenize('0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 0020 0021 0022 0023 0024 0025 0026 0027 0028 0029 0030 0031 0032 0033 0034 0035 0036 0037 0038 0039 0040 0041 0042 0043 0044 0045 0046 0047 0048 0049 0050 0051 0052 0053 0054 0055 0056 0057 0058 0059 0060 0061 0062 0063 0064 0065 0066 0067 0068 0069 0070 0071 0072 0073 0074 0075 0076 0077 0078 0079 0080 0081 0082 0083 0084 0085 0086 0087 0088 0089 0090 0091 0093 0094 0095 0096 0097 0098 0099 0100 0101 0102 0104 0105 0106 0107 0108 0109 0110 0111 0112 0113 0114 0115 0116 0117 0118 0119 0120 0121 0122 0123 0124 0125 0126 0127 0128 0129 0130 0131 0132 0133 0134 0135 0136 0137 0138 0139 0140 0141 0142 0143 0144 0145 0146 0147 0148 0149 0150 0151 0152 0153 0154 0155 0156 0157 0158 0159 0160 0161 0162 0163 0164 0165 0166 0167 0168 0169 0170 0171 0172 0173 0174 0175 0176 0177 0178 0179 0180 0183 0184 0185 0186 0187 0188 0189 0190 0191 0192 0193 0194 0195 0196 0197 0198 0199 0200 0201 0202 0203 0204 0205 0206 0207 0208 0209 0210 0211 0212 0213 0214 0215 0216 0217 0218 0219 0220 0221 0222 0223 0224 0225 0226 0227 0228 0229 0230 0231 0232 0233 0234 0235 0236 0237 0238 0239 0240 0241 0242 0243 0244', '\s')"/>
   <xsl:variable name="clMimeCode"
                 select="tokenize('application/pdf image/png image/jpeg image/tiff application/acad application/dwg drawing/dwg application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.oasis.opendocument.spreadsheet', '\s')"/>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation" priority="1118" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:CustomizationID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CustomizationID">
               <xsl:attribute name="id">PEPPOL-T115-B00101</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B00102</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B00103</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B00104</xsl:attribute>
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
         <xsl:when test="cbc:CancellationNote"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CancellationNote">
               <xsl:attribute name="id">PEPPOL-T115-B00105</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CancellationNote' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:OrderReference"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:OrderReference">
               <xsl:attribute name="id">PEPPOL-T115-B00106</xsl:attribute>
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
         <xsl:when test="cac:BuyerCustomerParty"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:BuyerCustomerParty">
               <xsl:attribute name="id">PEPPOL-T115-B00107</xsl:attribute>
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
         <xsl:when test="cac:SellerSupplierParty"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:SellerSupplierParty">
               <xsl:attribute name="id">PEPPOL-T115-B00108</xsl:attribute>
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
         <xsl:when test="not(@*:schemaLocation)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@*:schemaLocation)">
               <xsl:attribute name="id">PEPPOL-T115-B00109</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cbc:CustomizationID"
                 priority="1117"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:CustomizationID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3'">
               <xsl:attribute name="id">PEPPOL-T115-B00201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CustomizationID' MUST contain value 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:ProfileID"
                 priority="1116"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:ProfileID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:bis:advanced_ordering:3'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="normalize-space(text()) = 'urn:fdc:peppol.eu:poacc:bis:advanced_ordering:3'">
               <xsl:attribute name="id">PEPPOL-T115-B00301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:ProfileID' MUST contain value 'urn:fdc:peppol.eu:poacc:bis:advanced_ordering:3'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:ID" priority="1115" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:IssueDate"
                 priority="1114"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:IssueDate"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:IssueTime"
                 priority="1113"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:IssueTime"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:Note" priority="1112" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:Note"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cbc:CancellationNote"
                 priority="1111"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cbc:CancellationNote"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OrderReference"
                 priority="1110"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OrderReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B00901</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OrderReference/cbc:ID"
                 priority="1109"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OrderReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OrderReference/*"
                 priority="1108"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OrderReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B00902</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorDocumentReference"
                 priority="1107"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorDocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B01101</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorDocumentReference/cbc:ID"
                 priority="1106"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorDocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorDocumentReference/*"
                 priority="1105"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorDocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B01102</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference"
                 priority="1104"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B01301</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cbc:ID"
                 priority="1103"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cbc:DocumentType"
                 priority="1102"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cbc:DocumentType"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment"
                 priority="1101"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"
                 priority="1100"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@mimeCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@mimeCode">
               <xsl:attribute name="id">PEPPOL-T115-B01701</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B01702</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B01703</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference"
                 priority="1099"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:URI"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:URI">
               <xsl:attribute name="id">PEPPOL-T115-B02001</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"
                 priority="1098"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/cbc:URI"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/*"
                 priority="1097"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/cac:ExternalReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B02002</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/*"
                 priority="1096"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/cac:Attachment/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B01601</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:AdditionalDocumentReference/*"
                 priority="1095"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:AdditionalDocumentReference/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B01302</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:Contract"
                 priority="1094"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:Contract"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B02201</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:Contract/cbc:ID"
                 priority="1093"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:Contract/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:Contract/*"
                 priority="1092"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:Contract/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B02202</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty"
                 priority="1091"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Party"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Party">
               <xsl:attribute name="id">PEPPOL-T115-B02401</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party"
                 priority="1090"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:EndpointID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:EndpointID">
               <xsl:attribute name="id">PEPPOL-T115-B02501</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B02502</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID"
                 priority="1089"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="id">PEPPOL-T115-B02601</xsl:attribute>
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
               <xsl:attribute name="id">PEPPOL-T115-B02602</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification"
                 priority="1088"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B02801</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
                 priority="1087"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T115-B02901</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyName"
                 priority="1086"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T115-B03101</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyName/cbc:Name"
                 priority="1085"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress"
                 priority="1084"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T115-B03301</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName"
                 priority="1083"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"
                 priority="1082"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName"
                 priority="1081"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone"
                 priority="1080"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
                 priority="1079"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine"
                 priority="1078"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"
                 priority="1077"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country"
                 priority="1076"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T115-B04101</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
                 priority="1075"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T115-B04201</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 3166-1:Alpha2 Country codes'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/*"
                 priority="1074"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B04102</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/*"
                 priority="1073"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PostalAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B03302</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme"
                 priority="1072"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:CompanyID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:CompanyID">
               <xsl:attribute name="id">PEPPOL-T115-B04301</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cbc:CompanyID' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:TaxScheme"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:TaxScheme">
               <xsl:attribute name="id">PEPPOL-T115-B04302</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"
                 priority="1071"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme"
                 priority="1070"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B04501</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme/cbc:ID"
                 priority="1069"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme/cbc:ID"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme/*"
                 priority="1068"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/cac:TaxScheme/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B04502</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/*"
                 priority="1067"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyTaxScheme/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B04303</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity"
                 priority="1066"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:RegistrationName"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:RegistrationName">
               <xsl:attribute name="id">PEPPOL-T115-B04701</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"
                 priority="1065"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"
                 priority="1064"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T115-B04901</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress"
                 priority="1063"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T115-B05101</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"
                 priority="1062"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country"
                 priority="1061"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T115-B05301</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"
                 priority="1060"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T115-B05401</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 3166-1:Alpha2 Country codes'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/*"
                 priority="1059"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B05302</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/*"
                 priority="1058"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B05102</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/*"
                 priority="1057"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B04702</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact"
                 priority="1056"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:Name"
                 priority="1055"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:Telephone"
                 priority="1054"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:Telephone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"
                 priority="1053"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/*"
                 priority="1052"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/cac:Contact/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B05501</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/*"
                 priority="1051"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B02503</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:BuyerCustomerParty/*"
                 priority="1050"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:BuyerCustomerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B02402</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty"
                 priority="1049"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Party"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Party">
               <xsl:attribute name="id">PEPPOL-T115-B05901</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party"
                 priority="1048"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:EndpointID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:EndpointID">
               <xsl:attribute name="id">PEPPOL-T115-B06001</xsl:attribute>
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
         <xsl:when test="cac:PostalAddress"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:PostalAddress">
               <xsl:attribute name="id">PEPPOL-T115-B06002</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Element 'cac:PostalAddress' MUST be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:PartyLegalEntity"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:PartyLegalEntity">
               <xsl:attribute name="id">PEPPOL-T115-B06003</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cbc:EndpointID"
                 priority="1047"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cbc:EndpointID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="id">PEPPOL-T115-B06101</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Attribute 'schemeID' MUST be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification"
                 priority="1046"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B06301</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"
                 priority="1045"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T115-B06401</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyName"
                 priority="1044"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T115-B06601</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyName/cbc:Name"
                 priority="1043"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress"
                 priority="1042"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T115-B06801</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName"
                 priority="1041"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"
                 priority="1040"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName"
                 priority="1039"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone"
                 priority="1038"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:PostalZone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"
                 priority="1037"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine"
                 priority="1036"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"
                 priority="1035"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country"
                 priority="1034"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T115-B07601</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"
                 priority="1033"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T115-B07701</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 3166-1:Alpha2 Country codes'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/*"
                 priority="1032"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B07602</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/*"
                 priority="1031"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PostalAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B06802</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity"
                 priority="1030"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:RegistrationName"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:RegistrationName">
               <xsl:attribute name="id">PEPPOL-T115-B07801</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"
                 priority="1029"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"
                 priority="1028"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T115-B08001</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress"
                 priority="1027"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Country"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Country">
               <xsl:attribute name="id">PEPPOL-T115-B08201</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"
                 priority="1026"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country"
                 priority="1025"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:IdentificationCode"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:IdentificationCode">
               <xsl:attribute name="id">PEPPOL-T115-B08401</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"
                 priority="1024"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(some $code in $clISO3166 satisfies $code = normalize-space(text()))">
               <xsl:attribute name="id">PEPPOL-T115-B08501</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Value MUST be part of code list 'ISO 3166-1:Alpha2 Country codes'.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/*"
                 priority="1023"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B08402</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/*"
                 priority="1022"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B08202</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/*"
                 priority="1021"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B07802</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact"
                 priority="1020"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Name"
                 priority="1019"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Telephone"
                 priority="1018"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:Telephone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"
                 priority="1017"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/cbc:ElectronicMail"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/*"
                 priority="1016"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/cac:Contact/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B08601</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/*"
                 priority="1015"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B06004</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:SellerSupplierParty/*"
                 priority="1014"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:SellerSupplierParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B05902</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty"
                 priority="1013"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cac:Party"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cac:Party">
               <xsl:attribute name="id">PEPPOL-T115-B09001</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party"
                 priority="1012"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification"
                 priority="1011"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:ID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:ID">
               <xsl:attribute name="id">PEPPOL-T115-B09201</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"
                 priority="1010"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(@schemeID) or (some $code in $clICD satisfies $code = @schemeID)">
               <xsl:attribute name="id">PEPPOL-T115-B09301</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyName"
                 priority="1009"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyName"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="cbc:Name"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="cbc:Name">
               <xsl:attribute name="id">PEPPOL-T115-B09501</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyName/cbc:Name"
                 priority="1008"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:PartyName/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact"
                 priority="1007"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:Name"
                 priority="1006"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:Name"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:Telephone"
                 priority="1005"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:Telephone"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"
                 priority="1004"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/cbc:ElectronicMail"/>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/*"
                 priority="1003"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/cac:Contact/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B09701</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/*"
                 priority="1002"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/cac:Party/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B09101</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/cac:OriginatorCustomerParty/*"
                 priority="1001"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/cac:OriginatorCustomerParty/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B09002</xsl:attribute>
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
   <xsl:template match="/ubl:OrderCancellation/*" priority="1000" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/ubl:OrderCancellation/*"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false()">
               <xsl:attribute name="id">PEPPOL-T115-B00110</xsl:attribute>
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
   <!--RULE -->
   <xsl:template match="cbc:ProfileID" priority="1001" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="cbc:ProfileID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="some $p in tokenize('urn:fdc:peppol.eu:poacc:bis:advanced_ordering:3', '\s') satisfies $p = normalize-space(.)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="some $p in tokenize('urn:fdc:peppol.eu:poacc:bis:advanced_ordering:3', '\s') satisfies $p = normalize-space(.)">
               <xsl:attribute name="id">PEPPOL-T115-R031</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>An order cancellation transaction MUST use profile advanced_ordering.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="cbc:CustomizationID" priority="1000" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="cbc:CustomizationID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="starts-with(normalize-space(.), 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="starts-with(normalize-space(.), 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3')">
               <xsl:attribute name="id">PEPPOL-T115-R034</xsl:attribute>
               <xsl:attribute name="flag">fatal</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Specification identifier MUST start with the value 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3'.</svrl:text>
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
