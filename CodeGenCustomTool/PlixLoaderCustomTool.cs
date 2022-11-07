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
using Microsoft.VisualStudio.Shell.Interop;
using MsOle = Microsoft.VisualStudio.OLE.Interop;
using System.Runtime.InteropServices;
using System.IO;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Shell;
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
using IServiceProvider = System.IServiceProvider;

#if VISUALSTUDIO_15_0
using Microsoft.Win32;
#endif

namespace Neumont.Tools.CodeGeneration.Plix
{
	/// <summary>
	/// A custom tool to generate code using the Plix code generation framework
	/// </summary>
	public sealed class PlixLoaderCustomTool : IVsSingleFileGenerator, MsOle.IObjectWithSite, MsOle.IServiceProvider, IServiceProvider // Need additional service provider capabilities for VS2015
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
		/// <summary>
		/// A wrapper object to provide unified managed and unmanaged IServiceProvider implementations
		/// </summary>
		private readonly ServiceProvider myServiceProvider;
		/// <summary>
		/// The service provider handed us by the shell during IObjectWithSite.SetSite. This
		/// service provider lets us retrieve the EnvDTE.ProjectItem and CodeDomProvider objects and very little else.
		/// </summary>
		private MsOle.IServiceProvider myCustomToolServiceProvider;
		/// <summary>
		/// The full VS DTE service provider. We retrieve this on demand only
		/// </summary>
		private MsOle.IServiceProvider myDteServiceProvider;
		private CodeDomProvider myCodeDomProvider;
		private EnvDTE.ProjectItem myProjectItem;
		private const string PlixProjectSettingsFile = "Plix.xml";
		private const string CustomToolName = "NUPlixLoader";
		private const string RedirectNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiXRedirect";
		private const string RedirectElementName = "redirectSourceFile";
		private const string RedirectTargetAttribute = "target";
		#endregion // Member Variables
		#region Static variables
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
			// NOTE: Attempting to use any of the ServiceProviders will cause us to go into an infinite loop
			// unless SetSite has been called on us.
			myServiceProvider = new ServiceProvider(this, true);
		}
		#endregion // Constructor

		#region ServiceProvider Interface Implementations
		/// <summary>
		/// Returns a service instance of type <typeparamref name="T"/>, or <see langword="null"/> if no service instance of
		/// type <typeparamref name="T"/> is available.
		/// </summary>
		/// <typeparam name="T">The type of the service instance being requested.</typeparam>
		private T GetService<T>() where T : class
		{
			return myServiceProvider.GetService(typeof(T)) as T;
		}
		#region MsOle.IServiceProvider Members
		int MsOle.IServiceProvider.QueryService(ref Guid guidService, ref Guid riid, out IntPtr ppvObject)
		{
			MsOle.IServiceProvider customToolServiceProvider = myCustomToolServiceProvider;

			if (customToolServiceProvider == null)
			{
				ppvObject = IntPtr.Zero;
				return VSConstants.E_NOINTERFACE;
			}

			// First try to service the request via the IOleServiceProvider we were given. If unsuccessful, try via DTE's
			// MsOle.IServiceProvider implementation (if we have it).
			int errorCode = myCustomToolServiceProvider.QueryService(ref guidService, ref riid, out ppvObject);

			if (ErrorHandler.Failed(errorCode) || ppvObject == IntPtr.Zero)
			{
				// Fallback on the full environment service provider if necessary
				MsOle.IServiceProvider dteServiceProvider = myDteServiceProvider;
				if (dteServiceProvider == null)
				{
					myDteServiceProvider = customToolServiceProvider;
					EnvDTE.ProjectItem projectItem = GetService<EnvDTE.ProjectItem>();
					if (null != (projectItem = GetService<EnvDTE.ProjectItem>()) &&
						null != (dteServiceProvider = projectItem.DTE as MsOle.IServiceProvider))
					{
						myDteServiceProvider = dteServiceProvider;
					}
				}
				if (dteServiceProvider != null &&
					!object.ReferenceEquals(dteServiceProvider, customToolServiceProvider)) // Signal used to indicate failure to retrieve dte provider
				{
					errorCode = dteServiceProvider.QueryService(ref guidService, ref riid, out ppvObject);
				}
			}
			return errorCode;
		}
		#endregion // MsOle.IServiceProvider Members
		#region IServiceProvider Members
		object IServiceProvider.GetService(Type serviceType)
		{
			// Pass this on to our ServiceProvider which will pass it back to us via our implementation of MsOle.IServiceProvider
			return myServiceProvider.GetService(serviceType);
		}
		#endregion // IServiceProvider Members
		#endregion // ServiceProvider Interface Implementations
		#region IVsSingleFileGenerator Implementation
		int IVsSingleFileGenerator.DefaultExtension(out string pbstrDefaultExtension)
		{
			string retVal = CodeDomProvider.FileExtension;
			if (retVal[0] != '.')
			{
				retVal = "." + retVal;
			}
			pbstrDefaultExtension = retVal;
			return VSConstants.S_OK;
		}
		int IVsSingleFileGenerator.Generate(string wszInputFilePath, string bstrInputFileContents, string wszDefaultNamespace, IntPtr[] rgbOutputFileContents, out uint pcbOutput, IVsGeneratorProgress pGenerateProgress)
		{
			byte[] bytes = Encoding.UTF8.GetBytes(GenerateCode(bstrInputFileContents, wszDefaultNamespace));
			byte[] preamble = Encoding.UTF8.GetPreamble();
			int bufferLength = bytes.Length + preamble.Length;
			IntPtr pBuffer = Marshal.AllocCoTaskMem(bufferLength);
			rgbOutputFileContents[0] = pBuffer;
			pcbOutput = (uint)bufferLength;
			Marshal.Copy(preamble, 0, pBuffer, preamble.Length);
			if (IntPtr.Size == 8)
			{
				pBuffer = (IntPtr)(long)((ulong)pBuffer + (ulong)preamble.Length);
			}
			else
			{
				// This overflows without the (int) case if the uint is in the range that has the
				// sign bit set. The same change was applied to 64 bit case above as well. Note that
				// the IntPtr in question was returned directly from a system API and is definitely in
				// the range of valid system pointers.
				pBuffer = (IntPtr)(int)((uint)pBuffer + preamble.Length);
			}
			Marshal.Copy(bytes, 0, pBuffer, bytes.Length);
			myProjectItem = null; // No longer needed
			return VSConstants.S_OK;
		}
		#endregion // IVsSingleFileGenerator Implementation
		#region IObjectWithSite implementation
		void MsOle.IObjectWithSite.SetSite(object punkSite)
		{
			myCustomToolServiceProvider = punkSite as MsOle.IServiceProvider;
			// Don't call SetSite on _serviceProvider, we want the site to call back to use to us
			myDteServiceProvider = null;
			myProjectItem = null;
		}
		void MsOle.IObjectWithSite.GetSite(ref Guid riid, out IntPtr ppvSite)
		{
			(myServiceProvider as MsOle.IObjectWithSite).GetSite(ref riid, out ppvSite);
		}
		#endregion // IObjectWithSite implementation
		#region Service Properties
		private CodeDomProvider CodeDomProvider
		{
			get
			{
				CodeDomProvider retVal = myCodeDomProvider;
				if (retVal == null)
				{
					myCodeDomProvider = retVal = GetService<IVSMDCodeDomProvider>().CodeDomProvider as CodeDomProvider;
				}
				return retVal;
			}
		}
		private EnvDTE.ProjectItem CurrentProjectItem
		{
			get
			{
				EnvDTE.ProjectItem retVal = myProjectItem;
				if (retVal == null)
				{
					myProjectItem = retVal = GetService<EnvDTE.ProjectItem>();
				}
				return retVal;
			}
		}
		#endregion // Service Properties
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
			if (fileExtension.StartsWith("."))
			{
				fileExtension = fileExtension.Substring(1);
			}
			bool noByteOrderMark = false;
#if VISUALSTUDIO_15_0
			XslCompiledTransform formatter = null;
			RegistryKey registryRoot = null;
			try
			{
				formatter = FormatterManager.GetFormatterTransform(fileExtension, () =>
				{
					if (registryRoot == null)
					{
						IVsShell shell = GetService<IVsShell>();
						if (shell != null)
						{
							object registryRootObj;
							shell.GetProperty((int)__VSSPROPID.VSSPROPID_VirtualRegistryRoot, out registryRootObj);
							registryRoot = Registry.CurrentUser.OpenSubKey(registryRootObj.ToString() + "_Config", RegistryKeyPermissionCheck.ReadSubTree);
						}
					}
					return registryRoot;
				}, out noByteOrderMark);
			}
			finally
			{
				if (registryRoot != null)
				{
					registryRoot.Dispose();
				}
			}
#else
			XslCompiledTransform formatter = FormatterManager.GetFormatterTransform(fileExtension, out noByteOrderMark);
#endif
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
				try
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
				catch (XmlException ex)
				{
					return GenerateExceptionInformation(ex, provider);
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
				XslCompiledTransform transform = null;
				if (transformFile != null)
				{
					transform = new XslCompiledTransform();
					using (FileStream transformStream = new FileStream(transformFile, FileMode.Open, FileAccess.Read))
					{
						using (StreamReader reader = new StreamReader(transformStream))
						{
							transform.Load(new XmlTextReader(reader), XsltSettings.TrustedXslt, XmlUtility.CreateFileResolver(transformFile));
						}
					}
				}
				MemoryStream plixStream = null;
				XmlWriterSettings outputSettings = null;
				if (transform != null)
				{
					plixStream = new MemoryStream();
					outputSettings = transform.OutputSettings;
					if (noByteOrderMark)
					{
						outputSettings = outputSettings != null ? outputSettings.Clone() : new XmlWriterSettings();
						outputSettings.Encoding = new UTF8Encoding(false);
					}
				}
				using (XmlWriter xmlTextWriter = (transform != null) ? XmlWriter.Create(plixStream, outputSettings) : null)
				{
					// Variables that need to be disposed
					TextReader reader = null;
					Stream docStream = null;

					try
					{
						// First try to get data from the live object
						string docText = null;
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
									docText = textDoc.StartPoint.CreateEditPoint().GetText(textDoc.EndPoint);
									reader = new StringReader(docText);
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
							docText = fileContents;
							reader = new StringReader(fileContents);
						}

						if (transform == null)
						{
							XmlReaderSettings testPlixDocumentReaderSettings = new XmlReaderSettings();
							testPlixDocumentReaderSettings.CloseInput = false;
							bool plixDocument = false;
							try
							{
								using (XmlReader testPlixDocumentReader = XmlReader.Create(reader, testPlixDocumentReaderSettings))
								{
									testPlixDocumentReader.MoveToContent();
									if (testPlixDocumentReader.NodeType == XmlNodeType.Element && testPlixDocumentReader.NamespaceURI == PlixSchemaNamespace)
									{
										plixDocument = true;
									}
								}
							}
							catch (XmlException ex)
							{
								return GenerateExceptionInformation(ex, provider);
							}
							if (!plixDocument)
							{
								StringWriter writer = new StringWriter();
								provider.GenerateCodeFromStatement(new CodeCommentStatement("Transform file not found"), writer, null);
								GenerateNUPlixLoaderExceptionLine(writer, provider);
								return writer.ToString();
							}
							if (docText != null)
							{
								reader.Dispose();
								reader = new StringReader(docText);
							}
							else
							{
								StreamReader streamReader = (StreamReader)reader;
								streamReader.BaseStream.Position = 0;
							}
						}
						else
						{
							// Use an XmlTextReader here instead of an XPathDocument
							// so that our transforms support the xsl:preserve-space element
							transform.Transform(new XmlTextReader(reader), arguments, xmlTextWriter, XmlUtility.CreateFileResolver(sourceFile));
							plixStream.Position = 0;
						}
						// From the plix stream, generate the code
						using (StringWriter writer = new StringWriter(CultureInfo.InvariantCulture))
						{
							using (XmlReader plixReader = (plixStream != null) ? XmlReader.Create(plixStream, PlixReaderSettings) : XmlReader.Create(reader, PlixReaderSettings))
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
				return GenerateExceptionInformation(ex, provider);
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
		private static string GenerateExceptionInformation(Exception ex, CodeDomProvider provider)
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
			GenerateNUPlixLoaderExceptionLine(writer, provider);
			return writer.ToString();
		}
		private static void GenerateNUPlixLoaderExceptionLine(TextWriter writer, CodeDomProvider provider)
		{
			// This is only valid syntax for C# right now, but if another language does not
			// recognize this syntax then it will also throw a compile error, which is the intent,
			// so there is not much to lose here.
			provider.GenerateCodeFromStatement(new CodeSnippetStatement("#error NUPlixLoader Exception"), writer, null);
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
												Debug.Assert(XmlUtility.TestElementName(reader.LocalName, names.SourceFileElement)); // Only value allowed by the validating loader
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
																if (XmlUtility.TestElementName(localName, names.TransformParameterElement))
																{
																	// Add an argument for the transform
																	arguments.AddParam(reader.GetAttribute(names.NameAttribute), "", reader.GetAttribute(names.ValueAttribute));
																}
																else if (XmlUtility.TestElementName(localName, names.ExtensionClassElement))
																{
																	// Load an extension class and associate it with an extension namespace
																	// used by the transform
																	arguments.AddExtensionObject(reader.GetAttribute(names.XslNamespaceAttribute), Type.GetType(reader.GetAttribute(names.ClassNameAttribute), true, false).GetConstructor(Type.EmptyTypes).Invoke(new object[0]));
																}
																else if (XmlUtility.TestElementName(localName, names.ProjectReferenceElement))
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
																XmlUtility.PassEndElement(reader);
															}
															else if (nodeType == XmlNodeType.EndElement)
															{
																break;
															}
														}
													}
													break;
												}
												XmlUtility.PassEndElement(reader);
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
		#endregion // Project Settings Loader
	}
}
