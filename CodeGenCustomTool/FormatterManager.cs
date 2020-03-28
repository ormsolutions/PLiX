﻿/**************************************************************************\
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
using System.Diagnostics;
using System.IO;
using System.Xml;
using System.Xml.Xsl;
#if VISUALSTUDIO_15_0
using Microsoft.Win32;
#endif

namespace Neumont.Tools.CodeGeneration.Plix
{
	/// <summary>
	/// A utility class for loading available formatters
	/// </summary>
	public static class FormatterManager
	{
		#region Constant locations
#if VISUALSTUDIO_15_0
		private const string PlixFormattersKey = @"Neumont\PLiX\Formatters";
		private const string PlixFormatterOptionsKey = @"Neumont\PLiX\FormatterOptions";
#else
		private const string PlixInstallDirectory = @"\Neumont\PLiX\";
		private const string FormattersDirectory = @"Formatters\";
		private const string PlixGlobalSettingsFile = "PLiXSettings.xml";
#endif
		#endregion // Constant locations
		#region Static variables
		private static Dictionary<string, Formatter> myFormattersDictionary;
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
#if VISUALSTUDIO_15_0
#else // !VISUALSTUDIO_15_0
#region PlixDirectory property
		private static string myPlixDirectory;
		private static string PlixDirectory
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
							string commonProgramFiles = Environment.GetEnvironmentVariable("CommonProgramFiles", EnvironmentVariableTarget.Process);
							retVal = commonProgramFiles + PlixInstallDirectory;
							myPlixDirectory = retVal;
						}
					}
				}
				return retVal;
			}
		}
#endregion // PlixDirectory property
#region PlixSettingsSchema class
		private static class PlixSettingsSchema
		{
#region String Constants
			public const string SchemaNamespace = "http://schemas.neumont.edu/CodeGeneration/PLiXSettings";
			public const string FormatterElement = "formatter";
			public const string FormattersElement = "formatters";
			public const string FileExtensionAttribute = "fileExtension";
			public const string TransformAttribute = "transform";
			public const string NoByteOrderMarkAttribute = "noByteOrderMark";
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
								retVal.Schemas.Add(SchemaNamespace, new XmlTextReader(typeof(FormatterManager).Assembly.GetManifestResourceStream(typeof(FormatterManager), "PlixSettings.xsd")));
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
			public readonly string NoByteOrderMarkAttribute;
			public PlixSettingsNameTable()
				: base()
			{
				SchemaNamespace = Add(PlixSettingsSchema.SchemaNamespace);
				FormatterElement = Add(PlixSettingsSchema.FormatterElement);
				FormattersElement = Add(PlixSettingsSchema.FormattersElement);
				TransformAttribute = Add(PlixSettingsSchema.TransformAttribute);
				FileExtensionAttribute = Add(PlixSettingsSchema.FileExtensionAttribute);
				NoByteOrderMarkAttribute = Add(PlixSettingsSchema.NoByteOrderMarkAttribute);
			}
		}
#endregion // PlixSettingsNameTable class
#endif // !VISUALSTUDIO_15_0
#region Global Settings Loader
		private struct Formatter
		{
			private string myTransformFile;
			private XslCompiledTransform myTransform;
			private bool myNoBOM;
			/// <summary>
			/// Create a formatter structure for the given transform file
			/// </summary>
			/// <param name="transformFile">The full path to a transform file</param>
			public Formatter(string transformFile, bool noByteOrderMark)
			{
				myTransformFile = transformFile;
				myTransform = null;
				myNoBOM = noByteOrderMark;
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
										retVal.Load(new XmlTextReader(reader), XsltSettings.TrustedXslt, XmlUtility.CreateFileResolver(transformFile));
										myTransform = retVal;
									}
								}
							}
						}
					}
					return retVal;
				}
			}
			/// <summary>
			/// True to block generation of a byte order mark in the output xml writer
			/// </summary>
			public bool NoByteOrderMark
			{
				get
				{
					return myNoBOM;
				}
			}
		}
		/// <summary>
		/// Return a formatter for the registered file extension
		/// </summary>
		/// <param name="fileExtension">The file extension for the type of code file. For example, 'cs' or 'vb'.</param>
#if VISUALSTUDIO_15_0
		/// <param name="getRegistryRoot">A callback function to get the registry root. The caller is responsible for
		/// closing this key if the function is accessed during the call.</param>
#endif
		/// <returns>An <see cref="XslCompiledTransform"/> for the requested extension.</returns>
		public static XslCompiledTransform GetFormatterTransform(
			string fileExtension
#if VISUALSTUDIO_15_0
			, Func<RegistryKey> getRegistryRoot
#endif
			, out bool noByteOrderMark)
		{
			XslCompiledTransform retVal = null;
			noByteOrderMark = false;
			Dictionary<string, Formatter> dictionary = myFormattersDictionary;
			if (dictionary == null)
			{
				lock (LockObject)
				{
					if (null == (dictionary = myFormattersDictionary))
					{
						dictionary = new Dictionary<string, Formatter>();
						LoadGlobalSettings(
							dictionary
#if VISUALSTUDIO_15_0
							, getRegistryRoot
#endif
							);
						myFormattersDictionary = dictionary;
					}
				}
			}
			Formatter langFormatter;
			if (dictionary.TryGetValue(fileExtension.ToLowerInvariant(), out langFormatter))
			{
				bool resetDictionary = !langFormatter.HasTransform;
				retVal = langFormatter.Transform;
				noByteOrderMark = langFormatter.NoByteOrderMark;
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
		/// <summary>
		/// Determine if the file extension has a registered formatter without attempting to load the transform
		/// </summary>
		/// <param name="fileExtension">The file extension for the type of code file. For example, 'cs' or 'vb'.</param>
#if VISUALSTUDIO_15_0
		/// <param name="getRegistryRoot">A callback function to get the registry root. The caller is responsible for
		/// closing this key if the function is accessed during the call.</param>
#endif
		/// <returns><see langword="true"/> if registered</returns>
		public static bool IsFormatterRegistered(
			string fileExtension
#if VISUALSTUDIO_15_0
			, Func<RegistryKey> getRegistryRoot
#endif
			)
		{
			Dictionary<string, Formatter> dictionary = myFormattersDictionary;
			if (dictionary == null)
			{
				lock (LockObject)
				{
					if (null == (dictionary = myFormattersDictionary))
					{
						dictionary = new Dictionary<string, Formatter>();
						LoadGlobalSettings(
							dictionary
#if VISUALSTUDIO_15_0
							, getRegistryRoot
#endif
							);
						myFormattersDictionary = dictionary;
					}
				}
			}
			return dictionary.ContainsKey(fileExtension.ToLowerInvariant());
		}
#if VISUALSTUDIO_15_0
		private static void LoadGlobalSettings(Dictionary<string, Formatter> languageTransforms, Func<RegistryKey> getRegistryRoot)
		{
			RegistryKey rootKey = getRegistryRoot(); // The caller is responsible for closing this key
			if (rootKey != null)
			{
				using (RegistryKey formattersKey = rootKey.OpenSubKey(PlixFormattersKey, RegistryKeyPermissionCheck.ReadSubTree),
					formatterOptionsKey = rootKey.OpenSubKey(PlixFormatterOptionsKey, RegistryKeyPermissionCheck.ReadSubTree))
				{
					foreach (string extension in formattersKey.GetValueNames())
					{
						if (!string.IsNullOrEmpty(extension))
						{
							// The extension may have a corresponding key in the FormatterOptions key.
							bool noByteOrderMark = false;
							if (formatterOptionsKey != null)
							{
								using (RegistryKey optionsKey = formatterOptionsKey.OpenSubKey(extension, RegistryKeyPermissionCheck.ReadSubTree))
								{
									if (null != optionsKey)
									{
										noByteOrderMark = Convert.ToBoolean((int)optionsKey.GetValue("NoByteOrderMark", 0));
									}
								}
							}

							// Note that the directory path is part of the value
							languageTransforms[extension] = new Formatter(formattersKey.GetValue(extension).ToString(), noByteOrderMark);
						}
					}
				}
			}
		}
#else //!VISUALSTUDIO_15_0
		private static void LoadGlobalSettings(Dictionary<string, Formatter> languageTransforms)
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
										Debug.Assert(XmlUtility.TestElementName(reader.LocalName, names.FormattersElement)); // Only value allowed by the validating reader
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
												Debug.Assert(XmlUtility.TestElementName(reader.LocalName, names.FormatterElement)); // Only value allowed by the validating reader
												languageTransforms[reader.GetAttribute(PlixSettingsSchema.FileExtensionAttribute)] = new Formatter(formattersDir + reader.GetAttribute(PlixSettingsSchema.TransformAttribute), XmlConvert.ToBoolean(reader.GetAttribute(PlixSettingsSchema.NoByteOrderMarkAttribute)));
												XmlUtility.PassEndElement(reader);
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
#endif // !VISUALSTUDIO_15_0
#endregion // Global Settings Loader
	}
}
