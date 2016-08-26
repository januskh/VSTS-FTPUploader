Function Remove-FTPDirectory
{

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
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

        Write-Host "Locating files and folders to delete... please wait..."

        $filelist = Get-FTPChildItem -Path $Path -Recurse

        foreach($file in $filelist | ?{ $_.DIR -ne "DIR" }) {

	        $RequestUri = [regex]::Replace($file.Fullname, '/$', '')
	        $RequestUri = [regex]::Replace($RequestUri, '/+', '/')
	        $RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')

	        [System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
	        $Request.Credentials = $CurrentSession.Credentials
	        $Request.EnableSsl = $CurrentSession.EnableSsl
	        $Request.KeepAlive = $CurrentSession.KeepAlive
	        $Request.UseBinary = $CurrentSession.UseBinary
	        $Request.UsePassive = $CurrentSession.UsePassive
	        $Request.Method = [System.Net.WebRequestMethods+FTP]::DeleteFile
	        "->Remove File: $RequestUri"

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

        foreach($dir in $filelist | ?{ $_.DIR -eq "DIR" } | Sort-Object -Property FullName -Descending ) {

	        $RequestUri = [regex]::Replace($dir.Fullname, '/$', '')
	        $RequestUri = [regex]::Replace($RequestUri, '/+', '/')
	        $RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')

	        [System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
	        $Request.Credentials = $CurrentSession.Credentials
	        $Request.EnableSsl = $CurrentSession.EnableSsl
	        $Request.KeepAlive = $CurrentSession.KeepAlive
	        $Request.UseBinary = $CurrentSession.UseBinary
	        $Request.UsePassive = $CurrentSession.UsePassive
	        $Request.Method = [System.Net.WebRequestMethods+FTP]::RemoveDirectory
	        "->Remove Directory: $RequestUri"

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