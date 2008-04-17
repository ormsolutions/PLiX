<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Neumont PLiX (Programming Language in XML) Code Generator

	Copyright © Neumont University, Matthew Curland, and Brian Christensen. All rights reserved.

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

	<!-- use internal name for auto variables - bcc 080205 -->
	<xsl:param name="AutoVariablePrefix" select="'_PLiXPY'"/>
	<!-- standard python indent is four spaces - bcc 080205 -->
	<xsl:param name="IndentWith" select="'    '"/>
	<xsl:template match="*" mode="LanguageInfo">
<!-- need more info on:
     defaultStatementClose, requireCaseLabels, expandInlineStatements, docComment - bcc 080205 -->
		<plxGen:languageInfo
			defaultBlockClose=""
			blockOpen=""
			newLineBeforeBlockOpen="no"
			defaultStatementClose=""
			requireCaseLabels="no"
			expandInlineStatements="yes"
			autoVariablePrefix="{$AutoVariablePrefix}"
			comment="# "
			docComment="# ">
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
	<!-- python operator precedences http://docs.python.org/ref/summary.html (bcc) -->
	<xsl:template match="plx:callInstance" mode="Precedence">6</xsl:template>
	<xsl:template match="plx:callNew" mode="Precedence">8</xsl:template>
	<xsl:template match="plx:increment[@type='post']|plx:decrement[@type='post']" mode="Precedence">10</xsl:template>
	<xsl:template match="plx:unaryOperator[@type='booleanNot']" mode="Precedence">80</xsl:template>
	<xsl:template match="plx:cast|plx:unaryOperator|plx:increment|plx:decrement" mode="Precedence">20</xsl:template>
	<xsl:template match="plx:concatenate" mode="Precedence">40</xsl:template>
	<xsl:template match="plx:binaryOperator" mode="Precedence">
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$type='add'">40</xsl:when>
			<xsl:when test="$type='assignNamed'">0</xsl:when>
			<xsl:when test="$type='bitwiseAnd'">60</xsl:when>
			<xsl:when test="$type='bitwiseExclusiveOr'">62</xsl:when>
			<xsl:when test="$type='bitwiseOr'">64</xsl:when>
			<xsl:when test="$type='booleanAnd'">82</xsl:when>
			<xsl:when test="$type='booleanOr'">84</xsl:when>
			<xsl:when test="$type='divide'">30</xsl:when>
			<xsl:when test="$type='equality'">70</xsl:when>
			<xsl:when test="$type='greaterThan'">70</xsl:when>
			<xsl:when test="$type='greaterThanOrEqual'">70</xsl:when>
			<xsl:when test="$type='identityEquality'">72</xsl:when>
			<xsl:when test="$type='identityInequality'">72</xsl:when>
			<xsl:when test="$type='inequality'">70</xsl:when>
			<xsl:when test="$type='lessThan'">70</xsl:when>
			<xsl:when test="$type='lessThanOrEqual'">70</xsl:when>
			<xsl:when test="$type='modulus'">30</xsl:when>
			<xsl:when test="$type='multiply'">30</xsl:when>
			<xsl:when test="$type='shiftLeft'">50</xsl:when>
			<xsl:when test="$type='shiftRight'">50</xsl:when>
			<xsl:when test="$type='shiftRightZero'">50</xsl:when>
			<xsl:when test="$type='shiftRightPreserve'">50</xsl:when>
			<xsl:when test="$type='subtract'">40</xsl:when>
			<xsl:when test="$type='typeEquality'">0</xsl:when>
			<xsl:when test="$type='typeInequality'">0</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:nullFallbackOperator" mode="Precedence">94</xsl:template>
	<xsl:template match="plx:conditionalOperator" mode="Precedence">96</xsl:template>
	<xsl:template match="plx:assign|plx:attachEvent|plx:detachEvent" mode="Precedence">100</xsl:template>

	<!-- Matched templates -->
	<!-- done - bcc 080205 -->
	<xsl:template match="/">
		<xsl:text>import PLiXPY
from PLiXPY import System
# ----------------------------------------
</xsl:text>
		<!-- this is copied out of PLiXMain.xslt - bcc 080304 -->
		<xsl:variable name="baseIndent">
			<xsl:call-template name="GetBaseIndent"/>
		</xsl:variable>
		<xsl:apply-templates select="child::*" mode="TopLevel">
			<xsl:with-param name="Indent" select="string($baseIndent)"/>
		</xsl:apply-templates>
		<!-- end of copy -->
		<xsl:text>

# ----------------------------------------
PLiXPY.Meta.do_inits()

def _test():
    import doctest
    doctest.testmod()

if __name__ == "__main__":
    _test()
</xsl:text>
	</xsl:template>
	<xsl:template match="plx:alternateBranch">
		<xsl:param name="Indent"/>
		<xsl:text>elif (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>):</xsl:text>
	</xsl:template>
	<!-- can this be done in Python? - bcc 080205 
	not possible - bcc 080219 -->
	<xsl:template match="plx:anonymousFunction">
		<xsl:param name="Indent"/>
		<xsl:param name="LocalItemKey"/>
		<xsl:message terminate="yes">anonymousFunction not implemented yet</xsl:message>
		<xsl:text>delegate</xsl:text>
		<xsl:call-template name="RenderParams"/>
		<xsl:if test="$NewLineBeforeBlockOpen">
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
			<xsl:value-of select="$SingleIndent"/>
		</xsl:if>
		<xsl:value-of select="$BlockOpen"/>
		<xsl:value-of select="$NewLine"/>
		<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent,$SingleIndent)"/>
		<xsl:for-each select="child::*[not(self::plx:param or self::plx:returns)]">
			<xsl:call-template name="RenderElement">
				<xsl:with-param name="Indent" select="$nextIndent"/>
				<xsl:with-param name="LocalItemKey" select="$LocalItemKey"/>
				<xsl:with-param name="Statement" select="true()"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:value-of select="$Indent"/>
		<xsl:value-of select="$SingleIndent"/>
		<xsl:value-of select="$DefaultBlockClose"/>
	</xsl:template>
	<!-- okay? - bcc 080205 -->
	<!-- 
	
	== possible difference - name resolution ==
	Would python and c# find the same variable when searching for a name?
	In Python, name resolution goes: local, lexically enclosing functions, module, __builtin__
	In C#, name resolution goes:
	In Java, name resolution goes: local, instance, class, parent class
	
	In Java an instance variable can be "shadowed", the class and parent class define instance
	variables with the same name, both variables are created, but the parent defined
	variable is hidden behind the class defined variable name. The parent variable
	can be refered to using 'super.xxx'. Or by type casting the object reference to the 
	parent type.(see Learning Java p.156)
	Does python do the same?

  == difference - reserved words available for variable names == (changed on 080218)
	reserved words in java
	.Net uses the "@" prefix to treat "reserved words" as normal variables, is that used?
	Python non-reserved words that are built in function names that would be hidden if 
	they were used as variable (or function or class) names

	== difference - global variables ==
	Python has the concept of a 'global' variable that is defined in the Module. To make 
	an assignment to a global variable within a function it is necessary to explicitly
	declare the declare the variable as local ('global xxx').
	C# and Java do not have module variables. 
	Not a problem in translating to Python.
	
	== difference - module functions ==
	Python can have functions that are are not in classes.
	C# and Java require that all functions be either class or instance methods.
	Not a problem in translating to Python
	
	- Not built into python, but I found a receipe that will add the capability
	to python using the same syntax. How to specify the required imports? 
	http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/410686
	- bcc 080206
	-->
	<!-- okay - bcc 080327 -->
	<xsl:template match="plx:assign">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> = </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- done - bcc 080407 -->
	<xsl:template match="plx:attachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> += </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- do not implement (what should it generate instead?) - bcc 080206 -->
	<!-- python doesn't have the same 'attributes' as .Net (ditto iron python)
	python has 'decorators' that may perform a similar funtion
	will have to look at examples of use to decide what can be done
	as of python 2.5 decorators can only be applied to functions (not classes, etc.)
 - bcc 080206, 080218 -->
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
	<!-- this should be transformed into 'try-finally' before generating python
	- bcc 080206 
	It may be possible to implement this using "with ... as ..." 
	see http://docs.python.org/lib/module-contextlib.html
	- bcc 080209
	or perhaps better, using the 'with nested(A, B, C) as (X, Y, Z):' syntax
	to automatically call "displose" (using the .net libraries) would require writing a 
	new context manager; would "close" be the right action? it becomes more obvious
	that I want to focus on a specific code generation problem rather than the generic one
	
	a .net explanation of autodispose: http://msdn2.microsoft.com/en-us/library/yh598w02.aspx
	with interface defined: http://msdn2.microsoft.com/en-us/library/aa664736(VS.71).aspx
	- bcc 080219
	-->
	<xsl:template match="plx:autoDispose">
		<xsl:param name="Indent"/>
		<xsl:message terminate="yes">autoDispose not implemented yet</xsl:message>
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
	<!-- done (issues w/ 'shiftRight...' - bcc 080207 -->
	<xsl:template match="plx:binaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:variable name="negate" select="$type='typeInequality'"/>
		<xsl:variable name="typetest" select="$type='typeEquality' or $type='typeInequality'"/>
		<xsl:if test="$negate">
			<xsl:text>not(</xsl:text>
		</xsl:if>
		<xsl:if test="$typetest">
			<xsl:text>isinstance(</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:choose>
			<!-- references:
			python arithmatic binary: +, -, *, /, %
				http://docs.python.org/ref/binary.html
			python bitwise operators: binary: and &, xor ^, or |
				http://docs.python.org/ref/bitwise.html
			python boolean operators: and, or
				http://docs.python.org/ref/Booleans.html
			python same object test is: 'is', not '==' as in C#
			python type test is: 'isinstance(x, type)', not 'x is type' as in C#
			-->
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
				<xsl:text> and </xsl:text>
			</xsl:when>
			<xsl:when test="$type='booleanOr'">
				<xsl:text> or </xsl:text>
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
				<xsl:text> is </xsl:text>
			</xsl:when>
			<xsl:when test="$type='identityInequality'">
				<xsl:text> is not </xsl:text>
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
			<!-- python preserves the sign - bcc 080227 -->
			<xsl:when test="$type='shiftRightZero'">
				<xsl:text> &gt;&gt; </xsl:text>
				<xsl:message terminate="yes">shiftRightZero not implemented - Python built in shift operator preserves the sign.</xsl:message>
			</xsl:when>
			<!-- end of problem - bcc 080227 -->
			<xsl:when test="$type='shiftRightPreserve'">
				<xsl:text> &gt;&gt; </xsl:text>
			</xsl:when>
			<xsl:when test="$type='subtract'">
				<xsl:text> - </xsl:text>
			</xsl:when>
			<xsl:when test="$type='typeEquality'">
				<!-- This whole expression is in 'isinstance(...)'-->
				<xsl:text>, </xsl:text>
			</xsl:when>
			<xsl:when test="$type='typeInequality'">
				<!-- This whole expression is in 'not (isinstance(...))' -->
				<xsl:text>, </xsl:text>
			</xsl:when>
		</xsl:choose>
		<!-- what does this do? - bcc 080218
		resolve precedence looks at the precedence of the operators in the children
		to determine whether to add parenthesis - bcc 080227 -->
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:if test="$typetest">
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:if test="$negate">
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- done - bcc prior -->
	<xsl:template match="plx:branch">
		<xsl:param name="Indent"/>
		<xsl:text>if (</xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<!-- leave prens around test (doesn't hurt and may be helpful if multi line tests are generated), but add colon (bcc) -->
		<xsl:text>):</xsl:text>
	</xsl:template>
	<!-- ok - bcc 080207 -->
	<xsl:template match="plx:break">
		<xsl:text>break</xsl:text>
	</xsl:template>
	<!-- partial -->
	<!-- okay for:
	    field
			methodCall  (except where for library differences
				for example: .Net uses: instanceX.Length, python uses: len(instanceX)
			don't know for other types
	- bcc 080207 -->
	<xsl:template match="plx:callInstance">
		<xsl:param name="Indent"/>
		<xsl:choose>
			<xsl:when test="@name='Length' and @type='property'">
				<xsl:text>len(</xsl:text>
				<xsl:apply-templates select="plx:callObject/child::*" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text>)</xsl:text>
			</xsl:when>
			<!-- only allow zero based arrays -->
			<xsl:when test="@name='GetLowerBound'">
				<xsl:text>0</xsl:text>
			</xsl:when>
			<xsl:when test="@name='GetUpperBound'">
				<xsl:text>PLiXPY.GetUpperBound(</xsl:text>
				<xsl:apply-templates select="plx:callObject/child::*" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text>,</xsl:text>
				<xsl:apply-templates select="plx:passParam|plx:passParamArray/plx:passParam">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:when test="@name='ToString'">
				<xsl:text>str(</xsl:text>
				<xsl:apply-templates select="plx:callObject/child::*" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:otherwise>
			<xsl:apply-templates select="plx:callObject/child::*" mode="ResolvePrecedence">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Context" select="."/>
			</xsl:apply-templates>
			<xsl:call-template name="RenderCallBody">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- done down to marker - bcc 080206 -->
	<!-- good down to here (marker) - bcc 080206 -->
	<xsl:template match="plx:callNew">
		<xsl:param name="Indent"/>
		<!-- <xsl:text>new </xsl:text>   'new' keyword not required-->
		<!-- render type only if not array - bcc 080227 -->
		<!-- moved to non-array "otherwise" branch - bcc 080227
		<xsl:call-template name="RenderType">
			<xsl:with-param name="RenderArray" select="false()"/>
		</xsl:call-template>
		-->
		<xsl:variable name="arrayDescriptor" select="plx:arrayDescriptor"/>
		<xsl:variable name="isSimpleArray" select="@dataTypeIsSimpleArray='true' or @dataTypeIsSimpleArray='1'"/>
		<xsl:choose>
			<xsl:when test="$arrayDescriptor or $isSimpleArray">
				<xsl:variable name="initializer" select="plx:arrayInitializer"/>
				<xsl:choose>
					<xsl:when test="$initializer">
						<!-- If we have an array initializer, then ignore the passed in
							 parameters and render the full array descriptor brackets -->
						<!-- in python array descriptor brackets not needed - bcc 080227 -->
						<!-- 
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
						-->
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
						<!-- need to create array instance - bcc 080227 -->
								<xsl:text>PLiXPY.array</xsl:text>
						<xsl:variable name="typeName" >
							<!-- used by array function to determine initial values -->
							<xsl:text>'</xsl:text>
							<xsl:call-template name="RenderType">
								<xsl:with-param name="RenderArray" select="false()"/>
							</xsl:call-template>
							<xsl:text>', </xsl:text>
						</xsl:variable>
						<xsl:variable name="passParams" select="plx:passParam"/>
						<xsl:call-template name="RenderPassParams">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="PassParams" select="$passParams"/>
							<xsl:with-param name="BracketPair" select="'()'"/>
							<xsl:with-param name="BeforeFirstItem" select="$typeName"/>
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
				<xsl:call-template name="RenderType">
					<xsl:with-param name="RenderArray" select="false()"/>
				</xsl:call-template>
				<!-- Not an array constructor -->
				<xsl:call-template name="RenderPassParams">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- same as call instance?? - bc 080207 -->
	<xsl:template match="plx:callStatic">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderType"/>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Unqualified" select="@dataTypeName='.global'"/>
		</xsl:call-template>
	</xsl:template>
	<!-- syntax is different - bcc 080207 -->
	<xsl:template match="plx:callThis">
		<xsl:param name="Indent"/>
		<xsl:variable name="accessor" select="@accessor"/>
		<xsl:choose>
			<xsl:when test="$accessor='base'">
				<xsl:choose>
					<xsl:when test="@type='field'">
						<xsl:text>self</xsl:text>
					</xsl:when>
					<xsl:when test="@name='.implied'">
						<xsl:text>self.__super.__init__</xsl:text>
					</xsl:when>
					<!-- named function - bcc 080313 -->
					<xsl:otherwise>
						<xsl:text>self.__super</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$accessor='explicitThis'">
				<xsl:message terminate="yes">ExplicitThis calls are not supported by C#.</xsl:message>
			</xsl:when>
			<xsl:when test="$accessor='static'">
				<!-- Nothing to do, don't qualify (Matt's comment on C#) -->
				<!-- is this correct for python - bcc 080408 -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>self</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:call-template name="RenderCallBody">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Unqualified" select="$accessor='static'"/>
		</xsl:call-template>
	</xsl:template>
	<!-- not done - python uses 'elif' statements instead of 'case' - bcc 080219 -->
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
		<!-- not required with Python - bcc 080408
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
		</xsl:if> -->
	</xsl:template>
	<!-- python normally does not require type casting, but there may be exceptions - bcc 080219 -->
	<xsl:template match="plx:cast">
		<xsl:param name="Indent"/>
		<xsl:variable name="castTarget" select="child::plx:*[position()=last()]"/>
		<xsl:variable name="castType" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$castType='testCast'">
				<!-- for now we'll ignore all of this kind of casting - bcc 080322 
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text> as </xsl:text>
				<xsl:call-template name="RenderType"/>
				-->
			</xsl:when>
			<xsl:when test="starts-with(@dataTypeName,'.u') or starts-with(@dataTypeName,'.i')">
				<xsl:text>int(</xsl:text>
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:when test="starts-with(@dataTypeName,'.r')">
				<!-- we are doing this one to prevent integer division when float is expected - bcc080322 -->
				<xsl:text>float(</xsl:text>
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<!-- Handles exceptionCast, unbox, primitiveChecked, primitiveUnchecked -->
				<!-- UNDONE: Distinguish primitiveChecked vs primitiveUnchecked cast -->
				<!-- ignore these unless proven otherwise - bcc 080322
				<xsl:text>(</xsl:text>
				<xsl:call-template name="RenderType"/>
				<xsl:text>)</xsl:text> -->
				<xsl:apply-templates select="$castTarget" mode="ResolvePrecedence">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Context" select="."/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- okay - the python equivalent is the "except:" clause - bcc 080404 -->
	<xsl:template match="plx:catch">
		<xsl:text>except </xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:if test="string(@localName)">
			<xsl:text>, </xsl:text>
			<xsl:value-of select="@localName"/>
		</xsl:if>
		<xsl:text>:</xsl:text>
	</xsl:template>
	<!-- not yet -->
	<!-- 
	classes - problem with overloaded constructors
	python can't do duplicate names (put all of the logic into one? and test parameters?)
	interfaces - probably ignore them (but zope has an implementation)
	- bcc 080209
	structures - if structure are define to reduce space requirements, the python
	equivalent might be '__slots__'. Python slots prevent creation of a dictionary for the instance.
	- bc 080219
	each class has:
		__init__ - called when the class is created; it immediately calls one of the defined
								constructors via the function router
		_init - called by the constructors?
		Not neede: _base - may be called by the constructors?
	-->
	<xsl:template match="plx:class  | plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="concat($Indent,$SingleIndent)"/>
		<xsl:text>_function_router = {}</xsl:text>
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="concat($Indent,$SingleIndent)"/>
		<!-- init - bcc 080308 -->
		<xsl:text>def __init__(self, *parms):</xsl:text>
		<xsl:value-of select="$NewLine"/>
		<xsl:variable name="initIndent" select="concat($Indent,$SingleIndent,$SingleIndent)" />
		<xsl:value-of select="concat($Indent,$SingleIndent,$SingleIndent)"/>
		<!-- call defined constructor for explicit instance initialization - bcc 080308 -->
		<!-- old version
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:text>._function_router[('</xsl:text>
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:text>',len(parms))](self,*parms)</xsl:text>
		-->
		<xsl:text>self.</xsl:text>
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:text>(*parms)</xsl:text>

		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="concat($Indent,$SingleIndent)"/>
		<!-- _init - initialize instance (call only once) - bcc 080308 -->
			<xsl:text>def _init(self):</xsl:text>
			<xsl:value-of select="$NewLine"/>
		<xsl:variable name="instanceFields" select="child::plx:field[not(@static)]" />
		<xsl:variable name="instanceEvents" select="child::plx:event[not(@static)]" />
		<xsl:choose>
			<xsl:when test="$instanceFields|$instanceEvents">
				<xsl:for-each select="$instanceFields">
					<xsl:call-template name="RenderField">
						<xsl:with-param name="Indent" select="$initIndent"/>
						<xsl:with-param name="Prefix" select="'self.'"/>
					</xsl:call-template>
					<xsl:value-of select="$NewLine"/>
				</xsl:for-each>
				<xsl:for-each select="$instanceEvents">
					<xsl:value-of select="concat($Indent,$SingleIndent,$SingleIndent)"/>
					<xsl:text>self.</xsl:text>
					<xsl:value-of select="translate(@name,'$','_')"/>
					<xsl:text> = </xsl:text>
					<xsl:choose>
						<xsl:when test="plx:explicitDelegateType/@dataTypeQualifier">
							<xsl:value-of select="plx:explicitDelegateType/@dataTypeQualifier"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="../@name"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>.</xsl:text>
					<xsl:value-of select="translate(plx:explicitDelegateType/@dataTypeName,'$','_')"/>
					<xsl:text>()  # event</xsl:text>
					<xsl:value-of select="$NewLine"/>
					<xsl:variable name="hasAccessors" select="plx:onAdd/*|plx:onRemove/*"/>
					<xsl:if test="$hasAccessors">
						<xsl:call-template name="RenderEventAccessors">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="EventName" select="@name"/>
							<xsl:with-param name="Event" select="."/>
						</xsl:call-template>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($Indent,$SingleIndent,$SingleIndent)"/>
				<xsl:text>pass</xsl:text>
				<xsl:value-of select="$NewLine"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="concat($Indent,$SingleIndent)"/>
		<!-- _base - an easily accessable call to the base class - bcc 080308 -->
		<!--
		<xsl:variable name="BaseClassName" select="plx:derivesFromClass/@dataTypeName" />
		<xsl:if test="$BaseClassName">
			<xsl:text>def _base(self, *parms):</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="concat($Indent,$SingleIndent,$SingleIndent)"/>
			<xsl:value-of select="$BaseClassName" />
			<xsl:text>.__init__(self, *parms)</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="concat($Indent,$SingleIndent)"/>
		</xsl:if>
		-->
		<!-- <xsl:apply-templates select="plx:class | plx:delegate | plx:enum | plx:event | plx:field[not(@static)] | plx:function | plx:interface | plx:operatorFunction | plx:pragma | plx:property | plx:structure">
			<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
		</xsl:apply-templates> -->
	</xsl:template>
	<!--
	<xsl:template match="plx:class" mode="IndentInfo">
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
				</xsl:call-template>
	</xsl:template> -->
<!--	<xsl:template match="plx:class" mode="CloseBlock">
		<xsl:param name="Indent"/>
		<xsl:param name="StandardCloseWith"/>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:variable name="staticConstructor" select="child::plx:function[@name='.construct' and @modifier='static']"/>
			<xsl:if test ="$staticConstructor">
			<xsl:value-of select="concat($Indent,$SingleIndent)"/>
			<xsl:text>_</xsl:text>
				<xsl:value-of select="@name"/>
				<xsl:text>()</xsl:text>
				<xsl:value-of select="$NewLine"/>
				<xsl:value-of select="$NewLine"/>
			</xsl:if>
	</xsl:template> -->
	<!-- not yet -->
	<!-- this class method in .Net has 9? different versions
	http://msdn2.microsoft.com/en-us/library/system.string.concat(VS.71).aspx
	
	to concatinate two strings, python uses the '+' to concatinate strings
	whether that applies here depends on the parameter types
	- bcc 080219
	-->
	<xsl:template match="plx:concatenate">
		<xsl:param name="Indent"/>
		<xsl:text>string.Concat</xsl:text>
		<xsl:call-template name="RenderExpressionList">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
	</xsl:template>
	<!-- done - bcc 080221 -->
	<!-- python's equivalent is 'leftExp if condition else rightExp' - bcc 080219 -->
	<!-- C#'s equivalent is 'condition ? leftExp : rightExp' - bcc 080221 -->
	<xsl:template match="plx:conditionalOperator">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> if </xsl:text>
		<xsl:apply-templates select="plx:condition/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> else </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- okay? - python uses 'continue' with the same meaning - bcc 080219 -->
	<!-- but I don't understand what this is doing yet 
	- bcc 080219 -->
	<xsl:template match="plx:continue">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="parent::plx:*" mode="RenderBeforeLoopForContinue">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
		<xsl:text>continue</xsl:text>
	</xsl:template>
	<!-- what is this? - bcc 080219 -->
	<xsl:template match="*" mode="RenderBeforeLoopForContinue">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="parent::plx:*" mode="RenderBeforeLoopForContinue">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- ???? - bcc 080219 -->
	<xsl:template match="plx:iterator" mode="RenderBeforeLoopForContinue">
		<!-- We hit an iterator before a loop, the continue applies to this iterator, not a loop-->
	</xsl:template>
	<!-- no - non equivalent, python doesn't have a goto - bcc 080219 -->
	<xsl:template match="plx:label">
		<xsl:param name="Indent"/>
		<xsl:text> label </xsl:text>
		<xsl:message terminate="yes">goto/label not implemented - not available in normal Python.</xsl:message>
		<xsl:value-of select="translate(@name,'$','_')"/>
	</xsl:template>
	<xsl:template match="plx:label" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="statementClose" select="':'"/>
		</xsl:call-template>
	</xsl:template>
	<!-- not yet - bcc 080219 -->
	<!-- python uses 'while' and 'for' loops, but python's for is more like a 
	a c# foreach - bcc 080219 -->
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
	<!-- done - not expanded inline, ignore pre/post-fix - bcc 080229 -->
	<xsl:template match="plx:decrement">
		<xsl:param name="Indent"/>
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
			<xsl:text> -= 1</xsl:text>
	</xsl:template>
	<!-- no equivalent in python - bcc 080219 -->
	<!-- used to set default value when programmer when type isn't yet known 
	see http://msdn2.microsoft.com/en-us/library/xwth0h0d(vs.80).aspx for explanation
	-->
	<xsl:template match="plx:defaultValueOf">
		<xsl:text>PLiX.default("</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>")</xsl:text>
	</xsl:template>
	<!-- no equivalent in pytho - bcc 080219 -->
	<!-- I think this defines the delegate's signature, python doesn't define types - bcc 080219 -->
	<xsl:template match="plx:delegate">
		<xsl:param name="Indent"/>
		<xsl:variable name="returns" select="plx:returns"/>
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<!-- <xsl:if test="$returns">
			<xsl:for-each select="$returns">
				<xsl:call-template name="RenderAttributes">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="Prefix" select="'returns:'"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if> -->
		<!-- <xsl:call-template name="RenderVisibility"/> -->
		<!-- <xsl:call-template name="RenderReplacesName"/> -->
		<xsl:text>class </xsl:text>
		<!-- <xsl:choose>
			<xsl:when test="$returns">
				<xsl:for-each select="$returns">
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
				<xsl:text> </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>void </xsl:text>
			</xsl:otherwise>
		</xsl:choose> -->
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:text>(System.Delegate): pass</xsl:text>
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="$NewLine"/>
		<!-- <xsl:variable name="typeParams" select="plx:typeParam"/> -->
		<!-- <xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if> -->
		<!-- <xsl:call-template name="RenderParams"/> -->
		<!-- <xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParamConstraints">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:call-template>
		</xsl:if> -->
	</xsl:template>
	<!-- possible to use the same syntax (see attach event) - bcc 080219 -->
	<xsl:template match="plx:detachEvent">
		<xsl:param name="Indent"/>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> -= </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- ??? -->
	<xsl:template match="plx:directTypeReference">
		<xsl:call-template name="RenderType"/>
	</xsl:template>
	<!-- not done - not in python, but a recipe exists - bcc 080219 -->
	<!-- enum recipe: http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/413486
	here's another: http://pypi.python.org/pypi/enum/
	- bcc 080219
	-->
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
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<!-- trailing comma not needed - bcc 080304
	<xsl:template match="plx:enumItem" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="statementClose" select="','"/>
		</xsl:call-template>
	</xsl:template> -->
	<!-- this reference explains some differences between events and delegates
	http://blog.monstuff.com/archives/000040.html
	-->
	<!-- drafted - I define delegates and events in PLiXPY.py - bcc 080401 -->
	<xsl:template match="plx:event">
		<xsl:param name="Indent"/>
		<xsl:variable name="explicitDelegate" select="plx:explicitDelegateType"/>
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="implicitDelegateName" select="@implicitDelegateName"/>
		<xsl:variable name="isStatic" select="boolean(@static)"/>
		<xsl:variable name="hasAccessors" select="plx:onAdd/*|plx:onRemove/*"/>
		<!-- instance events are initialized explicitly inside of __init__ - bcc 080327 -->
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:text> = PLiXPY.event(</xsl:text>
		<xsl:if test="$isStatic">
			<xsl:choose>
				<xsl:when test="plx:explicitDelegateType/@dataTypeQualifier">
					<xsl:value-of select="plx:explicitDelegateType/@dataTypeQualifier"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="../@name"/>	
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>.</xsl:text>
			<xsl:value-of select="translate(explicitDelegateType/@dataTypeName,'$','_')"/>
			<xsl:text>()</xsl:text>
		</xsl:if>
		<xsl:text>) # event</xsl:text>
		<xsl:if test="$isStatic and $hasAccessors">
				<xsl:call-template name="RenderEventAccessors">
					<xsl:with-param name="Indent" select="$Indent"/>
					<xsl:with-param name="EventName" select="@name"/>
					<xsl:with-param name="Event" select="."/>
				</xsl:call-template>				
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
	<!-- no change - bcc 080219 -->
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
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:fallbackBranch">
		<xsl:text>else:</xsl:text>
	</xsl:template>
	<!-- not in python - change 'case' to 'if...elif' bcc 080219 -->
	<xsl:template match="plx:fallbackCase">
		<xsl:text>default:</xsl:text>
	</xsl:template>
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:fallbackCatch">
		<xsl:text>except:</xsl:text>
	</xsl:template>
	<!-- done - bc 080219 -->
	<xsl:template match="plx:falseKeyword">
		<xsl:text>False</xsl:text>
	</xsl:template>
	<!-- field: probably never render this one?? - bcc 080211 -->
	<!-- fields are always class and instance variables
	they never include initialization (that is done elsewhere)
	therefore they should never be generated!
	how to ignore fields? this writes blank lines - bcc 080211 -->
	<xsl:template match="plx:field">
		<xsl:param name="Indent"/>
		<xsl:choose>
			<!-- instance fields are rendered explicitly inside of __init__ - bcc 080307 -->
			<!-- this is giving me a blank line that I don't want. how to remove? - bcc 080307 -->
			<xsl:when test="not(@static) and name(..)='plx:class'" />
			<xsl:otherwise>
				<xsl:call-template name="RenderField">
					<!-- don't add a level of indentation - bcc 080322
					<xsl:with-param name="Indent" select="$Indent" /> -->
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:finally">
		<xsl:text>finally:</xsl:text>
	</xsl:template>
	<!-- partial - bcc 080219 -->
	<!-- need to address constructors (may be implicit in C#) and same name but different parameters 
- bcc 080221 -->
	<xsl:template match="plx:function">
		<xsl:param name="Indent"/>
		<!-- need to address static somehow - bcc 080306 -->
		<xsl:if test="not(@modifier='static') and not(@name='ToString')">
			<xsl:text>@PLiXPY.names(_function_router)</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>
		<!-- defer attributes - bcc 080306 
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template> -->
		<xsl:if test="@modifier='static'">
			<xsl:text>@staticmethod</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>
		<xsl:text>def </xsl:text>
		<xsl:variable name="name" select="@name"/>
		<xsl:choose>
			<!-- constructors and finalizers - bcc 080306 -->
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
							<xsl:text>_StaticInit</xsl:text>
							<!-- <xsl:value-of select="$className"/> -->
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$className"/>
						</xsl:otherwise>
						</xsl:choose>
						<xsl:variable name="firstparm">
							<xsl:if test="not(@modifier='static')">
								<xsl:text>self</xsl:text>
								<xsl:if test="count(plx:param)">
									<xsl:text>, </xsl:text>
								</xsl:if>
							</xsl:if>
						</xsl:variable>
						<xsl:call-template name="RenderParams">
							<xsl:with-param name="BeforeFirstItem" select="$firstparm"/>
						</xsl:call-template>
						<xsl:text>:</xsl:text>
						<!-- deal with initialize - bcc 080306 -->
						<xsl:choose>
							<xsl:when test="plx:initialize/child::plx:callThis">
						<xsl:for-each select="plx:initialize/child::plx:callThis">
							<xsl:value-of select="$NewLine"/>
							<xsl:value-of select="$Indent"/>
							<xsl:value-of select="$SingleIndent"/>
							<xsl:apply-templates select=".">
								<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
							</xsl:apply-templates>
						</xsl:for-each>
						</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$NewLine"/>
								<xsl:value-of select="concat($Indent, $SingleIndent)"/>
								<xsl:choose>
									<xsl:when test="@modifier='static'">
										<xsl:text>pass</xsl:text>
									</xsl:when>
									<xsl:otherwise>
								<xsl:text>self._init()</xsl:text>
									</xsl:otherwise>
								</xsl:choose>								
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- deal with finalize - bcc 080306
					<xsl:when test="$name='.finalize'">
						<xsl:text>~</xsl:text>
						<xsl:value-of select="$className"/>
						<xsl:text>()</xsl:text>
				<xsl:text>:</xsl:text>
					</xsl:when> -->
				</xsl:choose>
			</xsl:when>
			<!-- regular class and instance methods - bcc 080306 -->
			<xsl:otherwise>
				<!-- don't declare return value in python - bcc 080228
				<xsl:variable name="returns" select="plx:returns"/>
				<xsl:if test="$returns">
					<xsl:for-each select="$returns">
						<xsl:call-template name="RenderAttributes">
							<xsl:with-param name="Indent" select="$Indent"/>
							<xsl:with-param name="Prefix" select="'returns:'"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:if> -->
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
				<!-- return type: not in python - bcc 080211 -->
				<!-- <xsl:choose>
					<xsl:when test="$returns">
						<xsl:for-each select="$returns">
							<xsl:call-template name="RenderType"/>
						</xsl:for-each>
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>void </xsl:text>
					</xsl:otherwise>
				</xsl:choose> -->
				<xsl:if test="$isSimpleExplicitImplementation">
					<xsl:for-each select="plx:interfaceMember">
						<xsl:call-template name="RenderType"/>
					</xsl:for-each>
					<xsl:text>.</xsl:text>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="@name='ToString'">
						<xsl:text>__str__</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="translate(@name,'$','_')"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="typeParams" select="plx:typeParam"/>
				<xsl:if test="$typeParams">
					<xsl:call-template name="RenderTypeParams">
						<xsl:with-param name="TypeParams" select="$typeParams"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:variable name="firstparm">
					<xsl:if test="not(@modifier='static')">
						<xsl:text>self</xsl:text>
						<xsl:if test="count(plx:param)">
							<xsl:text>, </xsl:text>
						</xsl:if>
					</xsl:if>
				</xsl:variable>
				<xsl:call-template name="RenderParams">
					<xsl:with-param name="BeforeFirstItem" select="$firstparm"/>
				</xsl:call-template>
				<xsl:if test="$typeParams">
					<xsl:call-template name="RenderTypeParamConstraints">
						<xsl:with-param name="TypeParams" select="$typeParams"/>
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:text>:</xsl:text>
				<xsl:apply-templates select="." mode="RenderDocTest">
					<xsl:with-param name="Indent" select="$Indent" />
				</xsl:apply-templates>
				<!-- wrong test?? - need to test only contents - bcc 080306 -->
				<xsl:if test="count(*)- count(plx:leadingInfo|plx:trailingInfo|plx:attributeinterfaceMember|plx:typeParam|plx:param|plx:returns)=0">
					<xsl:value-of select="$NewLine"/>
					<xsl:value-of select="concat($Indent,$SingleIndent)"/>
					<xsl:text>pass</xsl:text>
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
	<!-- not yet - bcc 080219 -->
	<!-- the python syntax for properties/get/set is different
	see http://www.python.org/download/releases/2.2.3/descrintro/#property
	for details - bcc 080219 -->
	<xsl:template match="plx:get">
		<xsl:param name="Indent"/>
		<!-- <xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/> -->
		<xsl:choose>
			<xsl:when test="../@modifier='static'">
				<xsl:text>def __get__(self, obj, objtype):</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>def _get(self):</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(*)">
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="concat($Indent,$SingleIndent)"/>
			<xsl:text>raise AttributeError</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- goto not allowed in python - bcc 080219 -->
	<!-- someone implemented goto for python (as an april fools joke)!
	http://entrian.com/goto/
	http://mail.python.org/pipermail/python-list/2004-April/256904.html
	-->
	<xsl:template match="plx:goto">
		<xsl:param name="Indent"/>
		<xsl:text> goto </xsl:text>
		<xsl:message terminate="yes">goto not implemented - not available in normal Python.</xsl:message>
		<!-- <xsl:text>goto </xsl:text>
		<xsl:value-of select="translate(@name,'$','_')"/> -->
	</xsl:template>
	<xsl:template match="plx:gotoCase">
		<xsl:param name="Indent"/>
		<xsl:text> goto case </xsl:text>
		<xsl:message terminate="yes">goto case not implemented - not available in normal Python.</xsl:message>
		<!-- <xsl:text>goto case </xsl:text>
		<xsl:apply-templates select="plx:condition/child::*">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:apply-templates> -->
	</xsl:template>
	<!-- done - not expanded inline, ignore pre/post-fix- bcc 080229 -->
	<xsl:template match="plx:increment">
		<xsl:param name="Indent"/>
		<!-- UNDONE: Can we always render like this, or only for nameRef and call* type='field' -->
		<xsl:variable name="postfix" select="@type='post'"/>
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
			<xsl:text >+= 1</xsl:text>
	</xsl:template>
	<!-- not yet - 'foreach' in c# but 'for' in python; may depend on types - bcc 080219 -->
	<xsl:template match="plx:iterator">
		<xsl:param name="Indent"/>
		<xsl:text>for </xsl:text>
		<!-- don't gen type
		<xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text> -->
		<xsl:value-of select="@localName"/>
		<xsl:text> in </xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text>:</xsl:text>
	</xsl:template>
	<!-- never generate interfaces - bcc 080407 -->
	<xsl:template match="plx:interface" mode="CollectInline">
			<xsl:param name="LocalItemKey"/>
			<plxGen:inlineExpansion surrogatePreExpanded="true" childrenModified="true">
				<plxGen:expansion>
				</plxGen:expansion>
				<plxGen:surrogate>
				</plxGen:surrogate>
			</plxGen:inlineExpansion>
	</xsl:template>
	<!-- local: should only generate if initialized? - bcc 080211 -->
	<!-- partial - bcc 080219 -->
	<xsl:template match="plx:local">
		<xsl:param name="Indent"/>
		<!-- const: not in python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderConst"/> -->
		<!-- type: not in python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderType"/>
		<xsl:text> </xsl:text> -->
		<xsl:if test="not(plx:initialize)">
			<xsl:text># </xsl:text>
		</xsl:if>
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:for-each select="plx:initialize">
			<xsl:text> = </xsl:text>
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<!-- problem area - bcc 080219 -->
	<!-- there is a difference in what you are locking
	c# specifies the object that should be locked; python specifies a lock object
	c#'s lock is described at http://msdn2.microsoft.com/en-us/library/c5kehkcz(VS.71).aspx
	python's 'with lockobj:' is described at http://www.python.org/doc/lib/with-locks.html
	an example is given at http://effbot.org/zone/thread-synchronization.htm
	- bcc 080219 -->
	<xsl:template match="plx:lock">
		<xsl:param name="Indent"/>
		<xsl:message terminate="yes">lock implemented yet</xsl:message>
		<xsl:text>lock (</xsl:text>
		<xsl:for-each select="plx:initialize">
			<xsl:apply-templates select="child::*">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<!-- not yet - bcc 080219 -->
	<!-- c# has 'for, do, while' loops; python has only 'while' loop 
	I don't know yet the effect this will have on generating code
	- bcc 080219
	see formula for do...while loop in python
	http://mail.python.org/pipermail/python-list/2000-December/063859.html
	- bcc 080221 -->
	<xsl:template match="plx:loop">
		<xsl:param name="Indent"/>
		<xsl:variable name="initialize" select="plx:initializeLoop/child::plx:*"/>
		<xsl:variable name="condition" select="plx:condition/child::plx:*"/>
		<xsl:variable name="beforeLoop" select="plx:beforeLoop/child::plx:*"/>
		<xsl:if test="$initialize">
			<xsl:apply-templates select="$initialize">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
			<xsl:value-of select="$NewLine"/>
			<xsl:value-of select="$Indent"/>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="not(@checkCondition='after') and $condition">
				<xsl:text>while (</xsl:text>
				<xsl:apply-templates select="$condition">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
				<xsl:text>):</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>while 1:</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="plx:loop" mode="IndentInfo">
		<xsl:choose>
			<xsl:when test="@checkCondition='after' or plx:condition">
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
				<!-- <xsl:with-param name="Indent" select="$Indent"/> -->
				<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
			</xsl:apply-templates>
			<xsl:value-of select="$NewLine"/>
			<!-- <xsl:value-of select="$Indent"/> -->
		</xsl:if>
		<xsl:value-of select="$StandardCloseWith"/>
		<xsl:variable name="condition" select="plx:condition/child::plx:*"/>
		<xsl:if test="@checkCondition='after' and $condition">
			<xsl:value-of select="$SingleIndent"/>
			<xsl:text>if not (</xsl:text>
			<xsl:apply-templates select="plx:condition/child::plx:*">
				<!-- <xsl:with-param name="Indent" select="$Indent"/> -->
			<xsl:with-param name="Indent" select="concat($Indent,$SingleIndent)"/>
		</xsl:apply-templates>
			<xsl:text>): break</xsl:text>
			<xsl:value-of select="$NewLine"/>
			<!-- <xsl:value-of select="$Indent"/> -->
		</xsl:if>
	</xsl:template>
	<!-- same in python? - bcc 080219 -->
	<xsl:template match="plx:nameRef">
		<xsl:value-of select="translate(@name,'$','_')"/>
	</xsl:template>
	<!-- not in python - bcc 080219 -->
<!-- don't render namespace (and don't indent contents)
	<xsl:template match="plx:namespace">
		<xsl:text>namespace </xsl:text>
		<xsl:value-of select="translate(@name,'$','_')"/>
	</xsl:template> -->
	<xsl:template match="plx:namespace" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="'nakedBlock'"/>
		</xsl:call-template>
	</xsl:template>
	<!-- okay - different in python - bcc 080403 -->
	<!-- python imports modules, not namespaces, not clear what the 
	differences will be - bcc 080219 -->
	<xsl:template match="plx:namespaceImport">
		<xsl:choose>
			<!-- .NET names should already be accessable - bcc 0804003 --> 
			<xsl:when test="starts-with(@name, 'System.')"/>
			<xsl:otherwise>
				<xsl:text>import </xsl:text>
				<xsl:value-of select="@name"/>
				<xsl:if test="string-length(@alias)">
					<xsl:text> as </xsl:text>
					<xsl:value-of select="@alias"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- not in python - python doesn't allow inline statements - bcc 080219 -->
	<!-- need an example - for now assuming it isn't valid - bcc 080327 -->
	<xsl:template match="plx:nullFallbackOperator">
		<xsl:param name="Indent"/>
		<xsl:message terminate="yes">nullFallbackOperator implemented yet</xsl:message>
		<xsl:apply-templates select="plx:left/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
		<xsl:text> ?? </xsl:text>
		<xsl:apply-templates select="plx:right/child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- okay - bcc 080327 -->
	<xsl:template match="plx:nullKeyword">
		<xsl:text>None</xsl:text>
	</xsl:template>
	<!-- not yet - this appears to be functions that definition operators - bcc 080219 -->
	<!-- python defines special funtion names for defining operators on classes
	for example the '__add__' method is used to define '+' behavior
	I'll need to see examples to work out the python equivalents
	- bcc 080219 -->
	<xsl:template match="plx:operatorFunction">
		<xsl:param name="Indent"/>
		<xsl:message terminate="yes">operator functions implemented yet</xsl:message>
		<xsl:variable name="operatorType" select="string(@type)"/>
		<!-- working on this (bcc) -->
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
	<!-- not yet - bcc 080401 -->
	<!-- I did some work on these, but wasn't able to generate the correct 
	examples out of plix reflector - bcc 080401 -->
	<xsl:template match="plx:onAdd">
		<xsl:text> event add </xsl:text>
		<xsl:message terminate="yes">event add implemented yet</xsl:message>
	</xsl:template>
	<xsl:template match="plx:onRemove">
		<xsl:text> event remove </xsl:text>
		<xsl:message terminate="yes">event remove implemented yet</xsl:message>
	</xsl:template>
	<!-- python doesn't support pragma - bcc 080219 -->
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
	<!-- not yet - see 'get' - bcc 080219 -->
	<xsl:template match="plx:property">
		<xsl:param name="Indent"/>
		<!-- don't render attributes - bcc 080319
		<xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template> -->
		<xsl:variable name="returns" select="plx:returns"/>
		<!-- <xsl:for-each select="$returns">
			<xsl:call-template name="RenderAttributes">
				<xsl:with-param name="Indent" select="$Indent"/>
				<xsl:with-param name="Prefix" select="'returns:'"/>
			</xsl:call-template>
		</xsl:for-each> -->
		<xsl:variable name="isSimpleExplicitImplementation"
			select="@visibility='privateInterfaceMember' and not(@modifier='static') and count(plx:interfaceMember)=1 and @name=plx:interfaceMember/@memberName"/>
		<!-- <xsl:if test="not($isSimpleExplicitImplementation)">
			<xsl:if test="not(parent::plx:interface)">
				<xsl:call-template name="RenderVisibility"/>
				<xsl:call-template name="RenderProcedureModifier"/>
			</xsl:if>
			<xsl:call-template name="RenderReplacesName"/>
		</xsl:if> -->
		<!-- <xsl:for-each select="$returns">
			<xsl:call-template name="RenderType"/>
		</xsl:for-each> -->
		<xsl:text># property: </xsl:text>
		<xsl:variable name="name" select="@name"/>
		<xsl:variable name="isIndexer" select="parent::plx:*/@defaultMember=$name"/>
		<xsl:choose>
			<xsl:when test="$isIndexer">
				<xsl:message terminate="yes">indexers are not implemented </xsl:message>
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
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="$Indent"/>
		<xsl:choose>
			<xsl:when test="@modifier='static'">
				<!-- <xsl:message terminate="yes">static properties are not implemented </xsl:message> -->
				<xsl:text>class _property(object):</xsl:text>
				<xsl:if test="not(plx:get)">
					<xsl:value-of select="concat($NewLine,$Indent,$SingleIndent)"/>
					<xsl:text>def __get__(self, obj, objtype): raise AttributeError </xsl:text>
				</xsl:if>
				<xsl:if test="not(plx:set)">
					<xsl:value-of select="concat($NewLine,$Indent,$SingleIndent)"/>
					<xsl:text>def __set__(self, obj, value): raise AttributeError </xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>if 1:</xsl:text>
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
				<xsl:call-template name="CustomizeIndentInfo">
					<xsl:with-param name="defaultInfo">
						<xsl:apply-imports/>
					</xsl:with-param>
					<xsl:with-param name="closeBlockCallback" select="true()"/>
					<!-- <xsl:with-param name="style" select="'nakedBlock'"/> -->
				</xsl:call-template>
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
<!--		<xsl:variable name="generateForwardCalls">
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
							<!- - This isn't schema tested. Ignore warnings. - ->
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
		</xsl:choose> -->
		<xsl:value-of select="@name"/>
		<xsl:choose>
			<xsl:when test="$contextIsStatic">
				<xsl:text> = _property()</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> = property(</xsl:text>
				<xsl:variable name="get" select="plx:get"/>
				<xsl:variable name="set" select="plx:set"/>
				<xsl:choose>
					<xsl:when test="$get and $set">
						<xsl:text>_get, _set</xsl:text>
					</xsl:when>
					<xsl:when test="$get">
						<xsl:text>_get</xsl:text>
					</xsl:when>
					<xsl:when test="$set">
						<xsl:text>fset=_set</xsl:text>
					</xsl:when>
				</xsl:choose>
				<xsl:text>)</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$NewLine"/>
		<xsl:value-of select="$NewLine"/>
</xsl:template>
	<!-- same in python - bcc 080219 -->
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
	<!-- not yet - see 'get' - bcc 080219 -->
	<xsl:template match="plx:set">
		<xsl:param name="Indent"/>
		<!-- <xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>
		<xsl:call-template name="RenderVisibility"/> -->
		<xsl:choose>
			<xsl:when test="../@modifier='static'">
				<xsl:text>def __set__(self, obj, val):</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>def _set(self, value):</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(*)">
			<xsl:value-of select="concat($NewLine,$Indent,$SingleIndent)"/>
			<xsl:text>raise AttributeError</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- same in python - bcc 080219 -->
	<xsl:template match="plx:string">
		<xsl:variable name="rawValue">
			<xsl:call-template name="RenderRawString"/>
		</xsl:variable>
		<xsl:call-template name="RenderString">
			<xsl:with-param name="String" select="string($rawValue)"/>
		</xsl:call-template>
	</xsl:template>
	<!-- see class, interface, structure above - bcc 080219 -->
	<!-- never executed? (there is another match that catches this - bcc 080209 -->
	<xsl:template match="plx:structure">
		<xsl:param name="Indent"/>
		<xsl:call-template name="RenderTypeDefinition">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="TypeKeyword" select="'struct'"/>
		</xsl:call-template>
	</xsl:template>
	<!-- not in python - use 'if:...elif' - bcc 080219 -->
	<xsl:template match="plx:switch" mode="CollectInline">
		<xsl:param name="LocalItemKey"/>
		<xsl:variable name="condition" select="plx:condition/child::*"/>
		<xsl:variable name="customSwitchVariable" select="not($condition[self::plx:nameRef])"/>
		<xsl:variable name="customSwitchVariableName" select="concat($GeneratedVariablePrefix,$LocalItemKey,'sv')"/>
		<xsl:variable name="switchVariableFragment">
			<xsl:choose>
				<xsl:when test="$customSwitchVariable">
					<plx:nameRef name="{$customSwitchVariableName}"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$condition"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="cases" select="plx:case"/>
		<xsl:variable name="fallback" select="plx:fallbackCase"/>
		<plxGen:inlineExpansion surrogatePreExpanded="true" childrenModified="true">
			<plxGen:expansion>
				<xsl:if test="$customSwitchVariable">
					<plx:local name="{$customSwitchVariableName}">
						<!-- Note that we're not setting datatype, python won't use it anyway -->
						<plx:initialize>
							<xsl:copy-of select="$condition"/>
						</plx:initialize>
					</plx:local>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$cases">
						<xsl:variable name="firstCaseHasBlockInfo" select="boolean($cases[1]/child::plx:*[self::plx:blockLeadingInfo or self::plx:blockTrailingInfo])"/>
						<xsl:if test="$firstCaseHasBlockInfo">
							<!-- We can't do leading and trailing on a branch, force it to an alternate branch -->
							<plx:branch>
								<plx:condition>
									<plx:falseKeyword/>
								</plx:condition>
							</plx:branch>
						</xsl:if>
						<xsl:for-each select="$cases">
							<xsl:variable name="branchName">
								<xsl:choose>
									<xsl:when test="position()=1 and not($firstCaseHasBlockInfo)">
										<xsl:text>branch</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>alternateBranch</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:element name="plx:{$branchName}">
								<xsl:variable name="caseExpressionsFragment">
									<xsl:for-each select="plx:condition">
										<plx:binaryOperator type="equality">
											<plx:left>
												<xsl:copy-of select="$switchVariableFragment"/>
											</plx:left>
											<plx:right>
												<xsl:copy-of select="child::*"/>
											</plx:right>
										</plx:binaryOperator>
									</xsl:for-each>
								</xsl:variable>
								<plx:condition>
									<xsl:call-template name="OrTogetherExpressions">
										<xsl:with-param name="Expressions" select="exsl:node-set($caseExpressionsFragment)/child::*"/>
									</xsl:call-template>
								</plx:condition>
								<xsl:copy-of select="child::*[not(self::plx:condition)]"/>
							</xsl:element>
						</xsl:for-each>
						<plx:fallbackBranch>
							<xsl:copy-of select="$fallback/child::*"/>
						</plx:fallbackBranch>
					</xsl:when>
					<xsl:when test="$fallback">
						<xsl:copy-of select="$fallback/child::*"/>
					</xsl:when>
				</xsl:choose>
			</plxGen:expansion>
			<plxGen:surrogate>
			</plxGen:surrogate>
		</plxGen:inlineExpansion>
	</xsl:template>
	<xsl:template name="OrTogetherExpressions">
		<xsl:param name="Expressions"/>
		<xsl:param name="CurrentPosition" select="1"/>
		<xsl:param name="ItemCount" select="count($Expressions)"/>
		<xsl:choose>
			<xsl:when test="$CurrentPosition=$ItemCount">
				<xsl:copy-of select="$Expressions[$CurrentPosition]"/>
			</xsl:when>
			<xsl:otherwise>
				<plx:binaryOperator type="booleanOr">
					<plx:left>
						<xsl:copy-of select="$Expressions[$CurrentPosition]"/>
					</plx:left>
					<plx:right>
						<xsl:call-template name="OrTogetherExpressions">
							<xsl:with-param name="Expressions" select="$Expressions"/>
							<xsl:with-param name="CurrentPosition" select="$CurrentPosition + 1"/>
							<xsl:with-param name="ItemCount" select="$ItemCount"/>
						</xsl:call-template>
					</plx:right>
				</plx:binaryOperator>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--
	<xsl:template match="plx:switch" mode="IndentInfo">
		<xsl:call-template name="CustomizeIndentInfo">
			<xsl:with-param name="defaultInfo">
				<xsl:apply-imports/>
			</xsl:with-param>
			<xsl:with-param name="style" select="'nakedBlock'"/>
		</xsl:call-template>
	</xsl:template> -->
	<!-- done - python ususally uses 'self' instead - bcc 080219 -->
	<!-- python requires this in cases where it is optional in c#, but
is it always there in plix - bcc 080221 -->
	<xsl:template match="plx:thisKeyword">
		<xsl:text>self</xsl:text>
	</xsl:template>
	<!-- done - python uses 'raise' instead of 'throw' - bcc 080404 -->
	<xsl:template match="plx:throw">
		<xsl:param name="Indent"/>
		<xsl:text>raise</xsl:text>
		<xsl:for-each select="child::plx:*">
			<xsl:text> </xsl:text>
			<xsl:apply-templates select=".">
				<xsl:with-param name="Indent" select="$Indent"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:trueKeyword">
		<xsl:text>True</xsl:text>
	</xsl:template>
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:try">
		<xsl:text>try:</xsl:text>
	</xsl:template>
	<!-- done? - bcc 080219 -->
	<!-- this is the equivalent, but is it used the same way? - bcc 080219 -->
	<xsl:template match="plx:typeOf">
		<xsl:text>type(</xsl:text>
		<xsl:call-template name="RenderType"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	<!-- done - bcc 080219 -->
	<xsl:template match="plx:unaryOperator">
		<xsl:param name="Indent"/>
		<xsl:variable name="type" select="string(@type)"/>
		<xsl:choose>
			<xsl:when test="$type='booleanNot'">
				<xsl:text>not </xsl:text>
			</xsl:when>
			<!-- bitwise unary: not
				http://docs.python.org/ref/unary.html (bcc)-->
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
		<xsl:apply-templates select="child::*" mode="ResolvePrecedence">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="Context" select="."/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- okay - bcc 080401 -->
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
			<!-- not required in python - bcc 080401
			<xsl:when test="$type='r4'">
				<xsl:value-of select="$data"/>
				<xsl:text>F</xsl:text>
			</xsl:when> -->
			<xsl:otherwise>
				<xsl:value-of select="$data"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- in C# 'value' contains the data submitted to a setter 
	in python, the 'value' equivalent is defined as a parameter in the setter heading
	no problem with using the word 'value'
	- bcc 080221 -->
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
		<xsl:value-of select="translate(@name,'$','_')"/>
	</xsl:template>
	<xsl:template match="plx:passTypeParam|plx:passMemberTypeParam|plx:derivesFromClass|plx:implementsInterface|plx:returns|plx:explicitDelegateType|plx:typeConstraint" mode="TopLevel">
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
		<xsl:call-template name="RenderPassParams">
			<xsl:with-param name="Indent" select="$Indent"/>
			<xsl:with-param name="PassParams" select="plx:passParam"/>
			<xsl:with-param name="BracketPair" select="''"/>
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
	<!-- okay as it - bcc 080226 -->
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
	<!-- ignore attributes - bcc 080226 -->
	<!-- there is no generic equivalent in python
		it may be possible to implement equivalents for specific attributes
		but that should be treated on a case by case basis
		for methods python has a "decorator" that may be usable to implement
		equivalent effect in specific cases
		- bcc 080226 -->
	<xsl:template name="RenderAttribute">
		<xsl:param name="Indent"/>
	</xsl:template>
	<xsl:template name="RenderAttributes">
		<xsl:param name="Indent"/>
	</xsl:template>
	<!-- Not required in python - bcc 080226 -->
	<!-- python doesn't need to take any action when this 
	would be output - bcc 080226 -->
	<xsl:template name="RenderArrayDescriptor">
	</xsl:template>
	<!-- draft - needs testing - bcc 080226-->
	<xsl:template name="RenderArrayInitializer">
		<!-- I changed curly braces to square, ?may also have to omit empty braces? probably not - bcc 080226 -->
		<xsl:param name="Indent"/>
		<xsl:variable name="nestedInitializers" select="plx:arrayInitializer"/>
		<xsl:variable name="nextIndent" select="concat($Indent,$SingleIndent)"/>
		<!-- We either get nested expressions or nested initializers, but not both -->
		<xsl:choose>
			<xsl:when test="$nestedInitializers">
				<xsl:text>[</xsl:text>
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
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="RenderExpressionList">
					<xsl:with-param name="Indent" select="$nextIndent"/>
					<xsl:with-param name="BracketPair" select="'[]'"/>
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
			<xsl:choose>
				<xsl:when test="@name='IndexOf'">
					<xsl:text>find</xsl:text>
				</xsl:when>
				<!-- <xsl:when test="@name='Message'">
					<xsl:text>message</xsl:text>
				</xsl:when> -->
				<xsl:otherwise>
					<xsl:value-of select="translate(@name,'$','_')"/>
				</xsl:otherwise>
			</xsl:choose>
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
	<!-- not in python - bcc 080328 -->
  <!--	<xsl:template name="RenderClassModifier">
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
	</xsl:template> -->
	<!-- not in python - bcc 080401 -->
	<!-- <xsl:template name="RenderConst">
		<xsl:param name="Const" select="@const"/>
		<xsl:if test="$Const='true' or $Const='1'">
			<xsl:text>const </xsl:text>
		</xsl:if>
	</xsl:template> -->
	<xsl:template match="*" mode="RenderDocTest">
		<!-- Leave this empty, place holder for the same template in an importing file -->
	</xsl:template>
	<!-- on hold - unable to generate test case in PLiX from reflector - bcc 080401 -->
	<xsl:template name="RenderEventAccessors">
		<xsl:param name="Indent"/>
		<xsl:param name="EventName" select="''"/>
		<xsl:param name="Event"/>
		<!-- add -->
		<xsl:value-of select="concat($NewLine,$Indent)"/>
		<xsl:text>def _add(self):</xsl:text>
		<xsl:apply-templates select="plx:onAdd/*"/>
		<xsl:value-of select="concat($NewLine,$Indent)"/>
		<xsl:text>self.</xsl:text>
		<xsl:value-of select="$EventName"/>
		<xsl:text>.onAdd = instancemethod( _add, self, self.__class__)</xsl:text>
		<xsl:value-of select="concat($NewLine,$Indent)"/>
		<!-- remove -->
		<xsl:value-of select="concat($NewLine,$Indent)"/>
		<xsl:text>def _remove(self):</xsl:text>
		<xsl:apply-templates select="plx:onRemove/*"/>
		<xsl:value-of select="concat($NewLine,$Indent)"/>
		<xsl:text>self.</xsl:text>
		<xsl:value-of select="$EventName"/>
		<xsl:text>.onRemove = instancemethod( _add, self, self.__class__)</xsl:text>
		<xsl:value-of select="concat($NewLine,$Indent)"/>
	</xsl:template>
	<!-- no change - this looks okay - bcc 080226 -->
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
	<!-- moved field processing here, because must render
	static and non-static in different places - bcc 080207 -->
	<xsl:template name="RenderField">
		<xsl:param name="Indent"/>
		<xsl:param name="Prefix"/>
		<xsl:value-of select="$Indent"/>
		<xsl:value-of select="$Prefix"/>
		<!-- attributes: not yet - bcc 080211 -->
		<!-- <xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template> -->
		<!-- visibility: not yet, complex name issue - bcc 080211 -->
		<!-- <xsl:call-template name="RenderVisibility"/> -->
		<!-- static?: problem, render static and class in different places - bcc 080211 -->
		<!-- static variables are defined in the class in python,
		but instance variables should be defined inside the __init__ function - bcc 080211 -->
		<!-- <xsl:call-template name="RenderStatic"/> -->
		<!-- volatile: not in python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderVolatile"/> -->
		<!-- replaces name: not in Python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderReplacesName"/> -->
		<!-- const: not in python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderConst"/> -->
		<!-- readonly: not in python? - bcc 080211 -->
		<!-- may be possible with python getters and setters? - bc 080211 -->
		<!-- <xsl:call-template name="RenderReadOnly"/> -->
		<!-- type: not in python - bcc 080211 -->
		<!-- <xsl:call-template name="RenderType"/> 
		<xsl:text> </xsl:text> -->
		<xsl:value-of select="translate(@name,'$','_')"/>
		<xsl:choose>
			<xsl:when test="plx:initialize">
				<xsl:for-each select="plx:initialize">
					<xsl:text> = </xsl:text>
					<xsl:apply-templates select="child::*">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="@dataTypeName='.boolean'">
				<xsl:text> = False</xsl:text>
			</xsl:when>
			<xsl:when test="@dataTypeName='.string'">
				<xsl:text> = ""</xsl:text>
			</xsl:when>
			<xsl:when test="starts-with(@dataTypeName,'.i')">
				<xsl:text> = 0</xsl:text>
			</xsl:when>
			<xsl:when test="starts-with(@dataTypeName,'.r')">
				<xsl:text> = 0.0</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> = None</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<!-- <xsl:value-of select="concat($Indent,$SingleIndent)"/> -->
	</xsl:template>
	<xsl:template name="RenderParams">
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="RenderEmptyBrackets" select="true()"/>
		<xsl:param name="BeforeFirstItem" select="''"/>
		<xsl:variable name="params" select="plx:param"/>
		<xsl:choose>
			<xsl:when test="$params">
				<xsl:value-of select="substring($BracketPair,1,1)"/>
				<xsl:for-each select="$params">
					<xsl:choose>
						<xsl:when test="position()=1">
							<xsl:value-of select="$BeforeFirstItem"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>, </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
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
					<!-- <xsl:call-template name="RenderType"/>
					<xsl:text> </xsl:text> -->
					<xsl:value-of select="translate(@name,'$','_')"/>
				</xsl:for-each>
				<xsl:value-of select="substring($BracketPair,2,1)"/>
			</xsl:when>
			<xsl:when test="$RenderEmptyBrackets">
				<xsl:value-of select="substring($BracketPair,1,1)"/>
				<xsl:value-of select="$BeforeFirstItem"/>
				<xsl:value-of select="substring($BracketPair,2,1)"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderPartial">
		<xsl:param name="Partial" select="@partial"/>
		<xsl:if test="$Partial='true' or $Partial='1'">
			<xsl:message terminate="yes">partial not implemented - not available in Python.</xsl:message>
		</xsl:if>
	</xsl:template>
	<xsl:template name="RenderPassTypeParams">
		<xsl:param name="PassTypeParams" select="plx:passTypeParam"/>
		<!-- <xsl:if test="$PassTypeParams">
			<xsl:text>&lt;</xsl:text>
			<xsl:for-each select="$PassTypeParams">
				<xsl:if test="position()!=1">
					<xsl:text>, </xsl:text>
				</xsl:if>
				<xsl:call-template name="RenderType"/>
			</xsl:for-each>
			<xsl:text>&gt;</xsl:text>
		</xsl:if> -->
	</xsl:template>
	<xsl:template name="RenderPassParams">
		<xsl:param name="Indent"/>
		<xsl:param name="PassParams" select="plx:passParam|plx:passParamArray/plx:passParam"/>
		<xsl:param name="BracketPair" select="'()'"/>
		<xsl:param name="ListSeparator" select="', '"/>
		<xsl:param name="BeforeFirstItem" select="''"/>
		<xsl:choose>
			<xsl:when test="$BracketPair='[]' and count($PassParams)>1">
				<xsl:for-each select="$PassParams">
					<xsl:value-of select="substring($BracketPair,1,1)"/>
					<xsl:apply-templates select="child::*">
						<xsl:with-param name="Indent" select="$Indent"/>
					</xsl:apply-templates>
					<xsl:value-of select="substring($BracketPair,2)"/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
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
						<xsl:message terminate="yes">'ref' not implemented - not available in Python.</xsl:message>
						<xsl:text>ref </xsl:text>
					</xsl:when>
					<xsl:when test="@type='out'">
						<xsl:message terminate="yes">'out' not implemented - not available in Python.</xsl:message>
						<xsl:text>out </xsl:text>
					</xsl:when>
				</xsl:choose>
				<xsl:apply-templates select="child::*">
					<xsl:with-param name="Indent" select="$Indent"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:value-of select="substring($BracketPair,2)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="RenderProcedureModifier">
		<xsl:variable name="modifier" select="@modifier"/>
		<!--
		<xsl:choose> -->
			<!-- modifier not displayed at this position - bcc 080228
			<xsl:when test="$modifier='static'">
				<xsl:text>static </xsl:text>
			</xsl:when> -->
			<!-- not of these are required (or possible) in python - bcc 080306
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
			</xsl:when> -->
		<!-- </xsl:choose> -->
	</xsl:template>
	<!-- not available in python - bcc 080401 
	<xsl:template name="RenderReadOnly">
		<xsl:param name="ReadOnly" select="@readOnly"/>
		<xsl:if test="$ReadOnly='true' or $ReadOnly='1'">
			<xsl:text>readonly </xsl:text>
		</xsl:if>
	</xsl:template> -->
	<xsl:template name="RenderReplacesName">
		<xsl:param name="ReplacesName" select="@replacesName"/>
		<!-- not needed in python - bcc 080306
		<xsl:if test="$ReplacesName='true' or $ReplacesName='1'">
			<xsl:text>new </xsl:text>
		</xsl:if> -->
	</xsl:template>
	<!-- not used - bcc 080408 -->
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
				<xsl:if test="$AddQuotes">
					<xsl:text>&quot;</xsl:text>
				</xsl:if>
				<xsl:variable name="diff" select="string-length(translate($String,'&quot;\&#xd;&#xa;&#x9;',''))!=string-length($String)"/>
				<xsl:choose>
					<xsl:when test="$diff">
						<xsl:call-template name="EscapeString">
							<xsl:with-param name="String" select="$String"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$String"/>
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
	<xsl:template name="EscapeString">
		<xsl:param name="String"/>
		<xsl:if test="$String">
			<xsl:variable name="firstChar" select="substring($String,1,1)"/>
			<xsl:choose>
				<xsl:when test="'&quot;'=$firstChar">
					<xsl:text>\&quot;</xsl:text>
				</xsl:when>
				<xsl:when test="'\'=$firstChar">
					<xsl:text>\\</xsl:text>
				</xsl:when>
				<xsl:when test="'&#xd;'=$firstChar">
					<xsl:text>\r;</xsl:text>
				</xsl:when>
				<xsl:when test="'&#xa;'=$firstChar">
					<xsl:text>\n</xsl:text>
				</xsl:when>
				<xsl:when test="'&#x9;'=$firstChar">
					<xsl:text>\t</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$firstChar"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="EscapeString">
				<xsl:with-param name="String" select="substring($String,2)"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
		<xsl:template name="RenderType">
		<xsl:param name="RenderArray" select="true()"/>
		<xsl:param name="DataTypeName" select="@dataTypeName"/>
		<xsl:variable name="rawTypeName" select="string($DataTypeName)"/>
		<xsl:choose>
			<xsl:when test="string-length($rawTypeName)">
				<!-- Spit the name for the raw type -->
				<xsl:choose>
					<xsl:when test="starts-with($rawTypeName,'.')">
						<xsl:choose>
							<xsl:when test="$rawTypeName='.i1'">
								<xsl:text>System.sbyte</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i2'">
								<xsl:text>System.short</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i4'">
								<xsl:text>System.int</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.i8'">
								<xsl:text>System.long</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u1'">
								<xsl:text>System.byte</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u2'">
								<xsl:text>System.ushort</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u4'">
								<xsl:text>System.uint</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.u8'">
								<xsl:text>System.ulong</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.r4'">
								<xsl:text>System.float</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.r8'">
								<xsl:text>System.double</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.char'">
								<xsl:text>System.char</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.decimal'">
								<xsl:text>System.decimal</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.object'">
								<xsl:text>System.object</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.boolean'">
								<xsl:text>System.bool</xsl:text>
							</xsl:when>
							<xsl:when test="$rawTypeName='.string'">
								<xsl:text>System.string</xsl:text>
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
		<xsl:variable name="classtype" select="$TypeKeyword='class'"/>
		<xsl:variable name="enumtype" select="$TypeKeyword='enum'"/>
		<!-- <xsl:call-template name="RenderAttributes">
			<xsl:with-param name="Indent" select="$Indent"/>
		</xsl:call-template>  -->
		<!-- for now skip visibility, requires prefixing names w underscores? - bc 080209 -->
		<!-- <xsl:call-template name="RenderVisibility"/>  -->
		<!-- not required in python - bcc 080211 -->
		<!-- required in C# if a subclass hides the implementation in parent
		- bcc 080211 -->
		<!-- <xsl:call-template name="RenderReplacesName"/> -->
		<!-- python doesn't do static classes, don't know about abstract or sealed - bc 080209 -->
		<!-- <xsl:call-template name="RenderClassModifier"/> -->
		<!-- can python have partial classes? yes, but have to be manually combined?
		python allows easy to an existing class, but would we know which part comes first
		I think that in C# the parts are peers. We may have to generate both have to 
		create the class if it doesn't exist or add to it if it does.
		- bcc 080209
		-->
		<!-- not implemented - bcc 080401 -->
		<xsl:call-template name="RenderPartial"/>
		<xsl:choose>
			<xsl:when test="$enumtype">
				<xsl:text>class</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$TypeKeyword"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> </xsl:text>
		<xsl:value-of select="translate(@name,'$','_')"/>
		<!-- python doesn't put parameters in class def - bcc 080211 -->
		<!-- these are 'generic' types, what is python's equivalent? - bcc 080304 -->
		<!-- <xsl:variable name="typeParams" select="plx:typeParam"/>
		<xsl:if test="$typeParams">
			<xsl:call-template name="RenderTypeParams">
				<xsl:with-param name="TypeParams" select="$typeParams"/>
			</xsl:call-template>
		</xsl:if>
		-->
		<!-- python allows multiple, but plix only allows one -->
		<xsl:variable name="baseClass" select="plx:derivesFromClass"/>
		<xsl:choose>
			<xsl:when test="$baseClass">
				<xsl:text> ( </xsl:text>
				<xsl:for-each select="$baseClass">
					<xsl:call-template name="RenderType"/>
				</xsl:for-each>
				<xsl:text> ) </xsl:text>
			</xsl:when>
			<xsl:when test="$enumtype">
				<xsl:text>(PLiXPY.enum)</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>(PLiXPY.Object)</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<!-- don't implement interface yet - bcc 080211 -->
		<!--<xsl:for-each select="plx:implementsInterface">
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
		 -->
		<xsl:text>:</xsl:text>
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
				<xsl:value-of select="translate(@name,'$','_')"/>
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
	<!-- not required in python - bcc 080327 -->
	<xsl:template name="RenderTypeParams">
		<xsl:param name="TypeParams"/>
		<!-- 
		<xsl:text>&lt;</xsl:text>
		<xsl:for-each select="$TypeParams">
			<xsl:if test="position()!=1">
				<xsl:text>, </xsl:text>
			</xsl:if>
			<xsl:value-of select="translate(@name,'$','_')"/>
		</xsl:for-each>
		<xsl:text>&gt;</xsl:text> -->
	</xsl:template>
	<xsl:template name="RenderVisibility">
		<!-- don't render visilbility yet - bcc 080228
		<xsl:param name="Visibility" select="string(@visibility)"/>
		<xsl:if test="string-length($Visibility)">
			<!- Note that private implementation members will not have a visibility set ->
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
					<!- C# won't do the and protected, but enforce internal ->
					<xsl:text>internal </xsl:text>
				</xsl:when>
				<!- deferToPartial and privateInterfaceMember are not rendered ->
			</xsl:choose>
		</xsl:if> -->
	</xsl:template>
	<!-- not suported - bcc 080327 -->
	<xsl:template name="RenderVolatile">
		<xsl:param name="Volatile" select="@volatile"/>
		<xsl:if test="$Volatile='true' or $Volatile='1'">
			<xsl:text>NOT SUPPORTED volatile </xsl:text>
		</xsl:if>
	</xsl:template>

	<!-- none of the TestNoBlockExit is needed - python does not require break in case like C# - bcc 080227 -->
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

	<!-- the following are used to prepare doctests for inclusion into generated code - bcc 080305 -->
	<xsl:variable name="eol">
		<xsl:text>
</xsl:text>
	</xsl:variable>
	<xsl:template name="DeSpace">
		<xsl:param name="text" select="''" />
		<xsl:variable name="before" select="substring-before($text,$eol)" />
		<xsl:variable name="after" select="substring-after($text,$eol)" />
		<xsl:call-template name="UnIndent">
			<xsl:with-param name="text" select="$before" />
		</xsl:call-template>
		<xsl:value-of select="$eol" />
		<xsl:if test="$after">
			<xsl:call-template name="DeSpace">
				<xsl:with-param name="text" select="$after" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="UnIndent">
		<xsl:param name="text" select="''" />
		<xsl:variable name="before" select="substring($text,1,1)" />
		<xsl:variable name="after" select="substring($text,2)" />
		<xsl:choose>
			<xsl:when test="$before=' '">
				<xsl:call-template name="UnIndent">
					<xsl:with-param name="text" select="$after" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>