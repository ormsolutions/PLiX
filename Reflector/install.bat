@echo off
setlocal

IF "%ProgramFiles(X86)%"=="" (
	SET ResolvedProgramFiles=%ProgramFiles%
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
set plixBinaries=%ResolvedProgramFiles%\Neumont\PLiX for Visual Studio\bin\
set plixHelp=%ResolvedProgramFiles%\Neumont\PLiX for Visual Studio\Help\
set plixReflectorTool=Reflector.PLiXLanguage

:: Create new directories
if not exist "%plixBinaries%" md "%plixBinaries%"
if not exist "%plixHelp%" md "%plixHelp%"

xcopy /Y /D /Q "%rootPath%%outDir%%plixReflectorTool%.dll" "%plixBinaries%"
if exist "%rootPath%%outDir%%plixReflectorTool%.pdb" (
xcopy /Y /D /Q "%rootPath%%outDir%%plixReflectorTool%.pdb" "%plixBinaries%"
) else (
if exist "%plixBinaries%%plixReflectorTool%.pdb" (
del "%plixBinaries%%plixReflectorTool%.pdb"
)
)

xcopy /Y /D /Q "%rootPath%ReflectorIntegration.html" "%plixHelp%"

GOTO:EOF

:SET6432
::Do this somewhere the resolved parens will not cause problems.
SET ResolvedProgramFiles=%ProgramFiles(x86)%
GOTO:EOF
