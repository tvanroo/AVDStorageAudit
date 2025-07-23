# Fix Workspace Parameter Query in AVD Workbook
# This script updates the workspace parameter query to ensure it works correctly

param(
    [string]$TemplateFile = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"
)

Write-Host "🔧 Fixing workspace parameter query in AVD Workbook..." -ForegroundColor Cyan

try {
    # Read the ARM template
    Write-Host "📖 Reading ARM template: $TemplateFile" -ForegroundColor Yellow
    $armTemplate = Get-Content $TemplateFile -Raw | ConvertFrom-Json
    
    # Extract and parse the serialized workbook data
    Write-Host "🔍 Extracting workbook serializedData..." -ForegroundColor Yellow
    $workbookResource = $armTemplate.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    $serializedData = $workbookResource.properties.serializedData | ConvertFrom-Json
    
    # Find the workspace parameter
    Write-Host "🎯 Locating workspace parameter..." -ForegroundColor Yellow
    $parametersItem = $serializedData.items | Where-Object { $_.type -eq 9 }
    $workspaceParam = $parametersItem.content.parameters | Where-Object { $_.name -eq "workspace" }
    
    if ($workspaceParam) {
        Write-Host "✅ Found workspace parameter" -ForegroundColor Green
        Write-Host "Current query:" -ForegroundColor Gray
        Write-Host $workspaceParam.query -ForegroundColor White
        
        # Updated query that should work in Azure Workbook context
        $newQuery = @"
Resources
| where type == "microsoft.operationalinsights/workspaces"
| project id, name, subscriptionId, resourceGroup
| order by name asc
"@
        
        Write-Host "`n🔄 Updating workspace parameter query..." -ForegroundColor Yellow
        $workspaceParam.query = $newQuery
        
        # Also ensure the parameter type and settings are correct
        $workspaceParam.type = 5  # Resource picker type
        $workspaceParam.typeSettings.resourceTypeFilter = @{
            "microsoft.operationalinsights/workspaces" = $true
        }
        $workspaceParam.crossComponentResources = @("value::all")
        
        Write-Host "✅ Updated workspace parameter configuration" -ForegroundColor Green
        
        # Convert back to JSON and update the ARM template
        Write-Host "📝 Updating ARM template..." -ForegroundColor Yellow
        $updatedSerializedData = $serializedData | ConvertTo-Json -Depth 100 -Compress
        $workbookResource.properties.serializedData = $updatedSerializedData
        
        # Create backup
        $backupFile = "$TemplateFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "💾 Creating backup: $backupFile" -ForegroundColor Cyan
        Copy-Item $TemplateFile $backupFile
        
        # Save updated template
        Write-Host "💾 Saving updated ARM template..." -ForegroundColor Yellow
        $armTemplate | ConvertTo-Json -Depth 100 | Out-File $TemplateFile -Encoding UTF8
        
        Write-Host "`n✅ Successfully updated workspace parameter query!" -ForegroundColor Green
        Write-Host "📋 Summary of changes:" -ForegroundColor Cyan
        Write-Host "  • Updated workspace parameter query for better compatibility" -ForegroundColor White
        Write-Host "  • Ensured resource picker type is correctly configured" -ForegroundColor White
        Write-Host "  • Set crossComponentResources to 'value::all'" -ForegroundColor White
        Write-Host "  • Created backup: $backupFile" -ForegroundColor White
        
        # Test the query using Azure CLI
        Write-Host "`n🧪 Testing the query with Azure CLI..." -ForegroundColor Cyan
        $testResult = az graph query -q $newQuery --output json 2>$null
        if ($testResult) {
            $queryData = $testResult | ConvertFrom-Json
            Write-Host "✅ Query test successful! Found $($queryData.count) workspaces" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Could not test query with Azure CLI (may not be logged in)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "❌ Could not find workspace parameter in workbook" -ForegroundColor Red
        return
    }
    
} catch {
    Write-Host "❌ Error updating workspace parameter: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
    return
}

Write-Host "`n🎉 Workspace parameter fix completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Deploy the updated ARM template" -ForegroundColor White
Write-Host "2. Test the workspace dropdown in the Azure portal" -ForegroundColor White
Write-Host "3. Verify that all workspaces are listed correctly" -ForegroundColor White
