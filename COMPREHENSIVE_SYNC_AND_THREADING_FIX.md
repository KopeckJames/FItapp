# Comprehensive Sync and Threading Fix

## Issues Identified

1. **Background Thread Publishing** - Multiple UI updates happening off main thread
2. **Database Schema Mismatch** - Missing `analysis_version` column in `meal_analyses` table  
3. **RLS Policy Violations** - Row-level security blocking user operations
4. **Foreign Key Constraint Failures** - Data integrity issues
5. **Duplicate Key Violations** - Users already exist in database

## Fix Implementation

### 1. Database Schema Fix (Run in Supabase SQL Editor)

```sql
-- Add missing analysis_version column to meal_analyses table
ALTER TABLE meal_analyses 
ADD COLUMN IF NOT EXISTS analysis_version TEXT DEFAULT '1.0';

-- Update existing records to have a default analysis_version
UPDATE meal_analyses 
SET analysis_version = '1.0' 
WHERE analysis_version IS NULL;

-- Clean up duplicate users (keep the most recent one)
WITH duplicate_users AS (
    SELECT email, 
           MIN(created_at) as first_created,
           MAX(created_at) as last_created,
           COUNT(*) as count
    FROM users 
    GROUP BY email 
    HAVING COUNT(*) > 1
)
DELETE FROM users 
WHERE email IN (SELECT email FROM duplicate_users)
AND created_at NOT IN (SELECT last_created FROM duplicate_users);

-- Reset foreign key constraints by cleaning orphaned records
DELETE FROM meals WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM glucose_readings WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM meal_analyses WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM exercises WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM health_metrics WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM medications WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM medication_doses WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM user_settings WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM app_analytics WHERE user_id NOT IN (SELECT id FROM users);
```

### 2. Swift Threading and Sync Fixes

The main issues are in the sync operations and UI updates. Need to:

1. Ensure all UI updates happen on main thread
2. Fix RLS authentication issues
3. Handle duplicate user scenarios gracefully
4. Add proper error handling for foreign key constraints

### 3. Implementation Steps

1. Run the SQL fixes above in Supabase
2. Update sync services to handle threading properly
3. Fix authentication flow to ensure RLS tokens are set
4. Add duplicate handling logic
5. Test the complete flow

## Expected Results

- ✅ No more background thread publishing warnings
- ✅ Schema mismatch resolved
- ✅ RLS policies working correctly
- ✅ Clean user sync without duplicates
- ✅ Proper foreign key relationships
- ✅ Reduced memory usage
- ✅ Stable app performance