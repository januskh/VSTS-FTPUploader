Function Remove-FTPItem
{
    <#
	.SYNOPSIS
	    Remove specific item from ftp server.

	.DESCRIPTION
	    The Remove-FTPItem cmdlet remove item from specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER Recurse
	    Remove items recursively.		
			
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'. 
	
	.EXAMPLE
		PS> Remove-FTPItem -Path "/myFolder" -Recurse
		->Remove Dir: /myFolder/mySubFolder
		250 Remove directory operation successful.

		->Remove Dir: /myFolder
		250 Remove directory operation successful.

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
		[Switch]$Recurse = $False,
		$Session = "DefaultFTPSession"
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Remove item from ftp location")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			
			if((Get-FTPItemSize -Path $RequestUri -Session $Session -Silent) -ge 0)
			{
				$Request.Method = [System.Net.WebRequestMethods+FTP]::DeleteFile
				"->Remove File: $RequestUri"
			}
			else
			{
				$Request.Method = [System.Net.WebRequestMethods+FTP]::RemoveDirectory
				
				$SubItems = Get-FTPChildItem -Path $RequestUri -Session $Session 
				if($SubItems)
				{
					$RemoveFlag = 0
					if(!$Recurse)
					{
						$Title = "Remove recurse"
						$Message = "Do you want to recurse remove items from location?"

						$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
						$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
						$Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)

						$RemoveFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 0) 
					}
					else
					{
						$RemoveFlag = 1
					}
					
					if($RemoveFlag)
					{
						Foreach($SubItem in $SubItems)
						{
							Remove-FTPItem -Path ($RequestUri+"/"+$SubItem.Name.Trim()) -Session $Session -Recurse
						}
					}
					else
					{
						Return
					}
				}
				"->Remove Dir: $RequestUri"
			}
			
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$Response = $Request.GetResponse()

				$Status = $Response.StatusDescription
				$Response.Close()
				#Return $Status
			}
			Catch
			{
				Write-Error $_.Exception.Message -ErrorAction Stop 
			}
		}
	}
	
	End{}				
}