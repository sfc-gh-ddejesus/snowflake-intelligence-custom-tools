-- Test Examples for CSV Upload Procedure
-- Run these tests to verify the procedure is working correctly

-- =============================================================================
-- SETUP (Run once)
-- =============================================================================

-- Create required infrastructure
CREATE STAGE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;
CREATE TABLE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (csv_data STRING);

-- =============================================================================
-- TEST CASES
-- =============================================================================

-- Test 1: Simple CSV data
SELECT 'Test 1: Simple CSV data' as test_name;
CALL csv_to_presigned_url('name,age
John,25
Jane,30');

-- Test 2: CSV with quotes and special characters
SELECT 'Test 2: CSV with quotes and special characters' as test_name;
CALL csv_to_presigned_url('product,description,price
"Gaming Laptop","High-performance laptop with 16GB RAM",1299.99
"Office Chair","Ergonomic chair with lumbar support",249.50
"Coffee Maker","Programmable 12-cup coffee maker",89.99');

-- Test 3: Employee data with multiple fields
SELECT 'Test 3: Employee data' as test_name;
CALL csv_to_presigned_url('employee_id,first_name,last_name,department,salary,hire_date
101,John,Smith,Engineering,75000,2022-01-15
102,Sarah,Johnson,Marketing,68000,2022-03-22
103,Mike,Wilson,Sales,82000,2021-11-10
104,Lisa,Brown,HR,62000,2023-02-01');

-- Test 4: Sales data with decimals
SELECT 'Test 4: Sales data with decimals' as test_name;
CALL csv_to_presigned_url('order_id,customer,product,quantity,unit_price,total
1001,"ABC Corp","Widget A",100,12.50,1250.00
1002,"XYZ Inc","Widget B",50,25.75,1287.50
1003,"Tech Solutions","Widget C",75,18.99,1424.25');

-- Test 5: CSV with commas in data (properly quoted)
SELECT 'Test 5: CSV with commas in quoted fields' as test_name;
CALL csv_to_presigned_url('company,address,city,revenue
"Acme Corp","123 Main St, Suite 100","New York",1000000
"Tech Inc","456 Oak Ave, Floor 2","San Francisco",2500000
"Global Ltd","789 Pine Rd, Building C","Chicago",1750000');

-- Test 6: Large dataset simulation
SELECT 'Test 6: Larger dataset' as test_name;
CALL csv_to_presigned_url('id,name,category,price,in_stock
1,"Wireless Mouse","Electronics",29.99,true
2,"Mechanical Keyboard","Electronics",129.99,true
3,"USB-C Cable","Electronics",19.99,false
4,"Monitor Stand","Accessories",49.99,true
5,"Desk Lamp","Office",39.99,true
6,"Notebook","Stationery",12.99,true
7,"Pen Set","Stationery",24.99,false
8,"Wireless Charger","Electronics",34.99,true
9,"Phone Case","Accessories",15.99,true
10,"Bluetooth Speaker","Electronics",79.99,true');

-- Test 7: Error handling - empty content
SELECT 'Test 7: Error handling - empty content' as test_name;
CALL csv_to_presigned_url('');

-- Test 8: Error handling - only whitespace
SELECT 'Test 8: Error handling - whitespace only' as test_name;
CALL csv_to_presigned_url('   ');

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Check stage contents (see what files have been created)
SELECT 'Stage Contents:' as info;
LIST @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES;

-- Check temp table (should be empty after each run)
SELECT 'Temp Table Contents:' as info;
SELECT * FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;

-- =============================================================================
-- CLEANUP (Optional)
-- =============================================================================

-- Remove test files from stage (uncomment to clean up)
-- REMOVE @SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_FILES PATTERN='csv_export_.*';

-- =============================================================================
-- EXPECTED RESULTS
-- =============================================================================

/*
Each test should return a presigned URL that looks like:
https://sfc-ds2-customer-stage.s3.amazonaws.com/...

The URL should be valid for 1 hour and allow direct download of the CSV file.

Error tests (7 and 8) should return:
ERROR: CSV content cannot be empty
*/
