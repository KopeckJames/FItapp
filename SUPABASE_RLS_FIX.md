# Supabase RLS Policy Fix

## Issue Identified
**Error**: `PostgrestError code: "42501" - new row violates row-level security policy for table "users"`

**Root Cause**: The `auth_user_id` in the users table doesn't match the authenticated user's JWT `auth.uid()`, causing RLS policies to block data access.

## The Problem
1. User authenticates successfully with email `test@gmail.com`
2. App tries to sync data to Supabase
3. RLS policies check if `auth.uid() = auth_user_id` 
4. The check fails because `auth_user_id` is either NULL or doesn't match the JWT

## Solution Options

### Option 1: Fix User Record (Recommended)
Update the existing user record to have the correct `auth_user_id`:

```sql
-- Run this in Supabase SQL Editor
-- Replace 'test@gmail.com' with the actual email
-- Replace 'actual-auth-uuid' with the real auth.users.id

UPDATE users 
SET auth_user_id = (
    SELECT id FROM auth.users WHERE email = 'test@gmail.com'
)
WHERE email = 'test@gmail.com' AND auth_user_id IS NULL;
```

### Option 2: Temporary RLS Bypass (For Testing Only)
Temporarily disable RLS to test sync functionality:

```sql
-- ONLY FOR TESTING - DO NOT USE IN PRODUCTION
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Re-enable after testing:
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

### Option 3: Enhanced RLS Policies (Best Long-term)
Create more flexible RLS policies that handle edge cases:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Create enhanced policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (
        auth.uid() = auth_user_id OR 
        (auth_user_id IS NULL AND email = auth.jwt() ->> 'email')
    );

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (
        auth.uid() = auth_user_id OR 
        (auth_user_id IS NULL AND email = auth.jwt() ->> 'email')
    );

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (
        auth.uid() = auth_user_id OR 
        email = auth.jwt() ->> 'email'
    );
```

## iOS App Changes Needed

### 1. Add User ID Sync Function
Add this to your Supabase service:

```swift
func syncUserAuthId() async throws {
    guard let user = supabase.auth.currentUser else {
        throw SupabaseError.notAuthenticated
    }
    
    let userUpdate = [
        "auth_user_id": user.id.uuidString,
        "updated_at": ISO8601DateFormatter().string(from: Date())
    ]
    
    try await supabase
        .from("users")
        .update(userUpdate)
        .eq("email", value: user.email ?? "")
        .execute()
}
```

### 2. Call Sync on Login
In your authentication flow:

```swift
// After successful login
try await syncUserAuthId()
```

### 3. Enhanced Error Handling
Add specific handling for RLS errors:

```swift
func handleSupabaseError(_ error: Error) {
    if let postgrestError = error as? PostgrestError,
       postgrestError.code == "42501" {
        // RLS policy violation - try to sync user ID
        Task {
            try? await syncUserAuthId()
        }
    }
}
```

## Immediate Fix Steps

1. **Check Current User Data**:
   ```sql
   SELECT id, email, auth_user_id FROM users WHERE email = 'test@gmail.com';
   SELECT id, email FROM auth.users WHERE email = 'test@gmail.com';
   ```

2. **Update User Record**:
   ```sql
   UPDATE users 
   SET auth_user_id = (SELECT id FROM auth.users WHERE email = 'test@gmail.com')
   WHERE email = 'test@gmail.com';
   ```

3. **Verify Fix**:
   ```sql
   SELECT u.email, u.auth_user_id, au.id as auth_id
   FROM users u
   JOIN auth.users au ON u.email = au.email
   WHERE u.email = 'test@gmail.com';
   ```

## Prevention
- Always set `auth_user_id` when creating user records
- Add validation in the trigger function
- Implement proper error handling for RLS violations

This should resolve the sync failure and allow your app to properly sync data with Supabase.