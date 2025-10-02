# Supabase Sync Debugging Guide

## Issues Fixed

### 1. ✅ Background Thread Publishing
**Problem**: "Publishing changes from background threads is not allowed"
**Solution**: Added proper `MainActor.run` blocks for all @Published property updates in:
- `RealTimeHealthSyncService.swift`
- `SyncManager.swift` (already had @MainActor)

### 2. ✅ Added Debug Logging
**Problem**: No visibility into sync process
**Solution**: Added logging to show:
- Number of users needing sync
- Number of meals needing sync
- Sync progress and errors

### 3. ✅ Test Data Creation
**Problem**: No data to sync (likely cause of empty database)
**Solution**: Added test data creation functionality:
- New method `createTestDataForSync()` in CoreDataManager
- New "Create Test Data" button in SupabaseTestView
- Creates test user, meal, and glucose reading marked for sync

## How to Debug Sync Issues

### Step 1: Create Test Data
1. Open the app
2. Go to Settings → Cloud Sync → Test
3. Tap "Create Test Data"
4. This creates a test user, meal, and glucose reading

### Step 2: Test Sync
1. Tap "Test Data Sync" 
2. Watch the console logs for:
   ```
   🔄 Found X users needing sync
   🔄 Found X meals needing sync
   ✅ Full sync completed successfully
   ```

### Step 3: Check Supabase Database
1. Go to your Supabase dashboard
2. Check the `users`, `meals`, and `glucose_readings` tables
3. You should see the test data appear

## Common Issues & Solutions

### Issue: "Socket is not connected"
**Cause**: Network connectivity or Supabase configuration
**Check**: 
- Internet connection
- Supabase URL and API key in `SupabaseConfig.swift`
- Supabase project is running

### Issue: "No authenticated user for sync"
**Cause**: User not signed in to Supabase
**Solution**: 
- Use AuthTestView to sign up/sign in
- Check authentication status in SupabaseTestView

### Issue: Sync completes but no data in database
**Cause**: 
- No data marked for sync
- Authentication issues
- Database permissions

**Debug Steps**:
1. Check console logs for "Found X entities needing sync"
2. If 0 entities, create test data
3. Check authentication status
4. Verify Supabase RLS policies allow inserts

## Console Log Meanings

```
🔄 Found 1 users needing sync     // Good - data exists
🔄 Found 1 meals needing sync     // Good - data exists
✅ Full sync completed successfully // Sync finished

🔄 Found 0 users needing sync     // Problem - no data to sync
❌ No authenticated user for sync  // Problem - not signed in
❌ Failed to get session: ...      // Problem - auth error
```

## Next Steps

1. **Create test data** using the new button
2. **Check console logs** during sync
3. **Verify authentication** using AuthTestView
4. **Check Supabase dashboard** for synced data

If data still doesn't appear after these steps, the issue is likely:
- Supabase RLS policies blocking inserts
- Network connectivity issues
- Authentication token problems

## Quick Test Sequence

1. Open app
2. Settings → Cloud Sync → Test
3. "Create Test Data" → should see success message
4. "Test Data Sync" → watch console logs
5. Check Supabase dashboard → should see test data

This should help identify exactly where the sync process is failing!