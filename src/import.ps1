$ErrorActionPreference = "Stop"

$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal

function Import-Secure-Api {
    param([string] $msName, [string] $apiId, [string] $path)
    "Importing secure API $msName"
    $ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/$msName/swagger.json" -Path $path
    Set-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl $api.ServiceUrl -Name $api.Name
    Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId $apiId -PolicyFilePath "$pwd/src/private/security_policy.xml"
}

function Import-Api {
    param([string] $msName, [string] $apiId, [string] $path)
    "Importing API $msName"
    $ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/public/v1/$msName/swagger.json" -Path $path
    Set-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl $api.ServiceUrl -Name $api.Name
}

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
New-AzApiManagementProperty -Context $ApiMgmtContext -PropertyId "urlUsers" -Name "urlUsers" -Value "52.167.62.186:8080"

Import-Secure-Api -msName "accountsAndTransactions" -path "/private/v1/account-management" -apiId "accounts-api"
Import-Secure-Api -msName "devices" -path "/private/v1/device-management" -apiId "devices-api"
Import-Secure-Api -msName "identityprovider" -path "/private/v1/provider/users" -apiId "identityprovider-api"
Import-Secure-Api -msName "notifications" -path "/private/v1/customer-management" -apiId "notifications-api"
Import-Secure-Api -msName "paymentkyc" -path "/private/v1/payments-kyc" -apiId "paymentkyc-api"
Import-Secure-Api -msName "payments" -path "/private/v1/sales-services" -apiId "payments-api"
Import-Secure-Api -msName "users" -path "/private/v1/user-management" -apiId "users-api"
Import-Secure-Api -msName "cards" -path "/private/v1/cards-management" -apiId "cards-api"

Import-Api -msName "users" -path "/public/v1/user-management" -apiId "users-public-api"
Import-Api -msName "onboarding" -path "/public/v1/onboarding" -apiId "onboarding-public-api"
Import-Api -msName "appconfig" -path "/public/v1/app" -apiId "appconfig-public-api"

Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "accounts-api" -OperationId "listTransactionsUsingGET" -PolicyFilePath "$pwd/src/private/transaction_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "accounts-api" -OperationId "generateCodeUsingPOST" -PolicyFilePath "$pwd/src/private/transaction_policy.xml"

#Get-AzApiManagementOperation -Context $ApiMgmtContext -ApiId "account-api"
#Get-AzApiManagementApi -Context $ApiMgmtContext
#Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted  
#Install-Module -Name Az -AllowClobber -SkipPublisherCheck
#$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName tenpo_uat -ServiceName tenpo-uat-api-management
#Get-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId accounts-api -SaveAs "/Users/jorge/git/api/src/private/security_policy.xml"
#docker pull mcr.microsoft.com/powershell:6.2.0-alpine-3.8
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate -i /local/src/private/v1/accounts.yaml -l swagger
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli:2.4.5 generate -i src/private/v1/accounts.yaml -l swagger -o bin/private/v1/accounts
#docker run --rm -v ${PWD}:/local -w /local -e AZURE_ACCOUNT_NAME=ef4b51f2-362c-481f-883d-5d69d5fce8d9 -e AZURE_ACCOUNT_PASSWORD=35c40102-7641-4576-8768-8c5eb449f665 -e AZURE_TENANT_ID=b8944bcc-fb75-44c3-b743-5ae9eb56b0fc -e RESOURCE_GROUP_NAME=tenpo_uat -e SERVICE_NAME=tenpo-uat-api-management jaxkodex/powershell-az pwsh /local/src/import.ps1
