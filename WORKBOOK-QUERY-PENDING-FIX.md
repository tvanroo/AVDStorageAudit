# Fix for "Query Pending" Workbook Issue - RESOLVED

## ✅ **Issue Fixed**: Workspace Parameter Query Missing

### **Problem**
The Azure Workbook was showing "<query pending>" in the Log Analytics workspace dropdown because the workspace parameter was missing its query definition.

### **Root Cause**
The workspace parameter in the workbook JSON had:
- ✅ Correct parameter type (5 = resource picker)
- ✅ Correct resource type filter (`microsoft.operationalinsights/workspaces`)
- ❌ **Missing `query` property** to populate the dropdown
- ❌ **Missing `crossComponentResources`** for cross-subscription access

### **Solution Applied**
Updated the workspace parameter in both:
1. **Standalone workbook**: `AVD-Storage-Analytics-Workbook.json`
2. **ARM template**: `deploy-avd-data-collection.json`

**Added missing properties:**
```json
{
  "id": "workspace",
  "name": "Workspace", 
  "type": 5,
  "query": "Resources\r\n| where type == 'microsoft.operationalinsights/workspaces'\r\n| project id, name, subscriptionId, resourceGroup\r\n| order by name asc",
  "crossComponentResources": ["value::all"],
  "typeSettings": {
    "resourceTypeFilter": {
      "microsoft.operationalinsights/workspaces": true
    },
    "additionalResourceOptions": ["value::1"],
    "showDefault": false
  }
}
```

### **Key Components of the Fix**
1. **`query`**: KQL query to fetch all Log Analytics workspaces in accessible subscriptions
2. **`crossComponentResources: ["value::all"]`**: Enables cross-subscription/resource group access
3. **`showDefault: false`**: Prevents auto-selection of wrong workspace
4. **`additionalResourceOptions: ["value::1"]`**: Allows selection of current workspace

### **Expected Result**
- ✅ Workspace dropdown will populate with available Log Analytics workspaces
- ✅ Users can select the appropriate workspace containing AVD data
- ✅ All workbook queries will execute against the selected workspace
- ✅ No more "query pending" status

### **Verification**
1. **ARM Template**: ✅ Updated with corrected workbook JSON (27,286 characters)
2. **JSON Syntax**: ✅ Validated - template passes syntax check
3. **Query Embedded**: ✅ Workspace query properly escaped and embedded
4. **Standalone File**: ✅ Updated for future manual deployments

### **Files Updated**
- `c:\GitHub\AVDStorageAudit\AVD Workbook\AVD-Storage-Analytics-Workbook.json`
- `c:\GitHub\AVDStorageAudit\AVD Workbook\deploy-avd-data-collection.json`
- `c:\GitHub\AVDStorageAudit\Update-ARM-Workbook.ps1` (utility script)

### **Deployment Impact**
- **Existing Deployments**: Will need to redeploy workbook to get the fix
- **New Deployments**: Will work correctly with "Deploy to Azure" button
- **No Breaking Changes**: All existing queries and functionality preserved

### **Status**: 🎉 **RESOLVED** - Ready for deployment testing
