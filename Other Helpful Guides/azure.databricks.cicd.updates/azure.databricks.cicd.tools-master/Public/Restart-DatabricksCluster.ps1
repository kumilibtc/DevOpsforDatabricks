<#
.SYNOPSIS
Restarts a Databricks cluster or set of clusters with the same name.

.DESCRIPTION
Restarts a Databricks cluster or set of clusters with the same name.

.PARAMETER BearerToken
Your Databricks Bearer token to authenticate to your workspace (see User Settings in Datatbricks WebUI)

.PARAMETER Region
Azure Region - must match the URL of your Databricks workspace, example northeurope

.PARAMETER ClusterName
Optional. Will restart all clusters with this name.

.PARAMETER ClusterId
Optional. See Get-DatabricksClusters. Will restart this cluster only if provided.

.NOTES
Author: Simon D'Morias / Data Thirst Ltd
Author: Abhisek Mandal / Microsoft

#>

Function Restart-DatabricksCluster {  
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$BearerToken,    
        [parameter(Mandatory = $true)][string]$Region,
        [parameter(Mandatory = $false)][string]$ClusterName,
        [parameter(Mandatory = $false)][string]$ClusterId
        )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $InternalBearerToken = Format-BearerToken($BearerToken)
    $Region = $Region.Replace(" ","")
    
    $body = @{}
    $ClusterIds = @()

    If ($PSBoundParameters.ContainsKey('ClusterId')) {
        $ClusterIds += $ClusterId
    }
    elseif ($PSBoundParameters.ContainsKey('ClusterName')) {
        $Clusters = (Get-DatabricksClusters -Bearer $BearerToken -Region $Region | Where-Object {$_.cluster_name -eq $ClusterName})
        foreach ($c in $Clusters)
        {
            $ClusterIds += $c.cluster_id
        }
    }
    else{
        Write-Error "You must specify ClusterId or ClusterName"
        return
    }
    

    foreach ($ClusterId in $ClusterIds)
    {
        $Body['cluster_id'] = $ClusterId
        Try {
            $BodyText = $Body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Method Post -Body $BodyText -Uri "https://$Region.azuredatabricks.net/api/2.0/clusters/restart" -Headers @{Authorization = $InternalBearerToken}
        }
        Catch {
            Write-Output "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Output "StatusDescription:" $_.Exception.Response.StatusDescription
            Write-Output $_.Exception
            Write-Error $_.ErrorDetails.Message
            Return
        }
    }
}