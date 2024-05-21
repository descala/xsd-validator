<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
	expand-text="yes"
    version="3.0">
	
	<xsl:mode on-no-match="shallow-copy"/>
    	
	<xsl:template match="/">
	  <xsl:next-match/>
	  <xsl:comment>Processed at {current-dateTime()} by {static-base-uri()} through {system-property('xsl:product-name')} {system-property('xsl:product-version')}</xsl:comment>	  
	</xsl:template>
	
</xsl:stylesheet>