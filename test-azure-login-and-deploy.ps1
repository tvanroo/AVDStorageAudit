#!/usr/bin/env pwsh
# Azure CLI Login and Workbook Deployment Test Script
# Uses device code flow for non-GUI environments

param(
    [string]$ResourceGroupName = "rg-avd-storage-test",
    [string]$Location = "East US",
    [string]$SubscriptionId = "",
    [switch]$SkipLogin
)

Write-Host "🚀 Azure CLI Workbook Deployment Test" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Function to check Azure CLI installation
function Test-AzureCLI {
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        Write-Host "✅ Azure CLI found: $($azVersion.'azure-cli')" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
        Write-Host "Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
        return $false
    }
}

# Function to login using device code
function Invoke-AzureLogin {
    Write-Host "🔐 Starting Azure CLI login with device code..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Start device code login
        Write-Host "📱 Initiating device code login..." -ForegroundColor Cyan
        $loginResult = az login --use-device-code 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully logged in to Azure!" -ForegroundColor Green
            
            # Show current account
            $account = az account show --output json | ConvertFrom-Json
            Write-Host "📋 Current subscription:" -ForegroundColor Cyan
            Write-Host "   Name: $($account.name)" -ForegroundColor White
            Write-Host "   ID: $($account.id)" -ForegroundColor White
            Write-Host "   Tenant: $($account.tenantId)" -ForegroundColor White
            
            return $account.id
        } else {
            Write-Host "❌ Login failed: $loginResult" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "❌ Login error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to set subscription if provided
function Set-AzureSubscription {
    param([string]$SubId)
    
    if ($SubId) {
        Write-Host "🔄 Setting subscription to: $SubId" -ForegroundColor Yellow
        try {
            az account set --subscription $SubId
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Subscription set successfully" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Failed to set subscription" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ Subscription error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# Function to create resource group
function New-TestResourceGroup {
    param([string]$Name, [string]$Location)
    
    Write-Host "📦 Creating test resource group: $Name" -ForegroundColor Yellow
    
    try {
        # Check if resource group exists
        $rgExists = az group exists --name $Name --output tsv
        
        if ($rgExists -eq "true") {
            Write-Host "✅ Resource group '$Name' already exists" -ForegroundColor Green
            return $true
        } else {
            # Create resource group
            $result = az group create --name $Name --location $Location --output json
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Resource group '$Name' created successfully" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Failed to create resource group: $result" -ForegroundColor Red
                return $false
            }
        }
    } catch {
        Write-Host "❌ Resource group error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test workbook deployment
function Test-WorkbookDeployment {
    param([string]$ResourceGroup, [string]$TemplateFile, [string]$TestName)
    
    Write-Host "🧪 Testing: $TestName" -ForegroundColor Cyan
    Write-Host "   Template: $TemplateFile" -ForegroundColor White
    Write-Host "   Resource Group: $ResourceGroup" -ForegroundColor White
    
    try {
        # First validate the template
        Write-Host "🔍 Validating template..." -ForegroundColor Yellow
        $validateResult = az deployment group validate `
            --resource-group $ResourceGroup `
            --template-file $TemplateFile `
            --output json 2>&1
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Template validation passed" -ForegroundColor Green
            
            # Deploy the template
            Write-Host "🚀 Deploying template..." -ForegroundColor Yellow
            $deploymentName = "workbook-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            
            $deployResult = az deployment group create `
                --resource-group $ResourceGroup `
                --name $deploymentName `
                --template-file $TemplateFile `
                --output json 2>&1
                
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Deployment successful!" -ForegroundColor Green
                $deployment = $deployResult | ConvertFrom-Json
                Write-Host "   Deployment Name: $($deployment.name)" -ForegroundColor White
                Write-Host "   Provisioning State: $($deployment.properties.provisioningState)" -ForegroundColor White
                return $true
            } else {
                Write-Host "❌ Deployment failed:" -ForegroundColor Red
                Write-Host $deployResult -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Template validation failed:" -ForegroundColor Red
            Write-Host $validateResult -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Deployment error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    # Check Azure CLI
    if (-not (Test-AzureCLI)) {
        exit 1
    }
    
    # Login if not skipped
    if (-not $SkipLogin) {
        $currentSubscription = Invoke-AzureLogin
        if (-not $currentSubscription) {
            Write-Host "❌ Login failed. Cannot continue." -ForegroundColor Red
            exit 1
        }
        
        # Use provided subscription or current one
        if (-not $SubscriptionId) {
            $SubscriptionId = $currentSubscription
        }
    }
    
    # Set subscription if provided
    if (-not (Set-AzureSubscription -SubId $SubscriptionId)) {
        exit 1
    }
    
    # Create test resource group
    if (-not (New-TestResourceGroup -Name $ResourceGroupName -Location $Location)) {
        exit 1
    }
    
    Write-Host ""
    Write-Host "🧪 ITERATIVE WORKBOOK TESTING" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Cyan
    
    # Test 1: Simple workbook (if exists)
    $simpleTemplate = ".\test-workbook-simple.json"
    if (Test-Path $simpleTemplate) {
        Write-Host ""
        if (Test-WorkbookDeployment -ResourceGroup $ResourceGroupName -TemplateFile $simpleTemplate -TestName "Simple Workbook Test") {
            Write-Host "✅ Simple workbook test passed!" -ForegroundColor Green
        } else {
            Write-Host "❌ Simple workbook test failed - checking template..." -ForegroundColor Red
        }
    }
    
    # Test 2: Minimal workbook (if exists)
    $minimalTemplate = ".\test-workbook-minimal.json"
    if (Test-Path $minimalTemplate) {
        Write-Host ""
        if (Test-WorkbookDeployment -ResourceGroup $ResourceGroupName -TemplateFile $minimalTemplate -TestName "Minimal Workbook Test") {
            Write-Host "✅ Minimal workbook test passed!" -ForegroundColor Green
        } else {
            Write-Host "❌ Minimal workbook test failed - checking template..." -ForegroundColor Red
        }
    }
    
    # Test 3: Full template
    $fullTemplate = ".\AVD Workbook\deploy-avd-data-collection.json"
    if (Test-Path $fullTemplate) {
        Write-Host ""
        if (Test-WorkbookDeployment -ResourceGroup $ResourceGroupName -TemplateFile $fullTemplate -TestName "Full AVD Template Test") {
            Write-Host "✅ Full template test passed!" -ForegroundColor Green
        } else {
            Write-Host "❌ Full template test failed - analyzing errors..." -ForegroundColor Red
            
            # Try to get more detailed error information
            Write-Host ""
            Write-Host "🔍 Getting deployment error details..." -ForegroundColor Yellow
            $deployments = az deployment group list --resource-group $ResourceGroupName --output json | ConvertFrom-Json
            $latestDeployment = $deployments | Sort-Object properties.timestamp -Descending | Select-Object -First 1
            
            if ($latestDeployment) {
                Write-Host "📋 Latest deployment: $($latestDeployment.name)" -ForegroundColor Cyan
                Write-Host "   Status: $($latestDeployment.properties.provisioningState)" -ForegroundColor White
                
                if ($latestDeployment.properties.provisioningState -eq "Failed") {
                    $errorDetails = az deployment group show --resource-group $ResourceGroupName --name $latestDeployment.name --output json | ConvertFrom-Json
                    if ($errorDetails.properties.error) {
                        Write-Host "❌ Error Details:" -ForegroundColor Red
                        Write-Host "   Code: $($errorDetails.properties.error.code)" -ForegroundColor Red
                        Write-Host "   Message: $($errorDetails.properties.error.message)" -ForegroundColor Red
                    }
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "🎯 TESTING COMPLETED" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "Location: $Location" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 To clean up test resources:" -ForegroundColor Yellow
    Write-Host "   az group delete --name $ResourceGroupName --yes --no-wait" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Script error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
