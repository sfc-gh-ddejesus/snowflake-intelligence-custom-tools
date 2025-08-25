# Snowflake Intelligence Setup Guide for CSV Download Tool

This guide walks you through configuring the CSV download custom tool in Snowflake Intelligence UI.

## Prerequisites

**⚠️ CRITICAL: Complete ALL prerequisites before configuring the tool in Snowflake Intelligence**

### 1. Database Infrastructure (Must be created first)

The following objects MUST exist in your Snowflake account before the tool will work:

```sql
-- Create the temporary table for CSV processing
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (csv_data STRING);

-- Create the stage for file storage  
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- Deploy the stored procedure
-- (Use the code from csv_upload_procedure.sql)
```

### 2. Role and Access Requirements

**The user/role running Snowflake Intelligence MUST have the following permissions:**

```sql
-- Grant access to the schema
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC TO ROLE <your_intelligence_role>;

-- Grant access to the table
GRANT SELECT, INSERT, DELETE ON TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV TO ROLE <your_intelligence_role>;

-- Grant access to the stage
GRANT READ, WRITE ON STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES TO ROLE <your_intelligence_role>;

-- Grant execute permission on the procedure
GRANT EXECUTE ON PROCEDURE SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL(VARCHAR) TO ROLE <your_intelligence_role>;
```

### 3. Verification Commands

**Before proceeding with the UI setup, verify everything exists:**

```sql
-- Check table exists
SELECT * FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV LIMIT 1;

-- Check stage exists  
LIST @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- Check procedure exists
SHOW PROCEDURES LIKE 'CSV_TO_PRESIGNED_URL' IN SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC;

-- Test the procedure works
CALL SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL('test,data\n1,hello\n2,world');
```

### 4. Infrastructure Confirmation

Your Snowflake object browser should show (as seen in the screenshot):

```
SNOWFLAKE_INTELLIGENCE
└── PUBLIC
    ├── Tables
    │   └── TEMP_CSV
    ├── Stages  
    │   └── TEMP_FILES
    └── Procedures
        └── CSV_TO_PRESIGNED_URL(VARCHAR)
```

**✅ If you can see all these objects and run the test procedure successfully, you're ready to proceed with the UI configuration.**

## Step-by-Step Setup Guide

### Step 1: Access Snowflake Intelligence

1. Navigate to your Snowflake Intelligence interface
2. Go to the agent configuration section

### Step 2: Configure Response Instructions

In the **Instructions** section:

1. Click on **Instructions** in the left navigation
2. In the **Response instruction** field, add:
   ```
   If the user asks for a csv format use the csv_download tool provide the download link.
   ```

![Instructions Configuration](screenshots/instructions_config.png)

**Purpose:** This tells the agent when and how to use the CSV download tool.

### Step 3: Add Sample Questions (Optional)

In the **Sample questions** section:
1. Add relevant questions that users might ask that would trigger CSV downloads
2. Examples:
   - "Can I download this data as CSV?"
   - "Export the results to CSV format"
   - "Give me a CSV file of this data"

### Step 4: Configure Custom Tools

1. Navigate to the **Tools** section in the left navigation
2. Scroll down to **Custom tools** section
3. Click **+ Add** to add a new custom tool

![Tools Section](screenshots/tools_section.png)

### Step 5: Configure the CSV Download Tool

In the **Edit custom tool** dialog, configure the following:

#### Basic Information:
- **Name:** `csv_download`
- **Resource type:** `procedure` (dropdown selection)

#### Database & Schema:
- **Database & Schema:** `SNOWFLAKE_INTELLIGENCE.PUBLIC`

#### Custom Tool Identifier:
- **Custom tool identifier:** `SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL`

![Custom Tool Configuration](screenshots/custom_tool_config.png)

### Step 6: Configure Parameters

In the **Parameters** section:

1. Click **+ Add parameter**
2. Configure the parameter:
   - **Parameter:** `csv_content`
   - **Type:** `string` (dropdown selection)
   - **Required:** ✅ Checked
   - **Description:** 
     ```
     When the user receives a CSV output and ask to download, pass the entire raw text to this custom tool (procedure) and provide back the URL to download
     ```

![Parameter Configuration](screenshots/parameter_config.png)

### Step 7: Save Configuration

1. Click **Update** to save the custom tool configuration
2. The tool should now appear in your Custom tools list as `CSV_DOWNLOAD`

## Verification

### Test the Configuration

1. In Snowflake Intelligence, ask a question that would generate tabular data
2. Then ask: "Can I download this as CSV?"
3. The agent should:
   - Use the `csv_download` tool
   - Pass the CSV data to the `csv_content` parameter
   - Return a presigned download URL

### Expected Behavior

When working correctly, the agent will:
1. ✅ Recognize requests for CSV downloads
2. ✅ Call the `csv_download` custom tool
3. ✅ Pass the data to the `csv_to_presigned_url` procedure
4. ✅ Return a working download link to the user

## Configuration Summary

| Setting | Value |
|---------|-------|
| **Tool Name** | `csv_download` |
| **Resource Type** | `procedure` |
| **Database.Schema** | `SNOWFLAKE_INTELLIGENCE.PUBLIC` |
| **Procedure** | `CSV_TO_PRESIGNED_URL` |
| **Parameter Name** | `csv_content` |
| **Parameter Type** | `string` |
| **Required** | Yes |

## Troubleshooting

### Common Issues:

1. **🚨 "Object does not exist" errors:**
   - **Cause:** Required infrastructure not created
   - **Solution:** Run the prerequisite SQL commands to create TEMP_CSV table and TEMP_FILES stage

2. **🚨 "Access denied" or permission errors:**
   - **Cause:** Snowflake Intelligence role lacks proper permissions
   - **Solution:** Grant all required permissions (see Prerequisites section)
   - **Check:** Verify your role has access to the SNOWFLAKE_INTELLIGENCE.PUBLIC schema

3. **🚨 "Procedure not found" errors:**
   - **Cause:** Stored procedure not deployed or wrong schema
   - **Solution:** Deploy the procedure using csv_upload_procedure.sql in the correct schema

4. **🚨 Tool not appearing in Snowflake Intelligence:**
   - **Cause:** Custom tool configuration incorrect
   - **Solution:** Verify the tool identifier matches: `SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL`

5. **🚨 Agent not using the tool:**
   - **Cause:** Response instructions not configured
   - **Solution:** Add the instruction: "If the user asks for a csv format use the csv_download tool provide the download link."

6. **🚨 "ERROR: CSV content cannot be empty":**
   - **Cause:** Empty or null data passed to the procedure
   - **Solution:** Ensure the agent passes actual CSV content to the tool

### Pre-Deployment Verification:

**Run these commands to verify your setup before configuring the UI:**

```sql
-- 1. Check you have access to the schema
USE SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC;

-- 2. Verify table exists and you can access it
SELECT COUNT(*) FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;

-- 3. Verify stage exists and you can access it
LIST @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- 4. Verify procedure exists
SHOW PROCEDURES LIKE 'CSV_TO_PRESIGNED_URL' IN SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC;

-- 5. Test end-to-end functionality
CALL SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL('name,age\nJohn,25\nJane,30');
```

### Role Permission Verification:

```sql
-- Check what roles you have
SHOW GRANTS TO USER <your_username>;

-- Check what permissions your current role has on the objects
SHOW GRANTS ON TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;
SHOW GRANTS ON STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
SHOW GRANTS ON PROCEDURE SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL(VARCHAR);
```

**⚠️ IMPORTANT:** If any of the verification commands fail, you MUST fix the underlying infrastructure and permissions before proceeding with the Snowflake Intelligence configuration.

## Integration Complete! 🎉

Your CSV download tool is now integrated with Snowflake Intelligence. Users can now:
- Ask for data in any format
- Request CSV downloads
- Receive working download links
- Download properly formatted CSV files

The agent will automatically handle the conversion from query results to downloadable CSV files using your custom tool.
