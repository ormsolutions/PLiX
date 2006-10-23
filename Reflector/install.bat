@echo off
setlocal
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
set plixBinaries=%ProgramFiles%\Neumont\PLiX for Visual Studio\bin\
set plixReflectorTool=Reflector.PLiXLanguage

:: Create new directories
if not exist "%plixBinaries%" md "%plixBinaries%"

xcopy /Y /D /Q "%rootPath%%outDir%%plixReflectorTool%.dll" "%plixBinaries%"
if exist "%rootPath%%outDir%%plixReflectorTool%.pdb" (
xcopy /Y /D /Q "%rootPath%%outDir%%plixReflectorTool%.pdb" "%plixBinaries%"
) else (
if exist "%plixBinaries%%plixReflectorTool%.pdb" (
del "%plixBinaries%%plixReflectorTool%.pdb"
)
)
