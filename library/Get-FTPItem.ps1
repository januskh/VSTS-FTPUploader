Function Get-FTPItem
{
    <#
	.SYNOPSIS
	    Send specific file from ftop server to location disk.

	.DESCRIPTION
	    The Get-FTPItem cmdlet download file to specific location on local machine.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 
		
	.PARAMETER RecreateFolders
		Recreate locally folders structure from ftp server.

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Overwrite
	    Overwrite item in local path. 
		
	.EXAMPLE
		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test
		226 File send OK.

		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test

		A File name already exists in location: P:\test
		What do you want to do?
		[C] Cancel  [O] Overwrite  [?] Help (default is "O"): O
		226 File send OK.

	.EXAMPLE	
		PS P:\> Get-FTPChildItem -path folder/subfolder1 -Recurse | Get-FTPItem -localpath p:\test -RecreateFolders -Verbose
		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/test.xlsx'" on Target "p:\test\folder\subfolder1".
		VERBOSE: Creating folder: folder\subfolder1
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/ziped.zip'" on Target "p:\test\folder\subfolder1".
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/subfolder11/ziped.zip'" on Target "p:\test\folder\subfolder1\subfolder11".
		VERBOSE: Creating folder: folder\subfolder1\subfolder11
		226 File send OK.

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
        Get-FTPChildItem
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[Alias("FullName")]
		[String]$Path = "",
		[String]$LocalPath = (Get-Location).Path,
		[Switch]$RecreateFolders,
		[Int]$BufferSize = 20KB,
		$Session = "DefaultFTPSession",
		[Switch]$Overwrite = $false
	)
	
	Begin
	{
		if($Session -isnot [String])
		{
			$CurrentSession = $Session
		}
		else
		{
			$CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		}
		
		if($CurrentSession -eq $null)
		{
			Write-Warning "Add-FTPItem: Cannot find session $Session. First use Set-FTPConnection to config FTP connection."
			Break
			Return
		}	
	}
	
	Process
	{
		Write-Debug "Native path: $Path"
		
		if($Path -match "ftp://")
		{
			$RequestUri = $Path
			Write-Debug "Use original path: $RequestUri"
			
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path
			Write-Debug "Add ftp:// at start: $RequestUri"
		}
		$RequestUri = [regex]::Replace($RequestUri, '/$', '')
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		Write-Debug "Remove additonal slash: $RequestUri"
			
		if ($pscmdlet.ShouldProcess($LocalDir,"Download item: '$RequestUri'")) 
		{	
			$TotalData = Get-FTPItemSize $RequestUri -Session $Session -Silent
			if($TotalData -eq -1) { Return }
			if($TotalData -eq 0) { $TotalData = 1 }

			$AbsolutePath = ($RequestUri -split $CurrentSession.ServicePoint.Address.AbsoluteUri)[1]
			$LastIndex = $AbsolutePath.LastIndexOf("/")
			$ServerPath = $CurrentSession.ServicePoint.Address.AbsoluteUri
			if($LastIndex -eq -1)
			{
				$FolderPath = "\"
			}
			else
			{
				$FolderPath = $AbsolutePath.SubString(0,$LastIndex) -replace "/","\"
			}	
			$FileName = $AbsolutePath.SubString($LastIndex+1)
		
			if($RecreateFolders)
			{
				if(!(Test-Path (Join-Path -Path $LocalPath -ChildPath $FolderPath)))
				{
					Write-Verbose "Creating folder: $FolderPath"
					New-Item -Type Directory -Path $LocalPath -Name $FolderPath | Out-Null
				}
				$LocalDir = Join-Path -Path $LocalPath -ChildPath $FolderPath
			}
			else
			{
				$LocalDir = $LocalPath
			}			
			
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive

			$Request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile  
			Write-Debug "Use WebRequestMethods: $($Request.Method)"
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$SendFlag = 1
				
				if((Get-ItemProperty $LocalDir -ErrorAction SilentlyContinue).Attributes -match "Directory")
				{
					$LocalDir = Join-Path -Path $LocalDir -ChildPath $FileName
				}
				
				if(Test-Path ($LocalDir))
				{
					$FileSize = (Get-Item $LocalDir).Length
					
					if($Overwrite -eq $false)
					{
						$Title = "A file ($RequestUri) already exists in location: $LocalDir"
						$Message = "What do you want to do?"

						$CDOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
						$CDCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
						if($FileSize -lt $TotalData)
						{
							$CDResume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($CDCancel, $CDOverwrite, $CDResume)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
						}
						else
						{
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($CDCancel, $CDOverwrite)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1)
						}
					}
					else
					{
						$SendFlag = 1
					}
				}

				if($SendFlag)
				{
					[Byte[]]$Buffer = New-Object Byte[] $BufferSize

					$ReadedData = 0
					$AllReadedData = 0
					
					if($SendFlag -eq 2)
					{      
						$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Append)
						$Request.UseBinary = $True
						$Request.ContentOffset  = $FileSize 
						$AllReadedData = $FileSize
						Write-Debug "Open File to append: $LocalDir"
					}
					else
					{
						$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Create)
						Write-Debug "Create File: $LocalDir"
					}
					
					$Response = $Request.GetResponse()
					$Stream  = $Response.GetResponseStream()
					
					Do{
						$ReadedData=$Stream.Read($Buffer,0,$Buffer.Length)
						$AllReadedData +=$ReadedData
						$File.Write($Buffer,0,$ReadedData)
						if($TotalData)
						{
							Write-Progress -Activity "Download File: $Path" -Status "Downloading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
						}
					}
					While ($ReadedData -ne 0)
					$File.Close()
					Write-Debug "Close File: $LocalDir"
					
					$Status = $Response.StatusDescription
					$Response.Close()
					Return $Status
				}
			}
			Catch
			{
				Write-Error $_.Exception.Message -ErrorAction Stop 
			}
		}
	}
	
	End{}
}