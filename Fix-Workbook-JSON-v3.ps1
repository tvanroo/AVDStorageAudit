#!/usr/bin/env pwsh
<#
.SYNOPSIS
Fix the workbook JSON formatting using a simpler, more reliable approach

.DESCRIPTION
This script uses a different strategy - it extracts the current template structure
and properly embeds the workbook JSON using PowerShell's built-in JSON escaping.
#>

$workbookJsonPath = "c:\GitHub\AVDStorageAudit\AVD Workbook\AVD-Storage-Analytics-Workbook.json"
$armTemplatePath = "c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json"

Write-Host "🔧 Fixing workbook JSON with improved approach..." -ForegroundColor Cyan

try {
    # Read the source workbook JSON as a string (not parsed)
    Write-Host "📖 Reading source workbook JSON..." -ForegroundColor Yellow
    $workbookJsonRaw = Get-Content -Path $workbookJsonPath -Raw
    
    # Validate it's proper JSON first
    $null = $workbookJsonRaw | ConvertFrom-Json
    Write-Host "✅ Source workbook JSON is valid" -ForegroundColor Green
    
    # Compress the JSON to single line
    $workbookObj = $workbookJsonRaw | ConvertFrom-Json
    $compressedJson = $workbookObj | ConvertTo-Json -Depth 50 -Compress
    
    Write-Host "📏 Compressed JSON length: $($compressedJson.Length) characters" -ForegroundColor Blue
    
    # Read and parse the ARM template
    Write-Host "📖 Reading ARM template..." -ForegroundColor Yellow
    $armTemplate = Get-Content -Path $armTemplatePath -Raw | ConvertFrom-Json
    
    # Find the workbook resource and update its serializedData
    $workbookResource = $armTemplate.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    
    if ($workbookResource) {
        Write-Host "✅ Found workbook resource in ARM template" -ForegroundColor Green
        
        # Backup the original file
        $backupPath = $armTemplatePath + ".backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "💾 Creating backup: $backupPath" -ForegroundColor Blue
        Copy-Item -Path $armTemplatePath -Destination $backupPath
        
        # Update the serializedData with the compressed JSON
        $workbookResource.properties.serializedData = $compressedJson
        
        # Convert back to JSON with proper formatting
        Write-Host "🔄 Converting ARM template back to JSON..." -ForegroundColor Yellow
        $newArmJson = $armTemplate | ConvertTo-Json -Depth 50
        
        # Write the fixed ARM template
        Write-Host "💾 Writing fixed ARM template..." -ForegroundColor Yellow
        Set-Content -Path $armTemplatePath -Value $newArmJson -Encoding UTF8
        
        # Validate the updated template
        Write-Host "🔍 Validating updated ARM template..." -ForegroundColor Yellow
        try {
            $validationTest = Get-Content -Path $armTemplatePath -Raw | ConvertFrom-Json
            Write-Host "✅ ARM template JSON is valid" -ForegroundColor Green
            
            Write-Host "" -ForegroundColor White
            Write-Host "✅ SUCCESS: Fixed workbook JSON formatting!" -ForegroundColor Green
            Write-Host "📁 Backup saved to: $backupPath" -ForegroundColor Blue
            
            Write-Host "" -ForegroundColor White
            Write-Host "🎯 NEXT STEPS:" -ForegroundColor Cyan
            Write-Host "1. Test the ARM template deployment" -ForegroundColor White
            Write-Host "2. Verify the workbook loads correctly in Azure portal" -ForegroundColor White
            Write-Host "3. If successful, commit changes to GitHub repository" -ForegroundColor White
            
            return $true
        }
        catch {
            Write-Host "❌ ARM template validation failed: $($_.Exception.Message)" -ForegroundColor Red
            # Restore from backup
            Copy-Item -Path $backupPath -Destination $armTemplatePath -Force
            Write-Host "🔄 Restored from backup" -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Write-Host "❌ Could not find workbook resource in ARM template" -ForegroundColor Red
        return $false
    }
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}
