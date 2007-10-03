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

namespace Neumont.Tools.CodeGeneration.Plix.Shell
{
	partial class PlixPackage
	{
		private static class GuidList
		{
			// Command values must match values in CtcComponents/Guids.h
			public const string guidPlixPackagePkgString = "BC129A03-26C4-4667-8E12-96225B2D3CD2";
			public const string guidPlixPackageCmdSetString = "FCAC431C-E719-4354-A98F-5322DA9CE93C";
			public const string SnippetPreviewWindowGuidString = "976D6FA2-8D5A-4EDF-B5B5-1EDFCAEEB841";

			public static readonly Guid guidPlixPackagePkg = new Guid(guidPlixPackagePkgString);
			public static readonly Guid guidPlixPackageCmdSet = new Guid(guidPlixPackageCmdSetString);
			public static readonly Guid SnippetPreviewWindowGuid = new Guid(SnippetPreviewWindowGuidString);
		}
	}
}