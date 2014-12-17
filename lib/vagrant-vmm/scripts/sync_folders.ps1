Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_ip,
  [Parameter(Mandatory=$true)]
  [string]$folders_to_sync # json
)

# Sync flow:
# create fileshare on the remote machine
# get access to fileshare from the current machine
# transfer all required files to the fileshare
# re-copy/move files on remote machine from fileshare to correct folders


# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\manage_credentials.ps1"))


function Get-file-hash($source_path, $delimiter) {
  $source_files = @()
  (Get-ChildItem $source_path -rec | ForEach-Object -Process {
    Get-FileHash -Path $_.FullName -Algorithm MD5 } ) |
    ForEach-Object -Process {
      $source_files += $_.Path.Replace($source_path, "") + $delimiter + $_.Hash
    }
  $source_files
}

function Get-Remote-Session($guest_ip, $username, $password) {
  $secstr = convertto-securestring -AsPlainText -Force -String $password
  $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
  New-PSSession -ComputerName $guest_ip -Credential $cred
}


# New-PSDrive -Name P -PSProvider FileSystem -Root \\Server01\Public
$folders_to_sync = $folders_to_sync | ConvertFrom-Json

foreach ( $h_path in $folders_to_sync )
{
  $guest_path =  $folders_to_sync[$h_path]
  $folder_mapping[$h_path] = $guest_path
}

$resultHash = $folder_mapping

$result = ConvertTo-Json $resultHash
Write-Output-Message $result
