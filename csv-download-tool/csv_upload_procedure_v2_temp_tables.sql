-- CSV Upload Procedure v2 - Temporary Tables Approach
-- Each request creates its own temporary table for complete isolation

-- Prerequisites: Create these once (run these commands first)
/*
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
-- No shared table needed - each request creates its own temp table
*/

CREATE OR REPLACE PROCEDURE csv_to_presigned_url_temp_table(csv_content STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'csv_to_url_temp_handler'
AS
$$
import datetime

def csv_to_url_temp_handler(session, csv_content):
    """
    Temporary table approach - complete isolation per request
    Each request gets its own temporary table that auto-drops
    """
    temp_table_name = None
    try:
        # Validate input
        if not csv_content or not csv_content.strip():
            return "ERROR: CSV content cannot be empty"
        
        # Generate unique identifiers
        uuid_result = session.sql("SELECT UUID_STRING() as id").collect()
        request_id = uuid_result[0]['ID'].replace('-', '_')
        
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = f"csv_export_{timestamp}_{request_id[:8]}.csv"
        
        # Create unique temporary table name
        temp_table_name = f"TEMP_CSV_{request_id}"
        
        # Step 1: Create temporary table for this request only
        session.sql(f"""
            CREATE TEMPORARY TABLE {temp_table_name} (
                csv_data STRING
            )
        """).collect()
        
        # Clean CSV content for SQL
        cleaned_csv = csv_content.replace("'", "''")
        
        # Step 2: Insert data into this request's temporary table
        session.sql(f"""
            INSERT INTO {temp_table_name} VALUES ('{cleaned_csv}')
        """).collect()
        
        # Step 3: Copy from temporary table to stage
        session.sql(f"""
            COPY INTO @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}
            FROM (SELECT csv_data FROM {temp_table_name})
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
        
        # Step 4: Drop temporary table (optional - auto-drops at session end)
        session.sql(f"DROP TABLE IF EXISTS {temp_table_name}").collect()
        
        # Step 5: Generate presigned URL
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
        # Cleanup temporary table on error
        if temp_table_name:
            try:
                session.sql(f"DROP TABLE IF EXISTS {temp_table_name}").collect()
            except:
                pass  # Cleanup failed, but main error is more important
        
        return f"ERROR: {str(e)}"
$$;

-- Testing the Temporary Table Approach
/*
CALL csv_to_presigned_url_temp_table('product_id,product_name,price,category
1,"Gaming Laptop",1299.99,Electronics
2,"Office Chair",249.50,Furniture  
3,"Coffee Maker",89.99,Kitchen
4,"Bluetooth Headphones",79.99,Electronics');
*/
