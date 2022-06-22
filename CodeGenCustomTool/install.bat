@echo OFF
setlocal

:: TargetVisualStudioNumericVersion settings:
::   8.0 = Visual Studio 2005 (Code Name "Whidbey")
::   9.0 = Visual Studio 2008 (Code Name "Orcas")
::  10.0 = Visual Studio 2010 (Code Name "Rosario")
::  11.0 = Visual Studio 2012
::  12.0 = Visual Studio 2013
::  14.0 = Visual Studio 2015
::  15.0 = Visual Studio 2017
::  16.0 = Visual Studio 2019
::  17.0 = Visual Studio 2022
IF '%TargetVisualStudioNumericVersion%' == '15.0' GOTO:EOF
IF '%TargetVisualStudioNumericVersion%' == '16.0' GOTO:EOF
IF '%TargetVisualStudioNumericVersion%' == '17.0' GOTO:EOF
IF NOT DEFINED TargetVisualStudioNumericVersion (
	SET TargetVisualStudioNumericVersion=8.0
)

IF "%ProgramFiles(X86)%"=="" (
	SET ResolvedProgramFiles=%ProgramFiles%
	SET ResolvedCommonProgramFiles=%CommonProgramFiles%
	SET WOWRegistryAdjust=
) ELSE (
	CALL:SET6432
)

if '%1'=='' (
set rootPath=%~dp0
) else (
set rootPath=%~dp1
)
if '%2'=='' (
set outDir=bin\Debug\
) else (
set outDir=%~2
)
if '%3'=='' (
	CALL:SETVAR "envPath" "%ResolvedProgramFiles%\Microsoft Visual Studio 8\"
) else (
	CALL:SETVAR "envPath" "%~3"
)

SET VSRegistryRootBase=SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio
SET VSRegistryRootVersion=%TargetVisualStudioNumericVersion%
FOR /F "usebackq skip=2 tokens=2*" %%A IN (`REG QUERY "HKLM\%VSRegistryRootBase%\VSIP\%VSRegistryRootVersion%" /v "InstallDir"`) DO SET VSIPDir=%%~fB
IF "%TargetVisualStudioNumericVersion%"=="9.0" (CALL:SETVAR "vsipbin" "%VSIPDir%VisualStudioIntegration\Tools\Bin\VS2005\") ELSE (CALL:SETVAR "vsipbin" "%VSIPDir%VisualStudioIntegration\Tools\Bin\")

set plixBinaries=%ResolvedProgramFiles%\Neumont\PLiX for Visual Studio\bin\
set plixHelp=%ResolvedProgramFiles%\Neumont\PLiX for Visual Studio\Help\
set plixXML=%ResolvedCommonProgramFiles%\Neumont\PLiX\
set plixTool=Neumont.Tools.CodeGeneration.PLiX
set plixToolClass=Neumont.Tools.CodeGeneration.Plix.PlixLoaderCustomTool

IF EXIST "%plixBinaries%%plixTool%.dll" (
"%vsipbin%regpkg.exe" /root:"%VSRegistryRootBase%\%VSRegistryRootVersion%" /unregister "%plixBinaries%%plixTool%.dll"
"%vsipbin%regpkg.exe" /root:"%VSRegistryRootBase%\%VSRegistryRootVersion%Exp" /unregister "%plixBinaries%%plixTool%.dll"
)

:: Clean old install locations
if exist "%envPath%Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.dll" (
del "%envPath%Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.dll"
)
if exist "%envPath%Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.pdb" (
del "%envPath%Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.pdb"
)
del /f /q "%envPath%Xml\Schemas\Plix*.xsd" 1>NUL 2>&1
if exist "%envPath%Neumont" rd /s /q "%envPath%Neumont"
if exist "%plixBinaries%Neumont.Tools.CodeGeneration.CustomTools.dll" (
del "%plixBinaries%Neumont.Tools.CodeGeneration.CustomTools.dll"
)
if exist "%plixBinaries%Neumont.Tools.CodeGeneration.CustomTools.pdb" (
del "%plixBinaries%Neumont.Tools.CodeGeneration.CustomTools.pdb"
)

:: Create new directories
if not exist "%plixBinaries%" md "%plixBinaries%"
if not exist "%plixHelp%" md "%plixHelp%"
if not exist "%plixXML%Schemas" md "%plixXML%Schemas"
if not exist "%plixXML%Formatters" md "%plixXML%Formatters"

xcopy /Y /D /Q "%rootPath%%outDir%%plixTool%.dll" "%plixBinaries%"
if exist "%rootPath%%outDir%%plixTool%.pdb" (
xcopy /Y /D /Q "%rootPath%%outDir%%plixTool%.pdb" "%plixBinaries%"
) else (
if exist "%plixBinaries%%plixTool%.pdb" (
del "%plixBinaries%%plixTool%.pdb"
)
)

xcopy /Y /D /Q "%rootPath%PlixXsd.html" "%plixHelp%"
xcopy /Y /D /Q "%rootPath%PlixLoaderXsd.html" "%plixHelp%"
xcopy /Y /D /Q "%rootPath%VSIntegrationInstructions.html" "%plixHelp%"
xcopy /Y /D /Q "%rootPath%%outDir%PlixLoader.xsd" "%plixXML%Schemas"
xcopy /Y /D /Q "%rootPath%%outDir%Plix.xsd" "%plixXML%Schemas"
xcopy /Y /D /Q "%rootPath%%outDir%PlixRedirect.xsd" "%plixXML%Schemas"
xcopy /Y /D /Q "%rootPath%%outDir%PlixSettings.xsd" "%plixXML%Schemas"
xcopy /Y /D /Q "%rootPath%%outDir%catalog.xml" "%plixXML%Schemas"
xcopy /Y /D /Q "%rootPath%%outDir%PlixSettings.xml" "%plixXML%"
xcopy /Y /D /Q "%rootPath%%outDir%PlixMain.xslt" "%plixXML%Formatters"
xcopy /Y /D /Q "%rootPath%%outDir%PlixCS.xslt" "%plixXML%Formatters"
xcopy /Y /D /Q "%rootPath%%outDir%PlixVB.xslt" "%plixXML%Formatters"
xcopy /Y /D /Q "%rootPath%%outDir%PlixPHP.xslt" "%plixXML%Formatters"
xcopy /Y /D /Q "%rootPath%%outDir%PlixJSL.xslt" "%plixXML%Formatters"
xcopy /Y /D /Q "%rootPath%%outDir%PlixPY.xslt" "%plixXML%Formatters"
ECHO F | xcopy /Y /D /Q "%rootPath%..\Setup\PLiXSchemaCatalog.xml" "%envPath%Xml\Schemas"

"%vsipbin%regpkg.exe" /root:"%VSRegistryRootBase%\%VSRegistryRootVersion%" /codebase "%plixBinaries%%plixTool%.dll"
"%vsipbin%regpkg.exe" /root:"%VSRegistryRootBase%\%VSRegistryRootVersion%Exp" /codebase "%plixBinaries%%plixTool%.dll"

CALL:_InstallCustomTool "%TargetVisualStudioNumericVersion%"
CALL:_InstallCustomTool "%TargetVisualStudioNumericVersion%Exp"
GOTO:EOF

:_InstallCustomTool
CALL:_AddCustomToolReg "%~1"
CALL:_AddRegGenerator "%~1" "{fae04ec1-301f-11d3-bf4b-00c04f79efbc}" "Neumont C# Plix Loader"
CALL:_AddRegGenerator "%~1" "{164b10b9-b200-11d0-8c61-00a0c91e29d5}" "Neumont VB Plix Loader"
CALL:_AddRegGenerator "%~1" "{e6fdf8b0-f3d1-11d4-8576-0002a516ece8}" "Neumont J# Plix Loader"

:_AddCustomToolReg
REG DELETE "HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}" /f 1>NUL 2>&1
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997} /f /ve /d "%plixToolClass%" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}\InprocServer32 /f /ve /d "%SystemRoot%\System32\mscoree.dll" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}\InprocServer32 /f /v "ThreadingModel" /d "Both" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}\InprocServer32 /f /v "Class" /d "%plixToolClass%" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}\InprocServer32 /f /v "CodeBase" /d "%plixBinaries%%plixTool%.dll" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\CLSID\{12f1fc1e-20a6-4286-9c43-25209bba5997}\InprocServer32 /f /v "Assembly" /d "%plixTool%, Version=1.0, Culture=neutral, PublicKeyToken=7a0c83ac6f8a469f" 1>NUL
GOTO:EOF

:_AddRegGenerator
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\Generators\%~2\NUPlixLoader /f /ve /d "%~3" 1>NUL
REG ADD HKLM\SOFTWARE%WOWRegistryAdjust%\Microsoft\VisualStudio\%~1\Generators\%~2\NUPlixLoader /f /v "CLSID" /d "{12f1fc1e-20a6-4286-9c43-25209bba5997}" 1>NUL
GOTO:EOF

:SET6432
::Do this somewhere the resolved parens will not cause problems.
SET ResolvedProgramFiles=%ProgramFiles(x86)%
SET ResolvedCommonProgramFiles=%CommonProgramFiles(x86)%
IF DEFINED PROCESSOR_ARCHITEW6432 (
	:: Called from a 32-bit process, registry keys in the HKLM\SOFTWARE hive will self-adjust
	SET WOWRegistryAdjust=
) ELSE (
	SET WOWRegistryAdjust=\Wow6432Node
)
GOTO:EOF

:SETVAR
SET %~1=%~2
GOTO:EOF
