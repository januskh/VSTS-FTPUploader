Function Add-FTPItem
{
    <#
	.SYNOPSIS
	    Send file to specific ftp location.

	.DESCRIPTION
	    The Add-FTPItem cmdlet send file to specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 		
			
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Overwrite
	    Overwrite item on remote location. 		
	
	.EXAMPLE
		PS> Add-FTPItem -Path "/myfolder" -LocalPath "C:\myFile.txt"

		Dir          : -
		Right        : rw-r--r--
		Ln           : 1
		User         : ftp
		Group        : ftp
		Size         : 82033
		ModifiedDate : Aug 17 12:27
		Name         : myFile.txt
		
	.EXAMPLE
		PS> Add-FTPItem "C:\Folder" | Add-FTPItem

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
        Filename fixes by Janus Kamp Hansen - http://www.kamp-hansen.dk

	.LINK
        Add-FTPItem
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
		[parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[Alias("FullName")]		
		[String]$LocalPath,
        [String]$RemoteFileName,
		[Int]$BufferSize = 9KB,
		[Switch]$Overwrite = $false,
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
		if(Test-Path $LocalPath)
		{
            
            

			$LocalItem = Get-Item $LocalPath
            $ItemName = ($LocalItem).Name

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

            if($LocalItem -is [System.IO.DirectoryInfo])
            {
                if($CurrentSession.StartPath -eq "")
                {
                    $CurrentSession.StartPath =  $LocalItem.Parent.FullName -replace "\\","\\"
                }

                $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
                $StartLocalPath =  $CurrentSession.StartPath
                $PartLocalPath = $LocalPath -replace $StartLocalPath
                $RemotePath = $PartLocalPath -replace "\\","/"
			    $RequestUri = $RequestUri+"/"+$RemotePath
                $RequestUri = $RequestUri -replace $ItemName
			    $RequestUri = [regex]::Replace($RequestUri, '/$', '')
			    $RequestUri = [regex]::Replace($RequestUri, '/+', '/')
			    $RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')

                Try
                {
                    New-FTPItem -Path $RequestUri -Name $ItemName
                }
                Catch
                {
                    Write-Debug "Probably folder $ItemName exist in path $RequestUri"
                }
            }
            else
            {
			    <#$RequestUri = $RequestUri+"/"+$ItemName
			    $RequestUri = [regex]::Replace($RequestUri, '/$', '')
			    $RequestUri = [regex]::Replace($RequestUri, '/+', '/')
			    $RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')#>
                $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
                $StartLocalPath =  $CurrentSession.StartPath
                Write-Debug "StartPath: $StartLocalPath"

                $PartLocalPath = $LocalPath -replace $StartLocalPath
                Write-Debug "PartLocalPath: $PartLocalPath"

                $RemotePath = $PartLocalPath -replace "\\","/"
                Write-Debug "RemotePath: $RemotePath"

			    $RequestUri = $RequestUri+"/"+$RemoteFileName
                Write-Debug "RequestUri: $RequestUri"

			    $RequestUri = [regex]::Replace($RequestUri, '/$', '')
                Write-Debug "RequestUri: $RequestUri"

			    $RequestUri = [regex]::Replace($RequestUri, '/+', '/')
                Write-Debug "RequestUri: $RequestUri"

			    $RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
                Write-Debug "RequestUri: $RequestUri"

			    Write-Debug "Remove additonal slash: $RequestUri"
				
                if ($pscmdlet.ShouldProcess($RequestUri,"Send item: '$LocalPath' in ftp location")) 
			    {	
                    [System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				    $Request.Credentials = $CurrentSession.Credentials
				    $Request.EnableSsl = $CurrentSession.EnableSsl
				    $Request.KeepAlive = $CurrentSession.KeepAlive
				    $Request.UseBinary = $CurrentSession.UseBinary
				    $Request.UsePassive = $CurrentSession.UsePassive

				    Try
				    {

					    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					
					    $SendFlag = 1

					    if($Overwrite -eq $false)
					    {
						    $FileSize = Get-FTPItemSize -Path $RequestUri -Session $Session -Silent
                            if($FileSize -gt 0)
						    {
							    $FileSize = Get-FTPItemSize -Path $RequestUri -Session $Session -Silent
							
							    $Title = "A File name: $ItemName already exists in this location."
							    $Message = "What do you want to do?"

							    $ChoiceOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
							    $ChoiceCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
							    if($FileSize -lt (Get-Item -Path $LocalPath).Length)
							    {
								    $ChoiceResume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
								    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite, $ChoiceResume)
								    $SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
							    }
							    else
							    {
								    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite)
								    $SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1) 
							    }	
						    }
					    }
			
					    if($SendFlag -eq 2)
					    {
						    $Request.Method = [System.Net.WebRequestMethods+FTP]::AppendFile
					    }
					    else
					    {
						    $Request.Method = [System.Net.WebRequestMethods+FTP]::UploadFile
					    }
					    Write-Debug "Use WebRequestMethods: $($Request.Method)"
					
					    if($SendFlag)
					    {
						    $File = [IO.File]::OpenRead( (Convert-Path $LocalPath) )
						    Write-Debug "Open File: $LocalPath"
						
	           			    $Response = $Request.GetRequestStream()
            			    [Byte[]]$Buffer = New-Object Byte[] $BufferSize
						
						    $ReadedData = 0
						    $AllReadedData = 0
						    $TotalData = (Get-Item $LocalPath).Length
						
						    if($SendFlag -eq 2)
						    {
							    $SeekOrigin = [System.IO.SeekOrigin]::Begin
							    $File.Seek($FileSize,$SeekOrigin) | Out-Null
							    $AllReadedData = $FileSize
						    }
						
						    if($TotalData -eq 0)
						    {
							    $TotalData = 1
						    }
						
					        Do {
               				    $ReadedData = $File.Read($Buffer, 0, $Buffer.Length)
               				    $AllReadedData += $ReadedData
               				    $Response.Write($Buffer, 0, $ReadedData);
               				    Write-Progress -Activity "Upload File: $Path/$ItemName" -Status "Uploading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
            			    } While($ReadedData -gt 0)
			
			                $File.Close()
            			    $Response.Close()
						    Write-Debug "Close File: $LocalPath"
						
						    Return #Get-FTPChildItem -Path $RequestUri -Session $Session
					    }
					
				    }
				    Catch
				    {
					    Write-Error $_.Exception.Message -ErrorAction Stop 
				    }
			    }
            }
		}
		else
		{
			Write-Error "Cannot find local path '$LocalPath' because it does not exist." -ErrorAction Stop 
		}
	}
	
	End
    {
        $CurrentSession.StartPath = ""
    }				
}