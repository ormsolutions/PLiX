<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Neumont PLiX (Programming Language in XML) Code Generator

	Copyright © Neumont University and Matthew Curland. All rights reserved.

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
	xmlns:plx="http://schemas.neumont.edu/CodeGeneration/PLiX"
	xmlns:plxGen="urn:local-plix-generator" 
	xmlns:exsl="http://exslt.org/common"
	exclude-result-prefixes="#default exsl plx plxGen">
	<xsl:import href="PLiXMain.xslt"/>
	<xsl:output method="text"/>
	<!-- Supported brace styles are {C,Indent,Block}. C (the default style)
		 has braces below the statement, Indent indents the
		 braces one indent level, and Block puts the
		 opening brace on the same line as the statement -->
	<xsl:param name="BraceStyle" select="'C'"/>
	<xsl:template match="*" mode="LanguageInfo">
		<plxGen:languageInfo
			defaultBlockClose="}}"
			blockOpen="{{"
			newLineBeforeBlockOpen="yes"
			defaultStatementClose=";"
			requireCaseLabels="no"
			expandInlineStatements="no"
			comment="// "
			docComment="/// ">
			<xsl:choose>
				<xsl:when test="$BraceStyle='Block'">
					<xsl:attribute name="newLineBeforeBlockOpen">
						<xsl:text>no</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="blockOpen">
						<xsl:text> {</xsl:text>
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

	<!-- Matched templates -->
	<xsl:template match="plx:alternateBranch">
		<xsl:param name="Indent"/>
		<xsl:text>else if (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:assign">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text> = </xsl:text>
		<xsl:apply-templates select="plx:right/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:attachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text> += </xsl:text>
		<xsl:apply-templates select="plx:right/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:attribute">
		<xsl:param name="Indent"/>
		<xsl:text>[</xsl:text>
		<xsl:call-template name="RenderAttribute">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:text>]</xsl:text>
	</xsl:template>
	<xsl:template match="plx:attribute[@type='assembly' or @type='module']" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="statementNotClosed" select="true()"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:autoDispose">
		<xsl:param name="Indent"/>
		<xsl:text>using (</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@localName"/>
		<xsl:text> = </xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:binaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:variable name="negate" select="$type='typeInequality'"/>
		<xsl:variable name="left" select="plx:left/child::*"/>
		<xsl:variable name="right" select="plx:right/child::*"/>
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<xsl:if test="$negate">
			<xsl:text>!(</xsl:text>
		</xsl:if>
		<xsl:if test="$left[self::plx:binaryOperator|self::plx:inlineStatement]">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$left">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$left[self::plx:binaryOperator|self::plx:inlineStatement]">
			<xsl:text>)</xsl:text>
		</xsl:if>
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
				<xsl:text> == </xsl:text>
			</xsl:when>
			<xsl:when test="$type='identityInequality'">
				<xsl:text> != </xsl:text>
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
				<xsl:text> is </xsl:text>
			</xsl:when>
			<xsl:when test="$type='typeInequality'">
				<!-- This whole expression is negated -->
				<xsl:text> is </xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="$right[self::plx:binaryOperator|self::plx:inlineStatement]">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$right">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$right[self::plx:binaryOperator|self::plx:inlineStatement]">
			<xsl:text>)</xsl:text>
		</xsl:if>
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
		<xsl:variable name="caller" select="plx:callObject/child::*"/>
		<xsl:variable name="callerNeedsParensFragment">
			<xsl:for-each select="$caller">
				<xsl:choose>
					<xsl:when test="self::plx:cast|self::plx:binaryOperator|self::plx:unaryOperator|self::plx:callNew|self::plx:inlineStatement">
						<xsl:text>1</xsl:text>
					</xsl:when>
					<xsl:when test="self::plx:expression and not(@parens='true' or @parens='1')">
						<xsl:if test="plx:cast|plx:binaryOperator|plx:unaryOperator|plx:callNew|plx:inlineStatement">
							<xsl:text>1</xsl:text>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="callerNeedsParens" select="string-length($callerNeedsParensFragment)"/>
		<xsl:if test="$callerNeedsParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$caller">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$callerNeedsParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:callNew">
		<xsl:param name="Indent"/>
		<xsl:text>new </xsl:text>
		<xsl:call-template name="RenderType">
			<xsl:with-param name="RenderArray" select="false()"/>
		</xsl:call-template>
		<xsl:variable name="arrayDescriptor" select="plx:arrayDescriptor"/>
		<xsl:variable name="isSimpleArray" select="@dataTypeIsSimpleArray='true' or @dataTypeIsSimpleArray='1'"/>
		<xsl:choose>
			<xsl:when test="$arrayDescriptor or $isSimpleArray">
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
							<xsl:otherwise>
								<xsl:text>[]</xsl:text>
							</xsl:otherwise>
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
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:callStatic">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderType"/>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Unqualified" select="@dataTypeName='.global'"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:callThis">
		<xsl:param name="Indent"/>
		<xsl:variable name="accessor" select="@accessor"/>
		<xsl:choose>
			<xsl:when test="$accessor='base'">
				<xsl:text>base</xsl:text>
			</xsl:when>
			<xsl:when test="$accessor='explicitThis'">
				<xsl:message terminate="yes">ExplicitThis calls are not supported by C#.</xsl:message>
			</xsl:when>
			<xsl:when test="$accessor='static'">
				<!-- Nothing to do, don't qualify -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>this</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Unqualified" select="$accessor='static'"/>
		</xsl:call-template>
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
	<xsl:template match="plx:cast">
		<xsl:param name="Indent"/>
		<xsl:variable name="castTarget" select="child::plx:*[position()=last()]"/>
		<xsl:variable name="castType" select="string(@type)"/>
		<!-- UNDONE: Need more work on operator precedence -->
		<xsl:variable name="extraParens" select="$castTarget[self::plx:binaryOperator|self::plx:inlineStatement]"/>
		<xsl:choose>
			<xsl:when test="$castType='testCast'">
				<xsl:if test="$extraParens">
					<xsl:text>(</xsl:text>
				</xsl:if>
				<xsl:apply-templates select="$castTarget">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
				<xsl:if test="$extraParens">
					<xsl:text>)</xsl:text>
				</xsl:if>
				<xsl:text> as </xsl:text>
				<xsl:call-template name="RenderType"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Handles exceptionCast, unbox, primitiveChecked, primitiveUnchecked -->
				<!-- UNDONE: Distinguish primitiveChecked vs primitiveUnchecked cast -->
				<xsl:text>(</xsl:text>
				<xsl:call-template name="RenderType"/>
				<xsl:text>)</xsl:text>
				<xsl:if test="$extraParens">
					<xsl:text>(</xsl:text>
				</xsl:if>
				<xsl:apply-templates select="$castTarget">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
				<xsl:if test="$extraParens">
					<xsl:text>)</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:catch">
		<xsl:text>catch (</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:if test="string(@localName)">
			<xsl:text> </xsl:text>
			<xsl:value-of select="@localName"/>
		</xsl:if>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:class | plx:interface | plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:concatenate">
		<xsl:param name="Indent"/>
		<xsl:text>string.Concat</xsl:text>
		<xsl:call-template name="RenderExpressionList">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:conditionalOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="condition" select="plx:condition/child::*"/>
		<xsl:variable name="left" select="plx:left/child::*"/>
		<xsl:variable name="right" select="plx:right/child::*"/>
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<xsl:variable name="conditionalParens" select="$condition[self::plx:conditionalOperator | self::plx:binaryOperator | self::plx:assign | self::plx:nullFallbackOperator | self::plx:inlineStatement]"/>
		<xsl:variable name="leftParens" select="$left[self::plx:conditionalOperator | self::plx:binaryOperator | self::plx:assign | self::plx:nullFallbackOperator | self::plx:inlineStatement]"/>
		<xsl:variable name="rightParens" select="$right[self::plx:conditionalOperator | self::plx:binaryOperator | self::plx:assign | self::plx:nullFallbackOperator | self::plx:inlineStatement]"/>
		<xsl:if test="$conditionalParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$condition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$conditionalParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:text> ? </xsl:text>
		<xsl:if test="$leftParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$left">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$leftParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:text> : </xsl:text>
		<xsl:if test="$rightParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$right">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$rightParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:continue">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="parent::plx:*" mode="RenderBeforeLoopForContinue">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>continue</xsl:text>
	</xsl:template>
	<xsl:template match="*" mode="RenderBeforeLoopForContinue">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="parent::plx:*" mode="RenderBeforeLoopForContinue">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:iterator" mode="RenderBeforeLoopForContinue">
		<!-- We hit an iterator before a loop, the continue applies to this iterator, not a loop-->
	</xsl:template>
	<xsl:template match="plx:label">
		<xsl:param name="Indent"/>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:label" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="statementClose" select="':'"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:loop" mode="RenderBeforeLoopForContinue">
		<xsl:param name="Indent"/>
		<xsl:variable name="beforeLoopContents" select="self::*[@checkCondition='after'][plx:condition/child::*]/plx:beforeLoop/child::*"/>
		<xsl:if test="$beforeLoopContents">
			<xsl:for-each select="$beforeLoopContents">
				<xsl:call-template name="RenderElement">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Statement" select="true()"/>
					<xsl:with-param name="SkipLeadingIndent" select="true()"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:decrement">
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:if test="not($postfix)">
			<xsl:text>--</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*"/>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:if test="$returns">
			<xsl:for-each select="$returns">
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Prefix" select="'returns:'"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
		<xsl:call-template name="RenderVisibility"/>
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:text>delegate </xsl:text>
		<xsl:choose>
			<xsl:when test="$returns">
				<xsl:for-each select="$returns">
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
				<xsl:text> </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>void </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
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
	</xsl:template>
	<xsl:template match="plx:detachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text> -= </xsl:text>
		<xsl:apply-templates select="plx:right/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:directTypeReference">
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<xsl:template match="plx:enum">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:enumItem">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
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
			<xsl:with-param name="statementClose" select="','"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:event">
		<xsl:param name="Indent"/>
		<xsl:variable name="explicitDelegate" select="plx:explicitDelegateType"/>
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="implicitDelegateName" select="@implicitDelegateName"/>
		<xsl:variable name="isSimpleExplicitImplementation"
			select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName and plx:onAdd and plx:onRemove"/>
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
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
					<DataType dataTypeName="{$name}EventHandler">
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

		<!-- Render the implicit delegate after the event definition so that leading info binds correct to the event -->
		<xsl:if test="not($isSimpleExplicitImplementation) and not($explicitDelegate) and not(@modifier='override')">
			<!-- Use the provided parameters to define an implicit event procedure -->
			<!-- UNDONE: This won't work for interfaces, the handler will need to be
				 a sibiling to the interface. -->
			<xsl:text>;</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
			<xsl:text><![CDATA[/// <summary>Delegate auto-generated by PLiX CS formatter</summary>]]></xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
			<xsl:call-template name="RenderVisibility"/>
			<xsl:text>delegate void </xsl:text>
			<xsl:choose>
				<xsl:when test="string-length($implicitDelegateName)">
					<xsl:value-of select="$implicitDelegateName"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$name"/>
					<xsl:text>EventHandler</xsl:text>
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
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:event" mode="IndentInfo">
		<xsl:variable name="interfaceMembers" select="plx:interfaceMember"/>
		<xsl:choose>
			<xsl:when test="$interfaceMembers and not(@visibility='privateInterfaceMember' and not(@modifier='static') and count($interfaceMembers)=1 and @name=$interfaceMembers[1]/@memberName and plx:onAdd and plx:onRemove)">
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
										<xsl:text>EventHandler</xsl:text>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/>
		<xsl:call-template name="RenderStatic"/>
		<xsl:call-template name="RenderVolatile"/>
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:call-template name="RenderConst"/>
		<xsl:call-template name="RenderReadOnly"/>
		<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
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
						<xsl:choose>
							<xsl:when test="@modifier='static'">
								<!-- Ignore modifiers other than static, don't call RenderProcedureModifier -->
								<xsl:text>static </xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="RenderVisibility"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:if test="@modifier='static'">
						</xsl:if>
						<xsl:value-of select="$className"/>
						<xsl:call-template name="RenderParams"/>
						<xsl:for-each select="plx:initialize/child::plx:callThis">
							<xsl:value-of select="$NewLine"/>
							<xsl:value-of select="$Indent"/>
							<xsl:value-of select="$SingleIndent"/>
							<xsl:text>: </xsl:text>
							<xsl:apply-templates select=".">
								<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
							</xsl:apply-templates>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="$name='.finalize'">
						<xsl:text>~</xsl:text>
						<xsl:value-of select="$className"/>
						<xsl:text>()</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="returns" select="plx:returns"/>
				<xsl:if test="$returns">
					<xsl:for-each select="$returns">
						<xsl:call-template name="RenderAttributes">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Prefix" select="'returns:'"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if>
				<xsl:variable name="isSimpleExplicitImplementation"
					select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
				<xsl:if test="not($isSimpleExplicitImplementation)">
					<xsl:if test="not(parent::plx:interface)">
						<xsl:call-template name="RenderVisibility"/>
						<xsl:call-template name="RenderProcedureModifier"/>
						<xsl:if test="@modifier='static' and plx:attribute[@dataTypeName='DllImport' or @dataTypeName='DllImportAttribute'][not(@dataTypeQualifier) or @dataTypeQualifier='System.Runtime.InteropServices']">
							<xsl:text>extern </xsl:text>
						</xsl:if>
					</xsl:if>
					<xsl:call-template name="RenderReplacesName"/>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$returns">
						<xsl:for-each select="$returns">
							<xsl:call-template name="RenderType"/>
						</xsl:for-each>
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>void </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$isSimpleExplicitImplementation">
					<xsl:for-each select="plx:interfaceMember">
						<xsl:call-template name="RenderType"/>
					</xsl:for-each>
					<xsl:text>.</xsl:text>
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
			<xsl:when test="$interfaceMembers and not(@visibility='privateInterfaceMember' and not(@modifier='static') and count($interfaceMembers)=1 and @name=$interfaceMembers[1]/@memberName)">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="@modifier='static' and plx:attribute[@dataTypeName='DllImport' or @dataTypeName='DllImportAttribute'][not(@dataTypeQualifier) or @dataTypeQualifier='System.Runtime.InteropServices']">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="style" select="'simpleMember'"/>
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
				<xsl:for-each select="plx:interfaceMember">
					<xsl:variable name="memberName" select="@memberName"/>
					<xsl:if test="$contextIsStatic or $memberName!=$contextName or $contextVisibility!='public'">
						<xsl:variable name="privateImplFragment">
							<xsl:variable name="typeName">
								<xsl:call-template name="RenderType"/>
							</xsl:variable>
							<!-- This isn't schema tested. Ignore warnings. -->
							<plx:function name="{$typeName}.{$memberName}">
								<xsl:copy-of select="$contextTypeParams"/>
								<xsl:copy-of select="$contextParams"/>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/>
		<xsl:text>get</xsl:text>
	</xsl:template>
	<xsl:template match="plx:goto">
		<xsl:param name="Indent"/>
		<xsl:text>goto </xsl:text>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:gotoCase">
		<xsl:param name="Indent"/>
		<xsl:text>goto case </xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="plx:increment">
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:if test="not($postfix)">
			<xsl:text>++</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*"/>
		<xsl:if test="$postfix">
			<xsl:text>++</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="plx:iterator">
		<xsl:param name="Indent"/>
		<xsl:text>foreach (</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@localName"/>
		<xsl:text> in </xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:local">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderConst"/>
		<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
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
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:namespace">
		<xsl:text>namespace </xsl:text>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:namespaceImport">
		<xsl:text>using </xsl:text>
		<xsl:if test="string-length(@alias)">
			<xsl:value-of select="@alias"/>
			<xsl:text> = </xsl:text>
		</xsl:if>
		<xsl:value-of select="@name"/>
	</xsl:template>
	<xsl:template match="plx:nullFallbackOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="left" select="plx:left/child::*"/>
		<xsl:variable name="right" select="plx:right/child::*"/>
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<xsl:variable name="leftParens" select="$left[self::plx:conditionalOperator | self::plx:binaryOperator | self::plx:assign | self::plx:nullFallbackOperator | self::plx:inlineStatement]"/>
		<xsl:variable name="rightParens" select="$right[self::plx:conditionalOperator | self::plx:binaryOperator | self::plx:assign | self::plx:nullFallbackOperator | self::plx:inlineStatement]"/>
		<xsl:if test="$leftParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$left">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$leftParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:text> ?? </xsl:text>
		<xsl:if test="$rightParens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$right">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$rightParens">
			<xsl:text>)</xsl:text>
		</xsl:if>
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
				<xsl:for-each select="exsl:node-set($modifiedAttributesFragment)">
					<xsl:call-template name="RenderAttributes">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:variable name="returns" select="plx:returns"/>
		<xsl:for-each select="$returns">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Prefix" select="'returns:'"/>
			</xsl:call-template>
		</xsl:for-each>
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
		<xsl:text>add</xsl:text>
	</xsl:template>
	<xsl:template match="plx:onRemove">
		<xsl:text>remove</xsl:text>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:variable name="returns" select="plx:returns"/>
		<xsl:for-each select="$returns">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Prefix" select="'returns:'"/>
			</xsl:call-template>
		</xsl:for-each>
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
		<xsl:variable name="interfaceMembers" select="plx:interfaceMember"/>
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
		</xsl:choose>
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/>
		<xsl:text>set</xsl:text>
	</xsl:template>
	<xsl:template match="plx:string">
		<xsl:variable name="rawValue">
			<xsl:call-template name="RenderRawString"/>
		</xsl:variable>
		<xsl:call-template name="RenderString">
			<xsl:with-param name="String" select="string($rawValue)"/>
		</xsl:call-template>
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
		<xsl:text>this</xsl:text>
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
		<xsl:text>typeof(</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:unaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<xsl:variable name="parens" select="$type='booleanNot'"/>
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
		</xsl:choose>
		<xsl:if test="$parens">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="$parens">
			<xsl:text>)</xsl:text>
		</xsl:if>
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
			<xsl:when test="$type='r4'">
				<xsl:value-of select="$data"/>
				<xsl:text>F</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$data"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:valueKeyword">
		<xsl:variable name="stringize" select="string(@stringize)"/>
		<xsl:choose>
			<xsl:when test="$stringize='1' or $stringize='true'">
				<xsl:text>"value"</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>value</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
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
				<xsl:variable name="reorderedPassParamsFragment">
					<xsl:copy-of select="plx:passParam[not(plx:binaryOperator[@type='assignNamed'])]|plx:passParamArray/plx:passParam"/>
					<xsl:copy-of select="$namedParameters"/>
				</xsl:variable>
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="PassParams" select="exsl:node-set($reorderedPassParamsFragment)/child::*"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderAttributes">
		<xsl:param name="Indent"/>
		<xsl:param name="Inline" select="false()"/>
		<xsl:param name="Prefix" select="''"/>
		<xsl:choose>
			<xsl:when test="$Inline">
				<!-- Put them all in a single bracket -->
				<xsl:for-each select="plx:attribute">
					<xsl:choose>
						<xsl:when test="position()=1">
							<xsl:text>[</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>, </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:value-of select="$Prefix"/>
					<xsl:call-template name="RenderAttribute">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
					<xsl:if test="position()=last()">
						<xsl:text>] </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="plx:attribute">
					<xsl:text>[</xsl:text>
					<xsl:value-of select="$Prefix"/>
					<xsl:call-template name="RenderAttribute">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
					<xsl:text>]</xsl:text>
					<xsl:value-of select="$NewLine"/>
					<xsl:value-of select="$Indent"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
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
		<xsl:variable name="nestedInitializers" select="plx:arrayInitializer"/>
		<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
		<!-- We either get nested expressions or nested initializers, but not both -->
		<xsl:choose>
			<xsl:when test="$nestedInitializers">
				<xsl:text>{</xsl:text>
				<xsl:for-each select="$nestedInitializers">
					<xsl:if test="position()!=1">
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:value-of select="$NewLine"/>
					<xsl:value-of select="$nextIndent"/>
					<xsl:call-template name="RenderArrayInitializer">
						<xsl:with-param name="Indent" select="$nextIndent"/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderExpressionList">
					<xsl:with-param name="Indent" select="$nextIndent"/>
					<xsl:with-param name="BracketPair" select="'{}'"/>
					<xsl:with-param name="BeforeFirstItem" select="concat($NewLine,$nextIndent)"/>
					<xsl:with-param name="ListSeparator" select="concat(',',$NewLine,$nextIndent)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderCallBody">
		<xsl:param name="Indent"/>
		<!-- Helper function to render most of a call. The caller has already
			 been set before this call -->
		<xsl:param name="Unqualified" select="false()"/>
		<!-- Render the name -->
		<xsl:variable name="callType" select="string(@type)"/>
		<xsl:variable name="isIndexer" select="$callType='indexerCall' or $callType='arrayIndexer'"/>
		<xsl:if test="not(@name='.implied') and not($isIndexer)">
			<xsl:if test="not($Unqualified)">
				<xsl:text>.</xsl:text>
			</xsl:if>
			<xsl:value-of select="@name"/>
		</xsl:if>
		<!-- Add member type params -->
		<xsl:call-template name="RenderPassTypeParams">
			<xsl:with-param name="PassTypeParams" select="plx:passMemberTypeParam"/>
		</xsl:call-template>

		<xsl:variable name="passParams" select="plx:passParam|plx:passParamArray/plx:passParam"/>
		<xsl:variable name="hasParams" select="boolean($passParams)"/>
		<xsl:variable name="bracketPair">
			<xsl:choose>
				<xsl:when test="$callType='methodCall' or $callType='delegateCall' or string-length($callType)=0">
					<xsl:text>()</xsl:text>
				</xsl:when>
				<xsl:when test="$isIndexer">
					<xsl:text>[]</xsl:text>
				</xsl:when>
				<xsl:when test="$callType='property'">
					<xsl:if test="$hasParams">
						<xsl:text>[]</xsl:text>
					</xsl:if>
				</xsl:when>
				<!-- field, event, methodReference handled with silence-->
				<!-- UNDONE: fireStandardEvent, fireCustomEvent -->
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$bracketPair">
			<xsl:choose>
				<xsl:when test="$hasParams">
					<xsl:call-template name="RenderPassParams">
						<xsl:with-param name="Indent" select="$Indent"/>
						<xsl:with-param name="PassParams" select="$passParams"/>
						<xsl:with-param name="BracketPair" select="$bracketPair"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$bracketPair"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderClassModifier">
		<xsl:param name="Modifier" select="@modifier"/>
		<xsl:choose>
			<xsl:when test="$Modifier='sealed'">
				<xsl:text>sealed </xsl:text>
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
		<xsl:value-of select="substring($BracketPair,1,1)"/>
		<xsl:for-each select="$Expressions">
			<xsl:choose>
				<xsl:when test="position()=1">
					<xsl:value-of select="$BeforeFirstItem"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$ListSeparator"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select=".">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:value-of select="substring($BracketPair,2)"/>
	</xsl:template>
	<xsl:template name="RenderParams">
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="RenderEmptyBrackets" select="true()"/>
		<xsl:variable name="params" select="plx:param"/>
		<xsl:choose>
			<xsl:when test="$params">
				<xsl:value-of select="substring($BracketPair,1,1)"/>
				<xsl:for-each select="$params">
					<xsl:if test="position()!=1">
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:call-template name="RenderAttributes">
						<xsl:with-param name="Inline" select="true()"/>
					</xsl:call-template>
					<xsl:variable name="type" select="string(@type)"/>
					<xsl:if test="string-length($type)">
						<xsl:choose>
							<xsl:when test="$type='inOut'">
								<xsl:text>ref </xsl:text>
							</xsl:when>
							<xsl:when test="$type='out'">
								<xsl:text>out </xsl:text>
							</xsl:when>
							<xsl:when test="$type='params'">
								<xsl:text>params </xsl:text>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
					<xsl:call-template name="RenderType"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="@name"/>
				</xsl:for-each>
				<xsl:value-of select="substring($BracketPair,2,1)"/>
			</xsl:when>
			<xsl:when test="$RenderEmptyBrackets">
				<xsl:value-of select="$BracketPair"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderPartial">
		<xsl:param name="Partial" select="@partial"/>
		<xsl:if test="$Partial='true' or $Partial='1'">
			<xsl:text>partial </xsl:text>
		</xsl:if>
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
		<xsl:param name="PassParams" select="plx:passParam|plx:passParamArray/plx:passParam"/>
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="ListSeparator" select="', '"/>
		<xsl:param name="BeforeFirstItem" select="''"/>
		<xsl:value-of select="substring($BracketPair,1,1)"/>
		<xsl:for-each select="$PassParams">
			<xsl:choose>
				<xsl:when test="position()=1">
					<xsl:value-of select="$BeforeFirstItem"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$ListSeparator"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="@type='inOut'">
					<xsl:text>ref </xsl:text>
				</xsl:when>
				<xsl:when test="@type='out'">
					<xsl:text>out </xsl:text>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:value-of select="substring($BracketPair,2)"/>
	</xsl:template>
	<xsl:template name="RenderProcedureModifier">
		<xsl:variable name="modifier" select="@modifier"/>
		<xsl:choose>
			<xsl:when test="$modifier='static'">
				<xsl:text>static </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='virtual'">
				<xsl:text>virtual </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='abstract'">
				<xsl:text>abstract </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='override'">
				<xsl:text>override </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='sealedOverride'">
				<xsl:text>sealed override </xsl:text>
			</xsl:when>
			<xsl:when test="$modifier='abstractOverride'">
				<xsl:text>abstract override </xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderReadOnly">
		<xsl:param name="ReadOnly" select="@readOnly"/>
		<xsl:if test="$ReadOnly='true' or $ReadOnly='1'">
			<xsl:text>readonly </xsl:text>
		</xsl:if>
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
		<xsl:choose>
			<xsl:when test="string-length($String)">
				<xsl:choose>
					<xsl:when test="'&quot;'=substring($String,1,1)">
						<xsl:if test="$AddQuotes">
							<xsl:text>@&quot;</xsl:text>
						</xsl:if>
						<xsl:text>&quot;&quot;</xsl:text>
						<xsl:call-template name="RenderString">
							<xsl:with-param name="String" select="substring($String,2)"/>
							<xsl:with-param name="AddQuotes" select="false()"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="before" select="substring-before($String,'&quot;')"/>
						<xsl:choose>
							<xsl:when test="string-length($before)">
								<xsl:if test="$AddQuotes">
									<xsl:text>@&quot;</xsl:text>
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
									<!-- If there are any other characters that require escaping, we just prepend an @ -->
									<xsl:if test="string-length(translate($String,'\&#xd;&#xa;&#x9;',''))!=string-length($String)">
										<xsl:text>@</xsl:text>
									</xsl:if>
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
			<xsl:when test="string-length($rawTypeName)">
				<!-- Spit the name for the raw type -->
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
							<xsl:when test="$rawTypeName='.unspecifiedTypeParam'"/>
							<xsl:when test="$rawTypeName='.global'"/>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="parametrizedQualifier" select="plx:parametrizedDataTypeQualifier"/>
						<xsl:choose>
							<xsl:when test="$parametrizedQualifier">
								<xsl:for-each select="$parametrizedQualifier">
									<xsl:call-template name="RenderType">
										<!-- No reason to check for an array here -->
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
													<!-- No primitive type for DateTime in C#, but leave as copy/paste reference -->
													<!--<xsl:when test="$rawTypeName='DateTime'">
												<xsl:text></xsl:text>
											</xsl:when>-->
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

				<!-- Deal with any type parameters -->
				<xsl:call-template name="RenderPassTypeParams"/>

				<xsl:if test="$RenderArray">
					<!-- Deal with array definitions. The explicit descriptor trumps the @dataTypeIsSimpleArray attribute -->
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
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderTypeDefinition">
		<xsl:param name="Indent"/>
		<xsl:param name="TypeKeyword" select="local-name()"/>
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/>
		<xsl:call-template name="RenderReplacesName"/>
		<xsl:call-template name="RenderClassModifier"/>
		<xsl:call-template name="RenderPartial"/>
		<xsl:value-of select="$TypeKeyword"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@name"/>
		<xsl:variable name="typeParams" select="plx:typeParam"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:variable name="baseClass" select="plx:derivesFromClass"/>
		<xsl:if test="$baseClass">
			<xsl:text> : </xsl:text>
			<xsl:for-each select="$baseClass">
				<xsl:call-template name="RenderType"/>
			</xsl:for-each>
		</xsl:if>
		<xsl:for-each select="plx:implementsInterface">
			<xsl:choose>
				<xsl:when test="position()!=1 or $baseClass">
					<xsl:text>, </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> : </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="RenderType"/>
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
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$Indent"/>
				<xsl:value-of select="$SingleIndent"/>
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
					<xsl:text>internal </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedOrInternal'">
					<xsl:text>protected internal </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedAndInternal'">
					<!-- C# won't do the and protected, but enforce internal -->
					<xsl:text>internal </xsl:text>
				</xsl:when>
				<!-- deferToPartial and privateInterfaceMember are not rendered -->
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderVolatile">
		<xsl:param name="Volatile" select="@volatile"/>
		<xsl:if test="$Volatile='true' or $Volatile='1'">
			<xsl:text>volatile </xsl:text>
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
</xsl:stylesheet>