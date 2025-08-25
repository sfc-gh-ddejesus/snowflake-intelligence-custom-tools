# Concurrency Solutions for CSV Upload Procedure

## Problem Statement

The original CSV upload procedure has critical concurrency issues:
- Uses shared table with `DELETE` + `INSERT` (not atomic)
- Multiple users can overwrite each other's data
- Race conditions cause data corruption and failed requests

## Solution Comparison

### 1. Session-Based Table Approach ⭐ **RECOMMENDED**

**File:** `csv_upload_procedure_v2_session_based.sql`

#### How It Works:
- Uses `CURRENT_SESSION()` + `UUID_STRING()` for unique identification
- Inserts data with session and request IDs 
- Queries using `WHERE session_id = X AND request_id = Y`
- Immediately cleans up after use

#### Pros:
✅ **Complete isolation** - No data collisions possible  
✅ **Simple setup** - Only requires table schema change  
✅ **Familiar pattern** - Uses standard table operations  
✅ **Built-in cleanup** - Automatic data removal  
✅ **Performance indexed** - Can optimize with indices  
✅ **Error recovery** - Can cleanup on failure  

#### Cons:
❌ **Table growth** - Data accumulates if cleanup fails  
❌ **Additional I/O** - Still uses table intermediary  

#### Schema Change Required:
```sql
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (
    session_id STRING,
    request_id STRING,  
    csv_data STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

---

### 2. Temporary Tables Approach

**File:** `csv_upload_procedure_v2_temp_tables.sql`

#### How It Works:
- Creates unique temporary table per request
- Table name includes UUID for uniqueness
- Temporary tables auto-drop at session end

#### Pros:
✅ **Perfect isolation** - Each request has own table  
✅ **Auto cleanup** - Temporary tables self-destruct  
✅ **No shared resources** - Zero contention  
✅ **Familiar SQL** - Standard table operations  

#### Cons:
❌ **DDL overhead** - CREATE/DROP table per request  
❌ **Metadata impact** - Temporary table creation costs  
❌ **Session limits** - May hit temporary object limits  
❌ **No schema change** - But creates many temp tables  

---

### 3. Direct Stage Approach  

**File:** `csv_upload_procedure_v2_direct_stage.sql`

#### How It Works:
- Creates local temporary file in procedure
- Uses `PUT` command to upload directly to stage
- No table intermediary at all

#### Pros:
✅ **Highest performance** - No table overhead  
✅ **Perfect isolation** - Local files completely separate  
✅ **Minimal resources** - No persistent storage used  
✅ **Clean design** - Direct file → stage flow  

#### Cons:
❌ **Local file system** - Requires temp file creation  
❌ **PUT limitations** - May have size/permission limits  
❌ **Cleanup complexity** - Must handle local file cleanup  
❌ **Platform dependency** - Local filesystem access needed  

---

## Detailed Comparison Matrix

| Aspect | Session-Based | Temp Tables | Direct Stage |
|--------|---------------|-------------|--------------|
| **Concurrency Safety** | ✅ Perfect | ✅ Perfect | ✅ Perfect |
| **Setup Complexity** | 🟡 Medium | 🟢 Easy | 🟢 Easy |
| **Performance** | 🟡 Good | 🟡 Good | 🟢 Excellent |
| **Resource Usage** | 🟡 Medium | 🔴 High | 🟢 Low |
| **Scalability** | 🟢 Excellent | 🟡 Good | 🟢 Excellent |
| **Error Recovery** | 🟢 Good | 🟢 Good | 🟡 Medium |
| **Monitoring** | 🟢 Good | 🟡 Medium | 🔴 Limited |
| **Maintenance** | 🟡 Medium | 🟢 Low | 🟡 Medium |

## Additional Considerations

### Security
- **Session-Based:** Session IDs provide natural user isolation
- **Temp Tables:** Temporary tables have session-level security  
- **Direct Stage:** File system access may need additional security review

### Monitoring & Debugging
- **Session-Based:** Can query table to see active/stuck requests
- **Temp Tables:** Can see temporary tables in metadata
- **Direct Stage:** Limited visibility into local file operations

### Cleanup & Maintenance
- **Session-Based:** Requires periodic cleanup task (provided)
- **Temp Tables:** Auto-cleanup, but may leave metadata traces
- **Direct Stage:** Minimal cleanup needed

### Error Handling
- **Session-Based:** Can retry by querying existing data
- **Temp Tables:** Clean error states, easy recovery
- **Direct Stage:** File system errors may be harder to diagnose

## Migration Path

### From Current to Session-Based:
1. Alter existing table to add columns
2. Deploy new procedure
3. Update Snowflake Intelligence configuration
4. Optional: Setup cleanup task

### Migration Script:
```sql
-- Step 1: Backup current table
CREATE TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV_BACKUP AS 
SELECT * FROM SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV;

-- Step 2: Alter table structure  
ALTER TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV ADD COLUMN session_id STRING;
ALTER TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV ADD COLUMN request_id STRING;
ALTER TABLE SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

-- Step 3: Create index for performance
CREATE INDEX idx_temp_csv_session ON SNOWFLAKE_INTELLIGENCE.PUBLIC.TEMP_CSV (session_id, request_id);

-- Step 4: Deploy new procedure (copy from csv_upload_procedure_v2_session_based.sql)
```

## Recommendation: Session-Based Approach

**Why Session-Based is the best choice:**

1. **Proven Pattern** - Session-based isolation is a well-established pattern
2. **Incremental Change** - Requires minimal changes to existing setup  
3. **Best Balance** - Optimal mix of performance, safety, and maintainability
4. **Enterprise Ready** - Includes monitoring, cleanup, and error handling
5. **Snowflake Native** - Uses `CURRENT_SESSION()` built-in function

**Implementation Priority:**
1. ✅ **Immediate:** Deploy session-based solution  
2. 🔄 **Monitor:** Watch for any performance issues
3. ⚡ **Future:** Consider direct stage approach if performance becomes critical

The session-based approach provides the best foundation for a production system with multiple concurrent users.
