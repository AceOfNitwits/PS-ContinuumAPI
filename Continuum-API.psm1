# https://doccenter.itsupport247.net/#Reporting_API_Getting_Started.htm?Highlight=API
# To incorporate with Autotask (using the Autotask API module), use (Get-AtwsAccount -AccountNumber $_.siteCode) The Auttoask AccountNumber is the same as the Continuum SiteCode
Function Connect-Continuum{
    param($ApiKey,[switch]$ShowCreds)
    If (-not $ApiKey){$ApiKey = Read-Host "Continuum Reporting API Key"}
    $Script:continuumCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($ApiKey))
    If($ShowCreds){
        Write-Host $Script:continuumCredentials
    }
}

Function Get-ContinuumSites {
    $response = Invoke-RestMethod -Uri "https://api.itsupport247.net/reporting/v1/sites" -Method Get -ContentType "application/json" -Headers @{"Authorization" = "Basic $continuumCredentials"}
    Return $response
}

#https://doccenter.itsupport247.net/Content/Reporting_API_REST_Resources.htm#Agent%C2%A0De
Function Get-ContinuumAgentDetails {
    param ([string]$SiteCode)
    $response = Invoke-RestMethod -Uri "https://itsapi.itsupport247.net/reportingapi/ReportingAPIService.svc/json/agent/details" -Method Post -ContentType "application/json" -Headers @{"Authorization" = "Basic $continuumCredentials"} -Body $(ConvertTo-Json @{"SiteCode" = "$SiteCode"})
    $agentDetails = $response | Select-Object -ExpandProperty AgentDetails
    $AgentDetails | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name InstallDatePsLocal -Value $(Get-Date($_.InstallDate))
        If($_.LastBoot){$_ | Add-Member -MemberType NoteProperty -Name LastBootPsLocal -Value $(Get-Date($_.LastBoot))}
        $_ | Add-Member -MemberType NoteProperty -Name LastContactPsLocal -Value $(Get-Date($_.LastContact))
    }
    Return $agentDetails
}

Function Get-ContinuumStaleAgents {
    param (
        [string]$SiteCode,
        [int]$Days
    )
    $staleAgents = Get-ContinuumAgentDetails -SiteCode $SiteCode | Where-Object {$_.LastContactPSLocal -lt (Get-Date).AddDays(-$days)}
    Return $staleAgents
}

Function Get-ContinuumStaleAgentsAtAllSites {
    param (
        [int]$Days
    )
    Get-ContinuumSites | ForEach-Object {
        $mySiteCode = $_.siteCode
        $myStaleAgents = Get-ContinuumStaleAgents -SiteCode $_.siteCode -Days $Days | Select-Object -Property *, @{N='SiteCode';E={$($mySiteCode)}}
        $allStaleAgents+=@($myStaleAgents) #The array subexpression operator ensures that the value added to the variable is always an array, even if there is only one object.
    }
    Return $allStaleAgents
}

Function Get-ContinuumAgent {
    param(
        [string]$SiteCode,
        [string]$ResourceName
    )
    $siteResources = Get-ContinuumAgentDetails -SiteCode $SiteCode
    $siteResources | Where-Object ResourceName -eq $ResourceName
}

Function Get-ContinuumDevices {
    param ([string]$SiteCode)
    $response = Invoke-RestMethod -Uri "https://itsapi.itsupport247.net/reporting/v1/sites/$SiteCode/devices" -Method Get -ContentType "application/json" -Headers @{"Authorization" = "Basic $continuumCredentials"}
    $response | ForEach-Object {
        #$_ | Add-Member -MemberType NoteProperty -Name InstallDatePsLocal -Value $(Get-Date($_.InstallDate))
        #If($_.LastBoot){$_ | Add-Member -MemberType NoteProperty -Name LastBootPsLocal -Value $(Get-Date($_.LastBoot))}
        #$_ | Add-Member -MemberType NoteProperty -Name LastContactPsLocal -Value $(Get-Date($_.LastContact))
    }
    Return $response
}


Function Get-ContinuumInstalledSoftware {
    param ([string]$SiteCode)
    $response = Invoke-RestMethod -Uri "https://itsapi.itsupport247.net/reportingapi/ReportingAPIService.svc/json/software/installed" -Method Post -ContentType "application/json" -Headers @{"Authorization" = "Basic $continuumCredentials"} -Body $(ConvertTo-Json @{"SiteCode" = "$SiteCode"})
    $installedSoftware = $response | Select-Object -ExpandProperty InstalledSoftware
    $installedSoftware | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name DateCheckedPsLocal -Value $(Get-Date($_.DateChecked))
        If($_.InstallDate){$_ | Add-Member -MemberType NoteProperty -Name InstallDatePsLocal -Value $(Get-Date($_.InstallDate))}
    }
    Return $installedSoftware
}

Function Get-ContinuumSystemInformation {
    param ([string]$SiteCode)
    $response = Invoke-RestMethod -Uri "https://itsapi.itsupport247.net/reportingapi/ReportingAPIService.svc/json/systeminformation" -Method Post -ContentType "application/json" -Headers @{"Authorization" = "Basic $continuumCredentials"} -Body $(ConvertTo-Json @{"SiteCode" = "$SiteCode"})
    $systemInformation = $response | Select-Object -ExpandProperty SystemInformation
    $systemInformation | ForEach-Object {
        #$_ | Add-Member -MemberType NoteProperty -Name InstallDatePsLocal -Value $(Get-Date($_.InstallDate))
        #If($_.LastBoot){$_ | Add-Member -MemberType NoteProperty -Name LastBootPsLocal -Value $(Get-Date($_.LastBoot))}
        #$_ | Add-Member -MemberType NoteProperty -Name LastContactPsLocal -Value $(Get-Date($_.LastContact))
    }
    Return $systemInformation
}

Export-ModuleMember -Function *