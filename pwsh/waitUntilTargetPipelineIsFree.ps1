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
        $runs = ($response.Content | ConvertFrom-Json).value
        
        $isInProgressPipelines = $false
        foreach ($run in $runs)
        {
            if ($run.state -eq "inProgress")
            {
                $isInProgressPipelines = $true
                $numberOfSleeps = $numberOfSleeps + 1
                Start-Sleep -Seconds 60
            }
        }
    } while ($isInProgressPipelines -and $numberOfSleeps -le $numberOfSleepsLimit)

    if ($numberOfSleeps -le $numberOfSleepsLimit) {
        throw "Target Pipeline did not finish run before timeout"
    }
}

Main