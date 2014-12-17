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

  Write-host "Waiting for IP to be assigned for $vm_id..."
  $vm = Get-SCVirtualMachine -ID $vm_id
  $ip = $null
  do {
    sleep -s 1
    $ad = Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Ignore
    if ( $ad.IPv4Addresses.count -gt 0 )
    {
      $ip = $ad.IPv4Addresses[0]
    } else {
      $ips = [System.Net.Dns]::GetHostAddresses($vm.ComputerNameString)
      if ( $ips.count -gt 0 )
      {
        $ip = $ips[0].IPAddressToString
      }
    }
    $timeout -= 1
  } while ( $ip -eq $null -and $timeout -gt 0 )
  $ip
}

$ip_address = execute $script_block $vmm_server_address $proxy_server_address

$resultHash = @{
  ip = "$ip_address"
}
$result = ConvertTo-Json $resultHash
Write-Output-Message $result
