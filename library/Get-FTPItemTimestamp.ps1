Function Get-FTPItemTimestamp
{
    <#
	.SYNOPSIS
	    Gets the item timestamp.

	.DESCRIPTION
	    The Get-FTPItemTimestamp cmdlet gets the specific item timestamp. 
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER Silent
	    Hide warnings. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'. 
	
	.EXAMPLE
        PS> Get-FTPItemTimestamp -Path "/myFolder/myFile.txt"
		82033

	.NOTES
		Author: Thiago Lunardi
		Blog  : http://thiagolunardi.net/

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
			Write-Warning "Get-FTPItemTimestamp: Cannot find session $Session. First use Set-FTPConnection to config FTP connection."
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get item timestamp")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			
			$Request.Method = [System.Net.WebRequestMethods+FTP]::GetDateTimestamp 
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$Response = $Request.GetResponse()

				$Status = $Response.LastModified
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