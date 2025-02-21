param(
    $accessToken,
    $organisation,
    $project,
    $pipelineId
)

. $(Join-Path $PSScriptRoot "Shared-Cmdlets.ps1")

function Main
{
    $baseUri = "https://dev.azure.com/$organisation/$project/_apis/pipelines"
    $apiVersion = "?api-version=7.1"

    $listRunUri = "$baseUri/$pipelineId/runs$apiVersion"

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    $webRequest = @{
        Uri = $listRunUri
        Method = "GET"
        Headers = $headers
    }

    $isInProgressPipelines = $false
    $numberOfSleeps = 0
    $numberOfSleepsLimit = 5
    do
    {
        Write-Host "Invoking WebRequest '$listRunUri'"
        try
        {
            $response = Invoke-WebRequest @webRequest
            # This will only execute if the Invoke-WebRequest is successful.
            $statusCode = $response.StatusCode
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        Write-Host "Invoked." -NoNewline
        Write-Host "Response Http Status: $statusCode"
        if ($statusCode -ne 200) {
            throw "WebRequest to '$listRunUri' unsuccessful. Response Status Code: '$listRunUri'."
        }
        
        $runs = ($response.Content | ConvertFrom-Json).value
        
        $isInProgressPipelines = $false
        foreach ($run in $runs)
        {
            if ($run.state -eq "inProgress")
            {
                $isInProgressPipelines = $true
                $numberOfSleeps = $numberOfSleeps + 1
                Write-Host "Pipeline is still running, time to nap"
                Start-Sleep -Second 30
            }
        }
    } while ($isInProgressPipelines -and $numberOfSleeps -le $numberOfSleepsLimit)

    if ($isInProgressPipelines) {
        throw "Target Pipeline did not finish run before timeout"
    }
}

Main