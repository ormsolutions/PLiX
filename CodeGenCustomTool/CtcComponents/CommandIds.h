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
// CommandIds.h
// Command IDs used in defining command bars
//

// do not use #pragma once - used by ctc compiler
#ifndef __COMMANDIDS_H_
#define __COMMANDIDS_H_

///////////////////////////////////////////////////////////////////////////////
// Menu IDs

#define menuidSnippetPreviewToolbar			0x100
#define menuidSnippetPreviewFormatterMenu	0x101
#define menuidSnippetPreviewParentChoiceMenu      0x102

///////////////////////////////////////////////////////////////////////////////
// Menu Group IDs

#define groupidSnippetPreviewCommands   0x200
#define groupidFormatterChoiceCommands  0x201
#define groupidParentChoice             0x202

///////////////////////////////////////////////////////////////////////////////
// Command IDs

#define cmdidPlixSnippetPreviewWindow 0x1000
#define cmdidPlixSnippetPreviewSelfChoice 0x1001

#define cmdidPlixCSharpFormatter 0x1011
#define cmdidPlixVBFormatter 0x1012
#define cmdidPlixPHPFormatter 0x1013
// Additional commands for formatter ids must be sequential and match the order in PlixPackage.SnippetPreviewWindow.FormatterInfo.InitializeCommands

#define cmdidPlixSnippetPreviewParentChoice 0x1100
// Large ranges for dynamic commands, keep single commands in the 0x10__ range

///////////////////////////////////////////////////////////////////////////////
// Bitmap IDs
#define bmpPicPlixPreview 1
#define bmpPicSelf 2
#define bmpPicParent 3
#define bmpPicCSharp 4
#define bmpPicVB 5
#define bmpPicPHP 6


#endif // __COMMANDIDS_H_
