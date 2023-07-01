# Source based on Xorfor: https://github.com/Xorfor/HA-PWS/blob/main/configuration.yaml
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Define script var to its name
$env:script = ($MyInvocation.MyCommand.Name).replace("_","")

# Convert and calculate european values
Write-Log -value "Converting the rawdata"
$rawWheaterData = Convert-RawData -rawData $Request.RawBody
[pscustomobject]$wheaterData = @{
    temperature_outdoor = Convert-Farenheit2Celcius -farenheit $rawWheaterData.tempf
    temperature_indoor = Convert-Farenheit2Celcius -farenheit $rawWheaterData.tempinf
    humidity_outdoor = $rawWheaterData.humidity
    humidity_indoor = $rawWheaterData.humidityin
    barometer_relative = Convert-Pressure2hPa -pressure $rawWheaterData.baromrelin
    barometer_absolute = Convert-Pressure2hPa -pressure $rawWheaterData.baromabsin
    rainrate_mmh = Convert-Rainrate2mmh -rainRate $rawWheaterData.rainratein
    rain_mm = Convert-Rainrate2mmh -rainRate $rawWheaterData.dailyrainin
    solar_radiation = $rawWheaterData.solarradiation
    uv = $rawWheaterData.uv
    wind_speed = Convert-Windspeed2ms -windspeed $rawWheaterData.windspeedmph
    wind_gust = Convert-Windspeed2ms -windspeed $rawWheaterData.windgustmph
    wind_direction = $rawWheaterData.winddir
    wind_direction_abbreviation = (Get-WindDirection -Degree $rawWheaterData.winddir).Abbreviation
    wind_direction_entext = (Get-WindDirection -Degree $rawWheaterData.winddir).Direction
    stationtype = $rawWheaterData.stationtype
    model = $rawWheaterData.model
    dewpoint = Get-Dewpoint -outdoorFarenheit $rawWheaterData.tempf -outdoorHumidity $rawWheaterData.humidity
    windchill = Get-Windchill -windspeed $rawWheaterData.windspeedmph -outdoorFarenheit $rawWheaterData.tempf
    heat_index = Get-HeatIndex -outdoorFarenheit $rawWheaterData.tempf -outdoorHumidity $rawWheaterData.humidity
}

# Export for debugging
#$wheaterData | Export-Clixml -path "wheaterdata.xml"
Write-Output ($wheaterData | Out-String)

# Load MQTT module
Add-Type -Path ".\Modules\MQTTmodule\M2Mqtt.Net.dll"
Write-Log "M2MQtt module loaded"

# Verify if MQTT port is filled
if(!($env:MQTTport)) {
    $env:MQTTport = 1883
    Write-Log "Default MQTT port selected"
}

# Verify if MQTT address is filled
if(!$($env:MQTTserver)) {
    Write-Log "No MQTT server defined! Stop script"
    exit
}

# Verify if retain data is set
if(!($env:retainData)) {
    $env:retainData = 1 # 0 = False, 1 = true
    Write-Log "Default MQTT retain bit is set"
}

# Verify if PWS name is entered, otherwise make a default
if(!$($env:PWSname)) {
    Write-Log "No PWS name detected, defaults to 'MyPWS"
    $env:PWSname = "MyPWS"
}

# Define MQTT client object
$MQTTobject = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($env:MQTTserver, $env:MQTTport, $false, [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None, $null, $null)

Write-Log "Connecting to MQTT server $env:MQTTserver:$env:MQTTport"
if($env:MQTTuser -or $env:MQTTpassword) {
    # Connect with username and password
    $MQTTobject.Connect([guid]::NewGuid(), $env:MQTTuser, $env:MQTTpassword) 
}
else{
    # Connect anonymous
    $MQTTobject.Connect([guid]::NewGuid()) 
}

# Publishing data to MQTT
Write-Log "Publishing data per topic"
Publish-Statistics -MQTTobject $MQTTobject -statisticsData $wheaterData -mainTopic $env:PWSname
Write-Log "Publishing json data"
Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $wheaterData -mainTopic $env:PWSname
Write-Log "Publishing raw data (json)"
Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $rawWheaterData -mainTopic $env:PWSname -topic 'rawWheaterData'

# Disconnect MQTT
Write-Log "Disconnecting MQTT"
$MQTTobject.Disconnect()

Write-Log "End of function app"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})