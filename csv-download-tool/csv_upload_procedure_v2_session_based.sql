-- CSV Upload Procedure v2 - Session-Based Concurrency Safe
-- Handles multiple concurrent users with session isolation

-- Prerequisites: Create these once (run these commands first)
/*
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (
    session_id STRING,
    request_id STRING,
    csv_data STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Create index for performance
CREATE INDEX idx_temp_csv_session ON SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (session_id, request_id);

-- Optional: Create cleanup task (removes data older than 1 hour)
CREATE OR REPLACE TASK cleanup_temp_csv
  WAREHOUSE = COMPUTE_WH  -- Replace with your warehouse
  SCHEDULE = 'USING CRON 0 * * * * UTC'  -- Every hour
AS
  DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
  WHERE created_at < CURRENT_TIMESTAMP() - INTERVAL '1 HOUR';

-- Enable the task (optional)
-- ALTER TASK cleanup_temp_csv RESUME;
*/

CREATE OR REPLACE PROCEDURE csv_to_presigned_url_v2(csv_content STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'csv_to_url_handler_v2'
AS
$$
import datetime

def csv_to_url_handler_v2(session, csv_content):
    """
    Session-safe CSV upload procedure
    Uses session isolation to prevent concurrent user collisions
    """
    try:
        # Validate input
        if not csv_content or not csv_content.strip():
            return "ERROR: CSV content cannot be empty"
        
        # Generate session ID and unique request ID
        session_result = session.sql("SELECT CURRENT_SESSION() as session_id").collect()
        session_id = session_result[0]['SESSION_ID']
        
        uuid_result = session.sql("SELECT UUID_STRING() as id").collect()
        request_id = uuid_result[0]['ID']
        
        # Generate unique filename
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        short_request_id = request_id.replace('-', '_')[:8]
        file_name = f"csv_export_{timestamp}_{short_request_id}.csv"
        
        # Clean CSV content for SQL - handle quotes properly
        cleaned_csv = csv_content.replace("'", "''")
        
        # Step 1: Insert CSV data with session and request isolation
        session.sql(f"""
            INSERT INTO SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
            (session_id, request_id, csv_data) 
            VALUES ('{session_id}', '{request_id}', '{cleaned_csv}')
        """).collect()
        
        # Step 2: Copy CSV to stage using session-specific query
        session.sql(f"""
            COPY INTO @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}
            FROM (
                SELECT csv_data 
                FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
                WHERE session_id = '{session_id}' 
                AND request_id = '{request_id}'
            )
            FILE_FORMAT = (
                TYPE = 'CSV'
                COMPRESSION = 'NONE'
                FIELD_DELIMITER = 'NONE'
                RECORD_DELIMITER = 'NONE'
                FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE'
                ESCAPE_UNENCLOSED_FIELD = 'NONE'
                NULL_IF = ()
                EMPTY_FIELD_AS_NULL = FALSE
                ENCODING = 'UTF8'
                BINARY_FORMAT = 'HEX'
            )
            SINGLE = TRUE
            OVERWRITE = TRUE
            HEADER = FALSE
        """).collect()
        
        # Step 3: Cleanup this session's data immediately after use
        session.sql(f"""
            DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
            WHERE session_id = '{session_id}' 
            AND request_id = '{request_id}'
        """).collect()
        
        # Step 4: Generate presigned URL
        url_result = session.sql(f"""
            SELECT GET_PRESIGNED_URL(@SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES, '{file_name}', 3600) as presigned_url
        """).collect()
        
        if url_result and len(url_result) > 0:
            result_dict = url_result[0].asDict()
            for value in result_dict.values():
                if isinstance(value, str) and value.startswith('http'):
                    return value
        
        return f"ERROR: Could not generate presigned URL. File available at: @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}"
        
    except Exception as e:
        # Cleanup on error if possible
        try:
            if 'session_id' in locals() and 'request_id' in locals():
                session.sql(f"""
                    DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
                    WHERE session_id = '{session_id}' 
                    AND request_id = '{request_id}'
                """).collect()
        except:
            pass  # Cleanup failed, but main error is more important
        
        return f"ERROR: {str(e)}"
$$;

-- Testing the Session-Safe Stored Procedure
/*
CALL csv_to_presigned_url_v2('product_id,product_name,price,category
1,"Gaming Laptop",1299.99,Electronics
2,"Office Chair",249.50,Furniture  
3,"Coffee Maker",89.99,Kitchen
4,"Bluetooth Headphones",79.99,Electronics');
*/
