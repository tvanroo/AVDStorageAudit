# AVD Storage Analytics for ANF Planning

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftvanroo%2FAVDStorageAudit%2Fmain%2FAVD%2520Workbook%2Fdeploy-avd-data-collection.json)

This solution provides comprehensive data collection and analytics for Azure Virtual Desktop (AVD) environments to help architects design optimal Azure NetApp Files (ANF) storage solutions.

## 📊 What This Solution Analyzes

### ✅ User & Session Data
- Total number of provisioned AVD users
- Peak concurrent users (daily/weekly/monthly)
- Average session duration per user
- Session count per host pool
- User logon/logoff timestamps (session overlap calculation)
- FSLogix vs local profile usage percentage
- Reconnection frequency (profile performance indicators)

### 🗂️ FSLogix Profile Containers
- Total count of profile containers (active/inactive)
- Total and average size of user profiles (VHD/VHDX)
- Largest profile containers identification
- Growth rate analysis over time
- Profiles with large Outlook OST/PST or OneDrive cache folders
- Abnormal growth pattern detection
- Last accessed timestamps (stale profile identification)
- FSLogix error/warning events from session hosts

### ⚡ Storage Performance Metrics
- Read/write throughput (MiB/s) - average and peak
- Read/write IOPS - average and peak  
- Read/write latency - average and peak
- High-latency spike duration analysis
- Storage queue depth monitoring
- Throttling occurrence percentage
- SMB operations per second

### 📁 File Share and Mount Data
- Mounted SMB/NFS shares inventory
- Share usage per host/session
- Top accessed shares identification
- Data volume per share analysis
- File open/close activity per session
- Storage type comparison (Azure Files vs ANF vs on-premises)

### 🖥️ Host Pool & VM Insights
- VM SKU analysis (memory/disk profiles)
- OS disk and temp disk usage patterns
- Session host CPU/RAM usage correlation with storage
- Session host to active session ratios

### 🔐 Authentication & Identity
- AD type identification (AD DS, Azure AD DS, Hybrid, Entra ID)
- Sign-in method and success/failure rates
- Group policy delays impacting logon duration

### 📈 User Experience Indicators
- Logon duration breakdown (profile load time focus)
- Session logon trend analysis
- Application launch latency
- User experience telemetry (when available)

### 💾 Storage Inventory & Configuration
- Current storage type and tier analysis
- Provisioned capacity and burst limits
- Geo-redundancy and ZRS configuration
- Backup/snapshot configuration review
- Storage account limitations and alerts

### 💰 Cost & Efficiency Analysis
- Monthly profile storage cost estimation
- Cost per user/session calculations
- Storage efficiency ratios (used vs provisioned)
- Deduplication and Cool tier savings potential

## 🚀 Quick Deployment

### Option 1: Deploy to Azure Button (Recommended)

Click the "Deploy to Azure" button above to deploy the data collection infrastructure through the Azure portal with a guided UI.

### Option 2: PowerShell Deployment

```powershell
# Clone the repository
git clone https://github.com/tvanroo/AVDStorageAudit.git
cd AVDStorageAudit/AVD\ Workbook

# Run the deployment script
.\Deploy-AVD-DataCollection.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupName "rg-avd-analytics" -Location "East US"
```

### Option 3: Azure CLI Deployment

```bash
# Create resource group
az group create --name rg-avd-analytics --location eastus

# Deploy the template
az deployment group create \
  --resource-group rg-avd-analytics \
  --template-file deploy-avd-data-collection.json \
  --parameters deploy-avd-data-collection.parameters.json
```

## 📋 Prerequisites

- **Azure Subscription** with Owner or Contributor permissions
- **AVD Environment** (Host Pools, Session Hosts, User Profiles)
- **PowerShell 5.1+** (for PowerShell deployment option)
- **Azure PowerShell Module** (`Install-Module Az`)

## 🔧 What Gets Deployed

| Resource | Purpose |
|----------|---------|
| **Log Analytics Workspace** | Central data collection and storage for all AVD metrics |
| **Data Collection Rule** | Configures performance counters and event log collection |
| **Data Collection Endpoint** | Secure endpoint for data ingestion |
| **Diagnostic Settings** | Auto-configures logging for AVD Host Pools, Storage Accounts, and ANF volumes |
| **PowerShell Script Execution** | Discovers and configures existing AVD resources |

## 📊 Data Collection Scope

### Automatic Discovery & Configuration
- ✅ **AVD Host Pools** - All host pools in the subscription
- ✅ **Storage Accounts** - Accounts tagged with 'AVD' or containing 'avd', 'profile', 'fslogix' in name
- ✅ **Azure NetApp Files** - All ANF accounts, pools, and volumes
- ✅ **Session Hosts** - Performance counters and event logs via Data Collection Rules

### Performance Counters Collected
- Disk I/O metrics (reads, writes, queue length, latency)
- Memory utilization and committed bytes
- CPU usage and processor queue length
- Network interface statistics
- Terminal Services session counts
- User Profile Service metrics

### Event Logs Collected
- Terminal Services (Local Session Manager & Remote Connection Manager)
- FSLogix Apps (Operational & Admin)
- User Profile Service events
- Application and System logs (profile-related)

## ⏱️ Data Collection Timeline

| Timeframe | Available Data |
|-----------|----------------|
| **15 minutes** | Initial performance counters and events |
| **1 hour** | Basic session and performance trends |
| **24 hours** | Daily usage patterns and peak load analysis |
| **1 week** | Weekly trends, profile growth patterns |
| **1 month** | Comprehensive analysis for ANF sizing recommendations |

## 📈 Using the Analytics

### 1. Access Your Data
After deployment, navigate to:
- **Azure Portal** > **Log Analytics Workspaces** > **[Your Workspace Name]**
- **Logs** section for custom KQL queries
- **Workbooks** section for the AVD Storage Analytics workbook

### 2. Key Reports Available
- **Executive Summary** - High-level metrics for stakeholders
- **Storage Performance Analysis** - Detailed I/O patterns and bottlenecks
- **Profile Container Analytics** - FSLogix profile insights and optimization
- **ANF Sizing Recommendations** - Data-driven ANF capacity and performance tier suggestions
- **Cost Analysis** - Current vs projected ANF costs

### 3. Sample KQL Queries

```kql
// Average profile size by user
Perf
| where ObjectName == "LogicalDisk" and CounterName == "Free Megabytes"
| where InstanceName contains "Profile"
| summarize AvgFreeMB = avg(CounterValue) by Computer
```

```kql
// FSLogix profile load times
Event
| where Source == "FSLogix-Apps"
| where EventID in (2, 4, 62)
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated desc
```

## 🎯 ANF Sizing Recommendations

The analytics provide data-driven recommendations for:

### Performance Tiers
- **Standard** - Light usage scenarios (< 16 MiB/s per TB)
- **Premium** - Production workloads (64 MiB/s per TB)  
- **Ultra** - High-performance requirements (128 MiB/s per TB)

### Capacity Planning
- Base capacity requirements from profile size analysis
- Growth projections based on historical data
- Peak load capacity for concurrent user scenarios
- Burst capacity recommendations for profile loading

### Network Considerations
- Bandwidth requirements between session hosts and ANF
- Latency requirements for optimal user experience
- Subnet planning for ANF delegation

## 🔒 Security & Compliance

- **Role-Based Access** - Uses managed identity for resource access
- **Data Retention** - Configurable retention (30-730 days)
- **Network Security** - Supports private endpoints for Log Analytics
- **Encryption** - Data encrypted in transit and at rest
- **Compliance** - Meets Azure compliance standards

## 🛠️ Customization

### Modify Data Retention
```json
{
  "dataRetentionDays": {
    "value": 180
  }
}
```

### Disable Specific Data Collection
```json
{
  "enableANFDiagnostics": {
    "value": false
  }
}
```

### Add Custom Performance Counters
Edit the `dataCollectionRules` section in the ARM template to include additional counters.

## 🧩 Integration

### Power BI Integration
Export data to Power BI for executive dashboards:
```kql
// Export query for Power BI
Perf
| where TimeGenerated >= ago(30d)
| where ObjectName in ("LogicalDisk", "Memory", "Processor")
| summarize avg(CounterValue) by bin(TimeGenerated, 1h), CounterName, Computer
```

### Azure Advisor Integration
The solution provides recommendations that complement Azure Advisor storage optimization suggestions.

### Cost Management Integration
Correlate storage performance with Azure Cost Management data for ROI analysis.

## 📞 Support & Troubleshooting

### Common Issues

**Q: No data appearing in Log Analytics**
- Wait 15-30 minutes after deployment
- Verify diagnostic settings are enabled on AVD resources
- Check that session hosts have the Azure Monitor Agent installed

**Q: Storage accounts not being monitored**
- Ensure storage accounts are tagged with 'AVD' or contain 'avd', 'profile', or 'fslogix' in the name
- Verify permissions on storage accounts

**Q: ANF volumes not showing data**
- Confirm Azure NetApp Files are present in the subscription
- Verify ANF diagnostic settings were created successfully

### Getting Help

1. **Check deployment logs** in the Azure portal under Resource Group > Deployments
2. **Review diagnostic settings** on individual AVD resources
3. **Validate Log Analytics workspace** permissions and configuration
4. **Open an issue** in this GitHub repository with deployment details

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`azure` `avd` `azure-virtual-desktop` `azure-netapp-files` `anf` `storage` `analytics` `fslogix` `monitoring` `log-analytics`
