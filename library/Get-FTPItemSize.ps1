Function Get-FTPItemSize
{
    <#
	.SYNOPSIS
	    Gets the item size.

	.DESCRIPTION
	    The Get-FTPItemSize cmdlet gets the specific item size. 
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER Silent
	    Hide warnings. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'. 
	
	.EXAMPLE
        PS> Get-FTPItemSize -Path "/myFolder/myFile.txt"
		82033

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
		[parameter(Mandatory=$true)]
		[String]$Path = "",
		[Switch]$Silent = $False,
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get item size")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			
			$Request.Method = [System.Net.WebRequestMethods+FTP]::GetFileSize 
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$Response = $Request.GetResponse()

				$Status = $Response.ContentLength
				$Response.Close()
				Return $Status
			}
			Catch
			{
				if(!$Silent)
				{
					Write-Error $_.Exception.Message -ErrorAction Stop  
				}	
				Return -1
			}
		}
	}
	
	End{}				
}