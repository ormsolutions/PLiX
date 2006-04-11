@setlocal
@set BuildType=Debug
@FOR /F "usebackq skip=3 tokens=2*" %%A IN (`REG QUERY "HKLM\SOFTWARE\Microsoft\VisualStudio\8.0" /v "InstallDir"`) DO call set LaunchDevenv=%%~dpsBdevenv
%launchdevenv% "%~dp0CodeGen.sln" /Rebuild %BuildType%
call "%~dp0CodeGenCustomTool\Install.bat"
%launchdevenv% "%~dp0Setup/Setup.sln" /Rebuild Setup
