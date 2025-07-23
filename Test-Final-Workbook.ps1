#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test the final fixed workbook deployment

.DESCRIPTION
Deploy the ARM template with the corrected workbook JSON to verify the workbook loads correctly.
#>

Write-Host "🚀 Testing FINAL fixed workbook deployment..." -ForegroundColor Cyan

$resourceGroup = "rg-avd-storage-test"
$deploymentName = "test-final-workbook-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templatePath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"

try {
    Write-Host "🚀 Deploying ARM template directly..." -ForegroundColor Yellow
    
    $deploymentResult = az deployment group create `
        --resource-group $resourceGroup `
        --name $deploymentName `
        --template-file $templatePath `
        --parameters logAnalyticsWorkspaceName="AVDStorageAuditLAWFinal" `
        --only-show-errors `
        2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
        
        # Parse the deployment result
        $deployment = $deploymentResult | ConvertFrom-Json
        
        if ($deployment.properties.outputs.workbookId) {
            $workbookId = $deployment.properties.outputs.workbookId.value
            Write-Host "📋 Workbook ID: $workbookId" -ForegroundColor Blue
            
            $portalUrl = "https://portal.azure.com/#@/resource$workbookId/workbook"
            Write-Host "🌐 Open workbook in portal: $portalUrl" -ForegroundColor Green
        }
        
        Write-Host "" -ForegroundColor White
        Write-Host "🎉 SUCCESS: Final workbook deployed!" -ForegroundColor Green
        Write-Host "🔍 CRITICAL TEST: Open the workbook in Azure portal to verify:" -ForegroundColor Cyan
        Write-Host "   1. No 'workbook content failed to load' error" -ForegroundColor White
        Write-Host "   2. No JSON syntax errors" -ForegroundColor White
        Write-Host "   3. Workbook displays all sections correctly" -ForegroundColor White
        
        return $true
    }
    else {
        Write-Host "❌ Deployment failed:" -ForegroundColor Red
        Write-Host $deploymentResult -ForegroundColor Red
        return $false
    }
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}
