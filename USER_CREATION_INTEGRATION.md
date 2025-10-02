# Complete User Creation Integration Guide

## Overview
This guide ensures that every new user is properly created in both Supabase Auth and your public users table, with correct RLS policy compliance.

## 1. Database Setup (Run in Supabase SQL Editor)

### Step 1: Apply the Enhanced User Creation System
```sql
-- Run the entire SUPABASE_USER_CREATION_FIX.sql file
-- This includes:
-- - Enhanced trigger function
-- - Missing profile creation function  
-- - Profile verification function
-- - Automatic fix for existing users
```

### Step 2: Verify Current State
```sql
-- Check all user profiles
SELECT * FROM public.verify_user_profiles();

-- Fix any missing profiles
SELECT * FROM public.create_missing_user_profiles();
```

## 2. iOS Integration

### Step 1: Add the SupabaseUserService
- Add `SupabaseUserService.swift` to your project
- This handles all user profile creation and verification

### Step 2: Update Your Authentication Flow

Replace your current auth calls with:

```swift
// In your AuthViewModel or similar
class AuthViewModel: ObservableObject {
    private let userService: SupabaseUserService
    
    init() {
        self.userService = SupabaseUserService(supabase: supabase)
    }
    
    // For Sign Up
    func signUp(email: String, password: String, name: String) async {
        do {
            let user = try await userService.signUpWithProfile(
                email: email, 
                password: password, 
                name: name
            )
            // Handle successful signup
            await syncUserData()
        } catch {
            // Handle error
            print("Signup failed: \(error)")
        }
    }
    
    // For Sign In  
    func signIn(email: String, password: String) async {
        do {
            let user = try await userService.signInWithProfile(
                email: email, 
                password: password
            )
            // Handle successful signin
            await syncUserData()
        } catch {
            // Handle error
            print("Signin failed: \(error)")
        }
    }
    
    // Ensure profile exists (call after any auth state change)
    func ensureUserProfile() async {
        do {
            try await userService.ensureUserProfileExists()
        } catch {
            print("Profile verification failed: \(error)")
        }
    }
}
```

### Step 3: Update Your Sync Service

Add profile verification to your sync process:

```swift
// In your DataSyncService or similar
func performSync() async throws {
    // First ensure user profile exists
    try await userService.ensureUserProfileExists()
    
    // Then proceed with normal sync
    try await syncMeals()
    try await syncAnalyses()
    // ... other sync operations
}
```

## 3. Testing the Integration

### Test Case 1: New User Signup
1. Create a new account through your app
2. Check Supabase dashboard:
   - User should appear in Authentication > Users
   - User should appear in Database > users table
   - `auth_user_id` should match between tables

### Test Case 2: Existing User Fix
1. Run the verification function:
   ```sql
   SELECT * FROM public.verify_user_profiles();
   ```
2. Any issues should be automatically fixed

### Test Case 3: Sync After Profile Creation
1. Sign up a new user
2. Immediately try to sync data
3. Should work without RLS errors

## 4. Monitoring and Debugging

### Check User Profile Status
```sql
-- See all user profiles and their status
SELECT 
    u.email,
    u.auth_user_id,
    au.id as auth_id,
    u.created_at,
    CASE 
        WHEN u.auth_user_id = au.id THEN '✅ OK'
        WHEN u.auth_user_id IS NULL THEN '❌ Missing auth_user_id'
        ELSE '❌ ID Mismatch'
    END as status
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
ORDER BY u.created_at DESC;
```

### Check Recent User Creation Events
```sql
-- See recent user creation events
SELECT 
    event_type,
    event_data,
    timestamp
FROM app_analytics 
WHERE event_type = 'user_created' 
ORDER BY timestamp DESC 
LIMIT 10;
```

### iOS Debugging
Add this to your app startup:

```swift
// In your app initialization
func verifyUserSetup() async {
    if supabase.auth.currentUser != nil {
        do {
            let profile = try await userService.getUserProfile()
            print("✅ User profile verified: \(profile?.email ?? "unknown")")
        } catch {
            print("❌ User profile issue: \(error)")
            // Try to fix it
            try? await userService.ensureUserProfileExists()
        }
    }
}
```

## 5. Prevention Measures

### Always Use the UserService
- Never call `supabase.auth.signUp()` directly
- Always use `userService.signUpWithProfile()`
- Always call `ensureUserProfileExists()` after auth state changes

### Regular Health Checks
Add this to your app's periodic tasks:

```swift
// Run weekly or on app updates
func performUserHealthCheck() async {
    try? await userService.ensureUserProfileExists()
}
```

## Expected Results

After implementing this system:

✅ **New users**: Automatically get profiles in both auth and public tables  
✅ **Existing users**: Get fixed automatically on next login  
✅ **RLS compliance**: All operations respect security policies  
✅ **Sync reliability**: No more "42501" RLS policy violations  
✅ **Data integrity**: Consistent user data across all tables  

## Rollback Plan

If issues occur, you can temporarily disable RLS:

```sql
-- Emergency rollback (use sparingly)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Re-enable after fixing
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

This comprehensive approach ensures robust user creation and eliminates the RLS sync issues you're experiencing.