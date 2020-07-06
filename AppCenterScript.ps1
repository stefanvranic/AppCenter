<#
.DESCRIPTION
    Builds all provided branches. Takes username, app name, access token and an array of branches.

.EXAMPLE
    Build-AllBranches $username $appname $builds
#>
function Build-AllBranches {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0,mandatory=$true)]
        [string] $user,
        [Parameter(Position=1,mandatory=$true)]
        [string] $app,
        [Parameter(Position=2,mandatory=$true)]
        [string] $token,
        [Parameter(Position=3,mandatory=$true)]
        [Object[]] $branches
        
    )

    $builds = @()
    $branches | % {  
        $name = $_.name
        $builds += Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/branches/$name/builds" -Method Post -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"}
    }
    return $builds
}

<#
.DESCRIPTION
    Gets details for provided builds. Takes username, app name, access token and an array of builds.

.EXAMPLE
    Get-AllBuildsDetails $username $appname $builds
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
    
        # Repeat until the build is not completed
        do {
            $buildDetails = Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/builds/$buildId" -Method Get -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"};
    
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

# Get all branches
$branches = ((Invoke-RestMethod -Uri "https://api.appcenter.ms/v0.1/apps/$user/$app/branches" -Method Get -Headers @{"Accept"="application/json"; "X-API-Token"="$($token)"; "Content-Type"="application/json"}) | Select-Object branch) | Select-Object -ExpandProperty branch 

# Build all branches
$builds = Build-AllBranches $user $app $token $branches

# Get builds details
$details = Get-AllBuildsDetails $user $app $token $builds

# Preapare output data
$output = @()
for ($i = 0; $i -lt $branches.Length; $i++)
{
    $buildId = $details[$i].id
    $obj = new-object psobject -Property @{
                   BranchName =  $details[$i].sourceBranch
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