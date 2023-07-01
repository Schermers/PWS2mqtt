# Source based on Xorfor: https://github.com/Xorfor/HA-PWS/blob/main/configuration.yaml
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Define script var to its name
$env:script = ($MyInvocation.MyCommand.Name).replace("_","")

# Convert and calculate european values
Write-Log -value "Converting the rawdata"
$rawweatherData = Convert-RawData -rawData $Request.RawBody
[pscustomobject]$weatherData = @{
    temperature_outdoor = Convert-Farenheit2Celcius -farenheit $rawweatherData.tempf
    temperature_indoor = Convert-Farenheit2Celcius -farenheit $rawweatherData.tempinf
    humidity_outdoor = $rawweatherData.humidity
    humidity_indoor = $rawweatherData.humidityin
    barometer_relative = Convert-Pressure2hPa -pressure $rawweatherData.baromrelin
    barometer_absolute = Convert-Pressure2hPa -pressure $rawweatherData.baromabsin
    rainrate_mmh = Convert-Rainrate2mmh -rainRate $rawweatherData.rainratein
    rain_mm = Convert-Rainrate2mmh -rainRate $rawweatherData.dailyrainin
    solar_radiation = $rawweatherData.solarradiation
    uv = $rawweatherData.uv
    wind_speed = Convert-Windspeed2ms -windspeed $rawweatherData.windspeedmph
    wind_gust = Convert-Windspeed2ms -windspeed $rawweatherData.windgustmph
    wind_direction = $rawweatherData.winddir
    wind_direction_abbreviation = (Get-WindDirection -Degree $rawweatherData.winddir).Abbreviation
    wind_direction_entext = (Get-WindDirection -Degree $rawweatherData.winddir).Direction
    stationtype = $rawweatherData.stationtype
    model = $rawweatherData.model
    dewpoint = Get-Dewpoint -outdoorFarenheit $rawweatherData.tempf -outdoorHumidity $rawweatherData.humidity
    windchill = Get-Windchill -windspeed $rawweatherData.windspeedmph -outdoorFarenheit $rawweatherData.tempf
    heat_index = Get-HeatIndex -outdoorFarenheit $rawweatherData.tempf -outdoorHumidity $rawweatherData.humidity
}

# Export for debugging
#$Request.RawBody | Export-Clixml "rawbody.xml"
#$weatherData | Export-Clixml -path "weatherdata.xml"
Write-Output ($weatherData | Out-String)

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
Publish-Statistics -MQTTobject $MQTTobject -statisticsData $weatherData -mainTopic $env:PWSname
Write-Log "Publishing json data"
Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $weatherData -mainTopic $env:PWSname
Write-Log "Publishing raw data (json)"
Publish-StatisticsasJson -MQTTobject $MQTTobject -statisticsData $rawweatherData -mainTopic $env:PWSname -topic 'rawweatherData'

# Disconnect MQTT
Write-Log "Disconnecting MQTT"
$MQTTobject.Disconnect()

#$Request.RawBody | Export-Clixml "rawbody.xml"
#Invoke-WebRequest -UseDefaultCredentials -Uri "http://dze.schermers.local:5000/weatherstation/updateweatherstation.php?" -Method Get -Body $Request.RawBody -AllowUnencryptedAuthentication

Write-Log "End of function app"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})