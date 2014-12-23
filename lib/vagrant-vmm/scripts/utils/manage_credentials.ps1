
# get either cached or entered in the prompt credentials
function Get-Creds($server_address, $prompt_message, $username = $null, $password = $null )
{
  $temp_folder = $env:temp
  # get creds
  $cred_file = $temp_folder + "\creds_$server_address.clixml"
  if ( Test-Path $cred_file )
  {
    $credential = Import-CliXml $cred_file
  } else
  {
    if ( $username -ne $null -and $password -ne $null )
    {
      # creds passed, use them
      $password = ConvertTo-SecureString -string $password -asPlainText -force
      $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    } else
    {
      $credential = Get-Credential -Message $prompt_message
    }
    $credential | Export-CliXml $cred_file
    Write-host "Credentials for $server_address is cached in $cred_file"
  }
  return $credential
}
