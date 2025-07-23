#!/usr/bin/env pwsh

Write-Host "🔧 Fixing workbook JSON escaping issues..." -ForegroundColor Cyan

try {
    # Read the ARM template
    $templatePath = "AVD Workbook\deploy-avd-data-collection.json"
    $templateContent = Get-Content $templatePath -Raw
    $template = $templateContent | ConvertFrom-Json
    
    # Find the workbook resource
    $workbookResource = $template.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    
    if (-not $workbookResource) {
        throw "Workbook resource not found"
    }
    
    Write-Host "📊 Current serialized data preview (first 200 chars):" -ForegroundColor Yellow
    Write-Host $workbookResource.properties.serializedData.Substring(0, [Math]::Min(200, $workbookResource.properties.serializedData.Length)) -ForegroundColor Cyan
    
    # Read the clean workbook JSON
    $cleanWorkbookPath = "AVD Workbook\AVD-Storage-Analytics-Workbook.json"
    $cleanWorkbookContent = Get-Content $cleanWorkbookPath -Raw
    
    # Validate clean workbook JSON
    $cleanWorkbook = $cleanWorkbookContent | ConvertFrom-Json
    Write-Host "✅ Clean workbook JSON is valid" -ForegroundColor Green
    
    # Create properly escaped JSON for ARM template
    Write-Host "🔧 Creating properly escaped JSON..." -ForegroundColor Yellow
    
    # Method 1: Use PowerShell's built-in JSON conversion with proper escaping
    $compactWorkbookJson = $cleanWorkbook | ConvertTo-Json -Depth 100 -Compress
    
    # For ARM templates, we need to escape quotes and backslashes properly
    # ARM template JSON escaping rules:
    # - Double quotes must be escaped as \"
    # - Backslashes must be escaped as \\
    $escapedWorkbookJson = $compactWorkbookJson.Replace('\', '\\').Replace('"', '\"')
    
    Write-Host "📊 New serialized data preview (first 200 chars):" -ForegroundColor Yellow
    Write-Host $escapedWorkbookJson.Substring(0, [Math]::Min(200, $escapedWorkbookJson.Length)) -ForegroundColor Green
    
    # Update the workbook resource
    $workbookResource.properties.serializedData = $escapedWorkbookJson
    
    # Save the updated template
    $updatedTemplateJson = $template | ConvertTo-Json -Depth 100
    $updatedTemplateJson | Set-Content $templatePath -Encoding UTF8
    
    Write-Host "✅ ARM template updated with properly escaped workbook JSON" -ForegroundColor Green
    Write-Host "📏 New serialized data length: $($escapedWorkbookJson.Length) characters" -ForegroundColor Cyan
    
    # Validate the updated template
    Write-Host "🔍 Validating updated template..." -ForegroundColor Yellow
    $validatedTemplate = Get-Content $templatePath -Raw | ConvertFrom-Json
    $validatedWorkbook = $validatedTemplate.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    
    if ($validatedWorkbook -and $validatedWorkbook.properties.serializedData) {
        # Try to parse the escaped JSON by unescaping it first
        $unescapedJson = $validatedWorkbook.properties.serializedData.Replace('\\', '\').Replace('\"', '"')
        $parsedWorkbook = $unescapedJson | ConvertFrom-Json
        Write-Host "✅ Updated workbook JSON can be parsed correctly" -ForegroundColor Green
        Write-Host "📊 Workbook items: $($parsedWorkbook.items.Count)" -ForegroundColor Cyan
    } else {
        throw "Validation failed - workbook resource not found or empty"
    }
    
    Write-Host "🎉 Workbook JSON escaping fixed successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "❌ Error fixing workbook JSON: $($_.Exception.Message)"
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
}
