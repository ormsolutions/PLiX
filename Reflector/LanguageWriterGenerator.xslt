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
	xmlns:lw="urn:LanguageWriter"
	xmlns:exsl="http://exslt.org/common"
	extension-element-prefixes="exsl">
	<!--<xsl:output method="xml" indent="yes"/>-->
	<xsl:param name="CustomToolNamespace" select="'TestNamespace'"/>
	<xsl:param name="ParentClassName" select="'PLiXLanguage'"/>
	<xsl:param name="ClassName" select="'PLiXLanguageWriter'"/>
	<xsl:variable name="AttributeValueDecorator" select="'AttributeValue'"/>
	<xsl:variable name="CollectionItemDecorator" select="'Item'"/>
	<xsl:variable name="ChildDecorator" select="'Child'"/>
	<xsl:variable name="DelayEndElementChildDecorator" select="'DelayEndChildElement'"/>
	<xsl:template match="lw:root">
		<plx:root>
			<plx:namespaceImport name="System"/>
			<plx:namespaceImport name="System.Collections.Generic"/>
			<plx:namespaceImport name="Reflector.CodeModel"/>
			<plx:namespaceImport name="System.Xml"/>
			<plx:namespace name="{$CustomToolNamespace}">
				<xsl:if test="lw:Copyright">
					<plx:leadingInfo>
						<plx:comment blankLine="true"/>
						<plx:comment>
							<xsl:value-of select="lw:Copyright/@name"/>
						</plx:comment>
						<xsl:for-each select="lw:Copyright/lw:CopyrightLine">
							<plx:comment>
								<xsl:value-of select="."/>
							</plx:comment>
						</xsl:for-each>
						<plx:comment blankLine="true"/>
					</plx:leadingInfo>
				</xsl:if>
				<plx:class name="{$ParentClassName}" visibility="public" partial="true">
					<plx:class name="{$ClassName}" visibility="private" partial="true">
						<xsl:apply-templates select="*">
							<xsl:with-param name="DocumentRoot" select="."/>
						</xsl:apply-templates>
					</plx:class>
				</plx:class>
			</plx:namespace>
		</plx:root>
	</xsl:template>
	<xsl:template match="lw:Copyright"/>
	<xsl:template match="lw:handler">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:handler" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:variable name="elementName" select="string(@elementName)"/>
		<xsl:variable name="delayEndElement" select="@delayEndElement='true'"/>
		<xsl:variable name="delayDeferElement" select="$delayEndElement and not($elementName)"/>
		<plx:function name="{@name}" visibility="private">
			<plx:param name="value" dataTypeName="{@valueDataType}"/>
			<xsl:if test="$delayEndElement">
				<plx:param name="delayEndElement" dataTypeName=".boolean"/>
			</xsl:if>
			<xsl:copy-of select="plx:param"/>
			<xsl:if test="$delayEndElement">
				<plx:returns dataTypeName=".boolean"/>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$elementName">
					<plx:local name="elementName" dataTypeName=".string">
						<plx:initialize>
							<plx:string data="{$elementName}"/>
						</plx:initialize>
					</plx:local>
					<xsl:variable name="customElementNames" select="lw:customElementName"/>
					<xsl:if test="$customElementNames">
						<xsl:for-each select="$customElementNames">
							<xsl:variable name="customElementName" select="string(@elementName)"/>
							<xsl:if test="position()=1">
								<xsl:apply-templates select="preceding-sibling::*">
									<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
								</xsl:apply-templates>
							</xsl:if>
							<xsl:choose>
								<xsl:when test="$customElementName">
									<xsl:variable name="branchTagFragment">
										<xsl:choose>
											<xsl:when test="position()=1">
												<xsl:text>branch</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text>alternateBranch</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:element name="plx:{$branchTagFragment}">
										<plx:condition>
											<xsl:apply-templates select="*">
												<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
											</xsl:apply-templates>
										</plx:condition>
										<plx:assign>
											<plx:left>
												<plx:nameRef name="elementName"/>
											</plx:left>
											<plx:right>
												<plx:string data="{$customElementName}"/>
											</plx:right>
										</plx:assign>
									</xsl:element>
								</xsl:when>
								<xsl:otherwise>
									<!-- Custom code -->
									<xsl:apply-templates select="*">
										<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
									</xsl:apply-templates>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:if>
					<plx:callThis name="WriteElement">
						<xsl:if test="@allowEmptyElement='false'">
							<xsl:attribute name="name">
								<xsl:text>WriteElementDelayed</xsl:text>
							</xsl:attribute>
						</xsl:if>
						<plx:passParam>
							<plx:nameRef name="elementName"/>
						</plx:passParam>
					</plx:callThis>
					<xsl:choose>
						<xsl:when test="$customElementNames">
							<xsl:apply-templates select="$customElementNames[last()]/following-sibling::*">
								<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
							</xsl:apply-templates>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="*">
								<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
							</xsl:apply-templates>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="$delayEndElement">
							<plx:branch>
								<plx:condition>
									<plx:nameRef name="delayEndElement" type="parameter"/>
								</plx:condition>
								<plx:return>
									<plx:trueKeyword/>
								</plx:return>
							</plx:branch>
							<plx:fallbackBranch>
								<plx:callThis name="WriteEndElement"/>
								<plx:return>
									<plx:falseKeyword/>
								</plx:return>
							</plx:fallbackBranch>
						</xsl:when>
						<xsl:otherwise>
							<plx:callThis name="WriteEndElement"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="$delayDeferElement">
						<plx:local name="retVal" dataTypeName=".boolean">
							<plx:initialize>
								<plx:falseKeyword/>
							</plx:initialize>
						</plx:local>
					</xsl:if>
					<xsl:apply-templates select="*">
						<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
					</xsl:apply-templates>
					<xsl:if test="$delayDeferElement">
						<plx:return>
							<plx:nameRef name="retVal"/>
						</plx:return>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</plx:function>
	</xsl:template>
	<xsl:template match="lw:handler/plx:param">
		<!-- Handled directly by lw:handler -->
	</xsl:template>
	<xsl:template match="lw:elementNameSwitchMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:elementNameSwitchMap" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<plx:switch>
			<plx:condition>
				<xsl:choose>
					<xsl:when test="string(@valueProperty)">
						<plx:callInstance name="{@valueProperty}" type="property">
							<plx:callObject>
								<plx:nameRef name="value" type="parameter"/>
							</plx:callObject>
						</plx:callInstance>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="{@localName}"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:condition>
			<xsl:apply-templates select="*">
				<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			</xsl:apply-templates>
		</plx:switch>
	</xsl:template>
	<xsl:template match="lw:elementNameCaseMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:elementNameCaseMap" mode="ResolvedContext">
		<plx:case>
			<plx:condition>
				<plx:callStatic dataTypeName="{../@valueDataType}" name="{@value}" type="field"/>
			</plx:condition>
			<plx:assign>
				<plx:left>
					<plx:nameRef name="elementName"/>
				</plx:left>
				<plx:right>
					<plx:string data="{@elementName}"/>
				</plx:right>
			</plx:assign>
		</plx:case>
	</xsl:template>
	<xsl:template match="lw:attributeSwitchMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:attributeSwitchMap" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="DynamicAttributeInitialize"/>
		<plx:switch>
			<plx:condition>
				<xsl:choose>
					<xsl:when test="string(@valueProperty)">
						<plx:callInstance name="{@valueProperty}" type="property">
							<plx:callObject>
								<plx:nameRef name="value" type="parameter"/>
							</plx:callObject>
						</plx:callInstance>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="{@localName}"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:condition>
			<xsl:apply-templates select="*">
				<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			</xsl:apply-templates>
		</plx:switch>
		<xsl:call-template name="DynamicAttributeRender"/>
	</xsl:template>
	<xsl:template match="lw:attributeCaseMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:attributeCaseMap" mode="ResolvedContext">
		<plx:case>
			<xsl:call-template name="AddAttributeCaseMapCondition">
				<xsl:with-param name="RemainingValues" select="normalize-space(@value)"/>
			</xsl:call-template>
			<xsl:variable name="filterCondition" select="child::*"/>
			<xsl:variable name="assignFragment">
				<plx:assign>
					<plx:left>
						<plx:nameRef name="{../@attributeName}{$AttributeValueDecorator}"/>
					</plx:left>
					<plx:right>
						<plx:string data="{@attributeValue}"/>
					</plx:right>
				</plx:assign>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$filterCondition">
					<plx:branch>
						<plx:condition>
							<xsl:copy-of select="$filterCondition"/>
						</plx:condition>
						<xsl:copy-of select="$assignFragment"/>
					</plx:branch>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$assignFragment"/>
				</xsl:otherwise>
			</xsl:choose>
		</plx:case>
	</xsl:template>
	<xsl:template name="AddAttributeCaseMapCondition">
		<xsl:param name="RemainingValues"/>
		<xsl:variable name="remainder" select="substring-after($RemainingValues, ' ')"/>
		<xsl:variable name="currentValueFragment">
			<xsl:choose>
				<xsl:when test="$remainder">
					<xsl:value-of select="substring-before($RemainingValues, ' ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$RemainingValues"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="currentValue" select="string($currentValueFragment)"/>
		<plx:condition>
			<plx:callStatic dataTypeName="{../@valueDataType}" name="{$currentValue}" type="field"/>
		</plx:condition>
		<xsl:if test="$remainder">
			<xsl:call-template name="AddAttributeCaseMapCondition">
				<xsl:with-param name="RemainingValues" select="$remainder"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template match="lw:attributeConditionalMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:attributeConditionalMap" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="DynamicAttributeInitialize"/>
		<xsl:apply-templates select="*">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:apply-templates>
		<xsl:call-template name="DynamicAttributeRender"/>
	</xsl:template>
	<xsl:template match="lw:conditionMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:conditionMap" mode="ResolvedContext">
		<xsl:param name="CurrentPosition"/>
		<xsl:variable name="branchTagFragment">
			<xsl:choose>
				<xsl:when test="$CurrentPosition=1">
					<xsl:text>branch</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>alternateBranch</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="plx:{$branchTagFragment}">
			<plx:condition>
				<xsl:copy-of select="*"/>
			</plx:condition>
			<plx:assign>
				<plx:left>
					<plx:nameRef name="{../@attributeName}{$AttributeValueDecorator}"/>
				</plx:left>
				<plx:right>
					<plx:string data="{@attributeValue}"/>
				</plx:right>
			</plx:assign>
		</xsl:element>
	</xsl:template>
	<xsl:template match="lw:local">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:local" mode="ResolvedContext">
		<plx:local name="{@name}" dataTypeName="{@type}">
			<plx:initialize>
				<xsl:variable name="propertyFragment">
					<xsl:choose>
						<xsl:when test="string(@property)">
							<xsl:call-template name="BuildPropertyChain">
								<xsl:with-param name="RemainingProperties" select="normalize-space(translate(@property,'.',' '))"/>
								<xsl:with-param name="CallObject">
									<xsl:choose>
										<xsl:when test="string(@propertyOf)">
											<plx:nameRef name="{@propertyOf}"/>
										</xsl:when>
										<xsl:otherwise>
											<plx:nameRef name="value" type="parameter"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="string(@propertyOf)">
							<plx:nameRef name="{@propertyOf}"/>
						</xsl:when>
						<xsl:otherwise>
							<plx:nameRef name="value" type="parameter"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="@testCast='true'">
						<plx:cast dataTypeName="{@type}" type="testCast">
							<xsl:copy-of select="$propertyFragment"/>
						</plx:cast>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$propertyFragment"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:initialize>
		</plx:local>
	</xsl:template>
	<xsl:template name="BuildPropertyChain">
		<xsl:param name="RemainingProperties"/>
		<xsl:param name="CallObject"/>
		<xsl:variable name="remainder" select="substring-after($RemainingProperties, ' ')"/>
		<xsl:variable name="currentPropertyFragment">
			<xsl:choose>
				<xsl:when test="$remainder">
					<xsl:value-of select="substring-before($RemainingProperties, ' ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$RemainingProperties"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="currentProperty" select="string($currentPropertyFragment)"/>
		<xsl:choose>
			<xsl:when test="$remainder">
				<xsl:call-template name="BuildPropertyChain">
					<xsl:with-param name="RemainingProperties" select="$remainder"/>
					<xsl:with-param name="CallObject">
						<plx:callInstance name="{$currentProperty}" type="property">
							<plx:callObject>
								<xsl:copy-of select="$CallObject"/>
							</plx:callObject>
						</plx:callInstance>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<plx:callInstance name="{$currentProperty}" type="property">
					<plx:callObject>
						<xsl:copy-of select="$CallObject"/>
					</plx:callObject>
				</plx:callInstance>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="DynamicAttributeInitialize">
		<xsl:param name="AttributeName" select="@attributeName"/>
		<plx:local name="{$AttributeName}{$AttributeValueDecorator}" dataTypeName=".string">
			<plx:initialize>
				<plx:string/>
			</plx:initialize>
		</plx:local>
	</xsl:template>
	<xsl:template name="DynamicAttributeRender">
		<xsl:param name="AttributeName" select="@attributeName"/>
		<plx:branch>
			<plx:condition>
				<plx:binaryOperator type="inequality">
					<plx:left>
						<plx:callInstance name="Length" type="property">
							<plx:callObject>
								<plx:nameRef name="{$AttributeName}{$AttributeValueDecorator}"/>
							</plx:callObject>
						</plx:callInstance>
					</plx:left>
					<plx:right>
						<plx:value data="0" type="i4"/>
					</plx:right>
				</plx:binaryOperator>
			</plx:condition>
			<plx:callThis name="WriteAttribute">
				<plx:passParam>
					<plx:string data="{$AttributeName}"/>
				</plx:passParam>
				<plx:passParam>
					<plx:nameRef name="{$AttributeName}{$AttributeValueDecorator}"/>
				</plx:passParam>
			</plx:callThis>
		</plx:branch>
	</xsl:template>
	<xsl:template match="lw:typeHandlerMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="ValueVariableName"/>
		<xsl:variable name="resolvedFragment">
			<xsl:call-template name="ResolveContextAttributes">
				<xsl:with-param name="ReturnControl" select="true()"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="resolved" select="exsl:node-set($resolvedFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="$resolved">
				<xsl:apply-templates select="$resolved[2]" mode="ResolvedContext">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
					<xsl:with-param name="ValueVariableName" select="$ValueVariableName"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="ResolvedContext">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
					<xsl:with-param name="ValueVariableName" select="$ValueVariableName"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:typeHandlerMap" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="ValueVariableName" select="string(@testVariable)"/>
		<xsl:variable name="nameRefExpressionFragment">
			<plx:nameRef name="value">
				<xsl:choose>
					<xsl:when test="$ValueVariableName">
						<xsl:attribute name="name">
							<xsl:value-of select="$ValueVariableName"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="type">
							<xsl:text>parameter</xsl:text>
						</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</plx:nameRef>
		</xsl:variable>
		<xsl:apply-templates select="*">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			<xsl:with-param name="ValueExpression" select="exsl:node-set($nameRefExpressionFragment)/child::*"/>
			<xsl:with-param name="ValueName" select="$ValueVariableName"/>
			<xsl:with-param name="ParentDelayEndElement" select="../@delayEndElement='true'"/>
			<xsl:with-param name="ParentElementName" select="string(../@elementName)"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="lw:typeHandler">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="ValueExpression"/>
		<xsl:param name="ValueName"/>
		<xsl:param name="ParentDelayEndElement"/>
		<xsl:param name="ParentElementName"/>
		<xsl:param name="CurrentPosition" select="position()"/>
		<xsl:param name="LastPosition" select="last()"/>
		<xsl:variable name="resolvedFragment">
			<xsl:call-template name="ResolveContextAttributes">
				<xsl:with-param name="ReturnControl" select="true()"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="resolved" select="exsl:node-set($resolvedFragment)/child::*"/>
		<xsl:choose>
			<xsl:when test="$resolved">
				<xsl:apply-templates select="$resolved[2]" mode="ResolvedContext">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
					<xsl:with-param name="CurrentPosition" select="$CurrentPosition"/>
					<xsl:with-param name="LastPosition" select="$LastPosition"/>
					<xsl:with-param name="ValueExpression" select="$ValueExpression"/>
					<xsl:with-param name="ValueName" select="$ValueName"/>
					<xsl:with-param name="ParentDelayEndElement" select="$ParentDelayEndElement"/>
					<xsl:with-param name="ParentElementName" select="$ParentElementName"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="ResolvedContext">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
					<xsl:with-param name="CurrentPosition" select="$CurrentPosition"/>
					<xsl:with-param name="LastPosition" select="$LastPosition"/>
					<xsl:with-param name="ValueExpression" select="$ValueExpression"/>
					<xsl:with-param name="ValueName" select="$ValueName"/>
					<xsl:with-param name="ParentDelayEndElement" select="$ParentDelayEndElement"/>
					<xsl:with-param name="ParentElementName" select="$ParentElementName"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:typeHandler" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="CurrentPosition"/>
		<xsl:param name="LastPosition"/>
		<xsl:param name="ValueExpression"/>
		<xsl:param name="ValueName" select="'value'"/>
		<xsl:param name="ParentDelayEndElement" select="false()"/>
		<xsl:param name="ParentElementName"/>
		<xsl:if test="$CurrentPosition=1">
			<plx:local name="{$ValueName}As{@valueDataType}" dataTypeName="{@valueDataType}">
				<plx:initialize>
					<plx:cast dataTypeName="{@valueDataType}" type="testCast">
						<xsl:copy-of select="$ValueExpression"/>
					</plx:cast>
				</plx:initialize>
			</plx:local>
			<plx:branch>
				<plx:condition>
					<plx:binaryOperator type="identityInequality">
						<plx:left>
							<plx:nameRef name="{$ValueName}As{@valueDataType}"/>
						</plx:left>
						<plx:right>
							<plx:nullKeyword/>
						</plx:right>
					</plx:binaryOperator>
				</plx:condition>
				<xsl:choose>
					<xsl:when test="@delayEndElement">
						<xsl:choose>
							<xsl:when test="$ParentDelayEndElement">
								<plx:assign>
									<plx:left>
										<xsl:choose>
											<xsl:when test="$ParentElementName">
												<plx:nameRef name="delayEndElement" type="parameter"/>
											</xsl:when>
											<xsl:otherwise>
												<plx:nameRef name="retVal"/>
											</xsl:otherwise>
										</xsl:choose>
									</plx:left>
									<plx:right>
										<plx:callThis name="{@handler}">
											<plx:passParam>
												<plx:nameRef name="{$ValueName}As{@valueDataType}"/>
											</plx:passParam>
											<plx:passParam>
												<xsl:choose>
													<xsl:when test="string(@delayedEndElement)">
														<xsl:element name="plx:{@delayedEndElement}Keyword"/>
													</xsl:when>
													<xsl:otherwise>
														<plx:nameRef name="delayEndElement" type="parameter"/>
													</xsl:otherwise>
												</xsl:choose>
											</plx:passParam>
											<xsl:copy-of select="plx:passParam"/>
										</plx:callThis>
									</plx:right>
								</plx:assign>
							</xsl:when>
							<xsl:otherwise>
								<plx:callThis name="{@handler}">
									<plx:passParam>
										<plx:nameRef name="{$ValueName}As{@valueDataType}"/>
									</plx:passParam>
									<plx:passParam>
										<xsl:choose>
											<xsl:when test="string(@delayedEndElement)">
												<xsl:element name="plx:{@delayedEndElement}Keyword"/>
											</xsl:when>
											<xsl:otherwise>
												<plx:falseKeyword/>
											</xsl:otherwise>
										</xsl:choose>
									</plx:passParam>
									<xsl:copy-of select="plx:passParam"/>
								</plx:callThis>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="string(@delayEndElement)">
								<!-- Explicit setting, used the passed in value -->
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<plx:callThis name="{@handler}">
							<plx:passParam>
								<plx:nameRef name="{$ValueName}As{@valueDataType}"/>
							</plx:passParam>
							<xsl:copy-of select="plx:passParam"/>
						</plx:callThis>
					</xsl:otherwise>
				</xsl:choose>
			</plx:branch>
			<xsl:if test="$CurrentPosition!=$LastPosition">
				<plx:fallbackBranch>
					<xsl:apply-templates select="following-sibling::*">
						<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
						<xsl:with-param name="ValueExpression" select="$ValueExpression"/>
						<xsl:with-param name="ValueName" select="$ValueName"/>
						<xsl:with-param name="ParentDelayEndElement" select="$ParentDelayEndElement"/>
						<xsl:with-param name="ParentElementName" select="$ParentElementName"/>
					</xsl:apply-templates>
				</plx:fallbackBranch>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="lw:attribute">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:attribute" mode="ResolvedContext">
		<xsl:variable name="value" select="string(@value)"/>
		<xsl:variable name="valueProperty" select="string(@valueProperty)"/>
		<xsl:variable name="localName" select="string(@localName)"/>
		<xsl:variable name="emphasis" select="string(@emphasis)"/>
		<plx:callThis name="WriteAttribute">
			<plx:passParam>
				<plx:string data="{@name}"/>
			</plx:passParam>
			<plx:passParam>
				<xsl:choose>
					<xsl:when test="$value">
						<plx:string data="{$value}"/>
					</xsl:when>
					<xsl:when test="$valueProperty">
						<plx:callInstance name="{$valueProperty}" type="property">
							<plx:callObject>
								<xsl:choose>
									<xsl:when test="$localName">
										<plx:nameRef name="{$localName}"/>
									</xsl:when>
									<xsl:otherwise>
										<plx:nameRef name="value" type="parameter"/>
									</xsl:otherwise>
								</xsl:choose>
							</plx:callObject>
						</plx:callInstance>
					</xsl:when>
					<xsl:when test="$localName">
						<plx:nameRef name="{$localName}"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="plx:*[not(self::plx:passParam)]"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:passParam>
			<xsl:if test="$emphasis">
				<xsl:choose>
					<xsl:when test="$emphasis='declaration'">
						<plx:passParam>
							<plx:trueKeyword/>
						</plx:passParam>
						<plx:passParam>
							<plx:falseKeyword/>
						</plx:passParam>
					</xsl:when>
					<xsl:when test="$emphasis='literal'">
						<plx:passParam>
							<plx:falseKeyword/>
						</plx:passParam>
						<plx:passParam>
							<plx:trueKeyword/>
						</plx:passParam>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
			<xsl:copy-of select="plx:passParam"/>
		</plx:callThis>
	</xsl:template>
	<xsl:template match="lw:element">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:element" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<plx:callThis name="WriteElement">
			<xsl:if test="@allowEmptyElement='false'">
				<xsl:attribute name="name">
					<xsl:text>WriteElementDelayed</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<plx:passParam>
				<plx:string data="{@name}"/>
			</plx:passParam>
		</plx:callThis>
		<xsl:apply-templates select="*">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:apply-templates>
		<plx:callThis name="WriteEndElement"/>
	</xsl:template>
	<xsl:template match="lw:commonConstruct[@name]"/>
	<xsl:template match="lw:commonConstruct[@name]" mode="ResolvedCommonConstruct">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="ReferenceContext"/>
		<xsl:choose>
			<xsl:when test="$ReferenceContext">
				<!-- Create a fragment with a referenceContext element and the current element. This lets us reference
				     elements from the calling context using the lw:contextAttribute construct -->
				<xsl:variable name="referenceContextFragment">
					<xsl:copy-of select="$ReferenceContext"/>
					<xsl:copy-of select="."/>
				</xsl:variable>
				<xsl:apply-templates select="exsl:node-set($referenceContextFragment)/child::*[2]/child::*">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="*">
					<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:commonConstruct[@ref]">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:commonConstruct[@ref]" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:variable name="existingContext" select="/lw:referenceContext"/>
		<xsl:variable name="nonRefAttributes" select="@*[local-name()!='ref']"/>
		<xsl:variable name="resolvedConstruct" select="$DocumentRoot/lw:commonConstruct[@name=current()/@ref]"/>
		<xsl:variable name="mergeAttributesFragment">
			<lw:referenceContext>
				<xsl:copy-of select="$existingContext/@*"/>
				<xsl:copy-of select="$nonRefAttributes"/>
			</lw:referenceContext>
		</xsl:variable>
		<xsl:apply-templates select="$resolvedConstruct" mode="ResolvedCommonConstruct">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			<xsl:with-param name="ReferenceContext" select="exsl:node-set($mergeAttributesFragment)/child::*"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="lw:contextAttribute">
		<xsl:value-of select="/lw:referenceContext/@*[local-name()=current()/@name]"/>
	</xsl:template>
	<xsl:template name="ResolveContextAttributes">
		<xsl:param name="DocumentRoot"/>
		<xsl:param name="CurrentPosition" select="position()"/>
		<xsl:param name="LastPosition" select="last()"/>
		<!-- If ReturnControl is true and the parameters are modified, then the
		     modified contents are returned instead of being processed. If ReturnControl
				 is false (the default), then DocumentRoot is forwarded to the current context
				 with the ResolvedContext mode. The node to process is the second node in
				 the returned fragment -->
		<xsl:param name="ReturnControl" select="false()"/>
		<xsl:variable name="context" select="/lw:referenceContext"/>
		<xsl:choose>
			<xsl:when test="$context">
				<xsl:variable name="modifiedAttributesFragment">
					<lw:dummy>
						<xsl:for-each select="@*">
							<xsl:if test="substring(.,1,1)='?'">
								<xsl:variable name="contextAttribute" select="$context/@*[local-name()=substring(current(),2)]"/>
								<xsl:attribute name="{local-name()}">
									<xsl:if test="$contextAttribute">
										<xsl:value-of select="$contextAttribute"/>
									</xsl:if>
								</xsl:attribute>
							</xsl:if>
						</xsl:for-each>
					</lw:dummy>
				</xsl:variable>
				<xsl:variable name="modifiedAttributes" select="exsl:node-set($modifiedAttributesFragment)/child::*/@*"/>
				<xsl:choose>
					<xsl:when test="$modifiedAttributes">
						<xsl:choose>
							<xsl:when test="$ReturnControl">
								<xsl:copy-of select="$context"/>
								<xsl:copy>
									<xsl:copy-of select="@*"/>
									<xsl:copy-of select="$modifiedAttributes"/>
									<xsl:copy-of select="node()"/>
								</xsl:copy>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="newElementFragment">
									<xsl:copy-of select="$context"/>
									<xsl:copy>
										<xsl:copy-of select="@*"/>
										<xsl:copy-of select="$modifiedAttributes"/>
										<xsl:copy-of select="node()"/>
									</xsl:copy>
								</xsl:variable>
								<xsl:apply-templates select="exsl:node-set($newElementFragment)/child::*[2]" mode="ResolvedContext">
									<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
									<xsl:with-param name="CurrentPosition" select="$CurrentPosition"/>
									<xsl:with-param name="LastPosition" select="$LastPosition"/>
								</xsl:apply-templates>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="not($ReturnControl)">
							<xsl:apply-templates select="." mode="ResolvedContext">
								<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
								<xsl:with-param name="CurrentPosition" select="$CurrentPosition"/>
								<xsl:with-param name="LastPosition" select="$LastPosition"/>
							</xsl:apply-templates>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not($ReturnControl)">
					<xsl:apply-templates select="." mode="ResolvedContext">
						<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
						<xsl:with-param name="CurrentPosition" select="$CurrentPosition"/>
						<xsl:with-param name="LastPosition" select="$LastPosition"/>
					</xsl:apply-templates>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:typeReference">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:typeReference" mode="ResolvedContext">
		<xsl:param name="TypeForExpression">
			<xsl:copy-of select="child::*"/>
		</xsl:param>
		<xsl:param name="ElementName" select="@elementName"/>
		<xsl:param name="RenderObject" select="not(@renderObject='false')"/>
		<xsl:param name="RenderVoid" select="not(@renderVoid='false')"/>
		<plx:branch>
			<plx:condition>
				<xsl:choose>
					<xsl:when test="$RenderObject and $RenderVoid">
						<plx:binaryOperator type="identityInequality">
							<plx:left>
								<xsl:copy-of select="$TypeForExpression"/>
							</plx:left>
							<plx:right>
								<plx:nullKeyword/>
							</plx:right>
						</plx:binaryOperator>
					</xsl:when>
					<xsl:when test="@resolvedType='true'">
						<plx:binaryOperator type="booleanAnd">
							<plx:left>
								<plx:binaryOperator type="identityInequality">
									<plx:left>
										<xsl:copy-of select="$TypeForExpression"/>
									</plx:left>
									<plx:right>
										<plx:nullKeyword/>
									</plx:right>
								</plx:binaryOperator>
							</plx:left>
							<plx:right>
								<plx:binaryOperator type="booleanOr">
									<plx:left>
										<plx:binaryOperator type="inequality">
											<plx:left>
												<plx:callInstance name="Namespace" type="property">
													<plx:callObject>
														<xsl:copy-of select="$TypeForExpression"/>
													</plx:callObject>
												</plx:callInstance>
											</plx:left>
											<plx:right>
												<plx:string>System</plx:string>
											</plx:right>
										</plx:binaryOperator>
									</plx:left>
									<plx:right>
										<plx:binaryOperator type="inequality">
											<plx:left>
												<plx:callInstance name="Name" type="property">
													<plx:callObject>
														<xsl:copy-of select="$TypeForExpression"/>
													</plx:callObject>
												</plx:callInstance>
											</plx:left>
											<plx:right>
												<xsl:choose>
													<xsl:when test="$RenderVoid">
														<plx:string>Object</plx:string>
													</xsl:when>
													<xsl:otherwise>
														<plx:string>Void</plx:string>
													</xsl:otherwise>
												</xsl:choose>
											</plx:right>
										</plx:binaryOperator>
									</plx:right>
								</plx:binaryOperator>
							</plx:right>
						</plx:binaryOperator>
					</xsl:when>
					<xsl:otherwise>
						<plx:binaryOperator type="booleanAnd">
							<plx:left>
								<plx:binaryOperator type="identityInequality">
									<plx:left>
										<xsl:copy-of select="$TypeForExpression"/>
									</plx:left>
									<plx:right>
										<plx:nullKeyword/>
									</plx:right>
								</plx:binaryOperator>
							</plx:left>
							<plx:right>
								<plx:unaryOperator type="booleanNot">
									<plx:callThis name="IsVoidType" accessor="static">
										<xsl:if test="$RenderVoid">
											<xsl:attribute name="name">
												<xsl:text>IsObjectType</xsl:text>
											</xsl:attribute>
										</xsl:if>
										<plx:passParam>
											<xsl:copy-of select="$TypeForExpression"/>
										</plx:passParam>
									</plx:callThis>
								</plx:unaryOperator>
							</plx:right>
						</plx:binaryOperator>
					</xsl:otherwise>
				</xsl:choose>
			</plx:condition>
			<xsl:if test="$ElementName">
				<plx:callThis name="WriteElement">
					<xsl:if test="@allowEmptyElement='false'">
						<xsl:attribute name="name">
							<xsl:text>WriteElementDelayed</xsl:text>
						</xsl:attribute>
					</xsl:if>
					<plx:passParam>
						<plx:string data="{$ElementName}"/>
					</plx:passParam>
				</plx:callThis>
			</xsl:if>
			<plx:callThis name="RenderType">
				<xsl:if test="@resolvedType='true'">
					<xsl:attribute name="name">
						<xsl:choose>
							<xsl:when test="@resolvedTypeWithoutGenerics='true'">
								<xsl:text>RenderTypeReferenceWithoutGenerics</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>RenderTypeReference</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</xsl:if>
				<plx:passParam>
					<xsl:copy-of select="$TypeForExpression"/>
				</plx:passParam>
			</plx:callThis>
			<xsl:if test="$ElementName">
				<plx:callThis name="WriteEndElement"/>
			</xsl:if>
		</plx:branch>
	</xsl:template>
	<xsl:template match="lw:collection">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:collection" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:variable name="delayWrite" select="@allowEmptyElement='false'"/>
		<xsl:variable name="itemLocalName" select="concat(@localName,@collectionProperty,$CollectionItemDecorator)"/>
		<plx:iterator dataTypeName="{@itemDataType}" localName="{$itemLocalName}">
			<plx:initialize>
				<xsl:choose>
					<xsl:when test="string(@collectionProperty)">
						<plx:callInstance name="{@collectionProperty}" type="property">
							<plx:callObject>
								<xsl:choose>
									<xsl:when test="string(@localName)">
										<plx:nameRef name="{@localName}"/>
									</xsl:when>
									<xsl:otherwise>
										<plx:nameRef name="value" type="parameter"/>
									</xsl:otherwise>
								</xsl:choose>
							</plx:callObject>
						</plx:callInstance>
					</xsl:when>
					<xsl:when test="string(@localName)">
						<plx:nameRef name="{@localName}"/>
					</xsl:when>
					<xsl:otherwise>
						<plx:nameRef name="value" type="parameter"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:initialize>
			<xsl:apply-templates select="*[not(self::plx:passParam)]">
				<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			</xsl:apply-templates>
			<xsl:variable name="elementName" select="string(@elementName)"/>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteElement">
					<xsl:if test="$delayWrite">
						<xsl:attribute name="name">
							<xsl:text>WriteElementDelayed</xsl:text>
						</xsl:attribute>
					</xsl:if>
					<plx:passParam>
						<plx:string data="{$elementName}"/>
					</plx:passParam>
				</plx:callThis>
			</xsl:if>
			<plx:callThis name="{@renderItem}">
				<plx:passParam>
					<plx:nameRef name="{$itemLocalName}"/>
				</plx:passParam>
				<xsl:copy-of select="plx:passParam"/>
			</plx:callThis>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteEndElement"/>
			</xsl:if>
		</plx:iterator>
	</xsl:template>
	<xsl:template match="lw:child">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:child" mode="ResolvedContext">
		<xsl:variable name="localName" select="concat(@childProperty,$ChildDecorator)"/>
		<xsl:variable name="delayEndElement" select="string(@delayEndElement)"/>
		<xsl:variable name="delayEndElementLocalName" select="concat(@childProperty,$DelayEndElementChildDecorator)"/>
		<xsl:if test="$delayEndElement='true'">
			<plx:local name="{$delayEndElementLocalName}" dataTypeName=".boolean">
				<plx:initialize>
					<plx:falseKeyword/>
				</plx:initialize>
			</plx:local>
		</xsl:if>
		<plx:local name="{$localName}" dataTypeName="{@childDataType}">
			<plx:initialize>
				<xsl:variable name="callProperty">
					<plx:callInstance name="{@childProperty}" type="property">
						<plx:callObject>
							<xsl:choose>
								<xsl:when test="string(@propertyOf)">
									<plx:nameRef name="{@propertyOf}"/>
								</xsl:when>
								<xsl:otherwise>
									<plx:nameRef name="value" type="parameter"/>
								</xsl:otherwise>
							</xsl:choose>
						</plx:callObject>
					</plx:callInstance>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="@testCast='true'">
						<plx:cast dataTypeName="{@childDataType}" type="testCast">
							<xsl:copy-of select="$callProperty"/>
						</plx:cast>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$callProperty"/>
					</xsl:otherwise>
				</xsl:choose>
			</plx:initialize>
		</plx:local>
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
			<xsl:variable name="elementName" select="string(@elementName)"/>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteElement">
					<xsl:if test="@allowEmptyElement='false'">
						<xsl:attribute name="name">
							<xsl:text>WriteElementDelayed</xsl:text>
						</xsl:attribute>
					</xsl:if>
					<plx:passParam>
						<plx:string data="{$elementName}"/>
					</plx:passParam>
				</plx:callThis>
			</xsl:if>
			<xsl:variable name="renderChildFragment">
				<plx:callThis name="{@renderChild}">
					<plx:passParam>
						<plx:nameRef name="{$localName}"/>
					</plx:passParam>
					<xsl:if test="string(@delayEndElement)">
						<plx:passParam>
							<xsl:element name="plx:{@delayEndElement}Keyword"/>
						</plx:passParam>
					</xsl:if>
					<xsl:copy-of select="plx:passParam"/>
				</plx:callThis>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$delayEndElement='true'">
					<plx:assign>
						<plx:left>
							<plx:nameRef name="{$delayEndElementLocalName}"/>
						</plx:left>
						<plx:right>
							<xsl:copy-of select="$renderChildFragment"/>
						</plx:right>
					</plx:assign>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$renderChildFragment"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteEndElement"/>
			</xsl:if>
		</plx:branch>
	</xsl:template>
	<xsl:template match="lw:defer">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:defer" mode="ResolvedContext">
		<xsl:variable name="localName" select="string(@localName)"/>
		<xsl:variable name="deferRender" select="@deferRender"/>
		<xsl:variable name="delayEndElement" select="string(@delayEndElement)"/>
		<xsl:variable name="delayEndElementLocalNameFragment">
			<xsl:choose>
				<xsl:when test="not($delayEndElement)"/>
				<xsl:when test="$localName">
					<xsl:value-of select="concat($localName,$DelayEndElementChildDecorator)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="valueDefers" select="ancestor::lw:handler[1]/lw:defer[not(string(@localName))]"/>
					<xsl:choose>
						<xsl:when test="count($valueDefers)=1">
							<xsl:value-of select="concat('value',$DelayEndElementChildDecorator)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('value',$DelayEndElementChildDecorator,'For',$deferRender)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="delayEndElementLocalName" select="string($delayEndElementLocalNameFragment)"/>
		<xsl:if test="$delayEndElement='true'">
			<plx:local name="{$delayEndElementLocalName}" dataTypeName=".boolean">
				<plx:initialize>
					<plx:falseKeyword/>
				</plx:initialize>
			</plx:local>
		</xsl:if>
		<xsl:variable name="renderFragment">
			<xsl:variable name="elementName" select="string(@elementName)"/>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteElement">
					<xsl:if test="@allowEmptyElement='false'">
						<xsl:attribute name="name">
							<xsl:text>WriteElementDelayed</xsl:text>
						</xsl:attribute>
					</xsl:if>
					<plx:passParam>
						<plx:string data="{$elementName}"/>
					</plx:passParam>
				</plx:callThis>
			</xsl:if>
			<xsl:variable name="renderChildFragment">
				<plx:callThis name="{$deferRender}">
					<plx:passParam>
						<xsl:choose>
							<xsl:when test="$localName">
								<plx:nameRef name="{$localName}"/>
							</xsl:when>
							<xsl:otherwise>
								<plx:nameRef name="value" type="parameter"/>
							</xsl:otherwise>
						</xsl:choose>
					</plx:passParam>
					<xsl:if test="string(@delayEndElement)">
						<plx:passParam>
							<xsl:element name="plx:{@delayEndElement}Keyword"/>
						</plx:passParam>
					</xsl:if>
					<xsl:copy-of select="plx:passParam"/>
				</plx:callThis>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$delayEndElement='true'">
					<plx:assign>
						<plx:left>
							<plx:nameRef name="{$delayEndElementLocalName}"/>
						</plx:left>
						<plx:right>
							<xsl:copy-of select="$renderChildFragment"/>
						</plx:right>
					</plx:assign>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$renderChildFragment"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$elementName">
				<plx:callThis name="WriteEndElement"/>
			</xsl:if>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$localName">
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
					<xsl:copy-of select="$renderFragment"/>
				</plx:branch>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$renderFragment"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:deferExpressionType">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:deferExpressionType" mode="ResolvedContext">
		<plx:callThis name="RenderExpressionType">
			<plx:passParam>
				<xsl:call-template name="BuildExpressionTypeNullFallbacks">
					<xsl:with-param name="RemainingLocals" select="normalize-space(@localNames)"/>
				</xsl:call-template>
			</plx:passParam>
		</plx:callThis>
	</xsl:template>
	<xsl:template name="BuildExpressionTypeNullFallbacks">
		<xsl:param name="RemainingLocals"/>
		<xsl:variable name="remainder" select="substring-after($RemainingLocals, ' ')"/>
		<xsl:variable name="currentLocalFragment">
			<xsl:choose>
				<xsl:when test="$remainder">
					<xsl:value-of select="substring-before($RemainingLocals, ' ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$RemainingLocals"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="currentLocal" select="string($currentLocalFragment)"/>
		<xsl:variable name="testNullify">
			<plx:callThis name="TestNullifyExpression" accessor="static">
				<plx:passParam>
					<plx:nameRef name="{$currentLocal}"/>
				</plx:passParam>
			</plx:callThis>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$remainder">
				<plx:inlineStatement dataTypeName="IExpression">
					<plx:nullFallbackOperator>
						<plx:left>
							<xsl:copy-of select="$testNullify"/>
						</plx:left>
						<plx:right>
							<xsl:call-template name="BuildExpressionTypeNullFallbacks">
								<xsl:with-param name="RemainingLocals" select="$remainder"/>
							</xsl:call-template>
						</plx:right>
					</plx:nullFallbackOperator>
				</plx:inlineStatement>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$testNullify"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lw:literalValueMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:literalValueMap" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:variable name="getValue" select="not(@typesOnly='true')"/>
		<!-- Translate a literal value (in the literalValue object variable) into
		     xmlValue and valueType variables. Boolean and String types are special cased. -->
		<xsl:variable name="knownTypes" select="$DocumentRoot/lw:knownSystemTypeMap/child::*"/>
		<xsl:if test="$getValue">
			<plx:local name="xmlValue" dataTypeName=".string">
				<plx:initialize>
					<plx:nullKeyword/>
				</plx:initialize>
			</plx:local>
			<plx:local name="isSpecialValue" dataTypeName=".boolean">
				<plx:initialize>
					<plx:falseKeyword/>
				</plx:initialize>
			</plx:local>
		</xsl:if>
		<plx:local name="valueType" dataTypeName=".string">
			<plx:initialize>
				<plx:nullKeyword/>
			</plx:initialize>
		</plx:local>
		<plx:branch>
			<plx:condition>
				<plx:binaryOperator type="identityInequality">
					<plx:left>
						<plx:nameRef name="literalValue"/>
					</plx:left>
					<plx:right>
						<plx:nullKeyword/>
					</plx:right>
				</plx:binaryOperator>
			</plx:condition>
			<plx:switch>
				<plx:condition>
					<plx:callStatic name="GetTypeCode" dataTypeName="Type">
						<plx:passParam>
							<plx:callInstance name="GetType">
								<plx:callObject>
									<plx:nameRef name="literalValue"/>
								</plx:callObject>
							</plx:callInstance>
						</plx:passParam>
					</plx:callStatic>
				</plx:condition>
				<xsl:for-each select="$knownTypes[@systemName!='Object']">
					<plx:case>
						<plx:condition>
							<plx:callStatic name="{@systemName}" dataTypeName="TypeCode" type="field"/>
						</plx:condition>
						<xsl:if test="not($getValue) or not(@systemName='Boolean' or @systemName='String')">
							<plx:assign>
								<plx:left>
									<plx:nameRef name="valueType"/>
								</plx:left>
								<plx:right>
									<xsl:choose>
										<xsl:when test="$getValue">
											<plx:string data="{@name}"/>
										</xsl:when>
										<xsl:otherwise>
											<plx:string data=".{@name}"/>
										</xsl:otherwise>
									</xsl:choose>
								</plx:right>
							</plx:assign>
						</xsl:if>
						<xsl:if test="$getValue">
							<plx:assign>
								<plx:left>
									<plx:nameRef name="xmlValue"/>
								</plx:left>
								<plx:right>
									<xsl:choose>
										<xsl:when test="@systemName='String'">
											<plx:cast dataTypeName=".{@name}">
												<plx:nameRef name="literalValue"/>
											</plx:cast>
										</xsl:when>
										<xsl:otherwise>
											<plx:callStatic name="ToString" dataTypeName="XmlConvert">
												<plx:passParam>
													<plx:cast dataTypeName=".{@name}">
														<plx:nameRef name="literalValue"/>
													</plx:cast>
												</plx:passParam>
												<xsl:if test="@systemName='DateTime'">
													<plx:passParam>
														<plx:callStatic name="Utc" dataTypeName="XmlDateTimeSerializationMode" type="field"/>
													</plx:passParam>
												</xsl:if>
											</plx:callStatic>
										</xsl:otherwise>
									</xsl:choose>
								</plx:right>
							</plx:assign>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="not($getValue)"/>
							<xsl:when test="@systemName='String'">
								<plx:assign>
									<plx:left>
										<plx:nameRef name="elementName"/>
									</plx:left>
									<plx:right>
										<plx:string>string</plx:string>
									</plx:right>
								</plx:assign>
								<plx:assign>
									<plx:left>
										<plx:nameRef name="isSpecialValue"/>
									</plx:left>
									<plx:right>
										<plx:trueKeyword/>
									</plx:right>
								</plx:assign>
							</xsl:when>
							<xsl:when test="@systemName='Boolean'">
								<plx:assign>
									<plx:left>
										<plx:nameRef name="elementName"/>
									</plx:left>
									<plx:right>
										<plx:callStatic name="Concat" dataTypeName=".string">
											<plx:passParam>
												<plx:nameRef name="xmlValue"/>
											</plx:passParam>
											<plx:passParam>
												<plx:string>Keyword</plx:string>
											</plx:passParam>
										</plx:callStatic>
									</plx:right>
								</plx:assign>
								<plx:assign>
									<plx:left>
										<plx:nameRef name="xmlValue"/>
									</plx:left>
									<plx:right>
										<plx:nullKeyword/>
									</plx:right>
								</plx:assign>
								<plx:assign>
									<plx:left>
										<plx:nameRef name="isSpecialValue"/>
									</plx:left>
									<plx:right>
										<plx:trueKeyword/>
									</plx:right>
								</plx:assign>
							</xsl:when>
						</xsl:choose>
						<xsl:if test="@systemName='String'">
						</xsl:if>
					</plx:case>
				</xsl:for-each>
			</plx:switch>
		</plx:branch>
	</xsl:template>
	<xsl:template match="lw:knownSystemTypeMap">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:knownSystemTypeMap" mode="ResolvedContext">
		<plx:function name="MapKnownSystemType" visibility="private" modifier="static">
			<plx:param name="typeReference" dataTypeName="ITypeReference"/>
			<plx:returns dataTypeName=".string"/>
			<plx:local name="retVal" dataTypeName=".string">
				<plx:initialize>
					<plx:nullKeyword/>
				</plx:initialize>
			</plx:local>
			<plx:branch>
				<plx:condition>
					<plx:binaryOperator type="equality">
						<plx:left>
							<plx:callInstance name="Namespace" type="property">
								<plx:callObject>
									<plx:nameRef name="typeReference" type="parameter"/>
								</plx:callObject>
							</plx:callInstance>
						</plx:left>
						<plx:right>
							<plx:string>System</plx:string>
						</plx:right>
					</plx:binaryOperator>
				</plx:condition>
				<plx:local name="typeName" dataTypeName=".string">
					<plx:initialize>
						<plx:callInstance name="Name" type="property">
							<plx:callObject>
								<plx:nameRef name="typeReference" type="parameter"/>
							</plx:callObject>
						</plx:callInstance>
					</plx:initialize>
				</plx:local>
				<xsl:variable name="knownTypesWithLengthFragment">
					<xsl:for-each select="*">
						<xsl:copy>
							<xsl:copy-of select="@*"/>
							<xsl:attribute name="systemNameLength">
								<xsl:value-of select="string-length(@systemName)"/>
							</xsl:attribute>
						</xsl:copy>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="sortedKnownTypesFragment">
					<xsl:for-each select="exsl:node-set($knownTypesWithLengthFragment)/child::*">
						<xsl:sort select="@systemNameLength" data-type="number" order="ascending"/>
						<xsl:sort select="@systemName"/>
						<xsl:copy-of select="."/>
					</xsl:for-each>
				</xsl:variable>
				<plx:switch>
					<plx:condition>
						<plx:callInstance name="Length" type="property">
							<plx:callObject>
								<plx:nameRef name="typeName"/>
							</plx:callObject>
						</plx:callInstance>
					</plx:condition>
					<xsl:for-each select="exsl:node-set($sortedKnownTypesFragment)/child::*">
						<xsl:if test="string(preceding-sibling::*[1]/@systemNameLength)!=string(@systemNameLength)">
							<plx:case>
								<plx:condition>
									<plx:value data="{@systemNameLength}" type="i4"/>
								</plx:condition>
								<xsl:variable name="currentSystemNameLength" select="@systemNameLength"/>
								<plx:branch>
									<plx:condition>
										<plx:binaryOperator type="equality">
											<plx:left>
												<plx:nameRef name="typeName"/>
											</plx:left>
											<plx:right>
												<plx:string data="{@systemName}"/>
											</plx:right>
										</plx:binaryOperator>
									</plx:condition>
									<plx:assign>
										<plx:left>
											<plx:nameRef name="retVal"/>
										</plx:left>
										<plx:right>
											<plx:string data="{@name}"/>
										</plx:right>
									</plx:assign>
								</plx:branch>
								<xsl:for-each select="following-sibling::*[@systemNameLength=current()/@systemNameLength]">
									<plx:alternateBranch>
										<plx:condition>
											<plx:binaryOperator type="equality">
												<plx:left>
													<plx:nameRef name="typeName"/>
												</plx:left>
												<plx:right>
													<plx:string data="{@systemName}"/>
												</plx:right>
											</plx:binaryOperator>
										</plx:condition>
										<plx:assign>
											<plx:left>
												<plx:nameRef name="retVal"/>
											</plx:left>
											<plx:right>
												<plx:string data="{@name}"/>
											</plx:right>
										</plx:assign>
									</plx:alternateBranch>
								</xsl:for-each>
							</plx:case>
						</xsl:if>
					</xsl:for-each>
				</plx:switch>
			</plx:branch>
			<plx:return>
				<plx:nameRef name="retVal"/>
			</plx:return>
		</plx:function>
	</xsl:template>
	<xsl:template match="lw:systemTypeTestFunctions">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="lw:systemTypeTestFunctions" mode="ResolvedContext">
		<xsl:call-template name="GenerateSystemTypeTestFunction">
			<xsl:with-param name="RemainingTypes" select="normalize-space(@types)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="GenerateSystemTypeTestFunction">
		<xsl:param name="RemainingTypes"/>
		<xsl:variable name="remainder" select="substring-after($RemainingTypes, ' ')"/>
		<xsl:variable name="currentTypeFragment">
			<xsl:choose>
				<xsl:when test="$remainder">
					<xsl:value-of select="substring-before($RemainingTypes, ' ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$RemainingTypes"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="currentType" select="string($currentTypeFragment)"/>
		<plx:function name="Is{$currentType}Type" visibility="private" modifier="static">
			<plx:param name="type" dataTypeName="IType"/>
			<plx:returns dataTypeName=".boolean"/>
			<plx:local name="typeReference" dataTypeName="ITypeReference">
				<plx:initialize>
					<plx:cast dataTypeName="ITypeReference" type="testCast">
						<plx:nameRef name="type" type="parameter"/>
					</plx:cast>
				</plx:initialize>
			</plx:local>
			<plx:return>
				<plx:binaryOperator type="booleanAnd">
					<plx:left>
						<plx:binaryOperator type="identityInequality">
							<plx:left>
								<plx:nameRef name="typeReference"/>
							</plx:left>
							<plx:right>
								<plx:nullKeyword/>
							</plx:right>
						</plx:binaryOperator>
					</plx:left>
					<plx:right>
						<plx:binaryOperator type="booleanAnd">
							<plx:left>
								<plx:binaryOperator type="equality">
									<plx:left>
										<plx:callInstance name="Namespace" type="property">
											<plx:callObject>
												<plx:nameRef name="typeReference"/>
											</plx:callObject>
										</plx:callInstance>
									</plx:left>
									<plx:right>
										<plx:string>System</plx:string>
									</plx:right>
								</plx:binaryOperator>
							</plx:left>
							<plx:right>
								<plx:binaryOperator type="equality">
									<plx:left>
										<plx:callInstance name="Name" type="property">
											<plx:callObject>
												<plx:nameRef name="typeReference"/>
											</plx:callObject>
										</plx:callInstance>
									</plx:left>
									<plx:right>
										<plx:string data="{$currentType}"/>
									</plx:right>
								</plx:binaryOperator>
							</plx:right>
						</plx:binaryOperator>
					</plx:right>
				</plx:binaryOperator>
			</plx:return>
		</plx:function>
		<xsl:if test="$remainder">
			<xsl:call-template name="GenerateSystemTypeTestFunction">
				<xsl:with-param name="RemainingTypes" select="$remainder"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- Allow for inline code at any point -->
	<xsl:template match="plx:*">
		<xsl:param name="DocumentRoot"/>
		<xsl:call-template name="ResolveContextAttributes">
			<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="plx:*" mode="ResolvedContext">
		<xsl:param name="DocumentRoot"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="node()">
				<xsl:with-param name="DocumentRoot" select="$DocumentRoot"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<!-- Throw if an element is added we don't recognize -->
	<xsl:template match="*">
		<xsl:message terminate="yes">
			<xsl:text>Unrecognized element '</xsl:text>
			<xsl:value-of select="local-name()"/>
			<xsl:text>'</xsl:text>
		</xsl:message>
	</xsl:template>
</xsl:stylesheet>