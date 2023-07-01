<#
 .Synopsis
  Functions to determine weather conditions in Dutch metrics

 .Description
  Functions to determine weather conditions in Dutch metrics
#>

# Function to convert rawdata to table
function Convert-RawData {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Raw data retrieved from weather station")]
        [array]$rawData
    )
    # Split string into rows
    $rows = $rawData.split("&")
    
    # Convert rows into table
    $data = New-Object -TypeName PSObject
    foreach($entry in $rows) {
        $data | Add-Member -MemberType NoteProperty $entry.split("=")[0] -Value $entry.split("=")[1]
    }

    # Return table
    return $data
}

# Function to calculate degree celcius based on Farenheit
function Convert-Farenheit2Celcius {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter Farenheit")]
        [float]$farenheit
    )

    # Calculate celcius
    $celcius = [math]::Round((($farenheit - 32) / 1.8),1)

    # Return celcius
    return $celcius
}

# Function to calculate pressure
function Convert-Pressure2hPa {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter Pressure")]
        [float]$pressure
    )

    # Calculate pHa
    $pHa = [math]::Round(($pressure * 33.86),1)

    # Return pHa
    return $pHa
}

# Calculate rainrate in mm/h
function Convert-Rainrate2mmh {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter Rainrate")]
        [float]$rainRate
    )

    # Calculate mmh
    $mmh = [math]::Round(($rainRate * 2.54 * 10),1)

    # Return mmh
    return $mmh
}

# Calculate windspeed in meter per second
function Convert-Windspeed2ms {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter Windspeed")]
        [float]$windspeed
    )

    # Calculate ms
    $ms = [math]::Round(($windspeed * 0.44704),1)

    # Return ms
    return $ms
}

# Determine Winddirection
# Source: https://www.serverbrain.org/system-administration/a-powershell-function-to-convert-wind-degrees-to-compass-directions-and-italianate-wind-names.html
function Get-WindDirection {

    <#
    .Synopsis
       Returns wind direction
    .DESCRIPTION
       Returns wind direction, abbreviation and the italianate wind name
    .EXAMPLE
       Get-WindDirection -degress 90
    .NOTES
       happysysadm.com
       @sysadm2010
    #>
    
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Degrees
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateRange(0,360)][int]$Degree
    )
    Begin {
        $WindCompassDirectionAbbreviation = @('N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N')
        $WindCompassDirection = @("North","North Northeast","Northeast","East Northeast","East","East Southeast", "Southeast", "South Southeast","South","South Southwest","Southwest","West Southwest","West","West Northwest","Northwest","North Northwest","North")
        $WindCompassName = @('Tramontana','Tramontana-Grecale','Grecale','Grecale-Levante','Levante','Levante-Scirocco','Scirocco','Scirocco-Ostro','Ostro','Ostro-Libeccio','Libeccio','Libeccio-Ponente','Ponente','Ponente-Mastrale','Maestrale','Maestrale-Tramontana','Tramontana')
    }

    Process {
        $Sector = ($Degree+11.25)/22.5  #Divide the angle by 22.5 because 360deg/16 directions = 22.5deg/direction change
        Write-Verbose "$Degree is in $Sector sector."
        $Value = "" | Select-Object -Property Abbreviation,Direction,ItalianName
        $Value.Abbreviation = $WindCompassDirectionAbbreviation[$Sector]
        $Value.Direction = $WindCompassDirection[$Sector]
        $Value.ItalianName = $WindCompassName[$Sector]
        return $Value
    }

    End {}
}

# Calculate dewpoint
function Get-Dewpoint {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter outdoor temperature")]
        [float]$outdoorFarenheit,
        [Parameter(Mandatory=$True,HelpMessage="Enter humidity")]
        [float]$outdoorHumidity
    )

    # Calculate dewpoint
    $celcius = Convert-Farenheit2Celcius -farenheit $outdoorFarenheit
    $humidityAdjusted = [Math]::Pow(($outdoorHumidity/100), 1/8)
    $heatIndex = ($humidityAdjusted * (112 + 0.9 * $celcius)) + (0.1 * $celcius) - 112
    $Dewpoint = [Math]::Round($heatIndex, 1)

    # Return heatIndexRounded
    return $Dewpoint
}

# Calculate Windchill
function Get-Windchill {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter windspeed")]
        [float]$windspeed,
        [Parameter(Mandatory=$True,HelpMessage="Enter temperature")]
        [float]$outdoorFarenheit
    )

    # Calculate celcius
    $celcius = Convert-Farenheit2Celcius -farenheit $outdoorFarenheit

    $result = $null
    # Calculate windchill
    if ($celcius -gt -46.0 -and $celcius -lt 10.0 -and $windspeed -gt 1.3 -and $windspeed -lt 49.0) {
        $w = [Math]::Pow($windspeed, 0.16)
        $result = (13.12 + (0.6215 * $celcius) - (13.96 * $w) + (0.4867 * $celcius * $w))
        $result = [Math]::Round($result, 1)
    } else {
        $result = $celcius
    }

    # Return Windchill
    return $result
}

# Calculate Heat index
function Get-HeatIndex {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter humidity")]
        [float]$outdoorHumidity,
        [Parameter(Mandatory=$True,HelpMessage="Enter temperature")]
        [float]$outdoorFarenheit
    )

    # Calculate celcius
    $celcius = Convert-Farenheit2Celcius -farenheit $outdoorFarenheit

    if ($celcius -ge 26 -and $outdoorHumidity -ge 0.0 -and $outdoorHumidity -le 100.0) {
        $tp = $celcius * $celcius
        $hp = $outdoorHumidity * $outdoorHumidity
        $result = (-8.78469475556 +
            (1.61139411 * $celcius) +
            (2.33854883889 * $outdoorHumidity) +
            (-0.14611605 * $celcius * $outdoorHumidity) +
            (-0.012308094 * $tp) +
            (-0.0164248277778 * $hp) +
            (0.002211732 * $tp * $outdoorHumidity) +
            (0.00072546 * $celcius * $hp) +
            (-0.000003582 * $tp * $hp)
        )
        $result = [Math]::Round($result, 1)
    } else {
        $result = $celcius
    }

    # Return Heatindex
    return $result
}

# Export functions
Export-ModuleMember -Function Write-Log
Export-ModuleMember -Function Convert-RawData
Export-ModuleMember -Function Convert-Farenheit2Celcius
Export-ModuleMember -Function Convert-Pressure2hPa
Export-ModuleMember -Function Convert-Rainrate2mmh
Export-ModuleMember -Function Convert-Windspeed2ms
Export-ModuleMember -Function Get-WindDirection
Export-ModuleMember -Function Get-Dewpoint
Export-ModuleMember -Function Get-Windchill
Export-ModuleMember -Function Get-HeatIndex