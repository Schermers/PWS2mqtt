<#
 .Synopsis
  Functions to publish to MQTT

 .Description
  Functions to publish to MQTT
#>

# Function to publish the statistics results to MQTT
function Publish-Statistics {
    param (
        [Parameter(Mandatory=$True,HelpMessage="MQTT Object")]
        $MQTTobject,        
        [Parameter(Mandatory=$True,HelpMessage="Data as array")]
        [pscustomobject]$statisticsData,
        [Parameter(Mandatory=$True,HelpMessage="Main topic")]
        [string]$mainTopic
    )
    
    foreach($key in $statisticsData.Keys) {
        Write-Output "$key | $($statisticsData[$key])"
        # Publish message
        $MQTTobject.Publish("pws/$mainTopic/$key", [System.Text.Encoding]::UTF8.GetBytes($($statisticsData[$key])), 0, $env:retainData) 
    }
}

# Function to publish the raw statistics results to MQTT
function Publish-StatisticsasJson {
    param (
        [Parameter(Mandatory=$True,HelpMessage="MQTT Object")]
        $MQTTobject,    
        [Parameter(Mandatory=$True,HelpMessage="Data as array")]
        [pscustomobject]$statisticsData,
        [Parameter(Mandatory=$True,HelpMessage="Main topic")]
        [string]$mainTopic,
        [Parameter(Mandatory=$false,HelpMessage="Sub topic")]
        [string]$topic = 'jsondata'
    )

    # Convert data to JSON
    $jsonData = $statisticsData | ConvertTo-Json -Depth 20
    
    # Publish raw statistics
    $MQTTobject.Publish("pws/$mainTopic/$topic", [System.Text.Encoding]::UTF8.GetBytes($jsonData), 0, $env:retainData) 
}

Export-ModuleMember -Function Publish-Statistics
Export-ModuleMember -Function Publish-StatisticsasJson