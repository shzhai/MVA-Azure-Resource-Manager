Switch-AzureMode -Name AzureResourceManager
Add-AzureAccount

#List role assignments in the subscription
Get-AzureRoleAssignment

#Check existing role assignments for a particular role definition, at a particular scope to a particular user
Get-AzureRoleAssignment -ResourceGroupName {ResourceGroupName} -Mail {EmailAddress} -RoleDefinitionName Owner

#List the supported role definitions
Get-AzureRoleDefinition

#This will create a role assignment at a resource group level
New-AzureRoleAssignment -Mail {EmailAddress} -RoleDefinitionName Contributor -ResourceGroupName {ResourceGroupName}



#This will create a role assignment for a group at a resource group level
#Service Principal can be a Application User or User Group ID
#For User or group can use Get-AzureADUser or Get-AzureADGroup; For Application ID can find from Client ID of the Applicaiton
New-AzureRoleAssignment -ObjectID {ServicePrincipalID} -RoleDefinitionName Reader -ResourceGroupName {ResourceGroupName}


#This will create a role assignment at a resource level
$resources = Get-AzureResource
New-AzureRoleAssignment -Mail{EmailAddress} -RoleDefinitionName Owner -Scope $resources[0].ResourceId
