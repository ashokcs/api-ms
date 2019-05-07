$azureAccountName = $env:AZURE_ACCOUNT_NAME
$azurePassword = ConvertTo-SecureString $env:AZURE_ACCOUNT_PASSWORD -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name Az -AllowClobber -SkipPublisherCheck

$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
Connect-AzAccount -Credential $psCred -Tenant $tenantId -ServicePrincipal


$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $env:RESOURCE_GROUP_NAME -ServiceName $env:SERVICE_NAME
Import-AzApiManagementApi -ApiId accounts-api -Context $ApiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "$pwd/bin/private/v1/accounts/swagger.json" -Path "/private/v1/account-management"
#Set-AzApiManagementApi -ApiId accounts-api -Context $ApiMgmtContext -Protocols @('https')

#Get-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId accounts-api -SaveAs "/Users/jorge/git/api/src/private/security_policy.xml"
Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId "accounts-api" -PolicyFilePath "$pwd/src/private/security_policy.xml"

#docker pull mcr.microsoft.com/powershell:6.2.0-alpine-3.8
#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli generate -i /local/src/private/v1/accounts.yaml -l swagger


#docker run --rm -v ${PWD}:/local swaggerapi/swagger-codegen-cli:2.4.5 generate -i src/private/v1/accounts.yaml -l swagger -o bin/private/v1/accounts