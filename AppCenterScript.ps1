<#
.DESCRIPTION
    Builds all provided branches. Takes username, app name, access token and an array of branches.

.EXAMPLE
    Build-AllBranches $username $appname $token
#>
function Build-AllBranches {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0,mandatory=$true)]
        [string] $user,
        [Parameter(Position=1,mandatory=$true)]
        [string] $app,
        [Parameter(Position=2,mandatory=$true)]
        [string] $token
    )

    # Get all branches
    try {
        $branches = ((Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/branches" -Method Get -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"}) | Select-Object branch) | Select-Object -ExpandProperty branch 
    }
    catch {
        Write-Warning "Could not get branches for application $app"
        return 
    }

    $builds = @()
    $branches | % {  
        $name = $_.name
        try {
            $build = Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/branches/$name/builds" -Method Post -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"}
        }
        catch {
            Write-Warning "Could not build branch $name"
            continue
        }
        $builds += $build
    }
    return $builds
}

<#
.DESCRIPTION
    Gets details for provided builds. Takes username, app name, access token and an array of builds.

.EXAMPLE
    Get-AllBuildsDetails $username $appname $token $builds
#>
 function Get-AllBuildsDetails {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0,mandatory=$true)]
        [string] $user,
        [Parameter(Position=1,mandatory=$true)]
        [string] $app,
        [Parameter(Position=2,mandatory=$true)]
        [string] $token,
        [Parameter(Position=3,mandatory=$true)]
        [Object[]] $builds
    )

    $details = @()
    $builds | % {
        $buildId = $_.id
        $branchName = $_.branchName
    
        # Repeat until the build is not completed
        do {
            
            try {
                $buildDetails = Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/builds/$buildId" -Method Get -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"};
            }
            catch {
                Write-Warning "Could not get build of branch $branchName with id $buildId"
                break;
            }
            if ($buildDetails.status -ne "completed") { 
                # Wait 80 sec before calling the api again
                Start-Sleep -Seconds 80 
            } else {
                # Build is completed
                break
            }
        } While ($true)
        $details += $buildDetails
    }

    return $details
}

$user = Read-Host -Prompt 'Input your user name'
$app = Read-Host -Prompt 'Input your app name'
$token = Read-Host -Prompt 'Input your token'

# Build all branches
$builds = Build-AllBranches $user $app $token

# Get builds details
$details = Get-AllBuildsDetails $user $app $token $builds

# Preapare output data
$output = @()
for ($i = 0; $i -lt $details.Length; $i++)
{
    $buildId = $details[$i].id
    $branchName = $details[$i].sourceBranch
    $obj = new-object psobject -Property @{
                   BranchName =  $branchName
                   BuildStatus = $details[$i].result
                   BuildDurationInMinutes  = ([datetime]$details[$i].finishTime - [datetime]$details[$i].startTime).TotalMinutes
                   LinkToLogs  = "https://appcenter.ms/users/$user/apps/$app/build/branches/$branchName/builds/$buildId"
               }
    $output += $obj
}

# Output: Branch Name | Build status | Duration | Link to build logs
$output | Format-Table @{ Label = "Branch Name"; Expression={ $_.BranchName}},
                @{ Label = "Build Status"; Expression={ $_.BuildStatus}}, 
                @{ Label = "Duration"; Expression={ $_.BuildDurationInMinutes}},
                @{ Label = "Link to build logs"; Expression={ $_.LinkToLogs}}  