function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs = "" 
    return [String]$characters[$random]
}

function Get-HbsUniqueTenantId {
    param (
        $Name
    )
    $cleanName = ($Name -replace "[^a-zA-Z0-9_-]*", "").ToLower();
    $suffix = Get-RandomCharacters -length 7 -characters 'abcdefghiklmnoprstuvwxyz1234567890' 
    return "$cleanName-$suffix"
}

function New-ResourceGroupIfNeeded {
    param (
        $resourceGroup,
        $location
    )
    $rg = Get-AzResourceGroup -Name $resourceGroup -ErrorVariable noRg -ErrorAction SilentlyContinue
    if ($noRg) {
        $rg = New-AzResourceGroup -Name $resourceGroup -Location $location
    }    
    return $rg
}

