<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
	version="2.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:cdo="http://www.cdosuite.com/schemas"
	xmlns:cv="http://www.cdosuite.com/schemas/CustomValue.xsd"
	xmlns:lc="http://www.cdosuite.com/schemas/LookupCodes.xsd"
	xmlns:rt="http://www.cdosuite.com/schemas/Ratings.xsd"
	xmlns:ps="http://www.cdosuite.com/schemas/PortfolioSnapshot.xsd"
	xmlns:map="http://www.cdosuite.com/schemas/Mapping.xsd"
	xmlns:mstns="http://tempuri.org"
	xmlns="http://tempuri.org"

	exclude-result-prefixes="cdo cv lc ps rt xs xsi xsl"
>

	<xsl:output method="xml" version="1.0" indent="yes" encoding="utf-8"></xsl:output>
	<xsl:variable name="CopyNonMatches" select="'false'"/>
	<xsl:variable name="MappingElements" select="document('Lookup.xml')/descendant::map:Mapping"/>
	<xsl:variable name="Mapping" select="'XSDtoSQL'"/>

    <xsl:param name="USE_GLOBAL_CONTEXT" as="xs:boolean" static="true" select="false()"/>
    <xsl:variable name="principal" select="." use-when="$USE_GLOBAL_CONTEXT"/>

  <xsl:template match="/ps:Root">
  	<xsl:if test="not((/) is $principal)" use-when="$USE_GLOBAL_CONTEXT">
  		<xsl:message terminate="yes">Match selection differs from global context item</xsl:message>
  	</xsl:if>
		<mstns:dsPortfolioSnapshot>
      
			<!--This is actualy the root node, not a portfolio snapshot which is below as PS_Portfolio_Snapshot-->
			<xsl:attribute name="xsi:schemaLocation">
				<xsl:value-of select="'http://tempuri.org PortfolioSnapshot_CdoSuite.xsd'"/>
			</xsl:attribute>
			<xsl:apply-templates select="ps:PortfolioSnapshots/ps:PortfolioSnapshot"/>
		</mstns:dsPortfolioSnapshot>
	</xsl:template>

	<!--PortfolioSnapshot-->
	<xsl:template match="ps:PortfolioSnapshot">
		<mstns:CSES_PS_Portfolio_Snapshot>
			<mstns:ps_id>
				<xsl:value-of select="position()"/>
			</mstns:ps_id>
			<xsl:apply-templates/>
		</mstns:CSES_PS_Portfolio_Snapshot>
	</xsl:template>

	<!--Obligors-->
	<xsl:template match="ps:Obligor">
		<mstns:Obligor>
			<mstns:obligor_id>
				<xsl:value-of select="position()"/>
			</mstns:obligor_id>
			<xsl:apply-templates/>
		</mstns:Obligor>
	</xsl:template>

	<!--Issuers-->
	<xsl:template match="ps:Issuer">
		<mstns:Issuer>
			<xsl:apply-templates/>
		</mstns:Issuer>
	</xsl:template>

	<!--Issues-->
	<xsl:template match="*[parent::ps:Issue]">
		<mstns:Issue>
			<xsl:apply-templates/>
		</mstns:Issue>
	</xsl:template>

	<!--Purchase Lots-->
	<xsl:template match="ps:PurchaseLot">
		<mstns:PurchaseLot>
			<xsl:apply-templates/>
		</mstns:PurchaseLot>
	</xsl:template>

  <!--Copy each child node, renaming it if you can find a lookup for it.-->
  <xsl:template match="node()">

    <xsl:if test="not(*)">
      <!--Only do child elements if they themselves, do not have any child elements.-->

      <!--Path from the root to the current node -->
      <xsl:variable name="PathToCurrentNode">
        <xsl:call-template name="PathToNode"/>
      </xsl:variable>

      <xsl:variable name="MappingElement" select='$MappingElements[($Mapping = "XSDtoSQL" and @xsd=$PathToCurrentNode) or ($Mapping = "SQLtoXSD" and @sql=$PathToCurrentNode)]'/>

      <xsl:choose>
        <xsl:when  test="$MappingElement">
          <xsl:variable name="To" select='if ($Mapping = "XSDtoSQL") then $MappingElement/@sql else $MappingElement/@xsd'/>
          <xsl:if test="$To != '(SKIP)'">
            <xsl:variable name='ToValue' select='.'/>
            <xsl:for-each select='tokenize($To, ",")'>
              <xsl:element name='{normalize-space(.)}'>
                <xsl:value-of select="$ToValue"/>
              </xsl:element>
            </xsl:for-each>
          </xsl:if>
        </xsl:when>
        <xsl:when test="$CopyNonMatches='true'">
          <xsl:copy/>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template name="PathToNode">
    <xsl:for-each select="ancestor-or-self::*">
      <xsl:value-of select="name()" />
      <xsl:text>/</xsl:text>
    </xsl:for-each>
  </xsl:template>

 

</xsl:stylesheet>
