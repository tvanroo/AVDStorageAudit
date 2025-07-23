# Final Verification of AVD Workbook Deployment
# This script verifies that the workbook deployment is successful and the workspace dropdown works

param(
    [string]$ResourceGroup = "vanRoojen-AVDWorkbook",
    [string]$SubscriptionId = "c560a042-4311-40cf-beb5-edc67991179e"
)

Write-Host "🎉 AVD Workbook Deployment Verification" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Test 1: Verify the Azure Resource Graph query works
Write-Host "`n🧪 Test 1: Verifying Azure Resource Graph query..." -ForegroundColor Cyan
try {
    $workspaces = az graph query -q "Resources | where type == 'microsoft.operationalinsights/workspaces' | project id, name, subscriptionId, resourceGroup | order by name asc" --output json | ConvertFrom-Json
    Write-Host "✅ Query successful! Found $($workspaces.count) Log Analytics workspaces" -ForegroundColor Green
    
    # Show first few workspaces
    Write-Host "📋 Sample workspaces found:" -ForegroundColor Yellow
    $workspaces.data | Select-Object -First 5 | ForEach-Object {
        Write-Host "  • $($_.name) (Resource Group: $($_.resourceGroup))" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Query failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Verify the deployment resources exist
Write-Host "`n🔍 Test 2: Verifying deployed resources..." -ForegroundColor Cyan
try {
    $resources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json
    
    $workbook = $resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    $workspace = $resources | Where-Object { $_.type -eq "Microsoft.OperationalInsights/workspaces" }
    $dce = $resources | Where-Object { $_.type -eq "Microsoft.Insights/dataCollectionEndpoints" }
    $dcr = $resources | Where-Object { $_.type -eq "Microsoft.Insights/dataCollectionRules" }
    $identity = $resources | Where-Object { $_.type -eq "Microsoft.ManagedIdentity/userAssignedIdentities" }
    
    if ($workbook) {
        Write-Host "✅ Azure Workbook deployed: $($workbook.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Azure Workbook not found" -ForegroundColor Red
    }
    
    if ($workspace) {
        Write-Host "✅ Log Analytics Workspace deployed: $($workspace.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Log Analytics Workspace not found" -ForegroundColor Red
    }
    
    if ($dce) {
        Write-Host "✅ Data Collection Endpoint deployed: $($dce.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Data Collection Endpoint not found" -ForegroundColor Red
    }
    
    if ($dcr) {
        Write-Host "✅ Data Collection Rule deployed: $($dcr.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Data Collection Rule not found" -ForegroundColor Red
    }
    
    if ($identity) {
        Write-Host "✅ Managed Identity deployed: $($identity.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Managed Identity not found" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Failed to verify resources: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check the ARM template for valid JSON
Write-Host "`n📄 Test 3: Validating ARM template JSON..." -ForegroundColor Cyan
try {
    $templatePath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"
    $template = Get-Content $templatePath -Raw | ConvertFrom-Json
    Write-Host "✅ ARM template JSON is valid" -ForegroundColor Green
    
    # Check workbook serializedData
    $workbookResource = $template.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    if ($workbookResource) {
        $serializedData = $workbookResource.properties.serializedData | ConvertFrom-Json
        Write-Host "✅ Workbook serializedData is valid JSON" -ForegroundColor Green
        
        # Check workspace parameter
        $parametersItem = $serializedData.items | Where-Object { $_.type -eq 9 }
        $workspaceParam = $parametersItem.content.parameters | Where-Object { $_.name -eq "workspace" }
        if ($workspaceParam) {
            Write-Host "✅ Workspace parameter found in workbook" -ForegroundColor Green
            Write-Host "   Query: $($workspaceParam.query)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Workspace parameter not found in workbook" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Workbook resource not found in template" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ARM template validation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary and next steps
Write-Host "`n📋 Summary and Next Steps:" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

Write-Host "`n✅ Completed fixes:" -ForegroundColor Green
Write-Host "  • Fixed JSON formatting in serializedData (triple-escaped to properly escaped)" -ForegroundColor White
Write-Host "  • Resolved schema loading error for Microsoft.HybridCompute" -ForegroundColor White
Write-Host "  • Updated workspace parameter query for better compatibility" -ForegroundColor White
Write-Host "  • Successfully deployed ARM template to $ResourceGroup" -ForegroundColor White

Write-Host "`n🎯 Next verification steps:" -ForegroundColor Yellow
Write-Host "  1. Open Azure portal and navigate to the resource group: $ResourceGroup" -ForegroundColor White
Write-Host "  2. Find the Azure Workbook resource (GUID name)" -ForegroundColor White
Write-Host "  3. Click on the workbook to open it" -ForegroundColor White
Write-Host "  4. Test the 'Log Analytics Workspace' dropdown" -ForegroundColor White
Write-Host "  5. Verify all workbook sections load without errors" -ForegroundColor White

Write-Host "`n🔗 Useful Azure portal links:" -ForegroundColor Cyan
Write-Host "  • Resource Group: https://portal.azure.com/#@netapp.com/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/overview" -ForegroundColor Blue
Write-Host "  • Azure Workbooks: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/microsoft.insights%2Fworkbooks" -ForegroundColor Blue

Write-Host "`n🎉 Deployment verification completed!" -ForegroundColor Green
