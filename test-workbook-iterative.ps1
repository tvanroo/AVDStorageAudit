#!/usr/bin/env pwsh
param(
    [string]$ResourceGroupName = "rg-avd-test-workbook",
    [string]$Location = "eastus"
)

Write-Host "🧪 Testing workbook deployment iteratively..." -ForegroundColor Cyan

try {
    # Check Azure login
    Write-Host "Checking Azure CLI login..." -ForegroundColor Yellow
    $loginCheck = az account show 2>$null
    if (-not $loginCheck) {
        Write-Host "❌ Please login to Azure CLI first: az login" -ForegroundColor Red
        return
    }
    
    $account = $loginCheck | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "📋 Subscription: $($account.name)" -ForegroundColor Cyan

    # Create resource group
    Write-Host "`nCreating resource group: $ResourceGroupName" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location --only-show-errors | Out-Null
    Write-Host "✅ Resource group ready" -ForegroundColor Green

    # Test 1: Deploy minimal workbook template
    Write-Host "`n🧪 TEST 1: Deploying minimal workbook template..." -ForegroundColor Cyan
    $deployment1 = "test-minimal-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $result1 = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "test-workbook-minimal.json" `
        --name $deployment1 `
        --only-show-errors 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ TEST 1 PASSED: Minimal workbook deployed successfully!" -ForegroundColor Green
        $deployment1Result = $result1 | ConvertFrom-Json
        Write-Host "📊 Workbook ID: $($deployment1Result.properties.outputs.workbookId.value)" -ForegroundColor Cyan
        
        # Test accessing the workbook
        $workbookName = Split-Path $deployment1Result.properties.outputs.workbookId.value -Leaf
        Write-Host "🔍 Checking workbook in Azure portal..." -ForegroundColor Yellow
        Write-Host "   Workbook Name: $workbookName" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ TEST 1 FAILED: Minimal workbook deployment failed" -ForegroundColor Red
        Write-Host "Error output:" -ForegroundColor Yellow
        $result1 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        
        # Try to extract specific error information
        if ($result1 -match '"code":\s*"([^"]+)"') {
            Write-Host "Error code: $($Matches[1])" -ForegroundColor Yellow
        }
        if ($result1 -match '"message":\s*"([^"]+)"') {
            Write-Host "Error message: $($Matches[1])" -ForegroundColor Yellow
        }
        
        Write-Host "`n⏹️  Stopping tests due to minimal template failure" -ForegroundColor Red
        return
    }

    # Test 2: Deploy full workbook template
    Write-Host "`n🧪 TEST 2: Deploying full workbook template..." -ForegroundColor Cyan
    $deployment2 = "test-full-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $result2 = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "AVD Workbook\deploy-avd-data-collection.json" `
        --parameters logAnalyticsWorkspaceName="test-full-law-$(Get-Date -Format 'yyyyMMddHHmmss')" `
        --name $deployment2 `
        --only-show-errors 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ TEST 2 PASSED: Full workbook deployed successfully!" -ForegroundColor Green
        $deployment2Result = $result2 | ConvertFrom-Json
        Write-Host "📊 All resources deployed successfully" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ TEST 2 FAILED: Full workbook deployment failed" -ForegroundColor Red
        Write-Host "Error output:" -ForegroundColor Yellow
        $result2 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        
        # Extract specific error information for full template
        if ($result2 -match '"code":\s*"([^"]+)"') {
            Write-Host "Error code: $($Matches[1])" -ForegroundColor Yellow
        }
        if ($result2 -match '"message":\s*"([^"]+)"') {
            Write-Host "Error message: $($Matches[1])" -ForegroundColor Yellow
        }
        
        # Check if it's a workbook-specific error
        if ($result2 -match "workbook|serializedData") {
            Write-Host "`n🔍 This appears to be a workbook-specific error" -ForegroundColor Yellow
            Write-Host "   The issue is likely in the workbook JSON structure or escaping" -ForegroundColor Cyan
        }
    }

    Write-Host "`n📋 Deployment Summary:" -ForegroundColor Cyan
    Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "   Location: $Location" -ForegroundColor White
    
    # List workbooks in the resource group
    Write-Host "`n📊 Checking deployed workbooks..." -ForegroundColor Yellow
    $workbooks = az resource list --resource-group $ResourceGroupName --resource-type "Microsoft.Insights/workbooks" --query "[].{Name:name, Location:location}" --output table 2>$null
    if ($workbooks) {
        Write-Host $workbooks -ForegroundColor Green
    } else {
        Write-Host "No workbooks found in resource group" -ForegroundColor Yellow
    }

} catch {
    Write-Error "Script error: $($_.Exception.Message)"
} finally {
    # Cleanup prompt
    Write-Host "`n🧹 Cleanup Options:" -ForegroundColor Cyan
    Write-Host "   1. Keep resources for inspection" -ForegroundColor White
    Write-Host "   2. Delete resource group" -ForegroundColor White
    
    $cleanup = Read-Host "Delete test resource group '$ResourceGroupName'? (y/N)"
    if ($cleanup -eq 'y' -or $cleanup -eq 'Y') {
        Write-Host "Deleting resource group..." -ForegroundColor Yellow
        az group delete --name $ResourceGroupName --yes --no-wait --only-show-errors
        Write-Host "✅ Resource group deletion initiated" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Resources kept for inspection in: $ResourceGroupName" -ForegroundColor Cyan
        Write-Host "   Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$($account.id)/resourceGroups/$ResourceGroupName" -ForegroundColor Blue
    }
}

Write-Host "`n🏁 Testing completed!" -ForegroundColor Green
