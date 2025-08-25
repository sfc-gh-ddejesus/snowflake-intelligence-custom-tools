-- CSV Upload Procedure v2 - Direct Stage Approach  
-- Bypasses tables entirely, writes directly to stage using PUT

-- Prerequisites: Create these once (run these commands first)
/*
CREATE STAGE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
-- No table needed at all!
*/

CREATE OR REPLACE PROCEDURE csv_to_presigned_url_direct(csv_content STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'csv_to_url_direct_handler'
AS
$$
import datetime
import tempfile
import os

def csv_to_url_direct_handler(session, csv_content):
    """
    Direct stage approach - no table needed
    Creates local temp file and uploads directly to stage
    Complete isolation, highest performance
    """
    temp_file_path = None
    try:
        # Validate input
        if not csv_content or not csv_content.strip():
            return "ERROR: CSV content cannot be empty"
        
        # Generate unique filename
        uuid_result = session.sql("SELECT UUID_STRING() as id").collect()
        request_id = uuid_result[0]['ID'].replace('-', '_')
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = f"csv_export_{timestamp}_{request_id[:8]}.csv"
        
        # Step 1: Create temporary local file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, encoding='utf-8') as temp_file:
            temp_file.write(csv_content)
            temp_file_path = temp_file.name
        
        # Step 2: Upload file directly to stage using PUT
        put_result = session.sql(f"""
            PUT file://{temp_file_path} @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES/{file_name}
            AUTO_COMPRESS = FALSE
            OVERWRITE = TRUE
        """).collect()
        
        # Check if PUT was successful
        if not put_result or put_result[0]['status'] != 'UPLOADED':
            return f"ERROR: Failed to upload file to stage. Status: {put_result[0]['status'] if put_result else 'Unknown'}"
        
        # Step 3: Generate presigned URL
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
        return f"ERROR: {str(e)}"
    
    finally:
        # Always cleanup local temporary file
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
            except:
                pass  # Cleanup failed, but not critical
$$;

-- Testing the Direct Stage Approach
/*
CALL csv_to_presigned_url_direct('product_id,product_name,price,category
1,"Gaming Laptop",1299.99,Electronics
2,"Office Chair",249.50,Furniture  
3,"Coffee Maker",89.99,Kitchen
4,"Bluetooth Headphones",79.99,Electronics');
*/
