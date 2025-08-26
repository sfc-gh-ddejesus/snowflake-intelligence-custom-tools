-- Snowflake Intelligence CSV to Presigned URL Tool
-- This stored procedure takes CSV content and returns a presigned URL for download
-- Features: Session-based isolation for concurrent users
-- Prerequisites: 
--   - Stage: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES (with SSE encryption)
--   - Table: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (session_id, csv_data, created_at)

CREATE OR REPLACE PROCEDURE SNOWFLAKE_INTELLIGENCE.PUBLIC.CSV_TO_PRESIGNED_URL("CSV_CONTENT" VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'csv_to_url_handler'
EXECUTE AS OWNER
AS '
import datetime

def csv_to_url_handler(session, csv_content):
    """
    Takes CSV string, creates properly formatted CSV file, returns presigned URL
    Uses session-based isolation for concurrent user support:
    - Each session gets a unique session ID
    - Data is isolated per session in TEMP_CSV table
    - Data is cleaned up after successful file creation
    
    Uses pre-existing stage: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES 
    and table: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV
    """
    try:
        # Validate input
        if not csv_content or not csv_content.strip():
            return "ERROR: CSV content cannot be empty"
        
        # Get current session ID for isolation
        session_result = session.sql("SELECT CURRENT_SESSION() as session_id").collect()
        current_session_id = session_result[0][''SESSION_ID'']
        
        # Generate unique filename with session info
        uuid_result = session.sql("SELECT UUID_STRING() as id").collect()
        unique_id = uuid_result[0][''ID''].replace(''-'', ''_'')[:8]
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = f"csv_export_{timestamp}_{unique_id}.csv"
        
        # Clean CSV content for SQL - handle quotes properly
        cleaned_csv = csv_content.replace("''", "''''")
        
        # Step 1: Insert CSV data with session isolation
        # Clean up any existing data for this session first
        session.sql(f"""
            DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
            WHERE session_id = ''{current_session_id}''
        """).collect()
        
        # Insert new CSV data for this session
        session.sql(f"""
            INSERT INTO SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (session_id, csv_data, created_at) 
            VALUES (''{current_session_id}'', ''{cleaned_csv}'', CURRENT_TIMESTAMP())
        """).collect()
        
        # Step 2: Copy CSV to stage using session-isolated data
        session.sql(f"""
            COPY INTO @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}
            FROM (
                SELECT csv_data 
                FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
                WHERE session_id = ''{current_session_id}''
            )
            FILE_FORMAT = (
                TYPE = ''CSV''
                COMPRESSION = ''NONE''
                FIELD_DELIMITER = ''NONE''
                RECORD_DELIMITER = ''NONE''
                FIELD_OPTIONALLY_ENCLOSED_BY = ''NONE''
                ESCAPE_UNENCLOSED_FIELD = ''NONE''
                NULL_IF = ()
                EMPTY_FIELD_AS_NULL = FALSE
                ENCODING = ''UTF8''
                BINARY_FORMAT = ''HEX''
            )
            SINGLE = TRUE
            OVERWRITE = TRUE
            HEADER = FALSE
        """).collect()
        
        # Step 3: Clean up session data after successful copy
        session.sql(f"""
            DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
            WHERE session_id = ''{current_session_id}''
        """).collect()
        
        # Step 4: Generate presigned URL
        url_result = session.sql(f"""
            SELECT GET_PRESIGNED_URL(@SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES, ''{file_name}'', 3600) as presigned_url
        """).collect()
        
        if url_result and len(url_result) > 0:
            # Extract URL from result
            result_dict = url_result[0].asDict()
            for value in result_dict.values():
                if isinstance(value, str) and value.startswith(''http''):
                    return value
        
        # If we get here, URL generation failed
        return f"ERROR: Could not generate presigned URL. File available at: @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}"
        
    except Exception as e:
        # Clean up session data on error
        try:
            session_result = session.sql("SELECT CURRENT_SESSION() as session_id").collect()
            current_session_id = session_result[0][''SESSION_ID'']
            session.sql(f"""
                DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV 
                WHERE session_id = ''{current_session_id}''
            """).collect()
        except:
            pass  # Ignore cleanup errors
            
        return f"ERROR: {str(e)}"
';
