# Deployment Troubleshooting Guide

This document provides solutions to common deployment issues with the AVD Storage Analytics solution.

## 🚀 Quick Fix: Use Simplified Infrastructure Template

**RECOMMENDED APPROACH**: Use the simplified infrastructure template that avoids PowerShell deployment script issues:

```powershell
# Test the deployment first
.\test-infrastructure-deployment.ps1 -ResourceGroupName "your-rg-name"

# Deploy the infrastructure
New-AzResourceGroupDeployment -ResourceGroupName "your-rg-name" -TemplateFile ".\AVD Workbook\deploy-avd-infrastructure.json" -TemplateParameterFile ".\AVD Workbook\deploy-avd-infrastructure.parameters.json"

# Configure permissions and diagnostic settings manually
.\Grant-ManagedIdentityPermissions.ps1 -ResourceGroupName "your-rg-name"
.\Deploy-AVD-DataCollection.ps1 -ResourceGroupName "your-rg-name" -WorkspaceName "AVDStorageAuditLAW"
```

---

## Common Issues and Solutions

### 1. "CannotSetResourceIdentity" Error

**Symptom:** Deployment fails with error mentioning managed identity cannot be set.

**Cause:** This typically occurs when:
- The deployment script requires a User-Assigned managed identity but the template is incorrectly configured
- Insufficient permissions to create or assign managed identities

**Solution:**
1. Ensure you have `User Access Administrator` or `Owner` role on the subscription
2. Verify the managed identity is correctly configured in the ARM template
3. Use the validation script first: `.\Validate-Deployment.ps1 -SubscriptionId <id> -ResourceGroupName <name> -WhatIf`

### 2. "InvalidCreateRoleAssignmentRequest" Error

**Symptom:** Deployment fails with error about role assignment scope mismatch.

**Cause:** The ARM template deployment is scoped to a resource group, but some role assignments require subscription-level scope.

**Solution:**
1. Ensure you have `User Access Administrator` or `Owner` role on the subscription
2. After successful deployment, run the permission script:
   ```powershell
   .\Grant-ManagedIdentityPermissions.ps1 -SubscriptionId <id> -ResourceGroupName <name>
   ```

### 3. "RoleAssignmentUpdateNotPermitted" Error

**Symptom:** Deployment fails with error "Tenant ID, application ID, principal ID, and scope are not allowed to be updated."

**Cause:** This occurs when trying to create a role assignment that conflicts with an existing one, often from a previous deployment attempt.

**Solution:**
1. **Clean up conflicting role assignments**:
   ```powershell
   .\Clean-RoleAssignments.ps1 -SubscriptionId <id> -ResourceGroupName <name>
   ```

2. **Wait 2-3 minutes** after cleanup for Azure to propagate the changes

3. **Retry the deployment**

4. **Alternative manual cleanup**: In Azure portal, go to Resource Group > Access control (IAM) > Role assignments, and remove any existing assignments for the AVD storage managed identity

### 4. "Insufficient Permissions" Error

**Symptom:** Deployment fails with permission-related errors.

**Required Permissions:**
- `Contributor` role on the resource group (minimum)
- `User Access Administrator` role on the subscription (for role assignments)
- Or `Owner` role on the subscription

**Solution:**
```powershell
# Check your current role assignments
Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id

# If insufficient, ask your Azure administrator to assign appropriate roles
```

### 3. Template Validation Errors

**Symptom:** ARM template validation fails before deployment.

**Solution:**
1. Ensure you're using the latest template version from GitHub
2. Check the template syntax using the validation script
3. Verify all required Azure resource providers are registered:

```powershell
# Register required resource providers
Register-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights
Register-AzResourceProvider -ProviderNamespace Microsoft.Insights
Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity
Register-AzResourceProvider -ProviderNamespace Microsoft.Authorization
```

### 4. PowerShell Module Issues

**Symptom:** Import errors or missing cmdlets.

**Solution:**
```powershell
# Install required modules
Install-Module Az.Accounts -Force -AllowClobber
Install-Module Az.Resources -Force -AllowClobber
Install-Module Az.Monitor -Force -AllowClobber
Install-Module Az.DesktopVirtualization -Force -AllowClobber
Install-Module Az.Storage -Force -AllowClobber
Install-Module Az.NetAppFiles -Force -AllowClobber

# Update to latest versions
Update-Module Az
```

### 5. Network/Connectivity Issues

**Symptom:** Cannot download template from GitHub or connect to Azure.

**Solution:**
1. Check internet connectivity
2. Verify corporate firewall/proxy settings
3. Use local template file instead of URI:

```powershell
# Download template locally first
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tvanroo/AVDStorageAudit/main/AVD%20Workbook/deploy-avd-data-collection.json" -OutFile ".\deploy-avd-data-collection.json"

# Deploy with local file (modify the script to use -TemplateFile instead of -TemplateUri)
```

### 6. Deployment Script Timeout

**Symptom:** Deployment script times out during execution.

**Causes:**
- Large number of AVD resources to process
- Network latency
- Azure API throttling

**Solution:**
1. The template includes a 30-minute timeout, which should be sufficient for most environments
2. If deployment times out, check the deployment logs in the Azure portal
3. Consider deploying in smaller batches by disabling some diagnostic categories temporarily

### 7. Log Analytics Workspace Issues

**Symptom:** Workspace creation fails or already exists errors.

**Solution:**
1. If workspace name conflicts, let the template generate a unique name (don't specify -WorkspaceName)
2. If you need to use an existing workspace, ensure it's in the same region as your resource group
3. Verify workspace isn't soft-deleted:

```powershell
# Check for soft-deleted workspaces
Get-AzOperationalInsightsDeletedWorkspace
```

## Validation Steps

Before deployment, always run:

```powershell
# 1. Validate your environment
.\Validate-Deployment.ps1 -SubscriptionId "<your-subscription-id>" -ResourceGroupName "<your-rg-name>" -WhatIf

# 2. Test with minimal deployment first
.\Deploy-AVD-DataCollection.ps1 -SubscriptionId "<your-subscription-id>" -ResourceGroupName "<test-rg-name>" -EnableHostPoolDiagnostics $false -EnableStorageDiagnostics $false -EnableANFDiagnostics $false
```

## Getting Help

1. Check the deployment logs in Azure portal > Resource Groups > Deployments
2. Enable verbose logging: `$VerbosePreference = "Continue"`
3. Review the deployment script output for specific error messages
4. Create an issue on the GitHub repository with:
   - Error message
   - PowerShell version (`$PSVersionTable`)
   - Azure PowerShell version (`Get-Module Az -ListAvailable`)
   - Deployment logs from Azure portal

## Monitoring Deployment Progress

```powershell
# Monitor deployment status
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName "<your-rg-name>" -Name "<deployment-name>"
$deployment.ProvisioningState

# Get detailed deployment operations
Get-AzResourceGroupDeploymentOperation -ResourceGroupName "<your-rg-name>" -DeploymentName "<deployment-name>"
```

## Post-Deployment Verification

After successful deployment:

1. Verify Log Analytics workspace is created and accessible
2. Check that diagnostic settings are configured for your AVD resources
3. Confirm data is flowing into the workspace (may take 5-15 minutes)
4. Import the provided workbooks to visualize the data

```powershell
# Verify deployment outputs
$deployment = Get-AzResourceGroupDeployment -ResourceGroupName "<your-rg-name>" -Name "<deployment-name>"
$deployment.Outputs
```
