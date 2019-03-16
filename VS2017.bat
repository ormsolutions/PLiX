@ECHO OFF
SET TargetVisualStudioNumericVersion=15.0
set SDKVSCT=
for %%i in (vsct.exe) do (set EXISTINGVSCT=%%~s$PATH:i)
if '%EXISTINGVSCT%'=='' (
	CALL:GETSHORTPATH "SDKVSCT" "%VSSDK150INSTALL%\VisualStudioIntegration\Tools\Bin"
)
if NOT '%SDKVSCT%'=='' (
	CALL:EXTENDPATH "%SDKVSCT%"
)
SET FOUNDVSCT=
SET SDKVSCT=
SET EXISTINGVSCT=
goto:EOF

:GETSHORTPATH
SET %~1=%~s2
GOTO:EOF

:EXTENDPATH
SET PATH=%PATH%;%~1
GOTO:EOF
