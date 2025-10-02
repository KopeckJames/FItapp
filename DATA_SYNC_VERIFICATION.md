# 🔄 Data Sync Verification Guide

Your Supabase integration is now ready for testing! Follow this guide to ensure all data syncs properly.

## 🎯 **Quick Start Testing**

### 1. **Add Test Interface to Your App**
Add this to any view in your app for easy testing access:

```swift
// In your settings view or main view:
DebugMenuView()

// Or add to toolbar:
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        DebugMenuView()
    }
}
```

### 2. **Run Tests in Order**
1. **Authentication Test** → Create account and sign in
2. **Data Sync Test** → Verify data synchronization
3. **Full Integration Test** → Complete validation

## 🧪 **Test Scenarios**

### **Authentication Test**
- ✅ Create new account with email/password
- ✅ Sign in with existing credentials
- ✅ Verify user creation in both Core Data and Supabase
- ✅ Test automatic sync trigger on authentication

### **Data Sync Test**
- ✅ Create test meal, glucose reading, exercise, health metric
- ✅ Verify entities are marked for sync (`needsSync = true`)
- ✅ Push sync: Core Data → Supabase
- ✅ Pull sync: Supabase → Core Data
- ✅ Verify data appears in Supabase dashboard

### **Real-World Testing**
1. **Create Data**: Add meals, glucose readings, exercises
2. **Check Supabase**: Verify data appears in your dashboard
3. **Test Offline**: Turn off internet, add data, turn back on
4. **Multi-Device**: Sign in on another device, verify data syncs

## 🔍 **Verification Checklist**

### **Core Data Model** ✅
- [ ] All entities have sync attributes (`lastSyncedAt`, `isDeleted`, `needsSync`, `supabaseId`)
- [ ] Entities are properly marked for sync when created/modified
- [ ] Relationships between entities are maintained

### **Supabase Database** ✅
- [ ] All tables created successfully
- [ ] Row Level Security (RLS) policies active
- [ ] User can only see their own data
- [ ] Triggers and functions working

### **Authentication** ✅
- [ ] Users can sign up successfully
- [ ] Users can sign in successfully
- [ ] User records created in both Core Data and Supabase
- [ ] Authentication state persists across app launches

### **Data Synchronization** ✅
- [ ] New data syncs to Supabase automatically
- [ ] Remote data syncs to Core Data
- [ ] Offline changes sync when back online
- [ ] No duplicate data created
- [ ] Sync errors are handled gracefully

## 🚨 **Common Issues & Solutions**

### **Authentication Fails**
```
❌ Error: "Invalid credentials" or "User not found"
✅ Solution: 
- Check email/password format
- Verify Supabase auth is enabled
- Try creating new account first
```

### **Data Not Syncing**
```
❌ Error: Entities remain with needsSync = true
✅ Solution:
- Check network connectivity
- Verify user is authenticated
- Check Supabase dashboard for RLS policy issues
- Review sync error messages
```

### **Core Data Crashes**
```
❌ Error: "Entity not found" or attribute errors
✅ Solution:
- Verify Core Data model has all sync attributes
- Clean build folder (Cmd+Shift+K)
- Reset simulator if needed
```

### **Supabase Connection Issues**
```
❌ Error: Network or authentication errors
✅ Solution:
- Verify project URL and anon key
- Check Supabase project status
- Test with simple connection test
```

## 📊 **Monitoring Data Sync**

### **In Your App**
- Use `SyncStatusView()` to monitor sync progress
- Check `syncManager.syncErrors` for issues
- Monitor `syncManager.isSyncing` for active operations

### **In Supabase Dashboard**
1. Go to **Table Editor** to see synced data
2. Check **Authentication** → **Users** for user accounts
3. Review **Logs** for any errors or issues

### **Debug Information**
```swift
// Check sync status
print("Entities needing sync: \(coreDataManager.getEntitiesNeedingSync().count)")
print("Is online: \(supabaseService.isOnline)")
print("Current user: \(supabaseService.getCurrentUser()?.email ?? "None")")
```

## 🎉 **Success Indicators**

### **✅ Everything Working When:**
1. **Authentication**: Users can sign up/in without errors
2. **Data Creation**: New entities automatically marked for sync
3. **Push Sync**: Local data appears in Supabase dashboard
4. **Pull Sync**: Remote changes appear in app
5. **Offline Mode**: App works offline, syncs when back online
6. **Multi-Device**: Data syncs across different devices
7. **No Duplicates**: Same data doesn't appear multiple times

### **📈 Expected Behavior:**
- **New User**: Account created → User record in Supabase → Ready for data sync
- **Add Meal**: Meal created → Marked for sync → Appears in Supabase within seconds
- **Offline**: Data stored locally → Syncs automatically when online
- **Sign In**: Existing data pulled from Supabase → Available immediately

## 🔧 **Advanced Testing**

### **Stress Testing**
- Create 50+ meals rapidly
- Test with poor network connection
- Test concurrent operations

### **Edge Cases**
- Very long text in notes fields
- Special characters in names
- Rapid create/delete operations
- App backgrounding during sync

### **Performance Testing**
- Monitor sync times for large datasets
- Check memory usage during sync
- Test with thousands of records

## 📞 **Getting Help**

If tests fail or you encounter issues:

1. **Check the test results** for specific error messages
2. **Review Supabase logs** in your dashboard
3. **Verify your setup** against the setup guides
4. **Test with fresh data** to isolate issues
5. **Check network connectivity** and authentication state

Your integration includes comprehensive error handling and detailed logging to help diagnose any issues quickly!

---

**Ready to test?** Add `DebugMenuView()` to your app and start with the Authentication Test! 🚀