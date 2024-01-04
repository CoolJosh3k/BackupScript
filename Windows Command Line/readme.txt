Dependencies:
OpenSSL
WinRAR

Dependencies for remote:
gcloud tool

Setup windows:
* Create an enviroment path variable pointing to the folder containing openssl.exe
* Create an enviroment path variable pointing to the folder containing Rar.exe

Setup windows for remote:
* Create an enviroment path variable pointing to the folder containing gcloud.cmd

1. Replace the contents of "hash" with the output of
	openssl passwd -6 -salt salt
	to store the hash of your own encryption key

2. Modify the contents of exclude.txt as needed

3. Create an empty text file "Backup-Source.txt" onto root of source drive
	note: for local backup support also create an empty text file "Backup-Destination.txt" on destination drive

4. For remote support modify the gsutil command in UploadBackup.bat as needed

5. Run PerformBackup.bat and follow the prompts