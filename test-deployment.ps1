# Test script to validate ARM template deployment
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = ".\AVD Workbook\deploy-avd-data-collection.json"
)

# Check if logged into Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please log into Azure first using Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
    Write-Host "Using Azure context: $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Host "Please install Azure PowerShell and log in first" -ForegroundColor Red
    exit 1
}

# Test template syntax
Write-Host "Testing ARM template syntax..." -ForegroundColor Yellow
try {
    $templateTest = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose
    if ($templateTest) {
        Write-Host "Template validation issues found:" -ForegroundColor Red
        $templateTest | ForEach-Object {
            Write-Host "  - $($_.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Template syntax validation passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "Template validation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test deployment in validation mode
Write-Host "`nTesting deployment in validation mode..." -ForegroundColor Yellow
try {
    $deploymentTest = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Mode Complete -WhatIf -Verbose
    Write-Host "Deployment validation completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Deployment validation failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
}
