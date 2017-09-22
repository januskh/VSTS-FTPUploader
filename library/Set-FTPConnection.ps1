Function Set-FTPConnection
{
    <#
	.SYNOPSIS
	    Set config to ftp Connection.

	.DESCRIPTION
	    The Set-FTPConnection cmdlet creates a Windows PowerShell configuration to ftp server. When you create a ftp connection, you may run multiple commands that use this config.
		
	.PARAMETER Credential
	    Specifies a user account that has permission to access to ftp location.
			
	.PARAMETER Server
	    Specifies the ftp server you want to connect. 
			
	.PARAMETER EnableSsl
	    Specifies that an SSL connection should be used. 
			
	.PARAMETER ignoreCert
	    If you use SSL connection you may ignore certificate error. 
			
	.PARAMETER KeepAlive
	    Specifies whether the control connection to the ftp server is closed after the request completes.  
			
	.PARAMETER UseBinary
	    Specifies the data type for file transfers.  
			
	.PARAMETER UsePassive
	    Behavior of a client application's data transfer process. 

	.PARAMETER Timeout
		Sets the length of time, in milliseconds, before the request times out.
	
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE

		Set-FTPConnection -Credentials userName -Server myftpserver.com
		
	.EXAMPLE

		$Credentials = Get-Credential
		Set-FTPConnection -Credentials $Credentials -Server ftp://myftpserver.com -EnableSsl -ignoreCert -UsePassive

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
		[Alias("Credential")]
		$Credentials, 
		[parameter(Mandatory=$true)]
		[String]$Server,
		[Switch]$EnableSsl = $False,
		[Switch]$ignoreCert = $False,
		[Switch]$KeepAlive = $False,
		[Switch]$UseBinary = $False,
		[Switch]$UsePassive = $False,
		[String]$Session = "DefaultFTPSession",
		[Int]$Timeout = 5000
	)
	
	Begin
	{
		if($Credentials -isnot [System.Management.Automation.PSCredential])
		{
			$Credentials = Get-Credential $Credentials
		}
	}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Server,"Connect to FTP Server")) 
		{	
			if(!($Server -match "ftp://"))
			{
				$Server = "ftp://"+$Server	
				Write-Debug "Add ftp:// at start: $Server"				
			}
			
			Write-Verbose "Create FtpWebRequest object."
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($Server)
			$Request.Credentials = $Credentials
			$Request.EnableSsl = $EnableSsl
			$Request.KeepAlive = $KeepAlive
			$Request.UseBinary = $UseBinary
			$Request.UsePassive = $UsePassive
			$Request.Timeout = $Timeout
			$Request | Add-Member -MemberType NoteProperty -Name ignoreCert -Value $ignoreCert
			$Request | Add-Member -MemberType NoteProperty -Name Session -Value $Session
			$Request | Add-Member -MemberType NoteProperty -Name StartPath -Value ""

			$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$ignoreCert}
				$Response = $Request.GetResponse()
				$Response.Close()
				
				if((Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue) -eq $null)
				{
					Write-Verbose "Create global variable: $Session"
					New-Variable -Scope Global -Name $Session -Value $Request
				}
				else
				{
					Write-Verbose "Set global variable: $Session"
					Set-Variable -Scope Global -Name $Session -Value $Request
				}
				
				Return $Response
			}
			Catch
			{
				Write-Error $_.Exception.Message -ErrorAction Stop 
			}
		}
	}
	
	End{}				
}