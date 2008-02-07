/**************************************************************************\
* Neumont PLiX (Programming Language in XML) Code Generator                *
*                                                                          *
* Copyright © Neumont University and Matthew Curland. All rights reserved. *
*                                                                          *
* The use and distribution terms for this software are covered by the      *
* Common Public License 1.0 (http://opensource.org/licenses/cpl) which     *
* can be found in the file CPL.txt at the root of this distribution.       *
* By using this software in any fashion, you are agreeing to be bound by   *
* the terms of this license.                                               *
*                                                                          *
* You must not remove this notice, or any other, from this software.       *
\**************************************************************************/
using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Xml;
using Reflector;
using Reflector.CodeModel;
using System.Collections;
using System.Globalization;

namespace Reflector
{
	#region PLiXLanguage class
	/// <summary>
	/// The PLiX language for the reflector language dropdown
	/// </summary>
	public partial class PLiXLanguage : ILanguage
	{
		#region CustomAttributeTarget enum
		/// <summary>
		/// Custom attribute targets corresponding to plix values
		/// </summary>
		private enum CustomAttributeTarget
		{
			/// <summary>
			/// Attribute target is implicit from the context
			/// </summary>
			None,
			/// <summary>
			/// An assembly attribute
			/// </summary>
			Assembly,
			/// <summary>
			/// A module attribute
			/// </summary>
			Module,
			/// <summary>
			/// An attribute for an implicit field, used with simple events
			/// </summary>
			ImplicitField,
			/// <summary>
			/// An attribute for implicit accessor functions, used with simple events
			/// </summary>
			ImplicitAccessorFunction,
			/// <summary>
			/// An attribute for implicit value parameters, used with set/onAdd/onRemove
			/// accessor functions
			/// </summary>
			ImplicitValueParameter,
		}
		#endregion // CustomAttributeTarget enum
		#region Member Variables
		private ITranslatorManager myTranslatorManager;
		private PLiXLanguageWriter myWriter;
		private IPLiXConfiguration myConfiguration;
		#endregion // Member Variables
		#region Constructors
		/// <summary>
		/// Create a new PLiXLanguage class
		/// </summary>
		/// <param name="translatorManager">The <see cref="ITranslatorManager"/> provided by Reflector</param>
		/// <param name="configuration">The <see cref="IPLiXConfiguration"/> implementation provided by the <see cref="PLiXLanguagePackage"/></param>
		public PLiXLanguage(ITranslatorManager translatorManager, IPLiXConfiguration configuration)
		{
			myTranslatorManager = translatorManager;
			myConfiguration = configuration;
		}
		#endregion // Constructors
		#region Methods
		/// <summary>
		/// Simple callback method for notifying refresh
		/// </summary>
		public void OnRefresh()
		{
			PLiXLanguageWriter writer = myWriter;
			if (writer != null)
			{
				writer.OnRefresh();
			}
		}
		#endregion // Methods
		#region ILanguage Implementation
		/// <summary>
		/// Implements <see cref="ILanguage.FileExtension"/>
		/// </summary>
		protected static string FileExtension
		{
			get
			{
				return ".xml";
			}
		}
		string ILanguage.FileExtension
		{
			get
			{
				return FileExtension;
			}
		}
		/// <summary>
		/// Implements <see cref="ILanguage.GetWriter"/>
		/// </summary>
		protected ILanguageWriter GetWriter(IFormatter formatter, ILanguageWriterConfiguration configuration)
		{
			PLiXLanguageWriter retVal = myWriter;
			if (retVal == null)
			{
				myWriter = retVal = new PLiXLanguageWriter(myTranslatorManager.CreateDisassembler(null, null), myConfiguration);
			}
			retVal.Associate(formatter, configuration);
			return retVal;
		}
		ILanguageWriter ILanguage.GetWriter(IFormatter formatter, ILanguageWriterConfiguration configuration)
		{
			return GetWriter(formatter, configuration);
		}
		/// <summary>
		/// Implements <see cref="ILanguage.Name"/>
		/// </summary>
		protected static string Name
		{
			get
			{
				return "PLiX";
			}
		}
		string ILanguage.Name
		{
			get
			{
				return Name;
			}
		}
		/// <summary>
		/// Implements <see cref="ILanguage.Translate"/>.
		/// Returns false so that we can make our own translate
		/// requests explicitly.
		/// </summary>
		protected static bool Translate
		{
			get
			{
				return false;
			}
		}
		bool ILanguage.Translate
		{
			get
			{
				return Translate;
			}
		}
		#endregion // ILanguage Implementation
		#region PLiXLanguageWriter class
		/// <summary>
		/// PLiX Language Writer
		/// </summary>
		private partial class PLiXLanguageWriter : ILanguageWriter
		{
			#region Member Variables
			private IFormatter myFormatter;
			private ILanguageWriterConfiguration myWriterConfiguration;
			private IPLiXConfiguration myPLiXConfiguration;
			private Stack<string> myOpenElements;
			private bool myCurrentElementIsOpen;
			private bool myCurrentElementIsComment;
			private bool myCurrentElementClosedForText;
			private bool myFirstWrite;
			private string myDelayWriteElement;
			private ITranslator myTranslator;
			private bool myShowDocumentation;
			private bool myShowCustomAttributes;
			private string myContextDataTypeQualifier;
			private IMethodBody myCurrentMethodBody;
			private string myValueParameterName;
			private IMethodDeclaration myCurrentMethodDeclaration;
			private StringBuilder myEscapeTextStringBuilder;
			private StringWriter myEscapeTextStringWriter;
			private XmlTextWriter myEscapeTextXmlWriter;
			private MemberMapper myMemberMap;
			#endregion // Member Variables
			#region Constructors
			public PLiXLanguageWriter(ITranslator translator, IPLiXConfiguration configuration)
			{
				myTranslator = translator;
				myOpenElements = new Stack<string>();
				myPLiXConfiguration = configuration;
				myMemberMap = new MemberMapper(translator);
			}
			#endregion // Constructors
			#region Methods
			/// <summary>
			/// Associate this writer with the specified formatter and configuration settings
			/// </summary>
			public void Associate(IFormatter formatter, ILanguageWriterConfiguration configuration)
			{
				myFormatter = formatter;
				myWriterConfiguration = configuration;
				myShowCustomAttributes = configuration["ShowCustomAttributes"] == "true";
				myShowDocumentation = configuration["ShowDocumentation"] == "true";
			}
			/// <summary>
			/// Release any cached information
			/// </summary>
			public void OnRefresh()
			{
				myMemberMap.ClearCache();
			}
			#endregion // Methods
			#region ILanguageWriter Implementation
			/// <summary>
			///  Implements ILanguageWriter.WriteAssembly
			/// </summary>
			protected void WriteAssembly(IAssembly value)
			{
				bool detailedForm = myShowCustomAttributes;
				PrepareForWrite(detailedForm, null);
				if (detailedForm)
				{
					value = myTranslator.TranslateAssembly(value, false);
				}
				Render(value);
				if (!detailedForm)
				{
					myFormatter.WriteProperty("Location", value.Location);
					myFormatter.WriteProperty("Name", value.ToString());
					myFormatter.WriteProperty("Type", value.Type.ToString());
				}
			}
			void ILanguageWriter.WriteAssembly(IAssembly value)
			{
				WriteAssembly(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteAssemblyReference
			/// </summary>
			protected void WriteAssemblyReference(IAssemblyReference value)
			{
				bool detailedForm = myShowCustomAttributes;
				PrepareForWrite(detailedForm, null);
				if (detailedForm)
				{
					value = myTranslator.TranslateAssemblyReference(value);
				}
				Render(value);
				if (!detailedForm)
				{
					myFormatter.WriteProperty("Name", value.Name);
					myFormatter.WriteProperty("Version", value.ToString());
				}
			}
			void ILanguageWriter.WriteAssemblyReference(IAssemblyReference value)
			{
				WriteAssemblyReference(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteEventDeclaration
			/// </summary>
			protected void WriteEventDeclaration(IEventDeclaration value)
			{
				InterfaceMemberInfo interfaceMemberInfo = myMemberMap.GetInterfaceMemberInfo(value);
				if (interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation)
				{
					foreach (IEventDeclaration deferTo in interfaceMemberInfo.InterfaceMemberCollection)
					{
						WriteEventDeclaration(deferTo);
					}
					return;
				}
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : GetDataTypeQualifier(value.DeclaringType));
				Render(value, interfaceMemberInfo, detailedForm);
				if (!detailedForm)
				{
					WriteTypeReferenceProperties(value.DeclaringType as ITypeReference, "Declaring Type");
				}
			}
			void ILanguageWriter.WriteEventDeclaration(IEventDeclaration value)
			{
				WriteEventDeclaration(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteExpression
			/// </summary>
			protected void WriteExpression(IExpression value)
			{
				// UNDONE: WriteExpression
			}
			void ILanguageWriter.WriteExpression(IExpression value)
			{
				WriteExpression(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteFieldDeclaration
			/// </summary>
			protected void WriteFieldDeclaration(IFieldDeclaration value)
			{
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : GetDataTypeQualifier(value.DeclaringType));
				if (detailedForm)
				{
					value = myTranslator.TranslateFieldDeclaration(value);
				}
				Render(value);
				if (!detailedForm)
				{
					WriteTypeReferenceProperties(value.DeclaringType as ITypeReference, "Declaring Type");
				}
			}
			void ILanguageWriter.WriteFieldDeclaration(IFieldDeclaration value)
			{
				WriteFieldDeclaration(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteMethodDeclaration
			/// </summary>
			protected void WriteMethodDeclaration(IMethodDeclaration value)
			{
				InterfaceMemberInfo interfaceMemberInfo = myMemberMap.GetInterfaceMemberInfo(value);
				if (interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation)
				{
					foreach (IMethodDeclaration deferTo in interfaceMemberInfo.InterfaceMemberCollection)
					{
						WriteMethodDeclaration(deferTo);
					}
					return;
				}
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : GetDataTypeQualifier(value.DeclaringType));
				Render(value, interfaceMemberInfo, detailedForm);
				if (!detailedForm)
				{
					WriteTypeReferenceProperties(value.DeclaringType as ITypeReference, "Declaring Type");
				}
			}
			void ILanguageWriter.WriteMethodDeclaration(IMethodDeclaration value)
			{
				WriteMethodDeclaration(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteModule
			/// </summary>
			protected void WriteModule(IModule value)
			{
				bool detailedForm = myShowCustomAttributes;
				PrepareForWrite(detailedForm, null);
				Render(value);
				if (!detailedForm)
				{
					myFormatter.WriteProperty("Version", value.Version.ToString());
					string location = value.Location;
					myFormatter.WriteProperty("Location", value.Location);
					location = Environment.ExpandEnvironmentVariables(location);
					if (File.Exists(location))
					{
						myFormatter.WriteProperty("Size", (new FileInfo(location)).Length.ToString("N0") + " Bytes");
					}
				}
			}
			void ILanguageWriter.WriteModule(IModule value)
			{
				WriteModule(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteModuleReference
			/// </summary>
			protected void WriteModuleReference(IModuleReference value)
			{
				bool detailedForm = myShowCustomAttributes;
				PrepareForWrite(detailedForm, null);
				if (detailedForm)
				{
					value = myTranslator.TranslateModuleReference(value);
				}
				Render(value);
			}
			void ILanguageWriter.WriteModuleReference(IModuleReference value)
			{
				WriteModuleReference(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteNamespace
			/// </summary>
			protected void WriteNamespace(INamespace value)
			{
				bool detailedForm = myWriterConfiguration["ShowNamespaceBody"] == "true";
				bool fullExpansion = myPLiXConfiguration.FullyExpandNamespaceDeclarations;
				bool typeDeclarationBody = detailedForm && (fullExpansion || myWriterConfiguration["ShowTypeDeclarationBody"] == "true");
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : value.Name);
				Render(value, detailedForm, typeDeclarationBody, detailedForm && fullExpansion);
			}
			void ILanguageWriter.WriteNamespace(INamespace value)
			{
				WriteNamespace(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WritePropertyDeclaration
			/// </summary>
			protected void WritePropertyDeclaration(IPropertyDeclaration value)
			{
				InterfaceMemberInfo interfaceMemberInfo = myMemberMap.GetInterfaceMemberInfo(value);
				if (interfaceMemberInfo.Style == InterfaceMemberStyle.DeferredExplicitImplementation)
				{
					foreach (IPropertyDeclaration deferTo in interfaceMemberInfo.InterfaceMemberCollection)
					{
						WritePropertyDeclaration(deferTo);
					}
					return;
				}
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : GetDataTypeQualifier(value.DeclaringType));
				Render(value, interfaceMemberInfo, detailedForm);
				if (!detailedForm)
				{
					WriteTypeReferenceProperties(value.DeclaringType as ITypeReference, "Declaring Type");
				}
			}
			void ILanguageWriter.WritePropertyDeclaration(IPropertyDeclaration value)
			{
				WritePropertyDeclaration(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteResource
			/// </summary>
			protected void WriteResource(IResource value)
			{
				// UNDONE: WriteResource
			}
			void ILanguageWriter.WriteResource(IResource value)
			{
				WriteResource(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteStatement
			/// </summary>
			protected void WriteStatement(IStatement value)
			{
				// UNDONE: WriteStatement
			}
			void ILanguageWriter.WriteStatement(IStatement value)
			{
				WriteStatement(value);
			}
			/// <summary>
			///  Implements ILanguageWriter.WriteTypeDeclaration
			/// </summary>
			protected void WriteTypeDeclaration(ITypeDeclaration value)
			{
				bool detailedForm = myWriterConfiguration["ShowTypeDeclarationBody"] == "true";
				PrepareForWrite(detailedForm, myPLiXConfiguration.DisplayContextDataTypeQualifier ? null : GetDataTypeQualifier(value));
				Render(value, detailedForm, detailedForm && (myPLiXConfiguration.FullyExpandTypeDeclarations || myWriterConfiguration["ShowMethodDeclarationBody"] == "true"));
				if (!detailedForm)
				{
					WriteTypeReferenceProperties(value, "Name");
				}
			}
			void ILanguageWriter.WriteTypeDeclaration(ITypeDeclaration value)
			{
				WriteTypeDeclaration(value);
			}
			private void WriteTypeReferenceProperties(ITypeReference typeReference, string typeReferencePropertyName)
			{
				if (typeReference == null)
				{
					return;
				}
				StringBuilder builder = new StringBuilder();
				IModule owningModule = RenderSummaryTypeName(builder, typeReference);
				myFormatter.WriteProperty(typeReferencePropertyName, builder.ToString());
				if (owningModule != null)
				{
					IAssembly assembly = owningModule.Assembly;
					myFormatter.WriteProperty("Assembly", assembly.Name + ", " + assembly.Version.ToString(4));
				}
			}
			private static IModule RenderSummaryTypeName(StringBuilder builder, ITypeReference typeReference)
			{
				if (typeReference == null)
				{
					return null;
				}
				IModule retVal = null;
				object owner = typeReference.Owner;
				IModule owningModule = owner as IModule;
				if (owningModule == null)
				{
					retVal = RenderSummaryTypeName(builder, owner as ITypeReference);
					if (retVal != null)
					{
						builder.Append('+');
					}
				}
				else
				{
					retVal = owningModule;
					string namespaceName = typeReference.Namespace;
					if (!string.IsNullOrEmpty(namespaceName))
					{
						builder.Append(namespaceName);
						builder.Append('.');
					}
				}
				builder.Append(typeReference.Name);
				ITypeCollection genericArguments = typeReference.GenericArguments;
				int genericCount = genericArguments.Count;
				if (genericCount != 0)
				{
					IGenericArgumentProvider ownerArgumentProvider = owner as IGenericArgumentProvider;
					ITypeCollection ownerGenericArguments = null;
					if (ownerArgumentProvider != null)
					{
						ownerGenericArguments = ownerArgumentProvider.GenericArguments;
						if (ownerGenericArguments.Count == 0)
						{
							ownerGenericArguments = null;
						}
					}
					bool writtenFirstArgument = false;
					for (int i = 0; i < genericCount; ++i)
					{
						IType argument = genericArguments[i];
						if (ownerGenericArguments != null && ownerGenericArguments.Contains(argument))
						{
							continue;
						}
						if (writtenFirstArgument)
						{
							builder.Append(",");
						}
						else
						{
							writtenFirstArgument = true;
							builder.Append("<");
						}
						ITypeReference typedArgument = argument as ITypeReference;
						if (typedArgument != null)
						{
							RenderSummaryTypeName(builder, typedArgument);
						}
						else
						{
							builder.Append(argument.ToString());
						}
					}
					if (writtenFirstArgument)
					{
						builder.Append(">");
					}
				}
				return retVal;
			}
			#endregion // ILanguageWriter Implementation
			#region XML Output Helpers
			/// <summary>
			/// Call this to prepare to write. Clears all flags, allowing
			/// recovery from an earlier exception, and set other values.
			/// </summary>
			private void PrepareForWrite(bool writeNamespaceOnFirstWrite, string contextDataTypeQualifier)
			{
				myContextDataTypeQualifier = contextDataTypeQualifier;
				myFirstWrite = writeNamespaceOnFirstWrite;
				myOpenElements.Clear();
				myCurrentElementClosedForText = false;
				myCurrentElementIsComment = false;
				myCurrentElementIsOpen = false;
				myDelayWriteElement = null;
			}
			private void WriteElement(string tagName)
			{
				OutputDelayedElement();
				IFormatter formatter = myFormatter;
				if (myCurrentElementIsOpen)
				{
					if (myCurrentElementIsComment)
					{
						myCurrentElementIsComment = false;
						formatter.WriteComment(" -->");
						formatter.WriteLine();
					}
					else
					{
						WriteNamespace();
						formatter.Write(">");
						formatter.WriteLine();
						formatter.WriteIndent();
					}
				}
				else
				{
					if (myCurrentElementClosedForText)
					{
						myCurrentElementClosedForText = false;
						formatter.WriteIndent();
					}
					formatter.WriteLine();
					myCurrentElementIsOpen = true;
				}
				formatter.WriteKeyword("<plx");
				formatter.Write(":");
				formatter.WriteKeyword(tagName);
				myOpenElements.Push(tagName);
			}
			private void WriteXmlComment()
			{
				OutputDelayedElement();
				IFormatter formatter = myFormatter;
				if (myCurrentElementIsOpen)
				{
					if (myCurrentElementIsComment)
					{
						formatter.WriteComment(" -->");
						formatter.WriteLine();
					}
					else
					{
						WriteNamespace();
						formatter.Write(">");
						formatter.WriteLine();
						formatter.WriteIndent();
					}
				}
				else
				{
					if (myCurrentElementClosedForText)
					{
						myCurrentElementClosedForText = false;
						formatter.WriteIndent();
					}
					formatter.WriteLine();
					myCurrentElementIsOpen = true;
				}
				myCurrentElementIsComment = true;
				formatter.WriteComment("<!-- ");
				myOpenElements.Push(null);
			}
			private void WriteElementDelayed(string tagName)
			{
				OutputDelayedElement();
				myDelayWriteElement = tagName;
			}
			private void OutputDelayedElement()
			{
				string delayedElement = myDelayWriteElement;
				if (delayedElement != null)
				{
					myDelayWriteElement = null;
					WriteElement(delayedElement);
				}
			}
			private void WriteEndElement()
			{
				if (myDelayWriteElement != null)
				{
					myDelayWriteElement = null;
					return;
				}
				IFormatter formatter = myFormatter;
				bool emptyElement = myCurrentElementIsOpen;
				if (emptyElement)
				{
					if (myCurrentElementIsComment)
					{
						formatter.WriteComment(" -->");
						myCurrentElementIsComment = false;
					}
					else
					{
						WriteNamespace();
						formatter.Write("/>");
					}
					myOpenElements.Pop();
					myCurrentElementIsOpen = false;
				}
				else
				{
					string openTagName = myOpenElements.Pop();
					if (myCurrentElementClosedForText)
					{
						myCurrentElementClosedForText = false;
					}
					else if (openTagName != null)
					{
						formatter.WriteOutdent();
						formatter.WriteLine();
					}
					if (openTagName != null)
					{
						formatter.WriteKeyword("</plx");
						formatter.Write(":");
						formatter.WriteKeyword(openTagName);
						formatter.Write(">");
					}
				}
			}
			private delegate void WriteAttributeValue(IFormatter formatter, string escapedValue);
			private void WriteAttribute(string name, string value)
			{
				WriteAttribute(name, value, false, false);
			}
			private void WriteAttribute(string name, string value, string referenceDescription, object referenceTarget)
			{
				WriteAttribute(
					name,
					value,
					delegate(IFormatter formatter, string escapedValue)
					{
						formatter.WriteReference(escapedValue, referenceDescription, referenceTarget);
					});
			}
			private void WriteAttribute(string name, string value, bool isDeclaration, bool isLiteral)
			{
				WriteAttribute(
					name,
					value,
					delegate(IFormatter formatter, string escapedValue)
					{
						if (isDeclaration)
						{
							formatter.WriteDeclaration(escapedValue);
						}
						else if (isLiteral)
						{
							formatter.WriteLiteral(escapedValue);
						}
						else
						{
							formatter.Write(escapedValue);
						}
					});
			}
			private void WriteAttribute(string name, string value, WriteAttributeValue valueWriter)
			{
				OutputDelayedElement();
				IFormatter formatter = myFormatter;
				formatter.Write(" ");
				formatter.WriteKeyword(name);
				formatter.Write("=\"");
				valueWriter(formatter, EscapeText(value));
				formatter.Write("\"");
			}
			private class NoCloseStringWriter : StringWriter
			{
				/// <summary>
				/// Forward constructor parameters to base
				/// </summary>
				/// <param name="builder"><see cref="StringBuilder"/></param>
				public NoCloseStringWriter(StringBuilder builder)
					: base(builder)
				{
				}
				/// <summary>
				/// Don't close the string writer when detaching an XmlTextWriter
				/// </summary>
				public override void Close()
				{
					// Don't close
				}
			}
			private string EscapeText(string text)
			{
				StringBuilder builder = myEscapeTextStringBuilder;
				StringWriter stringWriter;
				XmlTextWriter xmlWriter;
				if (builder == null)
				{
					myEscapeTextStringBuilder = builder = new StringBuilder();
					myEscapeTextStringWriter = stringWriter = new NoCloseStringWriter(builder);
					myEscapeTextXmlWriter = xmlWriter = new XmlTextWriter(stringWriter);
				}
				else
				{
					stringWriter = myEscapeTextStringWriter;
					xmlWriter = myEscapeTextXmlWriter;
				}
				try
				{
					xmlWriter.WriteValue(text);
				}
				catch (Exception ex)
				{
					if (xmlWriter.WriteState == WriteState.Error)
					{
						xmlWriter.Close();
						stringWriter.Write(ex.Message);
						myEscapeTextXmlWriter = new XmlTextWriter(stringWriter);
					}
					if (!(ex is ArgumentException))
					{
						throw;
					}
				}
				finally
				{
					stringWriter.Flush();
					text = builder.ToString();
					builder.Length = 0;
				}
				return text;
			}
			/// <summary>
			/// Options for the WriteText method
			/// </summary>
			[Flags]
			private enum WriteTextOptions
			{
				/// <summary>
				/// Default options (text is escaped and rendered without newline or indent as unformatted text)
				/// </summary>
				None = 0,
				/// <summary>
				/// Text should not be escaped
				/// </summary>
				RenderRaw = 1,
				/// <summary>
				/// Format as a literal (default muted red color)
				/// </summary>
				AsLiteral = 2,
				/// <summary>
				/// Format as a comment (default light grey)
				/// </summary>
				AsComment = 4,
				/// <summary>
				/// Format as a declaration (default bold)
				/// </summary>
				AsDeclaration = 8,
				/// <summary>
				/// Add a new line before the text
				/// </summary>
				LeadingNewLine = 0x10,
				/// <summary>
				/// Add a new line after the text
				/// </summary>
				TrailingNewLine = 0x20,
				/// <summary>
				/// Add a leading indent before the text
				/// </summary>
				LeadingIndent = 0x40,
				/// <summary>
				/// Outdent after the text
				/// </summary>
				TrailingOutdent = 0x80,
				/// <summary>
				/// Used to render a string literal
				/// </summary>
				LiteralStringSettings = AsLiteral,
				/// <summary>
				/// Render text as a comment without xml escaping
				/// </summary>
				RawCommentSettings = AsComment | RenderRaw,
				/// <summary>
				/// Use to write an explicit comment (coming from this codebase) with a single call
				/// </summary>
				FullExplicitCommentSettings = AsComment | RenderRaw | LeadingNewLine | LeadingIndent | TrailingOutdent,
				/// <summary>
				/// Use to write the beginning of an explicit comment (coming from this codebase). WriteText
				/// should be called a second time with EndExplicitCommentSettings to finish the comment.
				/// </summary>
				StartExplicitCommentSettings = AsComment | RenderRaw | LeadingNewLine | LeadingIndent,
				/// <summary>
				/// Use to write the end of an explicit comment (coming from this codebase). WriteText
				/// should first be called with StartExplicitCommentMask to begin the comment.
				/// </summary>
				EndExplicitCommentSettings = AsComment | RenderRaw | TrailingOutdent,
			}
			private void WriteText(string value, WriteTextOptions options)
			{
				if (!string.IsNullOrEmpty(value))
				{
					OutputDelayedElement();
					IFormatter formatter = myFormatter;
					if (myCurrentElementIsOpen && !myCurrentElementIsComment)
					{
						WriteNamespace();
						formatter.Write(">");
						myCurrentElementClosedForText = true;
						myCurrentElementIsOpen = false;
					}
					if (0 != (options & WriteTextOptions.LeadingNewLine))
					{
						myFormatter.WriteLine();
					}
					if (0 != (options & WriteTextOptions.LeadingIndent))
					{
						myFormatter.WriteIndent();
					}
					string escapedText = (0 != (options & WriteTextOptions.RenderRaw)) ? value : EscapeText(value);
					if (0 != (options & WriteTextOptions.AsComment))
					{
						myFormatter.WriteComment(escapedText);
					}
					else if (0 != (options & WriteTextOptions.AsDeclaration))
					{
						myFormatter.WriteDeclaration(escapedText);
					}
					else if (0 != (options & WriteTextOptions.AsLiteral))
					{
						myFormatter.WriteLiteral(escapedText);
					}
					else
					{
						myFormatter.Write(escapedText);
					}
					if (0 != (options & WriteTextOptions.TrailingOutdent))
					{
						myFormatter.WriteOutdent();
					}
					if (0 != (options & WriteTextOptions.TrailingNewLine))
					{
						myFormatter.WriteLine();
					}
				}
			}
			private void WriteNamespace()
			{
				if (myFirstWrite)
				{
					myFirstWrite = false;
					IFormatter formatter = myFormatter;
					formatter.Write(" ");
					formatter.WriteKeyword("xmlns");
					formatter.Write(":");
					formatter.WriteKeyword("plx");
					formatter.Write("=\"http://schemas.neumont.edu/CodeGeneration/PLiX\"");
				}
			}
			#endregion // XML Output Helpers
			#region Example Statement Output
			private sealed class ExampleStatementFormatter : IFormatter
			{
				#region Member Variables
				private IFormatter myInnerFormatter;
				private int myIndentLevel;
				private bool myWriteLinePending;
				#endregion // Member Variables
				#region Constructor and Singleton
				private static readonly ExampleStatementFormatter Singleton = new ExampleStatementFormatter();
				private ExampleStatementFormatter() { }
				#endregion // Constructor and Singleton
				#region Methods
				public static void RenderExampleStatementComment(IStatement statement, ILanguage statementLanguage, IFormatter formatter, ILanguageWriterConfiguration writerConfiguration)
				{
					ExampleStatementFormatter wrappingFormatter = Singleton;
					wrappingFormatter.myInnerFormatter = formatter;
					wrappingFormatter.myIndentLevel = 0;
					wrappingFormatter.myWriteLinePending = false;
					formatter.WriteLine();
					formatter.WriteComment("<!-- ");
					statementLanguage.GetWriter(wrappingFormatter, writerConfiguration).WriteStatement(statement);
					formatter.WriteComment(" -->");
				}
				#endregion // Methods
				#region IFormatter Implementation
				private void Write(string value)
				{
					if (myIndentLevel == 0)
					{
						if (myWriteLinePending)
						{
							myWriteLinePending = false;
							myInnerFormatter.WriteLine();
						}
						myInnerFormatter.WriteComment(value);
					}
				}
				void IFormatter.Write(string value)
				{
					Write(value);
				}
				void IFormatter.WriteComment(string value)
				{
					Write(value);
				}
				void IFormatter.WriteDeclaration(string value)
				{
					Write(value);
				}
				void IFormatter.WriteDeclaration(string value, object target)
				{
					Write(value);
				}
				void IFormatter.WriteIndent()
				{
					++myIndentLevel;
				}
				void IFormatter.WriteKeyword(string value)
				{
					Write(value);
				}
				void IFormatter.WriteLine()
				{
					if (myIndentLevel == 0)
					{
						myWriteLinePending = true;
					}
				}
				void IFormatter.WriteLiteral(string value)
				{
					Write(value);
				}
				void IFormatter.WriteOutdent()
				{
					--myIndentLevel;
				}
				void IFormatter.WriteProperty(string name, string value)
				{
				}
				void IFormatter.WriteReference(string value, string description, object target)
				{
					Write(value);
				}
				#endregion // IFormatter Implementation
			}
			private void WriteExampleStatementComment(IStatement statement)
			{
				ILanguage exampleLanguage = myPLiXConfiguration.ExampleLanguage;
				if (exampleLanguage != null)
				{
					OutputDelayedElement();
					IFormatter formatter = myFormatter;
					if (myCurrentElementIsOpen)
					{
						WriteNamespace();
						formatter.Write(">");
						formatter.WriteIndent();
						myCurrentElementIsOpen = false;
					}
					ExampleStatementFormatter.RenderExampleStatementComment(statement, exampleLanguage, myFormatter, myWriterConfiguration);
				}
			}
			#endregion // Example Statement Output
			#region Array helper functions
			/// <summary>
			/// Resolve array dimensions
			/// </summary>
			/// <param name="arrayType">The starting array type</param>
			/// <param name="elementType">Returns the element type for the array</param>
			/// <returns>A queue of IArrayDimensionCollection collections, or null if the array is simple</returns>
			private static Queue<IArrayDimensionCollection> ResolveArrayDimensions(IArrayType arrayType, out IType elementType)
			{
				bool firstType = true;
				IArrayType nextArrayType = arrayType;
				Queue<IArrayDimensionCollection> retVal = null;
				IType nextElementType = null;
				while (nextArrayType != null)
				{
					IArrayDimensionCollection dimensions = nextArrayType.Dimensions;
					if (!firstType || dimensions.Count != 0)
					{
						if (retVal == null)
						{
							retVal = new Queue<IArrayDimensionCollection>();
							if (!firstType)
							{
								retVal.Enqueue(arrayType.Dimensions); // Push the empty dimensions
							}
						}
						retVal.Enqueue(dimensions);
					}
					nextElementType = nextArrayType.ElementType;
					nextArrayType = nextElementType as IArrayType;
					firstType = false;
				}
				elementType = nextElementType;
				return retVal;
			}
			#region ArrayTypeMockup class
			private sealed class ArrayTypeMockup : IArrayType
			{
				#region ArrayDimensionsMockup class
				private sealed class ArrayDimensionsMockup : IArrayDimensionCollection, IArrayDimension
				{
					#region Member Variables
					private int myDimensions;
					#endregion // Member Variables
					#region Constructors
					public ArrayDimensionsMockup(int dimensions)
					{
						myDimensions = dimensions;
					}
					#endregion // Constructors
					#region IArrayDimension Implementation
					int IArrayDimension.LowerBound
					{
						get
						{
							return 0;
						}
						set
						{
							throw new NotImplementedException();
						}
					}
					int IArrayDimension.UpperBound
					{
						get
						{
							return -1;
						}
						set
						{
							throw new NotImplementedException();
						}
					}
					#endregion // IArrayDimension Implementation
					#region IArrayDimensionCollection Implementation
					void IArrayDimensionCollection.Add(IArrayDimension value)
					{
						throw new NotImplementedException();
					}
					void IArrayDimensionCollection.AddRange(System.Collections.ICollection value)
					{
						throw new NotImplementedException();
					}
					void IArrayDimensionCollection.Clear()
					{
						throw new NotImplementedException();
					}
					bool IArrayDimensionCollection.Contains(IArrayDimension value)
					{
						throw new NotImplementedException();

					}
					int IArrayDimensionCollection.IndexOf(IArrayDimension value)
					{
						throw new NotImplementedException();
					}
					void IArrayDimensionCollection.Insert(int index, IArrayDimension value)
					{
						throw new NotImplementedException();
					}
					void IArrayDimensionCollection.Remove(IArrayDimension value)
					{
						throw new NotImplementedException();
					}
					void IArrayDimensionCollection.RemoveAt(int index)
					{
						throw new NotImplementedException();
					}
					IArrayDimension IArrayDimensionCollection.this[int index]
					{
						get
						{
							return this;
						}
						set
						{
							throw new NotImplementedException();
						}
					}
					void ICollection.CopyTo(Array array, int index)
					{
						throw new NotImplementedException();
					}

					int ICollection.Count
					{
						get
						{
							return myDimensions;
						}
					}

					bool ICollection.IsSynchronized
					{
						get
						{
							return false;
						}
					}
					object System.Collections.ICollection.SyncRoot
					{
						get
						{
							return null;
						}
					}
					IEnumerator IEnumerable.GetEnumerator()
					{
						throw new NotImplementedException();
					}
					#endregion // IArrayDimensionCollection Implementation
				}
				#endregion // ArrayDimensionsMockup class
				#region Member Variables
				private IType myElementType;
				private IArrayDimensionCollection myDimensions;
				#endregion // Member Variables
				#region Constructors
				public ArrayTypeMockup(IType elementType, int dimensions)
				{
					myElementType = elementType;
					myDimensions = new ArrayDimensionsMockup(dimensions);
				}
				#endregion // Constructors
				#region IArrayType Implementation
				IArrayDimensionCollection IArrayType.Dimensions
				{
					get
					{
						return myDimensions;
					}
				}
				IType IArrayType.ElementType
				{
					get
					{
						return myElementType;
					}
					set
					{
						throw new NotImplementedException();
					}
				}
				int IComparable.CompareTo(object obj)
				{
					throw new NotImplementedException();
				}
				#endregion //IArrayType Implementation
			}
			#endregion // ArrayTypeMockup class
			private static IArrayType MockupArrayType(IType elementType, int dimensions)
			{
				return new ArrayTypeMockup(elementType, dimensions);
			}
			#endregion // Array helper functions
			#region Other helper functions
			/// <summary>
			/// Get a dataTypeQualifier for a given context type
			/// </summary>
			/// <param name="contextType">The context type</param>
			/// <returns>Qualifier, or null if none available.</returns>
			private static string GetDataTypeQualifier(IType contextType)
			{
				ITypeReference typeReference;
				if (null != (typeReference = contextType as ITypeReference))
				{
					string resolvedNamespace = typeReference.Namespace;
					if (string.IsNullOrEmpty(resolvedNamespace))
					{
						ITypeReference owningType = typeReference.Owner as ITypeReference;
						if (owningType != null)
						{
							if (IsGenericTypeReference(owningType))
							{
								return GetDataTypeQualifier(owningType);
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
					return string.IsNullOrEmpty(resolvedNamespace) ? null : resolvedNamespace;
				}
				return null;
			}
			/// <summary>
			/// Returns true if the static call should be rendered unqualified based
			/// on the current user options and declaration type
			/// </summary>
			private bool ShouldRenderStaticThisCall(ITypeReferenceExpression staticTypeReference)
			{
				if (staticTypeReference != null)
				{
					IMethodDeclaration currentMethodDeclaration;
					switch (myPLiXConfiguration.StaticCallRenderingOption)
					{
						case StaticCallRenderingOption.ImplicitCurrentType:
							return null != (currentMethodDeclaration = myCurrentMethodDeclaration) &&
								currentMethodDeclaration.DeclaringType.Equals(staticTypeReference.Type);
						case StaticCallRenderingOption.ImplicitBaseTypes:
							ITypeReference testReference;
							if (null != (testReference = staticTypeReference.Type) &&
								null != (currentMethodDeclaration = myCurrentMethodDeclaration))
							{
								IType contextType = currentMethodDeclaration.DeclaringType;
								while (contextType != null)
								{
									if (contextType.Equals(testReference))
									{
										return true;
									}
									ITypeReference typeReference = contextType as ITypeReference;
									ITypeDeclaration typeDeclaration;
									contextType = (typeReference != null) ? (null != (typeDeclaration = typeReference.Resolve()) ? typeDeclaration.BaseType : null) : null;
								}
							}
							break;
					}
				}
				return false;
			}
			/// <summary>
			/// Returns true if the passed type or any of its owning types are generic
			/// </summary>
			private static bool IsGenericTypeReference(ITypeReference typeReference)
			{
				do
				{
					if (typeReference.GenericType != null)
					{
						return true;
					}
					typeReference = typeReference.Owner as ITypeReference;
				} while (typeReference != null);
				return false;
			}
			/// <summary>
			/// Returns true if this is a method reference to a delegate invoke function
			/// </summary>
			private static bool IsDelegateInvokeMethodReference(IMethodReference methodReference)
			{
				ITypeReference declaringType;
				ITypeDeclaration declaringTypeDeclaration;
				ITypeReference baseType;
				if (methodReference.Name == "Invoke" &&
					null != (declaringType = methodReference.DeclaringType as ITypeReference) &&
					null != (declaringTypeDeclaration = declaringType.Resolve()) &&
					null != (baseType = declaringTypeDeclaration.BaseType))
				{
					string baseName = baseType.Name;
					return baseName == "MulticastDelegate" || baseName == "Delegate";
				}
				return false;
			}
			private static int CompareMethodVisibilityStrength(MethodVisibility visibility1, MethodVisibility visibility2)
			{
				if (visibility1 == MethodVisibility.PrivateScope)
				{
					visibility1 = MethodVisibility.Private;
				}
				if (visibility2 == MethodVisibility.PrivateScope)
				{
					visibility2 = MethodVisibility.Private;
				}
				if (visibility1 == visibility2)
				{
					return 0;
				}
				// The values are naturally ordered, with more restrictive (stronger) values lower
				//PrivateScope = 0,
				//Private = 1,
				//FamilyAndAssembly = 2,
				//Assembly = 3,
				//Family = 4,
				//FamilyOrAssembly = 5,
				//Public = 6,
				else if (visibility1 < visibility2)
				{
					return 1;
				}
				return -1;
			}
			/// <summary>
			/// Return the method (from set or get) with the weakest visibility
			/// </summary>
			private static IMethodDeclaration GetPropertyReferenceMethod(IPropertyDeclaration propertyDeclaration)
			{
				IMethodReference getReference = propertyDeclaration.GetMethod;
				IMethodReference setReference = propertyDeclaration.SetMethod;
				IMethodDeclaration getter = (getReference != null) ? getReference.Resolve() : null;
				IMethodDeclaration setter = (setReference != null) ? setReference.Resolve() : null;
				if (getter == null || (setter != null && CompareMethodVisibilityStrength(getter.Visibility, setter.Visibility) > 0))
				{
					return setter;
				}
				return getter;
			}
			/// <summary>
			/// Return a method that can be used to represent the given event
			/// </summary>
			private static IMethodDeclaration GetEventReferenceMethod(IEventDeclaration eventDeclaration)
			{
				IMethodReference addReference = eventDeclaration.AddMethod;
				if (addReference != null)
				{
					return addReference.Resolve();
				}
				IMethodReference removeReference = eventDeclaration.AddMethod;
				if (removeReference != null)
				{
					return removeReference.Resolve();
				}
				return null;
			}
			private static IParameterDeclarationCollection GetDelegateParameters(ITypeReference eventType)
			{
				foreach (IMethodDeclaration methodDeclaration in eventType.Resolve().Methods)
				{
					if (methodDeclaration.Name == "Invoke")
					{
						return methodDeclaration.Parameters;
					}
				}
				return null;
			}
			private static IExpression TestNullifyExpression(IExpression expression)
			{
				ILiteralExpression literal = expression as ILiteralExpression;
				return (literal != null && literal.Value == null) ? null : expression;
			}
			#endregion // Other helper functions
			#region Interface and event member mapping
			#region InterfaceMemberStyle enum
			/// <summary>
			/// Determine how a member maps to an interface
			/// </summary>
			private enum InterfaceMemberStyle
			{
				/// <summary>
				/// The member does not have any interface members
				/// </summary>
				None,
				/// <summary>
				/// The member has one or more interface members
				/// </summary>
				HasInterfaceMembers,
				/// <summary>
				/// The member is an explicit interface implementation for a single interface member
				/// that defers to another method on the same class
				/// </summary>
				DeferredExplicitImplementation,

				// Note that this enum originally had an 'ExplicitImplementation' value between HasInterfaceMembers
				// and DeferredExplicitImplementation in strength. The intent was to indicate that the method
				// was marked as an explicit interface implementation as opposed to being bound by name to
				// a public method. This catered for the C# interface pattern that encourages the 'deferred' implementation
				// pattern also supported by the C# plix formatter. However, it was at odds with the (much cleaner) VB
				// implementation that basically combines the explicit overrides and the implementation into a single function.
				// For this reason, we will not disassemble 'privateInterfaceMember' visibility because there is no way to
				// tell the intent of the method simple by examing the override(s) and the body content.
			}
			#endregion // InterfaceMemberStyle enum
			#region InterfaceMemberInfo struct
			/// <summary>
			/// Structure indicating interface mapping information. Generally retrieved through
			/// the <see cref="MemberMapper.GetInterfaceMemberInfo"/> method.
			/// </summary>
			private struct InterfaceMemberInfo
			{
				private ICollection<IMemberReference> myInterfaceMembers;
				private InterfaceMemberStyle myStyle;
				/// <summary>
				/// Create a new <see cref="InterfaceMemberInfo"/> for a <see cref="IMemberDeclaration"/>
				/// </summary>
				/// <param name="memberDeclaration">The <see cref="IMemberDeclaration"/> to create information for/></param>
				/// <param name="memberReferences">A collection of <see cref="IMemberReference"/> elements representing the corresponding interface members</param>
				public InterfaceMemberInfo(IMemberDeclaration memberDeclaration, ICollection<IMemberReference> memberReferences)
				{
					myStyle = InterfaceMemberStyle.None;
					myInterfaceMembers = null;
					int memberCount;
					if (memberReferences != null &&
						0 != (memberCount = memberReferences.Count))
					{
						myInterfaceMembers = memberReferences;
						if (memberCount == 1)
						{
							foreach (IMemberReference interfaceMember in memberReferences)
							{
								myStyle = (interfaceMember.DeclaringType.Equals(memberDeclaration.DeclaringType)) ?
									InterfaceMemberStyle.DeferredExplicitImplementation :
									InterfaceMemberStyle.HasInterfaceMembers;
							}
						}
						else
						{
							myStyle = InterfaceMemberStyle.HasInterfaceMembers;
						}
					}
				}
				/// <summary>
				/// Get the <see cref="InterfaceMemberStyle"/> to determine the support interface member support
				/// </summary>
				public InterfaceMemberStyle Style
				{
					get
					{
						return myStyle;
					}
				}
				/// <summary>
				/// Returns true if there are any interface members
				/// </summary>
				public bool HasInterfaceMembers
				{
					get
					{
						return myStyle != InterfaceMemberStyle.None;
					}
				}
				private static readonly ICollection<IMemberReference> EmptyMemberReferences = new IMemberReference[0];
				/// <summary>
				/// Return a collection of member references
				/// </summary>
				public ICollection<IMemberReference> InterfaceMemberCollection
				{
					get
					{
						return myInterfaceMembers ?? EmptyMemberReferences;
					}
				}
			}
			#endregion // InterfaceMemberInfo struct
			#region MemberMapper class
			/// <summary>
			/// A helper class to enable interface and simple event mapping
			/// </summary>
			private class MemberMapper
			{
				#region Member Variables
				private IDictionary<ITypeDeclaration, ITypeDeclaration> myMappedTypes;
				private Dictionary<IMemberDeclaration, ICollection<IMemberReference>> myInterfaceMemberMap;
				private Dictionary<IMemberDeclaration, IMemberDeclaration> mySimpleEventMap;
				private ITranslator myTranslator;
				#endregion // Member Variables
				#region Constructors
				/// <summary>
				/// Create a new <see cref="MemberMapper"/> for the provided <paramref name="translator"/>
				/// </summary>
				/// <param name="translator">The <see cref="ITranslator"/> provided by Reflector</param>
				public MemberMapper(ITranslator translator)
				{
					myTranslator = translator;
					myMappedTypes = new Dictionary<ITypeDeclaration, ITypeDeclaration>();
					myInterfaceMemberMap = new Dictionary<IMemberDeclaration, ICollection<IMemberReference>>();
					mySimpleEventMap = new Dictionary<IMemberDeclaration, IMemberDeclaration>();
				}
				#endregion // Constructors
				#region Public accessor methods
				/// <summary>
				/// Get interface member info for a method, property, or event
				/// </summary>
				public InterfaceMemberInfo GetInterfaceMemberInfo(IMemberDeclaration methodDeclaration)
				{
					return new InterfaceMemberInfo(methodDeclaration, GetInterfaceMembers(methodDeclaration));
				}
				/// <summary>
				/// Does this event declaration match the simple event pattern?
				/// </summary>
				public IFieldDeclaration GetSimpleEventField(IEventDeclaration eventDeclaration)
				{
					EnsureMapForMember(eventDeclaration);
					IMemberDeclaration retVal;
					if (mySimpleEventMap.TryGetValue(eventDeclaration, out retVal))
					{
						return (IFieldDeclaration)retVal;
					}
					return null;
				}
				/// <summary>
				/// Does this field back an event that matches the simple event pattern?
				/// </summary>
				public bool IsSimpleEventField(IFieldDeclaration fieldDeclaration)
				{
					EnsureMapForMember(fieldDeclaration);
					return mySimpleEventMap.ContainsKey(fieldDeclaration);
				}
				#endregion // Public accessor methods
				#region Cache management
				/// <summary>
				/// Any current cached information is obsolete, clear it
				/// </summary>
				public void ClearCache()
				{
					myMappedTypes.Clear();
					myInterfaceMemberMap.Clear();
					mySimpleEventMap.Clear();
				}
				private void EnsureMapForMember(IMemberDeclaration memberDeclaration)
				{
					ITypeDeclaration declaringType = (memberDeclaration.DeclaringType as ITypeReference).Resolve();
					if (!declaringType.Interface && !myMappedTypes.ContainsKey(declaringType))
					{
						myMappedTypes[declaringType] = declaringType;
						MapMembers(declaringType);
						MapSimpleEvents(declaringType);
					}
				}
				#endregion // Cache management
				#region SimpleEvent Mapping
				private void MapSimpleEvents(ITypeDeclaration declaringType)
				{
					Dictionary<IMemberDeclaration, IMemberDeclaration> eventMaps = mySimpleEventMap;
					foreach (IEventDeclaration eventDecl in declaringType.Events)
					{
						IFieldReference fieldReference;
						IFieldDeclaration fieldDecl;
						if (null != (fieldReference = GetFieldReferenceForEventMethod(eventDecl.AddMethod, "Combine")) &&
							fieldReference.FieldType.Equals(eventDecl.EventType) &&
							null != (fieldDecl = fieldReference.Resolve()) &&
							fieldDecl.Visibility == FieldVisibility.Private &&
							fieldReference.Equals(GetFieldReferenceForEventMethod(eventDecl.RemoveMethod, "Remove")))
						{
							eventMaps[fieldDecl] = eventDecl;
							eventMaps[eventDecl] = fieldDecl;
						}
					}
				}
				private IFieldReference GetFieldReferenceForEventMethod(IMethodReference accessorMethod, string delegateMethodName)
				{
					IMethodDeclaration methodDecl;
					try
					{
						methodDecl = myTranslator.TranslateMethodDeclaration(accessorMethod.Resolve());
					}
					catch
					{
						methodDecl = null;
					}
					if (methodDecl != null)
					{
						IBlockStatement bodyBlock;
						IStatementCollection bodyStatements;
						IExpressionStatement expressionStatement;
						IAssignExpression assignExpression;
						IFieldReferenceExpression fieldReferenceExpression;
						IFieldReference fieldReference;
						IExpression fieldTarget;
						ITypeReferenceExpression fieldTypeReferenceExpression = null;
						ICastExpression castExpression;
						IMethodInvokeExpression invokeExpression;
						IMethodReferenceExpression invokedMethodExpression;
						IMethodReference invokedMethod;
						ITypeReference delegateTypeReference;
						IExpressionCollection arguments;

						if (null != (bodyBlock = methodDecl.Body as IBlockStatement) &&
							null != (bodyStatements = bodyBlock.Statements) &&
							// Looking for a single assign expression with a call to System.Delegate.Combine/Remove as the expression
							1 == bodyStatements.Count &&
							null != (expressionStatement = bodyStatements[0] as IExpressionStatement) &&
							null != (assignExpression = expressionStatement.Expression as IAssignExpression) &&
							null != (castExpression = assignExpression.Expression as ICastExpression) &&
							null != (invokeExpression = castExpression.Expression as IMethodInvokeExpression) &&
							null != (invokedMethodExpression = invokeExpression.Method as IMethodReferenceExpression) &&
							null != (invokedMethod = invokedMethodExpression.Method) &&
							invokedMethod.Name == delegateMethodName &&
							null != (delegateTypeReference = invokedMethod.DeclaringType as ITypeReference) &&
							delegateTypeReference.Name == "Delegate" &&
							delegateTypeReference.Namespace == "System" &&
							// Make sure we're assigning to an appropriate field
							null != (fieldReferenceExpression = assignExpression.Target as IFieldReferenceExpression) &&
							null != (fieldReference = fieldReferenceExpression.Field) &&
							((fieldTarget = fieldReferenceExpression.Target) is IThisReferenceExpression ||
							(methodDecl.Static &&
							null != (fieldTypeReferenceExpression = fieldTarget as ITypeReferenceExpression) &&
							accessorMethod.DeclaringType.Equals(fieldTypeReferenceExpression.Type))) &&
							// Verify that the arguments to the delegate method are correct. There is only one
							// argument to these methods, so any argument reference expression will do. Then we
							// verify that we're referencing the same field as the assignment target.
							(arguments = invokeExpression.Arguments)[1] is IArgumentReferenceExpression &&
							null != (fieldReferenceExpression = arguments[0] as IFieldReferenceExpression) &&
							fieldReference.Equals(fieldReferenceExpression.Field) &&
							(fieldTypeReferenceExpression != null ||
							fieldReferenceExpression.Target is IThisReferenceExpression))
						{
							return fieldReference;
						}
					}
					return null;
				}
				#endregion // SimpleEvent mapping
				#region InterfaceMember mapping
				/// <summary>
				/// Given a member declaration, return a collection of interface members referenced by the
				/// method. Can return null;
				/// </summary>
				private ICollection<IMemberReference> GetInterfaceMembers(IMemberDeclaration memberDeclaration)
				{
					EnsureMapForMember(memberDeclaration);
					ICollection<IMemberReference> retVal;
					if (myInterfaceMemberMap.TryGetValue(memberDeclaration, out retVal))
					{
						return retVal;
					}
					return null;
				}
				private bool AreSignaturesEqual(IMethodSignature signature1, IMethodSignature signature2)
				{
					if (signature1 != null && signature2 != null &&
						signature1.CallingConvention == signature2.CallingConvention &&
						signature1.ReturnType.Type.Equals(signature2.ReturnType.Type))
					{
						IParameterDeclarationCollection params1 = signature1.Parameters;
						IParameterDeclarationCollection params2 = signature2.Parameters;
						int paramsCount = params1.Count;
						if (paramsCount == params2.Count)
						{
							int i = 0;
							for (; i < paramsCount; ++i)
							{
								if (!params1[i].ParameterType.Equals(params2[i].ParameterType))
								{
									break;
								}
							}
							return i == paramsCount;
						}
					}
					return false;
				}
				private void MapMembers(ITypeDeclaration typeDeclaration)
				{
					ITranslator translator = myTranslator;
					ITypeReferenceCollection interfaces = typeDeclaration.Interfaces;
					int interfaceCount = interfaces.Count;
					if (interfaceCount != 0)
					{
						// Step 1: Get all possible interface members. Property and event accessor
						// methods are treated as normal methods here, so they
						Dictionary<IMemberDeclaration, IMemberDeclaration> interfaceDeclToMemberDeclMap = new Dictionary<IMemberDeclaration, IMemberDeclaration>();
						SeedInterfaceMembers(interfaceDeclToMemberDeclMap, interfaces);

						// Step 2a: Get all explicit method implementations and determine if they defer directly to another method
						// with the same signature. SpecialName methods are handled later with properties (Step 2b) and events (Step 2c) so we do not
						// need to rely on name parsing to determine special method usage.
						IMethodDeclarationCollection methods = typeDeclaration.Methods;
						foreach (IMethodDeclaration methodDecl in methods)
						{
							if (methodDecl.SpecialName || methodDecl.RuntimeSpecialName || methodDecl.Static)
							{
								continue;
							}
							IMethodReferenceCollection overrides = methodDecl.Overrides;
							int overrideCount = overrides.Count;
							for (int i = 0; i < overrideCount; ++i)
							{
								IMethodDeclaration resolvedInterfaceMethod = overrides[i].Resolve();
								if (interfaceDeclToMemberDeclMap.ContainsKey(resolvedInterfaceMethod))
								{
									interfaceDeclToMemberDeclMap[resolvedInterfaceMethod] = methodDecl;
									IMethodDeclaration translatedMethodDecl;
									try
									{
										translatedMethodDecl = translator.TranslateMethodDeclaration(methodDecl);
									}
									catch
									{
										translatedMethodDecl = null;
									}
									IStatementCollection statements;
									IBlockStatement bodyStatement;
									bool matchedDeferToPattern = false;
									if (translatedMethodDecl != null &&
										null != (bodyStatement = translatedMethodDecl.Body as IBlockStatement) &&
										null != (statements = bodyStatement.Statements) &&
										1 == statements.Count)
									{
										IType returnType = translatedMethodDecl.ReturnType.Type;
										IExpression returnExpression = null;
										IExpressionStatement expressionStatement;
										IMethodReturnStatement returnStatement;
										if (IsVoidType(returnType))
										{
											if (null != (expressionStatement = statements[0] as IExpressionStatement))
											{
												returnExpression = expressionStatement.Expression;
											}
										}
										else if (null != (returnStatement = statements[0] as IMethodReturnStatement))
										{
											returnExpression = returnStatement.Expression;
										}
										if (returnExpression != null)
										{
											IMethodInvokeExpression methodInvokeExpression;
											IMethodReferenceExpression methodReferenceExpression;
											IMethodReference methodReference;
											IExpression targetExpression;
											ITypeReferenceExpression targetTypeReferenceExpression;
											if (null != (methodInvokeExpression = returnExpression as IMethodInvokeExpression) &&
												null != (methodReferenceExpression = methodInvokeExpression.Method as IMethodReferenceExpression) &&
												((targetExpression = methodReferenceExpression.Target) is IThisReferenceExpression ||
												(null != (targetTypeReferenceExpression = targetExpression as ITypeReferenceExpression) &&
												targetTypeReferenceExpression.Type.Equals(typeDeclaration))) &&
												null != (methodReference = methodReferenceExpression.Method) &&
												methodReference.DeclaringType.Equals(typeDeclaration) &&
												AreSignaturesEqual(methodDecl, methodReference))
											{
												IExpressionCollection invokeArguments = methodInvokeExpression.Arguments;
												int argCount = invokeArguments.Count;
												int argIndex = 0;
												if (argCount != 0)
												{
													IParameterDeclarationCollection parameters = methodDecl.Parameters;
													for (; argIndex < argCount; ++argIndex)
													{
														IExpression expression = invokeArguments[argIndex];
														IArgumentReferenceExpression argumentReference = null;
														IAddressOutExpression outExpression;
														IAddressReferenceExpression refExpression;
														for (; ; )
														{
															// Note that the signatures have already been checked, only need to resolve the derefs to
															// get the underlying argument reference
															if (null != (argumentReference = expression as IArgumentReferenceExpression))
															{
																break;
															}
															else if (null != (refExpression = expression as IAddressReferenceExpression))
															{
																expression = refExpression.Expression;
															}
															else if (null != (outExpression = expression as IAddressOutExpression))
															{
																expression = outExpression.Expression;
															}
															else
															{
																break;
															}
														}
														if (argumentReference != null &&
															argumentReference.Parameter.Name == parameters[argIndex].Name)
														{
															continue;
														}
														break;
													}
												}
												if (argCount == argIndex)
												{
													matchedDeferToPattern = true;
													// Map this explicit interface implementation to the matching method on this type declaration to
													// signal the deferred pattern
													AddInterfaceMemberMap(methodDecl, methodReference);
													// Map the method declaration in this type back to the interface method
													AddInterfaceMemberMap(methodReference.Resolve(), resolvedInterfaceMethod);
												}
											}
										}
									}
									if (!matchedDeferToPattern)
									{
										AddInterfaceMemberMap(methodDecl, resolvedInterfaceMethod);
									}
								}
							}
						}

						// Step 2b: Explicitly bind property methods
						IPropertyDeclarationCollection properties = typeDeclaration.Properties;
						foreach (IPropertyDeclaration propertyDecl in properties)
						{
							IMethodDeclaration[] methodDecls = new IMethodDeclaration[]{
								// Note that the get/set order here is relied on during pattern matching below
								ResolveAccessorMethod(propertyDecl.GetMethod),
								ResolveAccessorMethod(propertyDecl.SetMethod)};
							for (int accessorMethodIndex = 0; accessorMethodIndex < methodDecls.Length; ++accessorMethodIndex)
							{
								IMethodDeclaration methodDecl = methodDecls[accessorMethodIndex];
								if (methodDecl == null)
								{
									continue;
								}
								// Create a reverse mapping from the method to the containing property. We
								// need someplace to keep this mapping (there is no natural mapping from
								// an accessor method back to its associated property), and this is as
								// good a place as any to put the reverse map so we don't have to search later.
								interfaceDeclToMemberDeclMap[methodDecl] = propertyDecl;
								IMethodReferenceCollection overrides = methodDecl.Overrides;
								int overrideCount = overrides.Count;
								for (int i = 0; i < overrideCount; ++i)
								{
									IMethodDeclaration resolvedInterfaceMethod = overrides[i].Resolve();
									if (interfaceDeclToMemberDeclMap.ContainsKey(resolvedInterfaceMethod))
									{
										interfaceDeclToMemberDeclMap[resolvedInterfaceMethod] = methodDecl;
										IMethodDeclaration translatedMethodDecl;
										try
										{
											translatedMethodDecl = translator.TranslateMethodDeclaration(methodDecl);
										}
										catch
										{
											translatedMethodDecl = null;
										}
										IStatementCollection statements;
										IBlockStatement bodyStatement;
										bool matchedDeferToPattern = false;
										if (translatedMethodDecl != null &&
											null != (bodyStatement = translatedMethodDecl.Body as IBlockStatement) &&
											null != (statements = bodyStatement.Statements) &&
											1 == statements.Count)
										{
											IExpressionStatement expressionStatement;
											IMethodReturnStatement returnStatement;
											IExpression somePropertyExpression;
											IPropertyIndexerExpression propertyIndexerExpression = null;
											IPropertyReferenceExpression propertyReferenceExpression;
											IPropertyReference propertyReference;
											IPropertyDeclaration propertyDeclaration;
											IExpression targetExpression;
											ITypeReferenceExpression targetTypeReferenceExpression;
											IMethodReference methodReference = null;
											IAssignExpression assignExpression = null;
											if (accessorMethodIndex == 0)
											{
												// Getter pattern
												if (null != (returnStatement = statements[0] as IMethodReturnStatement) &&
													(null != (propertyReferenceExpression = (somePropertyExpression = returnStatement.Expression) as IPropertyReferenceExpression) ||
													(null != (propertyIndexerExpression = somePropertyExpression as IPropertyIndexerExpression) &&
													null != (propertyReferenceExpression = propertyIndexerExpression.Target))) &&
													((targetExpression = propertyReferenceExpression.Target) is IThisReferenceExpression ||
													(null != (targetTypeReferenceExpression = targetExpression as ITypeReferenceExpression) &&
													targetTypeReferenceExpression.Type.Equals(typeDeclaration))) &&
													null != (propertyReference = propertyReferenceExpression.Property) &&
													propertyReference.DeclaringType.Equals(typeDeclaration) &&
													null != (propertyDeclaration = propertyReference.Resolve()) &&
													null != (methodReference = propertyDeclaration.GetMethod) &&
													AreSignaturesEqual(methodDecl, methodReference))
												{
													matchedDeferToPattern = true;
												}
											}
											else
											{
												// Setter pattern
												IType returnType = translatedMethodDecl.ReturnType.Type;
												if (IsVoidType(returnType) &&
													null != (expressionStatement = statements[0] as IExpressionStatement) &&
													null != (assignExpression = expressionStatement.Expression as IAssignExpression) &&
													// Note that there should only be one argument on the method if this is consider to be a true property
													// and not an indexer.
													assignExpression.Expression is IArgumentReferenceExpression &&
													(null != (propertyReferenceExpression = (somePropertyExpression = assignExpression.Target) as IPropertyReferenceExpression) ||
													(null != (propertyIndexerExpression = somePropertyExpression as IPropertyIndexerExpression) &&
													null != (propertyReferenceExpression = propertyIndexerExpression.Target))) &&
													((targetExpression = propertyReferenceExpression.Target) is IThisReferenceExpression ||
													(null != (targetTypeReferenceExpression = targetExpression as ITypeReferenceExpression) &&
													targetTypeReferenceExpression.Type.Equals(typeDeclaration))) &&
													null != (propertyReference = propertyReferenceExpression.Property) &&
													propertyReference.DeclaringType.Equals(typeDeclaration) &&
													null != (propertyDeclaration = propertyReference.Resolve()) &&
													null != (methodReference = propertyDeclaration.SetMethod) &&
													AreSignaturesEqual(methodDecl, methodReference))
												{
													matchedDeferToPattern = true;
												}
											}
											// Note that parametrized non-default properties can be generated by VB, but are
											// recognized by reflector as a method call directly to the accessor method.
											// This is a Reflector bug

											if (matchedDeferToPattern)
											{
												// Map this explicit interface implementation to the matching method on this type declaration to
												// signal the deferred pattern
												AddInterfaceMemberMap(methodDecl, methodReference);
												// Map the method declaration in this type back to the interface method
												AddInterfaceMemberMap(methodReference.Resolve(), resolvedInterfaceMethod);
											}
										}
										if (!matchedDeferToPattern)
										{
											AddInterfaceMemberMap(methodDecl, resolvedInterfaceMethod);
										}
									}
								}
							}
						}

						// Step 2c: Explicitly bind event methods
						IEventDeclarationCollection events = typeDeclaration.Events;
						foreach (IEventDeclaration eventDecl in events)
						{
							IMethodDeclaration[] methodDecls = new IMethodDeclaration[]{
								// Note that the add/remove/invoke order here is relied on during pattern matching below
								ResolveAccessorMethod(eventDecl.AddMethod),
								ResolveAccessorMethod(eventDecl.RemoveMethod)};
							// Note that there are raise event accessor methods as well, but they are not
							// currently implemented in any .NET language on interfaces, so there is no need to compare

							for (int accessorMethodIndex = 0; accessorMethodIndex < methodDecls.Length; ++accessorMethodIndex)
							{
								IMethodDeclaration methodDecl = methodDecls[accessorMethodIndex];
								if (methodDecl == null)
								{
									continue;
								}
								// Create a reverse mapping from the method to the containing event. We
								// need someplace to keep this mapping (there is no natural mapping from
								// an accessor method back to its associated event), and this is as
								// good a place as any to put the reverse map so we don't have to search later.
								interfaceDeclToMemberDeclMap[methodDecl] = eventDecl;
								IMethodReferenceCollection overrides = methodDecl.Overrides;
								int overrideCount = overrides.Count;
								for (int i = 0; i < overrideCount; ++i)
								{
									IMethodDeclaration resolvedInterfaceMethod = overrides[i].Resolve();
									if (interfaceDeclToMemberDeclMap.ContainsKey(resolvedInterfaceMethod))
									{
										interfaceDeclToMemberDeclMap[resolvedInterfaceMethod] = methodDecl;
										IMethodDeclaration translatedMethodDecl;
										try
										{
											translatedMethodDecl = translator.TranslateMethodDeclaration(methodDecl);
										}
										catch
										{
											translatedMethodDecl = null;
										}
										IStatementCollection statements;
										IBlockStatement bodyStatement;
										bool matchedDeferToPattern = false;
										if (translatedMethodDecl != null &&
											null != (bodyStatement = translatedMethodDecl.Body as IBlockStatement) &&
											null != (statements = bodyStatement.Statements) &&
											1 == statements.Count)
										{
											IAttachEventStatement attachEvent;
											IRemoveEventStatement detachEvent;
											IEventReferenceExpression eventReferenceExpression;
											IEventReference eventReference;
											IEventDeclaration eventDeclaration;
											IMethodReference methodReference = null;
											IExpression targetExpression;
											ITypeReferenceExpression targetTypeReferenceExpression;
											if (accessorMethodIndex == 0)
											{
												// AttachEvent pattern
												if (null != (attachEvent = statements[0] as IAttachEventStatement) &&
													null != (eventReferenceExpression = attachEvent.Event) &&
													((targetExpression = eventReferenceExpression.Target) is IThisReferenceExpression ||
													(null != (targetTypeReferenceExpression = targetExpression as ITypeReferenceExpression) &&
													targetTypeReferenceExpression.Type == typeDeclaration)) &&
													null != (eventReference = eventReferenceExpression.Event) &&
													eventReference.DeclaringType == typeDeclaration &&
													null != (eventDeclaration = eventReference.Resolve()) &&
													null != (methodReference = eventDeclaration.AddMethod) &&
													AreSignaturesEqual(methodDecl, methodReference))
												{
													matchedDeferToPattern = true;
												}
											}
											else // if (accessorMethodIndex == 1)
											{
												// AttachEvent pattern
												if (null != (detachEvent = statements[0] as IRemoveEventStatement) &&
													null != (eventReferenceExpression = detachEvent.Event) &&
													((targetExpression = eventReferenceExpression.Target) is IThisReferenceExpression ||
													(null != (targetTypeReferenceExpression = targetExpression as ITypeReferenceExpression) &&
													targetTypeReferenceExpression.Type.Equals(typeDeclaration))) &&
													null != (eventReference = eventReferenceExpression.Event) &&
													eventReference.DeclaringType.Equals(typeDeclaration) &&
													null != (eventDeclaration = eventReference.Resolve()) &&
													null != (methodReference = eventDeclaration.RemoveMethod) &&
													AreSignaturesEqual(methodDecl, methodReference))
												{
													matchedDeferToPattern = true;
												}
											}

											if (matchedDeferToPattern)
											{
												// Map this explicit interface implementation to the matching method on this type declaration to
												// signal the deferred pattern
												AddInterfaceMemberMap(methodDecl, methodReference);
												// Map the method declaration in this type back to the interface method
												AddInterfaceMemberMap(methodReference.Resolve(), resolvedInterfaceMethod);
											}
										}
										if (!matchedDeferToPattern)
										{
											AddInterfaceMemberMap(methodDecl, resolvedInterfaceMethod);
										}
									}
								}
							}
						}

						// Step 3: Walk unbound interface members.
						// Methods are bound by name and signature, properties and events are bound based on the
						// bindings of the corresponding underlying methods.
						foreach (IMemberDeclaration interfaceMember in interfaceDeclToMemberDeclMap.Keys)
						{
							if (null == interfaceDeclToMemberDeclMap[interfaceMember])
							{
								IMethodDeclaration unboundMethod;
								IPropertyDeclaration unboundProperty;
								IEventDeclaration unboundEvent;
								if (null != (unboundMethod = interfaceMember as IMethodDeclaration))
								{
									if (!unboundMethod.SpecialName)
									{
										string searchForName = unboundMethod.Name;
										foreach (IMethodDeclaration methodDecl in methods)
										{
											if (methodDecl.Visibility == MethodVisibility.Public &&
												!methodDecl.SpecialName &&
												0 == string.CompareOrdinal(methodDecl.Name, searchForName) &&
												AreSignaturesEqual(unboundMethod, methodDecl))
											{
												AddInterfaceMemberMap(methodDecl, unboundMethod);
												break;
											}
										}
									}
								}
								else if (null != (unboundProperty = interfaceMember as IPropertyDeclaration))
								{
									IMethodDeclaration[] methodDecls = new IMethodDeclaration[]{
										ResolveAccessorMethod(unboundProperty.GetMethod),
										ResolveAccessorMethod(unboundProperty.SetMethod)};

									// There are three properties we're potentially dealing with here
									// 1) The property defined on the interface (interfaceMember)
									// 2) The property whose methods explicitly implement that interface (explicitImplPropertyDecl)
									// 3) The property each of the implementing methods refer to (deferredImplPropertyDecl)

									IMemberDeclaration explicitImplPropertyDecl = null;
									IMemberDeclaration deferredImplPropertyDecl = null;
									bool inconsistentExplicitImplPattern = false;
									bool inconsistentDeferredImplPattern = false;
									for (int accessorMethodIndex = 0; accessorMethodIndex < methodDecls.Length && !inconsistentExplicitImplPattern; ++accessorMethodIndex)
									{
										IMethodDeclaration methodDecl = methodDecls[accessorMethodIndex];
										if (methodDecl == null)
										{
											continue;
										}
										IMemberDeclaration memberDeclMethod;
										if (null != (memberDeclMethod = interfaceDeclToMemberDeclMap[methodDecl]))
										{
											// Grab any reverse mapping we have from the method to the associated implementation property in step 2b
											IMemberDeclaration memberDeclPropertyImpl;
											if (interfaceDeclToMemberDeclMap.TryGetValue(memberDeclMethod, out memberDeclPropertyImpl))
											{
												foreach (IMethodReference mappedMember in GetInterfaceMembers(memberDeclMethod))
												{
													if (explicitImplPropertyDecl == null)
													{
														explicitImplPropertyDecl = memberDeclPropertyImpl;
													}
													else if (explicitImplPropertyDecl != memberDeclPropertyImpl)
													{
														inconsistentExplicitImplPattern = true;
														break;
													}
													if (!inconsistentDeferredImplPattern)
													{
														IMethodDeclaration implMethodDecl = mappedMember.Resolve();
														if (implMethodDecl != methodDecl)
														{
															IMemberDeclaration testDeferredImplProperty = interfaceDeclToMemberDeclMap[implMethodDecl];
															if (deferredImplPropertyDecl == null)
															{
																deferredImplPropertyDecl = testDeferredImplProperty;
															}
															else if (testDeferredImplProperty != deferredImplPropertyDecl)
															{
																deferredImplPropertyDecl = null;
																inconsistentDeferredImplPattern = true;
															}
														}
														else
														{
															deferredImplPropertyDecl = null;
															inconsistentDeferredImplPattern = true;
														}
													}
												}
											}
										}
									}

									if (!inconsistentExplicitImplPattern)
									{
										// If the explicit overrides are inconsistent there isn't really anything we can do
										if (explicitImplPropertyDecl != null)
										{
											if (deferredImplPropertyDecl != null)
											{
												AddInterfaceMemberMap(explicitImplPropertyDecl, deferredImplPropertyDecl);
												AddInterfaceMemberMap(deferredImplPropertyDecl, interfaceMember);
											}
											else
											{
												AddInterfaceMemberMap(explicitImplPropertyDecl, interfaceMember);
											}
										}
										else
										{
											string searchForName = unboundProperty.Name;
											IType searchForPropertyType = unboundProperty.PropertyType;
											IMethodReference unboundGetter = unboundProperty.GetMethod;
											IMethodReference unboundSetter = unboundProperty.SetMethod;
											IMethodDeclaration accessorMethod;
											foreach (IPropertyDeclaration propertyDecl in properties)
											{
												// Although property names cannot be overloaded, there is still no guarantee that
												// a parametrized property is the correct match, so we check the signatures on the
												// accessor methods.
												if (!propertyDecl.SpecialName &&
													0 == string.CompareOrdinal(propertyDecl.Name, searchForName) &&
													propertyDecl.PropertyType.Equals(searchForPropertyType) &&
													((unboundGetter == null) || (null != (accessorMethod = ResolveAccessorMethod(propertyDecl.GetMethod)) && accessorMethod.Visibility == MethodVisibility.Public && AreSignaturesEqual(accessorMethod, unboundGetter))) &&
													((unboundSetter == null) || (null != (accessorMethod = ResolveAccessorMethod(propertyDecl.SetMethod)) && accessorMethod.Visibility == MethodVisibility.Public && AreSignaturesEqual(accessorMethod, unboundSetter))))
												{
													AddInterfaceMemberMap(propertyDecl, unboundProperty);
													break;
												}
											}
										}
									}
								}
								else if (null != (unboundEvent = interfaceMember as IEventDeclaration))
								{
									IMethodDeclaration[] methodDecls = new IMethodDeclaration[]{
										// Note that the get/set order here is relied on during pattern matching below
										ResolveAccessorMethod(unboundEvent.AddMethod),
										ResolveAccessorMethod(unboundEvent.RemoveMethod)};

									// There are three events we're potentially dealing with here
									// 1) The event defined on the interface (interfaceMember)
									// 2) The event whose methods explicitly implement that interface (explicitImplEventDecl)
									// 3) The event each of the implementing methods refer to (deferredImplEventDecl)

									IMemberDeclaration explicitImplEventDecl = null;
									IMemberDeclaration deferredImplEventDecl = null;
									bool inconsistentExplicitImplPattern = false;
									bool inconsistentDeferredImplPattern = false;
									for (int accessorMethodIndex = 0; accessorMethodIndex < methodDecls.Length && !inconsistentExplicitImplPattern; ++accessorMethodIndex)
									{
										IMethodDeclaration methodDecl = methodDecls[accessorMethodIndex];
										if (methodDecl == null)
										{
											continue;
										}
										IMemberDeclaration memberDeclMethod;
										if (null != (memberDeclMethod = interfaceDeclToMemberDeclMap[methodDecl]))
										{
											// Grab any reverse mapping we have from the method to the associated implementation property in step 2b
											IMemberDeclaration memberDeclEventImpl;
											if (interfaceDeclToMemberDeclMap.TryGetValue(memberDeclMethod, out memberDeclEventImpl))
											{
												foreach (IMethodReference mappedMember in GetInterfaceMembers(memberDeclMethod))
												{
													if (explicitImplEventDecl == null)
													{
														explicitImplEventDecl = memberDeclEventImpl;
													}
													else if (explicitImplEventDecl != memberDeclEventImpl)
													{
														inconsistentExplicitImplPattern = true;
														break;
													}
													if (!inconsistentDeferredImplPattern)
													{
														IMethodDeclaration implMethodDecl = mappedMember.Resolve();
														if (implMethodDecl != methodDecl)
														{
															IMemberDeclaration testDeferredImplEvent = interfaceDeclToMemberDeclMap[implMethodDecl];
															if (deferredImplEventDecl == null)
															{
																deferredImplEventDecl = testDeferredImplEvent;
															}
															else if (testDeferredImplEvent != deferredImplEventDecl)
															{
																deferredImplEventDecl = null;
																inconsistentDeferredImplPattern = true;
															}
														}
														else
														{
															deferredImplEventDecl = null;
															inconsistentDeferredImplPattern = true;
														}
													}
												}
											}
										}
									}

									if (!inconsistentExplicitImplPattern)
									{
										// If the explicit overrides are inconsistent there isn't really anything we can do
										if (explicitImplEventDecl != null)
										{
											if (deferredImplEventDecl != null)
											{
												AddInterfaceMemberMap(explicitImplEventDecl, deferredImplEventDecl);
												AddInterfaceMemberMap(deferredImplEventDecl, interfaceMember);
											}
											else
											{
												AddInterfaceMemberMap(explicitImplEventDecl, interfaceMember);
											}
										}
										else
										{
											string searchForName = unboundEvent.Name;
											IType searchForEventType = unboundEvent.EventType;
											bool checkAttach = unboundEvent.AddMethod != null;
											bool checkDetach = unboundEvent.RemoveMethod != null;
											IMethodDeclaration accessorMethod;
											foreach (IEventDeclaration eventDecl in events)
											{
												if (!eventDecl.SpecialName &&
													0 == string.CompareOrdinal(eventDecl.Name, searchForName) &&
													eventDecl.EventType.Equals(searchForEventType) &&
													(!checkAttach || (null != (accessorMethod = ResolveAccessorMethod(eventDecl.AddMethod)) && accessorMethod.Visibility == MethodVisibility.Public)) &&
													(!checkDetach || (null != (accessorMethod = ResolveAccessorMethod(eventDecl.RemoveMethod)) && accessorMethod.Visibility == MethodVisibility.Public)))
												{
													// Note that signatures for any raise_ methods that might be defined must be consistent with the EventType
													// on both ends. There is no requirement to match raise_ methods (they are not on interfaces, and are not public even on classes)
													AddInterfaceMemberMap(eventDecl, unboundEvent);
													break;
												}
											}
										}
									}
								}
							}
						}
					}
				}
				private static IMethodDeclaration ResolveAccessorMethod(IMethodReference methodReference)
				{
					return (methodReference != null) ? methodReference.Resolve() : null;
				}
				private void AddInterfaceMemberMap(IMemberDeclaration memberDeclaration, IMemberReference memberReference)
				{
					ICollection<IMemberReference> existingInterfaceMembers;
					Dictionary<IMemberDeclaration, ICollection<IMemberReference>> map = myInterfaceMemberMap;
					if (map.TryGetValue(memberDeclaration, out existingInterfaceMembers))
					{
						LinkedList<IMemberReference> memberReferenceList;
						if (existingInterfaceMembers is Array)
						{
							memberReferenceList = new LinkedList<IMemberReference>(existingInterfaceMembers);
							myInterfaceMemberMap[memberDeclaration] = memberReferenceList;
						}
						else
						{
							memberReferenceList = (LinkedList<IMemberReference>)existingInterfaceMembers;
						}
						memberReferenceList.AddLast(memberReference);
					}
					else
					{
						myInterfaceMemberMap[memberDeclaration] = new IMemberReference[] { memberReference };
					}
				}
				/// <summary>
				/// Seed the interface member to class member mapping dictionary keys with all possible values. Called recursively.
				/// </summary>
				private static void SeedInterfaceMembers(Dictionary<IMemberDeclaration, IMemberDeclaration> interfaceDeclToMemberDeclMap, ITypeReferenceCollection interfaces)
				{
					int interfaceCount = interfaces.Count;
					for (int i = 0; i < interfaceCount; ++i)
					{
						ITypeDeclaration interfaceDeclaration = interfaces[i].Resolve();
						foreach (IMethodDeclaration methodDecl in interfaceDeclaration.Methods)
						{
							interfaceDeclToMemberDeclMap[methodDecl] = null;
						}
						foreach (IPropertyDeclaration propertyDecl in interfaceDeclaration.Properties)
						{
							// Map the property back to a get or set method
							IMethodDeclaration getMethod = ResolveAccessorMethod(propertyDecl.GetMethod);
							IMethodDeclaration setMethod = ResolveAccessorMethod(propertyDecl.SetMethod);
							interfaceDeclToMemberDeclMap[propertyDecl] = null;
							if (getMethod != null)
							{
								interfaceDeclToMemberDeclMap[getMethod] = null;
							}
							if (setMethod != null)
							{
								interfaceDeclToMemberDeclMap[setMethod] = null;
							}
						}
						foreach (IEventDeclaration eventDecl in interfaceDeclaration.Events)
						{
							IMethodDeclaration addMethod = ResolveAccessorMethod(eventDecl.AddMethod);
							IMethodDeclaration removeMethod = ResolveAccessorMethod(eventDecl.RemoveMethod);
							IMethodDeclaration invokeMethod = ResolveAccessorMethod(eventDecl.InvokeMethod);
							interfaceDeclToMemberDeclMap[eventDecl] = null;
							if (addMethod != null)
							{
								interfaceDeclToMemberDeclMap[addMethod] = null;
							}
							if (removeMethod != null)
							{
								interfaceDeclToMemberDeclMap[removeMethod] = null;
							}
							if (invokeMethod != null)
							{
								interfaceDeclToMemberDeclMap[invokeMethod] = null;
							}
						}
						SeedInterfaceMembers(interfaceDeclToMemberDeclMap, interfaceDeclaration.Interfaces);
					}
				}
				#endregion // InterfaceMember mapping
			}
			#endregion // MemberMapper class
			#endregion // Interface and event member mapping
		}
		#endregion // PLiXLanguageWriter class
	}
	#endregion // PLiXLanguage class
}
