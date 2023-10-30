function Set-AzDoBranchPolicyMergeStrategy {
  <#
.SYNOPSIS
    Creates a Merge strategy policy on a branch
.DESCRIPTION
    Creates a Merge strategy policy on a branch
.EXAMPLE
    $params = @{
        CollectionUri = "https://dev.azure.com/contoso"
        PAT = "***"
        RepoName = "Repo 1"
        ProjectName = "Project 1"
    }
    Set-AzDoBranchPolicyMergeStrategy @params

    This example creates a 'Require a merge strategy' policy with splatting parameters

.EXAMPLE
    'repo1', 'repo2' |
    Set-AzDoBranchPolicyMergeStrategy -CollectionUri "https://dev.azure.com/contoso" -ProjectName "Project 1" -PAT "***"

    This example creates a 'Require a merge strategy' policy on the main branch of repo1 and repo2

.OUTPUTS
    [PSCustomObject]@{
      CollectionUri      = $CollectionUri
      ProjectName        = $ProjectName
      RepoName           = $RepoName
      id                 = $res.id
      allowSquash        = $res.settings.allowSquash
      allowNoFastForward = $res.settings.allowNoFastForward
      allowRebase        = $res.settings.allowRebase
      allowRebaseMerge   = $res.settings.allowRebaseMerge
    }
.NOTES
#>
  [CmdletBinding(SupportsShouldProcess)]
  param (
    # Collection Uri of the organization
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $CollectionUri,

    # Project where the pipeline will be created.
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $ProjectName,

    # PAT to authentice with the organization
    [Parameter()]
    [string]
    $PAT,

    # Name of the Repository containing the YAML-sourcecode
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $RepoName,

    # Branch to create the policy on
    [Parameter()]
    [string]
    $Branch = "main",

    # Allow squash merge
    [Parameter()]
    [bool]
    $AllowSquash = $true,

    # Allow no fast forward merge
    [Parameter()]
    [bool]
    $AllowNoFastForward = $false,

    # Allow rebase merge
    [Parameter()]
    [bool]
    $AllowRebase = $false,

    # Allow rebase merge message
    [Parameter()]
    [bool]
    $AllowRebaseMerge = $false
  )

  begin {
    if (-not($script:header)) {

      try {
        New-ADOAuthHeader -PAT $PAT -ErrorAction Stop
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }
  }

  Process {
    Write-Debug "CollectionUri: $CollectionUri"
    Write-Debug "ProjectName: $ProjectName"
    Write-Debug "RepoName: $RepoName"
    Write-Debug "branch: $branch"
    Write-Debug "Required: $Required"
    Write-Debug "BuildDefinitionId: $Id"
    Write-Debug "Name: $Name"

    try {
      $policyId = Get-BranchPolicyType -CollectionUri $CollectionUri -ProjectName $ProjectName -PAT $PAT -PolicyType "Require a merge strategy"
    } catch {
      throw $_.Exception.Message
    }

    try {
      $repoId = (Get-AzDoRepo -CollectionUri $CollectionUri -ProjectName $ProjectName -PAT $PAT -RepoName $RepoName).RepoId
    } catch {
      throw $_.Exception.Message
    }

    $body = @{
      isEnabled  = $true
      isBlocking = $false
      type       = @{
        id = $policyId
      }
      settings   = @{
        allowSquash        = $AllowSquash
        allowNoFastForward = $AllowNoFastForward
        allowRebase        = $AllowRebase
        allowRebaseMerge   = $AllowRebaseMerge
        scope              = @(
          @{
            repositoryId = $repoId
            refName      = "refs/heads/$branch"
            matchKind    = "exact"
          }
        )
      }
    }

    $params = @{
      uri         = "$CollectionUri/$ProjectName/_apis/policy/configurations?api-version=7.2-preview.1"
      Method      = 'POST'
      Headers     = $script:header
      body        = $Body | ConvertTo-Json -Depth 99
      ContentType = 'application/json'
    }

    if ($PSCmdlet.ShouldProcess($CollectionUri)) {
      try {
        Write-Information "Creating 'Require a merge strategy' policy on $RepoName/$branch"
        $res = Invoke-RestMethod @params
        [PSCustomObject]@{
          CollectionUri      = $CollectionUri
          ProjectName        = $ProjectName
          RepoName           = $RepoName
          id                 = $res.id
          allowSquash        = $res.settings.allowSquash
          allowNoFastForward = $res.settings.allowNoFastForward
          allowRebase        = $res.settings.allowRebase
          allowRebaseMerge   = $res.settings.allowRebaseMerge
        }
      } catch {
        Write-Warning "Policy on $RepoName/$branch already exists. It is not possible to update policies"
      }
    } else {
      $Body | Format-List
    }

  }
}
