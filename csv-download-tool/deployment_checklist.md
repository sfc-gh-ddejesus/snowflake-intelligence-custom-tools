# CSV Download Tool - Deployment Checklist

## Pre-Deployment Checklist ✅

Use this checklist to ensure all prerequisites are met before configuring the tool in Snowflake Intelligence.

### 📋 Infrastructure Setup

- [ ] **Database/Schema Access**
  - [ ] Can access `SNOWFLAKE_INTELLIGENCE` database
  - [ ] Can access `PUBLIC` schema
  - [ ] Current role has necessary permissions

- [ ] **Required Objects Created**
  - [ ] Table: `SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV` (with session_id, csv_data, created_at columns)
  - [ ] Stage: `SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES` (with SSE encryption)
  - [ ] Procedure: `SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL(VARCHAR)`

- [ ] **Permissions Granted**
  - [ ] `USAGE` on schema `SNOWFLAKE_INTELLIGENCE.PUBLIC`
  - [ ] `SELECT, INSERT, DELETE` on table `TEMP_CSV`
  - [ ] `READ, WRITE` on stage `TEMP_FILES`
  - [ ] `EXECUTE` on procedure `CSV_TO_PRESIGNED_URL`

### 🧪 Verification Tests

Run these commands and verify they all succeed:

```sql
-- ✅ Test 1: Schema access
USE SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC;

-- ✅ Test 2: Table access
SELECT COUNT(*) FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;

-- ✅ Test 3: Stage access  
LIST @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- ✅ Test 4: Procedure exists
SHOW PROCEDURES LIKE 'CSV_TO_PRESIGNED_URL' IN SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC;

-- ✅ Test 5: End-to-end functionality
CALL SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL('test,data\n1,hello\n2,world');
```

**Expected Results:**
- [ ] All commands execute without errors
- [ ] Test 5 returns a presigned URL (starts with `https://`)

### 🎯 Snowflake Intelligence Configuration

- [ ] **Instructions Configured**
  - [ ] Added response instruction: "If the user asks for a csv format use the csv_download tool provide the download link."

- [ ] **Custom Tool Added**
  - [ ] Tool name: `csv_download`
  - [ ] Resource type: `procedure`
  - [ ] Database & Schema: `SNOWFLAKE_INTELLIGENCE.PUBLIC`
  - [ ] Tool identifier: `SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL`

- [ ] **Parameter Configured**
  - [ ] Parameter name: `csv_content`
  - [ ] Type: `string`
  - [ ] Required: ✅ Yes
  - [ ] Description added

### 🔄 Final Testing

- [ ] **Agent Testing**
  - [ ] Ask agent for data: "Show me some sample data"
  - [ ] Request CSV: "Can I download this as CSV?"
  - [ ] Agent responds with download link
  - [ ] Download link works and contains proper CSV

### 📊 Visual Confirmation

Your Snowflake object browser should show:

```
SNOWFLAKE_INTELLIGENCE
└── PUBLIC
    ├── Tables
    │   └── TEMP_CSV ✅
    ├── Stages  
    │   └── TEMP_FILES ✅
    └── Procedures
        └── CSV_TO_PRESIGNED_URL(VARCHAR) ✅
```

## Common Setup Commands

### Infrastructure Creation:
```sql
-- Create all required objects
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (
    session_id STRING NOT NULL,
    csv_data STRING NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Deploy procedure (use csv_to_presigned_url_procedure.sql)
```

### Permission Grants:
```sql
-- Replace <role_name> with the Snowflake Intelligence role
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.PUBLIC TO ROLE <role_name>;
GRANT SELECT, INSERT, DELETE ON TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV TO ROLE <role_name>;
GRANT READ, WRITE ON STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES TO ROLE <role_name>;
GRANT EXECUTE ON PROCEDURE SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL(VARCHAR) TO ROLE <role_name>;
```

## Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| "Object does not exist" | Create missing table/stage/procedure |
| "Access denied" | Grant proper permissions to role |
| "Tool not found" | Check tool identifier in UI config |
| "Agent not using tool" | Add response instruction |
| "Empty CSV error" | Check data being passed to tool |

## Success Criteria ✅

**The deployment is successful when:**
- [ ] All infrastructure objects exist
- [ ] All verification tests pass
- [ ] Snowflake Intelligence shows the custom tool
- [ ] Agent can generate working CSV download links
- [ ] Downloaded files contain properly formatted CSV data

---

**📞 Need Help?** Refer to the detailed setup guide in `snowflake_intelligence_setup_guide.md`
