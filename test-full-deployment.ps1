#!/usr/bin/env pwsh

Write-Host "Full AVD Storage Analytics Deployment Test" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Test parameters
$resourceGroupName = "rg-avd-storage-full-test-$(Get-Random -Minimum 1000 -Maximum 9999)"
$location = "East US"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host ""

try {
    # Create resource group
    Write-Host "Creating resource group..." -ForegroundColor Green
    az group create --name $resourceGroupName --location $location --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group"
    }
    Write-Host "Resource group created successfully" -ForegroundColor Green
    Write-Host ""

    # Deploy full template
    Write-Host "Deploying full AVD Storage Analytics template..." -ForegroundColor Green
    Write-Host "This includes:" -ForegroundColor Yellow
    Write-Host "  - Log Analytics Workspace" -ForegroundColor White
    Write-Host "  - Data Collection Rule" -ForegroundColor White
    Write-Host "  - Data Collection Endpoint" -ForegroundColor White
    Write-Host "  - User-Assigned Managed Identity" -ForegroundColor White
    Write-Host "  - AVD Storage Analytics Workbook" -ForegroundColor White
    Write-Host ""

    $templatePath = "AVD Workbook\deploy-avd-data-collection.json"
    $paramPath = "AVD Workbook\deploy-avd-data-collection.parameters.json"
    
    $deployResult = az deployment group create --resource-group $resourceGroupName --template-file $templatePath --parameters $paramPath --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Full deployment completed successfully!" -ForegroundColor Green
        $deployJson = $deployResult | ConvertFrom-Json
        
        Write-Host ""
        Write-Host "Deployment Results:" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan
        
        if ($deployJson.properties.outputs) {
            foreach ($output in $deployJson.properties.outputs.PSObject.Properties) {
                Write-Host "  $($output.Name): $($output.Value.value)" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-Host "Verifying workbook deployment..." -ForegroundColor Green
        $workbooks = az monitor app-insights workbook list --resource-group $resourceGroupName --output json | ConvertFrom-Json
        
        if ($workbooks -and $workbooks.Count -gt 0) {
            Write-Host "Workbook found:" -ForegroundColor Green
            foreach ($workbook in $workbooks) {
                Write-Host "  Name: $($workbook.name)" -ForegroundColor White
                Write-Host "  Display Name: $($workbook.properties.displayName)" -ForegroundColor White
                Write-Host "  Category: $($workbook.properties.category)" -ForegroundColor White
            }
        } else {
            Write-Host "No workbooks found in resource group" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "Full deployment failed:" -ForegroundColor Red
        Write-Host $deployResult -ForegroundColor Red
        
        # Get detailed error information
        Write-Host ""
        Write-Host "Getting deployment operation details..." -ForegroundColor Yellow
        $operations = az deployment operation group list --resource-group $resourceGroupName --name "deploy-avd-data-collection" --output json 2>$null | ConvertFrom-Json
        
        if ($operations) {
            foreach ($op in $operations) {
                if ($op.properties.statusMessage.error) {
                    Write-Host "Error in $($op.properties.targetResource.resourceName):" -ForegroundColor Red
                    Write-Host "  $($op.properties.statusMessage.error.message)" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host ""
    Write-Host "IMPORTANT: Resource group created for testing" -ForegroundColor Yellow
    Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Cyan
    Write-Host "You can view the deployed resources in the Azure portal" -ForegroundColor White
    Write-Host "Run the following command to clean up when done:" -ForegroundColor White
    Write-Host "  az group delete --name $resourceGroupName --yes" -ForegroundColor Cyan

} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "Cleaning up failed deployment..." -ForegroundColor Yellow
    if ($resourceGroupName) {
        az group delete --name $resourceGroupName --yes --no-wait 2>$null
        Write-Host "Cleanup initiated" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Test Complete!" -ForegroundColor Cyan
