<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Neumont PLiX (Programming Language in XML) Code Generator

	Copyright © Neumont University and Matthew Curland. All rights reserved.
	Copyright © ORM Solutions, LLC. All rights reserved.

	The use and distribution terms for this software are covered by the
	Common Public License 1.0 (http://opensource.org/licenses/cpl) which
	can be found in the file CPL.txt at the root of this distribution.
	By using this software in any fashion, you are agreeing to be bound by
	the terms of this license.

	You must not remove this notice, or any other, from this software.
-->
<!--
input Test.xml
output test.plix.xml
schemas: 
-->
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:plx="http://schemas.neumont.edu/CodeGeneration/PLiX"
	xmlns:plxPHP="http://schemas.neumont.edu/CodeGeneration/PLiX/PHP" 
	xmlns:plxGen="urn:local-plix-generator" 
	xmlns:exsl="http://exslt.org/common"
	exclude-result-prefixes="#default exsl plx plxGen">
	<xsl:import href="PLiXMain.xslt"/>
	<xsl:output method="text"/>
	<!-- Supported brace styles are {C,Indent,Block}. C (the default style)
		 has braces below the statement, Indent indents the
		 braces one indent level, and Block puts the
		 opening brace on the same line as the statement -->
	<xsl:param name="BraceStyle" select="'Block'"/>
	<xsl:param name="AutoVariablePrefix" select="'PLiXPHP'"/>
	<xsl:param name="PartialBaseSuffix" select="'Base'"/>

	<!-- Generate array() (pre PHP 5.4) instead of []. -->
	<xsl:param name="UseArrayKeyword" select="false()"/>
	<xsl:variable name="arrayOpenFragment">
		<xsl:choose>
			<xsl:when test="$UseArrayKeyword">
				<xsl:text>array(</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="arrayOpen" select="string($arrayOpenFragment)"/>
	<xsl:variable name="arrayCloseFragment">
		<xsl:choose>
			<xsl:when test="$UseArrayKeyword">
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="arrayClose" select="string($arrayCloseFragment)"/>

	<xsl:template match="*" mode="LanguageInfo">
		<plxGen:languageInfo
			defaultBlockClose="}}"
			blockOpen="{{"
			newLineBeforeBlockOpen="yes"
			defaultStatementClose=";"
			requireCaseLabels="no"
			expandInlineStatements="yes"
			autoVariablePrefix="{$AutoVariablePrefix}" 
			comment="// "
			docComment="* ">
			<xsl:choose>
				<xsl:when test="$BraceStyle='Block'">
					<xsl:attribute name="newLineBeforeBlockOpen">
						<xsl:text>no</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="blockOpen">
						<xsl:text> {</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="beforeSecondaryBlockOpen">
						<xsl:text> </xsl:text>
					</xsl:attribute>
				</xsl:when>
				<xsl:when test="$BraceStyle='Indent'">
					<xsl:attribute name="blockOpen">
						<xsl:value-of select="$IndentWith"/>
						<xsl:text>{</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="defaultBlockClose">
						<xsl:value-of select="$IndentWith"/>
						<xsl:text>}</xsl:text>
					</xsl:attribute>
				</xsl:when>
			</xsl:choose>
		</plxGen:languageInfo>
	</xsl:template>

	<!-- Operator Precedence Resolution -->
	<xsl:template match="*" mode="ResolvePrecedence">
		<xsl:param name="Indent"/>
		<xsl:param name="Context"/>
		<xsl:variable name="contextPrecedenceFragment">
			<xsl:apply-templates select="$Context" mode="Precedence"/>
		</xsl:variable>
		<xsl:variable name="contextPrecedence" select="number($contextPrecedenceFragment)"/>
		<xsl:choose>
			<!-- NaN tests false (which we want to ignore), but so does 0 (which we don't) -->
			<xsl:when test="$contextPrecedence or ($contextPrecedence=0)">
				<xsl:variable name="currentPrecedenceFragment">
					<xsl:apply-templates select="."  mode="Precedence"/>
				</xsl:variable>
				<xsl:variable name="currentPrecedence" select="number($currentPrecedenceFragment)"/>
				<xsl:choose>
					<xsl:when test="($currentPrecedence or ($currentPrecedence=0)) and ($contextPrecedence&lt;$currentPrecedence)">
						<xsl:text>(</xsl:text>
						<xsl:apply-templates select=".">
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:apply-templates>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select=".">
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select=".">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:expression[@parens='true' or @parens='1']" mode="ResolvePrecedence">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select=".">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- Assume elements without explicit precedence are autonomous expression  (indicated by 0) -->
	<xsl:template match="*" mode="Precedence">0</xsl:template>
	<xsl:template match="plx:inlineStatement" mode="Precedence">
		<xsl:apply-templates select="child::*" mode="Precedence"/>
	</xsl:template>
	<!-- Specific precedence values -->
	<xsl:template match="plx:callInstance|plx:attachEvent|plx:detachEvent" mode="Precedence">6</xsl:template>
	<xsl:template match="plx:callNew" mode="Precedence">
		<xsl:choose>
			<xsl:when test="plx:arrayInitializer or @dataTypeIsSimpleArray='true' or @dataTypeIsSimpleArray=1">0</xsl:when>
			<xsl:otherwise>8</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:cast|plx:unaryOperator|plx:increment|plx:decrement" mode="Precedence">20</xsl:template>
	<xsl:template match="plx:concatenate" mode="Precedence">40</xsl:template>
	<xsl:template match="plx:binaryOperator" mode="Precedence">
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$type='add'">40</xsl:when>
			<xsl:when test="$type='assignNamed'">0</xsl:when>
			<xsl:when test="$type='bitwiseAnd'">80</xsl:when>
			<xsl:when test="$type='bitwiseExclusiveOr'">82</xsl:when>
			<xsl:when test="$type='bitwiseOr'">84</xsl:when>
			<xsl:when test="$type='booleanAnd'">90</xsl:when>
			<xsl:when test="$type='booleanOr'">92</xsl:when>
			<xsl:when test="$type='divide'">30</xsl:when>
			<xsl:when test="$type='equality'">70</xsl:when>
			<xsl:when test="$type='greaterThan'">60</xsl:when>
			<xsl:when test="$type='greaterThanOrEqual'">60</xsl:when>
			<xsl:when test="$type='identityEquality'">70</xsl:when>
			<xsl:when test="$type='identityInequality'">70</xsl:when>
			<xsl:when test="$type='inequality'">70</xsl:when>
			<xsl:when test="$type='lessThan'">60</xsl:when>
			<xsl:when test="$type='lessThanOrEqual'">60</xsl:when>
			<xsl:when test="$type='modulus'">30</xsl:when>
			<xsl:when test="$type='multiply'">30</xsl:when>
			<xsl:when test="$type='shiftLeft'">50</xsl:when>
			<xsl:when test="$type='shiftRight'">50</xsl:when>
			<xsl:when test="$type='shiftRightZero'">50</xsl:when>
			<xsl:when test="$type='shiftRightPreserve'">50</xsl:when>
			<xsl:when test="$type='subtract'">40</xsl:when>
			<xsl:when test="$type='typeEquality'">60</xsl:when>
			<xsl:when test="$type='typeInequality'">60</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:conditionalOperator" mode="Precedence">96</xsl:template>
	<xsl:template match="plx:assign" mode="Precedence">100</xsl:template>

	<!-- Matched templates -->
	<xsl:template match="plx:alternateBranch">
		<xsl:param name="Indent"/>
		<xsl:text>else if (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:anonymousFunction">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey"/>
		<xsl:text>function</xsl:text>
		<xsl:call-template name="RenderParams"/>
		<xsl:if test="$NewLineBeforeBlockOpen">
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>
		<xsl:value-of select="$BlockOpen"/>
		<xsl:value-of select="$NewLine"/>
		<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
		<xsl:for-each select="child::*[not(self::plx:param or self::plx:returns)]">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$nextIndent"/>
				<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
				<xsl:with-param name="Statement" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:value-of select="$Indent"/>
		<xsl:value-of select="$DefaultBlockClose"/>
	</xsl:template>
	<xsl:template match="plx:assign">
		<xsl:param name="Indent"/>
		<xsl:variable name="left" select="plx:left/child::*"/>
		<xsl:variable name="leftCall" select="$left[self::plx:callInstance | self::plx:callThis | self::plx:callStatic]"/>
		<xsl:choose>
			<xsl:when test="not($leftCall[@type='property' or @type='indexerCall'])">
				<xsl:apply-templates select="$left" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text> = </xsl:text>
				<xsl:if test="@plxPHP:reference[.='true' or .=1]">
					<xsl:text>&amp;</xsl:text>
				</xsl:if>
				<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$left">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:attachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="plx:right/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:autoDispose" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:variable name="localNameFragment">
			<xsl:choose>
				<xsl:when test="@localName='.implied'">
					<xsl:value-of select="concat($GeneratedVariablePrefix,$LocalItemKey,'ad')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@localName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="localName" select="string($localNameFragment)"/>
		<xsl:variable name="rawTrySurrogateFragment">
			<plx:try>
				<xsl:copy-of select="child::*[not(self::plx:passTypeParam|self::plx:parametrizedDataTypeQualifier|self::plx:initialize)]"/>
				<plx:finally>
					<plx:branch>
						<plx:condition>
							<plx:binaryOperator type="identityInequality">
								<plx:left>
									<plx:nameRef name="{$localName}"/>
								</plx:left>
								<plx:right>
									<plx:nullKeyword/>
								</plx:right>
							</plx:binaryOperator>
						</plx:condition>
						<plx:callInstance name="Dispose">
							<plx:callObject>
								<plx:nameRef name="{$localName}"/>
							</plx:callObject>
						</plx:callInstance>
					</plx:branch>
				</plx:finally>
			</plx:try>
		</xsl:variable>
		<xsl:variable name="tryInlineExpansionFragment">
			<!-- The returned inline expansion must not require an additional expansion. Do it here. -->
			<xsl:apply-templates select="exsl:node-set($rawTrySurrogateFragment)/child::*" mode="CollectInline">
				<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="tryInlineExpansion" select="exsl:node-set($tryInlineExpansionFragment)/child::*"/>
		<plxGen:inlineExpansion surrogatePreExpanded="true" childrenModified="true">
			<plxGen:expansion>
				<plx:local name="{$localName}">
					<xsl:copy-of select="@dataTypeName|@dataTypeQualifier"/>
					<xsl:copy-of select="plx:passTypeParam|plx:parametrizedDataTypeQualifier|plx:initialize"/>
				</plx:local>
				<xsl:copy-of select="$tryInlineExpansion/plxGen:expansion/child::*"/>
			</plxGen:expansion>
			<xsl:copy-of select="$tryInlineExpansion/plxGen:surrogate"/>
		</plxGen:inlineExpansion>
	</xsl:template>
	<xsl:template match="plx:binaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:variable name="negate" select="$type='typeInequality'"/>
		<xsl:if test="$negate">
			<xsl:text>!(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:choose>
			<xsl:when test="$type='add'">
				<xsl:text> + </xsl:text>
			</xsl:when>
			<xsl:when test="$type='assignNamed'">
				<xsl:text>=</xsl:text>
			</xsl:when>
			<xsl:when test="$type='bitwiseAnd'">
				<xsl:text> &amp; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='bitwiseExclusiveOr'">
				<xsl:text> ^ </xsl:text>
			</xsl:when>
			<xsl:when test="$type='bitwiseOr'">
				<xsl:text> | </xsl:text>
			</xsl:when>
			<xsl:when test="$type='booleanAnd'">
				<xsl:text> &amp;&amp; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='booleanOr'">
				<xsl:text> || </xsl:text>
			</xsl:when>
			<xsl:when test="$type='divide'">
				<xsl:text> / </xsl:text>
			</xsl:when>
			<xsl:when test="$type='equality'">
				<xsl:text> == </xsl:text>
			</xsl:when>
			<xsl:when test="$type='greaterThan'">
				<xsl:text> &gt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='greaterThanOrEqual'">
				<xsl:text> &gt;= </xsl:text>
			</xsl:when>
			<xsl:when test="$type='identityEquality'">
				<xsl:text> === </xsl:text>
			</xsl:when>
			<xsl:when test="$type='identityInequality'">
				<xsl:text> !== </xsl:text>
			</xsl:when>
			<xsl:when test="$type='inequality'">
				<xsl:text> != </xsl:text>
			</xsl:when>
			<xsl:when test="$type='lessThan'">
				<xsl:text> &lt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='lessThanOrEqual'">
				<xsl:text> &lt;= </xsl:text>
			</xsl:when>
			<xsl:when test="$type='modulus'">
				<xsl:text> % </xsl:text>
			</xsl:when>
			<xsl:when test="$type='multiply'">
				<xsl:text> * </xsl:text>
			</xsl:when>
			<xsl:when test="$type='shiftLeft'">
				<xsl:text> &lt;&lt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='shiftRight'">
				<xsl:text> &gt;&gt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='shiftRightZero'">
				<xsl:text> &gt;&gt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='shiftRightPreserve'">
				<xsl:text> &gt;&gt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='subtract'">
				<xsl:text> - </xsl:text>
			</xsl:when>
			<xsl:when test="$type='typeEquality'">
				<xsl:text> instanceof </xsl:text>
			</xsl:when>
			<xsl:when test="$type='typeInequality'">
				<!-- This whole expression is negated -->
				<xsl:text> instanceof </xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:if test="$negate">
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:branch">
		<xsl:param name="Indent"/>
		<xsl:text>if (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:break">
		<xsl:text>break</xsl:text>
	</xsl:template>
	<xsl:template match="plx:callInstance">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:callObject/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:choose>
			<!-- delegateCall handled in its own template -->
			<xsl:when test="@type = 'indexerCall'">
				<xsl:choose>
					<xsl:when test="parent::plx:left">
						<xsl:text>->set_Item</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>->get_Item</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:callInstance[@type='delegateCall']">
		<xsl:param name="Indent"/>
		<xsl:variable name="delegateReferenceSupport" select="boolean(@plxPHP:delegateReferenceSupport[.='true' or .='1'])"/>
		<xsl:choose>
			<xsl:when test="$delegateReferenceSupport">
				<xsl:text>call_user_func_array</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>call_user_func</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:call-template name="RenderPassParams">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="PassParams" select="plx:callObject"/>
			<xsl:with-param name="BracketPair" select="'()'"/>
			<xsl:with-param name="PartialHasFollowing" select="true()"/>
		</xsl:call-template>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="PartialHasPreceding" select="true()"/>
			<xsl:with-param name="DelegateReferenceSupport" select="$delegateReferenceSupport"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:callNew">
		<xsl:param name="Indent"/>
		<xsl:choose>
			<xsl:when test="@dataTypeIsSimpleArray='true' or @dataTypeIsSimpleArray=1">
				<!--<xsl:text>/*</xsl:text>
				<xsl:call-template name="RenderType">
					<xsl:with-param name="RenderArray" select="false()"/>
				</xsl:call-template>
				<xsl:text>*/</xsl:text>-->
				<xsl:variable name="initializer" select="plx:arrayInitializer"/>
				<xsl:choose>
					<xsl:when test="ancestor::plx:attribute">
						<xsl:text>{</xsl:text>
						<xsl:for-each select="$initializer">
							<xsl:call-template name="RenderArrayInitializer">
								<xsl:with-param name="Indent" select="$Indent"/>
								<xsl:with-param name="SingleLine" select="true()"/>
							</xsl:call-template>
						</xsl:for-each>
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$arrayOpen"/>
						<xsl:for-each select="$initializer">
							<xsl:call-template name="RenderArrayInitializer">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:call-template>
						</xsl:for-each>
						<xsl:value-of select="$arrayClose"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="inlineAttributeConstructor" select="not(plx:arrayInitializer) and not(substring(@dataTypeName,1,1)='.') and ancestor::plx:attribute"/>
				<xsl:choose>
					<xsl:when test="plx:arrayInitializer">
						<xsl:text>array</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$inlineAttributeConstructor">
								<xsl:text>@</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>new </xsl:text>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="@plxPHP:typeVariable">
								<xsl:text>$</xsl:text>
								<xsl:value-of select="@plxPHP:typeVariable"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="RenderType">
									<xsl:with-param name="RenderArray" select="false()"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="arrayDescriptor" select="plx:arrayDescriptor"/>
				<xsl:choose>
					<xsl:when test="$arrayDescriptor">
						<xsl:variable name="initializer" select="plx:arrayInitializer"/>
						<xsl:choose>
							<xsl:when test="$initializer">
								<!-- If we have an array initializer, then ignore the passed in
								parameters and render the full array descriptor brackets -->
								<xsl:choose>
									<xsl:when test="$arrayDescriptor">
										<xsl:for-each select="$arrayDescriptor">
											<xsl:call-template name="RenderArrayDescriptor"/>
										</xsl:for-each>
									</xsl:when>
								</xsl:choose>
								<xsl:for-each select="$initializer">
									<xsl:call-template name="RenderArrayInitializer">
										<xsl:with-param name="Indent" select="$Indent"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<!-- There is no initializer, so parameters are passed for the
							 first bound. We need the same number as parameters as the
							 first array rank, and we get the array descriptor brackets
							 for nested arrays. -->
								<xsl:variable name="passParams" select="plx:passParam"/>
								<xsl:call-template name="RenderPassParams">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="PassParams" select="$passParams"/>
									<xsl:with-param name="BracketPair" select="'[]'"/>
								</xsl:call-template>
								<xsl:choose>
									<xsl:when test="$arrayDescriptor">
										<xsl:for-each select="$arrayDescriptor">
											<xsl:if test="@rank!=count($passParams)">
												<xsl:message terminate="yes">The number of parameters must match the rank of the array if no initializer is specified.</xsl:message>
											</xsl:if>
											<xsl:for-each select="plx:arrayDescriptor">
												<xsl:call-template name="RenderArrayDescriptor"/>
											</xsl:for-each>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<xsl:if test="1!=count($passParams)">
											<xsl:message terminate="yes">The number of parameters must match the rank of the array if no initializer is specified.</xsl:message>
										</xsl:if>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<!-- Not an array constructor -->
						<xsl:call-template name="RenderPassParams">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="RenderEmptyBrackets" select="not($inlineAttributeConstructor)"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:callStatic">
		<xsl:param name="Indent"/>
		<xsl:variable name="typePrefixFragment">
			<xsl:call-template name="RenderType"/>
		</xsl:variable>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="StaticPrefix" select="string($typePrefixFragment)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:callThis">
		<xsl:param name="Indent"/>
		<xsl:variable name="accessor" select="@accessor"/>
		<xsl:variable name="isConstructorInitializer" select="parent::plx:initialize[parent::plx:function]"/>
		<xsl:choose>
			<xsl:when test="$accessor='base'">
				<xsl:text>parent</xsl:text>
				<xsl:if test="$isConstructorInitializer">
					<xsl:text>::__construct</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$accessor='explicitThis' or $accessor='static'">
				<!-- Render with the body as a prefix in case we need to use call_user_func -->
				<!--<xsl:text>self::</xsl:text>-->
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>$this</xsl:text>
				<xsl:if test="$isConstructorInitializer">
					<!-- This construct implies overloading, but we need to generate
					something to indicate an invalid PHP construct -->
					<xsl:text>->__construct</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="$accessor='explicitThis' or $accessor='static'">
				<xsl:call-template name="RenderCallBody">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Unqualified" select="true()"/>
					<xsl:with-param name="StaticPrefix" select="'self::'"/>
					<xsl:with-param name="DelegateReferenceSupport" select="boolean(@plxPHP:delegateReferenceSupport[.='true' or .='1'])"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderCallBody">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Unqualified" select="$isConstructorInitializer"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:case">
		<xsl:param name="Indent"/>
		<xsl:for-each select="plx:condition">
			<xsl:if test="position()!=1">
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$Indent"/>
			</xsl:if>
			<xsl:text>case </xsl:text>
			<xsl:apply-templates select="child::plx:*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
			<xsl:text>:</xsl:text>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:case | plx:fallbackCase" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="closeBlockCallback" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:case | plx:fallbackCase" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:variable name="caseCompletes" select="string(@caseCompletes)"/>
		<xsl:variable name="caseBlockExits">
			<xsl:choose>
				<xsl:when test="string-length($caseCompletes)">
					<xsl:if test="$caseCompletes='false' or $caseCompletes='0'">
						<xsl:text>1</xsl:text>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="TestNoBlockExit"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="0=string-length($caseBlockExits)">
			<xsl:value-of select="$Indent"/>
			<xsl:text>break;</xsl:text>
			<xsl:value-of select="$NewLine"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:cast[@type='testCast']" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:variable name="castTarget" select="child::plx:*[position()=last()]"/>
		<xsl:choose>
			<xsl:when test="$castTarget/self::plx:nameRef[not(@type) or (@type='local')]">
				<xsl:apply-imports/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="tempVariableName" select="concat($GeneratedVariablePrefix,$LocalItemKey,'ct')"/>
				<xsl:variable name="dataTypeAttributes" select="@*[not(local-name()='type')]"/>
				<xsl:variable name="dataTypeElements" select="plx:parametrizedDataTypeQualifier|plx:passTypeParam|plx:arrayDescriptor"/>
				<plxGen:inlineExpansion surrogatePreExpanded="false" key="{$LocalItemKey}" >
					<plxGen:expansion>
						<plx:local name="{$tempVariableName}">
							<xsl:copy-of select="$dataTypeAttributes"/>
							<xsl:copy-of select="$dataTypeElements"/>
							<plx:initialize>
								<xsl:copy-of select="child::plx:*[position()=last()]"/>
							</plx:initialize>
						</plx:local>
					</plxGen:expansion>
					<plxGen:surrogate>
						<plx:inlineStatement>
							<xsl:copy-of select="$dataTypeAttributes"/>
							<xsl:copy-of select="$dataTypeElements"/>
							<plx:conditionalOperator>
								<plx:condition>
									<plx:binaryOperator type="typeEquality">
										<plx:left>
											<plx:nameRef name="{$tempVariableName}"/>
										</plx:left>
										<plx:right>
											<plx:directTypeReference>
												<xsl:copy-of select="$dataTypeAttributes"/>
												<xsl:copy-of select="$dataTypeElements"/>
											</plx:directTypeReference>
										</plx:right>
									</plx:binaryOperator>
								</plx:condition>
								<plx:left>
									<plx:nameRef name="{$tempVariableName}"/>
								</plx:left>
								<plx:right>
									<plx:nullKeyword/>
								</plx:right>
							</plx:conditionalOperator>
						</plx:inlineStatement>
					</plxGen:surrogate>
				</plxGen:inlineExpansion>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:cast[@type='testCast']" mode="ReplaceInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:param name="Expansions"/>
		<xsl:copy-of select="$Expansions[@key=$LocalItemKey]/plxGen:surrogate/child::*"/>
	</xsl:template>
	<xsl:template match="plx:cast">
		<xsl:param name="Indent"/>
		<xsl:variable name="castTarget" select="child::plx:*[position()=last()]"/>
		<xsl:variable name="castType" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$castType='testCast'">
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text> instanceof </xsl:text>
				<xsl:call-template name="RenderType"/>
				<xsl:text> ? </xsl:text>
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text> : null</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<!-- Handles exceptionCast, unbox, primitiveChecked, primitiveUnchecked -->
				<!-- UNDONE: Distinguish primitiveChecked vs primitiveUnchecked cast -->
				<xsl:choose>
					<!-- UNDONE: NOW This is too liberal. An array cast is also supported. -->
					<xsl:when test="substring(@dataTypeName,1,1)='.'">
						<xsl:text>(</xsl:text>
						<xsl:call-template name="RenderType"/>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>/*(</xsl:text>
						<xsl:call-template name="RenderType"/>
						<xsl:text>)*/</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:catch">
		<xsl:param name="LocalItemKey"/>
		<xsl:text>catch (</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text> $</xsl:text>
		<xsl:choose>
			<xsl:when test="@localName">
				<xsl:value-of select="@localName"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($GeneratedVariablePrefix,$LocalItemKey,'ex')"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:class | plx:interface | plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:class | plx:interface | plx:structure" mode="IndentInfo">
		<xsl:choose>
			<xsl:when test="@partial='true' or @partial='1'">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-imports/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:class | plx:interface | plx:structure" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:value-of select="$NewLine"/>
		<xsl:variable name="pseudoClass">
			<xsl:variable name="ctors" select="plx:function[@name='.construct']"/>
			<xsl:copy>
				<xsl:copy-of select="@*[local-name()!='partial']"/>
				<plx:derivesFromClass dataTypeName="{@name}{$PartialBaseSuffix}"/>
				<xsl:for-each select="$ctors">
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<plx:initialize>
							<plx:callThis name=".implied" accessor="base">
								<xsl:for-each select="plx:param">
									<plx:passParam>
										<plx:nameRef name="{@name}" type="parameter"/>
									</plx:passParam>
								</xsl:for-each>
							</plx:callThis>
						</plx:initialize>
					</xsl:copy>
				</xsl:for-each>
			</xsl:copy>
		</xsl:variable>
		<xsl:value-of select="$Indent"/>
		<xsl:text>if (!class_exists('</xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:text>'))</xsl:text>
		<xsl:choose>
			<xsl:when test="$BraceStyle='Block'">
				<xsl:text> {</xsl:text>
				<xsl:value-of select="$NewLine"/>
			</xsl:when>
			<xsl:when test="$BraceStyle='C'">
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$Indent"/>
				<xsl:text>{</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$Indent"/>
				<xsl:value-of select="$SingleIndent"/>
				<xsl:text>{</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:for-each select="exsl:node-set($pseudoClass)/child::*">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:choose>
			<xsl:when test="$BraceStyle='Block' or $BraceStyle='C'">
				<xsl:value-of select="$Indent"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$Indent"/>
				<xsl:value-of select="$SingleIndent"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
		<xsl:value-of select="$NewLine"/>
	</xsl:template>
	<xsl:template match="plx:conditionalOperator">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:condition/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> ? </xsl:text>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> : </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:concatenate">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderExpressionList">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="BracketPair" select="''"/>
			<xsl:with-param name="ListSeparator" select="' . '"/>
			<xsl:with-param name="PrecedenceContext" select="."/>
			<!-- The Keys parameter needs a nodeset -->
			<xsl:with-param name="Keys" select="plx:BOGUS"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:continue">
		<!-- UNDONE: If the nearest enclosing iterator or loop is a loop
			 and checkCondition is 'after' and a beforeLoop statement is
			 specified, then we need to execute the beforeLoop statement
			 before calling continue. -->
		<xsl:text>continue</xsl:text>
	</xsl:template>
	<xsl:template match="plx:decrement">
		<xsl:param name="Indent"/>
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:if test="not($postfix)">
			<xsl:text>--</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:if test="$postfix">
			<xsl:text>--</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:defaultValueOf">
		<xsl:text>default(</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:delegate">
		<xsl:param name="Indent"/>
		<xsl:variable name="returns" select="plx:returns"/>
		<!--<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>-->
		<!--<xsl:if test="$returns">
			<xsl:for-each select="$returns">
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Prefix" select="'returns:'"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>-->
		<xsl:call-template name="RenderVisibility"/>
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:text>class </xsl:text>
		<!--<xsl:choose>
			<xsl:when test="$returns">
				<xsl:for-each select="$returns">
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
				<xsl:text> </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>void </xsl:text>
			</xsl:otherwise>
		</xsl:choose>-->
		<xsl:value-of select="@name"/>
		<xsl:text> extends Delegate</xsl:text>
		<xsl:variable name="typeParams" select="plx:typeParam"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:call-template name="RenderParams"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParamConstraints">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:detachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="plx:right/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:directTypeReference">
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<xsl:template match="plx:enum">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:text> /* enum */</xsl:text>
	</xsl:template>
	<xsl:template match="plx:enumItem">
		<xsl:param name="Indent"/>
		<!--<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>-->
		<xsl:text>const </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:enumItem" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="statementClose" select="';'"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:event">
		<xsl:param name="Indent"/>
		<xsl:variable name="explicitDelegate" select="plx:explicitDelegateType"/>
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="implicitDelegateName" select="@implicitDelegateName"/>
		<xsl:variable name="isSimpleExplicitImplementation"
			select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName and plx:onAdd and plx:onRemove"/>
		<xsl:if test="not($isSimpleExplicitImplementation) and not($explicitDelegate) and not(@modifier='override')">
			<!-- Use the provided parameters to define an implicit event procedure -->
			<!-- UNDONE: This won't work for interfaces, the handler will need to be
				 a sibiling to the interface. -->
			<!-- UNDONE: Some sort of comment here -->
			<xsl:call-template name="RenderVisibility"/>
			<xsl:text>delegate void </xsl:text>
			<xsl:choose>
				<xsl:when test="string-length($implicitDelegateName)">
					<xsl:value-of select="$implicitDelegateName"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$name"/>
					<xsl:text>Handler</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:variable name="typeParams" select="plx:typeParam"/>
			<xsl:if test="$typeParams">
				<xsl:call-template name="RenderTypeParams">
					<xsl:with-param name="TypeParams" select="$typeParams"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:call-template name="RenderParams"/>
			<xsl:if test="$typeParams">
				<xsl:call-template name="RenderTypeParamConstraints">
					<xsl:with-param name="TypeParams" select="$typeParams"/>
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>

		<!-- With an implicit delegate in place, get back to rendering the event itself -->
		<!--<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>-->
		<xsl:if test="not($isSimpleExplicitImplementation)">
			<xsl:if test="not(parent::plx:interface)">
				<xsl:call-template name="RenderVisibility"/>
				<xsl:call-template name="RenderProcedureModifier"/>
			</xsl:if>
			<xsl:call-template name="RenderReplacesName"/>
		</xsl:if>
		<xsl:text>event </xsl:text>
		<xsl:variable name="delegateTypeFragment">
			<xsl:variable name="passTypeParams" select="plx:passTypeParam"/>
			<xsl:choose>
				<xsl:when test="$explicitDelegate">
					<xsl:for-each select="$explicitDelegate">
						<xsl:copy>
							<xsl:copy-of select="@*"/>
							<xsl:copy-of select="$passTypeParams"/>
						</xsl:copy>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<DataType dataTypeName="{$name}Handler">
						<xsl:if test="string-length($implicitDelegateName)">
							<xsl:attribute name="dataTypeName">
								<xsl:value-of select="$implicitDelegateName"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:copy-of select="$passTypeParams"/>
					</DataType>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:for-each select="exsl:node-set($delegateTypeFragment)/child::*">
			<xsl:call-template name="RenderType"/>
		</xsl:for-each>
		<xsl:text> </xsl:text>
		<xsl:if test="$isSimpleExplicitImplementation">
			<xsl:for-each select="plx:interfaceMember">
				<xsl:call-template name="RenderType"/>
			</xsl:for-each>
			<xsl:text>.</xsl:text>
		</xsl:if>
		<xsl:value-of select="$name"/>
	</xsl:template>
	<xsl:template match="plx:event" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="'nakedBlock'"/>
			<xsl:with-param name="closeBlockCallback" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:event" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:variable name="contextIsStatic" select="@modifier='static'"/>
		<xsl:variable name="contextName" select="@name"/>
		<xsl:variable name="contextVisibility" select="@visibility"/>
		<xsl:variable name="generateForwardCalls">
			<xsl:for-each select="plx:interfaceMember">
				<xsl:if test="$contextIsStatic or @memberName!=$contextName or $contextVisibility!='public'">
					<xsl:text>x</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($generateForwardCalls)">
				<xsl:variable name="contextTypeParams" select="plx:typeParam"/>
				<xsl:variable name="contextParams" select="plx:param"/>
				<xsl:variable name="contextPassTypeParams" select="plx:passTypeParam"/>
				<xsl:variable name="contextExplicitDelegateType" select="plx:explicitDelegateType"/>
				<xsl:variable name="implicitDelegateName" select="@implicitDelegateName"/>
				<xsl:variable name="explicitDelegateTypeFragment">
					<xsl:choose>
						<xsl:when test="$contextExplicitDelegateType">
							<xsl:copy-of select="$contextExplicitDelegateType"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- Just reference the filled in implicit type -->
							<plx:explicitDelegateType dataTypeName="{$implicitDelegateName}">
								<xsl:if test="0=string-length($implicitDelegateName)">
									<xsl:attribute name="dataTypeName">
										<xsl:value-of select="$contextName"/>
										<xsl:text>Handler</xsl:text>
									</xsl:attribute>
								</xsl:if>
							</plx:explicitDelegateType>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:for-each select="plx:interfaceMember">
					<xsl:variable name="memberName" select="@memberName"/>
					<xsl:if test="$contextIsStatic or $memberName!=$contextName or $contextVisibility!='public'">
						<xsl:variable name="privateImplFragment">
							<xsl:variable name="typeName">
								<xsl:call-template name="RenderType"/>
							</xsl:variable>
							<xsl:variable name="forwardCallAccessor">
								<plx:callThis name="{$contextName}" type="event">
									<xsl:if test="$contextIsStatic">
										<xsl:attribute name="accessor">
											<xsl:text>static</xsl:text>
										</xsl:attribute>
									</xsl:if>
								</plx:callThis>
							</xsl:variable>
							<!-- This isn't schema tested. Ignore warnings. -->
							<plx:event name="{$typeName}.{$memberName}">
								<xsl:copy-of select="$contextTypeParams"/>
								<xsl:copy-of select="$contextParams"/>
								<xsl:copy-of select="$explicitDelegateTypeFragment"/>
								<xsl:copy-of select="$contextPassTypeParams"/>
								<plx:onAdd>
									<plx:attachEvent>
										<plx:left>
											<xsl:copy-of select="$forwardCallAccessor"/>
										</plx:left>
										<plx:right>
											<plx:valueKeyword/>
										</plx:right>
									</plx:attachEvent>
								</plx:onAdd>
								<plx:onRemove>
									<plx:detachEvent>
										<plx:left>
											<xsl:copy-of select="$forwardCallAccessor"/>
										</plx:left>
										<plx:right>
											<plx:valueKeyword/>
										</plx:right>
									</plx:detachEvent>
								</plx:onRemove>
							</plx:event>
						</xsl:variable>
						<xsl:value-of select="$NewLine"/>
						<xsl:for-each select="exsl:node-set($privateImplFragment)/child::*">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$NewLine"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:expression">
		<xsl:variable name="outputParens" select="@parens='true' or @parens='1'"/>
		<xsl:if test="$outputParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*"/>
		<xsl:if test="$outputParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:fallbackBranch">
		<xsl:text>else</xsl:text>
	</xsl:template>
	<xsl:template match="plx:fallbackCase">
		<xsl:text>default:</xsl:text>
	</xsl:template>
	<xsl:template match="plx:fallbackCatch">
		<xsl:text>catch</xsl:text>
	</xsl:template>
	<xsl:template match="plx:falseKeyword">
		<xsl:text>false</xsl:text>
	</xsl:template>
	<xsl:template match="plx:field">
		<xsl:param name="Indent"/>
		<xsl:call-template name="WriteDocBlock">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Contents">
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:choose>
			<xsl:when test="@const">
				<xsl:call-template name="RenderVisibility"/>
				<xsl:call-template name="RenderConst"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderVisibility"/>
				<xsl:call-template name="RenderStatic"/>
				<xsl:call-template name="RenderReplacesName"/>
				<xsl:call-template name="RenderReadOnly"/>
				<!--<xsl:call-template name="RenderType"/>-->
				<xsl:text>$</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="@name"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
			<xsl:if test="@plxPHP:reference[.='true' or .=1]">
				<xsl:text>&amp;</xsl:text>
			</xsl:if>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:finally">
		<xsl:text>finally</xsl:text>
	</xsl:template>
	<xsl:template match="plx:function">
		<xsl:param name="Indent"/>
		<xsl:variable name="name" select="@name"/>
		<xsl:choose>
			<xsl:when test="starts-with($name,'.')">
				<xsl:variable name="parentType" select="parent::plx:*"/>
				<xsl:variable name="className">
					<xsl:choose>
						<xsl:when test="$parentType">
							<xsl:value-of select="$parentType/@name"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- Snippet case, make it obvious that the snippet is incomplete -->
							<xsl:text>CLASSNAME</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$name='.construct'">
						<xsl:call-template name="RenderVisibility"/>
						<xsl:if test="@modifier='static'">
							<!-- Ignore modifiers other than static, don't call RenderProcedureModifier -->
							<xsl:text>static </xsl:text>
						</xsl:if>
						<xsl:text>function __construct</xsl:text>
						<xsl:call-template name="RenderParams"/>
						<!--<xsl:for-each select="plx:initialize/child::plx:callThis">
							<xsl:value-of select="$NewLine"/>
							<xsl:value-of select="$Indent"/>
							<xsl:value-of select="$SingleIndent"/>
							<xsl:text>: </xsl:text>
							<xsl:apply-templates select=".">
								<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
							</xsl:apply-templates>
						</xsl:for-each>-->
					</xsl:when>
					<xsl:when test="$name='.finalize'">
						<xsl:text>function __destruct()</xsl:text>
						<!--<xsl:value-of select="$className"/>
						<xsl:text>()</xsl:text>-->
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="returns" select="plx:returns"/>
				<!--<xsl:if test="$returns">
					<xsl:for-each select="$returns">
						<xsl:call-template name="RenderAttributes">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Prefix" select="'returns:'"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>-->
				<xsl:variable name="isSimpleExplicitImplementation"
					select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
				<xsl:if test="not($isSimpleExplicitImplementation)">
					<xsl:if test="not(parent::plx:interface)">
						<xsl:choose>
							<xsl:when test="not(@visibility='public') and plx:interfaceMember[current()/@name=@memberName]">
								<xsl:call-template name="RenderVisibility">
									<xsl:with-param name="Visibility" select="'public'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="RenderVisibility"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
					<xsl:call-template name="RenderProcedureModifier"/>
					<xsl:call-template name="RenderReplacesName"/>
				</xsl:if>
				<!--<xsl:choose>
					<xsl:when test="$returns">
						<xsl:for-each select="$returns">
							<xsl:call-template name="RenderType"/>
						</xsl:for-each>
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>void </xsl:text>
					</xsl:otherwise>
				</xsl:choose>-->
				<xsl:if test="$isSimpleExplicitImplementation">
					<xsl:for-each select="plx:interfaceMember">
						<xsl:call-template name="RenderType"/>
					</xsl:for-each>
					<xsl:text>.</xsl:text>
				</xsl:if>
				<xsl:text>function </xsl:text>
				<xsl:if test="@plxPHP:reference[.='true' or .=1]">
					<xsl:text>&amp;</xsl:text>
				</xsl:if>
				<xsl:value-of select="@name"/>
				<xsl:variable name="typeParams" select="plx:typeParam"/>
				<xsl:if test="$typeParams">
					<xsl:call-template name="RenderTypeParams">
						<xsl:with-param name="TypeParams" select="$typeParams"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:call-template name="RenderParams"/>
				<xsl:if test="$typeParams">
					<xsl:call-template name="RenderTypeParamConstraints">
						<xsl:with-param name="TypeParams" select="$typeParams"/>
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:function" mode="IndentInfo">
		<xsl:variable name="interfaceMembers" select="plx:interfaceMember"/>
		<xsl:choose>
			<xsl:when test="$interfaceMembers[not(@memberName=current()/@name)] and not(@visibility='privateInterfaceMember' and not(@modifier='static') and count($interfaceMembers)=1 and @name=$interfaceMembers[1]/@memberName)">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-imports/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:function" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:variable name="contextIsStatic" select="@modifier='static'"/>
		<xsl:variable name="contextName" select="@name"/>
		<xsl:variable name="contextVisibility" select="@visibility"/>
		<xsl:variable name="generateForwardCalls">
			<xsl:for-each select="plx:interfaceMember">
				<xsl:if test="$contextIsStatic or @memberName!=$contextName or $contextVisibility!='public'">
					<xsl:text>x</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($generateForwardCalls)">
				<xsl:variable name="contextReturns" select="plx:returns"/>
				<xsl:variable name="contextParams" select="plx:param"/>
				<xsl:variable name="contextTypeParams" select="plx:typeParam"/>
				<xsl:for-each select="plx:interfaceMember[not(@memberName=current()/@name)]">
					<xsl:variable name="memberName" select="@memberName"/>
					<xsl:if test="$contextIsStatic or $memberName!=$contextName or $contextVisibility!='public'">
						<xsl:variable name="privateImplFragment">
							<!-- This isn't schema tested. Ignore warnings. -->
							<plx:function name="{$memberName}" visibility="public">
								<xsl:copy-of select="$contextTypeParams"/>
								<xsl:copy-of select="$contextParams"/>
								<plx:comment>
									<xsl:text>Implements '</xsl:text>
									<xsl:value-of select="$memberName"/>
									<xsl:text>' for '</xsl:text>
									<xsl:call-template name="RenderType"/>
									<xsl:text>'</xsl:text>
								</plx:comment>
								<xsl:variable name="forwardCall">
									<plx:callThis name="{$contextName}">
										<xsl:if test="$contextIsStatic">
											<xsl:attribute name="accessor">
												<xsl:text>static</xsl:text>
											</xsl:attribute>
										</xsl:if>
										<xsl:for-each select="$contextTypeParams">
											<plx:passMemberTypeParam dataTypeName="{@name}"/>
										</xsl:for-each>
										<xsl:for-each select="$contextParams">
											<plx:passParam>
												<xsl:variable name="passType" select="string(@type)"/>
												<xsl:if test="$passType='out' or $passType='inOut'">
													<xsl:copy-of select="@type"/>
												</xsl:if>
												<plx:nameRef type="parameter" name="{@name}"/>
											</plx:passParam>
										</xsl:for-each>
									</plx:callThis>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="$contextReturns">
										<xsl:copy-of select="$contextReturns"/>
										<plx:return>
											<xsl:copy-of select="$forwardCall"/>
										</plx:return>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="$forwardCall"/>
									</xsl:otherwise>
								</xsl:choose>
							</plx:function>
						</xsl:variable>
						<xsl:value-of select="$NewLine"/>
						<xsl:for-each select="exsl:node-set($privateImplFragment)/child::*">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$NewLine"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:get">
		<xsl:param name="Indent"/>
		<xsl:for-each select="..">
			<xsl:variable name="returns" select="plx:returns"/>
			<xsl:variable name="isSimpleExplicitImplementation"
				select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
			<xsl:if test="not($isSimpleExplicitImplementation)">
				<xsl:if test="not(parent::plx:interface)">
					<xsl:call-template name="RenderVisibility"/>
					<xsl:call-template name="RenderProcedureModifier"/>
				</xsl:if>
				<xsl:call-template name="RenderReplacesName"/>
			</xsl:if>
			<xsl:text>function get</xsl:text>
			<xsl:variable name="name" select="@name"/>
			<xsl:variable name="isIndexer" select="parent::plx:*/@defaultMember=$name"/>
			<xsl:choose>
				<xsl:when test="$isIndexer">
					<xsl:text>this</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$isSimpleExplicitImplementation">
						<xsl:for-each select="plx:interfaceMember">
							<xsl:call-template name="RenderType"/>
						</xsl:for-each>
						<xsl:text>.</xsl:text>
					</xsl:if>
					<xsl:value-of select="$name"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:variable name="typeParams" select="plx:typeParam"/>
			<xsl:if test="$typeParams">
				<xsl:call-template name="RenderTypeParams">
					<xsl:with-param name="TypeParams" select="$typeParams"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="plx:param">
					<xsl:call-template name="RenderParams">
						<xsl:with-param name="BracketPair" select="'()'"/>
						<xsl:with-param name="RenderEmptyBrackets" select="$isIndexer"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$typeParams">
						<xsl:call-template name="RenderTypeParamConstraints">
							<xsl:with-param name="TypeParams" select="$typeParams"/>
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:call-template>
					</xsl:if>
					<xsl:text>()</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:gotoCase">
		<xsl:param name="Indent"/>
		<xsl:text>goto case </xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:increment">
		<xsl:param name="Indent"/>
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:if test="not($postfix)">
			<xsl:text>++</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:if test="$postfix">
			<xsl:text>++</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:function/plx:initialize">
		<xsl:param name="Indent"/>
		<xsl:for-each select="child::*">
			<xsl:call-template name="RenderElement">
				<!--<xsl:with-param name="Indent" select="$Indent"/>-->
				<xsl:with-param name="Statement" select="false()"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:function/plx:initialize" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="'simple'"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:iterator">
		<xsl:param name="Indent"/>
		<xsl:text>foreach (</xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text> as </xsl:text>
		<xsl:variable name="keyLocal" select="@plxPHP:keyName"/>
		<xsl:if test="$keyLocal">
			<!--<xsl:call-template name="RenderType">
				<xsl:with-param name="DataTypeName" select="plxPHP:keyDataTypeName"/>
			</xsl:call-template>
			<xsl:text> </xsl:text>-->
			<xsl:text>$</xsl:text>
			<xsl:value-of select="$keyLocal"/>
			<xsl:text> =&gt; </xsl:text>
		</xsl:if>
		<!--<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text>-->
		<xsl:if test="@plxPHP:reference[.='true' or .=1]">
			<xsl:text>&amp;</xsl:text>
		</xsl:if>
		<xsl:text>$</xsl:text>
		<xsl:value-of select="@localName"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:local">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderConst"/>
		<xsl:variable name="isGlobal" select="@plxPHP:global[.='true' or .=1]"/>
		<xsl:if test="$isGlobal">
			<xsl:text>global </xsl:text>
		</xsl:if>
		<!--<xsl:call-template name="RenderType"/>-->
		<xsl:text>$</xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:choose>
			<xsl:when test="plx:initialize">
				<xsl:for-each select="plx:initialize">
					<xsl:text> = </xsl:text>
					<xsl:if test="@plxPHP:reference[.='true' or .=1]">
						<xsl:text>&amp;</xsl:text>
					</xsl:if>
					<xsl:apply-templates select="child::*">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="not($isGlobal)">
				<xsl:text> = null</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:lock">
		<xsl:param name="Indent"/>
		<xsl:text>lock (</xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:loop">
		<xsl:param name="Indent"/>
		<xsl:variable name="initialize" select="plx:initializeLoop/child::plx:*"/>
		<xsl:variable name="condition" select="plx:condition/child::plx:*"/>
		<xsl:variable name="beforeLoop" select="plx:beforeLoop/child::plx:*"/>
		<xsl:choose>
			<xsl:when test="@checkCondition='after' and $condition">
				<xsl:if test="$initialize">
					<xsl:apply-templates select="$initialize">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
					<xsl:text>;</xsl:text>
					<xsl:value-of select="$NewLine"/>
					<xsl:value-of select="$Indent"/>
				</xsl:if>
				<xsl:text>do</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="not($initialize) and not($beforeLoop)">
						<xsl:choose>
							<xsl:when test="$condition">
								<xsl:text>while (</xsl:text>
								<xsl:apply-templates select="$condition">
									<xsl:with-param name="Indent" select="$Indent"/>
								</xsl:apply-templates>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>for (;;)</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>for (</xsl:text>
						<xsl:if test="$initialize">
							<xsl:apply-templates select="$initialize">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:text>;</xsl:text>
						<xsl:if test="$condition">
							<xsl:text> </xsl:text>
							<xsl:apply-templates select="$condition">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:text>;</xsl:text>
						<xsl:if test="$beforeLoop">
							<xsl:text> </xsl:text>
							<xsl:apply-templates select="$beforeLoop">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:text>)</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:loop" mode="IndentInfo">
		<xsl:choose>
			<xsl:when test="@checkCondition='after' and plx:condition">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-imports/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:loop" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:variable name="beforeLoop" select="plx:beforeLoop/child::plx:*"/>
		<xsl:if test="$beforeLoop">
			<xsl:value-of select="$SingleIndent"/>
			<xsl:apply-templates select="$beforeLoop">
				<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
			</xsl:apply-templates>
			<xsl:text>;</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:text> while (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::plx:*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>);</xsl:text>
		<xsl:value-of select="$NewLine"/>
	</xsl:template>
	<xsl:template match="plx:nameRef">
		<xsl:if test="not(@type='namedParameter')">
			<xsl:text>$</xsl:text>
		</xsl:if>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:namespace" mode="IndentInfo">
		<xsl:variable name="blockStyleFragment">
			<xsl:choose>
				<xsl:when test="parent::plx:namespace">
					<xsl:text>blockSibling</xsl:text>
				</xsl:when>
				<xsl:when test="@name='.global' and not(preceding-sibling::plx:namespace) and not(following-sibling::plx:namespace) and not(child::plx:namespace)">
					<xsl:text>nakedBlock</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>blockWithNestedSiblings</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="string($blockStyleFragment)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="fullNamespaceName">
		<xsl:variable name="currentName" select="string(@name)"/>
		<xsl:for-each select="parent::plx:namespace[not(@name='.global')]">
			<xsl:call-template name="fullNamespaceName"/>
			<xsl:text>\</xsl:text>
		</xsl:for-each>
		<xsl:value-of select="translate($currentName,'.','\')"/>
	</xsl:template>
	<xsl:template match="plx:namespace">
		<xsl:param name="Indent"/>
		<xsl:variable name="isGlobal" select="@name='.global'"/>
		<xsl:variable name="imports" select="ancestor::plx:root/plx:namespaceImport"/>
		<xsl:variable name="renderName" select="parent::plx:namespace or not($isGlobal) or preceding-sibling::plx:namespace or following-sibling::plx:namespace or child::plx:namespace"/>
		<xsl:if test="$renderName">
			<xsl:text>namespace </xsl:text>
			<xsl:if test="not($isGlobal)">
				<xsl:call-template name="fullNamespaceName"/>
			</xsl:if>
			<xsl:if test="$imports">
				<xsl:text>;</xsl:text>
				<xsl:value-of select="$NewLine"/>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$imports">
			<xsl:for-each select="$imports">
				<xsl:call-template name="RenderElement">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Statement" select="not($renderName) or position()!=last()"/>
				</xsl:call-template>
			</xsl:for-each>
			<!-- Brace will go after the last import, don't try to switch a brace style for this. -->
			<xsl:if test="$renderName">
				<xsl:text>;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:namespaceImport">
		<xsl:text>use </xsl:text>
		<xsl:if test="string-length(@alias)">
			<xsl:value-of select="@alias"/>
			<xsl:text> = </xsl:text>
		</xsl:if>
		<xsl:call-template name="fullNamespaceName"/>
	</xsl:template>
	<xsl:template match="plx:nullKeyword">
		<xsl:text>null</xsl:text>
	</xsl:template>
	<xsl:template match="plx:operatorFunction">
		<xsl:param name="Indent"/>
		<xsl:variable name="operatorType" select="string(@type)"/>
		<xsl:variable name="operatorNameFragment">
			<xsl:choose>
				<xsl:when test="$operatorType='add'">
					<xsl:text>+</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='bitwiseAnd'">
					<xsl:text>&amp;</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='bitwiseExclusiveOr'">
					<xsl:text>^</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='bitwiseNot'">
					<xsl:text>~</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='bitwiseOr'">
					<xsl:text>|</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='booleanNot'">
					<xsl:text>!</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='castNarrow'">
					<xsl:text>cast.explicit</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='castWiden'">
					<xsl:text>cast.implicit</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='decrement'">
					<xsl:text>--</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='divide'">
					<xsl:text>/</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='equality'">
					<xsl:text>==</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='greaterThan'">
					<xsl:text>&gt;</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='greaterThanOrEqual'">
					<xsl:text>&gt;=</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='increment'">
					<xsl:text>++</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='inequality'">
					<xsl:text>!=</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='integerDivide'">
					<xsl:text>op_IntegerDivision</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='isFalse'">
					<xsl:text>false</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='isTrue'">
					<xsl:text>true</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='lessThan'">
					<xsl:text>&lt;</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='lessThanOrEqual'">
					<xsl:text>&lt;=</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='like'">
					<xsl:text>op_Like</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='modulus'">
					<xsl:text>%</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='multiply'">
					<xsl:text>*</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='negative'">
					<xsl:text>-</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='positive'">
					<xsl:text>+</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='shiftLeft'">
					<xsl:text>&lt;&lt;</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='shiftRight'">
					<xsl:text>&gt;&gt;</xsl:text>
				</xsl:when>
				<xsl:when test="$operatorType='subtract'">
					<xsl:text>-</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="operatorName" select="string($operatorNameFragment)"/>
		<xsl:choose>
			<xsl:when test="starts-with($operatorName,'op_')">
				<!-- Occurs when the operator is not one that C# does automatically. These can still be
					 implemented to look like the operator, but we need to add the additional
					 System.Runtime.CompilerServices.SpecialName attribute -->
				<xsl:variable name="modifiedAttributesFragment">
					<xsl:copy-of select="plx:attribute"/>
					<plx:attribute dataTypeName="SpecialName" dataTypeQualifier="System.Runtime.CompilerServices"/>
				</xsl:variable>
				<!--<xsl:for-each select="exsl:node-set($modifiedAttributesFragment)">
					<xsl:call-template name="RenderAttributes">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
				</xsl:for-each>-->
			</xsl:when>
			<!--<xsl:otherwise>
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:otherwise>-->
		</xsl:choose>
		<xsl:variable name="returns" select="plx:returns"/>
		<!--<xsl:for-each select="$returns">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Prefix" select="'returns:'"/>
			</xsl:call-template>
		</xsl:for-each>-->
		<xsl:text>public static </xsl:text>
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:if test="starts-with($operatorName, 'cast.')">
			<xsl:value-of select="substring($operatorName, 6)"/>
			<xsl:text> operator </xsl:text>
		</xsl:if>
		<xsl:for-each select="$returns">
			<xsl:call-template name="RenderType"/>
		</xsl:for-each>
		<xsl:if test="not(starts-with($operatorName, 'cast.'))">
			<xsl:text> </xsl:text>
			<xsl:if test="not(starts-with($operatorName, 'op_'))">
				<xsl:text>operator </xsl:text>
			</xsl:if>
			<xsl:value-of select="$operatorName"/>
		</xsl:if>
		<xsl:call-template name="RenderParams"/>
	</xsl:template>
	<xsl:template match="plx:onAdd">
		<xsl:call-template name="RenderVisibility">
			<xsl:with-param name="Visibility" select="../@visibility"/>
		</xsl:call-template>
		<xsl:text>function add</xsl:text>
		<xsl:value-of select="../@name"/>
		<xsl:text>($value)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:onRemove">
		<xsl:call-template name="RenderVisibility">
			<xsl:with-param name="Visibility" select="../@visibility"/>
		</xsl:call-template>
		<xsl:text>function remove</xsl:text>
		<xsl:value-of select="../@name"/>
		<xsl:text>($value)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:pragma">
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:variable name="data" select="string(@data)"/>
		<xsl:choose>
			<xsl:when test="$type='alternateConditional'">
				<xsl:text>#elif </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='alternateNotConditional'">
				<xsl:text>#elif !</xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='conditional'">
				<xsl:text>#if </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='closeConditional'">
				<xsl:text>#endif</xsl:text>
				<xsl:if test="string-length($data)">
					<xsl:text> // </xsl:text>
					<xsl:value-of select="$data"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$type='closeRegion'">
				<xsl:text>#endregion</xsl:text>
				<xsl:if test="string-length($data)">
					<xsl:text> // </xsl:text>
					<xsl:value-of select="$data"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$type='fallbackConditional'">
				<xsl:text>#else</xsl:text>
				<xsl:if test="string-length($data)">
					<xsl:text> // </xsl:text>
					<xsl:value-of select="$data"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$type='notConditional'">
				<xsl:text>#if !</xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='region'">
				<xsl:text>#region </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='warningDisable'">
				<xsl:text>#pragma warning disable </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='warningRestore'">
				<xsl:text>#pragma warning restore </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:property">
		<xsl:param name="Indent"/>
		<!--<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>-->
		<xsl:variable name="returns" select="plx:returns"/>
		<!--<xsl:for-each select="$returns">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Prefix" select="'returns:'"/>
			</xsl:call-template>
		</xsl:for-each>-->
		<xsl:variable name="isSimpleExplicitImplementation"
			select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
		<xsl:if test="not($isSimpleExplicitImplementation)">
			<xsl:if test="not(parent::plx:interface)">
				<xsl:call-template name="RenderVisibility"/>
				<xsl:call-template name="RenderProcedureModifier"/>
			</xsl:if>
			<xsl:call-template name="RenderReplacesName"/>
		</xsl:if>
		<xsl:for-each select="$returns">
			<xsl:call-template name="RenderType"/>
		</xsl:for-each>
		<xsl:text> </xsl:text>
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="isIndexer" select="parent::plx:*/@defaultMember=$name"/>
		<xsl:choose>
			<xsl:when test="$isIndexer">
				<xsl:text>this</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$isSimpleExplicitImplementation">
					<xsl:for-each select="plx:interfaceMember">
						<xsl:call-template name="RenderType"/>
					</xsl:for-each>
					<xsl:text>.</xsl:text>
				</xsl:if>
				<xsl:value-of select="$name"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:variable name="typeParams" select="plx:typeParam"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:call-template name="RenderParams">
			<xsl:with-param name="BracketPair" select="'[]'"/>
			<xsl:with-param name="RenderEmptyBrackets" select="$isIndexer"/>
		</xsl:call-template>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParamConstraints">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:property" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="'nakedBlock'"/>
		</xsl:call-template>
		<!--<xsl:variable name="interfaceMembers" select="plx:interfaceMember"/>
		<xsl:choose>
			<xsl:when test="$interfaceMembers and not(@visibility='privateInterfaceMember' and not(@modifier='static') and count($interfaceMembers)=1 and @name=$interfaceMembers[1]/@memberName)">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-imports/>
			</xsl:otherwise>
		</xsl:choose>-->
	</xsl:template>
	<xsl:template match="plx:property" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:variable name="contextIsStatic" select="@modifier='static'"/>
		<xsl:variable name="contextName" select="@name"/>
		<xsl:variable name="contextVisibility" select="@visibility"/>
		<!-- UNDONE: Deal with default member, generate indexer calls as needed, etc -->
		<xsl:variable name="generateForwardCalls">
			<xsl:for-each select="plx:interfaceMember">
				<xsl:if test="$contextIsStatic or @memberName!=$contextName or $contextVisibility!='public'">
					<xsl:text>x</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($generateForwardCalls)">
				<xsl:variable name="context" select="."/>
				<xsl:variable name="contextTypeParams" select="plx:typeParam"/>
				<xsl:variable name="contextParams" select="plx:param"/>
				<xsl:for-each select="plx:interfaceMember">
					<xsl:variable name="memberName" select="@memberName"/>
					<xsl:if test="$contextIsStatic or $memberName!=$contextName or $contextVisibility!='public'">
						<xsl:variable name="privateImplFragment">
							<xsl:variable name="typeName">
								<xsl:call-template name="RenderType"/>
							</xsl:variable>
							<xsl:variable name="forwardCall">
								<plx:callThis name="{$contextName}" type="property">
									<xsl:if test="$contextIsStatic">
										<xsl:attribute name="accessor">
											<xsl:text>static</xsl:text>
										</xsl:attribute>
									</xsl:if>
									<xsl:for-each select="$contextTypeParams">
										<plx:passMemberTypeParam dataTypeName="{@name}"/>
									</xsl:for-each>
									<xsl:for-each select="$contextParams">
										<plx:passParam>
											<xsl:variable name="passType" select="string(@type)"/>
											<xsl:if test="$passType='out' or $passType='inOut'">
												<xsl:copy-of select="@type"/>
											</xsl:if>
											<plx:nameRef type="parameter" name="{@name}"/>
										</plx:passParam>
									</xsl:for-each>
								</plx:callThis>
							</xsl:variable>
							<!-- This isn't schema tested. Ignore warnings. -->
							<plx:property name="{$typeName}.{$memberName}">
								<xsl:copy-of select="$contextTypeParams"/>
								<xsl:copy-of select="$contextParams"/>
								<xsl:copy-of select="$context/plx:returns"/>
								<xsl:if test="$context/plx:get">
									<plx:get>
										<plx:return>
											<xsl:copy-of select="$forwardCall"/>
										</plx:return>
									</plx:get>
								</xsl:if>
								<xsl:if test="$context/plx:set">
									<plx:assign>
										<plx:left>
											<xsl:copy-of select="$forwardCall"/>
										</plx:left>
										<plx:right>
											<plx:valueKeyword/>
										</plx:right>
									</plx:assign>
								</xsl:if>
							</plx:property>
						</xsl:variable>
						<xsl:value-of select="$NewLine"/>
						<xsl:for-each select="exsl:node-set($privateImplFragment)/child::*">
							<xsl:call-template name="RenderElement">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$NewLine"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:return">
		<xsl:param name="Indent"/>
		<xsl:variable name="retVal" select="child::*"/>
		<xsl:text>return</xsl:text>
		<xsl:if test="$retVal">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select="$retVal">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:set">
		<xsl:param name="Indent"/>
		<xsl:for-each select="..">
			<xsl:variable name="returns" select="plx:returns"/>
			<xsl:variable name="isSimpleExplicitImplementation"
				select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
			<xsl:if test="not($isSimpleExplicitImplementation)">
				<xsl:if test="not(parent::plx:interface)">
					<xsl:call-template name="RenderVisibility"/>
					<xsl:call-template name="RenderProcedureModifier"/>
				</xsl:if>
				<xsl:call-template name="RenderReplacesName"/>
			</xsl:if>
			<xsl:text>function set</xsl:text>
			<xsl:variable name="name" select="@name"/>
			<xsl:variable name="isIndexer" select="parent::plx:*/@defaultMember=$name"/>
			<xsl:choose>
				<xsl:when test="$isIndexer">
					<xsl:text>this</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$isSimpleExplicitImplementation">
						<xsl:for-each select="plx:interfaceMember">
							<xsl:call-template name="RenderType"/>
						</xsl:for-each>
						<xsl:text>.</xsl:text>
					</xsl:if>
					<xsl:value-of select="$name"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:variable name="typeParams" select="plx:typeParam"/>
			<xsl:if test="$typeParams">
				<xsl:call-template name="RenderTypeParams">
					<xsl:with-param name="TypeParams" select="$typeParams"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:variable name="valueParamFragment">
				<plx:param name="value">
					<xsl:for-each select="plx:returns">
						<xsl:copy-of select="@dataTypeName|@dataTypeQualifier|@dataTypeIsSimpleArray"/>
						<xsl:copy-of select="child::*"/>
					</xsl:for-each>
				</plx:param>
			</xsl:variable>
			<xsl:call-template name="RenderParams">
				<xsl:with-param name="BracketPair" select="'()'"/>
				<xsl:with-param name="RenderEmptyBrackets" select="$isIndexer"/>
				<xsl:with-param name="ExtraParams" select="exsl:node-set($valueParamFragment)/child::*"/>
			</xsl:call-template>
			<xsl:if test="$typeParams">
				<xsl:call-template name="RenderTypeParamConstraints">
					<xsl:with-param name="TypeParams" select="$typeParams"/>
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:string">
		<xsl:variable name="rawValue">
			<xsl:call-template name="RenderRawString"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="ancestor::plx:attribute">
				<xsl:call-template name="RenderAttributeString">
					<xsl:with-param name="String" select="string($rawValue)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderString">
					<xsl:with-param name="String" select="string($rawValue)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="TypeKeyword" select="'struct'"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:switch">
		<xsl:param name="Indent"/>
		<xsl:text>switch (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:thisKeyword">
		<xsl:text>$this</xsl:text>
	</xsl:template>
	<xsl:template match="plx:throw">
		<xsl:param name="Indent"/>
		<xsl:text>throw</xsl:text>
		<xsl:for-each select="child::plx:*">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select=".">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:trueKeyword">
		<xsl:text>true</xsl:text>
	</xsl:template>
	<xsl:template match="plx:try">
		<xsl:text>try</xsl:text>
	</xsl:template>
	<xsl:template match="plx:typeOf">
		<xsl:text>gettype(</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:unaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$type='booleanNot'">
				<xsl:text>!</xsl:text>
			</xsl:when>
			<xsl:when test="$type='bitwiseNot'">
				<xsl:text>~</xsl:text>
			</xsl:when>
			<xsl:when test="$type='negative'">
				<xsl:text>-</xsl:text>
			</xsl:when>
			<xsl:when test="$type='positive'">
				<xsl:text>+</xsl:text>
			</xsl:when>
			<xsl:when test="$type='clone'">
				<xsl:text>clone </xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:value">
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:variable name="data" select="string(@data)"/>
		<xsl:choose>
			<xsl:when test="$type='char'">
				<xsl:text>'</xsl:text>
				<xsl:variable name="rawCharData" select="substring($data,1,1)"/>
				<xsl:choose>
					<xsl:when test="$rawCharData='&#xd;'">
						<xsl:text>\r</xsl:text>
					</xsl:when>
					<xsl:when test="$rawCharData='&#xa;'">
						<xsl:text>\n</xsl:text>
					</xsl:when>
					<xsl:when test='$rawCharData="&apos;"'>
						<xsl:text>\'</xsl:text>
					</xsl:when>
					<xsl:when test="$rawCharData='\'">
						<xsl:text>\\</xsl:text>
					</xsl:when>
					<xsl:when test="$rawCharData='&#x9;'">
						<xsl:text>\t</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$rawCharData"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:when test="$type='hex2' or $type='hex4' or $type='hex8'">
				<xsl:text>0x</xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$data"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:valueKeyword">
		<xsl:text>$value</xsl:text>
	</xsl:template>

	<!-- TopLevel templates, used for rendering snippets only -->
	<xsl:template match="plx:arrayDescriptor" mode="TopLevel">
		<xsl:call-template name="RenderArrayDescriptor"/>
	</xsl:template>
	<xsl:template match="plx:arrayInitializer">
		<!-- Note not TopLevel to allow inline expansion -->
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderArrayInitializer">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:interfaceMember" mode="TopLevel">
		<xsl:call-template name="RenderType"/>
		<xsl:text>.</xsl:text>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:derivesFromClass" mode="TopLevel">
		<xsl:text>extends </xsl:text>
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<xsl:template match="plx:implementsInterface" mode="TopLevel">
		<xsl:text>implements </xsl:text>
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<xsl:template match="plx:passTypeParam|plx:passMemberTypeParam|plx:returns|plx:explicitDelegateType|plx:typeConstraint" mode="TopLevel">
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<xsl:template match="plx:parametrizedDataTypeQualifier" mode="TopLevel">
		<xsl:call-template name="RenderType">
			<!-- No reason to check for an array here -->
			<xsl:with-param name="RenderArray" select="false()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:passParam">
		<!-- Note not TopLevel to allow inline expansion -->
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderPassParams">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="PassParams" select="."/>
			<xsl:with-param name="BracketPair" select="''"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:passParamArray">
		<!-- Note not TopLevel to allow inline expansion -->
		<xsl:param name="Indent"/>
		<xsl:text>array</xsl:text>
		<xsl:call-template name="RenderPassParams">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="PassParams" select="plx:passParam"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:param" mode="TopLevel">
		<xsl:for-each select="..">
			<xsl:call-template name="RenderParams">
				<xsl:with-param name="BracketPair" select="''"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="plx:typeParam" mode="TopLevel">
		<xsl:param name="Indent"/>
		<!-- Note that this isn't quite a type param (the constraints go after the params),
		but gives us the information we want. -->
		<xsl:call-template name="RenderTypeParams">
			<xsl:with-param name="TypeParams" select="."/>
		</xsl:call-template>
		<xsl:call-template name="RenderTypeParamConstraints">
			<xsl:with-param name="TypeParams" select="."/>
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="SnippetFormat" select="true()"/>
		</xsl:call-template>
	</xsl:template>

	<!-- Named templates -->
	<xsl:template name="RepeatString">
		<xsl:param name="Count"/>
		<xsl:param name="String"/>
		<xsl:value-of select="$String"/>
		<xsl:if test="$Count &gt; 1">
			<xsl:call-template name="RepeatString">
				<xsl:with-param name="Count" select="$Count - 1"/>
				<xsl:with-param name="String" select="$String"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:docComment">
		<xsl:param name="Indent"/>
		<xsl:call-template name="WriteDocBlock">
			<xsl:with-param name="Indent"/>
			<xsl:with-param name="LineAfter" select="false()"/>
			<xsl:with-param name="Contents">
				<xsl:variable name="docBodyFragment">
					<xsl:apply-imports/>
				</xsl:variable>
				<xsl:variable name="docBody" select="string($docBodyFragment)"/>
				<xsl:if test="$docBody">
					<xsl:value-of select="$docBody"/>
					<xsl:value-of select="$NewLine"/>
					<xsl:value-of select="$Indent"/>
				</xsl:if>
				<xsl:for-each select="../..">
					<xsl:call-template name="RenderAttributes">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="InvokedByDocComment" select="true()"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="WriteDocBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="Contents"/>
		<xsl:param name="LineAfter" select="true()"/>
		<xsl:variable name="contentsString" select="string($Contents)"/>
		<xsl:if test="$contentsString">
			<xsl:text>/**</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
			<xsl:value-of select="$contentsString"/>
			<xsl:text>*/</xsl:text>
			<xsl:if test="$LineAfter">
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$Indent"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderAttribute">
		<xsl:param name="Indent"/>
		<xsl:variable name="attributePrefix" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="not($attributePrefix)"/>
			<xsl:when test="$attributePrefix='assembly'">
				<xsl:text>assembly: </xsl:text>
			</xsl:when>
			<xsl:when test="$attributePrefix='module'">
				<xsl:text>module: </xsl:text>
			</xsl:when>
			<xsl:when test="$attributePrefix='implicitField'">
				<xsl:text>field: </xsl:text>
			</xsl:when>
			<xsl:when test="$attributePrefix='implicitAccessorFunction'">
				<xsl:text>method: </xsl:text>
			</xsl:when>
			<xsl:when test="$attributePrefix='implicitValueParameter'">
				<xsl:text>param: </xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:variable name="rawAttributeName" select="@dataTypeName"/>
		<xsl:variable name="attributeNameFragment">
			<xsl:choose>
				<xsl:when test="string-length($rawAttributeName)&gt;9 and contains($rawAttributeName,'Attribute')">
					<xsl:choose>
						<xsl:when test="substring-after($rawAttributeName,'Attribute')">
							<xsl:value-of select="$rawAttributeName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="substring($rawAttributeName, 1, string-length($rawAttributeName)-9)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$rawAttributeName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="RenderType">
			<xsl:with-param name="DataTypeName" select="string($attributeNameFragment)"/>
		</xsl:call-template>
		<!-- Make sure any named arguments go last. This cannot be controlled 100% by the caller
			 because passParamArray always comes after passParam. -->
		<xsl:variable name="namedParameters" select="plx:passParam[plx:binaryOperator[@type='assignNamed']]"/>
		<xsl:choose>
			<xsl:when test="$namedParameters">
				<xsl:variable name="unnamedParameters" select="plx:passParam[not(plx:binaryOperator[@type='assignNamed'])]|plx:passParamArray/plx:passParam"/>
				<!-- Don't use a fragment here to facilitate (temporary) alternate renderings when
				an ancestor attribute is on the stack -->
				<xsl:if test="$unnamedParameters">
					<xsl:call-template name="RenderPassParams">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="PassParams" select="$unnamedParameters"/>
						<xsl:with-param name="PartialHasFollowing" select="true()"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="PassParams" select="$namedParameters"/>
					<xsl:with-param name="PartialHasPreceding" select="boolean($unnamedParameters)"/>
				</xsl:call-template>
				<!--<xsl:variable name="reorderedPassParamsFragment">
					<xsl:copy-of select="plx:passParam[not(plx:binaryOperator[@type='assignNamed'])]|plx:passParamArray/plx:passParam"/>
					<xsl:copy-of select="$namedParameters"/>
				</xsl:variable>
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="PassParams" select="exsl:node-set($reorderedPassParamsFragment)/child::*"/>
				</xsl:call-template>-->
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="RenderEmptyBrackets" select="false()"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:attribute">
		<!-- Note that this is called by the preview window only, provide a mockup. -->
		<xsl:variable name="dummyFragment">
			<plx:root>
				<xsl:copy-of select="."/>
			</plx:root>
		</xsl:variable>
		<xsl:text>/**</xsl:text>
		<xsl:value-of select="$NewLine"/>
		<xsl:for-each select="exsl:node-set($dummyFragment)/*">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="''"/>
				<xsl:with-param name="Inline" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:value-of select="$NewLine"/>
		<xsl:text>*/</xsl:text>
	</xsl:template>
	<xsl:template name="RenderAttributes">
		<xsl:param name="Indent"/>
		<xsl:param name="Inline" select="false()"/>
		<xsl:param name="Prefix" select="''"/>
		<xsl:param name="InvokedByDocComment" select="false()"/>
		<xsl:if test="$InvokedByDocComment or not(plx:leadingInfo/plx:docComment)">
			<xsl:choose>
				<xsl:when test="$Inline">
					<!--Put them all in a single bracket-->
					<xsl:for-each select="plx:attribute">
						<xsl:choose>
							<xsl:when test="position()=1">
								<xsl:text>* @</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text> @</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="$Prefix"/>
						<xsl:call-template name="RenderAttribute">
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="plx:attribute">
						<xsl:text>* @</xsl:text>
						<xsl:value-of select="$Prefix"/>
						<xsl:call-template name="RenderAttribute">
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:call-template>
						<xsl:value-of select="$NewLine"/>
						<xsl:value-of select="$Indent"/>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderArrayDescriptor">
		<xsl:text>[</xsl:text>
		<xsl:if test="@rank &gt; 1">
			<xsl:call-template name="RepeatString">
				<xsl:with-param name="Count" select="@rank - 1"/>
				<xsl:with-param name="String" select="','"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>]</xsl:text>
		<xsl:for-each select="plx:arrayDescriptor">
			<xsl:call-template name="RenderArrayDescriptor"/>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="RenderArrayInitializer">
		<xsl:param name="Indent"/>
		<xsl:param name="SingleLine" select="false()"/>
		<xsl:param name="InitializerKeys"/>
		<xsl:param name="External" select="true()"/>
		<xsl:choose>
			<xsl:when test="$External">
				<xsl:call-template name="RenderArrayInitializer">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="SingleLine" select="$SingleLine"/>
					<xsl:with-param name="External" select="false()"/>
					<xsl:with-param name="InitializerKeys" select="following-sibling::plxPHP:arrayInitializerKeys"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="nestedInitializers" select="plx:arrayInitializer"/>
				<!-- We either get nested expressions or nested initializers, but not both -->
				<xsl:choose>
					<xsl:when test="$nestedInitializers">
						<xsl:variable name="nestedKeys" select="$InitializerKeys/plxPHP:arrayInitializerKeys"/>
						<xsl:for-each select="$nestedInitializers">
							<xsl:variable name="nestedPosition" select="position()"/>
							<xsl:if test="$nestedPosition!=1">
								<xsl:text>, </xsl:text>
							</xsl:if>
							<xsl:choose>
								<xsl:when test="$SingleLine">
									<xsl:call-template name="RenderArrayInitializer">
										<xsl:with-param name="Indent" select="$Indent"/>
										<xsl:with-param name="SingleLine" select="$SingleLine"/>
										<xsl:with-param name="External" select="false()"/>
										<xsl:with-param name="InitializerKeys" select="$nestedKeys[$nestedPosition]"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
									<xsl:value-of select="$NewLine"/>
									<xsl:value-of select="$nextIndent"/>
									<xsl:call-template name="RenderArrayInitializer">
										<xsl:with-param name="Indent" select="$nextIndent"/>
										<xsl:with-param name="SingleLine" select="$SingleLine"/>
										<xsl:with-param name="External" select="false()"/>
										<xsl:with-param name="InitializerKeys" select="$nestedKeys[$nestedPosition]"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="$SingleLine">
						<xsl:call-template name="RenderExpressionList">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="BracketPair" select="''"/>
							<xsl:with-param name="Keys" select="$InitializerKeys"/>
							<xsl:with-param name="KeySeparator" select="' =&gt; '"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
						<xsl:call-template name="RenderExpressionList">
							<xsl:with-param name="Indent" select="$nextIndent"/>
							<xsl:with-param name="BracketPair" select="''"/>
							<xsl:with-param name="Keys" select="$InitializerKeys"/>
							<xsl:with-param name="KeySeparator" select="' =&gt; '"/>
							<xsl:with-param name="BeforeFirstItem" select="concat($NewLine,$nextIndent)"/>
							<xsl:with-param name="ListSeparator" select="concat(',',$NewLine,$nextIndent)"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderCallBody">
		<xsl:param name="Indent"/>
		<!-- Helper function to render most of a call. The caller has already
			 been set before this call unless it is passed in with a StaticPrefix -->
		<xsl:param name="Unqualified" select="false()"/>
		<xsl:param name="StaticPrefix" select="''"/>
		<!-- Forwarded to RenderPassParams -->
		<xsl:param name="PartialHasPreceding" select="false()"/>
		<!-- Use call_user_func_array instead of call_user_func, parameters pass in array -->
		<xsl:param name="DelegateReferenceSupport" select="false()"/>
		<!-- Render the name -->
		<xsl:variable name="callType" select="string(@type)"/>
		<xsl:variable name="isIndexer" select="$callType='arrayIndexer'"/>
		<xsl:variable name="leftOfAssign" select="parent::plx:left[parent::plx:assign]"/>
		<!-- The name should be set to .implied in this case -->
		<xsl:variable name="memberNameExpression" select="plxPHP:callExpression/child::*"/>
		<xsl:variable name="memberExpressionFragment">
			<xsl:if test="$memberNameExpression">
				<xsl:apply-templates select="$memberNameExpression">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="memberExpression" select="string($memberExpressionFragment)"/>
		<xsl:variable name="passParams" select="plx:passParam|plx:passParamArray"/>
		<xsl:variable name="compoundMemberExpression" select="$StaticPrefix and $memberExpression and (not(($memberNameExpression[self::plx:nameRef] and not($passParams[@plxPHP:reference[.='true' or .=1]])) or $callType='property' or $callType='event'))"/>
		<xsl:variable name="hasParams" select="boolean($passParams) or $PartialHasPreceding or ($leftOfAssign and ($callType='property' or $callType='indexerCall'))"/>
		<xsl:choose>
			<xsl:when test="$compoundMemberExpression">
				<xsl:choose>
					<xsl:when test="$DelegateReferenceSupport and $hasParams">
						<xsl:text>call_user_func_array('</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>call_user_func('</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="$StaticPrefix"/>
				<xsl:text>' . </xsl:text>
			</xsl:when>
			<xsl:when test="$StaticPrefix">
				<xsl:value-of select="$StaticPrefix"/>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="(not(@name='.implied') and not($isIndexer)) or $memberExpression">
			<xsl:choose>
				<xsl:when test="$callType = 'methodReference'">
					<xsl:text>,"</xsl:text>
				</xsl:when>
				<xsl:when test="not($Unqualified)">
					<xsl:choose>
						<xsl:when test="@dataTypeName='.global'"></xsl:when>
						<xsl:when test="self::plx:callStatic or @accessor='base'">
							<xsl:text>::</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>-></xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="$callType = 'property'">
					<xsl:choose>
						<xsl:when test="$compoundMemberExpression">
							<xsl:choose>
								<xsl:when test="$leftOfAssign">
									<xsl:text>'set' . </xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>'get' . </xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="$memberExpression"/>
						</xsl:when>
						<xsl:when test="$memberExpression">
							<xsl:choose>
								<xsl:when test="$leftOfAssign">
									<xsl:text>{'set' . </xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>{'get' . </xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="$memberExpression"/>
							<xsl:text>}</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$leftOfAssign">
									<xsl:text>set</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>get</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$callType='field' and (self::plx:callStatic or self::plx:callThis[@accessor='static'])">
					<xsl:if test="not(@dataTypeName='.global') and not(@plxPHP:const[.='true' or .='1'])">
						<xsl:text>$</xsl:text>
					</xsl:if>
					<xsl:choose>
						<xsl:when test="memberExpression">
							<xsl:choose>
								<xsl:when test="$StaticPrefix">
									<!-- Works with or without compound expression -->
									<xsl:value-of select="memberExpression"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>{</xsl:text>
									<xsl:value-of select="memberExpression"/>
									<xsl:text>}</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$callType='event'">
					<xsl:choose>
						<xsl:when test="$compoundMemberExpression">
							<xsl:choose>
								<xsl:when test="$leftOfAssign">
									<xsl:text>'remove' . </xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>'add' . </xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="$memberExpression"/>
						</xsl:when>
						<xsl:when test="$memberExpression">
							<xsl:choose>
								<xsl:when test="ancestor::plx:detachEvent">
									<xsl:text>{'remove' . </xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>{'add' . </xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="$memberExpression"/>
							<xsl:text>}</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="ancestor::plx:detachEvent">
									<xsl:text>remove</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>add</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$memberExpression">
					<xsl:choose>
						<xsl:when test="$StaticPrefix">
							<xsl:value-of select="$memberExpression"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>{</xsl:text>
							<xsl:value-of select="$memberExpression"/>
							<xsl:text>}</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@name"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$callType = 'methodReference'">
				<xsl:text>"</xsl:text>
			</xsl:if>
		</xsl:if>
		<!-- Add member type params -->
		<xsl:call-template name="RenderPassTypeParams">
			<xsl:with-param name="PassTypeParams" select="plx:passMemberTypeParam"/>
		</xsl:call-template>
		<xsl:variable name="bracketPairFragment">
			<xsl:choose>
				<xsl:when test="$callType='indexerCall' or $callType='property' or $callType='methodCall' or $callType='delegateCall' or string-length($callType)=0">
					<xsl:choose>
						<xsl:when test="$DelegateReferenceSupport and $hasParams and $compoundMemberExpression">
							<xsl:text>[]</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>()</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$isIndexer">
					<xsl:text>[]</xsl:text>
				</xsl:when>
				<!-- field, event, methodReference handled with silence-->
				<!-- UNDONE: fireStandardEvent, fireCustomEvent -->
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="bracketPair" select="string($bracketPairFragment)"/>
		<xsl:choose>
			<xsl:when test="$bracketPair">
				<xsl:choose>
					<xsl:when test="$hasParams">
						<xsl:choose>
							<xsl:when test="$leftOfAssign and ($callType='indexerCall' or $callType='property')">
								<xsl:call-template name="RenderPassParams">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="PassParams" select="$passParams"/>
									<xsl:with-param name="ExtraParam" select="$leftOfAssign/following-sibling::plx:right[1]/child::*"/>
									<xsl:with-param name="BracketPair" select="$bracketPair"/>
									<xsl:with-param name="PartialHasPreceding" select="$compoundMemberExpression"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="$DelegateReferenceSupport and ($PartialHasPreceding or $compoundMemberExpression)">
									<xsl:text>, </xsl:text>
								</xsl:if>
								<xsl:call-template name="RenderPassParams">
									<xsl:with-param name="Indent" select="$Indent"/>
									<xsl:with-param name="PassParams" select="$passParams"/>
									<xsl:with-param name="BracketPair" select="$bracketPair"/>
									<xsl:with-param name="PartialHasPreceding" select="($PartialHasPreceding or $compoundMemberExpression) and not($DelegateReferenceSupport)"/>
								</xsl:call-template>
								<xsl:if test="$DelegateReferenceSupport and $compoundMemberExpression">
									<xsl:text>)</xsl:text>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$compoundMemberExpression">
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$bracketPair"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$compoundMemberExpression">
				<xsl:text>)</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderClassModifier">
		<xsl:param name="Modifier" select="@modifier"/>
		<xsl:choose>
			<xsl:when test="$Modifier='sealed'">
				<xsl:text>final </xsl:text>
			</xsl:when>
			<xsl:when test="$Modifier='abstract'">
				<xsl:text>abstract </xsl:text>
			</xsl:when>
			<xsl:when test="$Modifier='static'">
				<xsl:text>static </xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderConst">
		<xsl:param name="Const" select="@const"/>
		<xsl:if test="$Const='true' or $Const='1'">
			<xsl:text>const </xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderExpressionList">
		<xsl:param name="Indent"/>
		<xsl:param name="Expressions" select="child::plx:*"/>
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="ListSeparator" select="', '"/>
		<xsl:param name="BeforeFirstItem" select="''"/>
		<xsl:param name="Keys"/>
		<xsl:param name="KeySeparator"/>
		<xsl:param name="PrecedenceContext"/>
		<xsl:variable name="hasPrecedenceContext" select="boolean($PrecedenceContext)"/>
		<xsl:value-of select="substring($BracketPair,1,1)"/>
		<xsl:variable name="keyExpressions" select="$Keys/child::plx:*"/>
		<xsl:for-each select="$Expressions">
			<xsl:variable name="expressionPosition" select="position()"/>
			<xsl:choose>
				<xsl:when test="$expressionPosition=1">
					<xsl:value-of select="$BeforeFirstItem"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$ListSeparator"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="$hasPrecedenceContext">
					<xsl:apply-templates select="." mode="ResolvePrecedence">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="Context" select="$PrecedenceContext"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$keyExpressions">
						<xsl:apply-templates select="$keyExpressions[$expressionPosition]">
							<xsl:with-param name="Indent" select="$Indent"/>
						</xsl:apply-templates>
						<xsl:value-of select="$KeySeparator"/>
					</xsl:if>
					<xsl:apply-templates select=".">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:value-of select="substring($BracketPair,2)"/>
	</xsl:template>
	<xsl:template name="RenderParams">
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="RenderEmptyBrackets" select="true()"/>
		<xsl:param name="ExtraParams" />
		<xsl:choose>
			<xsl:when test="$ExtraParams">
				<xsl:variable name="allParamsFragment">
					<xsl:copy-of select="plx:param"/>
					<xsl:copy-of select="$ExtraParams"/>
				</xsl:variable>
				<xsl:for-each select="exsl:node-set($allParamsFragment)">
					<xsl:call-template name="RenderParams">
						<xsl:with-param name="BracketPair" select="$BracketPair"/>
						<xsl:with-param name="RenderEmptyBrackets" select="$RenderEmptyBrackets"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="params" select="plx:param"/>
				<xsl:choose>
					<xsl:when test="$params">
						<xsl:value-of select="substring($BracketPair,1,1)"/>
						<xsl:for-each select="$params">
							<xsl:if test="position()!=1">
								<xsl:text>, </xsl:text>
							</xsl:if>
							<!--<xsl:call-template name="RenderAttributes">
								<xsl:with-param name="Inline" select="true()"/>
							</xsl:call-template>-->
							<xsl:variable name="type" select="string(@type)"/>
							<xsl:variable name="renderedTypeFragment">
								<xsl:call-template name="RenderType"/>
							</xsl:variable>
							<xsl:variable name="renderedType" select="exsl:node-set($renderedTypeFragment)/*"/>
							<xsl:if test="$renderedType">
								<xsl:copy-of select="$renderedTypeFragment"/>
								<xsl:text> </xsl:text>
							</xsl:if>
							<xsl:if test="string-length($type)">
								<xsl:choose>
									<xsl:when test="$type='inOut'">
										<xsl:text>&amp;</xsl:text>
									</xsl:when>
									<xsl:when test="$type='out'">
										<xsl:text>&amp;</xsl:text>
									</xsl:when>
									<!--<xsl:when test="$type='params'">
										<xsl:text>params </xsl:text>
									</xsl:when>-->
								</xsl:choose>
							</xsl:if>
							<xsl:if test="@plxPHP:reference[.='true' or .=1]">
								<xsl:text>&amp;</xsl:text>
							</xsl:if>
							<xsl:text>$</xsl:text>
							<xsl:value-of select="@name"/>
							<xsl:variable name="default" select="plxPHP:default"/>
							<xsl:if test="$default">
								<xsl:text> = </xsl:text>
								<xsl:apply-templates select="$default/*"/>
							</xsl:if>
						</xsl:for-each>
						<xsl:value-of select="substring($BracketPair,2,1)"/>
					</xsl:when>
					<xsl:when test="$RenderEmptyBrackets">
						<xsl:value-of select="$BracketPair"/>
					</xsl:when>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderPassTypeParams">
		<xsl:param name="PassTypeParams" select="plx:passTypeParam"/>
		<xsl:if test="$PassTypeParams">
			<xsl:text>&lt;</xsl:text>
			<xsl:for-each select="$PassTypeParams">
				<xsl:if test="position()!=1">
					<xsl:text>, </xsl:text>
				</xsl:if>
				<xsl:call-template name="RenderType"/>
			</xsl:for-each>
			<xsl:text>&gt;</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderPassParams">
		<xsl:param name="Indent"/>
		<xsl:param name="PassParams" select="plx:passParam|plx:passParamArray"/>
		<xsl:param name="ExtraParam"/>
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="ListSeparator" select="', '"/>
		<xsl:param name="BeforeFirstItem" select="''"/>
		<xsl:param name="RenderEmptyBrackets" select="true()"/>
		<xsl:param name="PartialHasPreceding" select="false()"/>
		<xsl:param name="PartialHasFollowing" select="false()"/>
		<xsl:choose>
			<xsl:when test="$PassParams or $ExtraParam">
				<xsl:choose>
					<xsl:when test="$PartialHasPreceding">
						<xsl:value-of select="$ListSeparator"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="substring($BracketPair,1,1)"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each select="$PassParams">
					<xsl:choose>
						<xsl:when test="self::plx:passParamArray">
							<xsl:choose>
								<xsl:when test="position()=1 and not($PartialHasPreceding)">
									<xsl:value-of select="$BeforeFirstItem"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$ListSeparator"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:text>array</xsl:text>
							<xsl:call-template name="RenderPassParams">
								<xsl:with-param name="PassParams" select="plx:passParam"/>
							</xsl:call-template>
							<xsl:text></xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="position()=1">
									<xsl:value-of select="$BeforeFirstItem"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$ListSeparator"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:if test="@plxPHP:reference[.='true' or .=1]">
								<xsl:text>&amp;</xsl:text>
							</xsl:if>
							<xsl:apply-templates select="child::*">
								<xsl:with-param name="Indent" select="$Indent"/>
							</xsl:apply-templates>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<xsl:if test="$ExtraParam">
					<xsl:choose>
						<xsl:when test="$PassParams or $PartialHasPreceding">
							<xsl:value-of select="$ListSeparator"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$BeforeFirstItem"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:apply-templates select="exsl:node-set($ExtraParam)">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="not($PartialHasFollowing)">
					<xsl:value-of select="substring($BracketPair,2)"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$RenderEmptyBrackets">
				<xsl:choose>
					<xsl:when test="$PartialHasFollowing">
						<xsl:if test="not($PartialHasPreceding)">
							<xsl:value-of select="substring($BracketPair,1,1)"/>
						</xsl:if>
					</xsl:when>
					<xsl:when test="$PartialHasPreceding">
						<xsl:value-of select="substring($BracketPair,2,1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$BracketPair"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderProcedureModifier">
		<xsl:variable name="modifier" select="@modifier"/>
		<xsl:choose>
			<xsl:when test="$modifier='static'">
				<xsl:text>static </xsl:text>
			</xsl:when>
			<!--<xsl:when test="$modifier='virtual'">
				<xsl:text>virtual </xsl:text>
			</xsl:when>-->
			<xsl:when test="$modifier='abstract'">
				<xsl:text>abstract </xsl:text>
			</xsl:when>
			<!--<xsl:when test="$modifier='override'">
				<xsl:text>override </xsl:text>
			</xsl:when>-->
			<xsl:when test="$modifier='sealedOverride'">
				<xsl:text>final </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='abstractOverride'">
				<xsl:text>abstract </xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderReadOnly">
		<xsl:param name="ReadOnly" select="@readOnly"/>
		<!--<xsl:if test="$ReadOnly='true' or $ReadOnly='1'">
			<xsl:text>readonly </xsl:text>
		</xsl:if>-->
	</xsl:template>
	<xsl:template name="RenderReplacesName">
		<xsl:param name="ReplacesName" select="@replacesName"/>
		<xsl:if test="$ReplacesName='true' or $ReplacesName='1'">
			<xsl:text>new </xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderStatic">
		<xsl:param name="Static" select="@static"/>
		<xsl:if test="$Static='true' or $Static='1'">
			<xsl:text>static </xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderString">
		<xsl:param name="String"/>
		<xsl:param name="AddQuotes" select="true()"/>
		<!-- Render with literal (single-quoted) strings. We aren't doing expansions at this point. -->
		<xsl:choose>
			<xsl:when test="string-length($String)">
				<xsl:variable name="firstChar" select="substring($String,1,1)"/>
				<xsl:choose>
					<xsl:when test='contains("&apos;\",$firstChar)'>
						<xsl:if test="$AddQuotes">
							<xsl:text>&apos;</xsl:text>
						</xsl:if>
						<xsl:text>\</xsl:text>
						<xsl:value-of select="$firstChar"/>
						<xsl:call-template name="RenderString">
							<xsl:with-param name="String" select="substring($String,2)"/>
							<xsl:with-param name="AddQuotes" select="false()"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="beforeFragment">
							<xsl:variable name="beforeSingleQuote" select='substring-before($String,"&apos;")'/>
							<xsl:variable name="beforeBackslash" select="substring-before($String,'\')"/>
							<xsl:choose>
								<xsl:when test="$beforeSingleQuote and (not($beforeBackslash) or string-length($beforeSingleQuote)&lt;string-length($beforeBackslash))">
									<xsl:value-of select="$beforeSingleQuote"/>
								</xsl:when>
								<xsl:when test="$beforeBackslash">
									<xsl:value-of select="$beforeBackslash"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="before" select="string($beforeFragment)"/>
						<xsl:choose>
							<xsl:when test="$before">
								<xsl:if test="$AddQuotes">
									<xsl:text>&apos;</xsl:text>
								</xsl:if>
								<xsl:value-of select="$before"/>
								<xsl:text>\</xsl:text>
								<xsl:value-of select="substring($String,string-length($before) + 1, 1)"/>
								<xsl:call-template name="RenderString">
									<xsl:with-param name="String" select="substring($String,string-length($before)+2)"/>
									<xsl:with-param name="AddQuotes" select="false()"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="$AddQuotes">
									<xsl:text>&apos;</xsl:text>
								</xsl:if>
								<xsl:value-of select="$String"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$AddQuotes">
					<xsl:text>&apos;</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$AddQuotes">
				<xsl:text>&apos;&apos;</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderAttributeString">
		<!-- An attribute string is double quoted with inner double quotes doubled. There are no expansions. -->
		<xsl:param name="String"/>
		<xsl:param name="AddQuotes" select="true()"/>
		<!-- Render with literal (single-quoted) strings. We aren't doing expansions at this point. -->
		<xsl:variable name="quote" select="'&quot;'"/>
		<xsl:choose>
			<xsl:when test="string-length($String)">
				<xsl:variable name="firstChar" select="substring($String,1,1)"/>
				<xsl:choose>
					<xsl:when test='$quote=$firstChar'>
						<xsl:if test="$AddQuotes">
							<xsl:text>&quot;</xsl:text>
						</xsl:if>
						<xsl:text>&quot;&quot;</xsl:text>
						<xsl:call-template name="RenderAttributeString">
							<xsl:with-param name="String" select="substring($String,2)"/>
							<xsl:with-param name="AddQuotes" select="false()"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="beforeFragment">
							<xsl:variable name="beforeQuote" select='substring-before($String,$quote)'/>
							<xsl:if test="$beforeQuote">
								<xsl:value-of select="$beforeQuote"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="before" select="string($beforeFragment)"/>
						<xsl:choose>
							<xsl:when test="$before">
								<xsl:if test="$AddQuotes">
									<xsl:text>&quot;</xsl:text>
								</xsl:if>
								<xsl:value-of select="$before"/>
								<xsl:text>&quot;&quot;</xsl:text>
								<xsl:call-template name="RenderString">
									<xsl:with-param name="String" select="substring($String,string-length($before)+2)"/>
									<xsl:with-param name="AddQuotes" select="false()"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="$AddQuotes">
									<xsl:text>&quot;</xsl:text>
								</xsl:if>
								<xsl:value-of select="$String"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$AddQuotes">
					<xsl:text>&quot;</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$AddQuotes">
				<xsl:text>&quot;&quot;</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderType">
		<xsl:param name="RenderArray" select="true()"/>
		<xsl:param name="DataTypeName" select="@dataTypeName"/>
		<xsl:variable name="rawTypeName" select="$DataTypeName"/>
		<xsl:choose>
			<xsl:when test="self::plx:param or parent::plx:property">
				<xsl:choose>
					<xsl:when test="@dataTypeIsSimpleArray">
						<xsl:text>/*array*/</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="starts-with($rawTypeName,'.')">
								<xsl:text>/*</xsl:text>
								<!--<xsl:value-of select="@dataTypeName"/>-->
								<xsl:call-template name="RenderRawType">
									<xsl:with-param name="rawTypeName" select="$rawTypeName"/>
								</xsl:call-template>
								<xsl:text>*/</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<!--<xsl:value-of select="@dataTypeName"/>-->
								<xsl:call-template name="RenderRawType">
									<xsl:with-param name="rawTypeName" select="$rawTypeName"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!--<xsl:value-of select="@dataTypeName"/>-->
				<xsl:variable name="qualifier" select="string(@dataTypeQualifier)"/>
				<xsl:if test="$qualifier">
					<xsl:text>\</xsl:text>
					<xsl:if test="not($qualifier='.global')">
						<xsl:value-of select="translate($qualifier,'.','\')"/>
						<xsl:text>\</xsl:text>
					</xsl:if>
				</xsl:if>
				<xsl:call-template name="RenderRawType">
					<xsl:with-param name="rawTypeName" select="$rawTypeName"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<!--<xsl:choose>
			<xsl:when test="string-length($rawTypeName)">
				-->
		<!-- Spit the name for the raw type -->
		<!--
				<xsl:choose>
					<xsl:when test="starts-with($rawTypeName,'.')">
						<xsl:choose>
							<xsl:when test="$rawTypeName='.i1'">
								<xsl:text>sbyte</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i2'">
								<xsl:text>short</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i4'">
								<xsl:text>int</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i8'">
								<xsl:text>long</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u1'">
								<xsl:text>byte</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u2'">
								<xsl:text>ushort</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u4'">
								<xsl:text>uint</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u8'">
								<xsl:text>ulong</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.r4'">
								<xsl:text>float</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.r8'">
								<xsl:text>double</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.char'">
								<xsl:text>char</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.decimal'">
								<xsl:text>decimal</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.object'">
								<xsl:text>object</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.boolean'">
								<xsl:text>bool</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.string'">
								<xsl:text>string</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.date'">
								<xsl:text>System.DateTime</xsl:text>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="parametrizedQualifier" select="plx:parametrizedDataTypeQualifier"/>
						<xsl:choose>
							<xsl:when test="$parametrizedQualifier">
								<xsl:for-each select="$parametrizedQualifier">
									<xsl:call-template name="RenderType">
										-->
		<!-- No reason to check for an array here -->
		<!--
										<xsl:with-param name="RenderArray" select="false()"/>
									</xsl:call-template>
								</xsl:for-each>
								<xsl:text>.</xsl:text>
								<xsl:value-of select="$rawTypeName"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="qualifier" select="@dataTypeQualifier"/>
								<xsl:choose>
									<xsl:when test="string-length($qualifier)">
										<xsl:choose>
											<xsl:when test="$qualifier='System'">
												<xsl:choose>
													<xsl:when test="$rawTypeName='SByte'">
														<xsl:text>sbyte</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Int16'">
														<xsl:text>short</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Int32'">
														<xsl:text>int</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Int64'">
														<xsl:text>long</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Byte'">
														<xsl:text>byte</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='UInt16'">
														<xsl:text>ushort</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='UInt32'">
														<xsl:text>uint</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='UInt64'">
														<xsl:text>ulong</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Single'">
														<xsl:text>float</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Double'">
														<xsl:text>double</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Char'">
														<xsl:text>char</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Decimal'">
														<xsl:text>decimal</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Object'">
														<xsl:text>object</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='Boolean'">
														<xsl:text>bool</xsl:text>
													</xsl:when>
													<xsl:when test="$rawTypeName='String'">
														<xsl:text>string</xsl:text>
													</xsl:when>
													-->
		<!-- No primitive type for DateTime in C#, but leave as copy/paste reference -->
		<!--
													<xsl:when test="$rawTypeName='DateTime'">
												<xsl:text></xsl:text>
											</xsl:when>
													<xsl:otherwise>
														<xsl:text>System.</xsl:text>
														<xsl:value-of select="$rawTypeName"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$qualifier"/>
												<xsl:text>.</xsl:text>
												<xsl:value-of select="$rawTypeName"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$rawTypeName"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>

				-->
		<!-- Deal with any type parameters -->
		<!--
				<xsl:call-template name="RenderPassTypeParams"/>

				<xsl:if test="$RenderArray">
					-->
		<!-- Deal with array definitions. The explicit descriptor trumps the @dataTypeIsSimpleArray attribute -->
		<!--
					<xsl:variable name="arrayDescriptor" select="plx:arrayDescriptor"/>
					<xsl:choose>
						<xsl:when test="$arrayDescriptor">
							<xsl:for-each select="$arrayDescriptor">
								<xsl:call-template name="RenderArrayDescriptor"/>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="@dataTypeIsSimpleArray='true' or @dataTypeIsSimpleArray='1'">
							<xsl:text>[]</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>void</xsl:text>
			</xsl:otherwise>
		</xsl:choose>-->
	</xsl:template>
	<xsl:template name="RenderRawType">
		<xsl:variable name="rawTypeName" select="@dataTypeName"/>
		<xsl:choose>
			<xsl:when test="substring($rawTypeName,1,1)='.'">
				<xsl:choose>
					<xsl:when test="$rawTypeName='.i1'">
						<xsl:text>sbyte</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.i2'">
						<xsl:text>short</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.i4'">
						<xsl:text>int</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.i8'">
						<xsl:text>long</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.u1'">
						<xsl:text>byte</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.u2'">
						<xsl:text>ushort</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.u4'">
						<xsl:text>uint</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.u8'">
						<xsl:text>ulong</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.r4'">
						<xsl:text>float</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.r8'">
						<xsl:text>double</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.char'">
						<xsl:text>char</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.decimal'">
						<xsl:text>decimal</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.object'">
						<xsl:text>object</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.boolean'">
						<xsl:text>bool</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.string'">
						<xsl:text>string</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.date'">
						<xsl:text>System.DateTime</xsl:text>
					</xsl:when>
					<xsl:when test="$rawTypeName='.global'">
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$rawTypeName"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderTypeDefinition">
		<xsl:param name="Indent"/>
		<xsl:param name="TypeKeyword" select="local-name()"/>
		<xsl:call-template name="WriteDocBlock">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Contents">
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
		<!--<xsl:call-template name="RenderVisibility"/>-->
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:call-template name="RenderClassModifier"/>
		<!--<xsl:call-template name="RenderPartial">
			<xsl:with-param name="className" select="@name"/>
		</xsl:call-template>-->
		<xsl:choose>
			<xsl:when test="$TypeKeyword = 'enum'">
				<xsl:text>final class</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$TypeKeyword"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:if test="@partial = 'true' or @partial='1'">
			<xsl:value-of select="$PartialBaseSuffix"/>
		</xsl:if>
		<xsl:variable name="typeParams" select="plx:typeParam"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:variable name="baseClass" select="plx:derivesFromClass"/>
		<xsl:if test="$baseClass">
			<xsl:text> extends </xsl:text>
			<xsl:for-each select="$baseClass">
				<xsl:call-template name="RenderType"/>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="plx:implementsInterface">
			<xsl:text> implements </xsl:text>
		</xsl:if>
		<xsl:for-each select="plx:implementsInterface">
			<xsl:call-template name="RenderType"/>
			<xsl:if test="position()!= last()">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParamConstraints">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderTypeParamConstraints">
		<xsl:param name="TypeParams"/>
		<xsl:param name="Indent"/>
		<xsl:param name="SnippetFormat" select="false()"/>
		<!-- There are 4 constraint types c=class,s=structure,n=new,t=typed. Track them
			 for each type param so we know where to put the commas -->
		<xsl:for-each select="$TypeParams">
			<xsl:variable name="typedConstraints" select="plx:typeConstraint"/>
			<xsl:variable name="constraintsFragment">
				<xsl:choose>
					<!-- class and struct are mutually exclusive -->
					<xsl:when test="@requireReferenceType='true' or @requireReferenceType='1'">
						<xsl:text>c</xsl:text>
					</xsl:when>
					<xsl:when test="@requireValueType='true' or @requireValueType='1'">
						<xsl:text>v</xsl:text>
					</xsl:when>
				</xsl:choose>
				<xsl:if test="$typedConstraints">
					<xsl:text>t</xsl:text>
				</xsl:if>
				<xsl:if test="@requireDefaultConstructor='true' or @requireDefaultConstructor='1'">
					<xsl:text>n</xsl:text>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="constraints" select="string($constraintsFragment)"/>
			<xsl:if test="string-length($constraints)">
				<xsl:choose>
					<xsl:when test="$SnippetFormat">
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$NewLine"/>
						<xsl:value-of select="$Indent"/>
						<xsl:value-of select="$SingleIndent"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>where </xsl:text>
				<xsl:value-of select="@name"/>
				<xsl:text> : </xsl:text>
				<xsl:choose>
					<xsl:when test="contains($constraints,'c')">
						<xsl:if test="not(starts-with($constraints,'c'))">
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:text>class</xsl:text>
					</xsl:when>
					<xsl:when test="contains($constraints,'v')">
						<xsl:if test="not(starts-with($constraints,'v'))">
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:text>struct</xsl:text>
					</xsl:when>
				</xsl:choose>
				<xsl:for-each select="$typedConstraints">
					<xsl:if test="position()!=1 or not(starts-with($constraints,'t'))">
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
				<xsl:if test="contains($constraints,'n')">
					<xsl:if test="not(starts-with($constraints,'n'))">
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:text>new()</xsl:text>
				</xsl:if>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="RenderTypeParams">
		<xsl:param name="TypeParams"/>
		<xsl:text>&lt;</xsl:text>
		<xsl:for-each select="$TypeParams">
			<xsl:if test="position()!=1">
				<xsl:text>, </xsl:text>
			</xsl:if>
			<xsl:value-of select="@name"/>
		</xsl:for-each>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	<xsl:template name="RenderVisibility">
		<xsl:param name="Visibility" select="string(@visibility)"/>
		<xsl:if test="string-length($Visibility)">
			<!-- Note that private implementation members will not have a visibility set -->
			<xsl:choose>
				<xsl:when test="$Visibility='public'">
					<xsl:text>public </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='private' or $Visibility='privateInterfaceMember'">
					<xsl:text>private </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protected'">
					<xsl:text>protected </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='internal'">
					<xsl:text>public </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedOrInternal'">
					<xsl:text>protected </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedAndInternal'">
					<!-- C# won't do the and protected, but enforce internal -->
					<xsl:text>protected </xsl:text>
				</xsl:when>
				<!-- deferToPartial and privateInterfaceMember are not rendered -->
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<!-- Templates to calculate if a block of code can reach the end or not. This
		 can never be 100% robust (plix is a formatter, not a compiler, and doesn't recognize
		 things like goto jump targets or code that is conditionally compiled), but
		 this does a reasonable job for most code. -->
	<xsl:template name="TestNoBlockExit">
		<!-- If we're inside a nested block construct then we should
			 not consider a break to be a jump out of the outer structure. -->
		<xsl:param name="IgnoreBreak" select="false()"/>
		<xsl:param name="IgnoreThrow" select="false()"/>
		<xsl:param name="IgnoreGotoCase" select="false()"/>
		<xsl:variable name="allChildren" select="child::*"/>
		<xsl:if test="$allChildren">
			<xsl:variable name="childCount" select="count($allChildren)"/>
			<xsl:apply-templates select="$allChildren[$childCount]" mode="TestNoBlockExit">
				<xsl:with-param name="AllChildren" select="$allChildren"/>
				<xsl:with-param name="TestIndex" select="$childCount"/>
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<xsl:template match="*" mode="TestNoBlockExit"/>
	<xsl:template match="plx:return" mode="TestNoBlockExit">
		<xsl:text>1</xsl:text>
	</xsl:template>
	<xsl:template match="plx:gotoCase" mode="TestNoBlockExit">
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:if test="not($IgnoreGotoCase)">
			<xsl:text>1</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:break" mode="TestNoBlockExit">
		<xsl:param name="IgnoreBreak"/>
		<xsl:if test="not($IgnoreBreak)">
			<xsl:text>1</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:throw" mode="TestNoBlockExit">
		<xsl:param name="IgnoreThrow"/>
		<xsl:if test="not($IgnoreThrow)">
			<xsl:text>1</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:lock | plx:autoDispose" mode="TestNoBlockExit">
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:call-template name="TestNoBlockExit">
			<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
			<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
			<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:loop | plx:iterator" mode="TestNoBlockExit">
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:call-template name="TestNoBlockExit">
			<xsl:with-param name="IgnoreBreak" select="true()"/>
			<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
			<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:switch" mode="TestNoBlockExit">
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:call-template name="TestNoBlockExit">
			<xsl:with-param name="IgnoreBreak" select="true()"/>
			<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
			<xsl:with-param name="IgnoreGotoCase" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:try" mode="TestNoBlockExit">
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:call-template name="TestNoBlockExit">
			<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
			<xsl:with-param name="IgnoreThrow" select="true()"/>
			<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:fallbackBranch | plx:fallbackCase | plx:fallbackCatch" mode="TestNoBlockExit">
		<xsl:param name="AllChildren"/>
		<xsl:param name="TestIndex"/>
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:variable name="testCurrentContents">
			<!-- First test if the contents exit -->
			<xsl:call-template name="TestNoBlockExit">
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<xsl:with-param name="IgnoreThrow" select="not(self::plx:fallbackCatch) and $IgnoreThrow"/>
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length($testCurrentContents)">
			<!-- If the contents exit, then the contents of all siblings must exit as well. -->
			<xsl:apply-templates select="$AllChildren[$TestIndex - 1]" mode="TestNoBlockExit">
				<xsl:with-param name="AllChildren" select="$AllChildren"/>
				<xsl:with-param name="TestIndex" select="$TestIndex - 1"/>
				<xsl:with-param name="FallbackSibling" select="true()"/>
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:alternateBranch | plx:case | plx:catch" mode="TestNoBlockExit">
		<xsl:param name="AllChildren"/>
		<xsl:param name="TestIndex"/>
		<xsl:param name="FallbackSibling" select="false()"/>
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:if test="$FallbackSibling">
			<xsl:variable name="testCurrentContents">
				<!-- First test if the contents exit -->
				<xsl:call-template name="TestNoBlockExit">
					<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
					<xsl:with-param name="IgnoreThrow" select="not(self::plx:catch) and $IgnoreThrow"/>
					<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="string-length($testCurrentContents)">
				<!-- If the contents exit, then the contents of all siblings must exit as well. -->
				<xsl:apply-templates select="$AllChildren[$TestIndex - 1]" mode="TestNoBlockExit">
					<xsl:with-param name="AllChildren" select="$AllChildren"/>
					<xsl:with-param name="TestIndex" select="$TestIndex - 1"/>
					<xsl:with-param name="FallbackSibling" select="true()"/>
					<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
					<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
					<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:branch" mode="TestNoBlockExit">
		<xsl:param name="FallbackSibling" select="false()"/>
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:if test="$FallbackSibling">
			<xsl:call-template name="TestNoBlockExit">
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:finally" mode="TestNoBlockExit">
		<xsl:param name="AllChildren"/>
		<xsl:param name="TestIndex"/>
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:variable name="testCurrentContents">
			<!-- First test if the contents exit. If the finally never exits, then
				 nothing in the try block can exit -->
			<xsl:call-template name="TestNoBlockExit">
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<!-- Don't pass the IgnoreThrow param here -->
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($testCurrentContents)">
				<xsl:text>1</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<!-- All paths may still exit. Keep looking at previous siblings. -->
				<xsl:apply-templates select="$AllChildren[$TestIndex - 1]" mode="TestNoBlockExit">
					<xsl:with-param name="AllChildren" select="$AllChildren"/>
					<xsl:with-param name="TestIndex" select="$TestIndex - 1"/>
					<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
					<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
					<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:comment | plx:pragma" mode="TestNoBlockExit">
		<xsl:param name="AllChildren"/>
		<xsl:param name="TestIndex"/>
		<xsl:param name="IgnoreBreak"/>
		<xsl:param name="IgnoreThrow"/>
		<xsl:param name="IgnoreGotoCase"/>
		<xsl:if test="$TestIndex &gt; 1">
			<xsl:apply-templates select="$AllChildren[$TestIndex - 1]" mode="TestNoBlockExit">
				<xsl:with-param name="AllChildren" select="$AllChildren"/>
				<xsl:with-param name="TestIndex" select="$TestIndex - 1"/>
				<xsl:with-param name="IgnoreBreak" select="$IgnoreBreak"/>
				<xsl:with-param name="IgnoreThrow" select="$IgnoreThrow"/>
				<xsl:with-param name="IgnoreGotoCase" select="$IgnoreGotoCase"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<!-- Inline expansion templates -->
	<xsl:template match="plx:increment|plx:decrement|plx:conditionalOperator" mode="ExpandInline">
		<!-- Leave this empty. Support all inline expansion except plx:nullFallbackOperator -->
	</xsl:template>
	<xsl:template match="plx:assign" mode="ExpandInline">
		<xsl:if test="plx:left/child::*[self::plx:callInstance | self::plx:callStatic | self::plx:callThis][@type='property']">
			<xsl:apply-imports/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:try" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:variable name="finallyContents" select="plx:finally/child::*"/>
		<xsl:if test="$finallyContents">
			<xsl:variable name="catchBlocks" select="plx:catch|plx:fallbackCatch"/>
			<xsl:variable name="otherChildren" select="child::*[not(self::plx:catch|self::plx:fallbackCatch|self::plx:finally)]"/>
			<xsl:variable name="startedFinallyVariableName" select="concat($GeneratedVariablePrefix,$LocalItemKey,'sf')"/>
			<xsl:variable name="fallbackCatchVariableName" select="concat($GeneratedVariablePrefix,$LocalItemKey,'cv')"/>
			<plxGen:inlineExpansion surrogatePreExpanded="true" childrenModified="true">
				<plxGen:expansion>
					<plx:local name="{$startedFinallyVariableName}" dataTypeName=".boolean">
						<plx:initialize>
							<plx:falseKeyword/>
						</plx:initialize>
					</plx:local>
				</plxGen:expansion>
				<plxGen:surrogate>
					<xsl:variable name="newCatchBlock">
						<plx:catch dataTypeName="Exception" localName="{$fallbackCatchVariableName}">
							<plx:branch>
								<plx:condition>
									<plx:unaryOperator type="booleanNot">
										<plx:nameRef name="{$startedFinallyVariableName}"/>
									</plx:unaryOperator>
								</plx:condition>
								<xsl:copy-of select="$finallyContents"/>
							</plx:branch>
							<plx:throw>
								<plx:nameRef name="{$fallbackCatchVariableName}"/>
							</plx:throw>
						</plx:catch>
					</xsl:variable>
					<xsl:variable name="runFinally">
						<plx:assign>
							<plx:left>
								<plx:nameRef name="{$startedFinallyVariableName}"/>
							</plx:left>
							<plx:right>
								<plx:trueKeyword/>
							</plx:right>
						</plx:assign>
						<xsl:copy-of select="$finallyContents"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$catchBlocks">
							<plx:try>
								<plx:try>
									<xsl:apply-templates select="$otherChildren"  mode="AddBeforeReturnCode">
										<xsl:with-param name="BeforeReturnCode" select="$runFinally"/>
									</xsl:apply-templates>
									<xsl:copy-of select="$runFinally"/>
									<xsl:apply-templates select="$catchBlocks"  mode="AddBeforeReturnCode">
										<xsl:with-param name="BeforeReturnCode" select="$runFinally"/>
									</xsl:apply-templates>
								</plx:try>
								<xsl:copy-of select="$newCatchBlock"/>
							</plx:try>
						</xsl:when>
						<xsl:otherwise>
							<!-- No catch blocks, move the finally contents into a catch -->
							<plx:try>
								<xsl:apply-templates select="$otherChildren"  mode="AddBeforeReturnCode">
									<xsl:with-param name="BeforeReturnCode" select="$runFinally"/>
								</xsl:apply-templates>
								<xsl:copy-of select="$runFinally"/>
								<xsl:copy-of select="$newCatchBlock"/>
							</plx:try>
						</xsl:otherwise>
					</xsl:choose>
				</plxGen:surrogate>
			</plxGen:inlineExpansion>
		</xsl:if>
	</xsl:template>
	<xsl:template match="*" mode="AddBeforeReturnCode">
		<xsl:param name="BeforeReturnCode"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="node()" mode="AddBeforeReturnCode">
				<xsl:with-param name="BeforeReturnCode" select="$BeforeReturnCode"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="plx:return" mode="AddBeforeReturnCode">
		<xsl:param name="BeforeReturnCode"/>
		<xsl:copy-of select="$BeforeReturnCode"/>
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template match="plx:root" mode="TopLevel">
		<xsl:param name="Indent"/>
		<xsl:text>&lt;?php</xsl:text>
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="$Indent"/>
		<!-- namespaceImports are rendered with namespaces if there are non-global namespaces. -->
		<xsl:variable name="hasRenderedNamespaces" select="child::plx:namespace[not(@name='.global')]"/>
		<xsl:for-each select="child::*[not($hasRenderedNamespaces) or not(self::plx:namespaceImport)]">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Statement" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>?&gt;</xsl:text>
	</xsl:template>
</xsl:stylesheet>