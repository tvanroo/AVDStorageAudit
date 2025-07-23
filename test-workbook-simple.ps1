#!/usr/bin/env pwsh

Write-Host "Quick Workbook Deployment Test" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Test parameters
$resourceGroupName = "rg-avd-test-$(Get-Random -Minimum 1000 -Maximum 9999)"
$location = "East US"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host ""

try {
    # Validate Azure login
    Write-Host "Validating Azure CLI..." -ForegroundColor Green
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Not logged in to Azure CLI"
    }
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host ""

    # Create resource group
    Write-Host "Creating resource group..." -ForegroundColor Green
    az group create --name $resourceGroupName --location $location --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group"
    }
    Write-Host "Resource group created" -ForegroundColor Green
    Write-Host ""

    # Test 1: Deploy minimal workbook
    Write-Host "Test 1: Deploying minimal workbook..." -ForegroundColor Green
    $deployResult = az deployment group create --resource-group $resourceGroupName --template-file "test-minimal-template.json" --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Minimal workbook deployed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Minimal workbook deployment failed:" -ForegroundColor Red
        Write-Host $deployResult -ForegroundColor Red
        throw "Minimal deployment failed"
    }
    Write-Host ""

    # Test 2: Validate full template
    Write-Host "Test 2: Validating full ARM template..." -ForegroundColor Green
    $templatePath = "AVD Workbook\deploy-avd-data-collection.json"
    $paramPath = "AVD Workbook\deploy-avd-data-collection.parameters.json"
    
    if (-not (Test-Path $templatePath)) {
        throw "Template not found: $templatePath"
    }
    
    $validateResult = az deployment group validate --resource-group $resourceGroupName --template-file $templatePath --parameters $paramPath --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Full template validation passed!" -ForegroundColor Green
    } else {
        Write-Host "Full template validation failed:" -ForegroundColor Red
        Write-Host $validateResult -ForegroundColor Red
    }

} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    Write-Host ""
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    if ($resourceGroupName) {
        az group delete --name $resourceGroupName --yes --no-wait 2>$null
        Write-Host "Cleanup initiated" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Test Complete!" -ForegroundColor Cyan
