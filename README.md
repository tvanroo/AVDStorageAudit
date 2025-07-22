# AVD Storage Audit

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftvanroo%2FAVDStorageAudit%2Fmain%2FAVD%2520Workbook%2Fdeploy-avd-data-collection.json)

This repository contains tools for comprehensive Azure Virtual Desktop (AVD) storage analysis and Azure NetApp Files (ANF) planning. The solution helps architects design optimal storage solutions by collecting and analyzing real-world usage patterns, performance metrics, and user behavior.

## 🚀 Quick Start

### One-Click Deployment
Click the "Deploy to Azure" button above to deploy the data collection infrastructure with a guided UI.

### Manual Deployment
```powershell
# Clone this repository
git clone https://github.com/tvanroo/AVDStorageAudit.git
cd AVDStorageAudit/AVD\ Workbook

# Deploy the analytics infrastructure
.\Deploy-AVD-DataCollection.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupName "rg-avd-analytics"

# Optional: Validate your environment first (recommended)
.\Validate-Deployment.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupName "rg-avd-analytics" -WhatIf

# Grant additional permissions for comprehensive monitoring (if needed)
.\Grant-ManagedIdentityPermissions.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupName "rg-avd-analytics"
```

## 📁 Repository Structure

```
AVDStorageAudit/
├── AVD Workbook/                          # Main analytics solution
│   ├── deploy-avd-data-collection.json    # ARM template for infrastructure
│   ├── deploy-avd-data-collection.parameters.json  # Template parameters
│   ├── Deploy-AVD-DataCollection.ps1      # PowerShell deployment script
│   ├── Validate-AVD-DataCollection.ps1    # Validation script
│   ├── README.md                          # Detailed documentation
│   ├── metadata.json                      # Azure QuickStart metadata
│   └── .github/workflows/                 # CI/CD workflows
└── README.md                              # This file
```

## 🎯 What This Solution Does

- **📊 Comprehensive Data Collection**: Automatically discovers and monitors AVD Host Pools, Session Hosts, Storage Accounts, and Azure NetApp Files
- **⚡ Performance Analytics**: Tracks disk I/O, memory usage, network performance, and user session patterns
- **🗂️ Profile Analysis**: Analyzes FSLogix profile containers, sizes, growth patterns, and performance
- **💰 Cost Optimization**: Provides data-driven recommendations for Azure NetApp Files sizing and cost optimization
- **🔍 Storage Planning**: Helps architects choose the right ANF performance tier and capacity

## 📋 Prerequisites

- Azure Subscription with Contributor or Owner permissions
- Existing AVD environment (Host Pools, Session Hosts, User Profiles)  
- PowerShell 5.1+ and Azure PowerShell module (for PowerShell deployment)

## ⏱️ Data Collection Timeline

| Timeframe | Available Data |
|-----------|----------------|
| **15 minutes** | Initial performance counters and events |
| **1 hour** | Basic session and performance trends |
| **24 hours** | Daily usage patterns and peak load analysis |
| **1 week** | Weekly trends, profile growth patterns |
| **1 month** | Comprehensive analysis for ANF sizing recommendations |

## 🔧 What Gets Deployed

- **Log Analytics Workspace** - Central data collection and storage
- **Data Collection Rules** - Performance counters and event log collection  
- **Data Collection Endpoints** - Secure data ingestion
- **Diagnostic Settings** - Auto-configured logging for AVD resources
- **PowerShell Automation** - Discovery and configuration of existing resources

## 📈 Key Analytics Provided

### Storage Performance Metrics
- Read/write throughput (MiB/s) - average and peak
- Read/write IOPS analysis  
- Latency measurements and spike analysis
- Storage queue depth monitoring

### User & Session Analysis
- Peak concurrent users tracking
- Session duration and overlap analysis
- Profile load performance
- User experience indicators

### ANF Sizing Recommendations
- Performance tier recommendations (Standard/Premium/Ultra)
- Capacity planning based on usage patterns
- Network bandwidth requirements
- Cost optimization suggestions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`azure` `avd` `azure-virtual-desktop` `azure-netapp-files` `anf` `storage` `analytics` `fslogix` `monitoring` `log-analytics`

## 📞 Support

For questions or issues:
1. Check the [detailed documentation](AVD%20Workbook/README.md)
2. Review the [Troubleshooting Guide](TROUBLESHOOTING.md) for common deployment issues
3. Use the validation script: `.\Validate-Deployment.ps1`
4. Open an issue in this repository
