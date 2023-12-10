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

# Original source: https://www.serverbrain.org/system-administration/a-powershell-function-to-translate-wind-speed-to-beaufort-scale-numbers.html
# Mapping between ms and beaufort: https://nl.wikipedia.org/wiki/Schaal_van_Beaufort
function Get-WindForce {

    <#
    .Synopsis
       Returns beaufort and wind force name from speed in m/s
    .DESCRIPTION
       Returns beaufort and wind force in a give language from speed in m/s
    .EXAMPLE
       Get-WindForce -speed 2 -language EN
    .EXAMPLE
       Get-WindForce -speed 31.5 -language IT
    .EXAMPLE
        15,40 | Get-WindForce -Language FR -Verbose
    .NOTES
       happysysadm.com
       @sysadm2010
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Speed of wind in m/s
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [double]$Speed,

        # Language to use for the output of the wind force
        [string]$Language = 'EN'
    )
    Begin {
        # Mapping between beaufort and windnames
        [pscustomobject]$windnames = @{
            0 = @{ 
                EN = 'Calm'
                IT = 'Calma'
                FR = 'Calme'
                DE = 'WindStille'
                NL = 'Stil'
            }
            1 = @{
                EN = 'Light air'
                IT = 'Bava di vento'
                FR = 'Très légère brise'
                DE = 'Leichter Zug'
                NL = 'Zeer zwak'
            }
            2 = @{
                EN = 'Light breeze'
                IT = 'Brezza leggera'
                FR = 'Légère brise'
                DE = 'Leichte Brise'
                NL = 'Zwak'
            }
            3 = @{
                EN = 'Gentle breeze'
                IT = 'Brezza testa'
                FR = 'Petite brise'
                DE = 'Schwache Brise'
                NL = 'Vrij matig'
            }
            4 = @{
                EN = 'Moderate breeze'
                IT = 'Vento moderato'
                FR = 'Jolie brise'
                DE = 'Mäßige Brise'
                NL = 'Matig'
            }
            5 = @{
                EN = 'Fresh breeze'
                IT = 'Vento teso'
                FR = 'Bonne brise'
                DE = 'Frische Brise'
                NL = 'Vrij krachtig'
            }
            6 = @{ 
                EN = 'Strong breeze'
                iT = 'Vento fresco'
                FR = 'Vent frais'
                DE = 'Starker Wind'
                NL = 'Krachtig'
            }
            7 = @{
                EN = 'Near gale'
                IT = 'Vento forte'
                FR = 'Grand frais'
                DE = 'Steifer Wind'
                NL = 'Hard'
            }
            8 = @{
                EN = 'Gale'
                IT = 'Burrasca'
                FR = 'Coup de vent'
                DE = 'Stürmischer Wind'
                NL = 'Stormachtig'
            }
            9 = @{
                EN = 'Strong gale'
                IT = 'Burrasca forte'
                FR = 'Fort coup de vent'
                DE = 'Sturm'
                NL = 'Storm'
            }
            10 = @{
                EN = 'Storm'
                IT = 'Tempesta'
                FR = 'Tempête'
                DE = 'Schwerer Sturm'
                NL = 'Zware storm'
            }
            11 = @{ 
                EN = 'Violent storm'
                IT = 'Fortunale'
                FR = 'Violent tempête'
                DE = 'Orkanartiger Sturm'
                NL = 'Orkaanachtig'
            }
            12 = @{
                EN = 'Hurricane'
                IT = 'Uragano'
                FR = 'Ouragan'
                DE = 'Orkan'
                NL = 'Orkaan'
            }
        }
    }

    Process {
        Write-Verbose "working on $speed m/s"
        # Determine beaufort based on ms
        $windforce = switch ($speed) {
            {$_ -lt 0.3} { 0 }
            {($_ -ge 0.3) -and ($_ -le 1.5)} { 1 }
            {($_ -ge 1.6) -and ($_ -le 3.3)} { 2 }
            {($_ -ge 3.4) -and ($_ -le 5.4)} { 3 }
            {($_ -ge 5.5) -and ($_ -le 7.9)} { 4 }
            {($_ -ge 8) -and ($_ -le 10.7)} { 5 }
            {($_ -ge 10.8) -and ($_ -le 13.8)} { 6 }
            {($_ -ge 13.9) -and ($_ -le 17.1)} { 7 } 
            {($_ -ge 17.2) -and ($_ -le 20.7)} { 8 }
            {($_ -ge 20.8) -and ($_ -le 24.4)} { 9 }
            {($_ -ge 24.5) -and ($_ -le 28.4)} { 10 }
            {($_ -ge 28.5) -and ($_ -le 32.6)} { 11 }
            {$_ -ge 32.7} { 12 }
            default { 'NA','NA','NA','NA' }
        }

        Write-Verbose "Printing in choosen language: $Language"
        # Create hastable to return
        [PSCustomObject]$result = @{
            Beaufort = $windforce
            Name = $windnames[$windforce].($Language)
        }

        # Return results as hashtable
        return $result
    }
}

# Calculate windspeed in meter per second
function Convert-Windspeed {
    param (
        [Parameter(Mandatory=$True,HelpMessage="Enter Windspeed in MPH")]
        [float]$windspeed,
        # Language to use for the output of the wind force
        [string]$Language = 'EN'
    )

    # Calculate mph2ms
    $ms = [math]::Round(($windspeed * 0.44704),1)
    # Calculate mph2kph
    $kph = [math]::Round(($windspeed * 1.609344),1)
    # Get Windspeed in Beaufort and name
    $windforce = Get-WindForce -Speed $ms -Language $Language

    [pscustomobject]$result = @{
        mph = $windspeed
        ms = $ms
        kph = $kph
        beaufort = $windforce['Beaufort']
        name = $windforce['Name']
    }

    # Return result
    return $result
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
Export-ModuleMember -Function Convert-RawData
Export-ModuleMember -Function Convert-Farenheit2Celcius
Export-ModuleMember -Function Convert-Pressure2hPa
Export-ModuleMember -Function Convert-Rainrate2mmh
Export-ModuleMember -Function Get-WindForce
Export-ModuleMember -Function Convert-Windspeed
Export-ModuleMember -Function Get-WindDirection
Export-ModuleMember -Function Get-Dewpoint
Export-ModuleMember -Function Get-Windchill
Export-ModuleMember -Function Get-HeatIndex