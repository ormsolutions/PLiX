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
	<xsl:variable name="DefaultStatementClose" select="$LanguageInfo/@defaultStatementClose"/>
	<xsl:variable name="Comment" select="$LanguageInfo/@comment"/>
	<xsl:variable name="DocComment" select="$LanguageInfo/@docComment"/>
	<xsl:variable name="BlockOpen" select="$LanguageInfo/@blockOpen"/>
	<xsl:variable name="NewLineBeforeBlockOpen" select="'yes'=$LanguageInfo/@newLineBeforeBlockOpen"/>
	<xsl:variable name="RequireCaseLabels" select="'yes'=$LanguageInfo/@requireCaseLabels"/>
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
	<xsl:template match="*" mode="TopLevel">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderElement">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
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
		<xsl:variable name="NextLine" select="concat($NewLine,$Indent,$DocComment)"/>
		<!-- The assumption is made that all doc comments are in xml tags -->
		<!-- UNDONE: Support spitting code examples in the output language -->
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
			<!-- UNDONE: We really just want to spit the xml as is, but this
				 is difficult to do in text output mode -->
			<xsl:text>&lt;</xsl:text>
			<xsl:value-of select="local-name()"/>
			<xsl:for-each select="@*">
				<xsl:text> </xsl:text>
				<xsl:value-of select="name()"/>
				<xsl:text>="</xsl:text>
				<xsl:value-of select="."/>
				<xsl:text>"</xsl:text>
			</xsl:for-each>
			<xsl:text>&gt;</xsl:text>
			<xsl:value-of select="$NextLine"/>
			<xsl:call-template name="RenderDocCommentString">
				<xsl:with-param name="String" select="."/>
				<xsl:with-param name="NextLine" select="$NextLine"/>
			</xsl:call-template>
			<xsl:value-of select="$NextLine"/>
			<xsl:text>&lt;/</xsl:text>
			<xsl:value-of select="local-name()"/>
			<xsl:text>&gt;</xsl:text>
		</xsl:for-each>
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
		<xsl:variable name="indentInfoFragment">
			<xsl:apply-templates select="." mode="IndentInfo"/>
		</xsl:variable>
		<xsl:variable name="indentInfo" select="exsl:node-set($indentInfoFragment)/child::*"/>
		<xsl:call-template name="RenderElementWithIndentInfo">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Statement" select="$Statement"/>
			<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			<xsl:with-param name="IndentInfo" select="$indentInfo"/>
			<xsl:with-param name="IndentStyle" select="string($indentInfo/@style)"/>
			<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="RenderElementWithIndentInfo">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey" select="''"/>
		<xsl:param name="Statement" select="false()"/>
		<xsl:param name="ProcessSecondaryBlock" select="false()"/>
		<xsl:param name="CurrentPosition" select="position()"/>
		<xsl:param name="IndentInfo"/>
		<xsl:param name="IndentStyle"/>
		<xsl:param name="CaseLabels"/>
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
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:value-of select="$Indent"/>
				<xsl:apply-templates select=".">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
					<!-- The next case labels don't apply until we're inside the switch scope, so always
						 use the original case labels here. -->
					<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
				</xsl:apply-templates>
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
			</xsl:when>
			<xsl:when test="$IndentStyle='simpleMember' or $IndentStyle='simple'">
				<xsl:variable name="hasInfo" select="$IndentStyle='simpleMember'"/>
				<xsl:if test="$hasInfo">
					<xsl:for-each select="plx:leadingInfo/child::plx:*">
						<xsl:call-template name="RenderElement">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Statement" select="true()"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:value-of select="$Indent"/>
				<xsl:apply-templates select=".">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
					<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
				</xsl:apply-templates>
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
			</xsl:when>
			<xsl:when test="$IndentStyle='blockSibling' or $IndentStyle='secondaryBlock'">
				<xsl:variable name="previousIndent" select="substring($Indent,1,string-length($Indent)-string-length($SingleIndent))"/>
				<xsl:for-each select="preceding-sibling::*/plx:blockTrailingInfo/child::plx:*">
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
					<xsl:value-of select="$NewLine"/>
				</xsl:if>
				<xsl:value-of select="$previousIndent"/>
				<xsl:apply-templates select=".">
					<xsl:with-param name="Indent" select="$previousIndent"/>
					<xsl:with-param name="LocalItemKey" select="$nextLocalItemKey"/>
					<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
				</xsl:apply-templates>
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
		<xsl:param name="Siblings" select="following-sibling::*"/>
		<xsl:param name="SiblingIndex" select="1"/>
		<xsl:param name="ParentLocalItemKey"/>
		<xsl:param name="LeadBlockPosition"/>
		<xsl:param name="CaseLabels"/>
		<xsl:for-each select="$Siblings[$SiblingIndex]">
			<xsl:variable name="indentInfoFragment">
				<xsl:apply-templates select="." mode="IndentInfo"/>
			</xsl:variable>
			<xsl:variable name="indentInfo" select="exsl:node-set($indentInfoFragment)/child::*"/>
			<xsl:variable name="indentStyle" select="string($indentInfo/@style)"/>
			<xsl:if test="$indentStyle='secondaryBlock'">
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
					<xsl:with-param name="Siblings" select="$Siblings"/>
					<xsl:with-param name="SiblingIndex" select="$SiblingIndex + 1"/>
					<xsl:with-param name="ParentLocalItemKey" select="$ParentLocalItemKey"/>
					<xsl:with-param name="LeadBlockPosition" select="$LeadBlockPosition"/>
					<xsl:with-param name="CaseLabels" select="$CaseLabels"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
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
	<xsl:template mode="IndentInfo" match="plx:loop | plx:iterator | plx:lock | plx:autoDispose">
		<plxGen:indentInfo style="block"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:branch">
		<plxGen:indentInfo style="blockWithSecondarySiblings"/>
	</xsl:template>
	<xsl:template mode="IndentInfo" match="plx:try | plx:switch">
		<!-- Put plx:switch here so it picks up blockLeadingInfo/blockTrailingInfo on the nested case statements -->
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
</xsl:stylesheet>