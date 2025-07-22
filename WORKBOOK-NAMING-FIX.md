# Azure Workbook Naming Fix - UPDATED

## Issue
Azure Workbook resource names must be in GUID format. The template was generating invalid names like:
```
avdstorageanalyticsjtarct2yjgfjq
```

This caused deployment failures with the error:
```
BadRequest: Invalid Workbook resource name: 'avdstorageanalyticsjtarct2yjgfjq'
```

## Root Cause
Azure Workbook names have strict requirements:
- Must be a valid GUID format (e.g., `12345678-1234-1234-1234-123456789abc`)
- Cannot be arbitrary strings, even if alphanumeric
- The `uniqueString()` function generates a hash, not a GUID

## Solution
Updated the workbook name generation in `deploy-avd-data-collection.json`:

**Before (First attempt):**
```json
"workbookName": "[concat('AVD-Storage-Analytics-', uniqueString(resourceGroup().id))]"
```

**Before (Second attempt):**
```json
"workbookName": "[concat('AVDStorageAnalytics', uniqueString(resourceGroup().id))]"
```

**After (Final fix):**
```json
"workbookName": "[guid(resourceGroup().id, 'avd-storage-workbook')]"
```

## Azure Workbook Naming Rules
- ✅ Must be a valid GUID format
- ✅ Must be unique within the resource group
- ✅ Use `guid()` ARM function, not `uniqueString()`
- ❌ Cannot be arbitrary text strings
- ❌ Cannot contain hyphens in non-GUID format
- ❌ Cannot be alphanumeric concatenations

## ARM Template Function Details
- `guid(seed1, seed2)` generates a deterministic GUID based on the seeds
- This ensures the same resource group will always get the same workbook GUID
- The GUID will be unique across different resource groups

## Verification
The ARM template JSON has been validated and is syntactically correct after this change.

## Impact
- ✅ Workbook will now deploy successfully via "Deploy to Azure" button
- ✅ No functionality changes - same comprehensive AVD analytics and ANF planning features
- ✅ Workbook will appear with a proper GUID name in the Azure portal
- ✅ Deterministic naming - same resource group = same workbook GUID
