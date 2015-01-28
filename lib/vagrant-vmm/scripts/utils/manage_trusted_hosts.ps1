
# add $address to trusted host list
function Add-To-Trusted($address)
{
  $trusted_hosts = get-item wsman:\localhost\Client\TrustedHosts
  if ( $address -as [ipaddress] -and !$trusted_hosts.Value.Contains($address) )
  {
    if ($trusted_hosts.Value)
    {
      $new_th_values = "$($trusted_hosts.Value),$address"
    } else {
      $new_th_values = $address
    }
    set-item wsman:\localhost\Client\TrustedHosts $new_th_values -Force
  }
}

# remove $address from trusted host list
function Remove-From-Trusted($address)
{
  # remove $address from trusted hosts
  $trusted_hosts = get-item wsman:\localhost\Client\TrustedHosts
  if ( $trusted_hosts.Value.Contains($address) )
  {
    $new_th_values = $trusted_hosts.Value -replace ",?$address", ""
    set-item wsman:\localhost\Client\TrustedHosts $new_th_values -Force
  }
}
