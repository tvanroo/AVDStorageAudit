# Validate AVD Storage Analytics Data Collection
# This script validates that data is being collected properly after deployment

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceName
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Validating AVD Storage Analytics Data Collection" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green

# Import required modules
Import-Module Az.Accounts, Az.OperationalInsights, Az.Monitor -Force

# Connect to Azure
try {
    $context = Get-AzContext
    if (-not $context -or $context.Subscription.Id -ne $SubscriptionId) {
        Connect-AzAccount -SubscriptionId $SubscriptionId
    }
    Write-Host "✅ Connected to Azure subscription" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    exit 1
}

# Get Log Analytics workspace
try {
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
    Write-Host "✅ Found Log Analytics workspace: $WorkspaceName" -ForegroundColor Green
}
catch {
    Write-Error "Failed to find workspace: $($_.Exception.Message)"
    exit 1
}

# Define validation queries
$validationQueries = @{
    "Performance Counters" = @{
        Query = "Perf | where TimeGenerated >= ago(1h) | summarize count() by ObjectName | order by count_ desc"
        MinExpected = 1
        Description = "Performance counter data collection"
    }
    "AVD Events" = @{
        Query = "Event | where TimeGenerated >= ago(1h) and Source contains 'TerminalServices' | summarize count()"
        MinExpected = 0
        Description = "AVD-related event logs"
    }
    "FSLogix Events" = @{
        Query = "Event | where TimeGenerated >= ago(1h) and Source contains 'FSLogix' | summarize count()"
        MinExpected = 0
        Description = "FSLogix application events"
    }
    "Disk Performance" = @{
        Query = "Perf | where TimeGenerated >= ago(1h) and ObjectName == 'LogicalDisk' | summarize count() by CounterName"
        MinExpected = 1
        Description = "Disk performance metrics"
    }
    "Memory Metrics" = @{
        Query = "Perf | where TimeGenerated >= ago(1h) and ObjectName == 'Memory' | summarize count()"
        MinExpected = 1
        Description = "Memory utilization metrics"
    }
    "Session Host Activity" = @{
        Query = "Perf | where TimeGenerated >= ago(1h) and ObjectName == 'Terminal Services' | summarize count()"
        MinExpected = 0
        Description = "Terminal Services metrics"
    }
}

$results = @()

Write-Host "`n🧪 Running validation queries..." -ForegroundColor Yellow

foreach ($testName in $validationQueries.Keys) {
    $test = $validationQueries[$testName]
    
    try {
        Write-Host "  Testing: $testName" -ForegroundColor Cyan
        
        $queryResult = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspace.CustomerId -Query $test.Query
        
        if ($queryResult.Results) {
            $resultCount = $queryResult.Results.Count
            if ($testName -eq "Performance Counters" -and $queryResult.Results) {
                $resultCount = ($queryResult.Results | Measure-Object -Property count_ -Sum).Sum
            }
            elseif ($testName -eq "Disk Performance" -and $queryResult.Results) {
                $resultCount = ($queryResult.Results | Measure-Object -Property count_ -Sum).Sum
            }
            elseif ($queryResult.Results[0].PSObject.Properties.Name -contains "count_") {
                $resultCount = $queryResult.Results[0].count_
            }
            
            if ($resultCount -ge $test.MinExpected) {
                Write-Host "    ✅ PASS: Found $resultCount records" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    Test = $testName
                    Status = "PASS"
                    Count = $resultCount
                    Description = $test.Description
                }
            }
            else {
                Write-Host "    ⚠️  WARNING: Found $resultCount records (expected >= $($test.MinExpected))" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    Test = $testName
                    Status = "WARNING"
                    Count = $resultCount
                    Description = $test.Description
                }
            }
        }
        else {
            Write-Host "    ❌ FAIL: No data found" -ForegroundColor Red
            $results += [PSCustomObject]@{
                Test = $testName
                Status = "FAIL"
                Count = 0
                Description = $test.Description
            }
        }
    }
    catch {
        Write-Host "    ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Test = $testName
            Status = "ERROR"
            Count = 0
            Description = "Query failed: $($_.Exception.Message)"
        }
    }
}

# Check diagnostic settings
Write-Host "`n🔧 Checking diagnostic settings..." -ForegroundColor Yellow

try {
    # Check for AVD Host Pools with diagnostic settings
    $hostPools = Get-AzWvdHostPool -ErrorAction SilentlyContinue
    $hostPoolsWithDiagnostics = 0
    
    foreach ($hostPool in $hostPools) {
        $diagnostics = Get-AzDiagnosticSetting -ResourceId $hostPool.Id -ErrorAction SilentlyContinue
        if ($diagnostics) {
            $hostPoolsWithDiagnostics++
        }
    }
    
    Write-Host "  Host Pools: $($hostPools.Count) total, $hostPoolsWithDiagnostics with diagnostics" -ForegroundColor Cyan
    
    # Check storage accounts
    $storageAccounts = Get-AzStorageAccount | Where-Object { 
        $_.StorageAccountName -match 'avd|profile|fslogix|vdi|wvd' -or 
        $_.Tags.ContainsKey('AVD') -or 
        $_.Tags.ContainsKey('FSLogix') 
    }
    
    $storageWithDiagnostics = 0
    foreach ($storage in $storageAccounts) {
        $diagnostics = Get-AzDiagnosticSetting -ResourceId $storage.Id -ErrorAction SilentlyContinue
        if ($diagnostics) {
            $storageWithDiagnostics++
        }
    }
    
    Write-Host "  Storage Accounts: $($storageAccounts.Count) AVD-related, $storageWithDiagnostics with diagnostics" -ForegroundColor Cyan
}
catch {
    Write-Host "  ⚠️  Could not validate diagnostic settings: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Validation Summary" -ForegroundColor Green
Write-Host "════════════════════" -ForegroundColor Green

$passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$warningCount = ($results | Where-Object { $_.Status -eq "WARNING" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$errorCount = ($results | Where-Object { $_.Status -eq "ERROR" }).Count

Write-Host "✅ Passed: $passCount" -ForegroundColor Green
Write-Host "⚠️  Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "🔴 Errors: $errorCount" -ForegroundColor Red

# Detailed results
Write-Host "`n📋 Detailed Results:" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Recommendations
Write-Host "`n💡 Recommendations:" -ForegroundColor Yellow

if ($failCount -gt 0 -or $errorCount -gt 0) {
    Write-Host "❗ Issues detected. Consider the following:" -ForegroundColor Red
    Write-Host "  1. Wait 15-30 minutes for initial data collection" -ForegroundColor White
    Write-Host "  2. Verify session hosts have Azure Monitor Agent installed" -ForegroundColor White
    Write-Host "  3. Check that diagnostic settings were created successfully" -ForegroundColor White
    Write-Host "  4. Ensure AVD resources are actively being used" -ForegroundColor White
}
elseif ($warningCount -gt 0) {
    Write-Host "⚠️  Some data collection may be limited:" -ForegroundColor Yellow
    Write-Host "  1. FSLogix events require active profile usage" -ForegroundColor White
    Write-Host "  2. AVD events require active user sessions" -ForegroundColor White
    Write-Host "  3. Consider running during business hours for complete data" -ForegroundColor White
}
else {
    Write-Host "🎉 All validations passed! Data collection is working properly." -ForegroundColor Green
    Write-Host "  You can now deploy the AVD Storage Analytics workbook." -ForegroundColor White
}

Write-Host "`n🔗 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy the AVD Storage Analytics workbook" -ForegroundColor White
Write-Host "  2. Allow 24 hours for comprehensive data collection" -ForegroundColor White
Write-Host "  3. Review analytics for ANF planning insights" -ForegroundColor White

return $results
