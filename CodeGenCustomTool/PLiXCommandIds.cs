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
		private static class PkgCmdIDList
		{
			// Command values must match values in CtcComponents/CommandIds.h
			public const uint menuidSnippetPreviewToolbar = 0x100;
			public const uint cmdidPlixSnippetPreviewWindow = 0x1000;
			public const uint cmdidPlixSnippetPreviewSelfChoice = 0x1001;
			public const uint cmdidPlixCSharpFormatter = 0x1011;
			public const uint cmdidPlixVBFormatter = 0x1012;
			public const uint cmdidPlixPHPFormatter = 0x1013;
			public const uint cmdidPlixJSharpFormatter = 0x1014;
			public const uint cmdidPlixPYFormatter = 0x1015;
			// Additional commands for formatter ids must be sequential and match the order in PlixPackage.SnippetPreviewWindow.FormatterInfo.InitializeCommands

			public const uint cmdidPlixSnippetPreviewParentChoice = 0x1100;
			public const uint cmdidPlixSnippetPreviewParentChoiceEnd = 0x11ff;
		};
	}
}
