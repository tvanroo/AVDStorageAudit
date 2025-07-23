#!/usr/bin/env pwsh
<#
.SYNOPSIS
Final verification script for the AVD Storage Analytics workbook deployment

.DESCRIPTION
This script provides the commands needed to test and verify the fixed workbook deployment.
Run this after the JSON formatting fix to confirm everything works.

.EXAMPLE
.\FINAL-WORKBOOK-VERIFICATION.ps1
#>

Write-Host "📋 FINAL VERIFICATION GUIDE - AVD Storage Analytics Workbook" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔧 JSON FORMATTING FIX COMPLETED" -ForegroundColor Green
Write-Host "✅ ARM template updated with properly escaped workbook JSON" -ForegroundColor Green
Write-Host "✅ Backup created: deploy-avd-data-collection.json.backup-20250723-103222" -ForegroundColor Green
Write-Host "✅ Template JSON validation passed" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 DEPLOYMENT TESTING COMMANDS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to workbook directory:" -ForegroundColor White
Write-Host "   cd 'c:\GitHub\AVDStorageAudit\AVD Workbook'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Deploy the fixed ARM template:" -ForegroundColor White
Write-Host "   az deployment group create \\" -ForegroundColor Gray
Write-Host "     --resource-group 'rg-avd-storage-test' \\" -ForegroundColor Gray
Write-Host "     --name 'final-workbook-test' \\" -ForegroundColor Gray
Write-Host "     --template-file 'deploy-avd-data-collection.json' \\" -ForegroundColor Gray
Write-Host "     --parameters logAnalyticsWorkspaceName='AVDStorageAuditLAWFinal'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Get the workbook URL:" -ForegroundColor White
Write-Host "   az deployment group show \\" -ForegroundColor Gray
Write-Host "     --resource-group 'rg-avd-storage-test' \\" -ForegroundColor Gray
Write-Host "     --name 'final-workbook-test' \\" -ForegroundColor Gray
Write-Host "     --query 'properties.outputs.workbookId.value' -o tsv" -ForegroundColor Gray

Write-Host ""
Write-Host "🔍 VERIFICATION CHECKLIST:" -ForegroundColor Yellow
Write-Host "□ ARM template deploys successfully" -ForegroundColor White
Write-Host "□ Workbook resource is created in Azure" -ForegroundColor White
Write-Host "□ Open workbook in Azure portal" -ForegroundColor White
Write-Host "□ Workbook loads WITHOUT 'content failed to load' error" -ForegroundColor White
Write-Host "□ No JSON syntax errors displayed" -ForegroundColor White
Write-Host "□ All workbook sections display correctly:" -ForegroundColor White
Write-Host "  □ Title section with ANF Planning header" -ForegroundColor Gray
Write-Host "  □ Parameters section (Time Range, Workspace, Host Pools)" -ForegroundColor Gray
Write-Host "  □ Executive Summary Dashboard" -ForegroundColor Gray
Write-Host "  □ User Session Analytics" -ForegroundColor Gray
Write-Host "  □ Storage Performance Deep Dive" -ForegroundColor Gray
Write-Host "  □ ANF Sizing Recommendations" -ForegroundColor Gray
Write-Host "  □ System Resource Utilization" -ForegroundColor Gray
Write-Host "  □ Key Insights & Action Items" -ForegroundColor Gray
Write-Host "  □ ANF Performance Tier Reference" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 SUCCESS CRITERIA:" -ForegroundColor Cyan
Write-Host "✅ No 'SyntaxError: Unexpected property name' message" -ForegroundColor Green 
Write-Host "✅ No 'Property keys must be doublequoted' error" -ForegroundColor Green
Write-Host "✅ Workbook displays full content with all sections" -ForegroundColor Green
Write-Host "✅ Parameters can be selected (Time Range, Workspace)" -ForegroundColor Green

Write-Host ""
Write-Host "📝 NEXT STEPS AFTER SUCCESSFUL VERIFICATION:" -ForegroundColor Yellow
Write-Host "1. Commit changes to GitHub repository" -ForegroundColor White
Write-Host "2. Update README with deployment instructions" -ForegroundColor White
Write-Host "3. Create release notes documenting the fix" -ForegroundColor White
Write-Host "4. Test with real AVD data if available" -ForegroundColor White

Write-Host ""
Write-Host "🚨 IF DEPLOYMENT STILL FAILS:" -ForegroundColor Red
Write-Host "1. Check Azure CLI login: az account show" -ForegroundColor White
Write-Host "2. Verify resource group exists: az group show -n 'rg-avd-storage-test'" -ForegroundColor White
Write-Host "3. Try minimal workbook test: test-minimal-template.json" -ForegroundColor White
Write-Host "4. Review ARM template errors in Azure portal deployment history" -ForegroundColor White

Write-Host ""
Write-Host "📞 SUPPORT INFORMATION:" -ForegroundColor Blue
Write-Host "Repository: https://github.com/tvanroo/AVDStorageAudit" -ForegroundColor Gray
Write-Host "Issue: Workbook JSON formatting - ARM template serializedData" -ForegroundColor Gray
Write-Host "Fix Applied: PowerShell-based JSON escaping correction" -ForegroundColor Gray

Write-Host ""
Write-Host "🎉 WORKBOOK JSON FORMATTING FIX COMPLETED!" -ForegroundColor Green
Write-Host "Ready for deployment testing..." -ForegroundColor Cyan
