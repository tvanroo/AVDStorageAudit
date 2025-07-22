# 📊 Azure Workbook Deployment Guide

## Quick Import Instructions

### Import the AVD Storage Analytics Workbook

1. **Navigate to Azure Portal**
   - Go to **Log Analytics workspaces** > Select your workspace
   - Click **Workbooks** in the left navigation

2. **Import the Workbook**
   ```bash
   # Option 1: Direct import from GitHub
   # Download the workbook JSON file
   wget https://raw.githubusercontent.com/tvanroo/AVDStorageAudit/main/AVD%20Workbook/AVD-Storage-Analytics-Workbook.json
   ```

3. **Create New Workbook**
   - Click **+ New** in the Azure Portal Workbooks section
   - Click **Advanced Editor** (</> icon)
   - Replace the default JSON with the contents of `AVD-Storage-Analytics-Workbook.json`
   - Click **Apply** then **Done Editing**
   - Click **Save** and provide a name: `AVD Storage Analytics & ANF Planning`

### Alternative: ARM Template Import

Deploy the workbook using an ARM template:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workbookName": {
      "type": "string",
      "defaultValue": "AVD Storage Analytics & ANF Planning"
    },
    "workspaceResourceId": {
      "type": "string",
      "metadata": {
        "description": "Resource ID of the Log Analytics workspace"
      }
    }
  },
  "resources": [
    {
      "type": "microsoft.insights/workbooks",
      "apiVersion": "2022-04-01",
      "name": "[guid(parameters('workbookName'))]",
      "location": "[resourceGroup().location]",
      "properties": {
        "displayName": "[parameters('workbookName')]",
        "serializedData": "[uri(deployment().properties.templateLink.uri, 'AVD-Storage-Analytics-Workbook.json')]",
        "category": "workbook",
        "sourceId": "[parameters('workspaceResourceId')]"
      }
    }
  ]
}
```

## 🔧 Configuration Requirements

### Prerequisites
- ✅ Log Analytics workspace deployed with AVD data collection
- ✅ AVD session hosts configured with Azure Monitor Agent
- ✅ Performance counters collecting for at least 1 hour
- ✅ Appropriate permissions (Log Analytics Reader or higher)

### Required Data Sources
The workbook expects these data streams:

| **Data Type** | **Source** | **Tables** |
|---------------|------------|------------|
| **Performance Counters** | AVD Session Hosts | `Perf` |
| **Event Logs** | Terminal Services, FSLogix | `Event` |
| **System Metrics** | CPU, Memory, Network | `Perf` |
| **Storage Metrics** | Disk I/O, Latency, Queue Depth | `Perf` |

### Performance Counters Required

```powershell
# Disk Performance
"LogicalDisk(*)\Disk Read Bytes/sec"
"LogicalDisk(*)\Disk Write Bytes/sec"
"LogicalDisk(*)\Disk Reads/sec"
"LogicalDisk(*)\Disk Writes/sec"
"LogicalDisk(*)\Current Disk Queue Length"
"LogicalDisk(*)\Avg. Disk sec/Read"
"LogicalDisk(*)\Avg. Disk sec/Write"

# System Performance
"Processor(_Total)\% Processor Time"
"Memory\Available MBytes"
"Memory\% Committed Bytes In Use"
"Network Interface(*)\Bytes Total/sec"

# Session Host Performance
"Terminal Services\Active Sessions"
"Terminal Services\Inactive Sessions"
```

## 📈 Using the Workbook

### 1. Initial Setup
After importing, configure these parameters:

- **Time Range**: Start with "Last 24 hours" for initial testing
- **Workspace**: Select your Log Analytics workspace
- **Host Pools**: Select specific AVD host pools (optional)

### 2. Data Validation
Check the **Executive Summary** section first:
- Verify session host count appears correctly
- Confirm storage metrics are populated
- Look for ANF performance tier recommendations

### 3. Interpreting Results

#### 🎯 Storage Performance Summary
- **Green metrics**: Optimal performance
- **Yellow metrics**: Monitor closely
- **Red metrics**: Action required

#### 👥 User Session Analytics
- **Peak Usage**: Identify high-demand periods
- **Session Patterns**: Plan capacity for concurrent users
- **Profile Activity**: Monitor FSLogix performance

#### 💾 Storage Deep Dive
- **IOPS Trends**: Understand I/O patterns
- **Latency Analysis**: Identify performance bottlenecks
- **Queue Depth**: Detect storage saturation

#### 🏆 ANF Recommendations
- **Performance Tier**: Based on throughput requirements
- **Capacity Planning**: Includes 30% growth buffer
- **Cost Estimates**: Monthly pricing estimates

## 🚨 Troubleshooting

### No Data Appearing
```kql
// Test query to verify data collection
Perf
| where TimeGenerated >= ago(1h)
| where CounterName contains "Disk"
| summarize count() by Computer, CounterName
| order by count_ desc
```

### Missing Performance Counters
```kql
// Check what counters are actually being collected
Perf
| where TimeGenerated >= ago(1h)
| summarize count() by ObjectName, CounterName
| order by ObjectName, CounterName
```

### Session Host Data Missing
```kql
// Verify session hosts are reporting
Heartbeat
| where TimeGenerated >= ago(1h)
| where Category == "Direct Agent"
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| order by LastHeartbeat desc
```

## 🔄 Data Refresh Settings

### Recommended Refresh Intervals
- **Real-time monitoring**: 5-15 minutes
- **Daily reviews**: 1 hour
- **Weekly planning**: 4 hours
- **Monthly analysis**: 24 hours

### Auto-refresh Configuration
```json
{
  "timeContext": {
    "durationMs": 3600000,
    "refreshInterval": 300000
  }
}
```

## 📊 Customization Options

### Add Custom Metrics
Edit any KQL query to include additional counters:

```kql
// Example: Add custom application counters
Perf
| where TimeGenerated >= ago({TimeRange:grain})
| where CounterName contains "YourApp"
| summarize avg(CounterValue) by Computer, CounterName
```

### Modify ANF Sizing Logic
Update the ANF recommendation thresholds:

```kql
// Customize ANF tier recommendations
| extend ANFPerformanceTier = case(
    PeakThroughputMBps > 500, "Ultra",     // Custom threshold
    PeakThroughputMBps > 200, "Premium",   // Custom threshold
    "Standard"
)
```

### Add Cost Analysis
Include actual Azure pricing:

```kql
// Add regional pricing calculations
| extend EstMonthlyCost = case(
    ANFPerformanceTier == "Ultra", RecommendedCapacityTiB * 520,
    ANFPerformanceTier == "Premium", RecommendedCapacityTiB * 260,
    RecommendedCapacityTiB * 135
)
```

## 🎯 Best Practices

### 1. Data Collection Period
- **Minimum**: 1 week for basic patterns
- **Recommended**: 2-4 weeks for accurate sizing
- **Optimal**: 1-3 months for comprehensive analysis

### 2. Monitoring Schedule
- **Daily**: Check for performance alerts
- **Weekly**: Review capacity trends
- **Monthly**: Analyze ANF sizing recommendations

### 3. Performance Baselines
- Establish baseline metrics after workbook deployment
- Monitor for 20%+ increases in latency or queue depth
- Track ANF recommendation changes over time

### 4. Cost Optimization
- Review ANF tier recommendations monthly
- Monitor for over-provisioning opportunities
- Consider burst vs. sustained performance requirements

## 🔗 Integration Options

### Power BI Integration
Export data for executive dashboards:

```kql
// Power BI export query
Perf
| where TimeGenerated >= ago(30d)
| where ObjectName in ("LogicalDisk", "Memory", "Processor")
| summarize avg(CounterValue) by bin(TimeGenerated, 1h), CounterName, Computer
```

### Azure Monitor Alerts
Create alerts based on workbook metrics:

```json
{
  "alertRule": {
    "name": "AVD High Storage Latency",
    "condition": "Perf | where CounterName == 'Avg. Disk sec/Read' | where CounterValue > 0.02",
    "severity": 2,
    "frequency": "PT5M"
  }
}
```

---

## 📞 Support

For issues with the workbook:
1. Check the [Troubleshooting section](#-troubleshooting) above
2. Verify data collection is working with test queries
3. Review the [main repository issues](https://github.com/tvanroo/AVDStorageAudit/issues)
4. Open a new issue with workbook logs and configuration details
