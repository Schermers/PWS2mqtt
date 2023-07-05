# Write Log function
function Write-Log {
    param(
        [string]$value
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm') | $($value)"
    # Write log to file
    if($env:EnableLog) {
        if(!(Test-Path -Path ".\Log")){
            New-Item ".\Log" -ItemType Directory
        }
        [pscustomobject]@{
            Date = (Get-Date -format 'yyyy-MM-dd')
            Time = (Get-Date -format 'HH:mm:ss')
            Script = $env:script
            Event = $value
        } | Export-Csv -Path ".\Log\$($env:script)_$(Get-Date -Format "yyyy-MM-dd").csv" -Delimiter ';' -Append -Encoding utf8 -NoTypeInformation
    }
}