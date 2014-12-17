Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_name,
  [Parameter(Mandatory=$true)]
  [string]$vmm_server_address,
  [Parameter(Mandatory=$true)]
  [string]$vm_template_name,
  [Parameter(Mandatory=$true)]
  [string]$vm_host_group_name,
  [string]$proxy_server_address=$null
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\vmm_executor.ps1"))


$script_block = {
  # external vars
  $vm_name            = $using:vm_name
  $vm_host_group_name = $using:vm_host_group_name
  $vmm_credential     = $using:vmm_credential
  $server_address     = $using:vmm_server_address
  $vm_template_name   = $using:vm_template_name

  $description = "VM created by vagrant for testing purposes"
  $MinFreeSpaceGB = 300 #

  # get VM Template object
  $VMTemplate = Get-SCVMTemplate -Name $vm_template_name
  # get host group
  $VMHostGroup = Get-VMHostGroup -Name $vm_host_group_name
  #
  Write-Host "Creating VM from template $vm_template_name"

  $tries = 10
  while ( $tries -gt 0 ) {
    $vm = Get-SCVirtualMachine -Name $vm_name
    if ( $vm -eq $null ) {
      break
    } else {
      $vm_name = $vm_name.substring(0, [math]::Min(14, $vm_name.length)) + $(Get-Random -Minimum 0 -Maximum 10)
    }
    $tries -= 1
  }
  if ( $vm -eq $null )
  {
      # Get and sort the host ratings for all the hosts in the host group.
      # select host which has rating > 0
      $hRatingHashParams = @{Template=$VMTemplate;
                             DiskSpaceGB=$MinFreeSpaceGB;
                             VMName=$vm_name;
                             VMHostGroup=$VMHostGroup;
                             VMMServer=$vmmServer
                            }

      $VMHost = $null
      $HostRatings = @(Get-VMHostRating @hRatingHashParams | Sort-Object -property Rating -descending)
      If($HostRatings.Count -eq 0) { throw "No hosts meet the requirements." }
      $VMHost = $HostRatings[0].VMHost

      # If there is at least one host that will support the virtual machine, create the virtual machine on the highest-rated host.
      If ($VMHost -ne $null )
      {
        # get placement path
        $path = $($VMHost.DiskVolumes | where { $_.IsAvailableForPlacement -eq $True } | Sort-Object -Property FreeSpace -Descending)[0]
        Write-Host "----- Creating VM ----"
        Write-Host "Host: $VMHost, $($VMHost.CPUManufacturer) $($VMHost.Rank)"
        Write-host "Placement path: $($path.Name), Free space - $($path.FreeSpace/1024/1024/1024) GB"
        Write-Host "Name: $vm_name"
        Write-Host "----- ----------- ----"
        # Create the virtual machine.
        $vmCreateParams = @{Name=$vm_name;
                            Path=$path.Name;
                            VMHost = $VMHost;
                            VMTemplate=$VMTemplate;
                            Description=$description;
                            ComputerName=$vm_name;
                            BlockDynamicOptimization=$false;
                            ReturnImmediately = $false; AnswerFile = $null;
                            StartAction = "NeverAutoTurnOnVM";
                            StopAction = "TurnOffVM";
                            StartVM=$false;
                            ErrorAction="stop";
                            DelayStartSeconds = $(Get-Random -Minimum 20 -Maximum 100)
                          }

      New-SCVirtualMachine @vmCreateParams
    } else {
      Write-Error "Cannot find suitable host for the VM."
    }
  } else {
    Write-Warning "Machine $vm_name already exists on host $($vm.VMHost.Name)"
    $vm
  }
}

$vm = execute $script_block $vmm_server_address $proxy_server_address

$resultHash = @{
  name = $vm.Name
  id = $vm.id.guid
}

$result = ConvertTo-Json $resultHash
Write-Output-Message $result
