@echo off

setlocal

rem Choose which backups to make
echo.
echo Will this be a Local backup, Remote backup or Both?
:ChoosePlannedBackupDestination
echo.
echo Please type L for Local, R for Remote, or B for Both:
set /p PlannedBackupDestination=

if /i %PlannedBackupDestination% == R (goto StartOutputFolderCreation)
if /i %PlannedBackupDestination% == L (goto StartOutputFolderCreation)
if /i %PlannedBackupDestination% == B (goto StartOutputFolderCreation) else (goto ChoosePlannedBackupDestination)


:StartOutputFolderCreation
rem Output folder creation
if exist "%cd%\output\" (echo. & echo Output folder already exists!) else (goto CreateOutputFolder)
echo.
echo Do you wish to clear the previous output folder? Enter Y to clear and continue.
set /p DeleteOutputFolder=
if /i %DeleteOutputFolder% == Y (rmdir /s /q "%cd%\output"
	if errorlevel 1 (
		echo.
		echo Failed to delete output folder! Ending script.
		goto Finish
	)
) else (goto Finish)
echo.
echo Previous output folder was deleted. Now creating new one and proceeding with backup script...

:CreateOutputFolder

md "%cd%\output"
if errorlevel 1 (
	echo.
	echo Failed to create the output folder! Ending script.
	goto Finish
)
echo.
echo Output folder created successfully.

rem Grab the hash from the hash file in the current directory
set /p HashFromFile= < hash

:PasswordEntry
echo.
echo Enter desired encryption phrase:
set /p BackupPassword=
rem Generate the hash
for /f "tokens=*" %%a in ('openssl passwd -6 -salt salt %BackupPassword%') do set Hash=%%a
rem Check that the generated hash is the same as a precomputed hash
if not %Hash% == %HashFromFile% (cls & echo Computed hash did not match stored hash of expected encryption phrase! Try again. & goto PasswordEntry)

cls

rem Get source drive
:GetSourceDrive
set BackupSourceDriveCheckFile=Backup-Source.txt
echo.
echo Enter drive letter for source drive:
set /p SourceDriveLetter=
if not exist %SourceDriveLetter%:\%BackupSourceDriveCheckFile% (echo. & echo %BackupSourceDriveCheckFile% not found on drive. Try again. & goto GetSourceDrive)

rem is this remote only?
if /i %PlannedBackupDestination% == R (goto SkipDestinationDrive)
rem Get destination drive
:GetDestinationDrive
set BackupDestinationDriveCheckFile=Backup-Destination.txt
echo.
echo Enter drive letter for destination drive:
set /p DestinationDriveLetter=
if not exist %DestinationDriveLetter%:\%BackupDestinationDriveCheckFile% (echo. & echo %BackupDestinationDriveCheckFile% not found on drive. Try again. & goto GetDestinationDrive)
:SkipDestinationDrive

rem Set type
echo.
echo Is this a "full" backup, a "differential" or a "version" backup?
:RequestBackupType
echo.
echo Please type either F for full, D for differential or V for version:
set /p BackupType=
if /i %BackupType% == F (goto FullBackup)
if /i %BackupType% == D (goto DiffBackup)
if /i %BackupType% == V (goto VerBackup) else (goto RequestBackupType)

:FullBackup
set BackupTypeName=Full
set FromTime=0
goto PerformBackup

:FromTimeEntry
set /p FromTime="%~1 (YYYYMMDDHHMMSS): "

set "var=" & for /f "delims=0123456789" %%i in ("%FromTime%") do set "var=%%i"
if defined var (
	goto InvalidTimeFormat
)

call :strlen FromTimeLength FromTime
if not %FromTimeLength% == 14 (
	goto InvalidTimeFormat
)

set BackupTypeName=%~2_%FromTime%
exit /b

:InvalidTimeFormat
echo.
echo Format mismatch! Please try again.
goto FromTimeEntry

:DiffBackup
echo.
call :FromTimeEntry "Please enter timestamp of last full backup" "Diff"
goto PerformBackup

:VerBackup
echo.
call :FromTimeEntry "Please enter timestamp of last version backup, or last full backup if no newer version backups exist" "Version"
goto PerformBackup

:PerformBackup

set Source="%SourceDriveLetter%:\*.*"

rem is this remote only?
if /i %PlannedBackupDestination% == R (goto SkipSetLocalDestination)

set Destination="%DestinationDriveLetter%:\_ImportantData_%BackupTypeName%.rar"
:SkipSetLocalDestination

echo.
pause
echo.

:RemoteBackup
if /i %PlannedBackupDestination% == L (goto SkipRemoteBackup)
rem Make remote
title Creating Remote Backup...
md "%cd%\output\RemoteBackup"
Rar a -ag+YYYYMMDDHHMMSS -dh -ep1 -es -ilog"%cd%\output\RemoteErrors.log" -k -logf="%cd%\output\RemoteBackup.log" -m5 -ms -os -p%BackupPassword% -r -s -t -tamco%FromTime% -x%BackupSourceDriveCheckFile% -x@"%cd%\exclude.txt" "%cd%\output\RemoteBackup\_ImportantData_%BackupTypeName%.rar" %Source%
if not exist "%cd%\output\RemoteErrors.log" (start "Uploading..." %0\..\UploadBackup.bat)
:SkipRemoteBackup

if /i %PlannedBackupDestination% == R (goto SkipLocalBackup)
:LocalBackup
rem Make local
title Creating Local Backup...
Rar a -ag+YYYYMMDDHHMMSS -dh -ep1 -es -ilog"%cd%\output\LocalErrors.log" -k  -logf="%cd%\output\LocalBackup.log" -m0 -os -p%BackupPassword% -r -rr100p -t -tamco%FromTime% -x%BackupSourceDriveCheckFile% -x@"%cd%\exclude.txt" %Destination% %Source%
:SkipLocalBackup

goto Finish

:Finish
rem clear all enviroment variables
set BackupType=
set BackupTypeName=
set FromTime=
set SourceDriveLetter=
set DestinationDriveLetter=
set BackupPassword=
set BackupPasswordConfirmation=

echo.

title Done!

endlocal

pause

exit

:strlen <resultVar> <stringVar>
(
	setlocal EnableDelayedExpansion
	(set^ tmp=!%~2!)
	if defined tmp (
		set "len=1"
		for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
			if "!tmp:~%%P,1!" NEQ "" ( 
				set /a "len+=%%P"
				set "tmp=!tmp:~%%P!"
			)
		)
	) ELSE (
		set len=0
	)
)
(
	endlocal
	set "%~1=%len%"
	exit /b
)