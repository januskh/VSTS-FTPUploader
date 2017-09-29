# FTP Uploader

This utility task can help you deploy to an IIS ftp server or alike. It uses PowerShell to generate the list of files that you may want to upload to an FTP server.

The task is based on the [PowerShell FTP Client Module](https://gallery.technet.microsoft.com/scriptcenter/PowerShell-FTP-Client-db6fe0cb), developed by [Michal Gajda](https://social.technet.microsoft.com/profile/michalgajda/), with small adjustments.



## Features

 - Exclude files filter
 Filter out files that you don't want to upload.
 - Deploy only the deployment files. 
 Certain files and folders are then excluded like *.vb and *.cs and more.
 - Delete old files
 Deletes all the existing files on the FTP server before uploading.
 - Ignore unchanged files
 Ignore and don't upload files with same size and older modification timestamp

## Change Log

Version: 1.0.29 - 29th of September 2017
- Bugfix: Error regarding ignoreUnchangedFiles. Error: System.Management.Automation.ParameterBindingException: A parameter cannot be found that matches parameter name 'ignoreUnchangedFiles''.

Version: 1.0.28 - 22th of September 2017
 - Added 'Ignore unchanged files' feature. - Thanks to Thiago Lunardi http://thiagolunardi.net/

Version: 1.0.26 - 22nd of September 2017
- Exclude filtering adjusted based on Justin Mangum suggestion. Thank you Justin.
 
Version: 1.0.24 - 8th of Febuary 2016
- Parameter bug fix in connection with the new 'Use binary' feature.

Version: 1.0.23 - 7th of Febuary 2016
- Updated description about SourcePath.
- Added 'Use binary' feature.

 
## Installation

Add the FTP Uploader to either your Build Definition or Release Definition.

**Properties**

- **Source Path**
Select what to deploy by using the [...] button.
Files will be uploaded recursive from the source-path. Everything will be included. Wildcards are not supported.

- **FTP Address**
The way you specify the server address is to start it with ftp:// 
```
  Example: ftp://myFTPServerAddress.com:21/
  Example: ftp://ftp.myFTPServerAddress.com:21/
```
You don't need to specify the port, unless you use another port than 21.

- **Username**
Specify the ftp-username that is used for the authentication on the FTP server.

- **Password**
You can either specify the password directly. It will be readable in the Build/Release definition, which is not recommendable. To hide the password, you switch to the "Configuration"-tab, and create a variable. Use the lock-icon to make it secret.
To use password variable, type in $(VariableName)
Replace 'VariableName' with the name of your variable.
```
  Example: $(Password)
```

- **Remote Path**
To specify the remote path you must specify the folder-root where you want to publish.
```
  Example: /public_html/
```
The folder is root based and must start with slash.

**Advanced Properties**

- **Use binary** (Default: False)
If checked, files and folders are transferred using Binary-protocol.

- **Ignore unchanged files** (Default: False)
If checked, files and folders with same size and older modification timestamp will not be uploaded.

- **Exclude files**
If there are files or filetypes that you do not want to deploy, you can specify them in the field. Default is: '*.vb','*.vbproj'
```
  Example: '*.vb','*.vbproj','web.config'
```
The string is comma seperated values. To read more, see the [-Exclude parameter section](https://technet.microsoft.com/en-us/library/hh849800.aspx) of this whitepaper.

- **Delete old Files** (Default: True)
If checked, files and folders inside the Remote Path will be deleted before uploading.
Uploading without this checked will overwrite existing files on the 'Remote Path'.

- **Publish only deployment files** 
This option will prevent not used deployment files to be uploaded. Folders: "/Obj/", "My Project" and file-types: *.vb, *.cs, *.vbproj, *.csproj, *.user, *.vspscc are not deployed.

## Contribute

If you experiance issues, and what to help, please check out the GitHub repo, clone and make a pull-request. The GitHub repo is located here:
https://github.com/januskh/VSTS-FTPUploader
 
Enjoy.

Thanks to [Michal Gajda](https://social.technet.microsoft.com/profile/michalgajda/)

Sincerely 
[Janus Kamp Hansen](https://social.technet.microsoft.com/Profile/Janus%20Kamp%20Hansen)