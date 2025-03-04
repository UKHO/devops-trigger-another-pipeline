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
    $apiVersion = "?api-version=7.2-preview.1"

    $runPipelineUri = "$baseUri/$pipelineId/runs$apiVersion"

    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }

    $body = @{
        resources = @{
            repositories = @{
                self = @{
                    refName = "refs/heads/main"
                }
            }
        }
    } | ConvertTo-Json -Depth 5

    $runPipelineWebRequest = @{
        Uri = $runPipelineUri
        Method = "POST"
        Headers = $headers
        Body = $body
    }

    $isInProgressPipelines = $false
    $numberOfSleeps = 0
    $numberOfSleepsLimit = 5
    $response = Invoke-WebRequest @runPipelineWebRequest
    Write-Host "Trigger other pipeline"
    $run = ($response.Content | ConvertFrom-Json).value
    $runId = $run.id

    $baseUri = "https://dev.azure.com/$organisation/$project/_apis/pipelines"
    $apiVersion = "?api-version=7.1"

    $getRunUri = "$baseUri/$pipelineId/runs/$runId$apiVersion"

    $headers = @{
        Authorization = $accessToken
    }

    $getWebRequest = @{
        Uri = $getRunUri
        Method = "GET"
        Headers = $headers
    }

    $isInProgressPipelines = $false
    $numberOfSleeps = 0
    $numberOfSleepsLimit = 5
    $runResult = ""
    do
    {
        Write-Host "Getting status of the pipeline"
        $response = Invoke-WebRequest @getWebRequest
        $run = ($response.Content | ConvertFrom-Json).value
        $isInProgressPipelines = $false

        if ($run.state -eq "inProgress")
        {
            $isInProgressPipelines = $true
            $numberOfSleeps = $numberOfSleeps + 1
            Write-Host "Pipeline still running, nap time"
            Start-Sleep -Seconds 30
        }
        else
        {
            $runResult = $run.result
        }
    } while ($isInProgressPipelines -and $numberOfSleeps -le $numberOfSleepsLimit)

    if ($numberOfSleeps -le $numberOfSleepsLimit -and $isInProgressPipelines)
    {
        throw "Triggered pipeline did not finish run before timeout"
    }

    if ($runResult -eq "succeeded")
    {
        return
    }
    throw "Target Pipeline did not have a succeeded run state"
}

Main