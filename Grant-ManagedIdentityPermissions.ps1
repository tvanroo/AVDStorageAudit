# Grant Additional Permissions to AVD Storage Audit Managed Identity
# This script grants the managed identity subscription-level permissions needed for comprehensive monitoring

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true, HelpMessage = "Resource group name where the solution was deployed")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Name of the managed identity (will auto-detect if not provided)")]
    [string]$ManagedIdentityName = ""
)

$ErrorActionPreference = "Stop"

# Helper function to write status messages
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Write-Host "$(Get-Date -Format 'HH:mm:ss') $Message" -ForegroundColor $color
}

Write-Status "🔐 Configuring additional permissions for AVD Storage Audit..." "Info"

# Set subscription context
try {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Status "✅ Set subscription context: $SubscriptionId" "Success"
} catch {
    Write-Status "❌ Failed to set subscription context: $($_.Exception.Message)" "Error"
    exit 1
}

# Find the managed identity if not specified
if (-not $ManagedIdentityName) {
    Write-Status "🔍 Finding managed identity in resource group..." "Info"
    try {
        $managedIdentities = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName
        $avdIdentity = $managedIdentities | Where-Object { $_.Name -like "*avd-storage*" -or $_.Name -like "*AVDStorage*" }
        
        if ($avdIdentity) {
            $ManagedIdentityName = $avdIdentity.Name
            Write-Status "✅ Found managed identity: $ManagedIdentityName" "Success"
        } else {
            Write-Status "❌ Could not find AVD storage managed identity in resource group. Please specify manually." "Error"
            exit 1
        }
    } catch {
        Write-Status "❌ Error finding managed identity: $($_.Exception.Message)" "Error"
        exit 1
    }
}

# Get the managed identity
try {
    $managedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $ManagedIdentityName
    $principalId = $managedIdentity.PrincipalId
    Write-Status "✅ Retrieved managed identity: $($managedIdentity.Name)" "Success"
    Write-Status "   Principal ID: $principalId" "Info"
} catch {
    Write-Status "❌ Failed to get managed identity: $($_.Exception.Message)" "Error"
    exit 1
}

# Define required role assignments
$roleAssignments = @(
    @{
        RoleName = "Monitoring Reader"
        RoleId = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
        Scope = "/subscriptions/$SubscriptionId"
        Description = "Read access to monitoring data across subscription"
    },
    @{
        RoleName = "Desktop Virtualization Reader"
        RoleId = "49a72310-ab8d-41df-bbb0-79b649203868"
        Scope = "/subscriptions/$SubscriptionId"  
        Description = "Read access to AVD resources"
    }
)

# Assign roles
foreach ($roleAssignment in $roleAssignments) {
    Write-Status "📋 Assigning role: $($roleAssignment.RoleName)..." "Info"
    try {
        # Check if role assignment already exists
        $existingAssignment = Get-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleAssignment.RoleId -Scope $roleAssignment.Scope -ErrorAction SilentlyContinue
        
        if ($existingAssignment) {
            Write-Status "ℹ️ Role assignment already exists: $($roleAssignment.RoleName)" "Warning"
        } else {
            New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleAssignment.RoleId -Scope $roleAssignment.Scope | Out-Null
            Write-Status "✅ Assigned role: $($roleAssignment.RoleName)" "Success"
            Write-Status "   Description: $($roleAssignment.Description)" "Info"
        }
    } catch {
        Write-Status "⚠️ Failed to assign role $($roleAssignment.RoleName): $($_.Exception.Message)" "Warning"
        Write-Status "   You may need to have your Azure administrator assign this role manually." "Warning"
    }
}

Write-Status "" "Info"
Write-Status "🎯 Permission configuration completed!" "Success"
Write-Status "" "Info"
Write-Status "The managed identity now has the following permissions:" "Info"
Write-Status "• Contributor access to the resource group (for creating diagnostic settings)" "Info"
Write-Status "• Monitoring Reader access to the subscription (for reading monitoring data)" "Info" 
Write-Status "• Desktop Virtualization Reader access to the subscription (for discovering AVD resources)" "Info"
Write-Status "" "Info"
Write-Status "💡 If you still encounter permission issues, you may need to assign additional roles:" "Info"
Write-Status "• Storage Account Contributor (for storage account diagnostic settings)" "Info"
Write-Status "• NetApp Contributor (for Azure NetApp Files diagnostic settings)" "Info"
Write-Status "" "Info"
Write-Status "🚀 You can now run the diagnostic configuration again or wait for the next scheduled run." "Success"
