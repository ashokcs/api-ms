$ErrorActionPreference = "Stop"

#Datos para conectarse a azure
$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

#Datos para azure active directory
$b2cTenantId = $env:AZURE_B2C_TENANT_ID
$authUrl = $env:AUTH_URL
$userFlowNameWebPay = $env:WEBPAY_USER_FLOW_NAME
$clientIdWebpay = $env:WEBPAY_CLIENT_ID
$tenantName = $env:AZURE_TENANT_NAME

#Ip Servicio customer-authentication-ms
$customerAuthenticationIp = $env:CUSTOMER_AUT_IP
#Subscription key 
$customerAuthSubscriptionKey1 = $env:CUSTOMER_AUT_SUBSCRIPTION_PRIMARY_KEY
$customerAuthSubscriptionKey2 = $env:CUSTOMER_AUT_SUBSCRIPTION_SECONDARY_KEY


$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
$null = Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal

function Import-Secure-Api {
    param([Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementContext] $context,
          [string] $msName, [string] $apiId, [string] $path, [string] $sufix, [string] $serviceBase)
    "Importing secure API $msName"
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/$msName/swagger.json" -Path $sufix$path
    Set-AzApiManagementApi -ApiId $apiId -Context $context -Protocols @('https') -ServiceUrl $serviceBase$path -Name $api.Name
    Set-AzApiManagementPolicy -Context $context -ApiId $apiId -PolicyFilePath "$pwd/src/private/webpay_policy.xml"
    Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId $apiId
    Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId webpayapi -ApiId $apiId
}

function Import-Api {
    param([Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementContext] $context,
          [string] $msName, [string] $apiId, [string] $path, [string] $sufix, [string] $serviceBase, [string] $productId)
    "Importing API $msName"
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/$msName/swagger.json" -Path $sufix$path
    Set-AzApiManagementApi -ApiId $apiId -Context $context -Protocols @('https') -ServiceUrl $serviceBase$path -Name $api.Name
    Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId $apiId
    Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId $productId -ApiId $apiId
}

$rg = $env:RESOURCE_GROUP_NAME
$sn = $env:SERVICE_NAME

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $rg -ServiceName $sn
New-AzApiManagementProduct -Context $ApiMgmtContext -ProductId webpayapi -Title "Tenpo Webpay API" -Description "Tenpo Webpay API" -LegalTerms "Free for all"  -State "Published"

#Propiedades de Apis
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "authUrl" -Name "authUrl" -Value $authUrl
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "userFlowNameWebpay" -Name "userFlowNameWebpay" -Value $userFlowNameWebPay
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "clientIdWebPay" -Name "clientIdWebPay" -Value $clientIdWebpay

#Propiedad Servicio
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlCustomerAuthentication" -Name "urlCustomerAuthentication" -Value $customerAuthenticationIp":8080"

#Import public
Import-Api -context $ApiMgmtContext -msName "customerAuthentication" -ProductId webpayapi -sufix "/public" -path "/v1/customer-authentication" -apiId "customer-authentication-public-api" -serviceBase "http://$customerAuthenticationIp`:8080"

#Import private
Import-Secure-Api -context $ApiMgmtContext -msName "customerAuthentication" -ProductId webpayapi -sufix "/private" -path "/v1/customer-authentication" -apiId "customer-authentication-api" -serviceBase "http://$customerAuthenticationIp`:8080"

$null = Import-AzApiManagementApi -ApiId "appconfig" -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/appconfig/swagger.json" -Path "/public/v1/app"
Set-AzApiManagementApi -ApiId "appconfig" -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl "http://localhost:8080" -Name "AppConfig - Tenpo public API"

$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "appconfig" -PolicyFilePath "$pwd/src/public/appconfig_policy.xml"
$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "customer-authentication-api" -PolicyFilePath "$pwd/src/public/error_policy.xml"
$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "customer-authentication-public-api" -PolicyFilePath "$pwd/src/public/error_policy.xml"

Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId "appconfig"
Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId webpayapi -ApiId "appconfig"

Remove-AzApiManagementSubscription -Context $ApiMgmtContext -SubscriptionId "200001"
New-AzApiManagementSubscription -Context $ApiMgmtContext -Name "subscriptionCustomerAuthentication" -SubscriptionId "200001" -Scope "/apis"  -PrimaryKey $customerAuthSubscriptionKey1 -SecondaryKey $customerAuthSubscriptionKey2 -State "Active"


Set-AzApiManagementPolicy -Context $ApiMgmtContext -PolicyFilePath "$pwd/src/tenantpolicy.xml"

Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "customer-authentication-api" -PolicyFilePath "$pwd/src/private/webpay_policy.xml"