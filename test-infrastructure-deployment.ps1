# Test script for simplified infrastructure deployment
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = ".\AVD Workbook\deploy-avd-infrastructure.json",
    
    [Parameter(Mandatory = $false)]
    [string]$ParametersFile = ".\AVD Workbook\deploy-avd-infrastructure.parameters.json"
)

Write-Host "AVD Storage Analytics - Infrastructure Deployment Test" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Check if logged into Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please log into Azure first using Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
    Write-Host "Using Azure context: $($context.Account.Id)" -ForegroundColor Green
    Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
} catch {
    Write-Host "Please install Azure PowerShell and log in first" -ForegroundColor Red
    exit 1
}

# Check if resource group exists
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Host "Resource group '$ResourceGroupName' found in $($rg.Location)" -ForegroundColor Green
} catch {
    Write-Host "Resource group '$ResourceGroupName' not found. Please create it first." -ForegroundColor Red
    exit 1
}

# Test template syntax
Write-Host "`nTesting ARM template syntax..." -ForegroundColor Yellow
try {
    $templateTest = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParametersFile
    if ($templateTest) {
        Write-Host "Template validation issues found:" -ForegroundColor Red
        $templateTest | ForEach-Object {
            Write-Host "  - $($_.Message)" -ForegroundColor Red
        }
        Write-Host "Please fix validation issues before deployment" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "Template syntax validation passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "Template validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test deployment in validation mode
Write-Host "`nTesting deployment in validation mode..." -ForegroundColor Yellow
try {
    $deploymentTest = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParametersFile -Mode Incremental -WhatIf
    Write-Host "Deployment validation completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Deployment validation failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Run this script to deploy infrastructure:" -ForegroundColor White
Write-Host "   New-AzResourceGroupDeployment -ResourceGroupName '$ResourceGroupName' -TemplateFile '$TemplateFile' -TemplateParameterFile '$ParametersFile'" -ForegroundColor Gray
Write-Host "`n2. After deployment, run Grant-ManagedIdentityPermissions.ps1 to configure permissions" -ForegroundColor White
Write-Host "`n3. Use Deploy-AVD-DataCollection.ps1 to configure diagnostic settings for AVD resources" -ForegroundColor White
Write-Host "`n4. Import the AVD Storage Analytics workbook in Azure Monitor" -ForegroundColor White
