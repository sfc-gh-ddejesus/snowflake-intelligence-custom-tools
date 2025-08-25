# Snowflake Intelligence Custom Tools

This directory contains custom tools and procedures for Snowflake Intelligence platform.

## CSV Upload to Presigned URL Tool

### Overview
A Snowflake stored procedure that converts CSV string content into downloadable files with presigned URLs. Perfect for Cortex AI agents that need to provide users with downloadable CSV data.

### Files
- `csv_upload_procedure.sql` - The main stored procedure implementation
- `test_examples.sql` - Comprehensive test cases and examples
- `README.md` - This documentation file

### Prerequisites

**⚠️ CRITICAL:** These objects MUST be created before the tool will work:

```sql
-- Create the temporary table for CSV processing
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (csv_data STRING);

-- Create the stage for file storage
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- Deploy the stored procedure (see csv_upload_procedure.sql)
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
1. Takes CSV string input
2. Generates unique filename with timestamp
3. Stores CSV content in temporary table
4. Copies content to stage as properly formatted CSV file
5. Generates presigned URL for download
6. Returns URL to user

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

- **Session-scoped:** Uses temporary table that's cleared on each use
- **Unique filenames:** Prevents file conflicts and overwrites
- **Presigned URLs:** Secure, time-limited access
- **Input validation:** Prevents empty or malformed content

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
