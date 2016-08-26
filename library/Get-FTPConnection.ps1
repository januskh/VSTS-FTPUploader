Function Get-FTPConnection
{
    <#
	.SYNOPSIS
	    Get config to ftp Connection.

	.DESCRIPTION
	    The Get-FTPConnection cmdlet create a list of registered PSFTP sessions.
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session.
	
	.EXAMPLE

		Get-FTPConnection
		
	.EXAMPLE

		Get-FTPConnection -Session DefaultFTPS*

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
        Set-FTPConnection
	#>    

	[OutputType('PSFTP.Session')]
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Session
	)
	
	Begin{}
	
	Process
	{
		if($Session)
		{
			$Variables = Get-Variable -Scope Global | 
			Where-Object {$_.value -is [System.Net.FtpWebRequest] -and $_.Name -like $Session}
		}
		else
		{
			$Variables = Get-Variable -Scope Global | Where-Object {$_.value -is [System.Net.FtpWebRequest]}
		}
		
		$Sessions = @()
		$Variables | ForEach{
			$CurrentSession = Get-Variable -Scope Global -Name $_.Name -ErrorAction SilentlyContinue -ValueOnly
		
			if($Sessions -notcontains $CurrentSession)
			{
				$Sessions += $_.Value
			}
		}

		$Sessions.PSTypeNames.Clear()
		$Sessions.PSTypeNames.Add('PSFTP.Session')
		
		Return $Sessions
	}
	
	End{}				
}