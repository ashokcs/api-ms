$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal

function Import-Secure-Api {
    param([string] $msName, [string] $apiId, [string] $path)
    $ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/$msName/swagger.json" -Path $path
    Set-AzApiManagementApi -ApiId accounts-api -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl $api.ServiceUrl -Name $api.Name
    Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId $apiId -PolicyFilePath "$pwd/src/private/security_policy.xml"
}

function Import-Api {
    param([string] $msName, [string] $apiId, [string] $path)
    $ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/$msName/swagger.json" -Path $path
    Set-AzApiManagementApi -ApiId accounts-api -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl $api.ServiceUrl -Name $api.Name
}

Import-Secure-Api -msName "accounts" -path "/private/v1/account-management" -apiId "accounts-api"
Import-Secure-Api -msName "devices" -path "/private/v1/device-management" -apiId "devices-api"
Import-Secure-Api -msName "identityprovider" -path "/private/v1/provider/users" -apiId "identityprovider-api"
Import-Secure-Api -msName "notifications" -path "/private/v1/customer-management" -apiId "notifications-api"
Import-Secure-Api -msName "paymentkyc" -path "/private/v1/payments-kyc" -apiId "paymentkyc-api"
Import-Secure-Api -msName "payments" -path "/private/v1/sales-services" -apiId "payments-api"
Import-Secure-Api -msName "transactions" -path "/private/v1/transaction-management" -apiId "transactions-api"
Import-Secure-Api -msName "users" -path "/private/v1/user-management" -apiId "users-api"

Import-Secure-Api -msName "users" -path "/public/v1/user-management" -apiId "users-public-api"
Import-Secure-Api -msName "onboarding" -path "/public/v1/onboarding" -apiId "onboarding-public-api"
Import-Secure-Api -msName "cards" -path "/public/v1/cards-management" -apiId "cards-public-api"

#Install-Module -Name Az -AllowClobber -SkipPublisherCheck
#$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName tenpo_uat -ServiceName tenpo-uat-api-management
#Get-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId accounts-api -SaveAs "/Users/jorge/git/api/src/private/security_policy.xml"
#docker pull mcr.microsoft.com/powershell:6.2.0-alpine-3.8
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate -i /local/src/private/v1/accounts.yaml -l swagger
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli:2.4.5 generate -i src/private/v1/accounts.yaml -l swagger -o bin/private/v1/accounts