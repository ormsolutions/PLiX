@ECHO OFF
SETLOCAL
IF NOT DEFINED FrameworkSDKDir (CALL "%VS80COMNTOOLS%\vsvars32.bat")
SET RootDir=%~dp0.
IF "%TargetVisualStudioNumericVersion%"=="15.0" (
	MSBuild.exe /nologo "%RootDir%\CodeGen.sln" %*
) ELSE (
	MSBuild.exe /nologo "%RootDir%\CodeGen.sln" %* /toolsversion:2.0
	MSBuild.exe /nologo "%RootDir%\PLiXReflector.sln" %*
	MSBuild.exe /nologo "%RootDir%\Setup\Setup.sln" %*
)
