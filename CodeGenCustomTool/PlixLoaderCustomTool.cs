using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.Shell.Interop;
using MsOle = Microsoft.VisualStudio.OLE.Interop;
using System.Runtime.InteropServices;
using System.IO;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Designer.Interfaces;
using System.Text;
using System.Diagnostics;
using System.Globalization;
using System.CodeDom;
using System.CodeDom.Compiler;
using System.Xml;
using System.Xml.XPath;
using System.Xml.Xsl;
using VSLangProj;

namespace Neumont.Tools.CodeGeneration
{
	/// <summary>
	/// A custom tool to generate code using the Plix code generation framework
	/// </summary>
	public sealed class PlixLoaderCustomTool : IVsSingleFileGenerator, MsOle.IObjectWithSite
	{
		#region Schema definition classes
		#region PlixLoaderSchema class
		private static class PlixLoaderSchema
		{
			#region String Constants
			public const string SchemaNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiXLoader";
			public const string TransformFileAttribute = "transformFile";
			public const string ProjectReferenceElement = "projectReference";
			public const string NamespaceAttribute = "namespace";
			public const string AssemblyAttribute = "assembly";
			public const string ExtensionClassElement = "extensionClass";
			public const string XslNamespaceAttribute = "xslNamespace";
			public const string ClassNameAttribute = "className";
			public const string LiveDocumentObjectAttribute = "liveDocumentObject";
			public const string TransformParameterElement = "transformParameter";
			public const string NameAttribute = "name";
			public const string ValueAttribute = "value";
			public const string SourceFileElement = "sourceFile";
			public const string FileAttribute = "file";
			#endregion // String Constants
			#region Static properties
			private static PlixLoaderNameTable myNames;
			public static PlixLoaderNameTable Names
			{
				get
				{
					PlixLoaderNameTable retVal = myNames;
					if (retVal == null)
					{
						lock (LockObject)
						{
							retVal = myNames;
							if (retVal == null)
							{
								retVal = myNames = new PlixLoaderNameTable();
							}
						}
					}
					return retVal;
				}
			}
			private static XmlReaderSettings myReaderSettings;
			public static XmlReaderSettings ReaderSettings
			{
				get
				{
					XmlReaderSettings retVal = myReaderSettings;
					if (retVal == null)
					{
						lock (LockObject)
						{
							retVal = myReaderSettings;
							if (retVal == null)
							{
								retVal = myReaderSettings = new XmlReaderSettings();
								retVal.ValidationType = ValidationType.Schema;
								retVal.Schemas.Add(SchemaNamespace, new XmlTextReader(typeof(PlixLoaderCustomTool).Assembly.GetManifestResourceStream(typeof(PlixLoaderCustomTool), "PlixLoader.xsd")));
								retVal.NameTable = Names;
							}
						}
					}
					return retVal;
				}
			}
			#endregion // Static properties
		}
		#endregion // PlixLoaderSchema class
		#region PlixLoaderNameTable class
		private class PlixLoaderNameTable : NameTable
		{
			public readonly string SchemaNamespace;
			public readonly string TransformFileAttribute;
			public readonly string ProjectReferenceElement;
			public readonly string NamespaceAttribute;
			public readonly string AssemblyAttribute;
			public readonly string ExtensionClassElement;
			public readonly string XslNamespaceAttribute;
			public readonly string ClassNameAttribute;
			public readonly string LiveDocumentObjectAttribute;
			public readonly string TransformParameterElement;
			public readonly string NameAttribute;
			public readonly string ValueAttribute;
			public readonly string SourceFileElement;
			public readonly string FileAttribute;
			public PlixLoaderNameTable() : base()
			{
				SchemaNamespace = Add(PlixLoaderSchema.SchemaNamespace);
				TransformFileAttribute = Add(PlixLoaderSchema.TransformFileAttribute);
				ProjectReferenceElement = Add(PlixLoaderSchema.ProjectReferenceElement);
				NamespaceAttribute = Add(PlixLoaderSchema.NamespaceAttribute);
				AssemblyAttribute = Add(PlixLoaderSchema.AssemblyAttribute);
				ExtensionClassElement = Add(PlixLoaderSchema.ExtensionClassElement);
				XslNamespaceAttribute = Add(PlixLoaderSchema.XslNamespaceAttribute);
				ClassNameAttribute = Add(PlixLoaderSchema.ClassNameAttribute);
				LiveDocumentObjectAttribute = Add(PlixLoaderSchema.LiveDocumentObjectAttribute);
				TransformParameterElement = Add(PlixLoaderSchema.TransformParameterElement);
				NameAttribute = Add(PlixLoaderSchema.NameAttribute);
				ValueAttribute = Add(PlixLoaderSchema.ValueAttribute);
				SourceFileElement = Add(PlixLoaderSchema.SourceFileElement);
				FileAttribute = Add(PlixLoaderSchema.FileAttribute);
			}
		}
		#endregion // PlixLoaderNameTable class
		#region PlixSettingsSchema class
		private static class PlixSettingsSchema
		{
			#region String Constants
			public const string SchemaNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiXSettings";
			public const string FormatterElement = "formatter";
			public const string FormattersElement = "formatters";
			public const string FileExtensionAttribute = "fileExtension";
			public const string TransformAttribute = "transform";
			#endregion // String Constants
			#region Static properties
			private static PlixSettingsNameTable myNames;
			public static PlixSettingsNameTable Names
			{
				get
				{
					PlixSettingsNameTable retVal = myNames;
					if (retVal == null)
					{
						lock (LockObject)
						{
							retVal = myNames;
							if (retVal == null)
							{
								retVal = myNames = new PlixSettingsNameTable();
							}
						}
					}
					return retVal;
				}
			}
			private static XmlReaderSettings myReaderSettings;
			public static XmlReaderSettings ReaderSettings
			{
				get
				{
					XmlReaderSettings retVal = myReaderSettings;
					if (retVal == null)
					{
						lock (LockObject)
						{
							retVal = myReaderSettings;
							if (retVal == null)
							{
								retVal = myReaderSettings = new XmlReaderSettings();
								retVal.ValidationType = ValidationType.Schema;
								retVal.Schemas.Add(SchemaNamespace, new XmlTextReader(typeof(PlixLoaderCustomTool).Assembly.GetManifestResourceStream(typeof(PlixLoaderCustomTool), "PlixSettings.xsd")));
								retVal.NameTable = Names;
							}
						}
					}
					return retVal;
				}
			}
			#endregion // Static properties
		}
		#endregion // PlixSettingsSchema class
		#region PlixSettingsNameTable class
		private class PlixSettingsNameTable : NameTable
		{
			public readonly string SchemaNamespace;
			public readonly string FormatterElement;
			public readonly string FormattersElement;
			public readonly string FileExtensionAttribute;
			public readonly string TransformAttribute;
			public PlixSettingsNameTable()
				: base()
			{
				SchemaNamespace = Add(PlixSettingsSchema.SchemaNamespace);
				FormatterElement = Add(PlixSettingsSchema.FormatterElement);
				FormattersElement = Add(PlixSettingsSchema.FormattersElement);
				TransformAttribute = Add(PlixSettingsSchema.TransformAttribute);
				FileExtensionAttribute = Add(PlixSettingsSchema.FileExtensionAttribute);
			}
		}
		#endregion // PlixSettingsNameTable class
		#region PLiX ReaderSettings
		private const string PlixSchemaNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiX";
		private static XmlReaderSettings myPlixReaderSettings;
		private static XmlReaderSettings PlixReaderSettings
		{
			get
			{
				XmlReaderSettings retVal = myPlixReaderSettings;
				if (retVal == null)
				{
					lock (LockObject)
					{
						retVal = myPlixReaderSettings;
						if (retVal == null)
						{
							myPlixReaderSettings = retVal = new XmlReaderSettings();
							retVal.ValidationType = ValidationType.Schema;
							retVal.Schemas.Add(PlixSchemaNamespace, new XmlTextReader(typeof(PlixLoaderCustomTool).Assembly.GetManifestResourceStream(typeof(PlixLoaderCustomTool), "PLiX.xsd")));
						}
					}
				}
				return retVal;
			}
		}
		#endregion // PLiX ReaderSettings
		#endregion // Schema definition classes
		#region Member Variables
		private MsOle.IServiceProvider myServiceProvider;
		private CodeDomProvider myCodeDomProvider;
		private EnvDTE.ProjectItem myProjectItem;
		private const string PlixProjectSettingsFile = "Plix.xml";
		private const string CustomToolName = "NUPlixLoader";
		private const string RedirectNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiXRedirect";
		private const string RedirectElementName = "redirectSourceFile";
		private const string RedirectTargetAttribute = "target";
		private const string PlixRelativeDirectory = @"\..\..\Neumont\CodeGeneration\PLiX\";
		private const string FormattersDirectory = @"Formatters\";
		private const string PlixGlobalSettingsFile = "PLiXSettings.xml";
		#endregion // Member Variables
		#region Static variables
		private static Dictionary<string, Formatter> myFormattersDictionary;
		private static string myPlixDirectory;
		private static object myLockObject;
		private static object LockObject
		{
			get
			{
				if (myLockObject == null)
				{
					object lockObj = new object();
					System.Threading.Interlocked.CompareExchange(ref myLockObject, lockObj, null);
				}
				return myLockObject;
			}
		}
		#endregion // Static variables
		#region Constructor
		/// <summary>
		/// Public constructor
		/// </summary>
		public PlixLoaderCustomTool()
		{
		}
		#endregion // Constructor
		#region IVsSingleFileGenerator Implementation
		int IVsSingleFileGenerator.DefaultExtension(out string pbstrDefaultExtension)
		{
			pbstrDefaultExtension = "." + CodeDomProvider.FileExtension;
			return VSConstants.S_OK;
		}
		int IVsSingleFileGenerator.Generate(string wszInputFilePath, string bstrInputFileContents, string wszDefaultNamespace, IntPtr[] rgbOutputFileContents, out uint pcbOutput, IVsGeneratorProgress pGenerateProgress)
		{
			byte[] bytes = Encoding.UTF8.GetBytes(GenerateCode(bstrInputFileContents, wszDefaultNamespace));
			byte[] preamble = Encoding.UTF8.GetPreamble();
			int bufferLength = bytes.Length + preamble.Length;
			IntPtr pBuffer = Marshal.AllocCoTaskMem(bufferLength);
			Marshal.Copy(preamble, 0, pBuffer, preamble.Length);
			Marshal.Copy(bytes, 0, (IntPtr)((uint)pBuffer + preamble.Length), bytes.Length);
			rgbOutputFileContents[0] = pBuffer;
			pcbOutput = (uint)bufferLength;
			myProjectItem = null; // No longer needed
			return VSConstants.S_OK;
		}
		#endregion // IVsSingleFileGenerator Implementation
		#region IObjectWithSite implementation
		void MsOle.IObjectWithSite.SetSite(object punkSite)
		{
			myServiceProvider = punkSite as MsOle.IServiceProvider;
			myCodeDomProvider = null;
			myProjectItem = null;
		}
		void MsOle.IObjectWithSite.GetSite(ref Guid riid, out IntPtr ppvSite)
		{
			ppvSite = IntPtr.Zero;
		}
		#endregion // IObjectWithSite implementation
		#region Service Properties
		private CodeDomProvider CodeDomProvider
		{
			get
			{
				if (myCodeDomProvider == null)
				{
					if (myServiceProvider != null)
					{
						Guid providerGuid = typeof(IVSMDCodeDomProvider).GUID;
						IntPtr pvObject = IntPtr.Zero;
						ErrorHandler.ThrowOnFailure(myServiceProvider.QueryService(ref providerGuid, ref providerGuid, out pvObject));
						if (pvObject != IntPtr.Zero)
						{
							try
							{
								IVSMDCodeDomProvider codeDomProvider = Marshal.GetObjectForIUnknown(pvObject) as IVSMDCodeDomProvider;
								if (codeDomProvider != null)
								{
									myCodeDomProvider = codeDomProvider.CodeDomProvider as CodeDomProvider;
								}
							}
							finally
							{
								Marshal.Release(pvObject);
							}
						}
					}
				}
				return myCodeDomProvider;
			}
		}
		private EnvDTE.ProjectItem CurrentProjectItem
		{
			get
			{
				if (myProjectItem == null)
				{
					if (myServiceProvider != null)
					{
						Guid providerGuid = typeof(EnvDTE.ProjectItem).GUID;
						IntPtr pvObject = IntPtr.Zero;

						ErrorHandler.ThrowOnFailure(myServiceProvider.QueryService(ref providerGuid, ref providerGuid, out pvObject));
						if (pvObject != IntPtr.Zero)
						{
							try
							{
								myProjectItem = Marshal.GetObjectForIUnknown(pvObject) as EnvDTE.ProjectItem;
							}
							finally
							{
								Marshal.Release(pvObject);
							}
						}
					}
				}
				return myProjectItem;
			}
		}
		#endregion // Service Properties
		#region XmlFileResolver class
		private class XmlFileResolver : XmlUrlResolver
		{
			private Uri myBaseUri;
			public XmlFileResolver(string baseFile)
			{
				myBaseUri = new Uri(baseFile, UriKind.Absolute);
			}
			public override Uri ResolveUri(Uri baseUri, string relativeUri)
			{
				return base.ResolveUri((baseUri == null) ? myBaseUri : baseUri, relativeUri);
			}
		}
		#endregion // XmlFileResolver class
		#region Plix specific
		/// <summary>
		/// Generate a code file for the current xml file contents. Loads
		/// settings for the file off the Plix.xml settings file in the project to
		/// get the generation transform and other settings to apply to the specific file.
		/// </summary>
		/// <param name="fileContents">Contents of an xml file to transform</param>
		/// <param name="defaultNamespace">The namespace provided in the property grid</param>
		/// <returns>Contents of the corresponding code file</returns>
		private string GenerateCode(string fileContents, string defaultNamespace)
		{
			// Make sure we have a CodeDomProvider
			CodeDomProvider provider = CodeDomProvider;
			if (provider == null)
			{
				return string.Empty;
			}

			// Get the current project item and project information
			EnvDTE.ProjectItem projectItem = CurrentProjectItem;
			string sourceFile = (string)projectItem.Properties.Item("LocalPath").Value;
			EnvDTE.Project project = projectItem.ContainingProject;
			string projectFile = (string)project.Properties.Item("LocalPath").Value;
			string projectLocation = projectFile.Substring(0, projectFile.LastIndexOf('\\') + 1);

			// If this is the Plix.xml settings file, then regenerate all other mentioned NUPlixLoader files
			if (0 == string.Compare(projectItem.Name, PlixProjectSettingsFile, true, CultureInfo.InvariantCulture))
			{
				RunCustomTool(
					project.ProjectItems,
					projectItem,
					delegate(EnvDTE.ProjectItem matchItem)
					{
						VSProjectItem vsProjItem = matchItem.Object as VSProjectItem;
						if (vsProjItem != null)
						{
							vsProjItem.RunCustomTool();
						}
					});
				StringWriter writer = new StringWriter();
				provider.GenerateCodeFromStatement(new CodeCommentStatement(
@"Empty file generated by NUPlixLoader for Plix.xml.

Setting NUPlixLoader as the custom tool on the Plix.xml settings file enables automatic
regeneration of other NUPlixLoader files in the project when the settings file is changed.

There is no way to both successfully trigger regeneration and avoid writing this file."), writer, null);
				return writer.ToString();
			}

			// Load a language formatter for this file extension
			string fileExtension = CodeDomProvider.FileExtension;
			XslCompiledTransform formatter = GetFormatterTransform(fileExtension);
			if (formatter == null)
			{
				StringWriter writer = new StringWriter();
				provider.GenerateCodeFromStatement(new CodeCommentStatement(string.Format(CultureInfo.InvariantCulture, "A PLiX formatter transform for the '{0}' language was not found.", fileExtension)), writer, null);
				return writer.ToString();
			}

			// Get options for this xml file
			XsltArgumentList arguments = new XsltArgumentList();
			string automationObjectName;
			string transformFile = LoadProjectSettings(sourceFile, projectLocation, arguments, project, out automationObjectName);

			// MSBUG: Beta2 There's a nasty bug with single-file generators right now where
			// the text for an open file that is not in a text document is
			// passed through as encoded bytes in the string.
			EnvDTE.Document itemDocument = projectItem.Document;
			if (itemDocument != null && "XML" != itemDocument.Language)
			{
				if (fileContents.Length > 1)
				{
					char[] leadChars = fileContents.ToCharArray(0, 2);
					byte[] leadBytes = new byte[2 * sizeof(char)];
					GCHandle handle = GCHandle.Alloc(leadBytes, GCHandleType.Pinned);
					Marshal.Copy(leadChars, 0, Marshal.UnsafeAddrOfPinnedArrayElement(leadBytes, 0), 2);
					handle.Free();
					EncodingInfo[] encodingInfos = Encoding.GetEncodings();
					int encodingsCount = encodingInfos.Length;
					for (int i = 0; i < encodingsCount; ++i)
					{
						EncodingInfo encodingInfo = encodingInfos[i];
						Encoding encoding = encodingInfo.GetEncoding();
						byte[] preamble = encoding.GetPreamble();
						int preambleByteCount = preamble.Length;
						if (preambleByteCount != 0)
						{
							Debug.Assert(preambleByteCount <= 4);
							int j;
							for (j = 0; j < preambleByteCount; ++j)
							{
								if (preamble[j] != leadBytes[j])
								{
									break;
								}
							}
							if (j == preambleByteCount)
							{
								Decoder decoder = encoding.GetDecoder();
								leadChars = fileContents.ToCharArray();
								int startCharCount = leadChars.Length;
								leadBytes = new byte[startCharCount * sizeof(char)];
								int byteCount = leadBytes.Length - preambleByteCount;
								GCHandle handle2 = GCHandle.Alloc(leadBytes, GCHandleType.Pinned);
								Marshal.Copy(leadChars, 0, Marshal.UnsafeAddrOfPinnedArrayElement(leadBytes, 0), startCharCount);
								handle2.Free();
								int finalCharCount = decoder.GetCharCount(leadBytes, preambleByteCount, byteCount, true);
								char[] finalChars = new char[finalCharCount + 1];
								decoder.GetChars(leadBytes, preambleByteCount, byteCount, finalChars, 0, true);

								// Hack within a hack to make sure that the Xml element has a trailing >,
								// byte data in a string has a tendency to lose the last byte
								char testChar = finalChars[finalCharCount - 1]; ;
								if (testChar != '>' && !char.IsWhiteSpace(testChar))
								{
									finalChars[finalCharCount] = '>';
									++finalCharCount;
								}
								fileContents = new string(finalChars, 0, finalCharCount);
							}
						}
					}
				}
			}

			// Resolve any file redirections here. File redirection allows the same source file
			// to generate multiple outputs via multiple transforms.
			string alternateSourceFile = null;
			using (StringReader stringReader = new StringReader(fileContents))
			{
				using (XmlTextReader reader = new XmlTextReader(stringReader))
				{
					if (XmlNodeType.Element == reader.MoveToContent())
					{
						if (reader.NamespaceURI == RedirectNamespace &&
							reader.LocalName == RedirectElementName)
						{
							string relativeTargetSourceFile = reader.GetAttribute(RedirectTargetAttribute);
							FileInfo targetSourceFileInfo = new FileInfo(sourceFile.Substring(0, sourceFile.LastIndexOf('\\') + 1) + relativeTargetSourceFile);
							if (targetSourceFileInfo.Exists)
							{
								alternateSourceFile = targetSourceFileInfo.FullName;
								sourceFile = alternateSourceFile;
								try
								{
									itemDocument = null;
									itemDocument = project.DTE.Documents.Item(alternateSourceFile);
								}
								catch (ArgumentException)
								{
									// Swallow if the document is not open
								}
							}
							else
							{
								StringWriter writer = new StringWriter();
								provider.GenerateCodeFromStatement(new CodeCommentStatement(string.Format(CultureInfo.InvariantCulture, "Redirection target file '{0}' not found", relativeTargetSourceFile)), writer, null);
								return writer.ToString();
							}
						}
					}
				}
			}

			// Add standard defined attributes to the argument list
			string projectNamespace = (string)project.Properties.Item("DefaultNamespace").Value;
			if (null == arguments.GetParam("ProjectPath", ""))
			{
				arguments.AddParam("ProjectPath", "", projectLocation);
			}
			if (null == arguments.GetParam("SourceFile", ""))
			{
				arguments.AddParam("SourceFile", "", sourceFile.Substring(projectLocation.Length));
			}
			if (null == arguments.GetParam("CustomToolNamespace", ""))
			{
				if (defaultNamespace == null || defaultNamespace.Length == 0)
				{
					defaultNamespace = projectNamespace;
				}
				arguments.AddParam("CustomToolNamespace", "", defaultNamespace);
			}
			if (null == arguments.GetParam("ProjectNamespace", ""))
			{
				arguments.AddParam("ProjectNamespace", "", projectNamespace);
			}

			try
			{
				if (transformFile == null)
				{
					StringWriter writer = new StringWriter();
					provider.GenerateCodeFromStatement(new CodeCommentStatement("Transform file not found"), writer, null);
					return writer.ToString();
				}
				else
				{
					try
					{
						XslCompiledTransform transform = new XslCompiledTransform();
						using (FileStream transformStream = new FileStream(transformFile, FileMode.Open, FileAccess.Read))
						{
							using (StreamReader reader = new StreamReader(transformStream))
							{
								transform.Load(new XmlTextReader(reader), XsltSettings.TrustedXslt, new XmlFileResolver(transformFile));
							}
						}
						MemoryStream plixStream = new MemoryStream();
						using (XmlTextWriter xmlTextWriter = new XmlTextWriter(plixStream, Encoding.Default))
						{
							// Variables that need to be disposed
							TextReader reader = null;
							Stream docStream = null;

							try
							{
								// First try to get data from the live object
								if (itemDocument != null)
								{
									if (automationObjectName != null)
									{
										docStream = itemDocument.Object(automationObjectName) as Stream;
										if (docStream != null)
										{
											reader = new StreamReader(docStream);
										}
									}

									// Fall back on getting the contents of the text buffer from the live document
									if (reader == null)
									{
										EnvDTE.TextDocument textDoc = itemDocument.Object("TextDocument") as EnvDTE.TextDocument;
										if (textDoc != null)
										{
											string liveText = textDoc.StartPoint.CreateEditPoint().GetText(textDoc.EndPoint);
											reader = new StringReader(liveText);
										}
									}
								}

								// If this is a redirection, then pull direction from the file
								if (reader == null && alternateSourceFile != null)
								{
									reader = new StreamReader(alternateSourceFile);
								}

								// Fallback on the default reading mechanism
								if (reader == null)
								{
									reader = new StringReader(fileContents);
								}

								// Use an XmlTextReader here instead of an XPathDocument
								// so that our transforms support the xsl:preserve-space element
								transform.Transform(new XmlTextReader(reader), arguments, xmlTextWriter);
								plixStream.Position = 0;

								// From the xcode stream, generate the code
								using (StringWriter writer = new StringWriter(CultureInfo.InvariantCulture))
								{
									using (XmlReader plixReader = XmlReader.Create(plixStream, PlixReaderSettings))
									{
										formatter.Transform(plixReader, new XsltArgumentList(), writer);
									}
									return writer.ToString();
								}
							}
							finally
							{
								if (reader != null)
								{
									(reader as IDisposable).Dispose();
								}
								if (docStream != null)
								{
									(docStream as IDisposable).Dispose();
								}
							}
						}
					}
					catch (Exception ex)
					{
						StringWriter writer = new StringWriter();
						Exception currentException = ex;
						provider.GenerateCodeFromStatement(new CodeCommentStatement("Generate threw an exception"), writer, null);
						while (currentException != null)
						{
							provider.GenerateCodeFromStatement(new CodeCommentStatement(ex.Message), writer, null);
							provider.GenerateCodeFromStatement(new CodeCommentStatement(ex.StackTrace), writer, null);
							currentException = currentException.InnerException;
							if (currentException != null)
							{
								provider.GenerateCodeFromStatement(new CodeCommentStatement("Info from InnerException"), writer, null);
							}
						}
						// This is only valid syntax for C# right now, but if another language does not
						// recognize this syntax then it will also throw a compile error, which is the intent,
						// so there is not much to lose here.
						provider.GenerateCodeFromStatement(new CodeSnippetStatement("#error NUPlixLoader Exception"), writer, null);
						return writer.ToString();
					}
				}
			}
			finally
			{
				// Regardless of how we finish process this file, we need to find files redirected to this
				// one and regenerate them.
				if (alternateSourceFile == null) // We only redirect one level
				{
					FileInfo sourceFileInfo = new FileInfo(sourceFile);
					RunCustomTool(
						project.ProjectItems,
						projectItem,
						delegate(EnvDTE.ProjectItem matchItem)
						{
							VSProjectItem vsProjItem = matchItem.Object as VSProjectItem;
							if (vsProjItem != null)
							{
								string itemFile = (string)matchItem.Properties.Item("LocalPath").Value;
								EnvDTE.Document liveDoc;
								EnvDTE.TextDocument textDoc;
								string liveText = null;
								if (null != (liveDoc = matchItem.Document) &&
									null != (textDoc = liveDoc.Object("TextDocument") as EnvDTE.TextDocument))
								{
									liveText = textDoc.StartPoint.CreateEditPoint().GetText(textDoc.EndPoint);
								}
								try
								{
									using (FileStream fileStream = (liveText == null) ? new FileStream(itemFile, FileMode.Open, FileAccess.Read) : null)
									{
										using (XmlTextReader reader = new XmlTextReader((liveText == null) ? new StreamReader(fileStream) as TextReader : new StringReader(liveText)))
										{
											if (XmlNodeType.Element == reader.MoveToContent())
											{
												if (reader.NamespaceURI == RedirectNamespace &&
													reader.LocalName == RedirectElementName)
												{
													FileInfo targetSourceFileInfo = new FileInfo(itemFile.Substring(0, itemFile.LastIndexOf('\\') + 1) + reader.GetAttribute(RedirectTargetAttribute));
													if (0 == string.Compare(sourceFileInfo.FullName, targetSourceFileInfo.FullName, true, CultureInfo.CurrentCulture))
													{
														vsProjItem.RunCustomTool();
													}
												}
											}
										}
									}
								}
								catch (XmlException)
								{
									// Swallow anything that Xml gripes about
								}
							}
						});
				}
			}
		}
		private delegate void ProcessProjectItem(EnvDTE.ProjectItem projectItem);
		/// <summary>
		/// Helper function to recursively trigger the NUPlixLoader tool
		/// </summary>
		private static void RunCustomTool(EnvDTE.ProjectItems items, EnvDTE.ProjectItem ignoreItem, ProcessProjectItem itemProcessor)
		{
			foreach (EnvDTE.ProjectItem testItem in items)
			{
				if (!object.ReferenceEquals(testItem, ignoreItem))
				{
					EnvDTE.Property prop = null;
					try
					{
						prop = testItem.Properties.Item("CustomTool");
					}
					catch (ArgumentException)
					{
						// Swallow
					}
					if (prop != null && 0 == string.Compare((string)prop.Value, CustomToolName, true, CultureInfo.InvariantCulture))
					{
						itemProcessor(testItem);
					}
					RunCustomTool(testItem.ProjectItems, ignoreItem, itemProcessor);
				}
			}
		}
		#endregion // Plix specific
		#region PlixDirectory property
		private string PlixDirectory
		{
			get
			{
				string retVal = myPlixDirectory;
				if (retVal == null)
				{
					lock (LockObject)
					{
						if (null == (retVal = myPlixDirectory))
						{
							// The service provider we were given does not
							// give us the install directory information we
							// need, so we have to dig down to the full service
							// provider from the hierarchy.
							Guid serviceGuid = typeof(IVsHierarchy).GUID;
							IntPtr pvHierarchy = IntPtr.Zero;
							ErrorHandler.ThrowOnFailure(myServiceProvider.QueryService(ref serviceGuid, ref serviceGuid, out pvHierarchy));
							if (pvHierarchy != IntPtr.Zero)
							{
								try
								{
									IVsHierarchy hierarchy = Marshal.GetObjectForIUnknown(pvHierarchy) as IVsHierarchy;
									if (hierarchy != null)
									{
										MsOle.IServiceProvider fullServiceProvider;
										ErrorHandler.ThrowOnFailure(hierarchy.GetSite(out fullServiceProvider));
										if (fullServiceProvider != null)
										{
											serviceGuid = typeof(IVsShell).GUID;
											IntPtr pvShell;
											ErrorHandler.ThrowOnFailure(fullServiceProvider.QueryService(ref serviceGuid, ref serviceGuid, out pvShell));
											if (pvShell != null)
											{
												try
												{
													IVsShell shell = Marshal.GetObjectForIUnknown(pvShell) as IVsShell;
													if (shell != null)
													{
														object vsInstallDir;
														ErrorHandler.ThrowOnFailure(shell.GetProperty((int)__VSSPROPID.VSSPROPID_InstallDirectory, out vsInstallDir));
														retVal = (new FileInfo(vsInstallDir + PlixRelativeDirectory)).FullName;
														myPlixDirectory = retVal;
													}
												}
												finally
												{
													Marshal.Release(pvShell);
												}
											}
										}
									}
								}
								finally
								{
									Marshal.Release(pvHierarchy);
								}
							}

						}
					}
				}
				return retVal;
			}
		}
		#endregion // PlixDirectory property
		#region Project Settings Loader
		/// <summary>
		/// Load the project settings for a specific transform file and return it
		/// </summary>
		/// <param name="sourceFile">The full path to the data file</param>
		/// <param name="baseDirectory">The path for the base directory (with a trailing \)</param>
		/// <param name="arguments">Argument list to pass to the returned transform</param>
		/// <param name="project">The context project</param>
		/// <param name="automationObjectName">The name of an automation object supported by the live document. Used
		/// to get a live version of the file stream.</param>
		/// <returns>The transform file name. Existence will have been verified.</returns>
		private string LoadProjectSettings(string sourceFile, string baseDirectory, XsltArgumentList arguments, EnvDTE.Project project, out string automationObjectName)
		{
			Debug.Assert(arguments != null); // Allocate before call
			string transformFile = null;
			automationObjectName = null;
			string plixProjectSettingsFile = baseDirectory + PlixProjectSettingsFile;
			if (File.Exists(plixProjectSettingsFile))
			{
				// Use the text from the live document if possible
				string liveText = null;
				EnvDTE.Document settingsDoc = null;
				try
				{
					settingsDoc = project.DTE.Documents.Item(plixProjectSettingsFile);
				}
				catch (ArgumentException)
				{
					// swallow
				}
				catch (InvalidCastException)
				{
					// swallow
				}
				if (settingsDoc != null)
				{
					EnvDTE.TextDocument textDoc = settingsDoc.Object("TextDocument") as EnvDTE.TextDocument;
					if (textDoc != null)
					{
						liveText = textDoc.StartPoint.CreateEditPoint().GetText(textDoc.EndPoint);
					}
				}
				string sourceFileIdentifier = sourceFile.Substring(baseDirectory.Length);
				PlixLoaderNameTable names = PlixLoaderSchema.Names;
				using (FileStream plixSettingsStream = (liveText == null) ? new FileStream(plixProjectSettingsFile, FileMode.Open, FileAccess.Read) : null)
				{
					using (XmlTextReader settingsReader = new XmlTextReader((liveText == null) ? new StreamReader(plixSettingsStream) as TextReader : new StringReader(liveText), names))
					{
						using (XmlReader reader = XmlReader.Create(settingsReader, PlixLoaderSchema.ReaderSettings))
						{
							References references = null;
							bool finished = false;
							while (!finished && reader.Read())
							{
								if (reader.NodeType == XmlNodeType.Element)
								{
									if (!reader.IsEmptyElement)
									{
										while (reader.Read())
										{
											XmlNodeType nodeType = reader.NodeType;
											if (nodeType == XmlNodeType.Element)
											{
												Debug.Assert(TestElementName(reader.LocalName, names.SourceFileElement)); // Only value allowed by the validating loader
												string testFileName = reader.GetAttribute(names.FileAttribute);
												if (0 == string.Compare(testFileName, sourceFileIdentifier, true, CultureInfo.CurrentCulture))
												{
													finished = true; // Stop looking
													string attrValue = reader.GetAttribute(names.TransformFileAttribute);
													if (attrValue != null && attrValue.Length != 0)
													{
														transformFile = baseDirectory + attrValue;
													}
													attrValue = reader.GetAttribute(names.LiveDocumentObjectAttribute);
													if (attrValue != null && attrValue.Length != 0)
													{
														automationObjectName = attrValue;
													}
													if (!reader.IsEmptyElement)
													{
														while (reader.Read())
														{
															nodeType = reader.NodeType;
															if (nodeType == XmlNodeType.Element)
															{
																string localName = reader.LocalName;
																if (TestElementName(localName, names.TransformParameterElement))
																{
																	// Add an argument for the transform
																	arguments.AddParam(reader.GetAttribute(names.NameAttribute), "", reader.GetAttribute(names.ValueAttribute));
																}
																else if (TestElementName(localName, names.ExtensionClassElement))
																{
																	// Load an extension class and associate it with an extension namespace
																	// used by the transform
																	arguments.AddExtensionObject(reader.GetAttribute(names.XslNamespaceAttribute), Type.GetType(reader.GetAttribute(names.ClassNameAttribute), true, false).GetConstructor(Type.EmptyTypes).Invoke(new object[0]));
																}
																else if (TestElementName(localName, names.ProjectReferenceElement))
																{
																	// The generated code requires project references, add them
																	if (null == references)
																	{
																		references = ((VSProject)project.Object).References;
																	}
																	if (references.Item(reader.GetAttribute(names.NamespaceAttribute)) == null)
																	{
																		references.Add(reader.GetAttribute(names.AssemblyAttribute));
																	}
																}
																else
																{
																	Debug.Assert(false); // Not allowed by schema definition
																}
																PassEndElement(reader);
															}
															else if (nodeType == XmlNodeType.EndElement)
															{
																break;
															}
														}
													}
													break;
												}
												PassEndElement(reader);
											}
											else if (nodeType == XmlNodeType.EndElement)
											{
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
			bool verifiedExistence = false;
			if (transformFile == null)
			{
				string fileBase = sourceFile.Substring(0, sourceFile.LastIndexOf('.'));
				transformFile = fileBase + ".xslt";
				if (File.Exists(transformFile))
				{
					verifiedExistence = true;
				}
				else
				{
					transformFile = fileBase + ".xsl";
				}
			}
			if (!verifiedExistence && !File.Exists(transformFile))
			{
				transformFile = null;
			}
			return transformFile;
		}
		private static bool TestElementName(string localName, string elementName)
		{
			return object.ReferenceEquals(localName, elementName);
		}
		/// <summary>
		/// Move the reader to the node immediately after the end element corresponding to the current open element
		/// </summary>
		/// <param name="reader">The XmlReader to advance</param>
		private static void PassEndElement(XmlReader reader)
		{
			if (!reader.IsEmptyElement)
			{
				bool finished = false;
				while (!finished && reader.Read())
				{
					switch (reader.NodeType)
					{
						case XmlNodeType.Element:
							PassEndElement(reader);
							break;

						case XmlNodeType.EndElement:
							finished = true;
							break;
					}
				}
			}
		}
		#endregion // Project Settings Loader
		#region Global Settings Loader
		private struct Formatter
		{
			private string myTransformFile;
			private XslCompiledTransform myTransform;
			/// <summary>
			/// Create a formatter structure for the given transform file
			/// </summary>
			/// <param name="transformFile">The full path to a transform file</param>
			public Formatter(string transformFile)
			{
				myTransformFile = transformFile;
				myTransform = null;
			}
			/// <summary>
			/// Has the transform been successfully loaded?
			/// </summary>
			public bool HasTransform
			{
				get
				{
					return myTransform != null;
				}
			}
			/// <summary>
			/// The compile transform
			/// </summary>
			public XslCompiledTransform Transform
			{
				get
				{
					XslCompiledTransform retVal = myTransform;
					if (retVal == null)
					{
						lock (LockObject)
						{
							if (null == (retVal = myTransform))
							{
								retVal = new XslCompiledTransform();
								string transformFile = myTransformFile;
								using (FileStream transformStream = new FileStream(transformFile, FileMode.Open, FileAccess.Read))
								{
									using (StreamReader reader = new StreamReader(transformStream))
									{
										retVal.Load(new XmlTextReader(reader), XsltSettings.TrustedXslt, new XmlFileResolver(transformFile));
										myTransform = retVal;
									}
								}
							}
						}
					}
					return retVal;
				}
			}
		}
		private XslCompiledTransform GetFormatterTransform(string fileExtension)
		{
			XslCompiledTransform retVal = null;
			Dictionary<string, Formatter> dictionary = myFormattersDictionary;
			if (dictionary == null)
			{
				lock (LockObject)
				{
					if (null == (dictionary = myFormattersDictionary))
					{
						dictionary = new Dictionary<string, Formatter>();
						LoadGlobalSettings(dictionary);
						myFormattersDictionary = dictionary;
					}
				}
			}
			Formatter langFormatter;
			if (dictionary.TryGetValue(fileExtension.ToLowerInvariant(), out langFormatter))
			{
				bool resetDictionary = !langFormatter.HasTransform;
				retVal = langFormatter.Transform;
				if (retVal != null && resetDictionary)
				{
					lock (LockObject)
					{
						dictionary[fileExtension] = langFormatter;
					}
				}
			}
			return retVal;
		}
		private void LoadGlobalSettings(Dictionary<string, Formatter> languageTransforms)
		{
			string settingsFile = PlixDirectory + PlixGlobalSettingsFile;
			if (File.Exists(settingsFile))
			{
				PlixSettingsNameTable names = PlixSettingsSchema.Names;
				using (FileStream plixSettingsStream = new FileStream(settingsFile, FileMode.Open, FileAccess.Read))
				{
					using (XmlTextReader settingsReader = new XmlTextReader(new StreamReader(plixSettingsStream), names))
					{
						using (XmlReader reader = XmlReader.Create(settingsReader, PlixSettingsSchema.ReaderSettings))
						{
							if (XmlNodeType.Element == reader.MoveToContent())
							{
								while (reader.Read())
								{
									XmlNodeType nodeType1 = reader.NodeType;
									if (nodeType1 == XmlNodeType.Element)
									{
										Debug.Assert(TestElementName(reader.LocalName, names.FormattersElement)); // Only value allowed by the validating reader
										if (reader.IsEmptyElement)
										{
											break;
										}
										string formattersDir = PlixDirectory + FormattersDirectory;
										while (reader.Read())
										{
											XmlNodeType nodeType2 = reader.NodeType;
											if (nodeType2 == XmlNodeType.Element)
											{
												Debug.Assert(TestElementName(reader.LocalName, names.FormatterElement)); // Only value allowed by the validating reader
												languageTransforms[reader.GetAttribute(PlixSettingsSchema.FileExtensionAttribute)] = new Formatter(formattersDir + reader.GetAttribute(PlixSettingsSchema.TransformAttribute));
												PassEndElement(reader);
											}
											else if (nodeType2 == XmlNodeType.EndElement)
											{
												break;
											}
										}
									}
									else if (nodeType1 == XmlNodeType.EndElement)
									{
										break;
									}
								}
							}
						}
					}
				}
			}
		}
		#endregion // Global Settings Loader
	}
}
