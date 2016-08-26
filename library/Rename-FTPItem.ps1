Function Rename-FTPItem
{
    <#
	.SYNOPSIS
	    Renames an item in ftp session. Additionally it can be used for move items between folders.

	.DESCRIPTION
	    The Rename-FTPItem cmdlet changes the name of a specified item. This cmdlet does not affect the content of the item being renamed.
		
	.PARAMETER Path
	    Specifies a path to ftp item. 
		
	.PARAMETER NewName
		Specifies a new name of ftp item.
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE
        PS> Rename-FTPItem -Path "/myfolder" -NewName "myNewFolder"
		250 Rename successful.

	.EXAMPLE
        PS> Rename-FTPItem TestFile.txt TestFolder/TestFile.txt
		250 Rename successful.

        PS> Rename-FTPItem TestFolder/TestFile.txt ../TestFile.txt
		250 Rename successful.
		
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
		[String]$NewName,
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Rename item to: '$NewName' in ftp location")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			$Request.RenameTo = $NewName

			$Request.Method = [System.Net.WebRequestMethods+FTP]::Rename
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
				Write-Error $_.Exception.Message -ErrorAction Stop 
			}
		}
	}
	
	End{}				
}