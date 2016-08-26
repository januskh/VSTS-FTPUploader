Function Get-FTPChildItem
{
	<#
	.SYNOPSIS
		Gets the item and child items from ftp location.

	.DESCRIPTION
		The Get-FTPChildItem cmdlet gets the items from ftp locations. If the item is a container, it gets the items inside the container, known as child items. 
		
	.PARAMETER Path
		Specifies a path to ftp location or file. 
			
	.PARAMETER Session
		Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Recurse
		Get recurse child items.

	.PARAMETER Depth
		Define depth of  folder in recurse mode. Autoenable recurse mode.

	.PARAMETER Filter
		Specifies a filter parameter to return only this objects that have proper name. This parameter allow to use of wildcards. Defalut value is *.	
		
	.EXAMPLE
		PS P:\> Get-FTPChildItem -path ftp://ftp.contoso.com/folder


		   Parent: ftp://ftp.contoso.com/folder

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 3   ftp    ftp           2012-06-19 12:58:00 subfolder1
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder2
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt

	.EXAMPLE
		PS P:\> Get-FTPChildItem -path ftp://ftp.contoso.com/folder -Filter "subfolder*"


		   Parent: ftp://ftp.contoso.com/folder

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 3   ftp    ftp           2012-06-19 12:58:00 subfolder1
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder2	

	.EXAMPLE
		PS P:\> Get-FTPChildItem -path folder -Recurse


		   Parent: ftp://ftp.contoso.com/folder

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 3   ftp    ftp           2012-06-19 12:58:00 subfolder1
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder2
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt


		   Parent: ftp://ftp.contoso.com/folder/subfolder1

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder11
		-   rw-r--r-- 1   ftp    ftp    21KB   2012-06-19 09:20:00 test.xlsx
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip


		   Parent: ftp://ftp.contoso.com/folder/subfolder1/subfolder11

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip


		   Parent: ftp://ftp.contoso.com/folder/subfolder2

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip

	.EXAMPLE
		PS P:\> $ftpFile = Get-FTPChildItem -path /folder/subfolder1/test.xlsx
		PS P:\> $ftpFile | Select-Object Parent, Name, ModifiedDate

		Parent                                  Name                                    ModifiedDate
		------                                  ----                                    ------------
		ftp://ftp.contoso.com/folder/subfolder1 test.xlsx                               2012-06-19 09:20:00
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
		Set-FTPConnection
	#>	 

	[OutputType('PSFTP.Item')]
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low"
	)]
	Param(
		[parameter(ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[String]$Path = "",
		$Session = "DefaultFTPSession",
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$Recurse,	
		[Int]$Depth = 0,		
		[String]$Filter = "*"
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
			Write-Verbose "Use original path: $RequestUri"
			
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path
			Write-Verbose "Add ftp:// at start: $RequestUri"
		}
		$RequestUri = [regex]::Replace($RequestUri, '/$', '')
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		Write-Verbose "Remove additonal slash: $RequestUri"

		if($Depth -gt 0)
		{
			$CurrentDepth = [regex]::matches($RequestUri,"/").count
			if((Get-Variable -Scope Script -Name MaxDepth -ErrorAction SilentlyContinue) -eq $null)
			{
				New-Variable -Scope Script -Name MaxDepth -Value ([Int]$CurrentDepth +$Depth)
			}
		
			Write-Verbose "Auto enable recurse mode. Current depth / Max Depth: $CurrentDepth / $($Script:MaxDepth)"
			$Recurse = $true
		}

		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get child items from ftp location")) 
		{	
			if((Get-FTPItemSize $RequestUri -Session $Session -Silent) -eq -1)
			{
				Write-Verbose "Path is directory"
				$ParentPath = $RequestUri
			}
			else
			{
				Write-Verbose "Path is file. Delete last file name to get parent path."
				$LastIndex = $RequestUri.LastIndexOf("/")
				$ParentPath = $RequestUri.SubString(0,$LastIndex)
			}
						
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
			$Request.Credentials = $CurrentSession.Credentials
			$Request.EnableSsl = $CurrentSession.EnableSsl
			$Request.KeepAlive = $CurrentSession.KeepAlive
			$Request.UseBinary = $CurrentSession.UseBinary
			$Request.UsePassive = $CurrentSession.UsePassive
			
			$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
			Write-Verbose "Use WebRequestMethods: $($Request.Method)"
			Try
			{
				$mode = "Unknown"
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
				$Response = $Request.GetResponse()
				
				[System.IO.StreamReader]$Stream = New-Object System.IO.StreamReader($Response.GetResponseStream(),[System.Text.Encoding]::Default)

				$DirList = @()
				$ItemsCollection = @()
				Try
				{
					[string]$Line = $Stream.ReadLine()
					Write-Debug "Read Line: $Line"
				}
				Catch
				{
					$Line = $null
					Write-Debug "Line is null"
				}
				
				While ($Line)
				{
					if($mode -eq "Compatible" -or $mode -eq "Unknown")
					{
						$null, [string]$IsDirectory, [string]$Flag, [string]$Link, [string]$UserName, [string]$GroupName, [string]$Size, [string]$Date, [string]$Name = `
						[regex]::split($Line,'^([d-])([rwxt-]{9})\s+(\d{1,})\s+([.@A-Za-z0-9-]+)\s+([A-Za-z0-9-]+)\s+(\d{1,})\s+(\w+\s+\d{1,2}\s+\d{1,2}:?\d{2})\s+(.+?)\s?$',"SingleLine,IgnoreCase,IgnorePatternWhitespace")

						if($IsDirectory -eq "" -and $mode -eq "Unknown")
						{
							$mode = "IIS6"
						}
						elseif($mode -ne "Compatible")
						{
							$mode = "Compatible" #IIS7/Linux
						}
						
						if($mode -eq "Compatible")
						{
							$DatePart = $Date -split "\s+"
							$NewDateString = "$($DatePart[0]) $('{0:D2}' -f [int]$DatePart[1]) $($DatePart[2])"
							
							Try
							{
								if($DatePart[2] -match ":")
								{
									$Month = ([DateTime]::ParseExact($DatePart[0],"MMM",[System.Globalization.CultureInfo]::InvariantCulture)).Month
									if((Get-Date).Month -ge $Month)
									{
										$NewDate = [DateTime]::ParseExact($NewDateString,"MMM dd HH:mm",[System.Globalization.CultureInfo]::InvariantCulture)
									}
									else
									{
										$NewDate = ([DateTime]::ParseExact($NewDateString,"MMM dd HH:mm",[System.Globalization.CultureInfo]::InvariantCulture)).AddYears(-1)
									}
								}
								else
								{
									$NewDate = [DateTime]::ParseExact($NewDateString,"MMM dd yyyy",[System.Globalization.CultureInfo]::InvariantCulture)
								}
							}
							Catch
							{
								Write-Verbose "Can't parse date: $Date"
							}							
						}
					}
					
					if($mode -eq "IIS6")
					{
						$null, [string]$NewDate, [string]$IsDirectory, [string]$Size, [string]$Name = `
						[regex]::split($Line,'^(\d{2}-\d{2}-\d{2}\s+\d{2}:\d{2}[AP]M)\s+<*([DIR]*)>*\s+(\d*)\s+(.+).*$',"SingleLine,IgnoreCase")
						
						if($IsDirectory -eq "")
						{
							$IsDirectory = "-"
						}
					}
					
					Switch($Size)
					{
						{[int64]$_ -lt 1024} { $HFSize = $_+"B"; break }
						{[System.Math]::Round([int64]$_/1KB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1KB,0))+"KB"; break }
						{[System.Math]::Round([int64]$_/1MB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1MB,0))+"MB"; break }
						{[System.Math]::Round([int64]$_/1GB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1GB,0))+"GB"; break }
						{[System.Math]::Round([int64]$_/1TB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1TB,0))+"TB"; break }
						{[System.Math]::Round([int64]$_/1PB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1PB,0))+"PB"; break }
					} 
					
					if($IsDirectory -eq "d" -or $IsDirectory -eq "DIR")
					{
						$HFSize = ""
					}
					
					if($ParentPath -match "\*|\?")
					{
						$LastIndex = $ParentPath.LastIndexOf("/")
						$ParentPath = $ParentPath.SubString(0,$LastIndex)
						$ParentPath.Trim() + "/" + $Name.Trim()
					}
					
					$LineObj = New-Object PSObject -Property @{
						Dir = $IsDirectory
						Right = $Flag
						Ln = $Link
						User = $UserName
						Group = $GroupName
						Size = $HFSize
						SizeInByte = $Size
						OrgModifiedDate = $Date
						ModifiedDate = $NewDate
						Name = $Name.Trim()
						FullName = $ParentPath.Trim() + "/" + $Name.Trim()
						Parent = $ParentPath.Trim()
					}
					
					$LineObj.PSTypeNames.Clear()
					$LineObj.PSTypeNames.Add('PSFTP.Item')
			
					if($Recurse -and ($LineObj.Dir -eq "d" -or $LineObj.Dir -eq "DIR"))
					{
						$DirList += $LineObj
					}
					
					
					if($LineObj.Dir)
					{
						if($LineObj.Name -like $Filter)
						{
							Write-Debug "Filter accepted: $Filter"
							$ItemsCollection += $LineObj
						}
					}
					$Line = $Stream.ReadLine()
					Write-Debug "Read Line: $Line"
				}
				
				$Response.Close()
				
				if($Recurse -and ($CurrentDepth -lt $Script:MaxDepth -or $Depth -eq 0))
				{
					$RecurseResult = @()
					$DirList | ForEach-Object {
						Write-Debug "Recurse is active and go to: $($_.FullName)"
						$RecurseResult += Get-FTPChildItem -Path ($_.FullName) -Session $Session -Recurse -Filter $Filter -Depth $Depth
						
					}	

					$ItemsCollection += $RecurseResult
				}	
				
				if($ItemsCollection.count -eq 0)
				{
					Return 
				}
				else
				{
					Return $ItemsCollection | Sort-Object -Property @{Expression="Parent";Descending=$false}, @{Expression="Dir";Descending=$true}, @{Expression="Name";Descending=$false} 
				}
			}
			Catch
			{
				Write-Error $_.Exception.Message -ErrorAction Stop 
			}
		}
		
		if($CurrentDepth -ge $Script:MaxDepth)
		{
			Remove-Variable -Scope Script -Name CurrentDepth 
		}		
	}
	
	End{}
}