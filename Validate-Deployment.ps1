# Validate AVD Storage Analytics Deployment
# This script helps validate and troubleshoot deployment issues

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true, HelpMessage = "Resource group name")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Test deployment without actually deploying")]
    [switch]$WhatIf
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

Write-Status "🔍 Starting AVD Storage Analytics deployment validation..." "Info"

# Check Azure PowerShell modules
Write-Status "Checking Azure PowerShell modules..." "Info"
$requiredModules = @("Az.Accounts", "Az.Resources", "Az.Monitor", "Az.DesktopVirtualization")
foreach ($module in $requiredModules) {
    try {
        $moduleInfo = Get-Module -Name $module -ListAvailable | Select-Object -First 1
        if ($moduleInfo) {
            Write-Status "✅ $module version $($moduleInfo.Version) is available" "Success"
        } else {
            Write-Status "❌ $module is not installed. Please run: Install-Module $module -Force" "Error"
            exit 1
        }
    } catch {
        Write-Status "❌ Error checking module $module`: $($_.Exception.Message)" "Error"
        exit 1
    }
}

# Check Azure context
Write-Status "Checking Azure authentication..." "Info"
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Status "❌ Not logged into Azure. Please run: Connect-AzAccount" "Error"
        exit 1
    }
    Write-Status "✅ Logged in as: $($context.Account.Id)" "Success"
    
    # Set subscription context
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Status "✅ Using subscription: $SubscriptionId" "Success"
} catch {
    Write-Status "❌ Error with Azure authentication: $($_.Exception.Message)" "Error"
    exit 1
}

# Check resource group
Write-Status "Checking resource group..." "Info"
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($rg) {
        Write-Status "✅ Resource group exists: $ResourceGroupName in $($rg.Location)" "Success"
    } else {
        Write-Status "⚠️ Resource group '$ResourceGroupName' does not exist. It will be created during deployment." "Warning"
    }
} catch {
    Write-Status "❌ Error checking resource group: $($_.Exception.Message)" "Error"
    exit 1
}

# Check permissions
Write-Status "Checking required permissions..." "Info"
try {
    # Test if we can list role assignments (indicates sufficient permissions)
    $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" -MaxResults 1 -ErrorAction SilentlyContinue
    if ($roleAssignments) {
        Write-Status "✅ Sufficient permissions to manage role assignments" "Success"
    } else {
        Write-Status "⚠️ Limited permissions detected. Managed identity role assignment may fail." "Warning"
    }
} catch {
    Write-Status "⚠️ Cannot verify role assignment permissions: $($_.Exception.Message)" "Warning"
}

# Validate ARM template
Write-Status "Validating ARM template..." "Info"
try {
    $templateUri = "https://raw.githubusercontent.com/tvanroo/AVDStorageAudit/main/AVD%20Workbook/deploy-avd-data-collection.json"
    
    # Test template parameters
    $testParams = @{
        dataRetentionDays = 90
        enableHostPoolDiagnostics = $true
        enableSessionHostDiagnostics = $true
        enableStorageDiagnostics = $true
        enableANFDiagnostics = $true
    }
    
    if ($rg) {
        $validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $templateUri -TemplateParameterObject $testParams
    } else {
        # Create a temporary RG for validation
        $tempRgName = "temp-validation-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Write-Status "Creating temporary resource group for validation: $tempRgName" "Info"
        $tempRg = New-AzResourceGroup -Name $tempRgName -Location "East US"
        $validation = Test-AzResourceGroupDeployment -ResourceGroupName $tempRgName -TemplateUri $templateUri -TemplateParameterObject $testParams
        Remove-AzResourceGroup -Name $tempRgName -Force
    }
    
    if ($validation) {
        Write-Status "❌ Template validation failed:" "Error"
        foreach ($error in $validation) {
            Write-Status "  • $($error.Message)" "Error"
        }
        exit 1
    } else {
        Write-Status "✅ ARM template validation passed" "Success"
    }
} catch {
    Write-Status "❌ Template validation error: $($_.Exception.Message)" "Error"
    exit 1
}

# Test deployment (WhatIf mode)
if ($WhatIf) {
    Write-Status "Running deployment test (WhatIf mode)..." "Info"
    try {
        $deploymentName = "avd-storage-analytics-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $whatIfResult = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $deploymentName -TemplateUri $templateUri -TemplateParameterObject $testParams -WhatIf
        Write-Status "✅ Deployment test completed successfully" "Success"
    } catch {
        Write-Status "❌ Deployment test failed: $($_.Exception.Message)" "Error"
        exit 1
    }
}

Write-Status "✅ All validation checks passed! You can proceed with deployment." "Success"
Write-Status "To deploy, run: .\Deploy-AVD-DataCollection.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName" "Info"
