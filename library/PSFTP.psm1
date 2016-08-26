Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }

New-Alias Send-FTPItem Add-FTPItem
New-Alias Receive-FTPItem Get-FTPItem
New-Alias Move-FTPItem Rename-FTPItem

Export-ModuleMember -Function * -Alias *