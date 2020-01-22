Function ComputePassword {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    $aesManaged.GenerateKey()
    return [System.Convert]::ToBase64String($aesManaged.Key)
}

Function CreateAppKey($fromDate, $durationInYears, $pw) {  
    $testKey = GenerateAppKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw  
    $key = $testKey  
    return $key
}

Function GenerateAppKey ($fromDate, $durationInYears, $pw) {
    $endDate = $fromDate.AddYears($durationInYears) 
    $keyId = (New-Guid).ToString();
    $key = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential($null, $endDate, $keyId, $fromDate, $pw)
    return $key
}

Function AddResourcePermission($requiredAccess, $exposedPermissions, $requiredAccesses, $permissionType) {
    foreach ($permission in $requiredAccesses.Trim().Split(" ")) {
        $reqPermission = $null
        $reqPermission = $exposedPermissions | Where-Object {$_.Value -contains $permission}
        $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
        $resourceAccess.Type = $permissionType
        $resourceAccess.Id = $reqPermission.Id    
        $requiredAccess.ResourceAccess.Add($resourceAccess)
    }
}

Function GetRequiredPermissions($requiredApplicationPermissions, $reqsp) {
    $sp = $reqsp
    $appid = $sp.AppId
    $requiredAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $requiredAccess.ResourceAppId = $appid
    $requiredAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
    if ($requiredApplicationPermissions) {
        AddResourcePermission $requiredAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType "Role"
    }
    return $requiredAccess
}

function New-HbsADApplication ($displayName, $applicationPermissions) {    
    $pw = ComputePassword
    $fromDate = [System.DateTime]::Now
    $appKey = CreateAppKey -fromDate $fromDate -durationInYears 10 -pw $pw

    if ($null -ne $applicationPermissions) {
        $graphsp = Get-AzureADServicePrincipal -SearchString "Microsoft Graph"
        # $graphsp = Get-AzureADServicePrincipal -ObjectId "b19d498e-6687-4156-869a-2e8a95a9d659"
        $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
        $microsoftGraphRequiredPermissions = GetRequiredPermissions -reqsp $graphsp -requiredApplicationPermissions $applicationPermissions 
        $requiredResourcesAccess.Add($microsoftGraphRequiredPermissions)
    }
    
    $aadApplication = New-AzureADApplication -DisplayName $displayName `
                      -PasswordCredentials $appKey -AvailableToOtherTenants $true `
                      -RequiredResourceAccess $requiredResourcesAccess 

    New-AzureADServicePrincipal -AppId $aadApplication.AppId                      

    return @{app = $aadApplication 
             creds=$appKey}
}

#New-HbsADApplication -displayName "Arie Test 3" -applicationPermissions ("Directory.Read.All", "Group.Read.All","OnlineMeetings.ReadWrite.All")


