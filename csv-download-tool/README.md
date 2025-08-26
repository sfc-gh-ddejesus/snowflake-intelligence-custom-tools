# Snowflake Intelligence Custom Tools

This directory contains custom tools and procedures for Snowflake Intelligence platform.

## CSV Upload to Presigned URL Tool

### Overview
A Snowflake stored procedure that converts CSV string content into downloadable files with presigned URLs. Perfect for Cortex AI agents that need to provide users with downloadable CSV data.

### Files
- `csv_to_presigned_url_procedure.sql` - The main stored procedure implementation
- `test_examples.sql` - Comprehensive test cases and examples
- `table_check.sql` - SQL commands to verify prerequisites
- `README.md` - This documentation file
- `deployment_checklist.md` - Step-by-step deployment guide
- `snowflake_intelligence_setup_guide.md` - Complete setup instructions

### Prerequisites

**⚠️ CRITICAL:** These objects MUST be created before the tool will work:

```sql
-- Create the temporary table for CSV processing with session isolation
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (
    session_id STRING NOT NULL,
    csv_data STRING NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Create the stage for file storage with SSE encryption
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Deploy the stored procedure (see csv_to_presigned_url_procedure.sql)
```

**Required Permissions:** The Snowflake Intelligence role MUST have:
- `USAGE` on schema `SNOWFLAKE_INTELLIGENCE.PUBLIC`
- `SELECT, INSERT, DELETE` on table `TEMP_CSV`
- `READ, WRITE` on stage `TEMP_FILES` 
- `EXECUTE` on procedure `CSV_TO_PRESIGNED_URL`

**📋 Use the `deployment_checklist.md` to verify your setup is complete.**

### Procedure Details

**Function:** `csv_to_presigned_url(csv_content STRING)`

**Input:** CSV content as a string
**Output:** Presigned download URL (valid for 1 hour)

**Workflow:**
1. Takes CSV string input and validates it
2. Gets current session ID for user isolation
3. Generates unique filename with timestamp and UUID
4. Stores CSV content in session-isolated temporary table
5. Copies content to stage as properly formatted CSV file
6. Cleans up session data from temporary table
7. Generates presigned URL for download
8. Returns URL to user

**Concurrency Features:**
- **Session Isolation:** Each user session gets isolated data storage
- **Automatic Cleanup:** Data is removed from temp table after file creation
- **Concurrent Safe:** Multiple users can use the tool simultaneously
- **Error Handling:** Session data is cleaned up even on errors

### Usage Examples

#### Basic Usage
```sql
CALL csv_to_presigned_url('name,age,city
John,25,New York
Jane,30,San Francisco');
```

#### Complex CSV with Quotes
```sql
CALL csv_to_presigned_url('product_id,product_name,price,category
1,"Gaming Laptop",1299.99,Electronics
2,"Office Chair",249.50,Furniture  
3,"Coffee Maker",89.99,Kitchen
4,"Bluetooth Headphones",79.99,Electronics');
```

#### Employee Data Example
```sql
CALL csv_to_presigned_url('employee_id,name,department,salary
101,"John Smith",Engineering,75000
102,"Sarah Johnson",Marketing,68000
103,"Mike Wilson",Sales,82000');
```

### Integration with Cortex AI

For Cortex AI agents, use this procedure to provide downloadable CSV files:

```python
# Example agent integration
def handle_csv_request(csv_data):
    result = execute_sql("CALL csv_to_presigned_url(?)", [csv_data])
    
    if result.startswith("http"):
        return f"✅ Your CSV is ready! Download: {result}"
    else:
        return f"❌ Error creating CSV: {result}"
```

### Technical Details

- **Runtime:** Python 3.11
- **Packages:** snowflake-snowpark-python
- **File Format:** UTF-8 encoded CSV
- **URL Expiration:** 1 hour (3600 seconds)
- **File Naming:** `csv_export_{timestamp}_{uuid}.csv`

### Error Handling

The procedure includes comprehensive error handling:
- Empty content validation
- SQL injection protection (quote escaping)
- Stage/table access error handling
- URL generation failure handling

### Security Features

- **Session Isolation:** Each user session has isolated data storage
- **Automatic Cleanup:** Temporary data is removed after processing
- **Unique Filenames:** Prevents file conflicts and overwrites
- **Presigned URLs:** Secure, time-limited access (1 hour expiration)
- **Input Validation:** Prevents empty or malformed content
- **SSE Encryption:** Files are encrypted at rest in the stage
- **Concurrent Safe:** Multiple users can't interfere with each other's data

### Troubleshooting

**Common Issues:**

1. **Permission Errors:** Ensure user has EXECUTE privileges on the procedure
2. **Stage Not Found:** Verify the TEMP_FILES stage exists
3. **Table Not Found:** Verify the TEMP_CSV table exists
4. **Gibberish Content:** The fixed procedure handles text encoding properly

**Verification:**
```sql
-- Check if stage exists
SHOW STAGES LIKE 'TEMP_FILES';

-- Check if table exists  
SHOW TABLES LIKE 'TEMP_CSV';

-- Test with simple data
CALL csv_to_presigned_url('test,data
1,hello
2,world');
```

### Maintenance

- **Cleanup:** Files in the stage should be cleaned up periodically
- **Monitoring:** Monitor stage usage and file accumulation
- **Updates:** Procedure can be updated without affecting existing files

### Version History

- **v1.0:** Initial implementation with working CSV download functionality
- **v1.1:** Fixed text encoding issues for proper CSV formatting
- **v1.2:** Added comprehensive error handling and documentation
- **v2.0:** Added session-based isolation for concurrent users
  - Enhanced table schema with session_id and created_at columns
  - Automatic cleanup of temporary data after file creation
  - Concurrent user support without data interference
  - Improved error handling with session cleanup
