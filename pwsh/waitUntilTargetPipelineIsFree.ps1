param(
    $accessToken,
    $organisation,
    $project,
    $pipelineId
)

function Main
{
    $baseUri = "https://dev.azure.com/$organisation/$project/_apis/pipelines"
    $apiVersion = "?api-version=7.1"

    $listRunUri = "$baseUri/$pipelineId/runs$apiVersion"

    $headers = @{
        Authorization = $accessToken
    }

    $listWebRequest = @{
        Uri = $listRunUri
        Method = "GET"
        Headers = $headers
    }

    $isInProgressPipelines = $false
    $numberOfSleeps = 0
    $numberOfSleepsLimit = 5
    do
    {
        $response = Invoke-WebRequest @listWebRequest
        Write-Host "Response Had"
        Write-Host $response
        $runs = ($response.Content | ConvertFrom-Json).value
        Write-Host $runs
        
        $isInProgressPipelines = $false
        foreach ($run in $runs)
        {
            Write-Host $run
            if ($run.state -eq "inProgress")
            {
                $isInProgressPipelines = $true
                $numberOfSleeps = $numberOfSleeps + 1
                Start-Sleep -Second 60
            }
        }
    } while ($isInProgressPipelines -and $numberOfSleeps -le $numberOfSleepsLimit)

    if ($numberOfSleeps -le $numberOfSleepsLimit -and $isInProgressPipelines) {
        throw "Target Pipeline did not finish run before timeout"
    }
}

Main