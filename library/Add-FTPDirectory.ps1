Function Add-FTPDirectory
{
    <#
	.SYNOPSIS
	    Create a folder on ftp location.

	.DESCRIPTION
	    The Add-FTPItem cmdlet send file to specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER NewFolder
	    Name of folder to create of ftp. 		
		
	.EXAMPLE
		PS> Add-FTPDirectory "/myExistingFolder" "NewFolder"

	.NOTES
		Author: Janus Kamp Hansen
		Blog  : http://www.kamp-hansen.dk/

	.LINK
        Add-FTPDirectory
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
		[String]$NewFolder = "",
        [bool]$SuppressErrors = $false,
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
		
		if($Path -match "ftp://")
		{
			$RequestUri = $Path
			Write-Debug "Use original path: $RequestUri"
			
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path+$NewFolder
			Write-Debug "Add ftp:// at start: $RequestUri"
		}
		$RequestUri = [regex]::Replace($RequestUri, '/$', '')
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		Write-Debug "Remove additonal slash: $RequestUri"
		
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
			#Return $Status
		}
		Catch
		{
			if ($SuppressErrors -eq $True) {
                Write-Error $_.Exception.Message -ErrorAction SilentlyContinue
            } else {
                Write-Error $_.Exception.Message -ErrorAction Stop 
            }
		}
	}
	
	End{}				
}