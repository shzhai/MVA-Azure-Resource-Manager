Switch-AzureMode -Name AzureResourceManager

Add-Type -Path C:\Users\SHZHAI~1.FAR\AppData\Local\Temp\Microsoft.IdentityModel.Clients.ActiveDirectory.2.19.208020213\lib\net45\Microsoft.IdentityModel.Clients.ActiveDirectory.dll


$tenantId = 'ac285bf5-84a9-41a4-a3a4-98373d435130'
$clientId = 'ccb25700-c585-4342-9332-8aeb3359e052'

$subscriptionId = Get-AzureSubscription -Current | Select-Object -ExpandProperty SubscriptionId
 
$authUrl = "https://login.windows.net/$tenantId"
# $secpasswd = ConvertTo-SecureString -String $spa -AsPlainText -Force 


$AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]$authUrl

$result = $AuthContext.AcquireToken("https://management.core.windows.net/",$clientId,[Uri]"http://ARMApp",[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto)

 
 
$authHeader = @{
'Content-Type'='application\json'
'Authorization'=$result.CreateAuthorizationHeader()
}

$JWT = $authHeader.Authorization | Out-File $env:TEMP\JWTToken.txt

$allProviders = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers?api-version=2015-01-01" -Headers $authHeader -Method Get -Verbose).Value
$allProviders | ? {$_.id -match 'search'} | Select-Object id,registrationState

$computeProvider = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers/Microsoft.classicCompute?api-version=2015-01-01" -Headers $authHeader -Method Get -Verbose)

Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers/Microsoft.Search/register?api-version=2015-01-01" -Method Post -Headers $authHeader -Verbose

(Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers?api-version=2015-01-01" -Headers $authHeader -Method Get -Verbose).Value | ? {$_.id -match 'search'} | Select-Object id,registrationState
