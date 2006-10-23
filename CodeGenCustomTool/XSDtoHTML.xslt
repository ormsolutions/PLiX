<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE stylesheet [
	<!ENTITY nbsp "<xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text>">
]>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:exsl="http://exslt.org/common"
	exclude-result-prefixes="xs"
	extension-element-prefixes="exsl">
	<xsl:output method="html" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" encoding="utf-8" omit-xml-declaration="no"/>
	<xsl:param name="TypeLinkDecorator" select="'_Type'"/>
	<xsl:param name="WriteGeneratedBy" select="false()"/>
	<xsl:variable name="TargetNamespace" select="string(/xs:schema/@targetNamespace)"/>
	<xsl:template name="WriteName" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="IsType" select="false()"/>
		<xsl:param name="NamePrefix" select="''"/>
		<xsl:param name="Reference" select="false()"/>
		<xsl:param name="WriteMultiplicity" select="false()"/>
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:param name="MinOccurs"/>
		<xsl:param name="MaxOccurs"/>
		<xsl:if test="string-length(@name)+string-length(@ref)">
			<b>
				<xsl:choose>
					<xsl:when test="string-length(@name)">
						<xsl:variable name="nameDecorator">
							<xsl:if test="$IsType">
								<xsl:value-of select="$TypeLinkDecorator"/>
							</xsl:if>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="not($Reference) and (parent::xs:schema or not(parent::*))">
								<a id="{@name}{$nameDecorator}">
									<xsl:value-of select="$NamePrefix"/>
									<xsl:value-of select="@name"/>
								</a>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$NamePrefix"/>
								<xsl:value-of select="@name"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<a href="#{@ref}">
							<xsl:value-of select="@ref"/>
						</a>
					</xsl:otherwise>
				</xsl:choose>
			</b>
			<xsl:if test="string-length(@type)">
				<xsl:text> (</xsl:text>
				<xsl:call-template name="RenderTypeReference"/>
				<xsl:if test="string-length(@use)">
					<xsl:text>, </xsl:text>
					<xsl:value-of select="@use"/>
				</xsl:if>
				<xsl:if test="string-length(@default)">
					<xsl:text>, default=</xsl:text>
					<xsl:value-of select="@default"/>
				</xsl:if>
				<xsl:text>)</xsl:text>
			</xsl:if>
			<xsl:if test="$WriteMultiplicity">
				<xsl:call-template name="RenderMultiplicity">
					<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:variable name="localDocumentationFragment">
				<xsl:apply-templates select="xs:annotation/xs:documentation"/>
			</xsl:variable>
			<xsl:variable name="localDocumentation" select="string($localDocumentationFragment)"/>
			<xsl:choose>
				<xsl:when test="$localDocumentation">
					<xsl:text>: </xsl:text>
					<xsl:value-of select="$localDocumentation"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="fallbackDocumentationFragment">
						<xsl:if test="@type">
							<xsl:choose>
								<xsl:when test="$GlobalComplexTypes">
									<xsl:apply-templates select="$GlobalComplexTypes[@name=current()/@type]/xs:annotation/xs:documentation"/>
								</xsl:when>
								<!-- UNDONE: Need to hand simple type references as well -->
							</xsl:choose>
						</xsl:if>
					</xsl:variable>
					<xsl:variable name="fallbackDocumentation" select="string($fallbackDocumentationFragment)"/>
					<xsl:if test="$fallbackDocumentation">
						<xsl:text>: </xsl:text>
						<xsl:value-of select="$fallbackDocumentation"/>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderTypeReference">
		<xsl:param name="QName" select="string(@type)"/>
		<xsl:param name="ContextNamespaces" select="namespace::*"/>
		<xsl:variable name="prefix" select="substring-before($QName,':')"/>
		<xsl:choose>
			<xsl:when test="$TargetNamespace=string($ContextNamespaces[local-name()=$prefix])">
				<xsl:variable name="localNameFragment">
					<xsl:choose>
						<xsl:when test="$prefix">
							<xsl:value-of select="substring($QName,string-length($prefix)+2)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$QName"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="localName" select="string($localNameFragment)"/>
				<a href="#{$localName}{$TypeLinkDecorator}">
					<xsl:value-of select="$localName" />
				</a>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$QName"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="/" xmlns="http://www.w3.org/1999/xhtml">
		<html>
			<head>
				<style type="text/css">
					body {font-family:verdana; font-size:smaller;}
					.targetNamespaceHeader {font-size:smaller; font-weight:400;}
					.mainHeader {font-size:large;text-align:center;}
					.tableSimpleType {border-collapse:collapse; width:94%; border-color:#000000;border-style:solid;border-width:1px;}
					.trSimpleType {font-weight:700; text-align:center; background-color:#000000; color:#FFFFFF;}
					.unit {border-style: solid; border-width: 1px; border-color: lightgrey;}
					.comment {font-family:courier new; color:#008000;}
				</style>
				<xsl:for-each select="xs:schema">
					<title>
						<xsl:if test="@id">
							<xsl:value-of select="@id"/>
							<xsl:text> </xsl:text>
						</xsl:if>
						<xsl:text>Schema: </xsl:text>
						<xsl:value-of select="@targetNamespace"/>
					</title>					
				</xsl:for-each>
			</head>
			<body>
				<xsl:apply-templates/>
				<xsl:if test="$WriteGeneratedBy">
					<p>
						<span class="comment">
							<xsl:text><![CDATA[//------------------------------------------------------------------------------]]></xsl:text>
							<br />
							<xsl:text><![CDATA[// <autogenerated>]]></xsl:text>
							<br />
							<xsl:text><![CDATA[//     This document was generated by XSDtoHTML.xslt]]></xsl:text>
							<br />
							<xsl:text><![CDATA[//     and must be regenerated if the XSD changes.]]></xsl:text>
							<br />
							<xsl:text><![CDATA[// </autogenerated>]]></xsl:text>
							<br />
							<xsl:text><![CDATA[//------------------------------------------------------------------------------]]></xsl:text>
							<br />
						</span>
					</p>
				</xsl:if>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="xs:schema" xmlns="http://www.w3.org/1999/xhtml">
		<h3 class="mainHeader">
			<xsl:value-of select="@id"/> Schema<br/><span class="targetNamespaceHeader">
				<xsl:value-of select="@targetNamespace"/>
			</span>
		</h3>
		<xsl:variable name="complexTypes" select="xs:complexType"/>
		<xsl:variable name="collatedComplexTypesFragment">
			<xsl:if test="$complexTypes">
				<xsl:apply-templates select="$complexTypes" mode="collate">
					<xsl:with-param name="GlobalComplexTypes" select="$complexTypes"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="collatedComplexTypes" select="exsl:node-set($collatedComplexTypesFragment)/child::*"/>
		<xsl:variable name="elements" select="xs:element"/>
		<xsl:if test="$elements">
			<h4 id="Elements_Header">
				<xsl:text>Elements</xsl:text>
				<span style="font-size:smaller">&nbsp;&nbsp;(<a href="#ComplexTypes_Header">Complex Types</a>,&nbsp;<a href="#SimpleTypes_Header">Simple Types</a>)</span>
			</h4>
			<ul>
				<xsl:apply-templates select="$elements">
					<xsl:sort select="@name"/>
					<xsl:with-param name="GlobalComplexTypes" select="$collatedComplexTypes"/>
				</xsl:apply-templates>
			</ul>
		</xsl:if>
		<xsl:if test="$complexTypes">
			<xsl:variable name="collapsedComplexTypesFragment">
				<xsl:apply-templates select="$collatedComplexTypes" mode="collapse"/>
			</xsl:variable>
			<xsl:variable name="collapsedComplexTypes" select="exsl:node-set($collapsedComplexTypesFragment)/child::*"/>
			<h4 id="ComplexTypes_Header">
				<xsl:text>Complex Types</xsl:text>
				<span style="font-size:smaller">&nbsp;&nbsp;(<a href="#Elements_Header">Elements</a>,&nbsp;<a href="#SimpleTypes_Header">Simple Types</a>)</span>
			</h4>
			<ul>
				<!--<xsl:apply-templates select="$complexTypes">
					<xsl:sort select="@name"/>
					<xsl:with-param name="GlobalComplexTypes" select="$complexTypes"/>
				</xsl:apply-templates>-->
				<!--<xsl:apply-templates select="$collatedComplexTypes">
					<xsl:sort select="@name"/>
					<xsl:with-param name="GlobalComplexTypes" select="$collatedComplexTypes"/>
				</xsl:apply-templates>-->
				<xsl:apply-templates select="$collapsedComplexTypes">
					<xsl:sort select="@name"/>
					<xsl:with-param name="GlobalComplexTypes" select="$collapsedComplexTypes"/>
				</xsl:apply-templates>
			</ul>
		</xsl:if>
		<xsl:variable name="simpleTypes" select="xs:simpleType"/>
		<xsl:if test="$simpleTypes">
			<h4 id="SimpleTypes_Header">
				<xsl:text>Simple Types</xsl:text>
				<span style="font-size:smaller">&nbsp;&nbsp;(<a href="#Elements_Header">Elements</a>,&nbsp;<a href="#ComplexTypes_Header">Complex Types</a>)</span>
			</h4>
			<ul style="list-style-type:none;">
				<xsl:apply-templates select="$simpleTypes">
					<xsl:sort select="@name"/>
				</xsl:apply-templates>
			</ul>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderSimpleType" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="InlineType" select="false()"/>
		<table border="1" class="tableSimpleType">
			<tr class="trSimpleType">
				<td colspan="2">
					<xsl:choose>
						<xsl:when test="$InlineType">
							<xsl:text>(inlineType)</xsl:text>
							<xsl:if test="xs:annotation/xs:documentation">
								<xsl:text>: </xsl:text>
								<xsl:apply-templates select="xs:annotation/xs:documentation"/>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="WriteName">
								<xsl:with-param name="IsType" select="true()"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</td>
			</tr>
			<xsl:apply-templates select="xs:restriction/xs:enumeration | xs:union | xs:list" />
		</table>
	</xsl:template>
	<xsl:template match="xs:simpleType[@name]" xmlns="http://www.w3.org/1999/xhtml">
		<li>
			<xsl:call-template name="RenderSimpleType"/>
		</li>
	</xsl:template>
	<xsl:template match="xs:simpleType" xmlns="http://www.w3.org/1999/xhtml">
		<ul>
			<li>
				<xsl:call-template name="RenderSimpleType"/>
			</li>
		</ul>
	</xsl:template>
	<xsl:template match="xs:union" xmlns="http://www.w3.org/1999/xhtml">
		<tr>
			<td colspan="2">
				<xsl:text>Match a valid value from any of the following types:</xsl:text>
			</td>
		</tr>
		<xsl:variable name="memberTypesFragment">
			<xsl:call-template name="ParseList">
				<xsl:with-param name="ListValues" select="@memberTypes"/>
			</xsl:call-template>
		</xsl:variable>
		<tr>
			<td colspan="2">
				<ul>
					<xsl:variable name="contextNamespaces" select="namespace::*"/>
					<xsl:for-each select="exsl:node-set($memberTypesFragment)/child::*">
						<li>
							<xsl:call-template name="RenderTypeReference">
								<xsl:with-param name="QName" select="string(.)"/>
								<xsl:with-param name="ContextNamespaces" select="$contextNamespaces"/>
							</xsl:call-template>
						</li>
					</xsl:for-each>
					<xsl:for-each select="xs:simpleType">
						<li>
							<xsl:call-template name="RenderSimpleType">
								<xsl:with-param name="InlineType" select="true()"/>
							</xsl:call-template>
						</li>
					</xsl:for-each>
				</ul>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="xs:list" xmlns="http://www.w3.org/1999/xhtml">
		<tr>
			<td colspan="2">
				<xsl:text>A space-delimited list of values from:</xsl:text>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<ul>
					<xsl:for-each select="@itemType">
						<li>
							<xsl:call-template name="RenderTypeReference">
								<xsl:with-param name="QName" select="string(.)"/>
							</xsl:call-template>
						</li>
					</xsl:for-each>
					<xsl:for-each select="xs:simpleType">
						<li>
							<xsl:call-template name="RenderSimpleType">
								<xsl:with-param name="InlineType" select="true()"/>
							</xsl:call-template>
						</li>
					</xsl:for-each>
				</ul>
			</td>
		</tr>
	</xsl:template>
	<xsl:template name="ParseList">
		<xsl:param name="ListValues"/>
		<xsl:call-template name="ParseListHelper">
			<xsl:with-param name="ListValues" select="normalize-space($ListValues)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="ParseListHelper">
		<xsl:param name="ListValues"/>
		<!-- Run after the string has been normalized -->
		<xsl:variable name="beforeSpace" select="substring-before($ListValues, ' ')"/>
		<xsl:choose>
			<xsl:when test="$beforeSpace">
				<listItem>
					<xsl:value-of select="$beforeSpace"/>
				</listItem>
				<xsl:call-template name="ParseListHelper">
					<xsl:with-param name="ListValues" select="substring($ListValues,string-length($beforeSpace)+2)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<listItem>
					<xsl:value-of select="$ListValues"/>
				</listItem>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:complexType[@name]" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:if test="not(@abstract='true' or @abstract='1')">
			<xsl:variable name="contentsFragment">
				<xsl:call-template name="PopulateComplexType">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="contents" select="exsl:node-set($contentsFragment)/child::*"/>
			<li>
				<xsl:call-template name="WriteName">
					<xsl:with-param name="IsType" select="true()"/>
				</xsl:call-template>
				<xsl:if test="$contents">
					<ul>
					<xsl:copy-of select="$contents"/>
				</ul>
				</xsl:if>
			</li>
		</xsl:if>
	</xsl:template>
	<xsl:template match="xs:complexType[@name]" mode="collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:call-template name="PopulateComplexType_Collate">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="xs:complexType">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:variable name="contentsFragment">
			<xsl:call-template name="PopulateComplexType">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="contents" select="exsl:node-set($contentsFragment)/child::*"/>
		<xsl:if test="$contents">
			<ul>
				<xsl:copy-of select="$contents"/>
			</ul>
		</xsl:if>
	</xsl:template>
	<xsl:template match="xs:complexType" mode="collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:call-template name="PopulateComplexType_Collate">
			<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="PopulateComplexType">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:variable name="extensionContentsFragment">
			<xsl:apply-templates select="xs:complexContent/xs:extension">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="extensionContents" select="exsl:node-set($extensionContentsFragment)/child::*"/>
		<!-- Note the xs:element here is not standard xsd, but supports the collapsed form we generate earlier -->
		<xsl:variable name="childElements" select="xs:element | xs:sequence | xs:choice | xs:all | xs:group"/>
		<xsl:variable name="childAttributes" select="xs:attribute | xs:attributeGroup"/>
		<xsl:if test="$childElements or $childAttributes or $extensionContents">
			<xsl:apply-templates select="$childAttributes"/>
			<xsl:copy-of select="$extensionContents"/>
			<xsl:apply-templates select="$childElements">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<xsl:template name="PopulateComplexType_Collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:variable name="extensionContentsFragment">
			<xsl:apply-templates select="xs:complexContent/xs:extension" mode="collate">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="extensionContents" select="exsl:node-set($extensionContentsFragment)/child::*"/>
		<xsl:variable name="localAnnotations" select="xs:annotation"/>
		<xsl:variable name="childElements" select="xs:sequence | xs:choice | xs:all | xs:group"/>
		<xsl:variable name="childAttributes" select="xs:attribute | xs:attributeGroup"/>
		<xsl:variable name="hasLocalContents" select="boolean($childElements) or boolean($childAttributes)"/>
		<xsl:choose>
			<xsl:when test="$extensionContents">
				<xsl:choose>
					<xsl:when test="$hasLocalContents">
						<xsl:choose>
							<xsl:when test="$childElements">
								<xsl:variable name="nonAttributeExtensions" select="$extensionContents[not(self::xs:attribute | self::xs:annotation)]"/>
								<xsl:choose>
									<xsl:when test="$nonAttributeExtensions">
										<xsl:call-template name="CollateAnnotations">
											<xsl:with-param name="PrimaryAnnotations" select="$localAnnotations"/>
											<xsl:with-param name="FallbackAnnotations" select="$extensionContents[self::xs:annotation]"/>
										</xsl:call-template>
										<xs:sequence minOccurs="1" maxOccurs="1">
											<xsl:copy-of select="nonAttributeExtensions"/>
											<xsl:apply-templates select="$childElements" mode="collate">
												<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
											</xsl:apply-templates>
										</xs:sequence>
									</xsl:when>
									<xsl:otherwise>
										<xsl:call-template name="CollateAnnotations">
											<xsl:with-param name="PrimaryAnnotations" select="$localAnnotations"/>
											<xsl:with-param name="FallbackAnnotations" select="$extensionContents[self::xs:annotation]"/>
										</xsl:call-template>
										<xsl:apply-templates select="$childElements" mode="collate">
											<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
										</xsl:apply-templates>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:copy-of select="$extensionContents[self::xs:attribute]"/>
								<xsl:apply-templates select="$childAttributes" mode="collate"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="CollateAnnotations">
									<xsl:with-param name="PrimaryAnnotations" select="$localAnnotations"/>
									<xsl:with-param name="FallbackAnnotations" select="$extensionContents[self::xs:annotation]"/>
								</xsl:call-template>
								<xsl:copy-of select="$extensionContents[not(self::xs:annotation)]"/>
								<xsl:apply-templates select="$childAttributes" mode="collate"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="CollateAnnotations">
							<xsl:with-param name="PrimaryAnnotations" select="$localAnnotations"/>
							<xsl:with-param name="FallbackAnnotations" select="$extensionContents[self::xs:annotation]"/>
						</xsl:call-template>
						<xsl:copy-of select="$extensionContents[not(self::xs:annotation)]"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$localAnnotations"/>
				<xsl:apply-templates select="$childElements" mode="collate">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="$childAttributes" mode="collate"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="CollateAnnotations">
		<xsl:param name="PrimaryAnnotations"/>
		<xsl:param name="FallbackAnnotations"/>
		<xsl:choose>
			<xsl:when test="$PrimaryAnnotations">
				<xsl:choose>
					<xsl:when test="$FallbackAnnotations">
						<xsl:variable name="primaryDocumentation" select="string($PrimaryAnnotations/xs:documentation)"/>
						<xsl:variable name="fallbackDocumentation" select="string($FallbackAnnotations/xs:documentation)"/>
						<!-- Make sure we only get one documentation tag, makes the rest of this file easier -->
						<xs:annotation>
							<xsl:if test="$primaryDocumentation or $fallbackDocumentation">
								<xs:documentation>
									<xsl:choose>
										<xsl:when test="$primaryDocumentation">
											<xsl:value-of select="$primaryDocumentation"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$fallbackDocumentation"/>
										</xsl:otherwise>
									</xsl:choose>
								</xs:documentation>
							</xsl:if>
							<xsl:copy-of select="$PrimaryAnnotations/xs:appinfo"/>
							<xsl:copy-of select="$FallbackAnnotations/xs:appinfo"/>
						</xs:annotation>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$PrimaryAnnotations"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$FallbackAnnotations">
				<xsl:copy-of select="$FallbackAnnotations"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:complexContent/xs:extension">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:for-each select="$GlobalComplexTypes[@name=current()/@base]">
			<xsl:call-template name="PopulateComplexType">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:call-template name="PopulateComplexType">
			<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xs:complexContent/xs:extension" mode="collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:variable name="baseContentsFragment">
			<xsl:for-each select="$GlobalComplexTypes[@name=current()/@base]">
				<xsl:call-template name="PopulateComplexType_Collate">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="baseContents" select="exsl:node-set($baseContentsFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="$baseContents">
				<xsl:variable name="localContentsFragment">
					<xsl:call-template name="PopulateComplexType_Collate">
						<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="localContents" select="exsl:node-set($localContentsFragment)/child::*"/>
				<xsl:choose>
					<xsl:when test="$localContents">
						<xsl:variable name="localElements" select="$localContents[not(self::xs:attribute | self::xs:annotation)]"/>
						<xsl:choose>
							<xsl:when test="$localElements">
								<xsl:variable name="baseElements" select="$baseContents[not(self::xs:attribute | self::xs:annotation)]"/>
								<xsl:copy-of select="$baseContents[self::xs:annotation]"/>
								<xsl:copy-of select="$localContents[self::xs:annotation]"/>
								<xsl:choose>
									<xsl:when test="$baseElements">
										<xs:sequence minOccurs="1" maxOccurs="1">
											<xsl:copy-of select="$baseElements"/>
											<xsl:copy-of select="$localElements"/>
										</xs:sequence>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="$localElements"/>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:copy-of select="$baseContents[self::xs:attribute]"/>
								<xsl:copy-of select="$localContents[self::xs:attribute]"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy-of select="$baseContents"/>
								<xsl:copy-of select="$localContents[self::xs:attribute]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$baseContents"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="PopulateComplexType_Collate">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:group">
		<xsl:param name="Referred" select="false()"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xsl:apply-templates select="/xs:schema/xs:group[@name=current()/@ref]">
					<xsl:with-param name="Referred" select="true()"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="$Referred">
				<xsl:apply-templates select="xs:choice | xs:sequence | xs:all"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:group" mode="collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:param name="Referred" select="false()"/>
		<xsl:param name="MinOccurs"/>
		<xsl:param name="MaxOccurs"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xsl:apply-templates select="/xs:schema/xs:group[@name=current()/@ref]" mode="collate">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
					<xsl:with-param name="Referred" select="true()"/>
					<xsl:with-param name="MinOccurs" select="@minOccurs"/>
					<xsl:with-param name="MaxOccurs" select="@maxOccurs"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="$Referred">
				<xsl:apply-templates select="xs:choice | xs:sequence | xs:all" mode="collate">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
					<xsl:with-param name="Referred" select="true()"/>
					<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
				</xsl:apply-templates>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:element" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:param name="Referred" select="false()"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xsl:apply-templates select="/xs:schema/xs:element[@name=current()/@ref]">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
					<xsl:with-param name="Referred" select="true()"/>
					<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not(@abstract='true' or @abstract='1')">
					<li>
						<xsl:call-template name="WriteName">
							<xsl:with-param name="Reference" select="$Referred"/>
							<xsl:with-param name="WriteMultiplicity" select="true()"/>
							<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
							<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
							<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
						</xsl:call-template>
						<xsl:variable name="nestedComplexType" select="xs:complexType"/>
						<xsl:choose>
							<xsl:when test="$nestedComplexType">
								<xsl:variable name="collatedNestedFragment">
									<xsl:apply-templates select="$nestedComplexType" mode="collate">
										<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
									</xsl:apply-templates>
								</xsl:variable>
								<xsl:variable name="collapsedNestedFragment">
									<xsl:apply-templates select="exsl:node-set($collatedNestedFragment)/child::*" mode="collapse">
										<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
									</xsl:apply-templates>
								</xsl:variable>
								<xsl:variable name="collapsedNested" select="exsl:node-set($collapsedNestedFragment)/child::*"/>
								<xsl:if test="$collapsedNested">
									<ul>
										<xsl:apply-templates select="$collapsedNested">
											<xsl:with-param name="Referred" select="true()"/>
											<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
										</xsl:apply-templates>
									</ul>
								</xsl:if>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates select="xs:simpleType">
									<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
								</xsl:apply-templates>
							</xsl:otherwise>
						</xsl:choose>
					</li>
				</xsl:if>
				<xsl:if test="$Referred">
					<xsl:apply-templates select="/xs:schema/xs:element[@substitutionGroup=current()/@name]">
						<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
						<xsl:with-param name="Referred" select="true()"/>
						<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
						<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
					</xsl:apply-templates>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:element" mode="collate">
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:param name="Referred" select="false()"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xs:choice>
					<xsl:choose>
						<xsl:when test="$Referred">
							<xsl:call-template name="EnsureMinMaxOccursAttributes">
								<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
								<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="EnsureMinMaxOccursAttributes"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:variable name="dummyFragment">
						<!-- MinOccurs and MaxOccurs need to be actual attributes, not numbers. Construct a fragment to accomodate -->
						<dummy minOccurs="1" maxOccurs="1"/>
					</xsl:variable>
					<xsl:variable name="dummy" select="exsl:node-set($dummyFragment)/child::*"/>
					<xsl:apply-templates select="/xs:schema/xs:element[@name=current()/@ref]" mode="collate">
						<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
						<xsl:with-param name="Referred" select="true()"/>
						<xsl:with-param name="MinOccurs" select="$dummy/@minOccurs"/>
						<xsl:with-param name="MaxOccurs" select="$dummy/@maxOccurs"/>
					</xsl:apply-templates>
				</xs:choice>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not(@abstract='true' or @abstract='1')">
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<xsl:choose>
							<xsl:when test="$Referred">
								<xsl:call-template name="EnsureMinMaxOccursAttributes">
									<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
									<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="EnsureMinMaxOccursAttributes"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:apply-templates select="xs:complexType | xs:simpleType" mode="collate">
							<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
						</xsl:apply-templates>
					</xsl:copy>
				</xsl:if>
				<xsl:if test="$Referred">
					<xsl:apply-templates select="/xs:schema/xs:element[@substitutionGroup=current()/@name]" mode="collate">
						<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
						<xsl:with-param name="Referred" select="true()"/>
						<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
						<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
					</xsl:apply-templates>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:annotation/xs:documentation">
		<xsl:value-of select="." />
	</xsl:template>
	<xsl:template match="xs:annotation" mode="collate">
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template match="xs:restriction/xs:enumeration" xmlns="http://www.w3.org/1999/xhtml">
		<tr>
			<td>
				<xsl:value-of select="@value"/>
			</td>
			<td style="width:100%;">
				<xsl:apply-templates select="xs:annotation/xs:documentation"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="xs:any" xmlns="http://www.w3.org/1999/xhtml">
		<li>
			<b>
				<xsl:value-of select="@namespace"/>
			</b>
		</li>
	</xsl:template>
	<xsl:template match="xs:any" mode="collate">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="_sortPriority">
				<xsl:text>2</xsl:text>
			</xsl:attribute>
			<xsl:call-template name="EnsureMinMaxOccursAttributes"/>
			<xsl:copy-of select="*|text()"/>
		</xsl:copy>
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template name="EnsureMinMaxOccursAttributes">
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:choose>
			<xsl:when test="$MinOccurs">
				<xsl:copy-of select="$MinOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="minOccurs">
					<xsl:text>1</xsl:text>
				</xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="$MaxOccurs">
				<xsl:copy-of select="$MaxOccurs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="maxOccurs">
					<xsl:text>1</xsl:text>
				</xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderMultiplicity">
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:choose>
			<xsl:when test="$MinOccurs=0">
				<xsl:choose>
					<xsl:when test="not($MaxOccurs) or $MaxOccurs=1">
						<xsl:text> (optional)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> (optional, repeat</xsl:text>
						<xsl:if test="not($MaxOccurs='unbounded')">
							<xsl:text> at most </xsl:text>
							<xsl:value-of select="$MaxOccurs"/>
							<xsl:text> times</xsl:text>
						</xsl:if>
						<xsl:text>)</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="not($MinOccurs) or $MinOccurs='1'">
				<xsl:choose>
					<xsl:when test="not($MaxOccurs) or $MaxOccurs=1">
						<!-- Nothing for required -->
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> (repeat</xsl:text>
						<xsl:if test="not($MaxOccurs='unbounded')">
							<xsl:text> at most </xsl:text>
							<xsl:value-of select="$MaxOccurs"/>
							<xsl:text> times</xsl:text>
						</xsl:if>
						<xsl:text>)</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$MaxOccurs=$MinOccurs">
						<xsl:text> (repeat </xsl:text>
						<xsl:value-of select="$MinOccurs"/>
						<xsl:text> times)</xsl:text>
					</xsl:when>
					<xsl:when test="$MaxOccurs='unbounded'">
						<xsl:text> (repeat at least </xsl:text>
						<xsl:value-of select="$MinOccurs"/>
						<xsl:text> times)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> (repeat </xsl:text>
						<xsl:value-of select="$MinOccurs"/>
						<xsl:text> to </xsl:text>
						<xsl:value-of select="$MaxOccurs"/>
						<xsl:text> times)</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:sequence" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="GlobalComplexTypes"/>
		<li class="unit">
			<xsl:text>Sequence</xsl:text>
			<xsl:call-template name="RenderMultiplicity"/>
			<ul>
				<xsl:apply-templates select="xs:element | xs:any | xs:choice | xs:sequence | xs:group">
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:apply-templates>
			</ul>
		</li>
	</xsl:template>
	<xsl:template match="xs:choice" xmlns="http://www.w3.org/1999/xhtml">
		<xsl:param name="GlobalComplexTypes"/>
		<li class="unit">
			<xsl:text>Choose One</xsl:text>
			<xsl:call-template name="RenderMultiplicity"/>
			<ul>
				<xsl:apply-templates select="xs:element | xs:any | xs:choice | xs:sequence | xs:group">
					<xsl:sort select="@_sortPriority" data-type="number"/>
					<xsl:sort select="@name"/>
					<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
				</xsl:apply-templates>
			</ul>
		</li>
	</xsl:template>
	<xsl:template match="xs:sequence | xs:choice | xs:all | xs:attribute" mode="collate">
		<xsl:param name="Referred" select="false()"/>
		<xsl:param name="MinOccurs"/>
		<xsl:param name="MaxOccurs"/>
		<xsl:param name="GlobalComplexTypes"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:choose>
				<xsl:when test="$Referred">
					<xsl:call-template name="EnsureMinMaxOccursAttributes">
						<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
						<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="EnsureMinMaxOccursAttributes"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="child::*" mode="collate">
				<xsl:with-param name="GlobalComplexTypes" select="$GlobalComplexTypes"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="xs:attribute" xmlns="http://www.w3.org/1999/xhtml">
		<li>
			<xsl:call-template name="WriteName">
				<xsl:with-param name="NamePrefix" select="'@'"/>
			</xsl:call-template>
		</li>
	</xsl:template>
	<xsl:template match="xs:attributeGroup">
		<xsl:param name="Referred" select="false()"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xsl:apply-templates select="/xs:schema/xs:attributeGroup[@name=current()/@ref]">
					<xsl:with-param name="Referred" select="true()"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="$Referred">
				<xsl:apply-templates select="xs:attribute | xs:attributeGroup"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:attributeGroup" mode="collate">
		<xsl:param name="Referred" select="false()"/>
		<xsl:choose>
			<xsl:when test="@ref">
				<xsl:apply-templates select="/xs:schema/xs:attributeGroup[@name=current()/@ref]" mode="collate">
					<xsl:with-param name="Referred" select="true()"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="$Referred">
				<xsl:apply-templates select="xs:attribute | xs:attributeGroup" mode="collate"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="*" mode="collapse">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="node()" mode="collapse"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="xs:sequence" mode="collapse">
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:param name="InChoice" select="false()"/>
		<xsl:param name="InOptionalChoice" select="false()"/>
		<xsl:param name="InOneChoice" select="false()"/>
		<xsl:variable name="children" select="child::*[not(self::xs:annotation)]"/>
		<xsl:choose>
			<xsl:when test="count($children)=1">
				<xsl:call-template name="CollapseSingleChildCompositor">
					<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
					<xsl:with-param name="InChoice" select="$InChoice"/>
					<xsl:with-param name="InOptionalChoice" select="$InOptionalChoice"/>
					<xsl:with-param name="InOneChoice" select="$InOneChoice"/>
					<xsl:with-param name="Child" select="$children[1]"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($InChoice) and $MinOccurs=1 and $MaxOccurs=1">
				<xsl:apply-templates select="child::*"  mode="collapse"/>
			</xsl:when>
			<xsl:when test="$MinOccurs=0 and $MaxOccurs=1 and count($children[@minOccurs=0])=count($children)">
				<!-- optional sequence with all optional children, collapse -->
				<xsl:apply-templates select="child::*"  mode="collapse"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Include this compositor with any overriden min/max values passed in from above -->
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:attribute name="_sortPriority">
						<xsl:text>2</xsl:text>
					</xsl:attribute>
					<xsl:copy-of select="$MinOccurs"/>
					<xsl:copy-of select="$MaxOccurs"/>
					<xsl:apply-templates select="child::*" mode="collapse"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:choice" mode="collapse">
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:param name="InOptionalChoice" select="false()"/>
		<xsl:param name="InOneChoice" select="false()"/>
		<xsl:param name="InChoice" select="false()"/>
		<xsl:variable name="children" select="child::*[not(self::xs:annotation)]"/>
		<xsl:choose>
			<xsl:when test="count($children)=1">
				<xsl:call-template name="CollapseSingleChildCompositor">
					<xsl:with-param name="MinOccurs" select="$MinOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$MaxOccurs"/>
					<xsl:with-param name="Child" select="$children[1]"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="($InChoice or $InOptionalChoice or $InOneChoice) and $MinOccurs=1 and $MaxOccurs=1">
				<xsl:apply-templates select="child::*" mode="collapse">
					<xsl:with-param name="InChoice" select="true()"/>
					<xsl:with-param name="InOptionalChoice" select="$InOptionalChoice"/>
					<xsl:with-param name="InOneChoice" select="$InOneChoice"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- Include this compositor with any overriden min/max values passed in from above -->
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:attribute name="_sortPriority">
						<xsl:text>3</xsl:text>
					</xsl:attribute>
					<xsl:copy-of select="$MinOccurs"/>
					<xsl:copy-of select="$MaxOccurs"/>
					<xsl:apply-templates select="child::*" mode="collapse">
						<xsl:with-param name="InChoice" select="true()"/>
						<xsl:with-param name="InOptionalChoice" select="$MinOccurs=0"/>
						<xsl:with-param name="InOneChoice" select="$MinOccurs=1 and $MaxOccurs=1"/>
					</xsl:apply-templates>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xs:element" mode="collapse">
		<xsl:param name="MinOccurs" select="@minOccurs"/>
		<xsl:param name="MaxOccurs" select="@maxOccurs"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="_sortPriority">
				<xsl:text>0</xsl:text>
			</xsl:attribute>
			<xsl:copy-of select="$MinOccurs"/>
			<xsl:copy-of select="$MaxOccurs"/>
			<xsl:apply-templates select="child::*" mode="collapse"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template name="CollapseSingleChildCompositor">
		<xsl:param name="MinOccurs"/>
		<xsl:param name="MaxOccurs"/>
		<xsl:param name="InChoice"/>
		<xsl:param name="InOptionalChoice"/>
		<xsl:param name="InOneChoice"/>
		<xsl:param name="Child"/>
		<xsl:variable name="currentMin" select="number($MinOccurs)"/>
		<xsl:variable name="currentMax" select="string($MaxOccurs)"/>
		<xsl:variable name="childMin" select="number($Child/@minOccurs)"/>
		<xsl:variable name="childMax" select="string($Child/@maxOccurs)"/>
		<xsl:variable name="dummyFragment">
			<!-- Collect minOccurs/maxOccurs attributes on a dummy node. Both must be present
				 to continue with collapse. -->
			<dummy>
				<xsl:choose>
					<xsl:when test="$currentMin=0">
						<xsl:choose>
							<xsl:when test="$childMin=0 or $childMin=1">
								<!-- pick up 0 min -->
								<xsl:copy-of select="$MinOccurs"/>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="minOccurs">
							<xsl:value-of select="$currentMin * $childMin"/>
						</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$currentMax=1">
						<xsl:copy-of select="$Child/@maxOccurs"/>
					</xsl:when>
					<xsl:when test="$currentMax='unbounded'">
						<xsl:choose>
							<xsl:when test="$childMax=1 or $childMax='unbounded'">
								<!-- pick up unbounded max -->
								<xsl:copy-of select="$MaxOccurs"/>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$childMax=1">
								<!-- pick up parent max -->
								<xsl:copy-of select="$MaxOccurs"/>
							</xsl:when>
							<xsl:when test="$childMax='unbounded'">
								<xsl:copy-of select="$Child/@maxOccurs"/>
							</xsl:when>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</dummy>
		</xsl:variable>
		<xsl:variable name="dummy" select="exsl:node-set($dummyFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="count($dummy/@*)=2">
				<!-- Skip the compositor but pick up the children with new
					 min/max values -->
				<xsl:apply-templates select="child::*" mode="collapse">
					<xsl:with-param name="MinOccurs" select="$dummy/@minOccurs"/>
					<xsl:with-param name="MaxOccurs" select="$dummy/@maxOccurs"/>
					<xsl:with-param name="InChoice" select="$InChoice"/>
					<xsl:with-param name="InOptionalChoice" select="$InOptionalChoice"/>
					<xsl:with-param name="InOneChoice" select="$InOneChoice"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- Include this compositor with any overriden min/max values passed in from above -->
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:copy-of select="$MinOccurs"/>
					<xsl:copy-of select="$MaxOccurs"/>
					<xsl:apply-templates select="child::*" mode="collapse">
						<xsl:with-param name="InChoice" select="self::xs:choice"/>
						<xsl:with-param name="InOptionalChoice" select="self::xs:choice and $MinOccurs=0"/>
						<xsl:with-param name="InOneChoice" select="self::xs:choice and $MinOccurs=1 and $MaxOccurs=1"/>
					</xsl:apply-templates>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>