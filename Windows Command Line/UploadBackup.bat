@echo off

set "ArchiveFolder=%cd%\output\RemoteBackup"

gcloud storage cp "%ArchiveFolder%\*.rar" "gs://regular_backups"

echo.
echo Done!
echo.
pause