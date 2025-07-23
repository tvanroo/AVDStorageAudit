#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test the fixed workbook deployment

.DESCRIPTION
Deploy the updated ARM template to test if the workbook JSON formatting issue is resolved.
#>

Write-Host "🚀 Testing fixed workbook deployment..." -ForegroundColor Cyan

$resourceGroup = "rg-avd-storage-test"
$deploymentName = "test-fixed-workbook-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templatePath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"

try {
    Write-Host "🔍 Validating template..." -ForegroundColor Yellow
    
    # Basic validation without parameters to check template structure
    $validationResult = az deployment group validate `
        --resource-group $resourceGroup `
        --template-file $templatePath `
        --parameters logAnalyticsWorkspaceName="AVDStorageAuditLAWFixed" `
        2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Template validation passed" -ForegroundColor Green
        
        Write-Host "🚀 Deploying template..." -ForegroundColor Yellow
        
        $deploymentResult = az deployment group create `
            --resource-group $resourceGroup `
            --name $deploymentName `
            --template-file $templatePath `
            --parameters logAnalyticsWorkspaceName="AVDStorageAuditLAWFixed" `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
            
            # Get the workbook ID from outputs
            Write-Host "📊 Getting workbook information..." -ForegroundColor Yellow
            $deployment = az deployment group show --resource-group $resourceGroup --name $deploymentName | ConvertFrom-Json
            
            if ($deployment.properties.outputs.workbookId) {
                $workbookId = $deployment.properties.outputs.workbookId.value
                Write-Host "📋 Workbook ID: $workbookId" -ForegroundColor Blue
                
                $portalUrl = "https://portal.azure.com/#@/resource$workbookId/workbook"
                Write-Host "🌐 Open workbook in portal: $portalUrl" -ForegroundColor Green
            }
            
            Write-Host "" -ForegroundColor White
            Write-Host "🎉 SUCCESS: Workbook deployed without JSON formatting errors!" -ForegroundColor Green
            Write-Host "🔍 Next step: Open the workbook in Azure portal to verify it loads correctly" -ForegroundColor Cyan
        }
        else {
            Write-Host "❌ Deployment failed:" -ForegroundColor Red
            Write-Host $deploymentResult -ForegroundColor Red
        }
    }
    else {
        Write-Host "❌ Template validation failed:" -ForegroundColor Red
        Write-Host $validationResult -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
