#!/usr/bin/env pwsh

Write-Host "🔍 Testing JSON structure and workbook configuration..." -ForegroundColor Cyan

# Test 1: Validate JSON structure
Write-Host "`n📋 TEST 1: Validating ARM template JSON structure..." -ForegroundColor Yellow

try {
    $templatePath = "AVD Workbook\deploy-avd-data-collection.json"
    $templateContent = Get-Content $templatePath -Raw
    $template = $templateContent | ConvertFrom-Json
    Write-Host "✅ ARM template JSON is valid" -ForegroundColor Green
    
    # Find workbook resource
    $workbookResource = $template.resources | Where-Object { $_.type -eq "Microsoft.Insights/workbooks" }
    if ($workbookResource) {
        Write-Host "✅ Workbook resource found" -ForegroundColor Green
        Write-Host "   - Display Name: $($workbookResource.properties.displayName)" -ForegroundColor Cyan
        Write-Host "   - Category: $($workbookResource.properties.category)" -ForegroundColor Cyan
        Write-Host "   - API Version: $($workbookResource.apiVersion)" -ForegroundColor Cyan
        Write-Host "   - Serialized Data Length: $($workbookResource.properties.serializedData.Length) characters" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No workbook resource found" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ ARM template JSON validation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Validate workbook JSON
Write-Host "`n📊 TEST 2: Validating embedded workbook JSON..." -ForegroundColor Yellow

try {
    if ($workbookResource -and $workbookResource.properties.serializedData) {
        $workbookJson = $workbookResource.properties.serializedData
        
        # Try to parse the embedded workbook JSON
        $workbookData = $workbookJson | ConvertFrom-Json
        Write-Host "✅ Embedded workbook JSON is valid" -ForegroundColor Green
        Write-Host "   - Version: $($workbookData.version)" -ForegroundColor Cyan
        Write-Host "   - Items count: $($workbookData.items.Count)" -ForegroundColor Cyan
        
        # Check for common issues
        if ($workbookData.items) {
            $titleItem = $workbookData.items | Where-Object { $_.name -eq "Title" }
            if ($titleItem) {
                Write-Host "✅ Title section found" -ForegroundColor Green
            } else {
                Write-Host "⚠️  No title section found" -ForegroundColor Yellow
            }
            
            $paramItems = $workbookData.items | Where-Object { $_.type -eq 9 }
            Write-Host "📊 Parameter sections: $($paramItems.Count)" -ForegroundColor Cyan
            
            $queryItems = $workbookData.items | Where-Object { $_.type -eq 3 }
            Write-Host "📈 Query sections: $($queryItems.Count)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ No serialized data found in workbook resource" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Embedded workbook JSON validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This might indicate JSON escaping issues or corruption" -ForegroundColor Yellow
}

# Test 3: Check for common ARM template issues
Write-Host "`n🔧 TEST 3: Checking for common ARM template issues..." -ForegroundColor Yellow

try {
    # Check variables section
    if ($template.variables) {
        $workbookNameVar = $template.variables.workbookName
        if ($workbookNameVar) {
            Write-Host "✅ workbookName variable found: $workbookNameVar" -ForegroundColor Green
        } else {
            Write-Host "❌ workbookName variable missing" -ForegroundColor Red
        }
    }
    
    # Check dependencies
    if ($workbookResource.dependsOn) {
        Write-Host "✅ Workbook dependencies found: $($workbookResource.dependsOn.Count)" -ForegroundColor Green
        foreach ($dep in $workbookResource.dependsOn) {
            Write-Host "   - $dep" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠️  No dependencies defined for workbook" -ForegroundColor Yellow
    }
    
    # Check parameters referenced in workbook
    $workbookSourceId = $workbookResource.properties.sourceId
    if ($workbookSourceId -match "parameters\('([^']+)'\)") {
        $paramName = $Matches[1]
        if ($template.parameters.$paramName) {
            Write-Host "✅ Referenced parameter '$paramName' exists" -ForegroundColor Green
        } else {
            Write-Host "❌ Referenced parameter '$paramName' not found" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ ARM template validation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 JSON validation completed!" -ForegroundColor Green
Write-Host "`n💡 Next steps to test deployment:" -ForegroundColor Cyan
Write-Host "   1. Login to Azure: az login" -ForegroundColor White
Write-Host "   2. Run: pwsh test-workbook-cli.ps1" -ForegroundColor White
