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
        [string]$mainTopic,
        [Parameter(Mandatory=$True,HelpMessage="Retain data")]
        $retainData
    )
    
    foreach($key in $statisticsData.Keys) {
        Write-Output "$key | $($statisticsData[$key])"
        # Publish message
        $MQTTobject.Publish("pws/$mainTopic/$key", [System.Text.Encoding]::UTF8.GetBytes($($statisticsData[$key])), 0, $retainData) 
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
        [string]$topic = 'jsondata',
        [Parameter(Mandatory=$True,HelpMessage="Retain data")]
        $retainData
    )

    # Convert data to JSON
    $jsonData = $statisticsData | ConvertTo-Json -Depth 20
    
    # Publish raw statistics
    $MQTTobject.Publish("pws/$mainTopic/$topic", [System.Text.Encoding]::UTF8.GetBytes($jsonData), 0, $retainData) 
}

# Function to publish the a single message
function Publish-Message {
    param (
        [Parameter(Mandatory=$True,HelpMessage="MQTT Object")]
        $MQTTobject,    
        [Parameter(Mandatory=$True,HelpMessage="json Data")]
        $jsonData,
        [Parameter(Mandatory=$True,HelpMessage="Topic")]
        $topic,
        [Parameter(Mandatory=$True,HelpMessage="Retain data")]
        $retainData
    )
    
    # Publish message
    $MQTTobject.Publish($topic, [System.Text.Encoding]::UTF8.GetBytes($jsonData), 0, $retainData)
}

function Publish-All2MQTT {
    param (
        [Parameter(Mandatory=$True,HelpMessage="MQTT Object")]
        $MQTTobject,        
        [Parameter(Mandatory=$True,HelpMessage="Data as array")]
        [pscustomobject]$weatherData,
        [Parameter(Mandatory=$True,HelpMessage="Data as array")]
        [pscustomobject]$rawweatherData,
        [Parameter(Mandatory=$True,HelpMessage="Main topic")]
        [string]$PWSname,
        [Parameter(Mandatory=$false,HelpMessage="Domoticz in topic")]
        $DomoticzInTopic,
        [Parameter(Mandatory=$false,HelpMessage="Domoticz message")]
        [string]$DomoticzMessage,
        [Parameter(Mandatory=$True,HelpMessage="Retain data")]
        $retainData
    )
    # Publishing data to MQTT
    Write-Log "Publishing data per topic"
    Publish-Statistics -MQTTobject $MQTTobject -statisticsData $weatherData -mainTopic $PWSname -retainData $retainData
    Write-Log "Publishing json data"
    Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $weatherData -mainTopic $PWSname -retainData $retainData
    Write-Log "Publishing raw data (json)"
    Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $rawweatherData -mainTopic $PWSname -topic 'rawweatherData' -retainData $retainData

    # Only publish to Domoticz if topic is entered
    if($DomoticzInTopic) {
        Write-Log "Domoticz topic entered: $DomoticzInTopic with message: $DomoticzMessage"
        
        # Publish message
        Write-Log "Publishing domoticz data"
        Publish-Message -MQTTobject $MQTTobject -jsonData $DomoticzMessage -topic $DomoticzInTopic -retainData $retainData
    }
}

Export-ModuleMember -Function Publish-All2MQTT
Export-ModuleMember -Function Publish-Statistics
Export-ModuleMember -Function Publish-StatisticsasJson
Export-ModuleMember -Function Publish-Message