@echo off
set rootPath=%1
if '%2'=='' (
set outDir="bin\Debug\"
) else (
set outDir=%2
)
if '%3'=='' (
set envPath="C:\Program Files\Microsoft Visual Studio 8\"
) else (
set envPath=%3
)
xcopy /Y /D /Q %rootPath%%outDir%"Neumont.Tools.CodeGeneration.CustomTools.dll" %envPath%"Common7\IDE\PrivateAssemblies\"
if exist %rootPath%%outDir%"Neumont.Tools.CodeGeneration.CustomTools.pdb" (
xcopy /Y /D /Q %rootPath%%outDir%"Neumont.Tools.CodeGeneration.CustomTools.pdb" %envPath%"Common7\IDE\PrivateAssemblies\"
) else (
if exist %envPath%"Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.pdb" (
del %envPath%"Common7\IDE\PrivateAssemblies\Neumont.Tools.CodeGeneration.CustomTools.pdb"
)
)
if not exist %envPath%"Neumont\CodeGeneration\PLiX\Formatters" (
mkdir %envPath%"Neumont\CodeGeneration\PLiX\Formatters"
)
xcopy /Y /D /Q %rootPath%%outDir%"PlixLoader.xsd" %envPath%"Xml\Schemas\"
xcopy /Y /D /Q %rootPath%%outDir%"Plix.xsd" %envPath%"Xml\Schemas\"
xcopy /Y /D /Q %rootPath%%outDir%"PlixRedirect.xsd" %envPath%"Xml\Schemas\"
xcopy /Y /D /Q %rootPath%%outDir%"PlixSettings.xsd" %envPath%"Xml\Schemas\"
xcopy /Y /D /Q %rootPath%%outDir%"PlixSettings.xml" %envPath%"Neumont\CodeGeneration\PLiX"
xcopy /Y /D /Q %rootPath%%outDir%"PlixMain.xslt" %envPath%"Neumont\CodeGeneration\PLiX\Formatters"
xcopy /Y /D /Q %rootPath%%outDir%"PlixCS.xslt" %envPath%"Neumont\CodeGeneration\PLiX\Formatters"
regedit /s %rootPath%PlixLoaderCustomTool.reg
