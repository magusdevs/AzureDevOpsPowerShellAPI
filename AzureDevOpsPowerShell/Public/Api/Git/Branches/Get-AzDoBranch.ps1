function Get-AzDoBranch {
  <#
.SYNOPSIS
    Gets information about a branch in Azure DevOps.
.DESCRIPTION
    Gets information about 1 branch if the parameter $Name is filled in. Otherwise it will list all the branches.
.EXAMPLE
    $Params = @{
        CollectionUri = "https://dev.azure.com/contoso"
        ProjectName = "Project 1"
        RepoName "Repo 1"
        Name "Branch1"
    }
    Get-AzDoBranch -CollectionUri = "https://dev.azure.com/contoso" -PAT = "***" -ProjectName = "Project 1" -RepoName "Repo 1"

    This example will list all the branches contained in 'Repo 1'.
.EXAMPLE
    $Params = @{
        CollectionUri = "https://dev.azure.com/contoso"
        ProjectName = "Project 1"
        RepoName "Repo 1"
        Name "Branch1", "Branch2"
    }
    Get-AzDoBranch -CollectionUri = "https://dev.azure.com/contoso" -PAT = "***" -ProjectName = "Project 1" -RepoName "Repo 1" -Name "Branch1", "Branch2"

    This example will fetch information about the branch with the name 'Branch1'.
.OUPUTS
    PSObject with branch(es).
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

    # Name of the branch to get information about
    [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string[]]
    $BranchName
  )

  begin {
    Write-Verbose "Starting function: Get-AzDoBranch"
  }

  process {

    $params = @{
      uri     = "$CollectionUri/$ProjectName/_apis/git/repositories/$RepoName/refs"
      version = "4.1-preview.1"
      method  = 'GET'
    }

    if ($PSCmdlet.ShouldProcess($CollectionUri, "Get Environments from: $($PSStyle.Bold)$ProjectName$($PSStyle.Reset)")) {
      $branches = (Invoke-AzDoRestMethod @params).value

      if ($BranchName) {
        foreach ($name in $BranchName) {
          if ($name -match "refs/heads/") { $name } else { $name = "refs/heads/$name" }
          $branch = $branches | Where-Object { $name -eq $_.name }
          if (-not($branch)) {
            Write-Error "branch $name not found"
            continue
          } else {
            $result += $branch
          }
        }
      } else {
        $result += $branches
      }

    } else {
      Write-Verbose "Calling Invoke-AzDoRestMethod with $($params| ConvertTo-Json -Depth 10)"
    }
  }

  end {
    if ($result) {
      $result | ForEach-Object {
        [PSCustomObject]@{
          CollectionURI = $CollectionUri
          ProjectName   = $ProjectName
          RepoName      = $RepoName
          BranchName    = $_.name
          ObjectId      = $_.objectId
          Url           = $_.url
        }
      }
    }
  }
}

