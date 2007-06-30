using System;
using System.Collections.Generic;
using Reflector.CodeModel;
using System.Xml;

// Common Public License Copyright Notice
// /**************************************************************************\
// * Neumont PLiX (Programming Language in XML) Code Generator                *
// *                                                                          *
// * Copyright © Neumont University and Matthew Curland. All rights reserved. *
// *                                                                          *
// * The use and distribution terms for this software are covered by the      *
// * Common Public License 1.0 (http://opensource.org/licenses/cpl) which     *
// * can be found in the file CPL.txt at the root of this distribution.       *
// * By using this software in any fashion, you are agreeing to be bound by   *
// * the terms of this license.                                               *
// *                                                                          *
// * You must not remove this notice, or any other, from this software.       *
// \**************************************************************************/

namespace Reflector
{
	public partial class PLiXLanguage
	{
		private partial class PLiXLanguageWriter
		{
			private void Render(ITypeDeclaration value, bool renderBody, bool translateMethods)
			{
				string elementName = "class";
				ITypeReference baseType = value.BaseType;
				bool isInterface = value.Interface;
				if (isInterface)
				{
					elementName = "interface";
				}
				else if ((baseType != null) && (baseType.Namespace == "System"))
				{
					string baseTypeName = baseType.Name;
					if (baseTypeName == "Enum")
					{
						elementName = "enum";
					}
					else if (baseTypeName == "ValueType")
					{
						elementName = "structure";
					}
					else if ((baseTypeName == "Delegate") || (baseTypeName == "MulticastDelegate"))
					{
						elementName = "delegate";
					}
				}
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name, true, false);
				string visibilityAttributeValue = "";
				switch (value.Visibility)
				{
					case TypeVisibility.Public:
						visibilityAttributeValue = "public";
						break;
					case TypeVisibility.Private:
						visibilityAttributeValue = "internal";
						break;
					case TypeVisibility.NestedAssembly:
						visibilityAttributeValue = "internal";
						break;
					case TypeVisibility.NestedFamily:
						visibilityAttributeValue = "protected";
						break;
					case TypeVisibility.NestedFamilyAndAssembly:
						visibilityAttributeValue = "protectedAndInternal";
						break;
					case TypeVisibility.NestedFamilyOrAssembly:
						visibilityAttributeValue = "protectedOrInternal";
						break;
					case TypeVisibility.NestedPublic:
						visibilityAttributeValue = "public";
						break;
					case TypeVisibility.NestedPrivate:
						visibilityAttributeValue = "private";
						break;
				}
				if (visibilityAttributeValue.Length != 0)
				{
					this.WriteAttribute("visibility", visibilityAttributeValue);
				}
				if (!(isInterface))
				{
					string modifierAttributeValue = "";
					if (value.Abstract)
					{
						modifierAttributeValue = "abstract";
					}
					else if (value.Sealed && (elementName == "class"))
					{
						modifierAttributeValue = "sealed";
					}
					if (modifierAttributeValue.Length != 0)
					{
						this.WriteAttribute("modifier", modifierAttributeValue);
					}
				}
				if (elementName == "enum")
				{
					this.RenderEnum(value, renderBody);
				}
				else
				{
					ICustomAttributeCollection customAttributes = value.Attributes;
					int defaultMemberAttributeIndex = -1;
					if (customAttributes.Count != 0)
					{
						int attributeIndex = 0;
						foreach (ICustomAttribute testCustomAttribute in customAttributes)
						{
							ITypeReference attributeType = testCustomAttribute.Constructor.DeclaringType as ITypeReference;
							if (attributeType != null)
							{
								if ((attributeType.Name == "DefaultMemberAttribute") && (attributeType.Namespace == "System.Reflection"))
								{
									ILiteralExpression defaultMemberNameLiteral;
									string defaultMemberName;
									object literalValue;
									IExpressionCollection arguments = testCustomAttribute.Arguments;
									if ((((arguments.Count == 1) && ((defaultMemberNameLiteral = arguments[0] as ILiteralExpression) != null)) && (((literalValue = defaultMemberNameLiteral.Value) != null) && (Type.GetTypeCode(literalValue.GetType()) == TypeCode.String))) && (null != (defaultMemberName = (string)literalValue)))
									{
										defaultMemberAttributeIndex = attributeIndex;
										this.WriteAttribute("defaultMember", defaultMemberName, false, true);
									}
									break;
								}
							}
							++attributeIndex;
						}
					}
					this.RenderDocumentation(value);
					int customAttributeIndex = -1;
					foreach (ICustomAttribute customAttributesItem in customAttributes)
					{
						++customAttributeIndex;
						if (customAttributeIndex == defaultMemberAttributeIndex)
						{
							continue;
						}
						this.RenderCustomAttribute(customAttributesItem);
					}
					IGenericArgumentProvider ownerGenericArgumentProvider = value.Owner as IGenericArgumentProvider;
					ITypeCollection ownerGenericArguments = null;
					if (ownerGenericArgumentProvider != null)
					{
						ownerGenericArguments = ownerGenericArgumentProvider.GenericArguments;
						if (ownerGenericArguments.Count == 0)
						{
							ownerGenericArguments = null;
						}
					}
					foreach (IGenericParameter GenericArgumentsItem in value.GenericArguments)
					{
						if ((ownerGenericArguments != null) && ownerGenericArguments.Contains(GenericArgumentsItem))
						{
							continue;
						}
						this.WriteElement("typeParam");
						this.RenderGenericParameterDeclaration(GenericArgumentsItem);
						this.WriteEndElement();
					}
					if (elementName == "delegate")
					{
						foreach (IMethodDeclaration MethodsItem in value.Methods)
						{
							this.RenderDelegateInvokeParameters(MethodsItem);
						}
					}
					else
					{
						if (elementName == "class")
						{
							if ((baseType != null) && ((baseType.Namespace != "System") || (baseType.Name != "Object")))
							{
								this.WriteElement("derivesFromClass");
								this.RenderTypeReference(baseType);
								this.WriteEndElement();
							}
						}
						foreach (ITypeReference InterfacesItem in value.Interfaces)
						{
							this.WriteElement("implementsInterface");
							this.RenderTypeReference(InterfacesItem);
							this.WriteEndElement();
						}
						if (renderBody)
						{
							foreach (IFieldDeclaration FieldsItem in value.Fields)
							{
								if (this.myMemberMap.IsSimpleEventField(FieldsItem))
								{
									continue;
								}
								this.Render(FieldsItem);
							}
							foreach (IPropertyDeclaration PropertiesItem in value.Properties)
							{
								InterfaceMemberInfo interfaceMemberInfo = this.myMemberMap.GetInterfaceMemberInfo(PropertiesItem);
								if (interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation)
								{
									continue;
								}
								this.Render(PropertiesItem, interfaceMemberInfo, translateMethods, isInterface);
							}
							foreach (IEventDeclaration EventsItem in value.Events)
							{
								InterfaceMemberInfo interfaceMemberInfo = this.myMemberMap.GetInterfaceMemberInfo(EventsItem);
								if (interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation)
								{
									continue;
								}
								this.Render(EventsItem, interfaceMemberInfo, translateMethods, isInterface);
							}
							foreach (IMethodDeclaration MethodsItem in value.Methods)
							{
								InterfaceMemberInfo interfaceMemberInfo = this.myMemberMap.GetInterfaceMemberInfo(MethodsItem);
								if ((interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation) || ((MethodsItem.SpecialName && !(MethodsItem.RuntimeSpecialName)) && !(MethodsItem.Static && MethodsItem.Name.StartsWith("op_"))))
								{
									continue;
								}
								this.Render(MethodsItem, interfaceMemberInfo, translateMethods, isInterface);
							}
							foreach (ITypeDeclaration NestedTypesItem in value.NestedTypes)
							{
								this.Render(NestedTypesItem, true, translateMethods);
							}
						}
					}
				}
				this.WriteEndElement();
			}
			private void Render(IFieldDeclaration value)
			{
				string elementName = "field";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name, true, false);
				string visibilityAttributeValue = "";
				switch (value.Visibility)
				{
					case FieldVisibility.Public:
						visibilityAttributeValue = "public";
						break;
					case FieldVisibility.Private:
						visibilityAttributeValue = "private";
						break;
					case FieldVisibility.PrivateScope:
						visibilityAttributeValue = "private";
						break;
					case FieldVisibility.Assembly:
						visibilityAttributeValue = "internal";
						break;
					case FieldVisibility.Family:
						visibilityAttributeValue = "protected";
						break;
					case FieldVisibility.FamilyAndAssembly:
						visibilityAttributeValue = "protectedAndInternal";
						break;
					case FieldVisibility.FamilyOrAssembly:
						visibilityAttributeValue = "protectedOrInternal";
						break;
				}
				if (visibilityAttributeValue.Length != 0)
				{
					this.WriteAttribute("visibility", visibilityAttributeValue);
				}
				string constAttributeValue = "";
				if (value.Literal)
				{
					constAttributeValue = "true";
				}
				if (constAttributeValue.Length != 0)
				{
					this.WriteAttribute("const", constAttributeValue);
				}
				string staticAttributeValue = "";
				if (value.Static && !(value.Literal))
				{
					staticAttributeValue = "true";
				}
				if (staticAttributeValue.Length != 0)
				{
					this.WriteAttribute("static", staticAttributeValue);
				}
				string readOnlyAttributeValue = "";
				if (value.ReadOnly)
				{
					readOnlyAttributeValue = "true";
				}
				if (readOnlyAttributeValue.Length != 0)
				{
					this.WriteAttribute("readOnly", readOnlyAttributeValue);
				}
				if (value.FieldType != null)
				{
					this.RenderType(value.FieldType);
				}
				this.RenderDocumentation(value);
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem);
				}
				IExpression InitializerChild = value.Initializer;
				if (InitializerChild != null)
				{
					this.WriteElement("initialize");
					this.RenderExpression(InitializerChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void Render(IPropertyDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethods)
			{
				ITypeReference declaringType = value.DeclaringType as ITypeReference;
				bool isInterfaceMember = (declaringType != null) && declaringType.Resolve().Interface;
				this.Render(value, interfaceMemberInfo, translateMethods, isInterfaceMember);
			}
			private void Render(IPropertyDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethods, bool isInterfaceMember)
			{
				string elementName = "property";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name, true, false);
				IMethodDeclaration referenceMethod = GetPropertyReferenceMethod(value);
				if (referenceMethod != null)
				{
					this.RenderMethodVisibilityAttribute(referenceMethod);
				}
				if (!(isInterfaceMember))
				{
					if (referenceMethod != null)
					{
						this.RenderMethodModifierAttribute(referenceMethod);
					}
				}
				this.RenderDocumentation(value);
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem);
				}
				if (interfaceMemberInfo.HasInterfaceMembers)
				{
					foreach (IMemberReference InterfaceMemberCollectionItem in interfaceMemberInfo.InterfaceMemberCollection)
					{
						this.RenderInterfaceMember(InterfaceMemberCollectionItem);
					}
				}
				foreach (IParameterDeclaration referenceMethodParametersItem in referenceMethod.Parameters)
				{
					this.WriteElement("param");
					this.RenderParameterDeclaration(referenceMethodParametersItem);
					this.WriteEndElement();
				}
				if (value.PropertyType != null)
				{
					this.WriteElement("returns");
					this.RenderType(value.PropertyType);
					this.WriteEndElement();
				}
				IMethodReference GetMethodChild = value.GetMethod;
				if (GetMethodChild != null)
				{
					this.WriteElement("get");
					this.RenderAccessorMethod(GetMethodChild, referenceMethod, false, translateMethods);
					this.WriteEndElement();
				}
				IMethodReference SetMethodChild = value.SetMethod;
				if (SetMethodChild != null)
				{
					this.WriteElement("set");
					this.RenderAccessorMethod(SetMethodChild, referenceMethod, true, translateMethods);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void Render(IEventDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethods)
			{
				ITypeReference declaringType = value.DeclaringType as ITypeReference;
				bool isInterfaceMember = (declaringType != null) && declaringType.Resolve().Interface;
				this.Render(value, interfaceMemberInfo, translateMethods, isInterfaceMember);
			}
			private void Render(IEventDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethods, bool isInterfaceMember)
			{
				string elementName = "event";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name, true, false);
				IMethodDeclaration referenceMethod = GetEventReferenceMethod(value);
				IFieldDeclaration backingField = this.myMemberMap.GetSimpleEventField(value);
				ITypeReference eventType = value.EventType;
				if (referenceMethod != null)
				{
					this.RenderMethodVisibilityAttribute(referenceMethod);
				}
				if (!(isInterfaceMember))
				{
					if (referenceMethod != null)
					{
						this.RenderMethodModifierAttribute(referenceMethod);
					}
				}
				this.RenderDocumentation(value);
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem);
				}
				if (backingField != null)
				{
					foreach (ICustomAttribute backingFieldAttributesItem in backingField.Attributes)
					{
						this.RenderCustomAttribute(backingFieldAttributesItem, CustomAttributeTarget.ImplicitField);
					}
					if (referenceMethod != null)
					{
						foreach (ICustomAttribute referenceMethodAttributesItem in referenceMethod.Attributes)
						{
							ITypeReference attributeType = referenceMethodAttributesItem.Constructor.DeclaringType as ITypeReference;
							if ((attributeType != null) && ((attributeType.Name == "DebuggerNonUserCodeAttribute") && (attributeType.Namespace == "System.Diagnostics")))
							{
								continue;
							}
							this.RenderCustomAttribute(referenceMethodAttributesItem, CustomAttributeTarget.ImplicitAccessorFunction);
						}
					}
				}
				if (interfaceMemberInfo.HasInterfaceMembers)
				{
					foreach (IMemberReference InterfaceMemberCollectionItem in interfaceMemberInfo.InterfaceMemberCollection)
					{
						this.RenderInterfaceMember(InterfaceMemberCollectionItem);
					}
				}
				IParameterDeclarationCollection parameters = GetDelegateParameters(eventType);
				foreach (IParameterDeclaration parametersItem in parameters)
				{
					this.WriteElement("param");
					this.RenderParameterDeclaration(parametersItem);
					this.WriteEndElement();
				}
				if (eventType != null)
				{
					this.WriteElement("explicitDelegateType");
					this.RenderTypeReferenceWithoutGenerics(eventType);
					this.WriteEndElement();
				}
				IGenericArgumentProvider ownerGenericArgumentProvider = eventType.Owner as IGenericArgumentProvider;
				ITypeCollection ownerGenericArguments = null;
				if (ownerGenericArgumentProvider != null)
				{
					ownerGenericArguments = ownerGenericArgumentProvider.GenericArguments;
					if (ownerGenericArguments.Count == 0)
					{
						ownerGenericArguments = null;
					}
				}
				foreach (IType eventTypeGenericArgumentsItem in eventType.GenericArguments)
				{
					if ((ownerGenericArguments != null) && ownerGenericArguments.Contains(eventTypeGenericArgumentsItem))
					{
						continue;
					}
					this.WriteElement("passTypeParam");
					this.RenderGenericArgument(eventTypeGenericArgumentsItem);
					this.WriteEndElement();
				}
				if (backingField == null)
				{
					IMethodReference AddMethodChild = value.AddMethod;
					if (AddMethodChild != null)
					{
						this.WriteElement("onAdd");
						this.RenderAccessorMethod(AddMethodChild, null, true, translateMethods);
						this.WriteEndElement();
					}
					IMethodReference RemoveMethodChild = value.RemoveMethod;
					if (RemoveMethodChild != null)
					{
						this.WriteElement("onRemove");
						this.RenderAccessorMethod(RemoveMethodChild, null, true, translateMethods);
						this.WriteEndElement();
					}
					IMethodReference InvokeMethodChild = value.InvokeMethod;
					if (InvokeMethodChild != null)
					{
						this.WriteElement("onFire");
						this.RenderAccessorMethod(InvokeMethodChild, null, false, translateMethods);
						this.WriteEndElement();
					}
				}
				this.WriteEndElement();
			}
			private void Render(INamespace value, bool renderNamespaceBody, bool renderTypeBody, bool translateMethods)
			{
				string elementName = "namespace";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name, true, false);
				if (renderNamespaceBody)
				{
					foreach (ITypeDeclaration TypesItem in value.Types)
					{
						this.Render(TypesItem, renderTypeBody, translateMethods);
					}
				}
				this.WriteEndElement();
			}
			private void Render(IModule value)
			{
				string elementName = "root";
				this.WriteElement(elementName);
				this.WriteXmlComment();
				this.WriteText("Module ", WriteTextOptions.RawCommentSettings);
				this.WriteText(value.Name, WriteTextOptions.RenderRaw | WriteTextOptions.AsDeclaration);
				this.WriteEndElement();
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem, CustomAttributeTarget.Module);
				}
				this.WriteEndElement();
			}
			private void Render(IAssembly value)
			{
				string elementName = "root";
				this.WriteElement(elementName);
				this.WriteXmlComment();
				this.WriteText("Assembly ", WriteTextOptions.RawCommentSettings);
				this.WriteText(value.Name, WriteTextOptions.RenderRaw | WriteTextOptions.AsDeclaration);
				this.WriteText(", Version ", WriteTextOptions.RawCommentSettings);
				Version version = value.Version;
				this.WriteText(version.ToString(4), WriteTextOptions.RawCommentSettings);
				this.WriteEndElement();
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem, CustomAttributeTarget.Assembly);
				}
				this.WriteEndElement();
			}
			private void Render(IAssemblyReference value)
			{
				string elementName = "root";
				this.WriteElement(elementName);
				this.WriteXmlComment();
				this.WriteText("Assembly Reference ", WriteTextOptions.RawCommentSettings);
				this.WriteText(value.Name, WriteTextOptions.RenderRaw | WriteTextOptions.AsDeclaration);
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void Render(IModuleReference value)
			{
				string elementName = "root";
				this.WriteElement(elementName);
				this.WriteXmlComment();
				this.WriteText("Module Reference ", WriteTextOptions.RawCommentSettings);
				this.WriteText(value.Name, WriteTextOptions.RenderRaw | WriteTextOptions.AsDeclaration);
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void RenderAccessorMethod(IMethodReference value, IMethodDeclaration referenceMethod, bool renderParameterAttributes, bool translateMethod)
			{
				IMethodDeclaration accessorDeclaration = value.Resolve();
				if ((referenceMethod != null) && (CompareMethodVisibilityStrength(referenceMethod.Visibility, accessorDeclaration.Visibility) < 0))
				{
					if (accessorDeclaration != null)
					{
						this.RenderMethodVisibilityAttribute(accessorDeclaration);
					}
				}
				if (accessorDeclaration != null)
				{
					this.RenderDocumentation(accessorDeclaration);
				}
				foreach (ICustomAttribute accessorDeclarationAttributesItem in accessorDeclaration.Attributes)
				{
					this.RenderCustomAttribute(accessorDeclarationAttributesItem);
				}
				if (renderParameterAttributes)
				{
					IParameterDeclaration firstParam = accessorDeclaration.Parameters[0];
					foreach (ICustomAttribute firstParamAttributesItem in firstParam.Attributes)
					{
						this.RenderCustomAttribute(firstParamAttributesItem, CustomAttributeTarget.ImplicitValueParameter);
					}
				}
				IMethodBody accessorBody = translateMethod ? accessorDeclaration.Body as IMethodBody : null;
				if (accessorBody != null)
				{
					accessorDeclaration = this.myTranslator.TranslateMethodDeclaration(accessorDeclaration);
					this.myCurrentMethodDeclaration = accessorDeclaration;
					this.myCurrentMethodBody = accessorBody;
					try
					{
						IBlockStatement BodyChild = accessorDeclaration.Body as IBlockStatement;
						if (BodyChild != null)
						{
							this.RenderBlockStatement(BodyChild);
						}
					}
					finally
					{
						this.myCurrentMethodDeclaration = null;
						this.myCurrentMethodBody = null;
					}
				}
			}
			private void Render(IMethodDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethod)
			{
				ITypeReference declaringType = value.DeclaringType as ITypeReference;
				bool isInterfaceMember = (declaringType != null) && declaringType.Resolve().Interface;
				this.Render(value, interfaceMemberInfo, translateMethod, isInterfaceMember);
			}
			private void Render(IMethodDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool translateMethod, bool isInterfaceMember)
			{
				translateMethod = translateMethod && !(isInterfaceMember);
				if (translateMethod)
				{
					try
					{
						this.myCurrentMethodDeclaration = value;
						this.myCurrentMethodBody = value.Body as IMethodBody;
						value = this.myTranslator.TranslateMethodDeclaration(value);
					}
					catch
					{
						if (!(this.myFirstWrite))
						{
							this.myFormatter.WriteLine();
						}
						this.myFormatter.WriteComment(string.Format(System.Globalization.CultureInfo.CurrentCulture, "<!-- Reflector Error: Disassembly of {0} failed, method body will be empty. -->", value.Name));
						translateMethod = false;
						this.myCurrentMethodDeclaration = null;
						this.myCurrentMethodBody = null;
					}
					try
					{
						this.RenderMethod(value, interfaceMemberInfo, isInterfaceMember);
					}
					finally
					{
						if (translateMethod)
						{
							this.myCurrentMethodDeclaration = null;
							this.myCurrentMethodBody = null;
						}
					}
				}
				else
				{
					this.RenderMethod(value, interfaceMemberInfo, isInterfaceMember);
				}
			}
			private void RenderMethod(IMethodDeclaration value, InterfaceMemberInfo interfaceMemberInfo, bool isInterfaceMember)
			{
				string elementName = "function";
				IConstructorDeclaration constructorDeclaration = value as IConstructorDeclaration;
				string methodName = value.Name;
				string operatorType = null;
				if ((constructorDeclaration != null) || (value.RuntimeSpecialName && ((methodName == ".ctor") || (methodName == ".cctor"))))
				{
					methodName = ".construct";
				}
				else if (((value.SpecialName && !(value.RuntimeSpecialName)) && value.Static) && methodName.StartsWith("op_"))
				{
					switch (methodName)
					{
						case "op_Addition":
							operatorType = "add";
							break;
						case "op_BitwiseAnd":
							operatorType = "bitwiseAnd";
							break;
						case "op_ExclusiveOr":
							operatorType = "bitwiseExclusiveOr";
							break;
						case "op_OnesComplement":
							operatorType = "bitwiseNot";
							break;
						case "op_BitwiseOr":
							operatorType = "bitwiseOr";
							break;
						case "op_LogicalNot":
							operatorType = "booleanNot";
							break;
						case "op_Explicit":
							operatorType = "castNarrow";
							break;
						case "op_Implicit":
							operatorType = "castWiden";
							break;
						case "op_Decrement":
							operatorType = "decrement";
							break;
						case "op_Division":
							operatorType = "divide";
							break;
						case "op_Equality":
							operatorType = "equality";
							break;
						case "op_GreaterThan":
							operatorType = "greaterThan";
							break;
						case "op_GreaterThanOrEqual":
							operatorType = "greaterThanOrEqual";
							break;
						case "op_Increment":
							operatorType = "increment";
							break;
						case "op_Inequality":
							operatorType = "inequality";
							break;
						case "op_IntegerDivision":
							operatorType = "integerDivide";
							break;
						case "op_False":
							operatorType = "isFalse";
							break;
						case "op_True":
							operatorType = "isTrue";
							break;
						case "op_LessThan":
							operatorType = "lessThan";
							break;
						case "op_LessThanOrEqual":
							operatorType = "lessThanOrEqual";
							break;
						case "op_Like":
							operatorType = "like";
							break;
						case "op_Modulus":
							operatorType = "modulus";
							break;
						case "op_Multiply":
							operatorType = "multiply";
							break;
						case "op_UnaryNegation":
							operatorType = "negative";
							break;
						case "op_UnaryPlus":
							operatorType = "positive";
							break;
						case "op_LeftShift":
							operatorType = "shiftLeft";
							break;
						case "op_RightShift":
							operatorType = "shiftRight";
							break;
						case "op_Subtraction":
							operatorType = "subtract";
							break;
					}
				}
				else if (methodName == "Finalize")
				{
					methodName = ".finalize";
				}
				if (operatorType != null)
				{
					elementName = "operatorFunction";
				}
				this.WriteElement(elementName);
				if (operatorType == null)
				{
					this.WriteAttribute("name", methodName, true, false);
					this.RenderMethodVisibilityAttribute(value);
					if (!(isInterfaceMember))
					{
						this.RenderMethodModifierAttribute(value);
					}
				}
				else
				{
					this.WriteAttribute("type", operatorType);
				}
				this.RenderDocumentation(value);
				foreach (ICustomAttribute AttributesItem in value.Attributes)
				{
					this.RenderCustomAttribute(AttributesItem);
				}
				if (interfaceMemberInfo.HasInterfaceMembers)
				{
					foreach (IMemberReference InterfaceMemberCollectionItem in interfaceMemberInfo.InterfaceMemberCollection)
					{
						this.RenderInterfaceMember(InterfaceMemberCollectionItem);
					}
				}
				IGenericArgumentProvider ownerGenericArgumentProvider = value.DeclaringType as IGenericArgumentProvider;
				ITypeCollection ownerGenericArguments = null;
				if (ownerGenericArgumentProvider != null)
				{
					ownerGenericArguments = ownerGenericArgumentProvider.GenericArguments;
					if (ownerGenericArguments.Count == 0)
					{
						ownerGenericArguments = null;
					}
				}
				foreach (IGenericParameter GenericArgumentsItem in value.GenericArguments)
				{
					if ((ownerGenericArguments != null) && ownerGenericArguments.Contains(GenericArgumentsItem))
					{
						continue;
					}
					this.WriteElement("typeParam");
					this.RenderGenericParameterDeclaration(GenericArgumentsItem);
					this.WriteEndElement();
				}
				foreach (IParameterDeclaration ParametersItem in value.Parameters)
				{
					this.WriteElement("param");
					this.RenderParameterDeclaration(ParametersItem);
					this.WriteEndElement();
				}
				IMethodReturnType methodReturnType = value.ReturnType;
				IType methodReturnTypeType = methodReturnType.Type;
				this.WriteElementDelayed("returns");
				if ((methodReturnTypeType != null) && !(IsVoidType(methodReturnTypeType)))
				{
					this.RenderType(methodReturnTypeType);
				}
				foreach (ICustomAttribute methodReturnTypeAttributesItem in methodReturnType.Attributes)
				{
					this.RenderCustomAttribute(methodReturnTypeAttributesItem);
				}
				this.WriteEndElement();
				if (this.myCurrentMethodBody != null)
				{
					if (constructorDeclaration != null)
					{
						IMethodInvokeExpression initializer = constructorDeclaration.Initializer;
						if (initializer != null)
						{
							IMethodReferenceExpression initializerMethod = initializer.Method as IMethodReferenceExpression;
							if (!(((initializerMethod != null) && (initializerMethod.Target is IBaseReferenceExpression)) && (initializer.Arguments.Count == 0)))
							{
								if (initializer != null)
								{
									this.WriteElementDelayed("initialize");
									this.RenderMethodInvokeExpression(initializer);
									this.WriteEndElement();
								}
							}
						}
					}
					IBlockStatement BodyChild = value.Body as IBlockStatement;
					if (BodyChild != null)
					{
						this.RenderBlockStatement(BodyChild);
					}
				}
				this.WriteEndElement();
			}
			private void RenderMethodVisibilityAttribute(IMethodDeclaration value)
			{
				string visibilityAttributeValue = "";
				switch (value.Visibility)
				{
					case MethodVisibility.Public:
						visibilityAttributeValue = "public";
						break;
					case MethodVisibility.Private:
						visibilityAttributeValue = "private";
						break;
					case MethodVisibility.PrivateScope:
						visibilityAttributeValue = "private";
						break;
					case MethodVisibility.Assembly:
						visibilityAttributeValue = "internal";
						break;
					case MethodVisibility.Family:
						visibilityAttributeValue = "protected";
						break;
					case MethodVisibility.FamilyAndAssembly:
						visibilityAttributeValue = "protectedAndInternal";
						break;
					case MethodVisibility.FamilyOrAssembly:
						visibilityAttributeValue = "protectedOrInternal";
						break;
				}
				if (visibilityAttributeValue.Length != 0)
				{
					this.WriteAttribute("visibility", visibilityAttributeValue);
				}
			}
			private void RenderMethodModifierAttribute(IMethodDeclaration value)
			{
				bool isVirtual = value.Virtual;
				bool isOverride = isVirtual && !(value.NewSlot);
				string modifierAttributeValue = "";
				if (value.Static)
				{
					modifierAttributeValue = "static";
				}
				else if (isOverride && value.Final)
				{
					modifierAttributeValue = "sealedOverride";
				}
				else if (isOverride && value.Abstract)
				{
					modifierAttributeValue = "abstractOverride";
				}
				else if (isOverride)
				{
					modifierAttributeValue = "override";
				}
				else if (value.Abstract)
				{
					modifierAttributeValue = "abstract";
				}
				else if (isVirtual && !(value.Final))
				{
					modifierAttributeValue = "virtual";
				}
				if (modifierAttributeValue.Length != 0)
				{
					this.WriteAttribute("modifier", modifierAttributeValue);
				}
			}
			private void RenderCustomAttribute(ICustomAttribute value)
			{
				this.RenderCustomAttribute(value, CustomAttributeTarget.None);
			}
			private void RenderCustomAttribute(ICustomAttribute value, CustomAttributeTarget attributeTarget)
			{
				if (this.myShowCustomAttributes)
				{
					this.RenderCustomAttributeUnfiltered(value, attributeTarget);
				}
			}
			private void RenderCustomAttributeUnfiltered(ICustomAttribute value, CustomAttributeTarget attributeTarget)
			{
				string elementName = "attribute";
				this.WriteElement(elementName);
				string typeAttributeValue = "";
				switch (attributeTarget)
				{
					case CustomAttributeTarget.Assembly:
						typeAttributeValue = "assembly";
						break;
					case CustomAttributeTarget.Module:
						typeAttributeValue = "module";
						break;
					case CustomAttributeTarget.ImplicitField:
						typeAttributeValue = "implicitField";
						break;
					case CustomAttributeTarget.ImplicitAccessorFunction:
						typeAttributeValue = "implicitAccessorFunction";
						break;
					case CustomAttributeTarget.ImplicitValueParameter:
						typeAttributeValue = "implicitValueParameter";
						break;
				}
				if (typeAttributeValue.Length != 0)
				{
					this.WriteAttribute("type", typeAttributeValue);
				}
				IMethodReference ctorReference = value.Constructor;
				IType attributeType = ctorReference.DeclaringType;
				if (attributeType != null)
				{
					this.RenderType(attributeType);
				}
				int argumentIndex = -1;
				IExpressionCollection arguments = value.Arguments;
				int lastArgumentIndex = arguments.Count - 1;
				for (int i = lastArgumentIndex; i >= 0; --i)
				{
					if (arguments[i] is IMemberInitializerExpression)
					{
						--lastArgumentIndex;
					}
				}
				foreach (IExpression argumentsItem in arguments)
				{
					++argumentIndex;
					if (argumentIndex == lastArgumentIndex)
					{
						bool argumentsItemDelayEndChildElement = false;
						if (argumentsItem != null)
						{
							argumentsItemDelayEndChildElement = this.RenderArrayCreateExpressionAsParamArray(argumentsItem, true, ctorReference, argumentIndex, arguments);
						}
						if (argumentsItemDelayEndChildElement)
						{
							this.WriteEndElement();
							break;
						}
					}
					this.WriteElement("passParam");
					this.RenderExpression(argumentsItem);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderStatement(IStatement value)
			{
				this.RenderStatement(value, false);
			}
			private void RenderStatement(IStatement value, bool topLevel)
			{
				IAttachEventStatement AsIAttachEventStatement = value as IAttachEventStatement;
				if (AsIAttachEventStatement != null)
				{
					this.RenderAttachEventStatement(AsIAttachEventStatement);
				}
				else
				{
					IBreakStatement AsIBreakStatement = value as IBreakStatement;
					if (AsIBreakStatement != null)
					{
						this.RenderBreakStatement(AsIBreakStatement);
					}
					else
					{
						ICommentStatement AsICommentStatement = value as ICommentStatement;
						if (AsICommentStatement != null)
						{
							this.RenderCommentStatement(AsICommentStatement);
						}
						else
						{
							IConditionStatement AsIConditionStatement = value as IConditionStatement;
							if (AsIConditionStatement != null)
							{
								this.RenderConditionStatement(AsIConditionStatement);
							}
							else
							{
								IContinueStatement AsIContinueStatement = value as IContinueStatement;
								if (AsIContinueStatement != null)
								{
									this.RenderContinueStatement(AsIContinueStatement);
								}
								else
								{
									IDoStatement AsIDoStatement = value as IDoStatement;
									if (AsIDoStatement != null)
									{
										this.RenderDoStatement(AsIDoStatement);
									}
									else
									{
										IExpressionStatement AsIExpressionStatement = value as IExpressionStatement;
										if (AsIExpressionStatement != null)
										{
											this.RenderExpressionStatement(AsIExpressionStatement, topLevel);
										}
										else
										{
											IForEachStatement AsIForEachStatement = value as IForEachStatement;
											if (AsIForEachStatement != null)
											{
												this.RenderForEachStatement(AsIForEachStatement);
											}
											else
											{
												IForStatement AsIForStatement = value as IForStatement;
												if (AsIForStatement != null)
												{
													this.RenderForStatement(AsIForStatement);
												}
												else
												{
													IGotoStatement AsIGotoStatement = value as IGotoStatement;
													if (AsIGotoStatement != null)
													{
														this.RenderGotoStatement(AsIGotoStatement);
													}
													else
													{
														ILabeledStatement AsILabeledStatement = value as ILabeledStatement;
														if (AsILabeledStatement != null)
														{
															this.RenderLabeledStatement(AsILabeledStatement, topLevel);
														}
														else
														{
															ILockStatement AsILockStatement = value as ILockStatement;
															if (AsILockStatement != null)
															{
																this.RenderLockStatement(AsILockStatement);
															}
															else
															{
																IMethodReturnStatement AsIMethodReturnStatement = value as IMethodReturnStatement;
																if (AsIMethodReturnStatement != null)
																{
																	this.RenderMethodReturnStatement(AsIMethodReturnStatement);
																}
																else
																{
																	IRemoveEventStatement AsIRemoveEventStatement = value as IRemoveEventStatement;
																	if (AsIRemoveEventStatement != null)
																	{
																		this.RenderRemoveEventStatement(AsIRemoveEventStatement);
																	}
																	else
																	{
																		ISwitchStatement AsISwitchStatement = value as ISwitchStatement;
																		if (AsISwitchStatement != null)
																		{
																			this.RenderSwitchStatement(AsISwitchStatement);
																		}
																		else
																		{
																			IThrowExceptionStatement AsIThrowExceptionStatement = value as IThrowExceptionStatement;
																			if (AsIThrowExceptionStatement != null)
																			{
																				this.RenderThrowExceptionStatement(AsIThrowExceptionStatement);
																			}
																			else
																			{
																				ITryCatchFinallyStatement AsITryCatchFinallyStatement = value as ITryCatchFinallyStatement;
																				if (AsITryCatchFinallyStatement != null)
																				{
																					this.RenderTryCatchFinallyStatement(AsITryCatchFinallyStatement);
																				}
																				else
																				{
																					IUsingStatement AsIUsingStatement = value as IUsingStatement;
																					if (AsIUsingStatement != null)
																					{
																						this.RenderUsingStatement(AsIUsingStatement);
																					}
																					else
																					{
																						IWhileStatement AsIWhileStatement = value as IWhileStatement;
																						if (AsIWhileStatement != null)
																						{
																							this.RenderWhileStatement(AsIWhileStatement);
																						}
																						else
																						{
																							IStatement AsIStatement = value as IStatement;
																							if (AsIStatement != null)
																							{
																								this.RenderUnhandledStatement(AsIStatement);
																							}
																						}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			private void RenderBlockStatement(IBlockStatement value)
			{
				foreach (IStatement StatementsItem in value.Statements)
				{
					this.WriteExampleStatementComment(StatementsItem);
					this.RenderStatement(StatementsItem, true);
				}
			}
			private void RenderAttachEventStatement(IAttachEventStatement value)
			{
				string elementName = "attachEvent";
				this.WriteElement(elementName);
				IEventReferenceExpression EventChild = value.Event;
				if (EventChild != null)
				{
					this.WriteElement("left");
					this.RenderEventReferenceExpression(EventChild);
					this.WriteEndElement();
				}
				IExpression ListenerChild = value.Listener;
				if (ListenerChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(ListenerChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderRemoveEventStatement(IRemoveEventStatement value)
			{
				string elementName = "detachEvent";
				this.WriteElement(elementName);
				IEventReferenceExpression EventChild = value.Event;
				if (EventChild != null)
				{
					this.WriteElement("left");
					this.RenderEventReferenceExpression(EventChild);
					this.WriteEndElement();
				}
				IExpression ListenerChild = value.Listener;
				if (ListenerChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(ListenerChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderBreakStatement(IBreakStatement value)
			{
				string elementName = "break";
				this.WriteElement(elementName);
				this.WriteEndElement();
			}
			private void RenderBranchContents(IConditionStatement value)
			{
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElement("condition");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IBlockStatement ThenChild = value.Then;
				if (ThenChild != null)
				{
					this.RenderBlockStatement(ThenChild);
				}
			}
			private void RenderCatchClause(ICatchClause value)
			{
				string elementName = "catch";
				IVariableDeclaration variable = value.Variable;
				IType variableType = variable.VariableType;
				bool isFallbackCatch = IsObjectType(variableType);
				if (isFallbackCatch)
				{
					elementName = "fallbackCatch";
				}
				this.WriteElement(elementName);
				string variableName = variable.Name;
				if (!(string.IsNullOrEmpty(variableName)) && (this.myCurrentMethodBody.LocalVariables.Count > variable.Identifier))
				{
					this.WriteAttribute("localName", variableName);
				}
				if (!(isFallbackCatch))
				{
					if (variableType != null)
					{
						this.RenderType(variableType);
					}
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderCommentStatement(ICommentStatement value)
			{
				string commentText = value.Comment.Text;
				this.WriteElement("comment");
				this.WriteText(commentText, WriteTextOptions.AsComment);
				this.WriteEndElement();
			}
			private void RenderConditionStatement(IConditionStatement value)
			{
				IStatementCollection elseStatements = value.Else.Statements;
				int elseStatementsCount = elseStatements.Count;
				this.WriteElement("branch");
				this.RenderBranchContents(value);
				this.WriteEndElement();
				while (elseStatementsCount == 1)
				{
					IConditionStatement elseIfCondition = elseStatements[0] as IConditionStatement;
					if (elseIfCondition != null)
					{
						this.WriteElement("alternateBranch");
						this.RenderBranchContents(elseIfCondition);
						this.WriteEndElement();
						elseStatements = elseIfCondition.Else.Statements;
						elseStatementsCount = elseStatements.Count;
					}
					else
					{
						break;
					}
				}
				if (elseStatementsCount != 0)
				{
					this.WriteElement("fallbackBranch");
					foreach (IStatement elseStatement in elseStatements)
					{
						this.WriteExampleStatementComment(elseStatement);
						this.RenderStatement(elseStatement, true);
					}
					this.WriteEndElement();
				}
			}
			private void RenderContinueStatement(IContinueStatement value)
			{
				string elementName = "continue";
				this.WriteElement(elementName);
				this.WriteEndElement();
			}
			private void RenderDoStatement(IDoStatement value)
			{
				string elementName = "loop";
				this.WriteElement(elementName);
				this.WriteAttribute("checkCondition", "after");
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElementDelayed("condition");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderDelegateInvokeParameters(IMethodDeclaration value)
			{
				string methodName = value.Name;
				if (methodName == "Invoke")
				{
					foreach (IParameterDeclaration ParametersItem in value.Parameters)
					{
						this.WriteElement("param");
						this.RenderParameterDeclaration(ParametersItem);
						this.WriteEndElement();
					}
					IMethodReturnType methodReturnType = value.ReturnType;
					IType methodReturnTypeType = methodReturnType.Type;
					this.WriteElementDelayed("returns");
					if ((methodReturnTypeType != null) && !(IsVoidType(methodReturnTypeType)))
					{
						this.RenderType(methodReturnTypeType);
					}
					foreach (ICustomAttribute methodReturnTypeAttributesItem in methodReturnType.Attributes)
					{
						this.RenderCustomAttribute(methodReturnTypeAttributesItem);
					}
					this.WriteEndElement();
				}
			}
			private void RenderDocumentation(IDocumentationProvider value)
			{
				if (this.myShowDocumentation)
				{
					string documentation = value.Documentation;
					if (!(string.IsNullOrEmpty(documentation)))
					{
						this.WriteElement("leadingInfo");
						this.WriteElement("docComment");
						this.WriteText(documentation, WriteTextOptions.RawCommentSettings);
						this.WriteEndElement();
						this.WriteEndElement();
					}
				}
			}
			private void RenderEnum(ITypeDeclaration value, bool renderBody)
			{
				IFieldDeclarationCollection fields = value.Fields;
				foreach (IFieldDeclaration testField in fields)
				{
					if (!(testField.Literal))
					{
						ITypeReference testFieldType = testField.FieldType as ITypeReference;
						if (testFieldType != null)
						{
							string typeName = MapKnownSystemType(testFieldType);
							if (!(string.IsNullOrEmpty(typeName)) && (typeName != "i4"))
							{
								this.WriteAttribute("elementType", typeName);
							}
							break;
						}
					}
				}
				if (renderBody)
				{
					this.RenderDocumentation(value);
					foreach (ICustomAttribute AttributesItem in value.Attributes)
					{
						this.RenderCustomAttribute(AttributesItem);
					}
					foreach (IFieldDeclaration fieldsItem in fields)
					{
						this.RenderEnumField(fieldsItem);
					}
				}
			}
			private void RenderEnumField(IFieldDeclaration value)
			{
				if (value.Literal)
				{
					this.WriteElement("enumItem");
					this.WriteAttribute("name", value.Name, true, false);
					this.RenderDocumentation(value);
					foreach (ICustomAttribute AttributesItem in value.Attributes)
					{
						this.RenderCustomAttribute(AttributesItem);
					}
					IExpression InitializerChild = value.Initializer;
					if (InitializerChild != null)
					{
						this.WriteElement("initialize");
						this.RenderExpression(InitializerChild);
						this.WriteEndElement();
					}
					this.WriteEndElement();
				}
			}
			private void RenderForStatement(IForStatement value)
			{
				string elementName = "loop";
				this.WriteElement(elementName);
				IStatement InitializerChild = value.Initializer;
				if (InitializerChild != null)
				{
					this.WriteElementDelayed("initializeLoop");
					this.RenderStatement(InitializerChild, true);
					this.WriteEndElement();
				}
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElementDelayed("condition");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IStatement IncrementChild = value.Increment;
				if (IncrementChild != null)
				{
					this.WriteElementDelayed("beforeLoop");
					this.RenderStatement(IncrementChild, true);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderForEachStatement(IForEachStatement value)
			{
				string elementName = "iterator";
				this.WriteElement(elementName);
				IVariableDeclaration variable = value.Variable;
				this.WriteAttribute("localName", variable.Name);
				if (variable.VariableType != null)
				{
					this.RenderType(variable.VariableType);
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("initialize");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderGotoStatement(IGotoStatement value)
			{
				string elementName = "goto";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Name);
				this.WriteEndElement();
			}
			private void RenderLabeledStatement(ILabeledStatement value, bool topLevel)
			{
				this.WriteElement("label");
				this.WriteAttribute("name", value.Name, true, false);
				this.WriteEndElement();
				IStatement StatementChild = value.Statement;
				if (StatementChild != null)
				{
					this.RenderStatement(StatementChild, topLevel);
				}
			}
			private void RenderLockStatement(ILockStatement value)
			{
				string elementName = "lock";
				this.WriteElement(elementName);
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("initialize");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderMethodReturnStatement(IMethodReturnStatement value)
			{
				string elementName = "return";
				this.WriteElement(elementName);
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
				this.WriteEndElement();
			}
			private void RenderSwitchStatement(ISwitchStatement value)
			{
				string elementName = "switch";
				this.WriteElement(elementName);
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("condition");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				foreach (ISwitchCase CasesItem in value.Cases)
				{
					this.RenderSwitchCase(CasesItem);
				}
				this.WriteEndElement();
			}
			private void RenderSwitchCase(ISwitchCase value)
			{
				IConditionCase AsIConditionCase = value as IConditionCase;
				if (AsIConditionCase != null)
				{
					this.RenderSwitchConditionCase(AsIConditionCase);
				}
				else
				{
					IDefaultCase AsIDefaultCase = value as IDefaultCase;
					if (AsIDefaultCase != null)
					{
						this.RenderSwitchDefaultCase(AsIDefaultCase);
					}
				}
			}
			private void RenderSwitchCaseBody(IBlockStatement value)
			{
				IStatementCollection statements = value.Statements;
				int statementCount = statements.Count;
				if ((statementCount != 0) && (statements[statementCount - 1] is IBreakStatement))
				{
					--statementCount;
				}
				for (int i = 0; i < statementCount; ++i)
				{
					IStatement currentStatement = statements[i];
					this.WriteExampleStatementComment(currentStatement);
					this.RenderStatement(currentStatement, true);
				}
			}
			private void RenderSwitchCaseConditions(IExpression value)
			{
				IBinaryExpression binaryExpression = value as IBinaryExpression;
				if ((binaryExpression != null) && (binaryExpression.Operator == BinaryOperator.BooleanOr))
				{
					this.RenderSwitchCaseConditions(binaryExpression.Left);
					this.RenderSwitchCaseConditions(binaryExpression.Right);
				}
				else
				{
					this.WriteElement("condition");
					this.RenderExpression(value);
					this.WriteEndElement();
				}
			}
			private void RenderSwitchConditionCase(IConditionCase value)
			{
				string elementName = "case";
				this.WriteElement(elementName);
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.RenderSwitchCaseConditions(ConditionChild);
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderSwitchCaseBody(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderSwitchDefaultCase(IDefaultCase value)
			{
				string elementName = "fallbackCase";
				this.WriteElement(elementName);
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderSwitchCaseBody(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderThrowExceptionStatement(IThrowExceptionStatement value)
			{
				string elementName = "throw";
				this.WriteElement(elementName);
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
				this.WriteEndElement();
			}
			private void RenderTryCatchFinallyStatement(ITryCatchFinallyStatement value)
			{
				string elementName = "try";
				this.WriteElement(elementName);
				IBlockStatement TryChild = value.Try;
				if (TryChild != null)
				{
					this.RenderBlockStatement(TryChild);
				}
				foreach (ICatchClause CatchClausesItem in value.CatchClauses)
				{
					this.RenderCatchClause(CatchClausesItem);
				}
				IBlockStatement FinallyChild = value.Finally;
				if (FinallyChild != null)
				{
					this.WriteElementDelayed("finally");
					this.RenderBlockStatement(FinallyChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderUsingStatement(IUsingStatement value)
			{
				string elementName = "autoDispose";
				this.WriteElement(elementName);
				IVariableDeclarationExpression variableDeclaration = value.Variable as IVariableDeclarationExpression;
				if (variableDeclaration != null)
				{
					IVariableDeclaration variable = variableDeclaration.Variable;
					this.WriteAttribute("localName", variable.Name);
					if (variable.VariableType != null)
					{
						this.RenderType(variable.VariableType);
					}
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("initialize");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderWhileStatement(IWhileStatement value)
			{
				string elementName = "loop";
				this.WriteElement(elementName);
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElementDelayed("condition");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IBlockStatement BodyChild = value.Body;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderUnhandledStatement(IStatement value)
			{
				string elementName = "UNHANDLED_STATEMENT";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.GetType().Name);
				this.WriteEndElement();
			}
			private void RenderExpressionStatement(IExpressionStatement value, bool topLevel)
			{
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild, false, topLevel);
				}
			}
			private void RenderExpression(IExpression value)
			{
				this.RenderExpression(value, false, false);
			}
			private bool RenderExpression(IExpression value, bool delayEndElement)
			{
				bool retVal = false;
				retVal = this.RenderExpression(value, delayEndElement, false);
				return retVal;
			}
			private bool RenderExpression(IExpression value, bool delayEndElement, bool topLevel)
			{
				bool retVal = false;
				IAddressOutExpression AsIAddressOutExpression = value as IAddressOutExpression;
				if (AsIAddressOutExpression != null)
				{
					this.RenderAddressOutExpression(AsIAddressOutExpression);
				}
				else
				{
					IAddressReferenceExpression AsIAddressReferenceExpression = value as IAddressReferenceExpression;
					if (AsIAddressReferenceExpression != null)
					{
						this.RenderAddressReferenceExpression(AsIAddressReferenceExpression);
					}
					else
					{
						IAnonymousMethodExpression AsIAnonymousMethodExpression = value as IAnonymousMethodExpression;
						if (AsIAnonymousMethodExpression != null)
						{
							this.RenderAnonymousMethodExpression(AsIAnonymousMethodExpression);
						}
						else
						{
							IArgumentReferenceExpression AsIArgumentReferenceExpression = value as IArgumentReferenceExpression;
							if (AsIArgumentReferenceExpression != null)
							{
								this.RenderArgumentReferenceExpression(AsIArgumentReferenceExpression);
							}
							else
							{
								IArrayCreateExpression AsIArrayCreateExpression = value as IArrayCreateExpression;
								if (AsIArrayCreateExpression != null)
								{
									this.RenderArrayCreateExpression(AsIArrayCreateExpression);
								}
								else
								{
									IArrayIndexerExpression AsIArrayIndexerExpression = value as IArrayIndexerExpression;
									if (AsIArrayIndexerExpression != null)
									{
										this.RenderArrayIndexerExpression(AsIArrayIndexerExpression);
									}
									else
									{
										IAssignExpression AsIAssignExpression = value as IAssignExpression;
										if (AsIAssignExpression != null)
										{
											this.RenderAssignExpression(AsIAssignExpression, topLevel);
										}
										else
										{
											IBinaryExpression AsIBinaryExpression = value as IBinaryExpression;
											if (AsIBinaryExpression != null)
											{
												this.RenderBinaryExpression(AsIBinaryExpression);
											}
											else
											{
												ICanCastExpression AsICanCastExpression = value as ICanCastExpression;
												if (AsICanCastExpression != null)
												{
													this.RenderCanCastExpression(AsICanCastExpression);
												}
												else
												{
													ICastExpression AsICastExpression = value as ICastExpression;
													if (AsICastExpression != null)
													{
														this.RenderCastExpression(AsICastExpression);
													}
													else
													{
														IConditionExpression AsIConditionExpression = value as IConditionExpression;
														if (AsIConditionExpression != null)
														{
															this.RenderConditionExpression(AsIConditionExpression);
														}
														else
														{
															IDelegateCreateExpression AsIDelegateCreateExpression = value as IDelegateCreateExpression;
															if (AsIDelegateCreateExpression != null)
															{
																this.RenderDelegateCreateExpression(AsIDelegateCreateExpression);
															}
															else
															{
																IEventReferenceExpression AsIEventReferenceExpression = value as IEventReferenceExpression;
																if (AsIEventReferenceExpression != null)
																{
																	this.RenderEventReferenceExpression(AsIEventReferenceExpression);
																}
																else
																{
																	IFieldReferenceExpression AsIFieldReferenceExpression = value as IFieldReferenceExpression;
																	if (AsIFieldReferenceExpression != null)
																	{
																		this.RenderFieldReferenceExpression(AsIFieldReferenceExpression);
																	}
																	else
																	{
																		IGenericDefaultExpression AsIGenericDefaultExpression = value as IGenericDefaultExpression;
																		if (AsIGenericDefaultExpression != null)
																		{
																			this.RenderGenericDefaultExpression(AsIGenericDefaultExpression);
																		}
																		else
																		{
																			ILiteralExpression AsILiteralExpression = value as ILiteralExpression;
																			if (AsILiteralExpression != null)
																			{
																				this.RenderLiteralExpression(AsILiteralExpression);
																			}
																			else
																			{
																				IMemberInitializerExpression AsIMemberInitializerExpression = value as IMemberInitializerExpression;
																				if (AsIMemberInitializerExpression != null)
																				{
																					this.RenderMemberInitializerExpression(AsIMemberInitializerExpression);
																				}
																				else
																				{
																					IMethodInvokeExpression AsIMethodInvokeExpression = value as IMethodInvokeExpression;
																					if (AsIMethodInvokeExpression != null)
																					{
																						this.RenderMethodInvokeExpression(AsIMethodInvokeExpression);
																					}
																					else
																					{
																						IMethodReferenceExpression AsIMethodReferenceExpression = value as IMethodReferenceExpression;
																						if (AsIMethodReferenceExpression != null)
																						{
																							retVal = this.RenderMethodReferenceExpression(AsIMethodReferenceExpression, delayEndElement);
																						}
																						else
																						{
																							INullCoalescingExpression AsINullCoalescingExpression = value as INullCoalescingExpression;
																							if (AsINullCoalescingExpression != null)
																							{
																								this.RenderNullCoalescingExpression(AsINullCoalescingExpression);
																							}
																							else
																							{
																								IObjectCreateExpression AsIObjectCreateExpression = value as IObjectCreateExpression;
																								if (AsIObjectCreateExpression != null)
																								{
																									this.RenderObjectCreateExpression(AsIObjectCreateExpression);
																								}
																								else
																								{
																									IPropertyIndexerExpression AsIPropertyIndexerExpression = value as IPropertyIndexerExpression;
																									if (AsIPropertyIndexerExpression != null)
																									{
																										this.RenderPropertyIndexerExpression(AsIPropertyIndexerExpression);
																									}
																									else
																									{
																										IPropertyReferenceExpression AsIPropertyReferenceExpression = value as IPropertyReferenceExpression;
																										if (AsIPropertyReferenceExpression != null)
																										{
																											retVal = this.RenderPropertyReferenceExpression(AsIPropertyReferenceExpression, delayEndElement, false);
																										}
																										else
																										{
																											IThisReferenceExpression AsIThisReferenceExpression = value as IThisReferenceExpression;
																											if (AsIThisReferenceExpression != null)
																											{
																												this.RenderThisReferenceExpression(AsIThisReferenceExpression);
																											}
																											else
																											{
																												ITryCastExpression AsITryCastExpression = value as ITryCastExpression;
																												if (AsITryCastExpression != null)
																												{
																													this.RenderTryCastExpression(AsITryCastExpression);
																												}
																												else
																												{
																													ITypeOfExpression AsITypeOfExpression = value as ITypeOfExpression;
																													if (AsITypeOfExpression != null)
																													{
																														this.RenderTypeOfExpression(AsITypeOfExpression);
																													}
																													else
																													{
																														ITypeReferenceExpression AsITypeReferenceExpression = value as ITypeReferenceExpression;
																														if (AsITypeReferenceExpression != null)
																														{
																															this.RenderTypeReferenceExpression(AsITypeReferenceExpression);
																														}
																														else
																														{
																															IUnaryExpression AsIUnaryExpression = value as IUnaryExpression;
																															if (AsIUnaryExpression != null)
																															{
																																this.RenderUnaryExpression(AsIUnaryExpression, topLevel);
																															}
																															else
																															{
																																IVariableDeclarationExpression AsIVariableDeclarationExpression = value as IVariableDeclarationExpression;
																																if (AsIVariableDeclarationExpression != null)
																																{
																																	this.RenderVariableDeclarationExpression(AsIVariableDeclarationExpression);
																																}
																																else
																																{
																																	IVariableReferenceExpression AsIVariableReferenceExpression = value as IVariableReferenceExpression;
																																	if (AsIVariableReferenceExpression != null)
																																	{
																																		this.RenderVariableReferenceExpression(AsIVariableReferenceExpression);
																																	}
																																	else
																																	{
																																		IExpression AsIExpression = value as IExpression;
																																		if (AsIExpression != null)
																																		{
																																			this.RenderUnhandledExpression(AsIExpression);
																																		}
																																	}
																																}
																															}
																														}
																													}
																												}
																											}
																										}
																									}
																								}
																							}
																						}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
				return retVal;
			}
			private void RenderExpressionType(IExpression value)
			{
				if (TestNullifyExpression(value) == null)
				{
					this.WriteAttribute("dataTypeName", ".object");
					return;
				}
				IAddressOutExpression AsIAddressOutExpression = value as IAddressOutExpression;
				if (AsIAddressOutExpression != null)
				{
					this.RenderAddressOutExpressionType(AsIAddressOutExpression);
				}
				else
				{
					IAddressReferenceExpression AsIAddressReferenceExpression = value as IAddressReferenceExpression;
					if (AsIAddressReferenceExpression != null)
					{
						this.RenderAddressReferenceExpressionType(AsIAddressReferenceExpression);
					}
					else
					{
						IAnonymousMethodExpression AsIAnonymousMethodExpression = value as IAnonymousMethodExpression;
						if (AsIAnonymousMethodExpression != null)
						{
							this.RenderAnonymousMethodExpressionType(AsIAnonymousMethodExpression);
						}
						else
						{
							IArgumentReferenceExpression AsIArgumentReferenceExpression = value as IArgumentReferenceExpression;
							if (AsIArgumentReferenceExpression != null)
							{
								this.RenderArgumentReferenceExpressionType(AsIArgumentReferenceExpression);
							}
							else
							{
								IArrayCreateExpression AsIArrayCreateExpression = value as IArrayCreateExpression;
								if (AsIArrayCreateExpression != null)
								{
									this.RenderArrayCreateExpressionType(AsIArrayCreateExpression);
								}
								else
								{
									IArrayIndexerExpression AsIArrayIndexerExpression = value as IArrayIndexerExpression;
									if (AsIArrayIndexerExpression != null)
									{
										this.RenderArrayIndexerExpressionType(AsIArrayIndexerExpression);
									}
									else
									{
										IAssignExpression AsIAssignExpression = value as IAssignExpression;
										if (AsIAssignExpression != null)
										{
											this.RenderAssignExpressionType(AsIAssignExpression);
										}
										else
										{
											IBinaryExpression AsIBinaryExpression = value as IBinaryExpression;
											if (AsIBinaryExpression != null)
											{
												this.RenderBinaryExpressionType(AsIBinaryExpression);
											}
											else
											{
												ICanCastExpression AsICanCastExpression = value as ICanCastExpression;
												if (AsICanCastExpression != null)
												{
													this.RenderCanCastExpressionType(AsICanCastExpression);
												}
												else
												{
													ICastExpression AsICastExpression = value as ICastExpression;
													if (AsICastExpression != null)
													{
														this.RenderCastExpressionType(AsICastExpression);
													}
													else
													{
														IConditionExpression AsIConditionExpression = value as IConditionExpression;
														if (AsIConditionExpression != null)
														{
															this.RenderConditionExpressionType(AsIConditionExpression);
														}
														else
														{
															IDelegateCreateExpression AsIDelegateCreateExpression = value as IDelegateCreateExpression;
															if (AsIDelegateCreateExpression != null)
															{
																this.RenderDelegateCreateExpressionType(AsIDelegateCreateExpression);
															}
															else
															{
																IEventReferenceExpression AsIEventReferenceExpression = value as IEventReferenceExpression;
																if (AsIEventReferenceExpression != null)
																{
																	this.RenderEventReferenceExpressionType(AsIEventReferenceExpression);
																}
																else
																{
																	IFieldReferenceExpression AsIFieldReferenceExpression = value as IFieldReferenceExpression;
																	if (AsIFieldReferenceExpression != null)
																	{
																		this.RenderFieldReferenceExpressionType(AsIFieldReferenceExpression);
																	}
																	else
																	{
																		IGenericDefaultExpression AsIGenericDefaultExpression = value as IGenericDefaultExpression;
																		if (AsIGenericDefaultExpression != null)
																		{
																			this.RenderGenericDefaultExpressionType(AsIGenericDefaultExpression);
																		}
																		else
																		{
																			ILiteralExpression AsILiteralExpression = value as ILiteralExpression;
																			if (AsILiteralExpression != null)
																			{
																				this.RenderLiteralExpressionType(AsILiteralExpression);
																			}
																			else
																			{
																				IMethodInvokeExpression AsIMethodInvokeExpression = value as IMethodInvokeExpression;
																				if (AsIMethodInvokeExpression != null)
																				{
																					this.RenderMethodInvokeExpressionType(AsIMethodInvokeExpression);
																				}
																				else
																				{
																					IMethodReferenceExpression AsIMethodReferenceExpression = value as IMethodReferenceExpression;
																					if (AsIMethodReferenceExpression != null)
																					{
																						this.RenderMethodReferenceExpressionType(AsIMethodReferenceExpression);
																					}
																					else
																					{
																						INullCoalescingExpression AsINullCoalescingExpression = value as INullCoalescingExpression;
																						if (AsINullCoalescingExpression != null)
																						{
																							this.RenderNullCoalescingExpressionType(AsINullCoalescingExpression);
																						}
																						else
																						{
																							IObjectCreateExpression AsIObjectCreateExpression = value as IObjectCreateExpression;
																							if (AsIObjectCreateExpression != null)
																							{
																								this.RenderObjectCreateExpressionType(AsIObjectCreateExpression);
																							}
																							else
																							{
																								IPropertyIndexerExpression AsIPropertyIndexerExpression = value as IPropertyIndexerExpression;
																								if (AsIPropertyIndexerExpression != null)
																								{
																									this.RenderPropertyIndexerExpressionType(AsIPropertyIndexerExpression);
																								}
																								else
																								{
																									IPropertyReferenceExpression AsIPropertyReferenceExpression = value as IPropertyReferenceExpression;
																									if (AsIPropertyReferenceExpression != null)
																									{
																										this.RenderPropertyReferenceExpressionType(AsIPropertyReferenceExpression);
																									}
																									else
																									{
																										IThisReferenceExpression AsIThisReferenceExpression = value as IThisReferenceExpression;
																										if (AsIThisReferenceExpression != null)
																										{
																											this.RenderThisReferenceExpressionType(AsIThisReferenceExpression);
																										}
																										else
																										{
																											ITryCastExpression AsITryCastExpression = value as ITryCastExpression;
																											if (AsITryCastExpression != null)
																											{
																												this.RenderTryCastExpressionType(AsITryCastExpression);
																											}
																											else
																											{
																												ITypeOfExpression AsITypeOfExpression = value as ITypeOfExpression;
																												if (AsITypeOfExpression != null)
																												{
																													this.RenderTypeOfExpressionType(AsITypeOfExpression);
																												}
																												else
																												{
																													ITypeReferenceExpression AsITypeReferenceExpression = value as ITypeReferenceExpression;
																													if (AsITypeReferenceExpression != null)
																													{
																														this.RenderTypeReferenceExpressionType(AsITypeReferenceExpression);
																													}
																													else
																													{
																														IUnaryExpression AsIUnaryExpression = value as IUnaryExpression;
																														if (AsIUnaryExpression != null)
																														{
																															this.RenderUnaryExpressionType(AsIUnaryExpression);
																														}
																														else
																														{
																															IVariableDeclarationExpression AsIVariableDeclarationExpression = value as IVariableDeclarationExpression;
																															if (AsIVariableDeclarationExpression != null)
																															{
																																this.RenderVariableDeclarationExpressionType(AsIVariableDeclarationExpression);
																															}
																															else
																															{
																																IVariableReferenceExpression AsIVariableReferenceExpression = value as IVariableReferenceExpression;
																																if (AsIVariableReferenceExpression != null)
																																{
																																	this.RenderVariableReferenceExpressionType(AsIVariableReferenceExpression);
																																}
																																else
																																{
																																	IExpression AsIExpression = value as IExpression;
																																	if (AsIExpression != null)
																																	{
																																		this.RenderUnhandledExpressionType(AsIExpression);
																																	}
																																}
																															}
																														}
																													}
																												}
																											}
																										}
																									}
																								}
																							}
																						}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			private void RenderAddressOutExpression(IAddressOutExpression value)
			{
				this.WriteAttribute("type", "out");
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
			}
			private void RenderAddressOutExpressionType(IAddressOutExpression value)
			{
				IExpression expression = value.Expression;
				this.RenderExpressionType(TestNullifyExpression(expression));
			}
			private void RenderAddressReferenceExpression(IAddressReferenceExpression value)
			{
				this.WriteAttribute("type", "inOut");
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
			}
			private void RenderAddressReferenceExpressionType(IAddressReferenceExpression value)
			{
				IExpression expression = value.Expression;
				this.RenderExpressionType(TestNullifyExpression(expression));
			}
			private void RenderAnonymousMethodExpression(IAnonymousMethodExpression value)
			{
				string elementName = "anonymousFunction";
				this.WriteElement(elementName);
				foreach (IParameterDeclaration ParametersItem in value.Parameters)
				{
					this.WriteElement("param");
					this.RenderParameterDeclaration(ParametersItem);
					this.WriteEndElement();
				}
				IType returnType = value.ReturnType.Type;
				this.WriteElementDelayed("returns");
				if ((returnType != null) && !(IsVoidType(returnType)))
				{
					this.RenderType(returnType);
				}
				this.WriteEndElement();
				IBlockStatement BodyChild = value.Body as IBlockStatement;
				if (BodyChild != null)
				{
					this.RenderBlockStatement(BodyChild);
				}
				this.WriteEndElement();
			}
			private void RenderAnonymousMethodExpressionType(IAnonymousMethodExpression value)
			{
				IType methodType = value.ReturnType.Type;
				if (methodType != null)
				{
					this.RenderType(methodType);
				}
			}
			private void RenderArgumentReferenceExpression(IArgumentReferenceExpression value)
			{
				string elementName = "nameRef";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Parameter.Name);
				this.WriteAttribute("type", "parameter");
				this.WriteEndElement();
			}
			private void RenderArgumentReferenceExpressionType(IArgumentReferenceExpression value)
			{
				IType parameterType = value.Parameter.Resolve().ParameterType;
				if (parameterType != null)
				{
					this.RenderType(parameterType);
				}
			}
			private void RenderArrayCreateExpression(IArrayCreateExpression value)
			{
				string elementName = "callNew";
				this.WriteElement(elementName);
				this.RenderArrayCreateExpressionType(value);
				IBlockExpression arrayInitializer = value.Initializer;
				if (arrayInitializer != null)
				{
					this.RenderArrayInitializerExpression(arrayInitializer);
				}
				else
				{
					foreach (IExpression DimensionsItem in value.Dimensions)
					{
						this.WriteElement("passParam");
						this.RenderExpression(DimensionsItem);
						this.WriteEndElement();
					}
				}
				this.WriteEndElement();
			}
			private bool RenderArrayCreateExpressionAsParamArray(IExpression value, bool delayEndElement, IExpression targetMethod, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				IArrayCreateExpression arrayCreate = value as IArrayCreateExpression;
				if (arrayCreate != null)
				{
					retVal = this.RenderArrayCreateExpressionAsParamArray(arrayCreate, true, targetMethod, argumentIndex, allArguments);
				}
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IExpression value, bool delayEndElement, IPropertyReferenceExpression targetProperty, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				IArrayCreateExpression arrayCreate = value as IArrayCreateExpression;
				if (arrayCreate != null)
				{
					retVal = this.RenderArrayCreateExpressionAsParamArray(arrayCreate, true, targetProperty, argumentIndex, allArguments);
				}
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IExpression value, bool delayEndElement, IMethodReference targetMethod, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				IArrayCreateExpression arrayCreate = value as IArrayCreateExpression;
				if (arrayCreate != null)
				{
					retVal = this.RenderArrayCreateExpressionAsParamArray(arrayCreate, true, targetMethod, argumentIndex, allArguments);
				}
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IArrayCreateExpression value, bool delayEndElement, IExpression targetMethod, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				IMethodReferenceExpression methodReferenceExpression = (IMethodReferenceExpression)targetMethod;
				if (methodReferenceExpression != null)
				{
					retVal = this.RenderArrayCreateExpressionAsParamArray(value, true, methodReferenceExpression.Method, argumentIndex, allArguments);
				}
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IArrayCreateExpression value, bool delayEndElement, IPropertyReferenceExpression targetProperty, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				retVal = this.RenderArrayCreateExpressionAsParamArray(value, true, targetProperty.Property.Parameters, argumentIndex, allArguments);
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IArrayCreateExpression value, bool delayEndElement, IMethodReference targetMethod, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				retVal = this.RenderArrayCreateExpressionAsParamArray(value, true, targetMethod.Resolve().Parameters, argumentIndex, allArguments);
				return retVal;
			}
			private bool RenderArrayCreateExpressionAsParamArray(IArrayCreateExpression value, bool delayEndElement, IParameterDeclarationCollection parameters, int argumentIndex, IExpressionCollection allArguments)
			{
				bool retVal = false;
				ICustomAttributeCollection parameterAttributes;
				int parameterAttributesCount;
				if (((value.Dimensions.Count == 1) && (value.Type is ITypeReference)) && (0 != (parameterAttributesCount = (parameterAttributes = parameters[argumentIndex].Resolve().Attributes).Count)))
				{
					for (int i = 0; i < parameterAttributesCount; ++i)
					{
						ITypeReference attributeType = parameterAttributes[i].Constructor.DeclaringType as ITypeReference;
						if ((attributeType.Name == "ParamArrayAttribute") && (attributeType.Namespace == "System"))
						{
							retVal = true;
							break;
						}
					}
					if (retVal)
					{
						if (allArguments != null)
						{
							// If allArguments is provided, then we need to render all named arguments before the passParamArray to satisfy the PLiX schema
							int allArgumentsCount = allArguments.Count;
							for (int iNamedArgument = argumentIndex + 1; iNamedArgument < allArgumentsCount; ++iNamedArgument)
							{
								this.WriteElement("passParam");
								this.RenderExpression(allArguments[iNamedArgument]);
								this.WriteEndElement();
							}
						}
						this.WriteElement("passParamArray");
						this.RenderArrayCreateExpressionType(value);
						IBlockExpression arrayInitializer = value.Initializer;
						if (arrayInitializer != null)
						{
							foreach (IExpression arrayInitializerExpressionsItem in arrayInitializer.Expressions)
							{
								this.WriteElement("passParam");
								this.RenderExpression(arrayInitializerExpressionsItem);
								this.WriteEndElement();
							}
						}
					}
				}
				return retVal;
			}
			private void RenderArrayCreateExpressionType(IArrayCreateExpression value)
			{
				this.RenderType(MockupArrayType(value.Type, value.Dimensions.Count));
			}
			private void RenderArrayIndexerExpression(IArrayIndexerExpression value)
			{
				string elementName = "callInstance";
				this.WriteElement(elementName);
				this.WriteAttribute("name", ".implied");
				this.WriteAttribute("type", "arrayIndexer");
				IExpression TargetChild = value.Target;
				if (TargetChild != null)
				{
					this.WriteElement("callObject");
					this.RenderExpression(TargetChild);
					this.WriteEndElement();
				}
				foreach (IExpression IndicesItem in value.Indices)
				{
					this.WriteElement("passParam");
					this.RenderExpression(IndicesItem);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderArrayIndexerExpressionType(IArrayIndexerExpression value)
			{
				IExpression expression = value.Target;
				this.RenderExpressionType(TestNullifyExpression(expression));
			}
			private void RenderArrayInitializerChildExpression(IExpression value)
			{
				IBlockExpression arrayInitializer = value as IBlockExpression;
				if (arrayInitializer != null)
				{
					if (arrayInitializer != null)
					{
						this.RenderArrayInitializerExpression(arrayInitializer);
					}
				}
				else
				{
					this.RenderExpression(value);
				}
			}
			private void RenderArrayInitializerExpression(IBlockExpression value)
			{
				string elementName = "arrayInitializer";
				this.WriteElement(elementName);
				foreach (IExpression ExpressionsItem in value.Expressions)
				{
					this.RenderArrayInitializerChildExpression(ExpressionsItem);
				}
				this.WriteEndElement();
			}
			private void RenderBinaryExpression(IBinaryExpression value)
			{
				string elementName = "binaryOperator";
				this.WriteElement(elementName);
				string typeAttributeValue = "";
				switch (value.Operator)
				{
					case BinaryOperator.Add:
						typeAttributeValue = "add";
						break;
					case BinaryOperator.BitwiseAnd:
						typeAttributeValue = "bitwiseAnd";
						break;
					case BinaryOperator.BitwiseExclusiveOr:
						typeAttributeValue = "bitwiseExclusiveOr";
						break;
					case BinaryOperator.BitwiseOr:
						typeAttributeValue = "bitwiseOr";
						break;
					case BinaryOperator.BooleanAnd:
						typeAttributeValue = "booleanAnd";
						break;
					case BinaryOperator.BooleanOr:
						typeAttributeValue = "booleanOr";
						break;
					case BinaryOperator.Divide:
						typeAttributeValue = "divide";
						break;
					case BinaryOperator.GreaterThan:
						typeAttributeValue = "greaterThan";
						break;
					case BinaryOperator.GreaterThanOrEqual:
						typeAttributeValue = "greaterThanOrEqual";
						break;
					case BinaryOperator.IdentityEquality:
						typeAttributeValue = "identityEquality";
						break;
					case BinaryOperator.IdentityInequality:
						typeAttributeValue = "identityInequality";
						break;
					case BinaryOperator.LessThan:
						typeAttributeValue = "lessThan";
						break;
					case BinaryOperator.LessThanOrEqual:
						typeAttributeValue = "lessThanOrEqual";
						break;
					case BinaryOperator.Modulus:
						typeAttributeValue = "modulus";
						break;
					case BinaryOperator.Multiply:
						typeAttributeValue = "multiply";
						break;
					case BinaryOperator.ShiftLeft:
						typeAttributeValue = "shiftLeft";
						break;
					case BinaryOperator.ShiftRight:
						typeAttributeValue = "shiftRight";
						break;
					case BinaryOperator.Subtract:
						typeAttributeValue = "subtract";
						break;
					case BinaryOperator.ValueEquality:
						typeAttributeValue = "equality";
						break;
					case BinaryOperator.ValueInequality:
						typeAttributeValue = "inequality";
						break;
				}
				if (typeAttributeValue.Length != 0)
				{
					this.WriteAttribute("type", typeAttributeValue);
				}
				IExpression LeftChild = value.Left;
				if (LeftChild != null)
				{
					this.WriteElement("left");
					this.RenderExpression(LeftChild);
					this.WriteEndElement();
				}
				IExpression RightChild = value.Right;
				if (RightChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(RightChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderBinaryExpressionType(IBinaryExpression value)
			{
				string dataTypeNameAttributeValue = "";
				switch (value.Operator)
				{
					case BinaryOperator.BooleanAnd:
					case BinaryOperator.BooleanOr:
					case BinaryOperator.GreaterThan:
					case BinaryOperator.GreaterThanOrEqual:
					case BinaryOperator.IdentityEquality:
					case BinaryOperator.IdentityInequality:
					case BinaryOperator.LessThan:
					case BinaryOperator.LessThanOrEqual:
					case BinaryOperator.ValueEquality:
					case BinaryOperator.ValueInequality:
						dataTypeNameAttributeValue = ".boolean";
						break;
				}
				if (dataTypeNameAttributeValue.Length != 0)
				{
					this.WriteAttribute("dataTypeName", dataTypeNameAttributeValue);
				}
				else
				{
					IExpression leftClause = value.Left;
					IExpression rightClause = value.Right;
					this.RenderExpressionType(TestNullifyExpression(leftClause) ?? TestNullifyExpression(rightClause));
				}
			}
			private void RenderCanCastExpression(ICanCastExpression value)
			{
				string elementName = "binaryOperator";
				this.WriteElement(elementName);
				this.WriteAttribute("type", "typeEquality");
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("left");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				this.WriteElement("right");
				if (value.TargetType != null)
				{
					this.WriteElement("directTypeReference");
					this.RenderType(value.TargetType);
					this.WriteEndElement();
				}
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void RenderCanCastExpressionType(ICanCastExpression value)
			{
				this.WriteAttribute("dataTypeName", ".boolean");
			}
			private void RenderCastExpression(ICastExpression value)
			{
				string elementName = "cast";
				this.WriteElement(elementName);
				IType TargetTypeChild = value.TargetType;
				if (TargetTypeChild != null)
				{
					this.RenderType(TargetTypeChild);
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
				this.WriteEndElement();
			}
			private void RenderCastExpressionType(ICastExpression value)
			{
				IType targetType = value.TargetType;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderEventReferenceExpression(IEventReferenceExpression value)
			{
				string elementName = "callInstance";
				IEventReference member = value.Event;
				IExpression target = value.Target;
				ITypeReferenceExpression staticTypeReference = target as ITypeReferenceExpression;
				bool staticCall = staticTypeReference != null;
				bool thisCall = !(staticCall) && (target is IThisReferenceExpression);
				bool baseCall = !(thisCall) && (target is IBaseReferenceExpression);
				if (staticCall)
				{
					elementName = "callStatic";
				}
				else if (thisCall || baseCall)
				{
					elementName = "callThis";
				}
				this.WriteElement(elementName);
				this.WriteAttribute("name", member.Name, member.ToString(), member);
				this.WriteAttribute("type", "event");
				if (staticCall)
				{
					this.RenderTypeReferenceExpression(staticTypeReference);
				}
				else if (baseCall)
				{
					this.WriteAttribute("accessor", "base");
				}
				else if (!(thisCall))
				{
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("callObject");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
				}
				this.WriteEndElement();
			}
			private void RenderEventReferenceExpressionType(IEventReferenceExpression value)
			{
				ITypeReference targetType = value.Event.EventType;
				if (targetType != null)
				{
					this.RenderTypeReference(targetType);
				}
			}
			private void RenderFieldReferenceExpression(IFieldReferenceExpression value)
			{
				string elementName = "callInstance";
				IFieldReference member = value.Field;
				IExpression target = value.Target;
				ITypeReferenceExpression staticTypeReference = target as ITypeReferenceExpression;
				bool staticCall = staticTypeReference != null;
				bool thisCall = !(staticCall) && (target is IThisReferenceExpression);
				bool baseCall = !(thisCall) && (target is IBaseReferenceExpression);
				if (staticCall)
				{
					elementName = "callStatic";
				}
				else if (thisCall || baseCall)
				{
					elementName = "callThis";
				}
				this.WriteElement(elementName);
				this.WriteAttribute("name", member.Name, member.ToString(), member);
				this.WriteAttribute("type", "field");
				if (staticCall)
				{
					this.RenderTypeReferenceExpression(staticTypeReference);
				}
				else if (baseCall)
				{
					this.WriteAttribute("accessor", "base");
				}
				else if (!(thisCall))
				{
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("callObject");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
				}
				this.WriteEndElement();
			}
			private void RenderFieldReferenceExpressionType(IFieldReferenceExpression value)
			{
				IType targetType = value.Field.FieldType;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderGenericDefaultExpression(IGenericDefaultExpression value)
			{
				string elementName = "defaultValueOf";
				this.WriteElement(elementName);
				IGenericArgument genericArgument = value.GenericArgument;
				IType objectType = genericArgument.Resolve();
				if (objectType != null)
				{
					this.RenderType(objectType);
				}
				this.WriteEndElement();
			}
			private void RenderGenericDefaultExpressionType(IGenericDefaultExpression value)
			{
				IGenericArgument genericArgument = value.GenericArgument;
				if (genericArgument.Resolve() != null)
				{
					this.RenderType(genericArgument.Resolve());
				}
			}
			private void RenderLiteralExpression(ILiteralExpression value)
			{
				string elementName = "value";
				object literalValue = value.Value;
				string xmlValue = null;
				bool isSpecialValue = false;
				string valueType = null;
				if (literalValue != null)
				{
					switch (Type.GetTypeCode(literalValue.GetType()))
					{
						case TypeCode.Boolean:
							xmlValue = XmlConvert.ToString((bool)literalValue);
							elementName = string.Concat(xmlValue, "Keyword");
							xmlValue = null;
							isSpecialValue = true;
							break;
						case TypeCode.Char:
							valueType = "char";
							xmlValue = XmlConvert.ToString((char)literalValue);
							break;
						case TypeCode.DateTime:
							valueType = "date";
							xmlValue = XmlConvert.ToString((System.DateTime)literalValue, XmlDateTimeSerializationMode.Utc);
							break;
						case TypeCode.Decimal:
							valueType = "decimal";
							xmlValue = XmlConvert.ToString((decimal)literalValue);
							break;
						case TypeCode.SByte:
							valueType = "i1";
							xmlValue = XmlConvert.ToString((sbyte)literalValue);
							break;
						case TypeCode.Int16:
							valueType = "i2";
							xmlValue = XmlConvert.ToString((short)literalValue);
							break;
						case TypeCode.Int32:
							valueType = "i4";
							xmlValue = XmlConvert.ToString((int)literalValue);
							break;
						case TypeCode.Int64:
							valueType = "i8";
							xmlValue = XmlConvert.ToString((long)literalValue);
							break;
						case TypeCode.Single:
							valueType = "r4";
							xmlValue = XmlConvert.ToString((float)literalValue);
							break;
						case TypeCode.Double:
							valueType = "r8";
							xmlValue = XmlConvert.ToString((double)literalValue);
							break;
						case TypeCode.String:
							xmlValue = (string)literalValue;
							elementName = "string";
							isSpecialValue = true;
							break;
						case TypeCode.Byte:
							valueType = "u1";
							xmlValue = XmlConvert.ToString((byte)literalValue);
							break;
						case TypeCode.UInt16:
							valueType = "u2";
							xmlValue = XmlConvert.ToString((ushort)literalValue);
							break;
						case TypeCode.UInt32:
							valueType = "u4";
							xmlValue = XmlConvert.ToString((uint)literalValue);
							break;
						case TypeCode.UInt64:
							valueType = "u8";
							xmlValue = XmlConvert.ToString((ulong)literalValue);
							break;
					}
				}
				if (!(isSpecialValue) && (xmlValue == null))
				{
					elementName = "nullKeyword";
				}
				this.WriteElement(elementName);
				if (xmlValue != null)
				{
					if (isSpecialValue)
					{
						this.WriteText(xmlValue, WriteTextOptions.LiteralStringSettings);
					}
					else
					{
						this.WriteAttribute("data", xmlValue, false, true);
						this.WriteAttribute("type", valueType);
					}
				}
				this.WriteEndElement();
			}
			private void RenderLiteralExpressionType(ILiteralExpression value)
			{
				object literalValue = value.Value;
				string valueType = null;
				if (literalValue != null)
				{
					switch (Type.GetTypeCode(literalValue.GetType()))
					{
						case TypeCode.Boolean:
							valueType = ".boolean";
							break;
						case TypeCode.Char:
							valueType = ".char";
							break;
						case TypeCode.DateTime:
							valueType = ".date";
							break;
						case TypeCode.Decimal:
							valueType = ".decimal";
							break;
						case TypeCode.SByte:
							valueType = ".i1";
							break;
						case TypeCode.Int16:
							valueType = ".i2";
							break;
						case TypeCode.Int32:
							valueType = ".i4";
							break;
						case TypeCode.Int64:
							valueType = ".i8";
							break;
						case TypeCode.Single:
							valueType = ".r4";
							break;
						case TypeCode.Double:
							valueType = ".r8";
							break;
						case TypeCode.String:
							valueType = ".string";
							break;
						case TypeCode.Byte:
							valueType = ".u1";
							break;
						case TypeCode.UInt16:
							valueType = ".u2";
							break;
						case TypeCode.UInt32:
							valueType = ".u4";
							break;
						case TypeCode.UInt64:
							valueType = ".u8";
							break;
					}
				}
				if (valueType != null)
				{
					this.WriteAttribute("dataTypeName", valueType);
				}
				else
				{
					this.WriteAttribute("dataTypeName", ".object");
				}
			}
			private void RenderConditionExpression(IConditionExpression value)
			{
				string elementName = "inlineStatement";
				this.WriteElement(elementName);
				this.RenderConditionExpressionType(value);
				this.WriteElement("conditionalOperator");
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElement("condition");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IExpression ThenChild = value.Then;
				if (ThenChild != null)
				{
					this.WriteElement("left");
					this.RenderExpression(ThenChild);
					this.WriteEndElement();
				}
				IExpression ElseChild = value.Else;
				if (ElseChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(ElseChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void RenderConditionExpressionType(IConditionExpression value)
			{
				IExpression thenClause = value.Then;
				IExpression elseClause = value.Else;
				this.RenderExpressionType(TestNullifyExpression(thenClause) ?? TestNullifyExpression(elseClause));
			}
			private void RenderDelegateCreateExpression(IDelegateCreateExpression value)
			{
				string elementName = "callNew";
				this.WriteElement(elementName);
				if (value.DelegateType != null)
				{
					this.RenderTypeReference(value.DelegateType);
				}
				this.WriteElement("passParam");
				this.RenderDelegateCreateExpressionPassParam(value);
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void RenderDelegateCreateExpressionType(IDelegateCreateExpression value)
			{
				ITypeReference targetType = value.DelegateType;
				if (targetType != null)
				{
					this.RenderTypeReference(targetType);
				}
			}
			private void RenderDelegateCreateExpressionPassParam(IDelegateCreateExpression value)
			{
				string elementName = "callInstance";
				IMethodReference member = value.Method;
				IExpression target = value.Target;
				ITypeReferenceExpression staticTypeReference = target as ITypeReferenceExpression;
				bool staticCall = staticTypeReference != null;
				bool thisCall = !(staticCall) && (target is IThisReferenceExpression);
				bool baseCall = !(thisCall) && (target is IBaseReferenceExpression);
				if (staticCall)
				{
					elementName = "callStatic";
				}
				else if (thisCall || baseCall)
				{
					elementName = "callThis";
				}
				this.WriteElement(elementName);
				this.WriteAttribute("name", member.Name);
				this.WriteAttribute("type", "methodReference");
				if (staticCall)
				{
					this.RenderTypeReferenceExpression(staticTypeReference);
				}
				else if (baseCall)
				{
					this.WriteAttribute("accessor", "base");
				}
				else if (!(thisCall))
				{
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("callObject");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
				}
				this.RenderGenericMemberArguments(member);
				this.WriteEndElement();
			}
			private void RenderMemberInitializerExpression(IMemberInitializerExpression value)
			{
				string elementName = "binaryOperator";
				this.WriteElement(elementName);
				this.WriteAttribute("type", "assignNamed");
				string propertyName = value.Member.Name;
				this.WriteElement("left");
				this.WriteElement("nameRef");
				this.WriteAttribute("name", propertyName);
				this.WriteAttribute("type", "namedParameter");
				this.WriteEndElement();
				this.WriteEndElement();
				IExpression ValueChild = value.Value;
				if (ValueChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(ValueChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderMethodReferenceExpressionType(IMethodReferenceExpression value)
			{
				IType targetType = value.Method.ReturnType.Type;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private bool RenderMethodReferenceExpression(IMethodReferenceExpression value, bool delayEndElement)
			{
				string elementName = "callInstance";
				IMethodReference member = value.Method;
				bool isDelegateInvoke = IsDelegateInvokeMethodReference(member);
				IExpression target = value.Target;
				ITypeReferenceExpression staticTypeReference = target as ITypeReferenceExpression;
				bool staticCall = staticTypeReference != null;
				bool thisCall = !(staticCall) && (target is IThisReferenceExpression);
				bool baseCall = !(thisCall) && (target is IBaseReferenceExpression);
				if (staticCall)
				{
					elementName = "callStatic";
				}
				else if (thisCall || baseCall)
				{
					elementName = "callThis";
				}
				this.WriteElement(elementName);
				string memberName;
				if (isDelegateInvoke)
				{
					memberName = ".implied";
				}
				else
				{
					memberName = member.Name;
					if ((thisCall || baseCall) && (memberName == ".ctor"))
					{
						memberName = ".implied";
					}
				}
				this.WriteAttribute("name", memberName, member.ToString(), member);
				if (isDelegateInvoke)
				{
					this.WriteAttribute("type", "delegateCall");
				}
				if (staticCall)
				{
					this.RenderTypeReferenceExpression(staticTypeReference);
				}
				else if (baseCall)
				{
					this.WriteAttribute("accessor", "base");
				}
				else if (!(thisCall))
				{
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("callObject");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
				}
				this.RenderGenericMemberArguments(member);
				if (delayEndElement)
				{
					return true;
				}
				else
				{
					this.WriteEndElement();
					return false;
				}
			}
			private void RenderInterfaceMember(IMemberReference value)
			{
				string elementName = "interfaceMember";
				this.WriteElement(elementName);
				string memberName = value.Name;
				this.WriteAttribute("memberName", memberName, value.ToString(), value);
				ITypeReference declaringType = value.DeclaringType as ITypeReference;
				if (declaringType != null)
				{
					ITypeDeclaration resolvedDeclaringType = declaringType.Resolve();
					if (resolvedDeclaringType != null)
					{
						ICustomAttributeCollection customAttributes = resolvedDeclaringType.Attributes;
						if (customAttributes.Count != 0)
						{
							foreach (ICustomAttribute testCustomAttribute in customAttributes)
							{
								ITypeReference attributeType = testCustomAttribute.Constructor.DeclaringType as ITypeReference;
								if (attributeType != null)
								{
									if ((attributeType.Name == "DefaultMemberAttribute") && (attributeType.Namespace == "System.Reflection"))
									{
										ILiteralExpression defaultMemberNameLiteral;
										string defaultMemberName;
										object literalValue;
										IExpressionCollection arguments = testCustomAttribute.Arguments;
										if (((((arguments.Count == 1) && ((defaultMemberNameLiteral = arguments[0] as ILiteralExpression) != null)) && (((literalValue = defaultMemberNameLiteral.Value) != null) && (Type.GetTypeCode(literalValue.GetType()) == TypeCode.String))) && (null != (defaultMemberName = (string)literalValue))) && (memberName == defaultMemberName))
										{
											this.WriteAttribute("defaultMember", "true");
										}
										break;
									}
								}
							}
						}
					}
				}
				if (declaringType != null)
				{
					this.RenderTypeReference(declaringType);
				}
				this.WriteEndElement();
			}
			private void RenderGenericMemberArguments(IGenericArgumentProvider value)
			{
				foreach (IType GenericArgumentsItem in value.GenericArguments)
				{
					this.WriteElement("passMemberTypeParam");
					this.RenderGenericArgument(GenericArgumentsItem);
					this.WriteEndElement();
				}
			}
			private void RenderMethodInvokeExpression(IMethodInvokeExpression value)
			{
				bool MethodDelayEndChildElement = false;
				IExpression MethodChild = value.Method;
				if (MethodChild != null)
				{
					MethodDelayEndChildElement = this.RenderExpression(MethodChild, true);
				}
				if (MethodDelayEndChildElement)
				{
					int argumentIndex = -1;
					IExpressionCollection arguments = value.Arguments;
					int lastArgumentIndex = arguments.Count - 1;
					foreach (IExpression argumentsItem in arguments)
					{
						++argumentIndex;
						if (argumentIndex == lastArgumentIndex)
						{
							bool argumentsItemDelayEndChildElement = false;
							if (argumentsItem != null)
							{
								argumentsItemDelayEndChildElement = this.RenderArrayCreateExpressionAsParamArray(argumentsItem, true, MethodChild, argumentIndex, null);
							}
							if (argumentsItemDelayEndChildElement)
							{
								this.WriteEndElement();
								break;
							}
						}
						this.WriteElement("passParam");
						this.RenderExpression(argumentsItem);
						this.WriteEndElement();
					}
					this.WriteEndElement();
				}
			}
			private void RenderMethodInvokeExpressionType(IMethodInvokeExpression value)
			{
				IExpression targetMethod = value.Method;
				this.RenderExpressionType(TestNullifyExpression(targetMethod));
			}
			private void RenderNullCoalescingExpression(INullCoalescingExpression value)
			{
				string elementName = "inlineStatement";
				this.WriteElement(elementName);
				this.RenderNullCoalescingExpressionType(value);
				this.WriteElement("nullFallbackOperator");
				IExpression ConditionChild = value.Condition;
				if (ConditionChild != null)
				{
					this.WriteElement("left");
					this.RenderExpression(ConditionChild);
					this.WriteEndElement();
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.WriteElement("right");
					this.RenderExpression(ExpressionChild);
					this.WriteEndElement();
				}
				this.WriteEndElement();
				this.WriteEndElement();
			}
			private void RenderNullCoalescingExpressionType(INullCoalescingExpression value)
			{
				IExpression thenClause = value.Condition;
				IExpression elseClause = value.Expression;
				this.RenderExpressionType(TestNullifyExpression(thenClause) ?? TestNullifyExpression(elseClause));
			}
			private void RenderObjectCreateExpression(IObjectCreateExpression value)
			{
				string elementName = "callNew";
				this.WriteElement(elementName);
				IType declaringType = value.Type;
				if (declaringType != null)
				{
					this.RenderType(declaringType);
				}
				IMethodReference ctorReference = value.Constructor;
				if (ctorReference != null)
				{
					this.RenderGenericMemberArguments(ctorReference);
					int argumentIndex = -1;
					IExpressionCollection arguments = value.Arguments;
					int lastArgumentIndex = arguments.Count - 1;
					foreach (IExpression argumentsItem in arguments)
					{
						++argumentIndex;
						if (argumentIndex == lastArgumentIndex)
						{
							bool argumentsItemDelayEndChildElement = false;
							if (argumentsItem != null)
							{
								argumentsItemDelayEndChildElement = this.RenderArrayCreateExpressionAsParamArray(argumentsItem, true, ctorReference, argumentIndex, null);
							}
							if (argumentsItemDelayEndChildElement)
							{
								this.WriteEndElement();
								break;
							}
						}
						this.WriteElement("passParam");
						this.RenderExpression(argumentsItem);
						this.WriteEndElement();
					}
				}
				this.WriteEndElement();
			}
			private void RenderObjectCreateExpressionType(IObjectCreateExpression value)
			{
				IType declaringType = value.Type;
				if (declaringType != null)
				{
					this.RenderType(declaringType);
				}
			}
			private void RenderPropertyIndexerExpression(IPropertyIndexerExpression value)
			{
				bool TargetDelayEndChildElement = false;
				IPropertyReferenceExpression TargetChild = value.Target;
				if (TargetChild != null)
				{
					TargetDelayEndChildElement = this.RenderPropertyReferenceExpression(TargetChild, true, true);
				}
				if (TargetDelayEndChildElement)
				{
					int argumentIndex = -1;
					IExpressionCollection arguments = value.Indices;
					int lastArgumentIndex = arguments.Count - 1;
					foreach (IExpression argumentsItem in arguments)
					{
						++argumentIndex;
						if (argumentIndex == lastArgumentIndex)
						{
							bool argumentsItemDelayEndChildElement = false;
							if (argumentsItem != null)
							{
								argumentsItemDelayEndChildElement = this.RenderArrayCreateExpressionAsParamArray(argumentsItem, true, TargetChild, argumentIndex, null);
							}
							if (argumentsItemDelayEndChildElement)
							{
								this.WriteEndElement();
								break;
							}
						}
						this.WriteElement("passParam");
						this.RenderExpression(argumentsItem);
						this.WriteEndElement();
					}
					this.WriteEndElement();
				}
			}
			private void RenderPropertyIndexerExpressionType(IPropertyIndexerExpression value)
			{
				IType propertyType = value.Target.Property.PropertyType;
				if (propertyType != null)
				{
					this.RenderType(propertyType);
				}
			}
			private bool RenderPropertyReferenceExpression(IPropertyReferenceExpression value, bool delayEndElement, bool isIndexer)
			{
				string elementName = "callInstance";
				IPropertyReference member = value.Property;
				IExpression target = value.Target;
				ITypeReferenceExpression staticTypeReference = target as ITypeReferenceExpression;
				bool staticCall = staticTypeReference != null;
				bool thisCall = !(staticCall) && (target is IThisReferenceExpression);
				bool baseCall = !(thisCall) && (target is IBaseReferenceExpression);
				if (staticCall)
				{
					elementName = "callStatic";
				}
				else if (thisCall || baseCall)
				{
					elementName = "callThis";
				}
				this.WriteElement(elementName);
				if (isIndexer)
				{
					this.WriteAttribute("name", ".implied", member.ToString(), member);
					this.WriteAttribute("type", "indexerCall");
				}
				else
				{
					this.WriteAttribute("name", member.Name, member.ToString(), member);
					this.WriteAttribute("type", "property");
				}
				if (staticCall)
				{
					this.RenderTypeReferenceExpression(staticTypeReference);
				}
				else if (baseCall)
				{
					this.WriteAttribute("accessor", "base");
				}
				else if (!(thisCall))
				{
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("callObject");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
				}
				if (delayEndElement)
				{
					return true;
				}
				else
				{
					this.WriteEndElement();
					return false;
				}
			}
			private void RenderPropertyReferenceExpressionType(IPropertyReferenceExpression value)
			{
				IType propertyType = value.Property.PropertyType;
				if (propertyType != null)
				{
					this.RenderType(propertyType);
				}
			}
			private void RenderThisReferenceExpression(IThisReferenceExpression value)
			{
				string elementName = "thisKeyword";
				this.WriteElement(elementName);
				this.WriteEndElement();
			}
			private void RenderThisReferenceExpressionType(IThisReferenceExpression value)
			{
				IType declaringType = this.myCurrentMethodDeclaration.DeclaringType;
				if (declaringType != null)
				{
					this.RenderType(declaringType);
				}
			}
			private void RenderTryCastExpression(ITryCastExpression value)
			{
				string elementName = "cast";
				this.WriteElement(elementName);
				this.WriteAttribute("type", "testCast");
				IType TargetTypeChild = value.TargetType;
				if (TargetTypeChild != null)
				{
					this.RenderType(TargetTypeChild);
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
				this.WriteEndElement();
			}
			private void RenderTryCastExpressionType(ITryCastExpression value)
			{
				IType targetType = value.TargetType;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderTypeOfExpression(ITypeOfExpression value)
			{
				string elementName = "typeOf";
				this.WriteElement(elementName);
				IType TypeChild = value.Type;
				if (TypeChild != null)
				{
					this.RenderType(TypeChild);
				}
				this.WriteEndElement();
			}
			private void RenderTypeOfExpressionType(ITypeOfExpression value)
			{
				IType targetType = value.Type;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderTypeReferenceExpression(ITypeReferenceExpression value)
			{
				ITypeReference TypeChild = value.Type;
				if (TypeChild != null)
				{
					this.RenderTypeReference(TypeChild);
				}
			}
			private void RenderTypeReferenceExpressionType(ITypeReferenceExpression value)
			{
				ITypeReference targetType = value.Type;
				if (targetType != null)
				{
					this.RenderTypeReference(targetType);
				}
			}
			private void RenderVariableDeclarationExpression(IVariableDeclarationExpression value)
			{
				IVariableDeclaration VariableChild = value.Variable;
				if (VariableChild != null)
				{
					this.WriteElement("local");
					this.RenderVariableDeclaration(VariableChild);
					this.WriteEndElement();
				}
			}
			private void RenderVariableDeclarationExpressionType(IVariableDeclarationExpression value)
			{
				IType targetType = value.Variable.VariableType;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderVariableReferenceExpression(IVariableReferenceExpression value)
			{
				string elementName = "nameRef";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.Variable.Resolve().Name);
				this.WriteEndElement();
			}
			private void RenderVariableReferenceExpressionType(IVariableReferenceExpression value)
			{
				IVariableReference targetReference = value.Variable;
				IType targetType = targetReference.Resolve().VariableType;
				if (targetType != null)
				{
					this.RenderType(targetType);
				}
			}
			private void RenderUnaryExpression(IUnaryExpression value, bool topLevel)
			{
				string elementName = "unaryOperator";
				UnaryOperator operatorType = value.Operator;
				bool renderInline = false;
				if (!(topLevel))
				{
					switch (operatorType)
					{
						case UnaryOperator.PreIncrement:
						case UnaryOperator.PostIncrement:
						case UnaryOperator.PreDecrement:
						case UnaryOperator.PostDecrement:
							renderInline = true;
							break;
					}
				}
				if (renderInline)
				{
					this.WriteElement("inlineStatement");
					this.RenderUnaryExpressionType(value);
				}
				switch (operatorType)
				{
					case UnaryOperator.PreIncrement:
						elementName = "increment";
						break;
					case UnaryOperator.PostIncrement:
						elementName = "increment";
						break;
					case UnaryOperator.PreDecrement:
						elementName = "decrement";
						break;
					case UnaryOperator.PostDecrement:
						elementName = "decrement";
						break;
				}
				this.WriteElement(elementName);
				string typeAttributeValue = "";
				switch (operatorType)
				{
					case UnaryOperator.BitwiseNot:
						typeAttributeValue = "bitwiseNot";
						break;
					case UnaryOperator.BooleanNot:
						typeAttributeValue = "booleanNot";
						break;
					case UnaryOperator.Negate:
						typeAttributeValue = "negative";
						break;
					case UnaryOperator.PostIncrement:
					case UnaryOperator.PostDecrement:
						if (!(topLevel))
						{
							typeAttributeValue = "post";
						}
						break;
				}
				if (typeAttributeValue.Length != 0)
				{
					this.WriteAttribute("type", typeAttributeValue);
				}
				IExpression ExpressionChild = value.Expression;
				if (ExpressionChild != null)
				{
					this.RenderExpression(ExpressionChild);
				}
				if (renderInline)
				{
					this.WriteEndElement();
				}
				this.WriteEndElement();
			}
			private void RenderUnaryExpressionType(IUnaryExpression value)
			{
				string dataTypeNameAttributeValue = "";
				switch (value.Operator)
				{
					case UnaryOperator.BooleanNot:
						dataTypeNameAttributeValue = ".boolean";
						break;
				}
				if (dataTypeNameAttributeValue.Length != 0)
				{
					this.WriteAttribute("dataTypeName", dataTypeNameAttributeValue);
				}
				else
				{
					IExpression expression = value.Expression;
					this.RenderExpressionType(TestNullifyExpression(expression));
				}
			}
			private void RenderUnhandledExpression(IExpression value)
			{
				string elementName = "UNHANDLED_EXPRESSION";
				this.WriteElement(elementName);
				this.WriteAttribute("name", value.GetType().Name);
				this.WriteEndElement();
			}
			private void RenderUnhandledExpressionType(IExpression value)
			{
				this.WriteAttribute("dataTypeName", string.Concat("UNHANDLED_ExpressionType_", value.GetType().Name));
			}
			private void RenderAssignExpression(IAssignExpression value, bool topLevel)
			{
				if (!(topLevel))
				{
					this.WriteElement("inlineStatement");
					this.RenderAssignExpressionType(value);
				}
				IVariableDeclarationExpression targetVariableDeclaration = value.Target as IVariableDeclarationExpression;
				if (targetVariableDeclaration != null)
				{
					this.WriteElement("local");
					this.RenderVariableDeclaration(targetVariableDeclaration.Variable);
					IExpression ExpressionChild = value.Expression;
					if (ExpressionChild != null)
					{
						this.WriteElement("initialize");
						this.RenderExpression(ExpressionChild);
						this.WriteEndElement();
					}
					this.WriteEndElement();
				}
				else
				{
					this.WriteElement("assign");
					IExpression TargetChild = value.Target;
					if (TargetChild != null)
					{
						this.WriteElement("left");
						this.RenderExpression(TargetChild);
						this.WriteEndElement();
					}
					IExpression ExpressionChild = value.Expression;
					if (ExpressionChild != null)
					{
						this.WriteElement("right");
						this.RenderExpression(ExpressionChild);
						this.WriteEndElement();
					}
					this.WriteEndElement();
				}
				if (!(topLevel))
				{
					this.WriteEndElement();
				}
			}
			private void RenderAssignExpressionType(IAssignExpression value)
			{
				IExpression leftClause = value.Target;
				IExpression rightClause = value.Expression;
				this.RenderExpressionType(TestNullifyExpression(leftClause) ?? TestNullifyExpression(rightClause));
			}
			private void RenderVariableDeclaration(IVariableDeclaration value)
			{
				this.WriteAttribute("name", value.Name, true, false);
				if (value.VariableType != null)
				{
					this.RenderType(value.VariableType);
				}
			}
			private void RenderParameterDeclaration(IParameterDeclaration value)
			{
				this.WriteAttribute("name", value.Name, true, false);
				IType parameterType = value.ParameterType;
				ICustomAttributeCollection customAttributes = value.Attributes;
				int paramsAttributeIndex = -1;
				int outAttributeIndex = -1;
				if (customAttributes.Count != 0)
				{
					int attributeIndex = 0;
					foreach (ICustomAttribute testCustomAttribute in customAttributes)
					{
						ITypeReference attributeType = testCustomAttribute.Constructor.DeclaringType as ITypeReference;
						if (attributeType != null)
						{
							if ((attributeType.Name == "ParamArrayAttribute") && (attributeType.Namespace == "System"))
							{
								paramsAttributeIndex = attributeIndex;
								break;
							}
							if ((attributeType.Name == "OutAttribute") && (attributeType.Namespace == "System.Runtime.InteropServices"))
							{
								outAttributeIndex = attributeIndex;
								break;
							}
						}
						++attributeIndex;
					}
				}
				bool isReferenceType = parameterType is IReferenceType;
				string typeAttributeValue = "";
				if (outAttributeIndex != -1)
				{
					typeAttributeValue = "out";
				}
				else if (isReferenceType)
				{
					typeAttributeValue = "inOut";
				}
				else if (paramsAttributeIndex != -1)
				{
					typeAttributeValue = "params";
				}
				if (typeAttributeValue.Length != 0)
				{
					this.WriteAttribute("type", typeAttributeValue);
				}
				if (parameterType != null)
				{
					this.RenderType(parameterType);
				}
				int customAttributeIndex = -1;
				foreach (ICustomAttribute customAttributesItem in customAttributes)
				{
					++customAttributeIndex;
					if ((customAttributeIndex == paramsAttributeIndex) || (customAttributeIndex == outAttributeIndex))
					{
						continue;
					}
					this.RenderCustomAttribute(customAttributesItem);
				}
			}
			private void RenderType(IType value)
			{
				ITypeReference AsITypeReference = value as ITypeReference;
				if (AsITypeReference != null)
				{
					this.RenderTypeReference(AsITypeReference);
				}
				else
				{
					IArrayType AsIArrayType = value as IArrayType;
					if (AsIArrayType != null)
					{
						this.RenderArrayType(AsIArrayType);
					}
					else
					{
						IGenericParameter AsIGenericParameter = value as IGenericParameter;
						if (AsIGenericParameter != null)
						{
							this.RenderGenericParameterName(AsIGenericParameter);
						}
						else
						{
							IGenericArgument AsIGenericArgument = value as IGenericArgument;
							if (AsIGenericArgument != null)
							{
								this.RenderGenericArgument(AsIGenericArgument);
							}
							else
							{
								IReferenceType AsIReferenceType = value as IReferenceType;
								if (AsIReferenceType != null)
								{
									this.RenderReferenceType(AsIReferenceType);
								}
								else
								{
									IRequiredModifier AsIRequiredModifier = value as IRequiredModifier;
									if (AsIRequiredModifier != null)
									{
										this.RenderRequiredModifierType(AsIRequiredModifier);
									}
									else
									{
										IOptionalModifier AsIOptionalModifier = value as IOptionalModifier;
										if (AsIOptionalModifier != null)
										{
											this.RenderOptionalModifierType(AsIOptionalModifier);
										}
									}
								}
							}
						}
					}
				}
			}
			private void RenderReferenceType(IReferenceType value)
			{
				IType elementType = value.ElementType;
				if (elementType != null)
				{
					this.RenderType(elementType);
				}
			}
			private void RenderRequiredModifierType(IRequiredModifier value)
			{
				IType elementType = value.ElementType;
				if (elementType != null)
				{
					this.RenderType(elementType);
				}
			}
			private void RenderOptionalModifierType(IOptionalModifier value)
			{
				IType elementType = value.ElementType;
				if (elementType != null)
				{
					this.RenderType(elementType);
				}
			}
			private static bool IsVoidType(IType type)
			{
				ITypeReference typeReference = type as ITypeReference;
				return (typeReference != null) && ((typeReference.Namespace == "System") && (typeReference.Name == "Void"));
			}
			private static bool IsObjectType(IType type)
			{
				ITypeReference typeReference = type as ITypeReference;
				return (typeReference != null) && ((typeReference.Namespace == "System") && (typeReference.Name == "Object"));
			}
			private static bool IsValueTypeType(IType type)
			{
				ITypeReference typeReference = type as ITypeReference;
				return (typeReference != null) && ((typeReference.Namespace == "System") && (typeReference.Name == "ValueType"));
			}
			private void RenderArrayType(IArrayType value)
			{
				IType elementType;
				Queue<IArrayDimensionCollection> dimensionsQueue = ResolveArrayDimensions(value, out elementType);
				bool isSimpleArray = dimensionsQueue == null;
				if (!(isSimpleArray) && (dimensionsQueue.Count == 1))
				{
					IArrayDimensionCollection firstDimensions = dimensionsQueue.Peek();
					if (firstDimensions.Count == 1)
					{
						IArrayDimension firstDimension = firstDimensions[0];
						isSimpleArray = (firstDimension.LowerBound == 0) && (firstDimension.UpperBound == -1);
					}
				}
				string dataTypeIsSimpleArrayAttributeValue = "";
				if (isSimpleArray)
				{
					dataTypeIsSimpleArrayAttributeValue = "true";
				}
				if (dataTypeIsSimpleArrayAttributeValue.Length != 0)
				{
					this.WriteAttribute("dataTypeIsSimpleArray", dataTypeIsSimpleArrayAttributeValue);
				}
				if (elementType != null)
				{
					this.RenderType(elementType);
				}
				if (!(isSimpleArray))
				{
					IArrayDimensionCollection currentDimensions = dimensionsQueue.Dequeue();
					this.RenderArrayDimensions(currentDimensions, dimensionsQueue);
				}
			}
			private void RenderArrayDimensions(IArrayDimensionCollection currentDimensions, Queue<IArrayDimensionCollection> remainingDimensions)
			{
				this.WriteElement("arrayDescriptor");
				int rank = currentDimensions.Count;
				if (rank == 0)
				{
					this.WriteAttribute("rank", "1");
				}
				else
				{
					this.WriteAttribute("rank", XmlConvert.ToString(rank));
				}
				if (remainingDimensions.Count != 0)
				{
					IArrayDimensionCollection nextDimensions = remainingDimensions.Dequeue();
					this.RenderArrayDimensions(nextDimensions, remainingDimensions);
				}
				this.WriteEndElement();
			}
			private static string MapKnownSystemType(ITypeReference typeReference)
			{
				string retVal = null;
				if (typeReference.Namespace == "System")
				{
					string typeName = typeReference.Name;
					switch (typeName.Length)
					{
						case 4:
							if (typeName == "Byte")
							{
								retVal = "u1";
							}
							else if (typeName == "Char")
							{
								retVal = "char";
							}
							break;
						case 5:
							if (typeName == "Int16")
							{
								retVal = "i2";
							}
							else if (typeName == "Int32")
							{
								retVal = "i4";
							}
							else if (typeName == "Int64")
							{
								retVal = "i8";
							}
							else if (typeName == "SByte")
							{
								retVal = "i1";
							}
							break;
						case 6:
							if (typeName == "Double")
							{
								retVal = "r8";
							}
							else if (typeName == "Object")
							{
								retVal = "object";
							}
							else if (typeName == "Single")
							{
								retVal = "r4";
							}
							else if (typeName == "String")
							{
								retVal = "string";
							}
							else if (typeName == "UInt16")
							{
								retVal = "u2";
							}
							else if (typeName == "UInt32")
							{
								retVal = "u4";
							}
							else if (typeName == "UInt64")
							{
								retVal = "u8";
							}
							break;
						case 7:
							if (typeName == "Boolean")
							{
								retVal = "boolean";
							}
							else if (typeName == "Decimal")
							{
								retVal = "decimal";
							}
							break;
						case 8:
							if (typeName == "DateTime")
							{
								retVal = "date";
							}
							break;
					}
				}
				return retVal;
			}
			private void RenderTypeReferenceWithoutGenerics(ITypeReference value)
			{
				string dataTypeName = value.Name;
				string displayDataTypeName = dataTypeName;
				string knownTypeName = MapKnownSystemType(value);
				if (knownTypeName != null)
				{
					displayDataTypeName = string.Concat(".", knownTypeName);
				}
				this.WriteAttribute("dataTypeName", displayDataTypeName, string.Concat(value.Namespace, ".", dataTypeName), value);
				ITypeReference parametrizedQualifier = null;
				if (knownTypeName == null)
				{
					string resolvedNamespace = value.Namespace;
					if (string.IsNullOrEmpty(resolvedNamespace))
					{
						ITypeReference owningType = value.Owner as ITypeReference;
						if (owningType != null)
						{
							if (IsGenericTypeReference(owningType))
							{
								parametrizedQualifier = owningType;
							}
							else
							{
								string lastNamespace = null;
								do
								{
									if (string.IsNullOrEmpty(resolvedNamespace))
									{
										resolvedNamespace = owningType.Name;
									}
									else
									{
										resolvedNamespace = string.Concat(owningType.Name, ".", resolvedNamespace);
									}
									lastNamespace = owningType.Namespace;
									owningType = owningType.Owner as ITypeReference;
								} while (owningType != null);
								if (!(string.IsNullOrEmpty(lastNamespace)))
								{
									resolvedNamespace = string.Concat(lastNamespace, ".", resolvedNamespace);
								}
							}
						}
					}
					if (!(string.IsNullOrEmpty(resolvedNamespace)))
					{
						string contextQualifier = this.myContextDataTypeQualifier;
						if (contextQualifier != null)
						{
							int qualifierLength = contextQualifier.Length;
							int resolvedLength = resolvedNamespace.Length;
							if ((qualifierLength <= resolvedLength) && resolvedNamespace.StartsWith(contextQualifier))
							{
								if (qualifierLength == resolvedLength)
								{
									resolvedNamespace = null;
								}
								else if (resolvedNamespace[qualifierLength] == '.')
								{
									resolvedNamespace = resolvedNamespace.Substring(qualifierLength + 1);
								}
							}
							if (!(string.IsNullOrEmpty(resolvedNamespace)))
							{
								this.WriteAttribute("dataTypeQualifier", resolvedNamespace);
							}
						}
						else
						{
							this.WriteAttribute("dataTypeQualifier", resolvedNamespace);
						}
					}
				}
				if (parametrizedQualifier != null)
				{
					this.WriteElementDelayed("parametrizedDataTypeQualifier");
					this.RenderTypeReference(parametrizedQualifier);
					this.WriteEndElement();
				}
			}
			private void RenderTypeReference(ITypeReference value)
			{
				this.RenderTypeReferenceWithoutGenerics(value);
				bool isUnboundGeneric = value.GenericType == null;
				IGenericArgumentProvider ownerGenericArgumentProvider = value.Owner as IGenericArgumentProvider;
				ITypeCollection ownerGenericArguments = null;
				if (ownerGenericArgumentProvider != null)
				{
					ownerGenericArguments = ownerGenericArgumentProvider.GenericArguments;
					if (ownerGenericArguments.Count == 0)
					{
						ownerGenericArguments = null;
					}
				}
				foreach (IType GenericArgumentsItem in value.GenericArguments)
				{
					if ((ownerGenericArguments != null) && ownerGenericArguments.Contains(GenericArgumentsItem))
					{
						continue;
					}
					if (isUnboundGeneric)
					{
						this.WriteElement("passTypeParam");
						this.WriteAttribute("dataTypeName", ".unspecifiedTypeParam");
						this.WriteEndElement();
						continue;
					}
					this.WriteElement("passTypeParam");
					this.RenderGenericArgument(GenericArgumentsItem);
					this.WriteEndElement();
				}
			}
			private void RenderGenericArgument(IType value)
			{
				if (value != null)
				{
					this.RenderType(value);
				}
			}
			private void RenderGenericArgument(IGenericArgument value)
			{
				if (value.Owner.GenericArguments[value.Position] != null)
				{
					this.RenderType(value.Owner.GenericArguments[value.Position]);
				}
			}
			private void RenderGenericParameterName(IGenericParameter value)
			{
				this.WriteAttribute("dataTypeName", value.Name);
			}
			private void RenderGenericParameterDeclaration(IGenericParameter value)
			{
				this.WriteAttribute("name", value.Name, true, false);
				bool isReferenceType = false;
				bool isDefaultConstructorType = false;
				bool isValueType = false;
				foreach (IType constraint in value.Constraints)
				{
					if (constraint is IReferenceTypeConstraint)
					{
						isReferenceType = true;
					}
					else if (constraint is IValueTypeConstraint)
					{
						isValueType = true;
					}
					else if (constraint is IDefaultConstructorConstraint)
					{
						isDefaultConstructorType = true;
					}
				}
				string requireReferenceTypeAttributeValue = "";
				if (isReferenceType)
				{
					requireReferenceTypeAttributeValue = "true";
				}
				if (requireReferenceTypeAttributeValue.Length != 0)
				{
					this.WriteAttribute("requireReferenceType", requireReferenceTypeAttributeValue);
				}
				string requireValueTypeAttributeValue = "";
				if (isValueType)
				{
					requireValueTypeAttributeValue = "true";
				}
				if (requireValueTypeAttributeValue.Length != 0)
				{
					this.WriteAttribute("requireValueType", requireValueTypeAttributeValue);
				}
				string requireDefaultConstructorAttributeValue = "";
				if (isDefaultConstructorType && !(isValueType))
				{
					requireDefaultConstructorAttributeValue = "true";
				}
				if (requireDefaultConstructorAttributeValue.Length != 0)
				{
					this.WriteAttribute("requireDefaultConstructor", requireDefaultConstructorAttributeValue);
				}
				foreach (IType ConstraintsItem in value.Constraints)
				{
					this.WriteElementDelayed("typeConstraint");
					this.RenderConstraintType(ConstraintsItem);
					this.WriteEndElement();
				}
			}
			private void RenderConstraintType(IType value)
			{
				if (!(IsValueTypeType(value)))
				{
					this.RenderType(value);
				}
			}
		}
	}
}
