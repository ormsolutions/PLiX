<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Neumont PLiX (Programming Language in XML) Code Generator

	Copyright © Neumont University. All rights reserved.

	The use and distribution terms for this software are covered by the
	Common Public License 1.0 (http://opensource.org/licenses/cpl) which
	can be found in the file CPL.txt at the root of this distribution.
	By using this software in any fashion, you are agreeing to be bound by
	the terms of this license.

	You must not remove this notice, or any other, from this software.
-->
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:plx="http://schemas.neumont.edu/CodeGeneration/PLiX"
	xmlns:plxGen="urn:local-plix-generator" 
	exclude-result-prefixes="#default exsl plx xs">
	<!--
	******************************************************************
	An inline schema for all intermediate types used in the standard
	plix generator. This allows language files importing this file
	to easily add extension elements that are automatically formatted
	using the standard code here
	******************************************************************
	-->
	<xs:schema
		targetNamespace="urn:local-plix-generator"
		attributeFormDefault="unqualified"
		elementFormDefault="qualified">
		<xs:simpleType name="indentationStyleValues">
			<xs:annotation>
				<xs:documentation>Information for each element used in the formatting process.</xs:documentation>
			</xs:annotation>
			<xs:restriction base="xs:string">
				<xs:enumeration value="block">
					<xs:annotation>
						<xs:documentation>A block with indented children and a close element.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blockDecorator">
					<xs:annotation>
						<xs:documentation>An child element that is processed by the formatter as part of rendering a block but is not written directly as a child element.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blockMember">
					<xs:annotation>
						<xs:documentation>A block with indented children and a close element that is also a member element.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blockSibling">
					<xs:annotation>
						<xs:documentation>An element that is rendered as a sibling of the block containing it.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blockWithNestedSiblings">
					<xs:annotation>
						<xs:documentation>A block with indented children and a close element. Some of the child elements can be blockSibling elements.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blockWithSecondarySiblings">
					<xs:annotation>
						<xs:documentation>A block with indent children and a close element. Trailing sibling elements can be secondaryBlock elements.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="nakedBlock">
					<xs:annotation>
						<xs:documentation>An element that acts like a block in that it contains elements for its parent block, but does not imply additional indentation.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="nakedIndentedBlock">
					<xs:annotation>
						<xs:documentation>A block with indented children but no open/close tags. closeBlockCallback is supported.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="secondaryBlock">
					<xs:annotation>
						<xs:documentation>An element that is rendered as the sibling to a previous block element.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="simple">
					<xs:annotation>
						<xs:documentation>A simple expression.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="simpleMember">
					<xs:annotation>
						<xs:documentation>A simple member. Process leading/trailing info.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
				<xs:enumeration value="blankLine">
					<xs:annotation>
						<xs:documentation>A blank line. Used for rendering blank line comments.</xs:documentation>
					</xs:annotation>
				</xs:enumeration>
			</xs:restriction>
		</xs:simpleType>
		<xs:element name="indentInfo">
			<xs:complexType>
				<xs:attribute name="style" type="plxGen:indentationStyleValues"/>
				<xs:attribute name="closeWith" type="xs:string" use="optional">
					<xs:annotation>
						<xs:documentation>The close text for this element. If this is not specified, then the default language block close tag will be used for block or blockMember styles. Naked blocks are not closed.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="statementClose" type="xs:string" use="optional">
					<xs:annotation>
						<xs:documentation>Provide an alternate statement close for simple elements. Defaults to the defaultStatementClose attribute on languageInfo.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="closeBlockCallback" type="xs:boolean" use="optional">
					<xs:annotation>
						<xs:documentation>Set to true if a template with the CloseBlock mode should be called for the element after its children are rendered. The template will be called with the output stream indented to the block level. The custom callback should finish with a &lt;xsl:value-of select="$NewLine"/&gt;. If the style is nakedIndentedBlock, then the stream is not pre-indented and the provided Indent level is the indent level of the children, not the current element.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<!-- Additional attributes here should have corresponding parameters in the CustomizeIndentInfo template below -->
			</xs:complexType>
		</xs:element>
		<xs:element name="languageInfo">
			<xs:complexType>
				<xs:attribute name="defaultBlockClose" type="xs:string">
					<xs:annotation>
						<xs:documentation>The default block close for the language. Used as the default setting for the indentInfo closeWith attribute.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="beforeSecondaryBlockOpen" type="xs:string">
					<xs:annotation>
						<xs:documentation>Provide a string to place before a secondary block. This is used after closing a block before rendering the secondary element. Indentation will not be applied if this is set.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="blockOpen" type="xs:string">
					<xs:annotation>
						<xs:documentation>The block open for the language. Use newLineBeforeBlockOpen for new line control, do not include it here.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="newLineBeforeBlockOpen">
					<xs:annotation>
						<xs:documentation>A new line is always associated with opening a block. Should an additional new line be included before writing the block open?</xs:documentation>
					</xs:annotation>
					<xs:simpleType>
						<xs:restriction base="xs:token">
							<xs:enumeration value="yes"/>
							<xs:enumeration value="no"/>
						</xs:restriction>
					</xs:simpleType>
				</xs:attribute>
				<xs:attribute name="defaultStatementClose" type="xs:string">
					<xs:annotation>
						<xs:documentation>The default close character for simple elements.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="requireCaseLabels">
					<xs:annotation>
						<xs:documentation>Do case labels need to be automatically generated to support the gotoCase element?</xs:documentation>
					</xs:annotation>
					<xs:simpleType>
						<xs:restriction base="xs:token">
							<xs:enumeration value="yes"/>
							<xs:enumeration value="no"/>
						</xs:restriction>
					</xs:simpleType>
				</xs:attribute>
				<xs:attribute name="expandInlineStatements">
					<xs:annotation>
						<xs:documentation>Are one or more inline statement types not natively support by the language?</xs:documentation>
					</xs:annotation>
					<xs:simpleType>
						<xs:restriction base="xs:token">
							<xs:enumeration value="yes"/>
							<xs:enumeration value="no"/>
						</xs:restriction>
					</xs:simpleType>
				</xs:attribute>
				<xs:attribute name="autoVariablePrefix" type="xs:string">
					<xs:annotation>
						<xs:documentation>The prefix used for the name of fields and locals auto-generated to handled inline expansions. Required if expandInlineStatements is set.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="comment" type="xs:string">
					<xs:annotation>
						<xs:documentation>The character sequence for a line comment</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="docComment" type="xs:string">
					<xs:annotation>
						<xs:documentation>The character sequence for a documentation comment line</xs:documentation>
					</xs:annotation>
				</xs:attribute>
			</xs:complexType>
		</xs:element>
		<xs:element name="caseLabel">
			<xs:annotation>
				<xs:documentation>Used if languageInfo/@requireCaseLabels is yes. Contains a matching condition and label for each case that is referenced by a gotoCase in the same switch scope. A collection of caseLabel elements is passed to all language-specific formatters that request it. The key attribute corresponds to the LocalItemKey parameter sent to the case statement.</xs:documentation>
			</xs:annotation>
			<xs:complexType>
				<xs:attribute name="condition" type="xs:string">
					<xs:annotation>
						<xs:documentation>The rendered condition. The rendering for a gotoCase condition must match a case condition in the same switch context.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="key" type="xs:string">
					<xs:annotation>
						<xs:documentation>The key for the matching case. Corresponds to the LocalItemKey param passed to the language-specific formatter.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
			</xs:complexType>
		</xs:element>
		<xs:element name="inlineExpansion">
			<xs:annotation>
				<xs:documentation>Used if languageInfo/@expandInlineStatements is yes. Contains the expansion of an inlineStatement and the surrogate expression that replaces it inline.</xs:documentation>
			</xs:annotation>
			<xs:complexType>
				<xs:all>
					<xs:element name="expansion">
						<xs:annotation>
							<xs:documentation>The expansion of the inline contents</xs:documentation>
						</xs:annotation>
						<xs:complexType>
							<xs:choice minOccurs="1" maxOccurs="unbounded">
								<xs:any namespace="##any" processContents="skip"/>
							</xs:choice>
						</xs:complexType>
					</xs:element>
					<xs:element name="surrogate">
						<xs:annotation>
							<xs:documentation>The expression to replace the inline statement</xs:documentation>
						</xs:annotation>
						<xs:complexType>
							<xs:sequence>
								<xs:any namespace="##any" processContents="skip"/>
							</xs:sequence>
						</xs:complexType>
					</xs:element>
				</xs:all>
				<xs:attribute name="key" type="xs:string" use="required">
					<xs:annotation>
						<xs:documentation>A unique key used to decorate generated variables.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="childrenModified" type="xs:boolean" default="false">
					<xs:annotation>
						<xs:documentation>By default, the assumption is made that child elements of an inline-expanded element are unchanged, and the surrogate does not need to copy the child elements that are not block decorators (used for render). If other children are modified, then set this to true to render all of the provided children instead of the children of the unmodified element.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
				<xs:attribute name="surrogatePreExpanded" type="xs:boolean" default="false">
					<xs:annotation>
						<xs:documentation>By default, the expanded item is processed using the ReplaceInline mode to replace expanded constructs with their surrogates. Alternately, the surrogate can be used as the expansion if this option is set. Ignored if more than one inlineExpansion is returned during CollectInline mode.</xs:documentation>
					</xs:annotation>
				</xs:attribute>
			</xs:complexType>
		</xs:element>
		<xs:attribute name="dontClose" type="xs:anySimpleType">
			<xs:annotation>
				<xs:documentation>Don't close the current block. Currently used to support leadingInfo and trailingInfo during secondary block inline statement expansion.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
	</xs:schema>

	<!--
	*******************************
	Externally definable parameters
	*******************************
	-->
	<xsl:param name="IndentWith" select="'&#x9;'"/>
	<xsl:param name="StartIndent" select="0"/>
	<xsl:param name="NewLine" select="'&#xD;&#xA;'"/>

	<!--
	***********************************************
	Helper functions for use by language formatters
	***********************************************
	-->
	<!-- Customize indent info. Used to extend default settings from this file. Language
		 formatters should always use this call to customize language info settings
		 so that we are free to add additional values in this file as needed. The
		 following is a sample use, changing the namespace close tag to 'End Namespace'.
	<xsl:template match="plx:namespace" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="closeWith" select="'End Namespace'"/>
		</xsl:call-template>
	</xsl:template>
	-->
	<xsl:template name="CustomizeIndentInfo">
		<xsl:param name="defaultInfo"/>
		<xsl:param name="style"/>
		<xsl:param name="closeWith"/>
		<xsl:param name="closeBlockCallback"/>
		<xsl:param name="statementClose"/>
		<xsl:param name="statementNotClosed"/>
		<xsl:for-each select="exsl:node-set($defaultInfo)/child::*">
			<xsl:copy>
				<xsl:copy-of select="@*"/>
				<xsl:if test="$style">
					<xsl:attribute name="style">
						<xsl:value-of select="$style"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$closeWith">
					<xsl:attribute name="closeWith">
						<xsl:value-of select="$closeWith"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$statementNotClosed">
						<xsl:attribute name="statementClose">
							<xsl:value-of select="''"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="$statementClose">
							<xsl:attribute name="statementClose">
								<xsl:value-of select="$statementClose"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="$closeBlockCallback">
							<xsl:attribute name="closeBlockCallback">
								<xsl:value-of select="$closeBlockCallback"/>
							</xsl:attribute>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:copy>
		</xsl:for-each>
	</xsl:template>
	<!--
	*******************
	Standard processing
	*******************
	-->
	<xsl:preserve-space elements="plx:string plxGen:languageInfo"/>
	<xsl:variable name="SingleIndent" select="$IndentWith"/>
	<xsl:variable name="LanguageInfoFragment">
		<xsl:apply-templates select="." mode="LanguageInfo"/>
	</xsl:variable>
	<xsl:variable name="LanguageInfo" select="exsl:node-set($LanguageInfoFragment)/child::*"/>
	<xsl:variable name="DefaultBlockClose" select="$LanguageInfo/@defaultBlockClose"/>
	<xsl:variable name="BeforeSecondaryBlockOpen" select="$LanguageInfo/@beforeSecondaryBlockOpen"/>
	<xsl:variable name="DefaultStatementClose" select="$LanguageInfo/@defaultStatementClose"/>
	<xsl:variable name="Comment" select="$LanguageInfo/@comment"/>
	<xsl:variable name="DocComment" select="$LanguageInfo/@docComment"/>
	<xsl:variable name="BlockOpen" select="$LanguageInfo/@blockOpen"/>
	<xsl:variable name="NewLineBeforeBlockOpen" select="'yes'=$LanguageInfo/@newLineBeforeBlockOpen"/>
	<xsl:variable name="RequireCaseLabels" select="'yes'=$LanguageInfo/@requireCaseLabels"/>
	<xsl:variable name="ExpandInlineStatements" select="'yes'=$LanguageInfo/@expandInlineStatements"/>
	<xsl:variable name="GeneratedVariablePrefix" select="$LanguageInfo/@autoVariablePrefix"/>
	<xsl:template match="/">
		<xsl:variable name="baseIndent">
			<xsl:call-template name="GetBaseIndent"/>
		</xsl:variable>
		<xsl:apply-templates select="child::*" mode="TopLevel">
			<xsl:with-param name="Indent" select="string($baseIndent)"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template name="GetBaseIndent">
		<xsl:param name="Remaining" select="floor($StartIndent)"/>
		<xsl:param name="CurrentIndent" select="''"/>
		<xsl:choose>
			<xsl:when test="$Remaining &gt; 0">
				<xsl:call-template name="GetBaseIndent">
					<xsl:with-param name="Remaining" select="$Remaining - 1"/>
					<xsl:with-param name="CurrentIndent" select="concat($CurrentIndent,$SingleIndent)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$CurrentIndent"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:root" mode="TopLevel">
		<xsl:param name="Indent"/>
		<xsl:for-each select="child::*">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Statement" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:left|plx:right|plx:callObject|plx:condition|plx:initialize|plx:beforeLoop|plx:initializeLoop" mode="TopLevel">
		<xsl:param name="Indent"/>
		<!-- Pass through common container children for snippet support, each has a single child expression -->
		<xsl:for-each select="child::*">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:leadingInfo|plx:trailingInfo|plx:blockLeadingInfo|plx:blockTrailingInfo" mode="TopLevel">
		<xsl:param name="Indent"/>
		<!-- Pass through common container children for snippet support, render as statement to support multiple elements -->
		<xsl:for-each select="child::*">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Statement" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="*" mode="TopLevel">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderElement">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="TopLevel" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:inlineStatement">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="CaseLabels"/>
		<xsl:apply-templates select="child::*[last()]">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="*">
		<xsl:text>UNRENDERED-</xsl:text>
		<xsl:value-of select="local-name()"/>
		<!--<xsl:message terminate="no">
			<xsl:text>The '</xsl:text>
			<xsl:value-of select="name()"/>
			<xsl:text>' element must be handled by the language formatter.</xsl:text>
		</xsl:message>-->
	</xsl:template>
	<xsl:template match="plx:comment">
		<xsl:value-of select="$Comment"/>
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="plx:docComment">
		<xsl:param name="Indent"/>
		<xsl:variable name="NextIndent" select="concat($Indent,$DocComment)"/>
		<xsl:variable name="NextLine" select="concat($NewLine,$NextIndent)"/>
		<!-- The assumption is made that all doc comments are in xml tags -->
		<!-- UNDONE: Support spitting code examples in other languages -->
		<xsl:for-each select="child::*">
			<xsl:choose>
				<xsl:when test="position()=1">
					<xsl:value-of select="$DocComment"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$NextLine"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="." mode="RenderDocComment">
				<xsl:with-param name="Indent" select="$NextIndent"/>
				<xsl:with-param name="NextLine" select="$NextLine"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="RenderRawString">
		<!-- Get the raw, unescaped contents of a string element-->
		<xsl:variable name="childStrings" select="plx:string"/>
		<xsl:choose>
			<xsl:when test="$childStrings">
				<xsl:for-each select="$childStrings">
					<xsl:call-template name="RenderRawString"/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="data" select="@data"/>
				<xsl:choose>
					<xsl:when test="$data">
						<xsl:value-of select="$data"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="*" mode="RenderDocComment">
		<xsl:param name="Indent"/>
		<xsl:param name="NextLine"/>
		<xsl:variable name="children" select="child::*|text()"/>
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:for-each select="@*">
			<xsl:text> </xsl:text>
			<xsl:value-of select="name()"/>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>"</xsl:text>
		</xsl:for-each>
		<xsl:choose>
			<xsl:when test="$children">
				<xsl:text>&gt;</xsl:text>
				<xsl:apply-templates select="child::*|text()" mode="RenderDocComment">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="NextLine" select="$NextLine"/>
				</xsl:apply-templates>
				<xsl:text>&lt;/</xsl:text>
				<xsl:value-of select="local-name()"/>
				<xsl:text>&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>/&gt;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:*" mode="RenderDocComment">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderElement">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="SkipLeadingIndent" select="true()"/>
			<!-- UNDONE: Not everything that passes here is necessarily a statement.
			For example, <plx:falseKeyword/> will render as 'false;' in C#. Add an
			'AutoStatement' mode where the statement/simple expression choice is made
			automatically. In the mean time, this is mostly used for code samples, so
			we'll default to include the statement -->
			<xsl:with-param name="Statement" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="text()" mode="RenderDocComment">
		<xsl:param name="NextLine"/>
		<xsl:call-template name="RenderDocCommentString">
			<xsl:with-param name="NextLine" select="$NextLine"/>
			<xsl:with-param name="String" select="string(.)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="RenderDocCommentString">
		<xsl:param name="NextLine"/>
		<xsl:param name="String"/>
		<!-- UNDONE: Find a better way to normalize carriage returns -->
		<xsl:if test="string-length($String)">
			<xsl:choose>
				<xsl:when test="contains($String,'&#xa;') or contains($String,'&#xd;')">
					<xsl:variable name="firstChar" select="substring($String,1,1)"/>
					<xsl:variable name="firstTwoChars" select="substring($String,1,2)"/>
					<xsl:choose>
						<xsl:when test="'&#xd;&#xa;'=$firstTwoChars or '&#xa;&#xd;'=$firstTwoChars">
							<xsl:value-of select="$NextLine"/>
							<xsl:call-template name="RenderDocCommentString">
								<xsl:with-param name="String" select="substring($String,3)"/>
								<xsl:with-param name="NextLine" select="$NextLine"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="'&#xd;'=$firstChar or '&#xa;'=$firstChar">
							<xsl:value-of select="$NextLine"/>
							<xsl:call-template name="RenderDocCommentString">
								<xsl:with-param name="String" select="substring($String,2)"/>
								<xsl:with-param name="NextLine" select="$NextLine"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="before1" select="substring-before($String,'&#xd;&#xa;')"/>
							<xsl:choose>
								<xsl:when test="string-length($before1)">
									<xsl:value-of select="$before1"/>
									<xsl:value-of select="$NextLine"/>
									<xsl:call-template name="RenderDocCommentString">
										<xsl:with-param name="String" select="substring($String,string-length($before1)+3)"/>
										<xsl:with-param name="NextLine" select="$NextLine"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:variable name="before2" select="substring-before($String,'&#xa;&#xd;')"/>
									<xsl:choose>
										<xsl:when test="string-length($before2)">
											<xsl:value-of select="$before2"/>
											<xsl:value-of select="$NextLine"/>
											<xsl:call-template name="RenderDocCommentString">
												<xsl:with-param name="String" select="substring($String,string-length($before2)+3)"/>
												<xsl:with-param name="NextLine" select="$NextLine"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:otherwise>
											<xsl:variable name="before3" select="substring-before($String,'&#xa;')"/>
											<xsl:choose>
												<xsl:when test="string-length($before3)">
													<xsl:value-of select="$before3"/>
													<xsl:value-of select="$NextLine"/>
													<xsl:call-template name="RenderDocCommentString">
														<xsl:with-param name="String" select="substring($String,string-length($before3)+2)"/>
														<xsl:with-param name="NextLine" select="$NextLine"/>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
													<xsl:variable name="before4" select="substring-before($String,'&#xd;')"/>
													<xsl:choose>
														<xsl:when test="string-length($before4)">
															<xsl:value-of select="$before4"/>
															<xsl:value-of select="$NextLine"/>
															<xsl:call-template name="RenderDocCommentString">
																<xsl:with-param name="String" select="substring($String,string-length($before4)+2)"/>
																<xsl:with-param name="NextLine" select="$NextLine"/>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="$String"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$String"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template match="*" mode="CloseBlock">
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:text>UNRENDERED_CUSTOM_CLOSE-</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:value-of select="$NewLine"/>
		<!--<xsl:message terminate="no">
			<xsl:text>The language handler specified a CloseBlock callback for '</xsl:text>
			<xsl:value-of select="name()"/>
			<xsl:text>' but did not define a template with the CloseBlock mode for an element with this type.</xsl:text>
		</xsl:message>-->
	</xsl:template>
	<xsl:template name="RenderElement">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Statement" select="false()"/>
		<xsl:param name="CaseLabels"/>
		<xsl:param name="SkipLeadingIndent" select="false()"/>
		<xsl:param name="TopLevel" select="false()"/>
		<xsl:variable name="indentInfoFragment">
			<xsl:choose>
				<xsl:when test="$TopLevel">
					<xsl:apply-templates select="." mode="TopLevelIndentInfo"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="." mode="IndentInfo"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="indentInfo" select="exsl:node-set($indentInfoFragment)/child::*"/>
		<xsl:variable name="indentStyle" select="string($indentInfo/@style)"/>
		<xsl:choose>
			<xsl:when test="$ExpandInlineStatements and not($indentStyle='secondaryBlock')">
				<xsl:variable name="inlineLocalItemKey" select="concat($LocalItemKey,'_',position(),'ex')"/>
				<xsl:variable name="inlineExpansionsFragment">
					<xsl:apply-templates select="." mode="CollectInline">
						<xsl:with-param name="LocalItemKey" select="$inlineLocalItemKey"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="inlineExpansions" select="exsl:node-set($inlineExpansionsFragment)/child::*"/>
				<xsl:choose>
					<xsl:when test="$inlineExpansions">
						<!-- The gist of the next block is shown here, but we need to get all expansion child at one shot
						so we can support skipping the first indent. Therefore, we back up from the children to the
						inline expansion key to get the key value.
						<xsl:for-each select="$inlineExpansions">
							<xsl:variable name="inlineExpansionKey" select="@key"/>
							<xsl:for-each select="plxGen:expansion/child::*">
								<xsl:call-template name="RenderElement">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="LocalItemKey" select="$inlineExpansionKey"/>
									<xsl:with-param name="Statement" select="$Statement"/>
									<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
								</xsl:call-template>
							</xsl:for-each>
						</xsl:for-each>
						-->
						<!-- Recurse to RenderElement to pick up nested inline statements -->
						<xsl:variable name="leadingExpansions" select="$inlineExpansions/plxGen:expansion/child::*"/>
						<xsl:for-each select="$leadingExpansions">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$Indent"/>
								<xsl:with-param name="LocalItemKey" select="../../@key"/>
								<xsl:with-param name="Statement" select="true()"/>
								<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
								<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent and position()=1"/>
							</xsl:call-template>
						</xsl:for-each>
						<xsl:variable name="preExpandedSurrogate" select="count($inlineExpansions)=1 and $inlineExpansions/@surrogatePreExpanded='true'"/>
						<xsl:variable name="modifiedFragment">
							<xsl:if test="not($preExpandedSurrogate)">
								<xsl:apply-templates select="." mode="ReplaceInline">
									<xsl:with-param name="LocalItemKey" select="$inlineLocalItemKey"/>
									<xsl:with-param name="Expansions" select="$inlineExpansions"/>
								</xsl:apply-templates>
							</xsl:if>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="count($inlineExpansions)=1 and $inlineExpansions/@childrenModified='true'">
								<xsl:variable name="currentPosition" select="position()"/>
								<xsl:choose>
									<xsl:when test="$preExpandedSurrogate">
										<xsl:for-each select="$inlineExpansions/plxGen:surrogate/child::*">
											<xsl:call-template name="RenderElementWithIndentInfo">
												<xsl:with-param name="Indent" select="$Indent"/>
												<xsl:with-param name="Statement" select="$Statement"/>
												<xsl:with-param name="CurrentPosition" select="$currentPosition"/>
												<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
												<xsl:with-param name="IndentInfo" select="$indentInfo"/>
												<xsl:with-param name="IndentStyle" select="$indentStyle"/>
												<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
												<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent and position()=1"/>
											</xsl:call-template>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="exsl:node-set($modifiedFragment)/child::*">
											<xsl:call-template name="RenderElementWithIndentInfo">
												<xsl:with-param name="Indent" select="$Indent"/>
												<xsl:with-param name="Statement" select="$Statement"/>
												<xsl:with-param name="CurrentPosition" select="$currentPosition"/>
												<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
												<xsl:with-param name="IndentInfo" select="$indentInfo"/>
												<xsl:with-param name="IndentStyle" select="$indentStyle"/>
												<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
												<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent and position()=1"/>
											</xsl:call-template>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$preExpandedSurrogate">
								<!-- Same as otherwise except ModifiedElement doesn't require another node-set -->
								<xsl:call-template name="RenderElementWithIndentInfo">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="Statement" select="$Statement"/>
									<xsl:with-param name="ModifiedElement" select="$inlineExpansions/plxGen:surrogate/child::*"/>
									<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
									<xsl:with-param name="IndentInfo" select="$indentInfo"/>
									<xsl:with-param name="IndentStyle" select="$indentStyle"/>
									<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
									<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<!-- Same as later otherwise clauses except for passing ModifiedElement -->
								<xsl:call-template name="RenderElementWithIndentInfo">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="Statement" select="$Statement"/>
									<xsl:with-param name="ModifiedElement" select="exsl:node-set($modifiedFragment)/child::*"/>
									<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
									<xsl:with-param name="IndentInfo" select="$indentInfo"/>
									<xsl:with-param name="IndentStyle" select="$indentStyle"/>
									<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
									<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<!-- Same as later otherwise -->
						<xsl:call-template name="RenderElementWithIndentInfo">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="$Statement"/>
							<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
							<xsl:with-param name="IndentInfo" select="$indentInfo"/>
							<xsl:with-param name="IndentStyle" select="$indentStyle"/>
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
							<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- Same as earlier otherwise -->
				<xsl:call-template name="RenderElementWithIndentInfo">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Statement" select="$Statement"/>
					<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
					<xsl:with-param name="IndentInfo" select="$indentInfo"/>
					<xsl:with-param name="IndentStyle" select="$indentStyle"/>
					<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
					<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderElementWithIndentInfo">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey" select="''"/>
		<xsl:param name="Statement" select="false()"/>
		<xsl:param name="ModifiedElement"/>
		<xsl:param name="ProcessSecondaryBlock" select="false()"/>
		<xsl:param name="CurrentPosition" select="position()"/>
		<xsl:param name="IndentInfo"/>
		<xsl:param name="IndentStyle"/>
		<xsl:param name="CaseLabels"/>
		<xsl:param name="SkipLeadingIndent" select="false()"/>
		<!-- A leadBlock may have siblings and has no leading or trailing info associated with it -->
		<xsl:variable name="leadBlock" select="$IndentStyle='block' or $IndentStyle='blockWithNestedSiblings' or $IndentStyle='blockWithSecondarySiblings'"/>
		<xsl:variable name="nextLocalItemKeyFragment">
			<xsl:if test="$IndentStyle!='blockMember'">
				<xsl:value-of select="$LocalItemKey"/>
				<xsl:text>_</xsl:text>
				<xsl:value-of select="$CurrentPosition"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="nextLocalItemKey" select="string($nextLocalItemKeyFragment)"/>
		<xsl:choose>
			<xsl:when test="not($ProcessSecondaryBlock) and $IndentStyle='secondaryBlock'"/>
			<xsl:when test="$leadBlock or $IndentStyle='blockMember' or $IndentStyle='nakedIndentedBlock'">
				<xsl:variable name="updateCaseLabels" select="$RequireCaseLabels and self::plx:switch"/>
				<xsl:variable name="caseLabelsFragment">
					<xsl:if test="$updateCaseLabels">
						<xsl:variable name="requiredCaseConditionsFragment">
							<xsl:apply-templates select="child::*" mode="GotoCaseConditions"/>
						</xsl:variable>
						<!-- Note: This xpath is order n(n-1), but there should not be enough gotoCase conditions to matter -->
						<xsl:variable name="requiredCaseConditions" select="exsl:node-set($requiredCaseConditionsFragment)/child::*[not(following-sibling::*/@condition=@condition)]"/>
						<xsl:if test="$requiredCaseConditions">
							<!-- UNDONE: PLiX is missing support for goto default, need a label for fallbackCase as well -->
							<!-- for-each all children so we get consistent LocalItemKey values. Filtered with xsl:if instead of xpath -->
							<xsl:for-each select="child::*">
								<xsl:if test="self::plx:case">
									<xsl:variable name="casePosition" select="position()"/>
									<xsl:for-each select="plx:condition/child::plx:*">
										<xsl:variable name="renderedCondition">
											<xsl:apply-templates select=".">
												<xsl:with-param name="Indent" select="''"/>
											</xsl:apply-templates>
										</xsl:variable>
										<xsl:for-each select="$requiredCaseConditions[@condition=string($renderedCondition)]">
											<plxGen:caseLabel condition="{@condition}" key="{$nextLocalItemKey}_{$casePosition}"/>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:if>
							</xsl:for-each>
						</xsl:if>
					</xsl:if>
				</xsl:variable>
				<xsl:variable name="newCaseLabels" select="exsl:node-set($caseLabelsFragment)/child::*[not(following-sibling::*/@condition=@condition)]"/>
				<xsl:variable name="hasInfo" select="not($leadBlock)"/>
				<xsl:variable name="isNakedIndent" select="$IndentStyle='nakedIndentedBlock'"/>
				<xsl:if test="$hasInfo">
					<xsl:for-each select="(plx:leadingInfo | plx:blockLeadingInfo)/child::plx:*">
						<xsl:call-template name="RenderElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="true()"/>
							<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent and position()=1"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:if test="not($SkipLeadingIndent)">
					<xsl:value-of select="$Indent"/>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$ModifiedElement">
						<xsl:apply-templates select="$ModifiedElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<!-- The next case labels don't apply until we're inside the switch scope, so always
						 use the original case labels here. -->
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select=".">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<!-- The next case labels don't apply until we're inside the switch scope, so always
						 use the original case labels here. -->
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$isNakedIndent">
						<xsl:value-of select="$NewLine"/>
					</xsl:when>
					<xsl:when test="string-length($BlockOpen)">
						<xsl:if test="$NewLineBeforeBlockOpen">
							<xsl:value-of select="$NewLine"/>
							<xsl:value-of select="$Indent"/>
						</xsl:if>
						<xsl:value-of select="$BlockOpen"/>
						<xsl:value-of select="$NewLine"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$NewLine"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
				<xsl:choose>
					<!-- These two blocks are exactly the same except for the CaseLabels with-param values -->
					<xsl:when test="$updateCaseLabels">
						<xsl:for-each select="child::*">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$nextIndent"/>
								<xsl:with-param name="Statement" select="true()"/>
								<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
								<xsl:with-param name="CaseLabels" select="$newCaseLabels"/>
							</xsl:call-template>
							<xsl:if test="position()=last() and $IndentStyle='blockWithNestedSiblings'">
								<xsl:for-each select="plx:blockTrailingInfo/child::*">
									<xsl:call-template name="RenderElement">
										<xsl:with-param name="Indent" select="$Indent"/>
										<xsl:with-param name="Statement" select="true()"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:if>
						</xsl:for-each>
						<xsl:if test="$IndentStyle='blockWithSecondarySiblings'">
							<xsl:call-template name="RenderSecondaryBlocks">
								<xsl:with-param name="Indent" select="$nextIndent"/>
								<xsl:with-param name="PreviousIndent" select="$Indent"/>
								<xsl:with-param name="ParentLocalItemKey" select="$LocalItemKey"/>
								<xsl:with-param name="LeadBlockPosition" select="$CurrentPosition"/>
								<xsl:with-param name="CaseLabels" select="$newCaseLabels"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="child::*">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$nextIndent"/>
								<xsl:with-param name="Statement" select="true()"/>
								<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
								<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
							</xsl:call-template>
							<xsl:if test="position()=last() and $IndentStyle='blockWithNestedSiblings'">
								<xsl:for-each select="plx:blockTrailingInfo/child::*">
									<xsl:call-template name="RenderElement">
										<xsl:with-param name="Indent" select="$Indent"/>
										<xsl:with-param name="Statement" select="true()"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:if>
						</xsl:for-each>
						<xsl:if test="$IndentStyle='blockWithSecondarySiblings'">
							<xsl:call-template name="RenderSecondaryBlocks">
								<xsl:with-param name="Indent" select="$nextIndent"/>
								<xsl:with-param name="PreviousIndent" select="$Indent"/>
								<xsl:with-param name="ParentLocalItemKey" select="$LocalItemKey"/>
								<xsl:with-param name="LeadBlockPosition" select="$CurrentPosition"/>
								<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="standardCloseWith">
					<xsl:choose>
						<xsl:when test="$isNakedIndent">
							<xsl:value-of select="''"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="customCloseWith" select="$IndentInfo/@closeWith"/>
							<xsl:choose>
								<xsl:when test="string-length($customCloseWith)">
									<xsl:value-of select="$customCloseWith"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$DefaultBlockClose"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="closeWithCallback" select="$IndentInfo/@closeBlockCallback"/>
				<xsl:choose>
					<xsl:when test="@plxGen:dontClose"/>
					<xsl:when test="$closeWithCallback='true' or $closeWithCallback='1'">
						<xsl:choose>
							<xsl:when test="$isNakedIndent">
								<xsl:apply-templates select="." mode="CloseBlock">
									<xsl:with-param name="Indent" select="$nextIndent"/>
								</xsl:apply-templates>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$Indent"/>
								<xsl:apply-templates select="." mode="CloseBlock">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="StandardCloseWith" select="string($standardCloseWith)"/>
								</xsl:apply-templates>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="not($isNakedIndent)">
						<xsl:value-of select="$Indent"/>
						<xsl:value-of select="string($standardCloseWith)"/>
						<xsl:value-of select="$NewLine"/>
					</xsl:when>
				</xsl:choose>
				<xsl:if test="$hasInfo">
					<xsl:for-each select="(plx:trailingInfo | plx:blockTrailingInfo)/child::plx:*">
						<xsl:call-template name="RenderElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="true()"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:if test="$SkipLeadingIndent">
					<xsl:value-of select="$Indent"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$IndentStyle='simpleMember' or $IndentStyle='simple'">
				<xsl:variable name="hasInfo" select="$IndentStyle='simpleMember'"/>
				<xsl:if test="$hasInfo">
					<xsl:for-each select="plx:leadingInfo/child::plx:*">
						<xsl:call-template name="RenderElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="true()"/>
							<xsl:with-param name="SkipLeadingIndent" select="$SkipLeadingIndent and position()=1"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:if test="not($SkipLeadingIndent)">
					<xsl:value-of select="$Indent"/>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$ModifiedElement">
						<xsl:apply-templates select="$ModifiedElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select=".">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$Statement">
					<xsl:variable name="standardCloseWith">
						<xsl:variable name="customStatementClose" select="$IndentInfo/@statementClose"/>
						<xsl:choose>
							<xsl:when test="$customStatementClose">
								<xsl:value-of select="$customStatementClose"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$DefaultStatementClose"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="closeWithCallback" select="$IndentInfo/@closeBlockCallback"/>
					<xsl:choose>
						<xsl:when test="@plxGen:dontClose"/>
						<xsl:when test="$closeWithCallback='true' or $closeWithCallback='1'">
							<xsl:apply-templates select="." mode="CloseBlock">
								<xsl:with-param name="Indent" select="$Indent"/>
								<xsl:with-param name="StandardCloseWith" select="string($standardCloseWith)"/>
							</xsl:apply-templates>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="string($standardCloseWith)"/>
							<xsl:value-of select="$NewLine"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<xsl:if test="$hasInfo">
					<xsl:for-each select="plx:trailingInfo/child::plx:*">
						<xsl:call-template name="RenderElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="true()"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:if test="$SkipLeadingIndent and $Statement">
					<xsl:value-of select="$Indent"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$IndentStyle='blockSibling' or $IndentStyle='secondaryBlock'">
				<xsl:variable name="previousIndent" select="substring($Indent,1,string-length($Indent)-string-length($SingleIndent))"/>
				<xsl:for-each select="preceding-sibling::*[1]/plx:blockTrailingInfo/child::plx:*">
					<xsl:call-template name="RenderElement">
						<xsl:with-param name="Indent" select="$previousIndent"/>
						<xsl:with-param name="Statement" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:for-each select="plx:blockLeadingInfo/child::plx:*">
					<xsl:call-template name="RenderElement">
						<xsl:with-param name="Indent" select="$previousIndent"/>
						<xsl:with-param name="Statement" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:if test="string-length($DefaultBlockClose)">
					<!-- UNDONE: This is sufficient to handle VB, C#, Java, C++, etc,
						 but there may be problems with other languages -->
					<xsl:value-of select="$previousIndent"/>
					<xsl:value-of select="$DefaultBlockClose"/>
					<xsl:if test="not($BeforeSecondaryBlockOpen)">
						<xsl:value-of select="$NewLine"/>
					</xsl:if>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$BeforeSecondaryBlockOpen">
						<xsl:value-of select="$BeforeSecondaryBlockOpen"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$previousIndent"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$ModifiedElement">
						<xsl:apply-templates select="$ModifiedElement">
							<xsl:with-param name="Indent" select="$previousIndent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select=".">
							<xsl:with-param name="Indent" select="$previousIndent"/>
							<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
							<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="string-length($BlockOpen)">
						<xsl:if test="$NewLineBeforeBlockOpen">
							<xsl:value-of select="$NewLine"/>
							<xsl:value-of select="$previousIndent"/>
						</xsl:if>
						<xsl:value-of select="$BlockOpen"/>
						<xsl:value-of select="$NewLine"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$NewLine"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each select="child::*">
					<xsl:call-template name="RenderElement">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="Statement" select="true()"/>
						<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
						<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$IndentStyle='nakedBlock'">
				<xsl:for-each select="child::*">
					<xsl:call-template name="RenderElement">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="Statement" select="$Statement"/>
						<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
						<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$IndentStyle='blankLine'">
				<xsl:value-of select="$NewLine"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderSecondaryBlocks">
		<xsl:param name="Indent"/>
		<xsl:param name="PreviousIndent"/>
		<xsl:param name="Siblings" select="following-sibling::*"/>
		<xsl:param name="SiblingIndex" select="1"/>
		<xsl:param name="ParentLocalItemKey"/>
		<xsl:param name="LeadBlockPosition"/>
		<xsl:param name="CaseLabels"/>
		<xsl:variable name="currentSibling" select="$Siblings[$SiblingIndex]"/>
		<xsl:choose>
			<xsl:when test="$currentSibling">
				<xsl:for-each select="$Siblings[$SiblingIndex]">
					<xsl:variable name="indentInfoFragment">
						<xsl:apply-templates select="." mode="IndentInfo"/>
					</xsl:variable>
					<xsl:variable name="indentInfo" select="exsl:node-set($indentInfoFragment)/child::*"/>
					<xsl:variable name="indentStyle" select="string($indentInfo/@style)"/>
					<xsl:choose>
						<xsl:when test="$indentStyle='secondaryBlock'">
							<xsl:choose>
								<xsl:when test="$ExpandInlineStatements">
									<xsl:variable name="inlineLocalItemKey" select="concat($ParentLocalItemKey,'_',position(),'ex')"/>
									<xsl:variable name="inlineExpansionsFragment">
										<xsl:apply-templates select="." mode="CollectInline">
											<xsl:with-param name="LocalItemKey" select="$inlineLocalItemKey"/>
										</xsl:apply-templates>
									</xsl:variable>
									<xsl:variable name="inlineExpansions" select="exsl:node-set($inlineExpansionsFragment)/child::*"/>
									<xsl:choose>
										<xsl:when test="$inlineExpansions">
											<xsl:variable name="replacementBlockFragment">
												<plx:dummy>
													<xsl:copy-of select="preceding-sibling::*[1]/plx:blockTrailingInfo"/>
												</plx:dummy>
												<xsl:apply-templates select="." mode="BuildInlineSecondaryBlock">
													<xsl:with-param name="InlineExpansions" select="$inlineExpansions"/>
													<xsl:with-param name="InlineLocalItemKey" select="$inlineLocalItemKey"/>
													<xsl:with-param name="Siblings" select="$Siblings"/>
													<xsl:with-param name="SiblingIndex" select="$SiblingIndex"/>
												</xsl:apply-templates>
											</xsl:variable>
											<xsl:for-each select="exsl:node-set($replacementBlockFragment)/child::*[2]">
												<xsl:variable name="indentInfoModifiedFragment">
													<xsl:apply-templates select="." mode="IndentInfo"/>
												</xsl:variable>
												<xsl:variable name="indentInfoModified" select="exsl:node-set($indentInfoModifiedFragment)/child::*"/>
												<xsl:variable name="indentStyleModified" select="string($indentInfoModified/@style)"/>
												<xsl:call-template name="RenderElementWithIndentInfo">
													<xsl:with-param name="Indent" select="$Indent"/>
													<xsl:with-param name="Statement" select="true()"/>
													<xsl:with-param name="ProcessSecondaryBlock" select="true()"/>
													<xsl:with-param name="CurrentPosition" select="$LeadBlockPosition + $SiblingIndex"/>
													<xsl:with-param name="LocalItemKey" select="$ParentLocalItemKey"/>
													<xsl:with-param name="IndentInfo" select="$indentInfoModified"/>
													<xsl:with-param name="IndentStyle" select="$indentStyleModified"/>
													<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
												</xsl:call-template>
											</xsl:for-each>
										</xsl:when>
										<xsl:otherwise>
											<!-- Same as later otherwise -->
											<xsl:call-template name="RenderElementWithIndentInfo">
												<xsl:with-param name="Indent" select="$Indent"/>
												<xsl:with-param name="Statement" select="true()"/>
												<xsl:with-param name="ProcessSecondaryBlock" select="true()"/>
												<xsl:with-param name="CurrentPosition" select="$LeadBlockPosition + $SiblingIndex"/>
												<xsl:with-param name="LocalItemKey" select="$ParentLocalItemKey"/>
												<xsl:with-param name="IndentInfo" select="$indentInfo"/>
												<xsl:with-param name="IndentStyle" select="$indentStyle"/>
												<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
											</xsl:call-template>
											<xsl:call-template name="RenderSecondaryBlocks">
												<xsl:with-param name="Indent" select="$Indent"/>
												<xsl:with-param name="PreviousIndent" select="$PreviousIndent"/>
												<xsl:with-param name="Siblings" select="$Siblings"/>
												<xsl:with-param name="SiblingIndex" select="$SiblingIndex + 1"/>
												<xsl:with-param name="ParentLocalItemKey" select="$ParentLocalItemKey"/>
												<xsl:with-param name="LeadBlockPosition" select="$LeadBlockPosition"/>
												<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
											</xsl:call-template>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<!-- Same as previous otherwise -->
									<xsl:call-template name="RenderElementWithIndentInfo">
										<xsl:with-param name="Indent" select="$Indent"/>
										<xsl:with-param name="Statement" select="true()"/>
										<xsl:with-param name="ProcessSecondaryBlock" select="true()"/>
										<xsl:with-param name="CurrentPosition" select="$LeadBlockPosition + $SiblingIndex"/>
										<xsl:with-param name="LocalItemKey" select="$ParentLocalItemKey"/>
										<xsl:with-param name="IndentInfo" select="$indentInfo"/>
										<xsl:with-param name="IndentStyle" select="$indentStyle"/>
										<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
									</xsl:call-template>
									<xsl:call-template name="RenderSecondaryBlocks">
										<xsl:with-param name="Indent" select="$Indent"/>
										<xsl:with-param name="PreviousIndent" select="$PreviousIndent"/>
										<xsl:with-param name="Siblings" select="$Siblings"/>
										<xsl:with-param name="SiblingIndex" select="$SiblingIndex + 1"/>
										<xsl:with-param name="ParentLocalItemKey" select="$ParentLocalItemKey"/>
										<xsl:with-param name="LeadBlockPosition" select="$LeadBlockPosition"/>
										<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="$SiblingIndex > 1">
							<xsl:for-each select="$Siblings[$SiblingIndex - 1]/plx:blockTrailingInfo/child::plx:*">
								<xsl:call-template name="RenderElement">
									<xsl:with-param name="Indent" select="$PreviousIndent"/>
									<xsl:with-param name="Statement" select="true()"/>
								</xsl:call-template>
							</xsl:for-each>
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$SiblingIndex > 1">
				<xsl:for-each select="$Siblings[$SiblingIndex - 1]/plx:blockTrailingInfo/child::plx:*">
					<xsl:call-template name="RenderElement">
						<xsl:with-param name="Indent" select="$PreviousIndent"/>
						<xsl:with-param name="Statement" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:alternateBranch" mode="BuildInlineSecondaryBlock">
		<xsl:param name="InlineExpansions"/>
		<xsl:param name="InlineLocalItemKey"/>
		<xsl:param name="Siblings"/>
		<xsl:param  name="SiblingIndex"/>
		<plx:fallbackBranch>
			<xsl:copy-of select="plx:blockLeadingInfo/child::*"/>
			<xsl:copy-of select="$InlineExpansions/plxGen:expansion/child::*"/>
			<xsl:variable name="modifiedElementFragment">
				<xsl:apply-templates select="." mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="$InlineLocalItemKey"/>
					<xsl:with-param name="Expansions" select="$InlineExpansions"/>
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:for-each select="exsl:node-set($modifiedElementFragment)/child::*">
				<plx:branch>
					<xsl:copy-of select="@*|child::*|text()"/>
					<xsl:if test="plx:blockTrailingInfo/child::plx:pragma[@type='closeConditional'] and plx:blockLeadingInfo/child::plx:pragma[@type='conditional' or @type='notConditional' or @type='alternateConditional' or @type='alternateNotConditional']">
						<plx:pragma type="fallbackConditional"/>
						<plx:branch plxGen:dontClose="">
							<plx:condition>
								<plx:falseKeyword/>
							</plx:condition>
						</plx:branch>
					</xsl:if>
				</plx:branch>
			</xsl:for-each>
			<xsl:call-template name="CopySecondaryBlocks">
				<xsl:with-param name="Siblings" select="$Siblings"/>
				<xsl:with-param name="SiblingIndex" select="$SiblingIndex + 1"/>
			</xsl:call-template>
		</plx:fallbackBranch>
	</xsl:template>
	<xsl:template name="CopySecondaryBlocks">
		<xsl:param name="Siblings" select="following-sibling::*"/>
		<xsl:param name="SiblingIndex" select="1"/>
		<xsl:param name="RecursiveCall" select="false()"/>
		<xsl:variable name="nextSibling" select="$Siblings[$SiblingIndex]"/>
		<xsl:choose>
			<xsl:when test="$nextSibling">
				<xsl:for-each select="$nextSibling">
					<xsl:variable name="indentInfoFragment">
						<xsl:apply-templates select="." mode="IndentInfo"/>
					</xsl:variable>
					<xsl:variable name="indentInfo" select="exsl:node-set($indentInfoFragment)/child::*"/>
					<xsl:variable name="indentStyle" select="string($indentInfo/@style)"/>
					<xsl:choose>
						<xsl:when test="$indentStyle='secondaryBlock'">
							<xsl:copy-of select="."/>
							<xsl:call-template name="CopySecondaryBlocks">
								<xsl:with-param name="Siblings" select="$Siblings"/>
								<xsl:with-param name="SiblingIndex" select="$SiblingIndex + 1"/>
								<xsl:with-param name="RecursiveCall" select="true()"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="not($RecursiveCall) and ($SiblingIndex > 1)">
							<xsl:copy-of select="$Siblings[$SiblingIndex - 1]/plx:blockTrailingInfo/child::plx:*"/>
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="not($RecursiveCall) and ($SiblingIndex > 1)">
				<xsl:copy-of select="$Siblings[$SiblingIndex - 1]/plx:blockTrailingInfo/child::plx:*"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!--
	*********************************************************
	Helper templates to determine when explicit case labels are required
	*********************************************************
	-->
	<xsl:template match="*" mode="GotoCaseConditions">
		<xsl:apply-templates select="child::*" mode="GotoCaseConditions"/>
	</xsl:template>
	<xsl:template match="plx:gotoCase" mode="GotoCaseConditions">
		<xsl:variable name="renderedCondition">
			<xsl:apply-templates select="plx:condition/child::plx:*">
				<xsl:with-param name="Indent" select="''"/>
			</xsl:apply-templates>
		</xsl:variable>
		<!-- The element name here doesn't matter, but condition is used in RenderElement -->
		<renderedCaseCondition condition="{$renderedCondition}"/>
	</xsl:template>
	<!-- Don't walk into a nested switch statement -->
	<xsl:template match="plx:switch" mode="GotoCaseConditions"/>

	<!-- 
	*********************************************************
	Modification of indent information for top level elements to improve snippet presentation
	*********************************************************
	-->
	<xsl:template match="*" mode="TopLevelIndentInfo">
		<xsl:variable name="normalIndentInfoFragment">
			<xsl:apply-templates select="." mode="IndentInfo"/>
		</xsl:variable>
		<xsl:variable name="normalIndentInfo" select="exsl:node-set($normalIndentInfoFragment)/child::plxGen:indentInfo"/>
		<xsl:choose>
			<xsl:when test="$normalIndentInfo">
				<xsl:for-each select="$normalIndentInfo">
					<xsl:variable name="style" select="string(@style)"/>
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<xsl:attribute name="style">
							<xsl:choose>
								<xsl:when test="$style='blockDecorator'">
									<xsl:text>simpleMember</xsl:text>
								</xsl:when>
								<xsl:when test="$style='secondaryBlock' or $style='blockSibling'">
									<xsl:text>block</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$style"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:copy-of select="*"/>
					</xsl:copy>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$normalIndentInfoFragment"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- 
	*********************************************************
	Default indentation information for native plix elements
	*********************************************************
	-->
	<xsl:template match="*" mode="IndentInfo">
		<plxGen:indentInfo style="simple"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:namespace | plx:class | plx:structure | plx:interface | plx:enum | plx:property | plx:onAdd | plx:onRemove | plx:onFire | plx:operatorFunction">
		<plxGen:indentInfo style="blockMember"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:get | plx:set">
		<xsl:variable name="isAbstract">
			<xsl:for-each select="parent::plx:property">
				<xsl:choose>
					<xsl:when test="@modifier='abstract'">
						<xsl:text>x</xsl:text>
					</xsl:when>
					<xsl:when test="@modifier='abstractOverride'">
						<xsl:text>x</xsl:text>
					</xsl:when>
					<xsl:when test="parent::plx:interface">
						<xsl:text>x</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<plxGen:indentInfo style="blockMember">
			<xsl:if test="string-length($isAbstract)">
				<xsl:attribute name="style">
					<xsl:text>simpleMember</xsl:text>
				</xsl:attribute>
			</xsl:if>
		</plxGen:indentInfo>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:function">
		<xsl:variable name="isAbstract">
			<xsl:choose>
				<xsl:when test="@modifier='abstract'">
					<xsl:text>x</xsl:text>
				</xsl:when>
				<xsl:when test="@modifier='abstractOverride'">
					<xsl:text>x</xsl:text>
				</xsl:when>
				<xsl:when test="parent::plx:interface">
					<xsl:text>x</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<plxGen:indentInfo style="blockMember">
			<xsl:if test="string-length($isAbstract)">
				<xsl:attribute name="style">
					<xsl:text>simpleMember</xsl:text>
				</xsl:attribute>
			</xsl:if>
		</plxGen:indentInfo>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:event">
		<xsl:variable name="isAbstract">
			<xsl:choose>
				<xsl:when test="@modifier='abstract'">
					<xsl:text>x</xsl:text>
				</xsl:when>
				<xsl:when test="@modifier='abstractOverride'">
					<xsl:text>x</xsl:text>
				</xsl:when>
				<xsl:when test="parent::plx:interface">
					<xsl:text>x</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<plxGen:indentInfo style="blockMember">
			<!-- Testing for onAdd is sufficient here. The schema requires onAdd for the other custom functions -->
			<xsl:if test="string-length($isAbstract) or not(plx:onAdd)">
				<xsl:attribute name="style">
					<xsl:text>simpleMember</xsl:text>
				</xsl:attribute>
			</xsl:if>
		</plxGen:indentInfo>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:field | plx:enumItem | plx:delegate">
		<plxGen:indentInfo style="simpleMember"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:loop | plx:iterator | plx:lock | plx:autoDispose | plx:switch">
		<plxGen:indentInfo style="block"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:branch">
		<plxGen:indentInfo style="blockWithSecondarySiblings"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:try">
		<plxGen:indentInfo style="blockWithNestedSiblings"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:alternateBranch | plx:fallbackBranch">
		<plxGen:indentInfo style="secondaryBlock"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:fallbackCatch | plx:catch | plx:finally">
		<plxGen:indentInfo style="blockSibling"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:case | plx:fallbackCase">
		<plxGen:indentInfo style="nakedIndentedBlock"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:attribute[@type='assembly' or @type='module']">
		<plxGen:indentInfo style="simple"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:condition | plx:initialize | plx:attribute | plx:arrayDescriptor | plx:passTypeParam | plx:passMemberTypeParam | plx:typeParam | plx:derivesFromClass | plx:implementsInterface | plx:interfaceMember | plx:param | plx:returns | plx:beforeLoop | plx:initializeLoop | plx:leadingInfo | plx:trailingInfo | plx:blockLeadingInfo | plx:blockTrailingInfo | plx:explicitDelegateType | plx:parametrizedDataTypeQualifier">
		<plxGen:indentInfo style="blockDecorator"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:comment">
		<xsl:variable name="blankLine" select="@blankLine"/>
		<xsl:choose>
			<xsl:when test="$blankLine='true' or $blankLine='1'">
				<plxGen:indentInfo style="blankLine"/>
			</xsl:when>
			<xsl:otherwise>
				<plxGen:indentInfo style="simple" statementClose=""/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:pragma | plx:docComment">
		<plxGen:indentInfo style="simple" statementClose=""/>
	</xsl:template>
	<!-- 
	*********************************************************
	Default inline statement expansion for native plix elements
	*********************************************************
	-->
	<xsl:template match="plx:inlineStatement" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:variable name="expansionFragment">
			<xsl:apply-templates select="child::*[last()]" mode="ExpandInline">
				<xsl:with-param name="TypeAttributes" select="@*"/>
				<xsl:with-param name="TypeElements" select="child::*[position()!=last()]"/>
				<xsl:with-param name="Key" select="$LocalItemKey"/>
				<xsl:with-param name="Prefix" select="$GeneratedVariablePrefix"/>
				<xsl:with-param name="ContextField" select="$ContextField"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="expansion" select="exsl:node-set($expansionFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="$expansion">
				<xsl:copy-of select="$expansion"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- If an empty set is returned then recurse to continue to look
				     for inline statements farther down. If inline items are expanded,
						 then nested inline expansions are handled by recursive RenderElement
						 calls on the expansions returned from this template. -->
				<xsl:apply-templates select="child::*[last()]" mode="CollectInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_1')"/>
					<xsl:with-param name="ContextField" select="$ContextField"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="*" mode="CollectInline">
		<!-- Nothing to do, just block the automatic xsl recursive handling -->
	</xsl:template>
	<xsl:template match="*" mode="ReplaceInline" name="DefaultReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*|text()" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:inlineStatement" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:variable name="inlineExpansion" select="$Expansions[@key=$LocalItemKey]"/>
		<xsl:choose>
			<xsl:when test="$inlineExpansion">
				<xsl:copy-of select="$inlineExpansion/plxGen:surrogate/child::*"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:copy-of select="child::*[position()&lt;last()]"/>
					<xsl:apply-templates select="child::*[last()]" mode="ReplaceInline">
						<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_1')"/>
						<xsl:with-param name="Expansions" select="$Expansions"/>
					</xsl:apply-templates>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- 
	*********************************************************
	CollectInline and ReplaceInline templates for specific elements.
	Note that any 'CollectInline' template that adjusts the forwarded
	LocalItemKey should have corresponding 'ReplaceInline' templates
	for all child elements that were forwarded the adjusted item key.
	*********************************************************
	-->
	<!-- UNDONE: enumItem/initialize?, caseType/condition? -->
	<xsl:template match="plx:field" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="plx:initialize/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'f')"/>
			<xsl:with-param name="ContextField" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:field" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*|text()" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'f')"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:local | plx:autoDispose | plx:lock | plx:iterator" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="plx:initialize/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:assign | plx:nullFallbackOperator | plx:attachEvent | plx:detachEvent" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:apply-templates select="plx:left/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'l')"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="plx:right/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'r')"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:binaryOperator" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:variable name="isBooleanAnd" select="@type='booleanAnd'"/>
		<xsl:variable name="isBooleanOr" select="@type='booleanOr'"/>
		<xsl:choose>
			<xsl:when test="$isBooleanAnd or $isBooleanOr">
				<!-- Expansions on the right hand side need special consideration for short-circuiting -->
				<xsl:variable name="rightExpansionFragment">
					<!-- This is just a test to see if we get anything. There is currently no way to
					stop CollectInline from returning data, and adding this support would be a lot of
					extra checking for downstream templates, but we can make it lighter by not forwarding the context
					field or key. Any expansion we do here will be reapplied as part of the normal
					inline expansion of our expansions. -->
					<xsl:apply-templates select="plx:right/child::*" mode="CollectInline">
						<xsl:with-param name="LocalItemKey" select="''"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="rightExpansion" select="exsl:node-set($rightExpansionFragment)/child::*"/>
				<xsl:choose>
					<xsl:when test="$rightExpansion">
						<xsl:variable name="variableName" select="concat($GeneratedVariablePrefix,$LocalItemKey)"/>
						<xsl:variable name="conditionFragment">
							<plx:inlineStatement dataTypeName=".boolean">
								<plx:conditionalOperator>
									<plx:condition>
										<xsl:copy-of select="plx:left/child::*"/>
									</plx:condition>
									<xsl:choose>
										<xsl:when test="$isBooleanAnd">
											<plx:left>
												<xsl:copy-of select="plx:right/child::*"/>
											</plx:left>
											<plx:right>
												<plx:falseKeyword/>
											</plx:right>
										</xsl:when>
										<xsl:otherwise>
											<plx:left>
												<plx:trueKeyword/>
											</plx:left>
											<plx:right>
												<xsl:copy-of select="plx:right/child::*"/>
											</plx:right>
										</xsl:otherwise>
									</xsl:choose>
								</plx:conditionalOperator>
							</plx:inlineStatement>
						</xsl:variable>
						<plxGen:inlineExpansion key="{$LocalItemKey}">
							<plxGen:expansion>
								<xsl:choose>
									<xsl:when test="$ContextField">
										<plx:property name="{$variableName}" visibility="private">
											<xsl:if test="$ContextField/@static='true'">
												<xsl:attribute name="modifier">
													<xsl:text>static</xsl:text>
												</xsl:attribute>
											</xsl:if>
											<plx:returns dataTypeName=".boolean"/>
											<plx:get>
												<plx:return>
													<xsl:copy-of select="$conditionFragment"/>
												</plx:return>
											</plx:get>
										</plx:property>
									</xsl:when>
									<xsl:otherwise>
										<plx:local name="{$variableName}" dataTypeName=".boolean">
											<plx:initialize>
												<xsl:copy-of select="$conditionFragment"/>
											</plx:initialize>
										</plx:local>
									</xsl:otherwise>
								</xsl:choose>
							</plxGen:expansion>
							<plxGen:surrogate>
								<xsl:choose>
									<xsl:when test="$ContextField">
										<plx:callThis name="{$variableName}" type="property">
											<xsl:if test="$ContextField/@static='true'">
												<xsl:attribute name="accessor">
													<xsl:text>static</xsl:text>
												</xsl:attribute>
											</xsl:if>
										</plx:callThis>
									</xsl:when>
									<xsl:otherwise>
										<plx:nameRef name="{$variableName}"/>
									</xsl:otherwise>
								</xsl:choose>
							</plxGen:surrogate>
						</plxGen:inlineExpansion>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="plx:left/child::*" mode="CollectInline">
							<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'l')"/>
							<xsl:with-param name="ContextField" select="$ContextField"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- Other operator types do not short circuit -->
				<xsl:apply-templates select="plx:left/child::*" mode="CollectInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'l')"/>
					<xsl:with-param name="ContextField" select="$ContextField"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="plx:right/child::*" mode="CollectInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'r')"/>
					<xsl:with-param name="ContextField" select="$ContextField"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:binaryOperator" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:variable name="inlineExpansion" select="$Expansions[@key=$LocalItemKey]"/>
		<xsl:choose>
			<xsl:when test="$inlineExpansion">
				<xsl:copy-of select="$inlineExpansion/plxGen:surrogate/child::*"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="DefaultReplaceInline">
					<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
					<xsl:with-param name="Expansions" select="$Expansions"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:conditionalOperator" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:apply-templates select="plx:condition/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'c')"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="plx:left/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'l')"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="plx:right/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'r')"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:assign/child::*[self::plx:left or self::plx:right] | plx:binaryOperator/child::*[self::plx:left or self::plx:right] | plx:conditionalOperator/child::*[self::plx:left or self::plx:right or self::plx:condition] | plx:nullFallbackOperator/child::*[self::plx:left or self::plx:right] | plx:attachEvent/child::*[self::plx:left or self::plx:right] | plx:detachEvent/child::*[self::plx:left or self::plx:right]" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*|text()" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,substring(local-name(),1,1))"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:cast" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:apply-templates select="child::*[last()]" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:unaryOperator | plx:increment | plx:decrement | plx:throw | plx:return | plx:expression" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:apply-templates select="child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			<xsl:with-param name="ContextField" select="$ContextField"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:branch | plx:alternateBranch | plx:switch" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="plx:condition/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:callStatic | plx:callThis | plx:callNew" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:for-each select="plx:arrayInitializer">
			<xsl:apply-templates select="." mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'ai')"/>
				<xsl:with-param name="ContextField" select="$ContextField"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:for-each select="plx:passParam | plx:passParamArray/plx:passParam">
			<xsl:apply-templates select="child::*" mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_',position())"/>
				<xsl:with-param name="ContextField" select="$ContextField"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:callInstance" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:apply-templates select="plx:callObject/child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_0')"/>
		</xsl:apply-templates>
		<xsl:for-each select="plx:passParam | plx:passParamArray/plx:passParam">
			<xsl:apply-templates select="child::*" mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_',position())"/>
				<xsl:with-param name="ContextField" select="$ContextField"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:callInstance | plx:callStatic | plx:callThis | plx:callNew" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="plx:passTypeParam | plx:passMemberTypeParam | plx:arrayDescriptor | plx:parametrizedDataTypeQualifier"/>
			<xsl:if test="self::plx:callInstance">
				<xsl:apply-templates select="plx:callObject" mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_0')"/>
					<xsl:with-param name="Expansions" select="$Expansions"/>
				</xsl:apply-templates>
			</xsl:if>
			<xsl:for-each select="plx:arrayInitializer">
				<xsl:apply-templates select="." mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'ai')"/>
					<xsl:with-param name="Expansions" select="$Expansions"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:for-each select="plx:passParam | plx:passParamArray/plx:passParam">
				<xsl:apply-templates select="." mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_', position())"/>
					<xsl:with-param name="Expansions" select="$Expansions"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:*/plx:arrayInitializer | plx:concatenate" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="ContextField"/>
		<xsl:for-each select="child::*">
			<xsl:apply-templates select="." mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_',position())"/>
				<xsl:with-param name="ContextField" select="$ContextField"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:*/plx:arrayInitializer | plx:concatenate" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:for-each select="child::*">
				<xsl:apply-templates select="." mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'_', position())"/>
					<xsl:with-param name="Expansions" select="$Expansions"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	
	<!-- TopeLevel snippet inline expansion.
	Note that all other explicitly handled elements (left, right, callObject, initialize, condition, beforeLoop, initializeLoop) defer directly to their child elements and
	do not need to be directly expanded.  -->
	<xsl:template match="plx:passParam[not(parent::plx:*)]" priority="-.4" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'p')"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:passParam[not(parent::plx:*)]" priority="-.4" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'p')"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:passParamArray[not(parent::plx:*)]" priority="-.4" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'p',position())"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:passParamArray[not(parent::plx:*)]" priority="-.4" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'p',position())"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:arrayInitializer[not(parent::plx:*)]" priority="-.4" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:apply-templates select="child::*" mode="CollectInline">
			<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'ai')"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:arrayInitializer[not(parent::plx:*)]" priority="-.4" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::*" mode="ReplaceInline">
				<xsl:with-param name="LocalItemKey" select="concat($LocalItemKey,'ai')"/>
				<xsl:with-param name="Expansions" select="$Expansions"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<!-- Loop inline expansion -->
	<xsl:template match="plx:loop" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:variable name="loopDecorators" select="plx:initializeLoop | plx:condition | plx:beforeLoop"/>
		<xsl:if test="$loopDecorators//plx:inlineStatement">

			<!-- Cache the contents of all three block decorators -->
			<xsl:variable name="init" select="$loopDecorators/self::plx:initializeLoop/child::*"/>
			<xsl:variable name="check" select="$loopDecorators/self::plx:condition/child::*"/>
			<xsl:variable name="incr" select="$loopDecorators/self::plx:beforeLoop/child::*"/>

			<!-- Create local item keys for all three block decorators -->
			<xsl:variable name="initKey" select="concat($LocalItemKey,'i')"/>
			<xsl:variable name="checkKey" select="concat($LocalItemKey,'c')"/>
			<xsl:variable name="incrKey" select="concat($LocalItemKey,'b')"/>

			<xsl:variable name="body" select="child::*[not(self::plx:initializeLoop | self::plx:condition | self::plx:beforeLoop)]"/>
			<xsl:variable name="bodyHasContinueFragment">
				<xsl:apply-templates select="$body" mode="LoopBodyHasContinue"/>
			</xsl:variable>
			<!-- If the body has one or more continue statements, then we need to do extra check and increment work -->
			<xsl:variable name="bodyHasContinue" select="boolean(string($bodyHasContinueFragment))"/>

			<xsl:variable name="checkAfter" select="@checkCondition='after'"/>

			<xsl:variable name="initInlineExpansionsFragment">
				<xsl:apply-templates select="$init" mode="CollectInline">
					<xsl:with-param name="LocalItemKey" select="$initKey"/>
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:variable name="initInlineExpansions" select="exsl:node-set($initInlineExpansionsFragment)/child::*"/>

			<xsl:variable name="checkInlineExpansionsFragment">
				<xsl:apply-templates select="$check" mode="CollectInline">
					<xsl:with-param name="LocalItemKey" select="$checkKey"/>
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:variable name="checkInlineExpansions" select="exsl:node-set($checkInlineExpansionsFragment)/child::*"/>
			<xsl:variable name="resolvedCheckInlineExpansionsFragment">
				<xsl:if test="$checkAfter and $checkInlineExpansions">
					<xsl:call-template name="SeparateLocalInitialize">
						<xsl:with-param name="CodeFragment">
							<xsl:for-each select="$checkInlineExpansions">
								<xsl:variable name="key" select="@key"/>
								<xsl:for-each select="plxGen:expansion/child::*">
									<xsl:call-template name="FullyResolveInlineExpansions">
										<xsl:with-param name="LocalItemKey" select="concat($key,'_',position())"/>
										<xsl:with-param name="TopLevel" select="false()"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:for-each>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="resolvedCheckInlineExpansions" select="exsl:node-set($resolvedCheckInlineExpansionsFragment)/child::*"/>

			<xsl:variable name="incrInlineExpansionsFragment">
				<xsl:choose>
					<xsl:when test="$bodyHasContinue">
						<!-- Fully expand inline so we can extract all locals and declare them once -->
						<xsl:call-template name="SeparateLocalInitialize">
							<xsl:with-param name="CodeFragment">
								<xsl:for-each select="$incr">
									<xsl:call-template name="FullyResolveInlineExpansions">
										<xsl:with-param name="LocalItemKey" select="$incrKey"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="$incr" mode="CollectInline">
							<xsl:with-param name="LocalItemKey" select="$incrKey"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="incrInlineExpansions" select="exsl:node-set($incrInlineExpansionsFragment)/child::*"/>

			<xsl:if test="$initInlineExpansions or $checkInlineExpansions or $incrInlineExpansions">
				<xsl:variable name="modifiedBody" select="$checkInlineExpansions or $incrInlineExpansions"/>
				<plxGen:inlineExpansion key="{$LocalItemKey}" surrogatePreExpanded="true">
					<xsl:if test="$modifiedBody">
						<xsl:attribute name="childrenModified">
							<xsl:text>true</xsl:text>
						</xsl:attribute>
					</xsl:if>
					<plxGen:expansion>
						<xsl:if test="$initInlineExpansions">
							<xsl:copy-of select="$initInlineExpansions/plxGen:expansion/child::*"/>
							<xsl:apply-templates select="$init" mode="ReplaceInline">
								<xsl:with-param name="LocalItemKey" select="$initKey"/>
								<xsl:with-param name="Expansions" select="$initInlineExpansions"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:if test="$checkAfter and $resolvedCheckInlineExpansions">
							<xsl:copy-of select="$resolvedCheckInlineExpansions/self::plx:local"/>
						</xsl:if>
					</plxGen:expansion>
					<plxGen:surrogate>
						<plx:loop>
							<xsl:copy-of select="@checkCondition"/>
							<xsl:if test="$init and not($initInlineExpansions)">
								<plx:initializeLoop>
									<xsl:copy-of select="$init"/>
								</plx:initializeLoop>
							</xsl:if>
							<xsl:if test="$check">
								<xsl:choose>
									<xsl:when test="not($checkInlineExpansions)">
										<plx:condition>
											<xsl:copy-of select="$check"/>
										</plx:condition>
									</xsl:when>
									<xsl:when test="$checkAfter">
										<plx:condition>
											<xsl:apply-templates select="$check" mode="ReplaceInline">
												<xsl:with-param name="LocalItemKey" select="$checkKey"/>
												<xsl:with-param name="Expansions" select="$checkInlineExpansions"/>
											</xsl:apply-templates>
										</plx:condition>
									</xsl:when>
								</xsl:choose>
							</xsl:if>
							<xsl:if test="$incr and not($incrInlineExpansions)">
								<plx:beforeLoop>
									<xsl:copy-of select="$incr"/>
								</plx:beforeLoop>
							</xsl:if>
							<xsl:if test="$modifiedBody">
								<xsl:if test="not($checkAfter) and $checkInlineExpansions">
									<xsl:copy-of select="$checkInlineExpansions/plxGen:expansion/child::*"/>
									<plx:branch>
										<plx:condition>
											<plx:unaryOperator type="booleanNot">
												<xsl:apply-templates select="$check" mode="ReplaceInline">
													<xsl:with-param name="LocalItemKey" select="$checkKey"/>
													<xsl:with-param name="Expansions" select="$checkInlineExpansions"/>
												</xsl:apply-templates>
											</plx:unaryOperator>
										</plx:condition>
										<plx:break/>
									</plx:branch>
								</xsl:if>
								<xsl:choose>
									<xsl:when test="$bodyHasContinue">
										<xsl:if test="$incrInlineExpansions">
											<xsl:copy-of select="$incrInlineExpansions/self::plx:local"/>
										</xsl:if>
										<xsl:if test="$checkAfter and $checkInlineExpansions">
											<xsl:copy-of select="$checkInlineExpansions/self::plx:local"/>
										</xsl:if>
										<xsl:variable name="endCodeFragment">
											<xsl:if test="$incrInlineExpansions">
												<xsl:copy-of select="$incrInlineExpansions[not(self::plx:local)]"/>
											</xsl:if>
											<xsl:if test="$checkAfter and $resolvedCheckInlineExpansions">
												<xsl:copy-of select="$resolvedCheckInlineExpansions[not(self::plx:local)]"/>
											</xsl:if>
										</xsl:variable>
										<xsl:apply-templates select="$body" mode="LoopBodyAddBeforeContinue">
											<xsl:with-param name="NewCode" select="$endCodeFragment"/>
										</xsl:apply-templates>
										<xsl:copy-of select="$endCodeFragment"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="$body"/>
										<xsl:if test="$incrInlineExpansions">
											<xsl:copy-of select="$incrInlineExpansions/plxGen:expansion/child::*"/>
											<xsl:apply-templates select="$incr" mode="ReplaceInline">
												<xsl:with-param name="LocalItemKey" select="$incrKey"/>
												<xsl:with-param name="Expansions" select="$incrInlineExpansions"/>
											</xsl:apply-templates>
										</xsl:if>
										<xsl:if test="$checkAfter and $resolvedCheckInlineExpansions">
											<xsl:copy-of select="$resolvedCheckInlineExpansions[not(self::plx:local)]"/>
										</xsl:if>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</plx:loop>
					</plxGen:surrogate>
				</plxGen:inlineExpansion>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:loop" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<!-- This is a backup in case the main loop decides it cannot use the surrogate directly -->
		<xsl:copy-of select="$Expansions/plxGen:surrogate/child::*"/>
	</xsl:template>
	<xsl:template match="*" mode="LoopBodyHasContinue">
		<xsl:apply-templates select="child::*" mode="LoopBodyHasContinue"/>
	</xsl:template>
	<xsl:template match="plx:loop|plx:iterator" mode="LoopBodyHasContinue">
		<!-- We don't care about continues inside nested loops -->
	</xsl:template>
	<xsl:template match="plx:continue" mode="LoopBodyHasContinue">
		<xsl:text>x</xsl:text>
	</xsl:template>
	<xsl:template match="*" mode="LoopBodyAddBeforeContinue">
		<xsl:param name="NewCode"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="child::node()" mode="LoopBodyAddBeforeContinue">
				<xsl:with-param name="NewCode" select="$NewCode"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:loop|plx:iterator" mode="LoopBodyAddBeforeContinue">
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template match="plx:continue" mode="LoopBodyAddBeforeContinue">
		<xsl:param name="NewCode"/>
		<xsl:copy-of select="$NewCode"/>
		<xsl:copy-of select="."/>
	</xsl:template>
	<!-- Helper function to fully resolve inline expansions. Normally, nested
	     inlineStatement elements are rendered naturally on the next pass. However,
			 some situations require all inline statements to be fully resolved before
			 proceeding with additional processing. If TopLevel is true() (the default),
			 then an empty fragment is returned if there are no inline expansions. -->
	<xsl:template name="FullyResolveInlineExpansions">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="TopLevel" select="true()"/>
		<xsl:variable name="expansionsFragment">
			<xsl:apply-templates select="." mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="expansions" select="exsl:node-set($expansionsFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="$expansions">
				<xsl:for-each select="$expansions">
					<xsl:variable name="key" select="@key"/>
					<xsl:for-each select="plxGen:expansion/child::*">
						<xsl:call-template name="FullyResolveInlineExpansions">
							<xsl:with-param name="LocalItemKey" select="concat($key,'_',position())"/>
							<xsl:with-param name="TopLevel" select="false()"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:for-each>
				<xsl:apply-templates select="." mode="ReplaceInline">
					<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
					<xsl:with-param name="Expansions" select="$expansions"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="not($TopLevel)">
				<xsl:copy-of select="."/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- Helper function to turn a local construct with an initialize block into a local followed
	     by an assign construct.-->
	<xsl:template name="SeparateLocalInitialize">
		<xsl:param name="CodeFragment"/>
		<xsl:for-each select="exsl:node-set($CodeFragment)/child::*">
			<xsl:choose>
				<xsl:when test="self::plx:local">
					<xsl:variable name="initContents" select="plx:initialize/child::*"/>
					<xsl:choose>
						<xsl:when test="$initContents">
							<xsl:copy>
								<xsl:copy-of select="@*"/>
								<xsl:copy-of select="child::*[not(self::plx:initialize)]"/>
							</xsl:copy>
							<plx:assign>
								<plx:left>
									<plx:nameRef name="{@name}"/>
								</plx:left>
								<plx:right>
									<xsl:copy-of select="$initContents"/>
								</plx:right>
							</plx:assign>
						</xsl:when>
						<xsl:otherwise>
							<xsl:copy-of select="."/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<!--
	*********************************************************
	ExpandInline templates. These templates should return an
	plxGen:inlineExpansion structure if the inlineStatement
	needs to be replaced, and an empty set otherwise. The following
	passed in param values are provided:
	TypeAttributes: attributes needed to render auto-generated type elements
	TypeElements: elements needed to render auto-generated type elements
	Key: The key used to identify the expansion and surrogate
	VariablePrefix: The language-specified prefix for auto-generated variables
	*********************************************************
	-->
	<xsl:template match="plx:assign" mode="ExpandInline">
		<xsl:param name="TypeAttributes"/>
		<xsl:param name="TypeElements"/>
		<xsl:param name="Key"/>
		<xsl:param name="Prefix"/>
		<xsl:param name="ContextField"/>
		<xsl:variable name="variableName" select="concat($Prefix,$Key)"/>
		<xsl:variable name="leftLocalNameRef" select="plx:left/plx:nameRef[not(@type) or (@type='local')]"/>
		<plxGen:inlineExpansion key="{$Key}">
			<plxGen:expansion>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:property name="{$variableName}" visibility="private">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="modifier">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
							<plx:returns>
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
							</plx:returns>
							<plx:get>
								<xsl:copy-of select="."/>
								<plx:return>
									<xsl:copy-of select="plx:left/child::*"/>
								</plx:return>
							</plx:get>
						</plx:property>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="."/>
						<xsl:if test="not($leftLocalNameRef)">
							<plx:local name="{$variableName}">
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
								<plx:initialize>
									<xsl:copy-of select="plx:left/child::*"/>
								</plx:initialize>
							</plx:local>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:expansion>
			<plxGen:surrogate>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:callThis name="{$variableName}" type="property">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="accessor">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
						</plx:callThis>
					</xsl:when>
					<xsl:when test="$leftLocalNameRef">
						<xsl:copy-of select="$leftLocalNameRef"/>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="{$variableName}"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:surrogate>
		</plxGen:inlineExpansion>
	</xsl:template>
	<xsl:template match="plx:increment | plx:decrement" mode="ExpandInline">
		<xsl:param name="TypeAttributes"/>
		<xsl:param name="TypeElements"/>
		<xsl:param name="Key"/>
		<xsl:param name="Prefix"/>
		<xsl:param name="ContextField"/>
		<plxGen:inlineExpansion key="{$Key}">
			<plxGen:expansion>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:property name="{$Prefix}{$Key}" visibility="private">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="modifier">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
							<plx:returns>
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
							</plx:returns>
							<plx:get>
								<xsl:choose>
									<xsl:when test="@type='post'">
										<plx:local name="retVal">
											<xsl:copy-of select="$TypeAttributes"/>
											<xsl:copy-of select="$TypeElements"/>
											<plx:initialize>
												<xsl:copy-of select="child::*"/>
											</plx:initialize>
										</plx:local>
										<xsl:copy-of select="."/>
										<plx:return>
											<plx:nameRef name="retVal"/>
										</plx:return>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="."/>
										<plx:return>
											<xsl:copy-of select="child::*"/>
										</plx:return>
									</xsl:otherwise>
								</xsl:choose>
							</plx:get>
						</plx:property>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="@type='post'">
							<plx:local name="{$Prefix}{$Key}">
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
								<plx:initialize>
									<xsl:copy-of select="child::*"/>
								</plx:initialize>
							</plx:local>
						</xsl:if>
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:expansion>
			<plxGen:surrogate>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:callThis name="{$Prefix}{$Key}" type="property">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="accessor">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
						</plx:callThis>
					</xsl:when>
					<xsl:when test="@type='post'">
						<plx:nameRef name="{$Prefix}{$Key}"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="child::*"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:surrogate>
		</plxGen:inlineExpansion>
	</xsl:template>
	<xsl:template match="plx:conditionalOperator" mode="ExpandInline">
		<xsl:param name="TypeAttributes"/>
		<xsl:param name="TypeElements"/>
		<xsl:param name="Key"/>
		<xsl:param name="Prefix"/>
		<xsl:param name="ContextField"/>
		<xsl:variable name="variableNameFragment">
			<xsl:choose>
				<xsl:when test="$ContextField">
					<xsl:text>retVal</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$Prefix"/>
					<xsl:value-of select="$Key"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="variableName" select="string($variableNameFragment)"/>
		<xsl:variable name="expansion">
			<plx:local name="{$variableName}">
				<xsl:copy-of select="$TypeAttributes"/>
				<xsl:copy-of select="$TypeElements"/>
			</plx:local>
			<plx:branch>
				<plx:condition>
					<xsl:copy-of select="plx:condition/child::*"/>
				</plx:condition>
				<plx:assign>
					<plx:left>
						<plx:nameRef name="{$variableName}"/>
					</plx:left>
					<plx:right>
						<xsl:copy-of select="plx:left/child::*"/>
					</plx:right>
				</plx:assign>
			</plx:branch>
			<plx:fallbackBranch>
				<plx:assign>
					<plx:left>
						<plx:nameRef name="{$variableName}"/>
					</plx:left>
					<plx:right>
						<xsl:copy-of select="plx:right/child::*"/>
					</plx:right>
				</plx:assign>
			</plx:fallbackBranch>
		</xsl:variable>
		<plxGen:inlineExpansion key="{$Key}">
			<plxGen:expansion>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:property name="{$Prefix}{$Key}" visibility="private">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="modifier">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
							<plx:returns>
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
							</plx:returns>
							<plx:get>
								<xsl:copy-of select="$expansion"/>
								<plx:return>
									<plx:nameRef name="{$variableName}"/>
								</plx:return>
							</plx:get>
						</plx:property>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$expansion"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:expansion>
			<plxGen:surrogate>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:callThis name="{$Prefix}{$Key}" type="property">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="accessor">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
						</plx:callThis>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="{$variableName}"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:surrogate>
		</plxGen:inlineExpansion>
	</xsl:template>
	<xsl:template match="plx:nullFallbackOperator" mode="ExpandInline">
		<xsl:param name="TypeAttributes"/>
		<xsl:param name="TypeElements"/>
		<xsl:param name="Key"/>
		<xsl:param name="Prefix"/>
		<xsl:param name="ContextField"/>
		<xsl:variable name="variableNameFragment">
			<xsl:choose>
				<xsl:when test="$ContextField">
					<xsl:text>retVal</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$Prefix"/>
					<xsl:value-of select="$Key"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="variableName" select="string($variableNameFragment)"/>
		<xsl:variable name="expansion">
			<plx:local name="{$variableName}">
				<xsl:copy-of select="$TypeAttributes"/>
				<xsl:copy-of select="$TypeElements"/>
				<plx:initialize>
					<xsl:copy-of select="plx:left/child::*"/>
				</plx:initialize>
			</plx:local>
			<plx:branch>
				<plx:condition>
					<plx:binaryOperator type="identityEquality">
						<plx:left>
							<plx:nameRef name="{$variableName}"/>
						</plx:left>
						<plx:right>
							<plx:nullKeyword/>
						</plx:right>
					</plx:binaryOperator>
				</plx:condition>
				<plx:assign>
					<plx:left>
						<plx:nameRef name="{$variableName}"/>
					</plx:left>
					<plx:right>
						<xsl:copy-of select="plx:right/child::*"/>
					</plx:right>
				</plx:assign>
			</plx:branch>
		</xsl:variable>
		<plxGen:inlineExpansion key="{$Key}">
			<plxGen:expansion>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:property name="{$Prefix}{$Key}" visibility="private">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="modifier">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
							<plx:returns>
								<xsl:copy-of select="$TypeAttributes"/>
								<xsl:copy-of select="$TypeElements"/>
							</plx:returns>
							<plx:get>
								<xsl:copy-of select="$expansion"/>
								<plx:return>
									<plx:nameRef name="{$variableName}"/>
								</plx:return>
							</plx:get>
						</plx:property>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$expansion"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:expansion>
			<plxGen:surrogate>
				<xsl:choose>
					<xsl:when test="$ContextField">
						<plx:callThis name="{$Prefix}{$Key}" type="property">
							<xsl:if test="$ContextField/@static='true'">
								<xsl:attribute name="accessor">
									<xsl:text>static</xsl:text>
								</xsl:attribute>
							</xsl:if>
						</plx:callThis>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="{$variableName}"/>
					</xsl:otherwise>
				</xsl:choose>
			</plxGen:surrogate>
		</plxGen:inlineExpansion>
	</xsl:template>
</xsl:stylesheet>