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
				myWriter = retVal = new PLiXLanguageWriter(myTranslatorManager.Disassembler, myConfiguration);
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
			private IMethodBody myCurrentMethodBody;
			private IMethodDeclaration myCurrentMethodDeclaration;
			private StringBuilder myEscapeTextStringBuilder;
			private StringWriter myEscapeTextStringWriter;
			private XmlTextWriter myEscapeTextXmlWriter;
			#endregion // Member Variables
			#region Constructors
			public PLiXLanguageWriter(ITranslator translator, IPLiXConfiguration configuration)
			{
				myTranslator = translator;
				myOpenElements = new Stack<string>();
				myPLiXConfiguration = configuration;
			}
			public void Associate(IFormatter formatter, ILanguageWriterConfiguration configuration)
			{
				myFormatter = formatter;
				myWriterConfiguration = configuration;
				myShowCustomAttributes = configuration["ShowCustomAttributes"] == "true";
				myShowDocumentation = configuration["ShowDocumentation"] == "true";
			}
			#endregion // Constructors
			#region ILanguageWriter Implementation
			/// <summary>
			///  Implements ILanguageWriter.WriteAssembly
			/// </summary>
			protected void WriteAssembly(IAssembly value)
			{
				bool detailedForm = myShowCustomAttributes;
				myFirstWrite = detailedForm;
				if (detailedForm)
				{
					value = myTranslator.TranslateAssembly(value);
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
				myFirstWrite = detailedForm;
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
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				myFirstWrite = detailedForm;
				Render(value, detailedForm);
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
				myFirstWrite = detailedForm;
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
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				myFirstWrite = detailedForm;
				Render(value, detailedForm);
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
				myFirstWrite = detailedForm;
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
				myFirstWrite = detailedForm;
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
				myFirstWrite = detailedForm;
				Render(value, detailedForm, detailedForm && myPLiXConfiguration.FullyExpandNamespaceDeclarations);
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
				bool detailedForm = myWriterConfiguration["ShowMethodDeclarationBody"] == "true";
				myFirstWrite = detailedForm;
				Render(value, detailedForm);
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
				myFirstWrite = detailedForm;
				Render(value, detailedForm, detailedForm && myPLiXConfiguration.FullyExpandTypeDeclarations);
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
			private string EscapeText(string text)
			{
				StringBuilder builder = myEscapeTextStringBuilder;
				StringWriter stringWriter;
				XmlTextWriter xmlWriter;
				if (builder == null)
				{
					myEscapeTextStringBuilder = builder = new StringBuilder();
					myEscapeTextStringWriter = stringWriter = new StringWriter(builder);
					myEscapeTextXmlWriter = xmlWriter = new XmlTextWriter(stringWriter);
				}
				else
				{
					stringWriter = myEscapeTextStringWriter;
					xmlWriter = myEscapeTextXmlWriter;
				}
				xmlWriter.WriteValue(text);
				stringWriter.Flush();
				text = builder.ToString();
				builder.Length = 0;
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
		}
		#endregion // PLiXLanguageWriter class
	}
	#endregion // PLiXLanguage class
}
