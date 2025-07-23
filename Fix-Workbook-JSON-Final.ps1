#!/usr/bin/env pwsh
<#
.SYNOPSIS
Fix the workbook JSON formatting in the ARM template

.DESCRIPTION
This script properly escapes the workbook JSON for embedding in the ARM template's serializedData field.
The current template has triple-escaped JSON which causes parsing errors in Azure portal.

.EXAMPLE
.\Fix-Workbook-JSON-Final.ps1
#>

# Read the source workbook JSON
$workbookJsonPath = "c:\GitHub\AVDStorageAudit\AVD Workbook\AVD-Storage-Analytics-Workbook.json"
$armTemplatePath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"

Write-Host "🔧 Fixing workbook JSON formatting in ARM template..." -ForegroundColor Cyan

try {
    # Read and validate the source workbook JSON
    Write-Host "📖 Reading source workbook JSON..." -ForegroundColor Yellow
    $workbookContent = Get-Content -Path $workbookJsonPath -Raw
    $workbookJson = $workbookContent | ConvertFrom-Json
    Write-Host "✅ Source workbook JSON is valid" -ForegroundColor Green
    
    # Compress the JSON (remove whitespace) and properly escape for ARM template
    Write-Host "🔄 Compressing and escaping JSON for ARM template..." -ForegroundColor Yellow
    $compressedJson = $workbookContent | ConvertFrom-Json | ConvertTo-Json -Depth 50 -Compress
    
    # Escape the JSON for ARM template embedding (simple escaping, not triple escaping)
    $escapedJson = $compressedJson -replace '"', '\"' -replace '\\', '\\'
    
    Write-Host "📏 Compressed JSON length: $($escapedJson.Length) characters" -ForegroundColor Blue
    
    # Read the ARM template
    Write-Host "📖 Reading ARM template..." -ForegroundColor Yellow
    $armContent = Get-Content -Path $armTemplatePath -Raw
    
    # Find the serializedData line pattern
    $serializedDataPattern = '"serializedData":\s*"[^"]*"'
    
    if ($armContent -match $serializedDataPattern) {
        Write-Host "✅ Found serializedData in ARM template" -ForegroundColor Green
        
        # Replace the serializedData with properly escaped JSON
        $newSerializedData = '"serializedData": "' + $escapedJson + '"'
        $newArmContent = $armContent -replace $serializedDataPattern, $newSerializedData
        
        # Backup the original file
        $backupPath = $armTemplatePath + ".backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "💾 Creating backup: $backupPath" -ForegroundColor Blue
        Copy-Item -Path $armTemplatePath -Destination $backupPath
        
        # Write the fixed ARM template
        Write-Host "💾 Writing fixed ARM template..." -ForegroundColor Yellow
        Set-Content -Path $armTemplatePath -Value $newArmContent -Encoding UTF8
        
        Write-Host "✅ SUCCESS: Fixed workbook JSON formatting in ARM template!" -ForegroundColor Green
        Write-Host "📁 Backup saved to: $backupPath" -ForegroundColor Blue
        
        # Validate the JSON in the updated template
        Write-Host "🔍 Validating ARM template JSON..." -ForegroundColor Yellow
        try {
            $armJson = Get-Content -Path $armTemplatePath -Raw | ConvertFrom-Json
            Write-Host "✅ ARM template JSON is valid" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ ARM template JSON validation failed: $($_.Exception.Message)" -ForegroundColor Red
            # Restore from backup
            Copy-Item -Path $backupPath -Destination $armTemplatePath -Force
            Write-Host "🔄 Restored from backup due to JSON validation failure" -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "" -ForegroundColor White
        Write-Host "🎯 NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Test the ARM template deployment:" -ForegroundColor White
        Write-Host "   az deployment group create --resource-group 'rg-avd-storage-test' --template-file '$armTemplatePath'" -ForegroundColor Gray
        Write-Host "2. Verify the workbook loads correctly in Azure portal" -ForegroundColor White
        Write-Host "3. If successful, commit changes to GitHub repository" -ForegroundColor White
        
        return $true
    }
    else {
        Write-Host "❌ Could not find serializedData pattern in ARM template" -ForegroundColor Red
        return $false
    }
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}
