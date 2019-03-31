@ECHO OFF
SETLOCAL
SET RootDir=%~dp0.
IF "%TargetVisualStudioNumericVersion%"=="15.0" (
	MSBuild.exe /nologo "%RootDir%\CodeGen.VS2017.sln" %*
	MSBuild.exe /nologo "%RootDir%\VSIXInstall\VSIXOnly\PLiXVSIX.VS2017.sln" %*
) ELSE (
	IF NOT DEFINED FrameworkSDKDir (CALL "%VS80COMNTOOLS%\vsvars32.bat")
	MSBuild.exe /nologo "%RootDir%\CodeGen.sln" %* /toolsversion:2.0
	MSBuild.exe /nologo "%RootDir%\PLiXReflector.sln" %*
	MSBuild.exe /nologo "%RootDir%\Setup\Setup.sln" %*
)
