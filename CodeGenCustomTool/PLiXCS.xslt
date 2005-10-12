<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:plx="http://schemas.neumont.edu/CodeGeneration/PLiX"
	xmlns:plxGen="urn:local-plix-generator" 
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	exclude-result-prefixes="#default msxsl plx plxGen">
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
	<xsl:template match="plx:binaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="@type"/>
		<xsl:variable name="negate" select="$type='typeInequality'"/>
		<xsl:variable name="left" select="plx:left/child::*"/>
		<xsl:variable name="right" select="plx:right/child::*"/>
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<xsl:if test="$negate">
			<xsl:text>!(</xsl:text>
		</xsl:if>
		<xsl:if test="local-name($left)='binaryOperator'">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$left">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="local-name($left)='binaryOperator'">
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
		<xsl:if test="local-name($right)='binaryOperator'">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="$right">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:if test="local-name($right)='binaryOperator'">
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
				<xsl:variable name="tagName" select="local-name()"/>
				<xsl:choose>
					<xsl:when test="$tagName='cast' or $tagName='binaryOperator' or $tagName='unaryOperator' or $tagName='callNew'">
						<xsl:text>1</xsl:text>
					</xsl:when>
					<xsl:when test="$tagName='expression' and not(@parens='true' or @parens='1')">
						<xsl:variable name="tagName2" select="local-name()"/>
						<xsl:if test="$tagName2='cast' or $tagName2='binaryOperator' or $tagName2='unaryOperator' or $tagName2='callNew'">
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
	<xsl:template match="plx:cast">
		<xsl:param name="Indent"/>
		<xsl:variable name="castTarget" select="child::plx:*[position()=last()]"/>
		<xsl:variable name="castType" select="@type"/>
		<!-- UNDONE: Need more work on operator precedence -->
		<xsl:variable name="extraParens" select="local-name($castTarget)='binaryOperator'"/>
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
		<xsl:text> </xsl:text>
		<xsl:value-of select="@localName"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<xsl:template match="plx:class | plx:interface | plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:continue">
		<!-- UNDONE: If the nearest enclosing iterator or loop is a loop
			 and checkCondition is 'after' and a beforeLoop statement is
			 specified, then we need to execute the beforeLoop statement
			 before calling continue. -->
		<xsl:text>continue</xsl:text>
	</xsl:template>
	<xsl:template match="plx:defaultValueOf">
		<xsl:text>default(</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>)</xsl:text>
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
		<xsl:if test="not($explicitDelegate) and @modifier!='override'">
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
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:if test="not(parent::plx:interface)">
			<xsl:call-template name="RenderVisibility"/>
			<xsl:call-template name="RenderProcedureModifier"/>
		</xsl:if>
		<xsl:call-template name="RenderReplacesName"/>
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
		<xsl:for-each select="msxsl:node-set($delegateTypeFragment)/child::*">
			<xsl:call-template name="RenderType"/>
		</xsl:for-each>
		<xsl:text> </xsl:text>
		<xsl:value-of select="$name"/>
	</xsl:template>
	<xsl:template match="plx:event" mode="IndentInfo">
		<xsl:choose>
			<xsl:when test="plx:interfaceMember">
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
						<xsl:for-each select="msxsl:node-set($privateImplFragment)/child::*">
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
	<xsl:template match="plx:fallbackBranch">
		<xsl:text>else</xsl:text>
	</xsl:template>
	<xsl:template match="plx:fallbackCase">
		<xsl:text>default</xsl:text>
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
						<xsl:call-template name="RenderVisibility"/>
						<xsl:if test="@modifier='static'">
							<!-- Ignore modifiers other than static, don't call RenderProcedureModifier -->
							<xsl:text>static </xsl:text>
						</xsl:if>
						<xsl:value-of select="$className"/>
						<xsl:call-template name="RenderParams"/>
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
				<xsl:if test="not(parent::plx:interface)">
					<xsl:call-template name="RenderVisibility"/>
					<xsl:call-template name="RenderProcedureModifier"/>
				</xsl:if>
				<xsl:call-template name="RenderReplacesName"/>
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
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:function" mode="IndentInfo">
		<xsl:choose>
			<xsl:when test="plx:interfaceMember">
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
												<xsl:variable name="passType" select="@type"/>
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
						<xsl:for-each select="msxsl:node-set($privateImplFragment)/child::*">
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
	<xsl:template match="plx:nullKeyword">
		<xsl:text>null</xsl:text>
	</xsl:template>
	<xsl:template match="plx:onAdd">
		<xsl:text>add</xsl:text>
	</xsl:template>
	<xsl:template match="plx:onRemove">
		<xsl:text>remove</xsl:text>
	</xsl:template>
	<xsl:template match="plx:pragma">
		<xsl:variable name="type" select="@type"/>
		<xsl:variable name="data" select="@data"/>
		<xsl:choose>
			<xsl:when test="$type='alternateConditional'">
				<xsl:text>#elif </xsl:text>
				<xsl:value-of select="$data"/>
			</xsl:when>
			<xsl:when test="$type='alternateNotConditional'">
				<xsl:text>#elif !</xsl:text>
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
				<xsl:value-of select="@data"/>
			</xsl:when>
			<xsl:when test="$type='region'">
				<xsl:text>#region </xsl:text>
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
		<xsl:if test="not(parent::plx:interface)">
			<xsl:call-template name="RenderVisibility"/>
			<xsl:call-template name="RenderProcedureModifier"/>
		</xsl:if>
		<xsl:call-template name="RenderReplacesName"/>
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
		<xsl:choose>
			<xsl:when test="plx:interfaceMember">
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
											<xsl:variable name="passType" select="@type"/>
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
						<xsl:for-each select="msxsl:node-set($privateImplFragment)/child::*">
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
		<xsl:variable name="type" select="@type"/>
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
	<xsl:template match="plx:increment">
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:text>++</xsl:text>
		<xsl:apply-templates select="child::*"/>
	</xsl:template>
	<xsl:template match="plx:decrement">
		<!-- UNDONE: Add operator precedence tables to the language info and
			 automatically determine when we need to add additional parentheses -->
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:text>--</xsl:text>
		<xsl:apply-templates select="child::*"/>
	</xsl:template>
	<xsl:template match="plx:value">
		<xsl:variable name="type" select="@type"/>
		<xsl:choose>
			<xsl:when test="$type='char'">
				<xsl:text>'</xsl:text>
				<xsl:value-of select="@data"/>
				<xsl:text>'</xsl:text>
			</xsl:when>
			<xsl:when test="$type='hex2' or $type='hex4' or $type='hex8'">
				<xsl:text>0x</xsl:text>
				<xsl:value-of select="@data"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@data"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:valueKeyword">
		<xsl:text>value</xsl:text>
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
					<xsl:call-template name="RenderType"/>
					<xsl:call-template name="RenderPassParams">
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
					<xsl:call-template name="RenderType"/>
					<xsl:call-template name="RenderPassParams">
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
		<xsl:variable name="passParams" select="plx:passParam"/>
		<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
		<!-- We either get params or nested initializers, but not both -->
		<xsl:choose>
			<xsl:when test="$passParams">
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$nextIndent"/>
					<xsl:with-param name="PassParams" select="$passParams"/>
					<xsl:with-param name="BracketPair" select="'{}'"/>
					<xsl:with-param name="BeforeFirstItem" select="concat($NewLine,$nextIndent)"/>
					<xsl:with-param name="ListSeparator" select="concat(',',$NewLine,$nextIndent)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>{</xsl:text>
				<xsl:for-each select="plx:arrayInitializer">
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
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderCallBody">
		<xsl:param name="Indent"/>
		<!-- Helper function to render most of a call. The caller has already
			 been set before this call -->
		<xsl:param name="Unqualified" select="false()"/>
		<!-- Render the name -->
		<xsl:variable name="callType" select="@type"/>
		<xsl:variable name="isIndexer" select="$callType='indexerCall' or $callType='arrayIndexer'"/>
		<xsl:if test="not(@name='.implied') and not($isIndexer)">
			<xsl:if test="not($Unqualified)">
				<xsl:text>.</xsl:text>
			</xsl:if>
			<xsl:value-of select="@name"/>
		</xsl:if>
		<!-- Add member type params -->
		<xsl:call-template name="RenderPassTypeParams">
			<xsl:with-param name="PassTypeParams" select="plx:passMemberTypeParams"/>
		</xsl:call-template>

		<xsl:variable name="passParams" select="plx:passParam"/>
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
					<xsl:variable name="type" select="@type"/>
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
		<xsl:param name="PassParams" select="plx:passParam"/>
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
				<xsl:text>override sealed </xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderRawString">
		<!-- Get the raw, unescaped version of a string element-->
		<xsl:variable name="childStrings" select="plx:string"/>
		<xsl:choose>
			<xsl:when test="$childStrings">
				<xsl:for-each select="$childStrings">
					<xsl:call-template name="RenderRawString"/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
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
		<xsl:variable name="rawTypeName" select="@dataTypeName"/>
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
							<xsl:when test="$rawTypeName='.ui'">
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
				<xsl:if test="$typedConstraints">
					<xsl:text>t</xsl:text>
				</xsl:if>
				<xsl:choose>
					<!-- class and struct are mutually exclusive -->
					<xsl:when test="@requireReferenceType='true' or @requireReferenceType='1'">
						<xsl:text>c</xsl:text>
					</xsl:when>
					<xsl:when test="@requireValueType='true' or @requireValueType='1'">
						<xsl:text>v</xsl:text>
					</xsl:when>
				</xsl:choose>
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
				<xsl:for-each select="$typedConstraints">
					<xsl:if test="position()!=1">
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
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
		<xsl:param name="Visibility" select="@visibility"/>
		<xsl:if test="string-length($Visibility)">
			<!-- Note that private implementation members will not have a visibility set -->
			<xsl:choose>
				<xsl:when test="$Visibility='public'">
					<xsl:text>public </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='private'">
					<xsl:text>private </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protected'">
					<xsl:text>protected </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='internal'">
					<xsl:text>internal </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedOrInternal'">
					<xsl:text>protectedinternal </xsl:text>
				</xsl:when>
				<xsl:when test="$Visibility='protectedAndInternal'">
					<!-- C# won't do the and protected, but enforce internal -->
					<xsl:text>internal </xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>