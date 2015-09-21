<# Beginning in version 0.8.0, the Azure PowerShell installation includes more than 
one PowerShell module. You must explicitly decide whether to use the commands that are 
available in the Azure module or the Azure Resource Manager module.
#>
Switch-AzureMode -Name AzureResourceManager

Get-Command -Module AzureResourceManager | Get-Help | Format-Table Name, Synopsis

# Add Your Azure account
Add-AzureAccount

# Make sure Current Subscription support Azure Resource Manager Mode
# Get-AzureSubscription | Where-Object {$_.SupportedModes -imatch 'AzureResourceManager'}
(Get-AzureSubscription -Current).SupportedModes -imatch 'AzureResourceManage'

# Create a resource group
<# There are several ways to create a resource group and its resources, 
but the easiest way is to use a resource group template. 
A resource group template is JSON string that defines the resources in a resource group. 
The string includes placeholders called "parameters" for user-defined values, like names and sizes.
Azure hosts a gallery of resource group templates and you can create your own templates, 
either from scratch or by editing a gallery template. 
To see all of the templates in the Azure resource group template gallery, 
use the Get-AzureResourceGroupGalleryTemplate cmdlet by specify a publisher parameter. 
#>
Get-AzureResourceGroupGalleryTemplate -Publisher Microsoft

# Select and get a gallery template
## Get Azure resources template through the Azure Resource Manager with community contributed templates.
# http://azure.microsoft.com/en-us/documentation/templates/
# https://github.com/Azure/azure-quickstart-templateshttps://github.com/Azure/azure-quickstart-templates
$DemoPath = 'C:\Users\shzhai.FAREAST\Desktop\MVA TBD\Azure Resource Manager'
$DemoTempalteId = (Get-AzureResourceGroupGalleryTemplate -Publisher Microsoft -AllVersions | ? {$_.Identity -imatch 'Microsoft.WebSiteSQLDatabase'} | Sort-Object -Descending )[0].Identity
$DemoTempalte = Get-AzureResourceGroupGalleryTemplate -Identity $DemoTempalteId
$DemoTemplateFile = $DemoTempalte | Save-AzureResourceGroupGalleryTemplate -Path "$DemoPath\New-WebNDB.json" -Force

<# When you run the command, the version of the template may be slightly different because a new version has been released. 
Use the latest version of the template. To get more information about a gallery template, 
use the Identity parameter. The value of the Identity parameter is Identity of the template. 
#>

# Examine the Template we download 
# Noticed template Schema based from https://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json
# We will Explorer three mainly sections which are ("parameters","resources","dependsOn" )

# Get resource type locations
<# Most templates ask you to specify a location for each of the resources in a resource group. 
Every resource is located in an Azure data center, but not every Azure data center supports every resource type. 
Select any location that supports the resource type. 
You do not have to create all of the resources in a resource group in the same location; however, whenever possible, 
you will want to create resources in the same location to optimize performance. 
In particular, you will want to make sure that your database is in the same location as the app accessing it. 
#>
Get-AzureLocation | Where-Object {$_.Name -eq "ResourceGroup"} | Format-Table Name, LocationsString -Wrap

# Create a resource group
## The template file can be very helpful for determining parameter values to pass, such as the correct ApiVersion for a resource.
<# $SecPWD = $(Read-Host -AsSecureString)
$DemoParam = @{"newStorageAccountName"="demostorageaccount";"newDomainName"="TestDomain";"Hostname"="TestRGVM1";`
"vmlocation"="East Asia";"newVirtualNetworkName"="TestVN";"vnetAddressSpace"="192.168.0.0";`
"userName"="shzhai";"password"="$SecPWD";"hardwareSize"="A2"} #>

$location = "East Asia"
$demositeName = "mvademoweb1"
# ApiVersion here meaning the Provider for this resouce version https://portal.azure.com/?l=zh-hans.zh-cn&r=1#blade/HubsExtension/BrowseAllBlade to find out
$hostingPlanName = "$demositeName"+"-hostingplan1"
$serverFarmResrouceGroupName = "Default-Web-MVADemo"
$testWebRG = "TestRG1"
$demohostingplan = @{"name"= "$hostingPlanName";"sku"="Free";"workersize"="0"}

if (Get-AzureResourceGroup -Name $testWebRG -ErrorAction SilentlyContinue) {Remove-AzureResourceGroup -Name $testWebRG  -Force}
if (Get-AzureResourceGroup -Name $serverFarmResrouceGroupName -ErrorAction SilentlyContinue) {Remove-AzureResourceGroup -Name $serverFarmResrouceGroupName -Force}

New-AzureResourceGroup -Name $serverFarmResrouceGroupName -Location $location
New-AzureResource -ApiVersion "2014-04-01" -Location $location -Name $hostingPlanName `
-ResourceGroupName $serverFarmResrouceGroupName -ResourceType Microsoft.Web/serverFarms `
-Properties $demohostingplan -Force -OutputObjectFormat New 

$DemoParam = @{"siteName"="$demositeName";"hostingPlanName"="$hostingPlanName";"serverFarmResourceGroup"="$serverFarmResrouceGroupName";`
"sitelocation"="$location";"serverName"="mvademodbserver1";`
"serverLocation"="$location";"administratorLogin"="shzhai";"databaseName"="DemoWebDB1"}


New-AzureResourceGroup -Name $testWebRG -location $location -TemplateFile $DemoTemplateFile.Path -TemplateParameterObject $DemoParam

Get-AzureResourceGroup -ResourceGroupName $testWebRG -ErrorAction Continue

New-AzureResource -Name mvademowebsite2 -Location "North Europe" -ResourceGroupName $testWebRG -ResourceType `
"Microsoft.Web/sites" -ApiVersion 2014-06-01 -PropertyObject @{"name" = "mvademowebsite2"; "siteMode"= "Limited"; `
"computeMode" = "Shared"} -Force -OutputObjectFormat New

Remove-AzureResource -Name mvademowebsite2  -ResourceGroupName $testWebRG -ResourceType "Microsoft.Web/sites" -ApiVersion 2014-06-01 -Force


# Use template based depolyment to easy deploy new website; Please be noted the sitelocation is part of hostingplan's location; so you can't define
# these two seperatly or you have to create a new hosting plan associate with the location you defined.
New-AzureResourceGroupDeployment -ResourceGroupName $testWebRG `
-GalleryTemplateIdentity Microsoft.WebSite.0.4.1 `
-siteName mvademowebsite2 `
-hostingPlanName $hostingPlanName `
-siteLocation $location `
-serverFarmResourceGroup $serverFarmResrouceGroupName 



# Reset Demo environment 
Get-AzureResourceGroup -ResourceGroupName $testWebRG | Remove-AzureResourceGroup -Force
Get-AzureResourceGroup -ResourceGroupName $serverFarmResrouceGroupName | Remove-AzureResourceGroup -Force

######################################################## Appendix:#########################################################################################3
#### 防止错误

### The AzureResourceManager module includes cmdlets that help you to prevent errors.

## Get-AzureLocation: 
# This cmdlet gets the locations that support each type of resource. 
# Before you enter a location for a resource, use this cmdlet to verify that the location supports the resource type.
## Test-AzureResourceGroupTemplate: 
# Test your template and template parameter before you use them. 
# Enter a custom or gallery template and the template parameter values you plan to use. 
# This cmdlet tests whether the template is internally consistent and whether your parameter value set matches the template. 

### 排除错误
## Get-AzureResourceGroupLog: 
# This cmdlet gets the entries in the log for each deployment of the resource group.
# If something goes wrong, begin by examining the deployment logs. 
## Verbose and Debug: 
# The cmdlets in the AzureResourceManager module call REST APIs that do the actual work. 
# To see the messages that the APIs return, set the $DebugPreference variable to "Continue" and use the Verbose common parameter in your commands. 
# The messages often provide vital clues about the cause of any failures.
## Your Azure credentials have not been set up or have expired: 
# To refresh the credentials in your Windows PowerShell session, 
# use the Add-AzureAccount cmdlet. 
# The credentials in a publish settings file are not sufficient for the cmdlets in the AzureResourceManager module.

 Get-AzureResourceGroupLog -ResourceGroup ExampleResourceGroup -Status Failed -DetailedOutput





## Browse Resouce Group and Resources from Portal 门户资源浏览器
# https://portal.azure.com/?l=zh-hans.zh-cn&r=1#blade/HubsExtension/BrowseAllBlade

## Create Azure Deploy Button on GitHub
# http://contoso.se/blog/?p=4142 
# http://www.bradygaster.com/post/the-deploy-to-azure-button
<# <img style="max-width:100%;" src="https://camo.githubusercontent.com/9285dd3998997a0835869065bb15e5d500475034/687474703a2f2f617a7572656465706c6f792e6e65742f6465706c6f79627574746f6e2e706e67" 
data-canonical-src="http://azuredeploy.net/deploybutton.png">
#>


## Authenticating Azure Resource Manager requests 
# https://msdn.microsoft.com/en-us/library/azure/dn790557.aspx
## Using Azure Resource Management REST API in PowerShell
# http://www.powershellmagazine.com/2014/12/24/using-azure-resource-management-rest-api-in-powershell/
## Developer’s guide to auth with Azure Resource Manager API 
# http://www.dushyantgill.com/blog/2015/05/23/developers-guide-to-auth-with-azure-resource-manager-api/

## Using Azure PowerShell with Azure Resource Manager
# https://azure.microsoft.com/en-us/documentation/articles/powershell-azure-resource-manager/

## Authoring Azure Resource Manager templates
# https://azure.microsoft.com/en-us/documentation/articles/resource-group-authoring-templates/

## Deploy an application with Azure Resource Manager template
# https://azure.microsoft.com/en-us/documentation/articles/resource-group-template-deploy/
