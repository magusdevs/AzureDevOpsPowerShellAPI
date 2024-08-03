function New-AzDoBranch {
  <#
.SYNOPSIS
    Creates a new branch in Azure DevOps.
.DESCRIPTION
    Creates a new branch in Azure DevOps.
.EXAMPLE
    $Params = @{
        CollectionUri = "https://dev.azure.com/contoso"
        ProjectName = "Project 1"
        RepoName "Repo 1"
        SourceBranchName "master"
        BranchName "Branch 1"
    }
    New-AzDoBranch -CollectionUri = "https://dev.azure.com/contoso" -PAT = "***" -ProjectName = "Project 1" -RepoName "Repo 1" -SourceBranchName "master" -BranchName "Branch 1"

    This example will list all the repo's contained in 'Project 1'.
.OUTPUTS
    PSObject of the created branch.
.NOTES
#>

  [CmdletBinding(SupportsShouldProcess)]
  param (
    # Collection Uri of the organization
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [ValidateScript({ Validate-CollectionUri -CollectionUri $_ })]
    [string]
    $CollectionUri,

    # Project where the Repos are contained
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $ProjectName,

    # Name of the Repo to get information about
    [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $RepoName,

    # Name of the source branch
    [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $SourceBranchName,

    # Name of the branch to create
    [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $BranchName
  )

  begin {
    Write-Verbose "Starting function: New-AzDoBranch"
  }

  process {
    $Uri = "$CollectionUri/$ProjectName/_apis/git/repositories/$RepoName/push"
    if ($SourceBranchName -match "refs/heads/") { $SourceBranchName } else { $SourceBranchName = "refs/heads/$SourceBranchName" }
    $SourceBranchId = (Get-AzDoBranch -CollectionUri $CollectionUri -ProjectName $ProjectName -RepoName $RepoName -BranchName $SourceBranchName).objectId
    if ($SourceBranchId -eq $null) { throw "Source branch not found" }
    $SourceRepositoryId = (Get-AzDoRepo -CollectionUri $CollectionUri -ProjectName $ProjectName -RepoName $RepoName).RepoId
    if ($SourceRepositoryId -eq $null) { throw "Source repository not found" }
    Write-Host "Source branch id: $SourceBranchId"

    # check if git is installed and if not, install it
    if (-not(Get-Command git -ErrorAction SilentlyContinue)) {
      Write-Host "Git is not installed. Installing git..."
      # Install git depending on the OS, later
    }
    git branch $BranchName $SourceBranchName
    git push origin $BranchName
  }
  end {
    Write-Verbose "Ending function: New-AzDoBranch"
  }
}
