Param(
# Make Sure We Get Our Params
#  [parameter(Mandatory=$True)]
  [String]$server,
#  [parameter(Mandatory=$True)]
  [String]$user,
#  [parameter(Mandatory=$True)]
  [String]$pass
)
if(([string]::IsNullOrEmpty($server)) -or ([string]::IsNullOrEmpty($user)) -or ([string]::IsNullOrEmpty($pass))) {

write-host "Required Parameters Missing!"
Write-Host "Usage: server.example.com username password"
exit
}

Function AuthServer {

    Param($myserver,$myusername,$mypassword)

    $userpass  = $myusername + “:” + $mypassword
    $bytes= [System.Text.Encoding]::UTF8.GetBytes($userpass)
    $encodedlogin=[Convert]::ToBase64String($bytes)
    $authheader = "Basic " + $encodedlogin
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization",$authheader)
    $headers.Add("Accept","application/json")
    $headers.Add("Content-Type","application/json")
    $uri = "https://" + $myserver + ":16000/fmi/admin/api/v2/user/auth"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post

    $json = $response | ConvertTo-Json | ConvertFrom-Json
    return $json.response.token
}
Function DeAuthToken {

    Param($myserver,$token)

    $authheader = "Bearer " + $token
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization",$authheader)
    $headers.Add("Accept","application/json")
    $headers.Add("Content-Type","application/json")
    $uri = "https://" + $myserver + ":16000/fmi/admin/api/v2/user/auth/" + $token
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete

    $json = $response | ConvertTo-Json | ConvertFrom-Json

    return $json.response
}
Function GetDAPIInfo {

    Param($myserver,$token)

    $authheader = "Bearer " + $token
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization",$authheader)
    $headers.Add("Accept","application/json")
    $headers.Add("Content-Type","application/json")
    $uri = "https://" + $myserver + ":16000/fmi/admin/api/v2/fmdapi/config"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

    $json = $response | ConvertTo-Json | ConvertFrom-Json

    return $json
}

Try
{
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $theToken = AuthServer $server $user $pass

    $usage = GetDAPIInfo $server $theToken
    $deAuth = DeAuthToken $server $theToken
    Write-Host $usage.response.fmdapiBandwidthOut
} catch {
    Write-Warning $Error[0]

}
 
