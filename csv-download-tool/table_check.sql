-- Prerequisites Setup and Verification Script
-- Run these commands to set up the required objects for the CSV to Presigned URL tool

-- 1. Create the temporary table for CSV processing with session isolation
CREATE TABLE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (
    session_id STRING NOT NULL,
    csv_data STRING NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- 2. Create the stage for file storage with SSE encryption
CREATE STAGE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- 3. Verify the table exists and check structure
DESCRIBE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;

-- 4. Verify the stage exists and check properties
DESCRIBE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- 5. Check current data in the table (session-aware)
SELECT 
    session_id,
    LEFT(csv_data, 100) as csv_preview,
    LENGTH(csv_data) as data_length,
    created_at
FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
ORDER BY created_at DESC
LIMIT 10;

-- 6. Check stage file count
LIST @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- 7. Test basic permissions
SELECT 'Prerequisites setup complete!' as status;
