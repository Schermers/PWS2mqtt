# Source based on Xorfor: https://github.com/Xorfor/HA-PWS/blob/main/configuration.yaml
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Define script var to its name
$env:script = ($MyInvocation.MyCommand.Name).replace("_","")
Write-Log "Start of function app"

# Function to prepare domoticz message
function Get-DomoticzMessage {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Data as array")]
        [pscustomobject]$weatherData,
        [Parameter(Mandatory=$True,HelpMessage="Custom event to trigger")]
        [string]$CustomEvent
    )
    # Prepare domoticz output
    $weatherData.rainrate_mmh = $weatherData.rainrate_mmh * 100
    $domoticzOutput = $weatherData | ConvertTo-Json

    # Define domoticz custom event trigger
    $domoticzMessage = @{
        command = "customevent"
        event = $CustomEvent
        data = $domoticzOutput
    } | ConvertTo-Json

    return $domoticzMessage
}

# Log raw data request
Write-Log "Incoming data: $($request.RawBody)"

# Verify if incoming data contains weather data
if($request.RawBody -like "PASSKEY=*" -and $request.RawBody -like "*tempinf=*") {
    Write-Log "Incomging data seems valid weather data, continue processing"

    # Verify if language is filled
    if(!$($env:Language)) {
        $env:Language = "EN"
    }

    # Convert and calculate european values
    Write-Log -value "Converting the rawdata"
    $rawweatherData = Convert-RawData -rawData $Request.RawBody
    
    # Create hash table
    [pscustomobject]$weatherData = @{}

    # Check if 'outdoor temperature' is passed
    if($rawweatherData.tempf) {
        $weatherData += @{        
            temperature_outdoor = Convert-Farenheit2Celcius -farenheit $rawweatherData.tempf
        }
        # Check if 'outdoor humidity' is passed
        if($rawweatherData.humidity){
            $weatherData += @{        
                dewpoint = Get-Dewpoint -outdoorFarenheit $rawweatherData.tempf -outdoorHumidity $rawweatherData.humidity
                heat_index = Get-HeatIndex -outdoorFarenheit $rawweatherData.tempf -outdoorHumidity $rawweatherData.humidity
            }   
        }
        else {
            Write-Log "humidity_outdoor (humidity) not found"
        }
        # Check if 'wind speed' is passed
        if($rawweatherData.windspeedmph){
            $weatherData += @{        
                windchill = Get-Windchill -windspeed $rawweatherData.windspeedmph -outdoorFarenheit $rawweatherData.tempf
            }   
        }
        else {
            Write-Log "winspeed (winspeedmph) not found"
        }
    }

    # Check if 'indoor temperature' is passed
    if($rawweatherData.tempinf) {
        $weatherData += @{        
            temperature_indoor = Convert-Farenheit2Celcius -farenheit $rawweatherData.tempinf
        }
    }
    else {
        Write-Log "temperature_indoor (tempinf) not found"
    }
    
    # Check if 'outdoor humidity' is passed
    if($rawweatherData.humidity) {
        $weatherData += @{        
            humidity_outdoor = $rawweatherData.humidity
        }
    }
    else {
        Write-Log "humidity_outdoor (humidity) not found"
    }

    # Check if 'indoor humidity' is passed
    if($rawweatherData.humidityin) {
        $weatherData += @{        
            humidity_indoor = $rawweatherData.humidityin
        }
    }
    else {
        Write-Log "humidity_indoor (humidityin) not found"
    }

    # Check if 'barometer relative' is passed
    if($rawweatherData.baromrelin) {
        $weatherData += @{        
            barometer_relative = Convert-Pressure2hPa -pressure $rawweatherData.baromrelin
        }
    }
    else {
        Write-Log "barometer_relative (baromrelin) not found"
    }

    # Check if 'barometer absolute' is passed
    if($rawweatherData.baromabsin) {
        $weatherData += @{        
            barometer_absolute = Convert-Pressure2hPa -pressure $rawweatherData.baromabsin
        }
    }
    else {
        Write-Log "barometer_absolute (baromabsin) not found"
    }

    # Check if 'rainrate' is passed
    if($rawweatherData.rainratein) {
        $weatherData += @{        
            rainrate_mmh = Convert-Rainrate2mmh -rainRate $rawweatherData.rainratein
        }
    }
    else {
        Write-Log "rainrate_mmh (rainratein) not found"
    }

    # Check if 'daily rain'' is passed
    if($rawweatherData.dailyrainin) {
        $weatherData += @{        
            rain_mm = Convert-Rainrate2mmh -rainRate $rawweatherData.dailyrainin
        }
    }
    else {
        Write-Log "rain_mm (dailyrainin) not found"
    }

    # Check if 'total rain' is passed
    if($rawweatherData.totalrainin) {
        $weatherData += @{        
            totalrain_mm = Convert-Rainrate2mmh -rainRate $rawweatherData.totalrainin
        }
    }
    else {
        Write-Log "totalrain_mm (totalrainin) not found"
    }

    # Check if 'solar' is passed
    if($rawweatherData.solarradiation) {
        $weatherData += @{        
            solar_radiation = $rawweatherData.solarradiation
        }
    }
    else {
        Write-Log "solar_radiation (solarradiation) not found"
    }

    # Check if 'uv' is passed
    if($rawweatherData.uv) {
        $weatherData += @{        
            uv = $rawweatherData.uv
        }
    }
    else {
        Write-Log "uv (uv) not found"
    }

    # Check if 'windspeed' is passed
    if($rawweatherData.windspeedmph) {
        # Prepare wind speed
        $windspeed = Convert-Windspeed -windspeed $rawweatherData.windspeedmph -Language $env:Language
        
        $weatherData += @{        
            wind_speed_ms = $windspeed['ms']
            wind_speed_kph = $windspeed['kph']
            wind_scale_beaufort = $windspeed['beaufort']
            wind_speed_name = $windspeed['name']
        }
    }
    else {
        Write-Log "wind_speed (windspeedmph) not found"
    }

    # Check if 'wind gust' is passed
    if($rawweatherData.windgustmph) {
        # Prepare wind speed
        $windspeed = Convert-Windspeed -windspeed $rawweatherData.windgustmph -Language $env:Language
        
        $weatherData += @{        
            wind_gust_ms = $windspeed['ms']
            wind_gust_kph = $windspeed['kph']
            wind_gust_scale_beaufort = $windspeed['beaufort']
            wind_gust_name = $windspeed['name']
        }
    }
    else {
        Write-Log "wind_gust (windgustmph) not found"
    }

    # Check if 'wind direction' is passed
    if($rawweatherData.winddir) {
        # Prepare wind speed
        $winddirection = Get-WindDirection -Degree $rawweatherData.winddir
        
        $weatherData += @{        
            wind_direction = $rawweatherData.winddir
            wind_direction_abbreviation = $winddirection.Abbreviation
            wind_direction_entext = $winddirection.Direction    
        }
    }
    else {
        Write-Log "wind_direction (winddir) not found"
    }

    # Check if 'stationtype' is passed
    if($rawweatherData.stationtype) {
        $weatherData += @{        
            stationtype = $rawweatherData.stationtype
        }
    }
    else {
        Write-Log "stationtype (stationtype) not found"
    }

    # Check if 'model'' is passed
    if($rawweatherData.model) {
        $weatherData += @{        
            model = $rawweatherData.model
        }
    }
    else {
        Write-Log "model (model) not found"
    }

    # Export for debugging
    #$Request | Export-Clixml "rawRequest.xml"
    #$Request.RawBody | Export-Clixml "rawbody.xml"
    #$weatherData | Export-Clixml -path "weatherdata.xml"
    Write-Output ($weatherData | Out-String)

    # Load MQTT module
    Add-Type -Path ".\Modules\MQTTmodule\M2Mqtt.Net.dll"
    Write-Log "M2MQtt module loaded"

    # Verify if MQTT address is filled
    if(!$($env:MQTTserver)) {
        Write-Log "No MQTT server defined! Stop script"
        exit
    }

    # Verify if retain data is set
    if(!($env:retainData)) {
        $env:retainData = 0 # 0 = False, 1 = true
        Write-Log "Default MQTT retain bit is set"
    }

    # Verify if PWS name is entered, otherwise make a default
    if(!$($env:PWSname)) {
        Write-Log "No PWS name detected, defaults to 'MyPWS"
        $env:PWSname = "MyPWS"
    }

    # Verify if PWS eventname is entered, otherwise make a default
    if(!$($env:DomoticzCustomEvent)) {
        $env:DomoticzCustomEvent = "PWS2mqtt"
    }

    # Create array of MQTT instances
    $MQTTinstances = @() 

    # Add MQTT properties to array
    $MQTTinstances += [PSCustomObject]@{
        MQTTserver = $env:MQTTserver;
        MQTTport = $env:MQTTport;
        MQTTuser = $env:MQTTuser;
        MQTTpassword = $env:MQTTpassword;
    }

    # Add MQTT properties to array
    $MQTTinstances += [PSCustomObject]@{
        MQTTserver = $env:MQTTserver2;
        MQTTport = $env:MQTTport2;
        MQTTuser = $env:MQTTuser2;
        MQTTpassword = $env:MQTTpassword2;
    }

    # Prepare Domoticz message
    $domoticzMessage = Get-DomoticzMessage -weatherData $weatherData -CustomEvent $env:DomoticzCustomEvent

    # Loop through every MQTT instance to publish the messages
    foreach($MQTTinstance in $MQTTinstances) {
        # Verify if MQTTserver name is filled, otherwise skip
        if($MQTTinstance.MQTTserver) {
            # Clear MQTTobject
            $MQTTobject = $null

            # Verify if MQTT port is filled
            if(!($MQTTinstance.MQTTport)) {
                $MQTTinstance.MQTTport = 1883
                Write-Log "Default MQTT port selected for $($MQTTinstance.MQTTserver)"
            }

            # Define MQTT client object
            $MQTTobject = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($MQTTinstance.MQTTserver, $MQTTinstance.MQTTport, $false, [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None, $null, $null)

            Write-Log "Connecting to MQTT server $($MQTTinstance.MQTTserver):$($MQTTinstance.MQTTport)"
            if($MQTTinstance.MQTTuser -and $MQTTinstance.MQTTpassword) {
                # Connect with username and password
                $MQTTobject.Connect([guid]::NewGuid(), $MQTTinstance.MQTTuser, $MQTTinstance.MQTTpassword) 
            }
            else{
                # Connect anonymous
                $MQTTobject.Connect([guid]::NewGuid()) 
            }

            # Publish all messages to MQTT
            Write-Log "Sending messages to: $($MQTTinstance.MQTTserver)"
            Publish-All2MQTT -MQTTobject $MQTTobject -weatherData $weatherData -rawweatherData $rawweatherData -PWSname $env:PWSname -DomoticzInTopic $env:DomoticzInTopic -DomoticzMessage $domoticzMessage -retainData $env:retainData

            # Disconnect MQTT
            Write-Log "Disconnecting from: $($MQTTinstance.MQTTserver)"
            $MQTTobject.Disconnect()
        }
    }
}
else{
    # Incoming data doesn't contain expected data
    Write-Log "Stop processing this data. Incoming data is missing expected values: 'PASSKEY=' and 'tempinf='"
    Write-Log $Request.RawBody
}

Write-Log "End of function app"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})