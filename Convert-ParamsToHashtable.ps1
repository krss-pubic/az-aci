# Path to your parameters.json
$ParameterFile = "./parameters.json"

# Read JSON
$paramJson = Get-Content -Raw -Path $ParameterFile | ConvertFrom-Json

# Build a simple hashtable of parameterName -> value (extracting the .value field)
$paramsVnet = @{}
foreach ($p in $paramJson.parameters.PSObject.Properties.Name) {
    $entry = $paramJson.parameters.$p
    $paramsVnet[$p] = if ($entry -and $entry.PSObject.Properties.Name -contains 'value') { $entry.value } else { $entry }
}

# Recursive converter to PowerShell literal syntax
function Convert-ToPSLiteral {
    param($obj)

    if ($null -eq $obj) { return '$null' }

    # IDictionary / Hashtable / PSCustomObject -> @{ 'k' = v; ... }
    if ($obj -is [System.Collections.IDictionary] -or $obj -is [System.Management.Automation.PSCustomObject]) {
        $pairs = @()
        foreach ($prop in $obj.PSObject.Properties) {
            $k = $prop.Name -replace "'", "''"
            $v = Convert-ToPSLiteral $prop.Value
            $pairs += "'$k' = $v"
        }
        return "@{ " + ($pairs -join '; ') + " }"
    }

    # Arrays / Enumerables (but not string)
    if ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
        $items = @()
        foreach ($item in $obj) { $items += (Convert-ToPSLiteral $item) }
        return "@(" + ($items -join ', ') + ")"
    }

    # Booleans
    if ($obj -is [bool]) { return ($obj ? '$true' : '$false') }

    # Numbers
    if ($obj -is [int] -or $obj -is [long] -or $obj -is [double] -or $obj -is [decimal]) { return $obj.ToString() }

    # Fallback: string (escape single quotes)
    $s = [string]$obj
    $s = $s -replace "'", "''"
    return "'$s'"
}

# Produce the PowerShell hashtable literal and output
$literal = '$paramsVnet = ' + (Convert-ToPSLiteral $paramsVnet)
Write-Output $literal