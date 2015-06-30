Param(
  [Parameter(Mandatory=$true)]
  [string]$vm_id,
  [Parameter(Mandatory=$true)]
  [string]$vmm_server_address,
  [string]$proxy_server_address=$null,
  [int]$timeout
)


# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($Dir, "utils\vmm_executor.ps1"))


$script_block = {
  # external vars
  $vm_id  = $using:vm_id
  $timeout  = $using:timeout


  $vm = Get-SCVirtualMachine -ID $vm_id
  $vm = Read-SCVirtualMachine -VM $vm

  Write-host "Waiting for IP to be assigned for $($vm.ComputerNameString) (id: $vm_id)..."
  $ip = $null
  $tries = 0
  do {
    sleep -s 1
    $ad = Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Ignore
    if ( $ad.IPv4Addresses.count -gt 0 )
    {
      $ip = $ad.IPv4Addresses[0]
    } else {
      try {
        $ips = [System.Net.Dns]::GetHostAddresses($vm.ComputerNameString)
        if ( $ips.count -gt 0 )
        {
          $ip = $ips[0].IPAddressToString
        }
      }catch{
      }
    }
    Write-progress -Activity "Trying to get IP from $($vm.ComputerNameString)" -PercentComplete $($tries*100/$timeout) -Status "Try: $tries"
    $tries += 1
  } while ( $ip -eq $null -and $tries -le $timeout )
  #
  return @{
    ip =  $ip;
  }
}

$address_info = execute $script_block $vmm_server_address $proxy_server_address
$address_to_use = $address_info["ip"]

if ( $address_to_use -eq $null )
{
  # ask for manual IP entry if timedout
  Write-host "Couldn't get ip for the VM within given timeout, you can get and specify it manually (or leave blank and vagrant will stop)."
  $ip = Read-Host 'Enter VM IP address:'
}


$resultHash = @{
  address = $address_to_use
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
