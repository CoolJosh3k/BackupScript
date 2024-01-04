@echo off

set "ArchiveFolder=%cd%\output\RemoteBackup"

gsutil cp "%ArchiveFolder%\*.rar" "gs://regular_backups"

echo.
echo Done!
echo.
pause