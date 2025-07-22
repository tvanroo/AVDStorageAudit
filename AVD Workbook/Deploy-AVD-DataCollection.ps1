# Deploy AVD Storage Analytics Data Collection Infrastructure
# This script deploys the necessary Log Analytics workspace and diagnostic settings
# for comprehensive AVD storage analysis and ANF planning

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure subscription ID where resources will be deployed")]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true, HelpMessage = "Name of the resource group where resources will be deployed")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Name of the Log Analytics workspace (will be made unique)")]
    [string]$WorkspaceName = "",
    
    [Parameter(Mandatory = $false, HelpMessage = "Number of days to retain log data (30-730)")]
    [ValidateRange(30, 730)]
    [int]$DataRetentionDays = 90,
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable diagnostic settings for AVD Host Pools")]
    [bool]$EnableHostPoolDiagnostics = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable diagnostic settings and performance counters for AVD Session Hosts")]
    [bool]$EnableSessionHostDiagnostics = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable diagnostic settings for Storage Accounts")]
    [bool]$EnableStorageDiagnostics = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable diagnostic settings for Azure NetApp Files")]
    [bool]$EnableANFDiagnostics = $true,
    
    [Parameter(Mandatory = $false, HelpMessage = "URI to the ARM template")]
    [string]$TemplateUri = "https://raw.githubusercontent.com/tvanroo/AVDStorageAudit/main/AVD%20Workbook/deploy-avd-data-collection.json"
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Starting AVD Storage Analytics Data Collection Deployment" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green

# Check if required modules are installed
$requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Monitor', 'Az.DesktopVirtualization')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "❌ Required module $module is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $module -Force -AllowClobber
    }
}

# Connect to Azure
try {
    $context = Get-AzContext
    if (-not $context -or $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "🔐 Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount -SubscriptionId $SubscriptionId
    }
    
    Write-Host "✅ Connected to Azure subscription: $($context.Subscription.Name)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# Create resource group if it doesn't exist (location must be provided if creating new RG)
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        # If no resource group exists, we need a location - use a default or prompt user
        $defaultLocation = "East US"
        Write-Host "📁 Creating resource group: $ResourceGroupName in $defaultLocation" -ForegroundColor Yellow
        Write-Host "💡 Note: You can specify a different location by creating the resource group first in the Azure portal" -ForegroundColor Cyan
        New-AzResourceGroup -Name $ResourceGroupName -Location $defaultLocation
        Write-Host "✅ Resource group created successfully" -ForegroundColor Green
        $rg = Get-AzResourceGroup -Name $ResourceGroupName
    } else {
        Write-Host "✅ Resource group already exists: $ResourceGroupName in $($rg.Location)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to create resource group: $($_.Exception.Message)"
    exit 1
}

# Deploy the ARM template
try {
    Write-Host "📋 Deploying data collection infrastructure..." -ForegroundColor Yellow
      $deploymentName = "avd-storage-analytics-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    # Build template parameters
    $templateParameters = @{
        dataRetentionDays = $DataRetentionDays
        enableHostPoolDiagnostics = $EnableHostPoolDiagnostics
        enableSessionHostDiagnostics = $EnableSessionHostDiagnostics
        enableStorageDiagnostics = $EnableStorageDiagnostics
        enableANFDiagnostics = $EnableANFDiagnostics
    }
    
    # Only add workspace name if specified (let template use default with unique suffix)
    if ($WorkspaceName -and $WorkspaceName.Trim() -ne "") {
        $templateParameters.logAnalyticsWorkspaceName = $WorkspaceName.Trim()
    }
    
    # Check if template file exists locally, otherwise use URI
    $templatePath = Join-Path $PSScriptRoot "deploy-avd-data-collection.json"
    if (Test-Path $templatePath) {
        Write-Host "📄 Using local template file" -ForegroundColor Cyan
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $deploymentName -TemplateFile $templatePath -TemplateParameterObject $templateParameters -Verbose
    } else {
        Write-Host "🌐 Using remote template from: $TemplateUri" -ForegroundColor Cyan
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $deploymentName -TemplateUri $TemplateUri -TemplateParameterObject $templateParameters -Verbose
    }
    
    if ($deployment.ProvisioningState -eq 'Succeeded') {
        Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
        
        # Display outputs
        Write-Host "`n📊 Deployment Results:" -ForegroundColor Cyan
        Write-Host "══════════════════════" -ForegroundColor Cyan        Write-Host "Log Analytics Workspace: $($deployment.Outputs.logAnalyticsWorkspaceName.Value)" -ForegroundColor White
        Write-Host "Workspace Resource ID: $($deployment.Outputs.logAnalyticsWorkspaceId.Value)" -ForegroundColor White
        Write-Host "Data Collection Rule ID: $($deployment.Outputs.dataCollectionRuleId.Value)" -ForegroundColor White
        Write-Host "Managed Identity ID: $($deployment.Outputs.managedIdentityId.Value)" -ForegroundColor White
        
        # Check current AVD resources
        Write-Host "`n🔍 Scanning for AVD resources in subscription..." -ForegroundColor Yellow
        
        $hostPools = Get-AzWvdHostPool -ErrorAction SilentlyContinue
        $storageAccounts = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -match 'avd|profile|fslogix|vdi|wvd' -or $_.Tags.ContainsKey('AVD') }
        
        Write-Host "Found $($hostPools.Count) AVD Host Pool(s)" -ForegroundColor Cyan
        Write-Host "Found $($storageAccounts.Count) relevant Storage Account(s)" -ForegroundColor Cyan
        
        if ($hostPools.Count -eq 0) {
            Write-Host "⚠️  No AVD Host Pools found. Diagnostic settings will be applied when Host Pools are created." -ForegroundColor Yellow
        }
        
        if ($storageAccounts.Count -eq 0) {
            Write-Host "⚠️  No AVD-related Storage Accounts found. Make sure to tag storage accounts with 'AVD' or include 'avd', 'profile', or 'fslogix' in the name." -ForegroundColor Yellow
        }
        
    } else {
        Write-Error "Deployment failed with state: $($deployment.ProvisioningState)"
        Write-Host "Error details:" -ForegroundColor Red
        $deployment.DeploymentDebugLogLevel = 'All'
        Write-Host $deployment | ConvertTo-Json -Depth 10
        exit 1
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n🎉 AVD Storage Analytics data collection infrastructure is ready!" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Deploy the AVD Storage Analytics workbook" -ForegroundColor White
Write-Host "2. Wait 15-30 minutes for initial data collection" -ForegroundColor White
Write-Host "3. Review storage analytics and ANF recommendations" -ForegroundColor White
Write-Host "`nWorkspace Name: $($deployment.Outputs.logAnalyticsWorkspaceName.Value)" -ForegroundColor Yellow
