function New-AzDoPullRequest {
  <#
.SYNOPSIS
    Creates a pull request in Azure DevOps.
.DESCRIPTION
    Creates a pull request in Azure DevOps.
.EXAMPLE
    $params = @{
        CollectionUri = "https://dev.azure.com/contoso"
        RepoId          = "fc16d875-9a38-3qb1-8822-a29c7d437582"
        ProjectName   = "Project 1"
        Title          = "New Pull Request"
        Description    = "This is a new pull request"
        SourceRefName  = "refs/heads/feature1"
        TargetRefName  = "refs/heads/main"
    }
    New-AzDoPullRequest @params

    This example creates a new Azure DevOps Pull Request with splatting parameters
.OUTPUTS
    [PSCustomObject]@{
        CollectionUri  = $CollectionUri
        ProjectName    = $ProjectName
        RepoId         = $RepoId
        PullRequestId  = $res.pullRequestId
        PullRequestURL = $res.url
      }
.NOTES
#>

  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param (
    # Collection Uri of the organization
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [ValidateScript({ Validate-CollectionUri -CollectionUri $_ })]
    [string]
    $CollectionUri,

    # Id of the repository
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $RepoId,

    # Name of the project where the new repository has to be created
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $ProjectName,

    # Title of the pull request
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $Title,

    # Description of the pull request
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $Description,

    # Source ref name
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $SourceRefName,

    # Target ref name
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $TargetRefName
  )

  begin {
    Write-Verbose "Starting function: New-AzDoPullRequest"
  }

  process {
    $ProjectId = (Get-AzDoProject -CollectionUri $CollectionUri -ProjectName $ProjectName).Projectid

    $params = @{
      uri     = "$CollectionUri/$ProjectName/_apis/git/repositories/$RepoId/pullrequests"
      version = '7.2-preview.2'
      method  = 'POST'
      body    = @{
        sourceRefName = $SourceRefName
        targetRefName = $TargetRefName
        title         = $Title
        description   = $Description
      }
    }

    $res = Invoke-AzDoRestMethod @params

    [PSCustomObject]@{
      CollectionUri     = $CollectionUri
      ProjectName       = $ProjectName
      RepoId            = $RepoId
      PullRequestId     = $res.pullRequestId
      PullRequestURL    = $res.url
      PullRequestWebUrl = "$CollectionUri/$ProjectId/_git/$RepoId/pullrequest/$($res.pullRequestId)"
    }
  }

  end {
    Write-Verbose "Ending function: New-AzDoPullRequest"
  }
}
