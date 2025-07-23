#!/usr/bin/env pwsh
param(
    [string]$ResourceGroupName = "rg-avd-test-workbook",
    [string]$Location = "eastus"
)

Write-Host "🧪 Testing workbook deployment with Azure CLI..." -ForegroundColor Cyan

try {
    # Check if logged in to Azure
    Write-Host "Checking Azure login status..." -ForegroundColor Yellow
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "❌ Not logged in to Azure. Please run: az login" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "📋 Using subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan

    # Create resource group if it doesn't exist
    Write-Host "Creating resource group if needed..." -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location --only-show-errors
    Write-Host "✅ Resource group ready: $ResourceGroupName" -ForegroundColor Green

    # Create a test Log Analytics workspace for the workbook
    $workspaceName = "test-law-$((Get-Date).ToString('yyyyMMddHHmmss'))"
    Write-Host "Creating Log Analytics workspace: $workspaceName" -ForegroundColor Yellow
    
    $workspace = az monitor log-analytics workspace create `
        --resource-group $ResourceGroupName `
        --workspace-name $workspaceName `
        --location $Location `
        --only-show-errors | ConvertFrom-Json

    if (-not $workspace) {
        throw "Failed to create Log Analytics workspace"
    }

    Write-Host "✅ Log Analytics workspace created: $($workspace.id)" -ForegroundColor Green

    # Test 1: Deploy simple workbook
    Write-Host "`n🧪 TEST 1: Deploying simple workbook..." -ForegroundColor Cyan
    $deploymentName = "test-simple-workbook-$((Get-Date).ToString('yyyyMMddHHmmss'))"
    
    $result = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "test-workbook-simple.json" `
        --parameters logAnalyticsWorkspaceId="$($workspace.id)" `
        --name $deploymentName `
        --only-show-errors 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ TEST 1 PASSED: Simple workbook deployed successfully!" -ForegroundColor Green
        $deployment = $result | ConvertFrom-Json
        Write-Host "📊 Workbook ID: $($deployment.properties.outputs.workbookId.value)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ TEST 1 FAILED: Simple workbook deployment failed" -ForegroundColor Red
        Write-Host "Error details:" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Red
    }

    # Test 2: Try to deploy the complex workbook
    Write-Host "`n🧪 TEST 2: Deploying complex workbook from full template..." -ForegroundColor Cyan
    $complexDeploymentName = "test-complex-workbook-$((Get-Date).ToString('yyyyMMddHHmmss'))"
    
    $complexResult = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "AVD Workbook\deploy-avd-data-collection.json" `
        --parameters logAnalyticsWorkspaceName="test-complex-law-$((Get-Date).ToString('yyyyMMddHHmmss'))" `
        --name $complexDeploymentName `
        --only-show-errors 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ TEST 2 PASSED: Complex workbook deployed successfully!" -ForegroundColor Green
        $complexDeployment = $complexResult | ConvertFrom-Json
    } else {
        Write-Host "❌ TEST 2 FAILED: Complex workbook deployment failed" -ForegroundColor Red
        Write-Host "Error details:" -ForegroundColor Yellow
        Write-Host $complexResult -ForegroundColor Red
        
        # Extract specific error details
        if ($complexResult -match '"message":\s*"([^"]+)"') {
            Write-Host "`n🔍 Extracted error message: $($Matches[1])" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Error "❌ Script error: $($_.Exception.Message)"
} finally {
    # Cleanup - ask user if they want to keep resources
    $cleanup = Read-Host "`n🧹 Delete test resource group '$ResourceGroupName'? (y/N)"
    if ($cleanup -eq 'y' -or $cleanup -eq 'Y') {
        Write-Host "Deleting test resource group..." -ForegroundColor Yellow
        az group delete --name $ResourceGroupName --yes --no-wait --only-show-errors
        Write-Host "✅ Resource group deletion initiated" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Test resources kept in: $ResourceGroupName" -ForegroundColor Cyan
    }
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Green
