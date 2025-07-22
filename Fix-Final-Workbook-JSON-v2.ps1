#!/usr/bin/env pwsh
param(
    [string]$WorkbookJsonPath = "c:\GitHub\AVDStorageAudit\AVD Workbook\AVD-Storage-Analytics-Workbook.json",
    [string]$TemplateJsonPath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"
)

Write-Host "Fixing final workbook JSON integration..." -ForegroundColor Cyan

try {
    # Read the standalone workbook JSON
    Write-Host "Reading workbook JSON..." -ForegroundColor Yellow
    $workbookContent = Get-Content $WorkbookJsonPath -Raw
    
    # Validate the workbook JSON
    $workbookObject = $workbookContent | ConvertFrom-Json
    Write-Host "Workbook JSON is valid" -ForegroundColor Green
    
    # Read the ARM template
    Write-Host "Reading ARM template..." -ForegroundColor Yellow
    $templateContent = Get-Content $TemplateJsonPath -Raw
    $templateObject = $templateContent | ConvertFrom-Json
    
    # Find the workbook resource
    $workbookResource = $templateObject.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    
    if (-not $workbookResource) {
        throw "Workbook resource not found in ARM template"
    }
    
    # Convert workbook to compact JSON (no formatting)
    $compactWorkbookJson = $workbookContent | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
    
    # Escape the JSON properly for ARM template
    $escapedWorkbookJson = $compactWorkbookJson.Replace('\', '\\').Replace('"', '\"')
    
    # Update the serializedData property
    $workbookResource.properties.serializedData = $escapedWorkbookJson
    
    # Convert template back to JSON with proper formatting
    $updatedTemplateJson = $templateObject | ConvertTo-Json -Depth 100
    
    # Save the updated template
    $updatedTemplateJson | Set-Content $TemplateJsonPath -Encoding UTF8
    
    Write-Host "Successfully updated ARM template with fixed workbook JSON" -ForegroundColor Green
    
    # Validate the final template
    Write-Host "Validating final template..." -ForegroundColor Yellow
    $finalTemplate = Get-Content $TemplateJsonPath -Raw | ConvertFrom-Json
    
    $finalWorkbookResource = $finalTemplate.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    if ($finalWorkbookResource -and $finalWorkbookResource.properties.serializedData) {
        Write-Host "Final template validation successful" -ForegroundColor Green
        Write-Host "Workbook data length: $($finalWorkbookResource.properties.serializedData.Length) characters" -ForegroundColor Cyan
    } else {
        throw "Final template validation failed"
    }
    
} catch {
    Write-Error "Error fixing workbook JSON: $($_.Exception.Message)"
    exit 1
}

Write-Host "Workbook JSON integration completed successfully!" -ForegroundColor Green
