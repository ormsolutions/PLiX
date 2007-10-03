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
using System.Xml;

namespace Neumont.Tools.CodeGeneration.Plix
{
	/// <summary>
	/// Utility methods used with Xml processing
	/// </summary>
	public sealed class XmlUtility
	{
		/// <summary>
		/// Determine if two elements have the same name by comparing the
		/// object values of the string. The assumption is made that both
		/// strings come from the same <see cref="NameTable"/>
		/// </summary>
		/// <param name="localName"></param>
		/// <param name="elementName"></param>
		/// <returns></returns>
		public static bool TestElementName(string localName, string elementName)
		{
			return object.ReferenceEquals(localName, elementName);
		}
		/// <summary>
		/// Move the reader to the node immediately after the end element
		/// corresponding to the current open element. PassEndElement generally
		/// works much better than <see cref="XmlReader.Skip"/>, which moves
		/// to the element past the end element. PassEndElement leaves the reader
		/// on the end element so that a subsequent call to <see cref="XmlReader.Read"/>
		/// does not move past the next element.
		/// </summary>
		/// <param name="reader">The XmlReader to advance</param>
		public static void PassEndElement(XmlReader reader)
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
		/// <summary>
		/// Create an <see cref="XmlResolver"/> that resolves file paths relative
		/// the the provided <paramref name="baseFile"/>
		/// </summary>
		/// <param name="baseFile">A file path</param>
		/// <returns>A new <see cref="XmlResolver"/></returns>
		public static XmlResolver CreateFileResolver(string baseFile)
		{
			return new XmlFileResolver(baseFile);
		}
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
	}
}
