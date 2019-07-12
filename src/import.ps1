$ErrorActionPreference = "Stop"

$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

$usersIp = $env:USERS_IP
$launchIp = $env:LAUNCH_IP
$accountsIp = $env:ACCOUNT_IP
$identityproviderIp = $env:IDENTITPROVIDER_IP
$transactionsIp = $env:TRANSACTIONS_IP
$notificationsIp = $env:NOTIFICATION_IP
$paymentsIp = $env:PAYMENTS_IP
$paymentsKycIp = $env:PAYMENTSKYC_IP
$cardsIp = $env:CARDS_IP
$apiPrepaidIp = $env:API_PREPAID
$utilityPaymentsIp = $env:API_UTILITY_PAYMENT
$paymentsTopUpIp = $env:API_PAYMENTS_TOPUP

$b2cTenantId = $env:AZURE_B2C_TENANT_ID
$authUrl = $env:AUTH_URL
$userFlowName = $env:USER_FLOW_NAME
$clientId = $env:CLIENT_ID
$tenantName = $env:AZURE_TENANT_NAME

$userSubscriptionKey = $env:USER_SUBSCRIPTION_KEY
$PaymentSubscriptionKey = $env:PAYMENT_SUBSCRIPTION_KEY

$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
$null = Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal

function Import-Secure-Api {
    param([Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementContext] $context,
          [string] $msName, [string] $apiId, [string] $path, [string] $sufix, [string] $serviceBase)
    "Importing secure API $msName"
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/$msName/swagger.json" -Path $sufix$path
    Set-AzApiManagementApi -ApiId $apiId -Context $context -Protocols @('https') -ServiceUrl $serviceBase$path -Name $api.Name
    Set-AzApiManagementPolicy -Context $context -ApiId $apiId -PolicyFilePath "$pwd/src/private/security_policy.xml"
    Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId $apiId
    Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId tenpoapi -ApiId $apiId
}

function Import-Secure-Api-OpenApi {
    param([Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementContext] $context,
          [string] $msName, [string] $apiId, [string] $path, [string] $prefix, [string] $serviceBase)
    "Importing secure API $msName - OpenAPI"
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "OpenApi" -SpecificationPath "$pwd/src/private/v1/$msName.yaml" -Path $prefix$path
    Set-AzApiManagementApi -ApiId $apiId -Context $context -Protocols @('https') -ServiceUrl $serviceBase$path -Name $api.Name
    Set-AzApiManagementPolicy -Context $context -ApiId $apiId -PolicyFilePath "$pwd/src/private/security_policy.xml"
    Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId $apiId
    Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId tenpoapi -ApiId $apiId
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

#function Import-Api-Subscription {
#    param([Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementContext] $context,
#          [string] $msName, [string] $apiId, [string] $path, [string] $sufix, [string] $serviceBase)
#    "Importing API $msName"
#    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/$msName/swagger.json" -Path $sufix$path
#    Set-AzApiManagementApi -ApiId $apiId -Context $context -Protocols @('https') -ServiceUrl $serviceBase$path -Name $api.Name -SubscriptionRequired
#    Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId $apiId
#    Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId tenpoapiSubscription -ApiId $apiId
#}

$rg = $env:RESOURCE_GROUP_NAME
$sn = $env:SERVICE_NAME

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $rg -ServiceName $sn
New-AzApiManagementProduct -Context $ApiMgmtContext -ProductId tenpoapi -Title "Tenpo API" -Description "Tenpo API" -LegalTerms "Free for all" -SubscriptionRequired $False -State "Published"
New-AzApiManagementProduct -Context $ApiMgmtContext -ProductId tenpoapiSubscription -Title "Tenpo API Subscription" -Description "Tenpo API Subscription" -LegalTerms "Free for all"  -State "Published"

#Set-AzApiManagementProduct -Context $ApiMgmtContext -ProductId unlimited -SubscriptionRequired $False
#Set-AzApiManagementSubscription -Context $ApiMgmtContext -SubscriptionId -0123456789 -PrimaryKey "80450f7d0b6d481382113073f67822c1" -SecondaryKey "97d6112c3a8f48d5bf0266b7a09a761c" -State "Active"

$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlUsers" -Name "urlUsers" -Value $usersIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlAccounts" -Name "urlAccounts" -Value $accountsIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlTransactions" -Name "urlTransactions" -Value $transactionsIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlIdentityProvider" -Name "urlIdentityProvider" -Value $identityproviderIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlNotifications" -Name "urlNotifications" -Value $notificationsIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlPaymentskyc" -Name "urlPaymentskyc" -Value $paymentsKycIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlPayments" -Name "urlPayments" -Value $paymentsIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlCards" -Name "urlCards" -Value $cardsIp":8080"
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlApiPrepaid" -Name "urlApiPrepaid" -Value $apiPrepaidIp
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlUtilityPaymentsIp" -Name "urlUtilityPaymentsIp" -Value $utilityPaymentsIp
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlPaymentsTopUpIp" -Name "urlPaymentsTopUpIp" -Value $paymentsTopUpIp

$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "authUrl" -Name "authUrl" -Value $authUrl
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "userFlowName" -Name "userFlowName" -Value $userFlowName
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "clientId" -Name "clientId" -Value $clientId
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "tenantId" -Name "tenantId" -Value $b2cTenantId
$null = New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "tenantName" -Name "tenantName" -Value $tenantName

Import-Secure-Api -context $ApiMgmtContext -msName "accountsAndTransactions" -sufix "/private" -path "/v1/account-management" -apiId "accounts-api" -serviceBase "http://$accountsIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "devices" -sufix "/private" -path "/v1/device-management" -apiId "devices-api" -serviceBase "http://$usersIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "identityprovider" -sufix "/private" -path "/v1/provider/users" -apiId "identityprovider-api" -serviceBase "http://$identityproviderIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "notifications" -sufix "/private" -path "/v1/customer-management" -apiId "notifications-api" -serviceBase "http://$notificationsIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "paymentkyc" -sufix "/private" -path "/v1/payments-kyc" -apiId "paymentkyc-api" -serviceBase "http://$paymentsKycIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "payments" -sufix "/private" -path "/v1/sales-services" -apiId "payments-api" -serviceBase "http://$paymentsIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "users" -sufix "/private" -path "/v1/user-management" -apiId "users-api" -serviceBase "http://$usersIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "cards" -sufix "/private" -path "/v1/cards-management" -apiId "cards-api" -serviceBase "http://$cardsIp`:8080"
Import-Secure-Api -context $ApiMgmtContext -msName "utilityPayments" -sufix "/private" -path "/v1/utility-payments" -apiId "utility-payments-api" -serviceBase "https://$utilityPaymentsIp"

Import-Secure-Api-OpenApi -context $ApiMgmtContext -msName "paymentsTopUp" -prefix "/private" -path "/v1/topup" -apiId "payments-topup-api" -serviceBase "https://$paymentsTopUpIp"

Import-Api -context $ApiMgmtContext -msName "users" -ProductId tenpoapi -path "/v1/user-management" -sufix "/public" -apiId "users-public-api" -serviceBase "http://$usersIp`:8080"
Import-Api -context $ApiMgmtContext -msName "launch" -ProductId tenpoapi -path "/v1/launch" -sufix "/public" -apiId "launch-public-api" -serviceBase "http://$launchIp`:8080"
Import-Api -context $ApiMgmtContext -msName "onboarding"-ProductId tenpoapi  -path "/v1/onboarding" -sufix "/public" -apiId "onboarding-public-api" -serviceBase "http://$usersIp`:8080"
#Import-Api -context $ApiMgmtContext -msName "payments" -path "/v1/integration/payment/cl/on-site" -sufix "/public" -apiId "payments-public-api" -serviceBase "http://$paymentsIp`:8080"
#Import-Api -context $ApiMgmtContext -msName "validateUsers" -path "/v1/webhook-user-management/" -sufix "/public" -apiId "webhook-user-api" -serviceBase "http://$usersIp`:8080"
Import-Api -context $ApiMgmtContext -msName "payments" -ProductId tenpoapiSubscription -path "/v1/integration/payment/cl/on-site" -sufix "/public" -apiId "payments-public-api" -serviceBase "http://$paymentsIp`:8080"
Import-Api -context $ApiMgmtContext -msName "validateUsers" -ProductId tenpoapiSubscription -path "/v1/webhook-user-management/" -sufix "/public" -apiId "webhook-user-api" -serviceBase "http://$usersIp`:8080"

Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId tenpoapi -ApiId payments-public-api
Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId tenpoapi -ApiId webhook-user-api

$null = Import-AzApiManagementApi -ApiId "appconfig" -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/appconfig/swagger.json" -Path "/public/v1/app"
Set-AzApiManagementApi -ApiId "appconfig" -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl "http://localhost:8080" -Name "AppConfig - Tenpo public API"
$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "appconfig" -PolicyFilePath "$pwd/src/public/appconfig_policy.xml"
$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "payments-public-api" -PolicyFilePath "$pwd/src/public/error_policy.xml"
$null = Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "webhook-user-api" -PolicyFilePath "$pwd/src/public/error_policy.xml"
Remove-AzApiManagementApiFromProduct -Context $ApiMgmtContext -ProductId unlimited -ApiId "appconfig"
Add-AzApiManagementApiToProduct -Context $ApiMgmtContext -ProductId tenpoapi -ApiId "appconfig"

Remove-AzApiManagementSubscription -Context $ApiMgmtContext -SubscriptionId "123456"
Remove-AzApiManagementSubscription -Context $ApiMgmtContext -SubscriptionId "123457"
New-AzApiManagementSubscription -Context $ApiMgmtContext -Name "subscriptionPaymentPublic" -SubscriptionId "123456" -Scope "/apis/payments-public-api"  -PrimaryKey $PaymentSubscriptionKey -SecondaryKey "97d6112c3a8f48d5bf0266b7a09a763c" -State "Active"
New-AzApiManagementSubscription -Context $ApiMgmtContext -Name "subscriptionUserPublic" -SubscriptionId "123457" -Scope "/apis/webhook-user-api"  -PrimaryKey $userSubscriptionKey -SecondaryKey "97d6112c3a8f48d5bf0266b7a09a764c" -State "Active"

Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "accounts-api" -OperationId "listTransactionsUsingGET" -PolicyFilePath "$pwd/src/private/transaction_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "accounts-api" -OperationId "generateCodeUsingPOST" -PolicyFilePath "$pwd/src/private/transaction_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "cards-api" -OperationId "getCardDetailByUserIdUsingGET" -PolicyFilePath "$pwd/src/private/cards_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "launch-public-api" -OperationId "processIdentityValidationIntentUsingPOST" -PolicyFilePath "$pwd/src/public/launch_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -PolicyFilePath "$pwd/src/tenantpolicy.xml"

#Get-AzApiManagementOperation -Context $ApiMgmtContext -ApiId "account-api"
#Get-AzApiManagementApi -Context $ApiMgmtContext
#Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
#Install-Module -Name Az -AllowClobber -SkipPublisherCheck
#$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName tenpo_uat -ServiceName tenpo-uat-api-management
#Get-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId accounts-api -SaveAs "/Users/jorge/git/api/src/private/security_policy.xml"
#docker pull mcr.microsoft.com/powershell:6.2.0-alpine-3.8
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate -i /local/src/private/v1/accounts.yaml -l swagger
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli:2.4.5 generate -i src/private/v1/accounts.yaml -l swagger -o bin/private/v1/accounts
#docker run --rm -v ${PWD}:/local -w /local -e AZURE_B2C_TENANT_ID=cae09fee-473e-48e2-99dc-3b7bf4a97411 -e USERS_IP=172.11.0.129 -e ACCOUNT_IP=172.11.0.131 -e IDENTITPROVIDER_IP=172.11.0.133 -e TRANSACTIONS_IP=172.11.0.137 -e NOTIFICATION_IP=172.11.0.134 -e PAYMENTS_IP=172.11.0.130 -e PAYMENTSKYC_IP=0.0.0.0 -e CARDS_IP=172.11.0.132 -e AUTH_URL=https://tenpodev2.b2clogin.com/ -e USER_FLOW_NAME=B2C_1_ROPC_mobile -e CLIENT_ID=5cba8f4d-b819-4903-a414-732dbd4b8378 -e AZURE_TENANT_NAME=uattenpo2.onmicrosoft.com -e AZURE_ACCOUNT_NAME=ef4b51f2-362c-481f-883d-5d69d5fce8d9 -e AZURE_ACCOUNT_PASSWORD=35c40102-7641-4576-8768-8c5eb449f665 -e AZURE_TENANT_ID=b8944bcc-fb75-44c3-b743-5ae9eb56b0fc -e RESOURCE_GROUP_NAME=tenpo_uat -e SERVICE_NAME=tenpo-uat-api-management jaxkodex/powershell-az pwsh /local/src/import.ps1