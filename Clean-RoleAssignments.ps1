# Clean up conflicting role assignments for AVD Storage Audit
# This script removes any existing role assignments that might conflict with deployment

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true, HelpMessage = "Resource group name")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force removal without confirmation")]
    [switch]$Force
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

Write-Status "🧹 Cleaning up conflicting role assignments for AVD Storage Audit..." "Info"

# Set subscription context
try {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Status "✅ Set subscription context: $SubscriptionId" "Success"
} catch {
    Write-Status "❌ Failed to set subscription context: $($_.Exception.Message)" "Error"
    exit 1
}

# Find managed identities related to AVD Storage
Write-Status "🔍 Finding AVD Storage related managed identities..." "Info"
try {
    $managedIdentities = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName | Where-Object { 
        $_.Name -like "*avd-storage*" -or 
        $_.Name -like "*AVDStorage*" -or 
        $_.Name -like "*id-avd*" 
    }
    
    if ($managedIdentities) {
        Write-Status "Found $($managedIdentities.Count) AVD Storage managed identities:" "Info"
        foreach ($identity in $managedIdentities) {
            Write-Status "  • $($identity.Name) (Principal ID: $($identity.PrincipalId))" "Info"
        }
    } else {
        Write-Status "ℹ️ No AVD Storage managed identities found in resource group" "Warning"
        Write-Status "This is normal if you haven't deployed the solution before" "Info"
        exit 0
    }
} catch {
    Write-Status "❌ Error finding managed identities: $($_.Exception.Message)" "Error"
    exit 1
}

# Find and clean up role assignments
$roleAssignmentsToRemove = @()

foreach ($identity in $managedIdentities) {
    Write-Status "🔍 Checking role assignments for: $($identity.Name)..." "Info"
    
    try {
        # Get role assignments for this managed identity in the resource group
        $roleAssignments = Get-AzRoleAssignment -ObjectId $identity.PrincipalId -Scope "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroupName" -ErrorAction SilentlyContinue
        
        foreach ($assignment in $roleAssignments) {
            if ($assignment.RoleDefinitionName -eq "Contributor") {
                $roleAssignmentsToRemove += @{
                    Identity = $identity.Name
                    AssignmentId = $assignment.RoleAssignmentId
                    RoleName = $assignment.RoleDefinitionName
                    Scope = $assignment.Scope
                }
                Write-Status "Found conflicting role assignment: $($assignment.RoleDefinitionName) for $($identity.Name)" "Warning"
            }
        }
    } catch {
        Write-Status "⚠️ Could not retrieve role assignments for $($identity.Name): $($_.Exception.Message)" "Warning"
    }
}

if ($roleAssignmentsToRemove.Count -eq 0) {
    Write-Status "✅ No conflicting role assignments found!" "Success"
    Write-Status "You can proceed with deployment." "Info"
    exit 0
}

# Display what will be removed
Write-Status "" "Info"
Write-Status "📋 Found $($roleAssignmentsToRemove.Count) role assignments that may conflict:" "Warning"
foreach ($assignment in $roleAssignmentsToRemove) {
    Write-Status "  • $($assignment.RoleName) for $($assignment.Identity)" "Warning"
    Write-Status "    Scope: $($assignment.Scope)" "Info"
}

# Confirm removal
if (-not $Force) {
    Write-Status "" "Info"
    $confirm = Read-Host "Do you want to remove these role assignments? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Status "❌ Operation cancelled by user" "Warning"
        Write-Status "💡 You can run with -Force to skip confirmation" "Info"
        exit 0
    }
}

# Remove role assignments
Write-Status "" "Info"
Write-Status "🗑️ Removing conflicting role assignments..." "Info"

$successCount = 0
$errorCount = 0

foreach ($assignment in $roleAssignmentsToRemove) {
    try {
        Remove-AzRoleAssignment -RoleAssignmentId $assignment.AssignmentId | Out-Null
        Write-Status "✅ Removed: $($assignment.RoleName) for $($assignment.Identity)" "Success"
        $successCount++
    } catch {
        Write-Status "❌ Failed to remove $($assignment.RoleName) for $($assignment.Identity): $($_.Exception.Message)" "Error"
        $errorCount++
    }
}

Write-Status "" "Info"
if ($errorCount -eq 0) {
    Write-Status "🎉 Successfully removed all $successCount conflicting role assignments!" "Success"
    Write-Status "✅ You can now proceed with deployment" "Success"
} else {
    Write-Status "⚠️ Removed $successCount role assignments, but $errorCount failed" "Warning"
    Write-Status "You may need to manually remove the remaining assignments in the Azure portal" "Warning"
}

Write-Status "" "Info"
Write-Status "💡 Next steps:" "Info"
Write-Status "1. Run your deployment script again" "Info"
Write-Status "2. If you still get role assignment errors, wait 2-3 minutes and try again" "Info"
Write-Status "3. Check the troubleshooting guide for additional solutions" "Info"
