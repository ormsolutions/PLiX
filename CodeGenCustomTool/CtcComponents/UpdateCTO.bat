@echo off
setlocal
:: TargetVisualStudioNumericVersion settings:
::   8.0 = Visual Studio 2005 (Code Name "Whidbey")
::   9.0 = Visual Studio 2008 (Code Name "Orcas")
IF %TargetVisualStudioNumericVersion% GEQ 15.0 GOTO:EOF

SET TargetVisualStudioNumericVersion=8.0

SET VSRegistryRootBase=SOFTWARE\Microsoft\VisualStudio
SET VSRegistryRootVersion=%TargetVisualStudioNumericVersion%
FOR /F "usebackq skip=2 tokens=2*" %%A IN (`REG QUERY "HKLM\%VSRegistryRootBase%\VSIP\%VSRegistryRootVersion%" /v "InstallDir"`) DO SET VSIPDir=%%~fB
SET vsipbin=%VSIPDir%VisualStudioIntegration\Tools\Bin\

REM Only update if the newest file is not the .cto
for /F "usebackq tokens=2 delims=." %%A in (`dir /b /od "%~dp0PLiXPackage.ctc" "%~dp0PLiXPackage.cto"`) do set NewestExtension=%%A
if NOT "%NewestExtension%"=="cto" (
@echo on
"%vsipbin%ctc.exe" -nologo "%~dp0PLiXPackage.ctc" "%~dp0PLiXPackage.cto" -Ccl -s- -I"%VSIPDir%VisualStudioIntegration\Common\Inc" -I"%VSIPDir%VisualStudioIntegration\Common\Inc\office10"
)
