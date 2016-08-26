Function New-FTPItem
{
    <#
	.SYNOPSIS
	    Creates a new folder on ftp.

	.DESCRIPTION
		The New-FTPItem cmdlet creates a new folder in specific path in current ftp session.
		
	.PARAMETER Path
	    Specifies a path to ftp location or file. 
		
	.PARAMETER Name
	    Specifies a name of item. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.  
	
	.EXAMPLE
        PS> New-FTPItem -Name "myfolder"
		257 "/mg/myfolder" created

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
		[String]$Path = "",
		[parameter(Mandatory=$true)]
		[String]$Name,
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
		$RequestUri = $RequestUri+"/"+$Name
		$RequestUri = [regex]::Replace($RequestUri, '/$', '')
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		Write-Debug "Remove additonal slash: $RequestUri"

		if ($pscmdlet.ShouldProcess($RequestUri,"Create new folder: '$Name' in ftp location")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			
			$Request.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$Response = $Request.GetResponse()

				$Status = $Response.StatusDescription
				$Response.Close()
				Return $Status
			}
			Catch
			{
				$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
				Write-Error $Error -ErrorAction Stop 
			}
		}
	}
	
	End{}				
}