param($ClientId, $ClientSecret, $TenantId)

Write-Host "Getting access token for $clientId"

$webRequest = @{
    Uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    Method = "POST"
    Headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }
    Body = @{
        client_id = $clientId
        grant_type = "client_credentials"
        scope = "499b84ac-1321-427f-aa17-267ca6975798/.default"
        client_secret = $clientSecret
    }
}

Write-Host "Invoking WebRequest '$( $webRequest.Uri )'. " -NoNewline
$statusCode
try
{
    $response = Invoke-WebRequest @webRequest
    # This will only execute if the Invoke-WebRequest is successful.
    $statusCode = $response.StatusCode
}
catch
{
    $statusCode = $_.Exception.Response.StatusCode.value__
}
Write-Host "Invoked."
Write-Host "Response Http Status: $statusCode"
if ($statusCode -ne 200)
{
    throw "WebRequest to '$listRunUri' unsuccessful. Response Status Code: '$listRunUri'."
}
$accessToken = ($response.Content | ConvertFrom-Json).access_token

$accessToken | Set-Clipboard

Write-Host "##vso[task.setvariable variable=AccessToken;]$accessToken"