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
// guids.h: definitions of GUIDs/IIDs/CLSIDs used in this VsPackage

/*
Do not use #pragma once, as this file needs to be included twice.  Once to declare the externs
for the GUIDs, and again right after including initguid.h to actually define the GUIDs.
*/



// package guid
// { bc129a03-26c4-4667-8e12-96225b2d3cd2 }
#define guidPlixPackagePkg { 0xBC129A03, 0x26C4, 0x4667, { 0x8E, 0x12, 0x96, 0x22, 0x5B, 0x2D, 0x3C, 0xD2 } }
#ifdef DEFINE_GUID
DEFINE_GUID(CLSID_PlixPackage,
0xBC129A03, 0x26C4, 0x4667, 0x8E, 0x12, 0x96, 0x22, 0x5B, 0x2D, 0x3C, 0xD2 );
#endif

// Command set guid for our commands (used with IOleCommandTarget)
// { fcac431c-e719-4354-a98f-5322da9ce93c }
#define guidPlixPackageCmdSet { 0xFCAC431C, 0xE719, 0x4354, { 0xA9, 0x8F, 0x53, 0x22, 0xDA, 0x9C, 0xE9, 0x3C } }
#ifdef DEFINE_GUID
DEFINE_GUID(CLSID_PlixPackageCmdSet, 
0xFCAC431C, 0xE719, 0x4354, 0xA9, 0x8F, 0x53, 0x22, 0xDA, 0x9C, 0xE9, 0x3C );
#endif


