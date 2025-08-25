-- Fixed CSV Upload Procedure - Properly handles CSV formatting
-- Uses existing stage and table with correct text output

-- Prerequisites: Create these once (run these commands first)
/*
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (csv_data STRING);
*/

CREATE OR REPLACE PROCEDURE csv_to_presigned_url(csv_content STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'csv_to_url_handler'
AS
$$
import datetime

def csv_to_url_handler(session, csv_content):
    """
    Takes CSV string, creates properly formatted CSV file, returns presigned URL
    Uses pre-existing stage: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES 
    and table: SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV
    """
    try:
        # Validate input
        if not csv_content or not csv_content.strip():
            return "ERROR: CSV content cannot be empty"
        
        # Generate unique filename
        uuid_result = session.sql("SELECT UUID_STRING() as id").collect()
        unique_id = uuid_result[0]['ID'].replace('-', '_')[:8]
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = f"csv_export_{timestamp}_{unique_id}.csv"
        
        # Clean CSV content for SQL - handle quotes properly
        cleaned_csv = csv_content.replace("'", "''")
        
        # Step 1: Clear and insert new CSV data into existing table
        session.sql("DELETE FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV").collect()
        session.sql(f"INSERT INTO SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV VALUES ('{cleaned_csv}')").collect()
        
        # Step 2: Copy CSV to existing stage as raw text file
        session.sql(f"""
            COPY INTO @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}
            FROM (SELECT csv_data FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV)
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
        
        # Step 3: Generate presigned URL
        url_result = session.sql(f"""
            SELECT GET_PRESIGNED_URL(@SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES, '{file_name}', 3600) as presigned_url
        """).collect()
        
        if url_result and len(url_result) > 0:
            # Extract URL from result
            result_dict = url_result[0].asDict()
            for value in result_dict.values():
                if isinstance(value, str) and value.startswith('http'):
                    return value
        
        # If we get here, URL generation failed
        return f"ERROR: Could not generate presigned URL. File available at: @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}"
        
    except Exception as e:
        return f"ERROR: {str(e)}"
$$;



-- Testing the Stored Procedure
CALL csv_to_presigned_url('product_id,product_name,price,category
1,"Gaming Laptop",1299.99,Electronics
2,"Office Chair",249.50,Furniture  
3,"Coffee Maker",89.99,Kitchen
4,"Bluetooth Headphones",79.99,Electronics');
