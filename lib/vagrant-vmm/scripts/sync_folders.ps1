#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
# part of code taken from:
# https://github.com/MSOpenTech/vagrant-windows-hyperv/blob/master/lib/vagrant-windows-hyperv/scripts/file_sync.ps1

Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_address,
  [Parameter(Mandatory=$true)]
  [string]$folders_to_sync,
  [string]$winrm_vm_username,
  [string]$winrm_vm_password
)
# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\manage_credentials.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\manage_trusted_hosts.ps1"))

# Sync flow:
# get list of files to sync, compare hashes with the remote ones
# create fileshare on the remote machine
# get access to fileshare from the current machine
# transfer all required files to the fileshare
# re-copy/move files on remote machine from fileshare to correct folders


# convert from json to ps object
$folders_to_sync_obj = ConvertFrom-Json $folders_to_sync
$delimiter = " || "
$creds_to_vm = Get-Creds $vm_address "Credentials for access to the VM ($vm_address) via WinRM" $winrm_vm_username $winrm_vm_password

# add to trusted hosts
Add-To-Trusted $vm_address


function Get-file-hash($source_paths, $delimiter) {
  $source_files = @{}
  Write-host "$(&hostname) :: Collecting file hashes..."

  foreach ( $source_path in $source_paths )
  {
    $source_files[$source_path] = @()
    # convert unix style to windows
    $source_path_normalized = [System.IO.Path]::GetFullPath($source_path)
    if ( Test-path $source_path_normalized )
    {
      (Get-ChildItem $source_path_normalized -rec | ForEach-Object -Process {
          Get-FileHash -Path $_.FullName -Algorithm MD5
        }
      ) | ForEach-Object -Process {
          $source_files[$source_path] += $_.Path.Replace($source_path_normalized, "") + $delimiter + $_.Hash
      }
      # get empty dirs, set hash to be 0 for them
      Get-ChildItem $source_path_normalized -recurse |
        Where-Object {$_.PSIsContainer -eq $True} |
          Where-Object {$_.GetFiles().Count -eq 0} |
            Select-Object FullName | ForEach-Object -Process {
              $source_files[$source_path] += $_.FullName.Replace($source_path_normalized, "") + $delimiter + "0"
            }
    }
  }
  return $source_files
}

function Get-remote-file-hash($source_paths, $delimiter, $session) {
  return Invoke-Command -Session $session -ScriptBlock ${function:Get-file-hash} -ArgumentList $source_paths, $delimiter
}

function Get-session {
  $session = $script:session
  if ( !$session -or $session.State.ToString() -ne "Opened" )
  {
    $auth_method = "default"
    if ( !$creds_to_vm.UserName.contains("\") -and !$creds_to_vm.UserName.contains("@") )
    {
      $auth_method = "basic"
    }
    $session = New-PSSession -ComputerName $vm_address -Credential $creds_to_vm -Authentication $auth_method
    $script:session = $session
  }
  return $script:session
}

# Compare source and destination files
$remove_files = @{}
$copy_files = @{}
$folder_mappings = @{}
foreach ( $hst_path in $folders_to_sync_obj.psobject.properties.Name )
{
  $guest_path =  $folders_to_sync_obj.$hst_path
  $folder_mappings[$hst_path] = $guest_path
  $copy_files[$hst_path] = @()
  $remove_files[$guest_path] = @()
}

$source_files = Get-file-hash $folder_mappings.Keys $delimiter
$destination_files = Get-remote-file-hash $folder_mappings.Values $delimiter $(Get-session)
if (!$destination_files) {
  $destination_files = @{}
}

$sync_required = $false
# compare hashes and derive what should be copied over and what removed
foreach ( $hst_path in $folder_mappings.Keys )
{
  $guest_path = $folder_mappings[$hst_path]
  Write-host "Comparing hashes $hst_path <=> $guest_path"
  if ( !$destination_files[$guest_path] ) {
    $destination_files[$guest_path] = @()
  }

  Compare-Object -ReferenceObject $source_files[$hst_path] -DifferenceObject $destination_files[$guest_path] | ForEach-Object {
    $obj_path = $_.InputObject.Split($delimiter)[0]
    if ($obj_path -and $obj_path.Trim())
    {
      # if not empty
      if ($_.SideIndicator -eq '=>') {
        $remove_files[$guest_path] += $obj_path
      } else {
        $copy_files[$hst_path] += $obj_path
      }
      $sync_required = $true
    }
  }
}

if ( $sync_required )
{
  # create file share on the remote machine
  Invoke-Command -Session $(Get-session) -ScriptBlock {
    $fileshare_dest = "$($env:SystemDrive)\vagrant-sync"
    if (Test-path $fileshare_dest)
    {
      Remove-item "$fileshare_dest\*" -recurse -force
    } else {
      $sync_dir = New-item $fileshare_dest -itemtype directory
    }
    $shr = Get-SmbShare -Name "vagrant-sync" -ErrorAction Ignore
    if ( $shr -eq $null )
    {
      Write-host "$(&hostname) :: Creating fileshare on the remote host in $fileshare_dest, granting access to Everyone"
      $shr = New-SmbShare -Name "vagrant-sync" -Temporary -Path $fileshare_dest
    }
    $g_info = Grant-SmbShareAccess -InputObject $shr -AccountName "$($env:USERDOMAIN)\$($env:USERNAME)" -AccessRight Full -Force
  }

  # get access to the fileshare from the current machine
  Write-host "Getting access from the current machine to the created fileshare (\\$vm_address\vagrant-sync)"
  $vagrant_sync_drive = New-PSDrive -Name 'V' -PSProvider 'FileSystem' -Root "\\$vm_address\vagrant-sync" -Credential $creds_to_vm

  Write-host "Syncing files to fileshare..."
  foreach ( $hst_path in $copy_files.Keys )
  {
    $current = 0
    $total = $copy_files[$hst_path].Count
    # copy files to the fileshare
    foreach( $file in $copy_files[$hst_path] )
    {
      $current += 1
      $file_path = $hst_path + $file
      $guest_path = $folder_mappings[$hst_path]
      $guest_path = [System.IO.Path]::GetFullPath("$($vagrant_sync_drive.root)\$guest_path")
      Write-progress -Activity "Syncing $hst_path with $guest_path" -PercentComplete $($current*100/$total) -Status "Copying $file"
      if (Test-Path $file_path -pathtype container)
      {
        # folder
        $out = New-Item $file_path -itemtype directory -ErrorAction Ignore
      } else {
        # file
        $file_dir = split-path $file
        $out = New-item "$guest_path\$file_dir" -itemtype directory -ErrorAction Ignore
        Copy-Item $file_path "$guest_path\$file" -recurse
      }
    }
  }

  # copy from fileshare to the dest locations on the remote machine
  # as well as remove files that shouldn't be there
  Invoke-Command -Session $(Get-session) -ScriptBlock {
    $remove_files = $using:remove_files
    $fileshare_dest = "$($env:SystemDrive)\vagrant-sync"
    write-host "$(&hostname) :: Distributing files from $fileshare_dest..."
    # remove files
    $total = $remove_files.Keys.Count
    $current = 0
    foreach ( $g_path in $remove_files.Keys )
    {
      $current += 1
      Write-progress -Activity "Cleaning redundant files" -PercentComplete $($current*100/$total) -Status "Cleaning under: $g_path"
      foreach ($r_file in $remove_files[$g_path])
      {
        Remove-Item $($g_path+$r_file) -recurse -force -ErrorAction Ignore
      }
    }
    $root_files_in_share = Get-ChildItem $fileshare_dest -Directory -ErrorAction Ignore
    $total = $root_files_in_share.Count
    $current = 0
    #TODO: remove hard-code to SystemDrive
    foreach ( $guest_path in $root_files_in_share )
    {
      $current += 1
      Write-progress -Activity "Distributing files on the remote machine" -PercentComplete $($current*100/$total) -Status "Copying: $guest_path"
      Copy-Item "$fileshare_dest\$guest_path" "$($env:SystemDrive)\" -recurse -force
    }
  }
} else # if there are something to copy or remove
{
  Write-host "Skipping sync as there are nothing to sync."
}

# close session
Remove-PSSession -Id $session.Id

# remove vm_address from trusted hosts
Remove-From-Trusted $vm_address


$resultHash = $folder_mappings
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
