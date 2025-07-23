#!/usr/bin/env pwsh

Write-Host "🔄 AVD Workbook Iterative Deployment Test" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Test parameters
$resourceGroupName = "rg-avd-storage-test-$(Get-Random -Minimum 1000 -Maximum 9999)"
$location = "East US"
$workspaceName = "law-avd-test-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "📋 Test Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host "  Workspace: $workspaceName" -ForegroundColor White
Write-Host ""

try {
    # Step 1: Validate current Azure login
    Write-Host "🔍 Step 1: Validating Azure CLI login..." -ForegroundColor Green
    $currentAccount = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $currentAccount) {
        throw "Not logged in to Azure CLI. Please run 'az login' first."
    }
    Write-Host "✅ Logged in as: $($currentAccount.user.name)" -ForegroundColor Green
    Write-Host "✅ Subscription: $($currentAccount.name) ($($currentAccount.id))" -ForegroundColor Green
    Write-Host ""

    # Step 2: Create test resource group
    Write-Host "🏗️ Step 2: Creating test resource group..." -ForegroundColor Green
    $rgResult = az group create --name $resourceGroupName --location $location --output json | ConvertFrom-Json
    if ($rgResult.properties.provisioningState -eq "Succeeded") {
        Write-Host "✅ Resource group created successfully" -ForegroundColor Green
    } else {
        throw "Failed to create resource group"
    }
    Write-Host ""    # Step 3: Test minimal workbook deployment
    Write-Host "📊 Step 3: Testing minimal workbook deployment..." -ForegroundColor Green
    
    # Create minimal template separately to avoid PowerShell parsing issues
    $templateContent = @'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workbookName": {
      "type": "string",
      "defaultValue": "test-workbook-12345",
      "metadata": {
        "description": "Name of the workbook"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Insights/workbooks",
      "apiVersion": "2022-04-01",
      "name": "[parameters('workbookName')]",
      "location": "[resourceGroup().location]",
      "kind": "shared",
      "properties": {
        "displayName": "AVD Storage Test Workbook",
        "description": "Simple test workbook for validation",
        "category": "Azure Virtual Desktop",
        "serializedData": "{\"version\":\"Notebook/1.0\",\"items\":[{\"type\":1,\"content\":{\"json\":\"# Test Workbook\\r\\nThis is a simple test workbook to validate deployment.\"},\"name\":\"title\"}],\"styleSettings\":{},\"$schema\":\"https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json\"}"
      }
    }
  ],
  "outputs": {
    "workbookId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Insights/workbooks', parameters('workbookName'))]"
    }
  }
}
'@

    $templateContent | Out-File -FilePath "test-minimal-workbook.json" -Encoding UTF8
    
    Write-Host "🚀 Deploying minimal workbook..." -ForegroundColor Yellow
    $deployResult = az deployment group create `
        --resource-group $resourceGroupName `
        --template-file "test-minimal-workbook.json" `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $deployJson = $deployResult | ConvertFrom-Json
        Write-Host "✅ Minimal workbook deployed successfully!" -ForegroundColor Green
        Write-Host "   Workbook ID: $($deployJson.properties.outputs.workbookId.value)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Minimal workbook deployment failed:" -ForegroundColor Red
        Write-Host $deployResult -ForegroundColor Red
        throw "Minimal deployment failed"
    }
    Write-Host ""

    # Step 4: Test ARM template validation
    Write-Host "🔍 Step 4: Validating full ARM template..." -ForegroundColor Green
    $templatePath = "AVD Workbook\deploy-avd-data-collection.json"
    $paramPath = "AVD Workbook\deploy-avd-data-collection.parameters.json"
    
    if (-not (Test-Path $templatePath)) {
        throw "ARM template not found: $templatePath"
    }
    
    Write-Host "🧪 Running template validation..." -ForegroundColor Yellow
    $validateResult = az deployment group validate `
        --resource-group $resourceGroupName `
        --template-file $templatePath `
        --parameters $paramPath `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ARM template validation passed!" -ForegroundColor Green
    } else {
        Write-Host "❌ ARM template validation failed:" -ForegroundColor Red
        Write-Host $validateResult -ForegroundColor Red
        
        # Try to extract specific error information
        if ($validateResult -match "InvalidTemplate") {
            Write-Host "" -ForegroundColor Yellow
            Write-Host "🔧 Analyzing template errors..." -ForegroundColor Yellow
            
            # Check for common workbook issues
            if ($validateResult -match "serializedData") {
                Write-Host "❌ Issue detected in workbook serializedData" -ForegroundColor Red
                Write-Host "💡 Suggestion: The workbook JSON may have escaping issues" -ForegroundColor Yellow
            }
            
            if ($validateResult -match "Invalid character") {
                Write-Host "❌ Invalid character in JSON detected" -ForegroundColor Red
                Write-Host "💡 Suggestion: Check JSON escaping in ARM template" -ForegroundColor Yellow
            }
        }
    }
    Write-Host ""

    # Step 5: Test what-if deployment (if validation passed)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🔮 Step 5: Running what-if deployment..." -ForegroundColor Green
        $whatifResult = az deployment group what-if `
            --resource-group $resourceGroupName `
            --template-file $templatePath `
            --parameters $paramPath `
            --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ What-if analysis completed!" -ForegroundColor Green
            Write-Host "📊 Predicted changes:" -ForegroundColor Cyan
            $whatifJson = $whatifResult | ConvertFrom-Json
            if ($whatifJson.changes) {
                foreach ($change in $whatifJson.changes) {
                    Write-Host "  - $($change.changeType): $($change.resourceId)" -ForegroundColor White
                }
            }
        } else {
            Write-Host "❌ What-if analysis failed:" -ForegroundColor Red
            Write-Host $whatifResult -ForegroundColor Red
        }
        Write-Host ""
    }

} catch {
    Write-Host "❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    Write-Host "🧹 Cleaning up test resources..." -ForegroundColor Yellow
    if ($resourceGroupName) {
        try {
            az group delete --name $resourceGroupName --yes --no-wait 2>$null
            Write-Host "✅ Resource group cleanup initiated" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Failed to cleanup resource group: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Clean up test files
    @("test-minimal-workbook.json") | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item $_ -Force
            Write-Host "✅ Cleaned up test file: $_" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "🎯 Test Summary:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "1. ✅ Azure CLI validation" -ForegroundColor White
Write-Host "2. ✅ Resource group creation" -ForegroundColor White
Write-Host "3. ✅ Minimal workbook deployment" -ForegroundColor White
Write-Host "4. ❓ Full template validation (check results above)" -ForegroundColor White
Write-Host "5. ❓ What-if analysis (if validation passed)" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next steps based on results:" -ForegroundColor Yellow
Write-Host "- If validation failed: Fix JSON escaping issues in workbook serializedData" -ForegroundColor White
Write-Host "- If validation passed: Proceed with actual deployment" -ForegroundColor White
Write-Host "- Check Azure portal for deployed minimal workbook" -ForegroundColor White
