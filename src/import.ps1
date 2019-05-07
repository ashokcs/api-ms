$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
#Install-Module -Name Az -AllowClobber -SkipPublisherCheck

$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal

function Import-Api {
    param([string] $msName, [string] $apiId, [string] $path)
    $ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
    $api = Import-AzApiManagementApi -ApiId $apiId -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/$msName/swagger.json" -Path $path
    Set-AzApiManagementApi -ApiId accounts-api -Context $ApiMgmtContext -Protocols @('https') -ServiceUrl $api.ServiceUrl -Name $api.Name
    Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId $apiId -PolicyFilePath "$pwd/src/private/security_policy.xml"
}

ImportApi -msName "accounts" -path "/private/v1/account-management" -apiId "accounts-api"


#$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName tenpo_uat -ServiceName tenpo-uat-api-management
#Get-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId accounts-api -SaveAs "/Users/jorge/git/api/src/private/security_policy.xml"
#docker pull mcr.microsoft.com/powershell:6.2.0-alpine-3.8
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate -i /local/src/private/v1/accounts.yaml -l swagger
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli:2.4.5 generate -i src/private/v1/accounts.yaml -l swagger -o bin/private/v1/accounts