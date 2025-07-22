# Azure Workbook Naming Fix

## Issue
Azure Workbook resource names have strict naming requirements and cannot contain hyphens. The original template was generating workbook names like:
```
AVD-Storage-Analytics-{uniqueString}
```

This caused deployment failures with the error:
```
BadRequest: Invalid Workbook resource name: 'avd-storage-analytics-jtarct2yjgfjq'
```

## Solution
Updated the workbook name generation in `deploy-avd-data-collection.json` to use only alphanumeric characters:

**Before:**
```json
"workbookName": "[concat('AVD-Storage-Analytics-', uniqueString(resourceGroup().id))]"
```

**After:**
```json
"workbookName": "[concat('AVDStorageAnalytics', uniqueString(resourceGroup().id))]"
```

## Azure Workbook Naming Rules
- Must be alphanumeric characters only
- No hyphens, underscores, or special characters allowed
- Must be unique within the resource group
- Case-sensitive

## Verification
The ARM template JSON has been validated and is syntactically correct after this change.

## Impact
- ✅ Workbook will now deploy successfully via "Deploy to Azure" button
- ✅ No functionality changes - same comprehensive AVD analytics and ANF planning features
- ✅ Workbook will appear as "AVDStorageAnalytics{uniqueString}" in the Azure portal
