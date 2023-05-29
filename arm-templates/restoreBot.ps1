param ($secret, $baseUrl, $hbsRestoreFile)

Add-Type -AssemblyName System.Security

Function Get-HMACSHA512 {
    param(
        [Parameter(Mandatory = $true)][String]$data
        , [Parameter(Mandatory = $true)][String]$key
    )
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256  
    $hmacsha.key = [Text.Encoding]::UTF8.GetBytes($key)
    $bytesToSign = [Text.Encoding]::UTF8.GetBytes($data)
    $sign = $hmacsha.ComputeHash($bytesToSign)
    return $sign
}

Function Get-Base64UrlEncodeFromByteArray {
    param(
        [Parameter(Mandatory = $true)][byte[]]$byteArray
    )
    # Special "url-safe" base64 encode.
    $base64 = [System.Convert]::ToBase64String($byteArray, [Base64FormattingOptions]::None).Replace('+', '-').Replace('/', '_').Replace("=", "")
    return $base64
}

Function Get-Base64UrlEncodeFromString {
    param(
        [Parameter(Mandatory = $true)][String]$inputString
    )
    $inputBytes = [Text.Encoding]::UTF8.GetBytes($inputString)
    
    # Special "url-safe" base64 encode.
    $base64 = [System.Convert]::ToBase64String($inputBytes, [Base64FormattingOptions]::None).Replace('+', '-').Replace('/', '_').Replace("=", "")
    return $base64
}

Function New-Jwt {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Specialized.OrderedDictionary]$headers
        , [Parameter(Mandatory = $true)][System.Collections.Specialized.OrderedDictionary]$payload
        , [Parameter(Mandatory = $true)][string]$secret
    )
    $headersJson = $headers | ConvertTo-Json -Compress 
    $payloadJson = $payload | ConvertTo-Json -Compress
    $headersEncoded = Get-Base64UrlEncodeFromString -inputString $headersJson #[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($headersJson),[Base64FormattingOptions]::None)
    $payloadEncoded = Get-Base64UrlEncodeFromString -inputString $payloadJson #[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($payloadJson),[Base64FormattingOptions]::None)

    $content = "$( $headersEncoded ).$( $payloadEncoded )"

    $signatureByte = Get-HMACSHA512 -data $content -key $secret
    $signature = Get-Base64UrlEncodeFromByteArray -byteArray $signatureByte

    $jwt = "$( $headersEncoded ).$( $payloadEncoded ).$( $signature )"
    return $jwt
}

$tenantName = Split-Path -Path $baseUrl -Leaf
$DateTime = Get-Date 
$epoch = ([DateTimeOffset]$DateTime).ToUnixTimeSeconds()

$headers = [ordered]@{
    "alg" = "HS256"    
    "typ" = "JWT"
}

$payload = [ordered]@{
    "tenantName" = $tenantName
    "iat"        = $epoch
}

$botTemplate = Invoke-WebRequest `
    -Uri $hbsRestoreFile `
    -Method "get" 

$botTemplateString = [System.Text.Encoding]::UTF8.GetString($botTemplate.Content)

$jwtToken = New-Jwt -headers $headers -payload $payload -secret $secret

$apiUrl = $baseUrl.Replace('/account', '/api/account') + '/backup'

$headers = @{
    Authorization = 'Bearer ' + $jwtToken
}

# replace env varibles placeholders in template with its actual value by using ExpandEnvironmentVariables
# and convert to json
$body = @{
    hbs = $botTemplateString.TrimEnd() | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) } 
} | ConvertTo-Json -Depth 5

$result = Invoke-WebRequest -Uri $apiUrl `
    -Method "post" `
    -Headers $headers `
    -ContentType "application/json; charset=utf-8" `
    -Body $body

write-host $result