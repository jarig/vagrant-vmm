
# get either cached or entered in the prompt credentials
function Get-Creds($server_address, $prompt_message) {
  $temp_folder = $env:temp
  # get creds
  $cred_file = $temp_folder + "\\creds_$server_address.clixml"
  if ( Test-Path $cred_file )
  {
    $credential = Import-CliXml $cred_file
  } else {
    $credential = Get-Credential -Message $prompt_message
    $credential | Export-CliXml $cred_file
  }
  return $credential
}
