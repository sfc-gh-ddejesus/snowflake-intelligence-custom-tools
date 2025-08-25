# Snowflake Intelligence Custom Tools

A collection of custom tools and integrations for Snowflake Intelligence platform to extend its capabilities with specialized functionality.

## 🏗️ Repository Structure

```
snowflake-intelligence-custom-tools/
├── README.md                    # This file - main repository overview
├── docs/                        # General documentation
│   ├── contributing.md          # Contribution guidelines
│   ├── deployment-guide.md      # General deployment patterns
│   └── troubleshooting.md       # Common issues and solutions
├── examples/                    # Example implementations and demos
├── csv-download-tool/          # CSV file download tool
│   ├── README.md               # Tool-specific documentation
│   ├── csv_upload_procedure.sql # Main stored procedure
│   ├── test_examples.sql       # Test cases and examples
│   ├── deployment_checklist.md # Step-by-step deployment checklist
│   └── snowflake_intelligence_setup_guide.md # UI configuration guide
└── [future-tools]/             # Additional tools will be added here
```

## 🛠️ Available Tools

### 1. CSV Download Tool
**Status:** ✅ Production Ready  
**Purpose:** Converts query results to downloadable CSV files with presigned URLs  
**Location:** [`csv-download-tool/`](./csv-download-tool/)

**Features:**
- ✅ Convert CSV string data to downloadable files
- ✅ Generate secure presigned URLs (1-hour expiration)
- ✅ Seamless Snowflake Intelligence integration
- ✅ Automatic file cleanup and unique naming
- ✅ Comprehensive error handling

**Quick Start:**
```sql
-- 1. Create infrastructure (one-time setup)
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (csv_data STRING);
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- 2. Deploy procedure (see csv-download-tool/ folder)
-- 3. Configure in Snowflake Intelligence UI
-- 4. Users can now request CSV downloads!
```

## 🚀 Getting Started

### Prerequisites
- Snowflake account with Intelligence enabled
- Appropriate role permissions (see individual tool docs)
- Basic knowledge of Snowflake SQL and procedures

### General Deployment Process

1. **Choose a tool** from the available options
2. **Read the tool-specific README** in its folder
3. **Follow the deployment checklist** provided with each tool
4. **Configure in Snowflake Intelligence** using the setup guide
5. **Test functionality** with provided examples

### Repository Navigation

- 📖 **New to custom tools?** Start with [`csv-download-tool/README.md`](./csv-download-tool/README.md)
- 🎯 **Want to add CSV downloads?** Go to [`csv-download-tool/`](./csv-download-tool/)
- 🔧 **Having issues?** Check [`csv-download-tool/deployment_checklist.md`](./csv-download-tool/deployment_checklist.md)
- 🤝 **Want to contribute?** See [`docs/README.md`](./docs/README.md)

## 🤝 Contributing

We welcome contributions! Please see our [Documentation](./docs/README.md) for details.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`snowflake` `intelligence` `custom-tools` `sql` `procedures` `ai` `csv` `download` `export` `automation`

---

⭐ **Star this repository** if you find these tools useful!  
🔔 **Watch** for updates on new tools and features!  
🍴 **Fork** to customize tools for your organization!
