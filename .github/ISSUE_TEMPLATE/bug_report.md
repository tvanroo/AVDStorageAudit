---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Deploy the template with parameters '...'
2. Run the script '...'
3. Check the Log Analytics workspace '...'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots/Logs**
If applicable, add screenshots or log outputs to help explain your problem.

**Environment (please complete the following information):**
 - Azure Region: [e.g. East US]
 - PowerShell Version: [e.g. 5.1, 7.3]
 - Azure PowerShell Module Version: [e.g. 10.4.1]
 - AVD Host Pool Count: [e.g. 2]
 - Storage Account Types: [e.g. Azure Files, Azure NetApp Files]

**ARM Template Parameters Used**
```json
{
  "logAnalyticsWorkspaceName": "your-workspace-name",
  "dataRetentionDays": 90,
  "enableHostPoolDiagnostics": true,
  "enableStorageDiagnostics": true
}
```

**Error Messages**
```
Paste any error messages here
```

**Additional context**
Add any other context about the problem here.
