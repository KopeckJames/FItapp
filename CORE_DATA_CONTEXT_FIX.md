# Core Data Context Mismatch Fix

## Problem
The app was crashing with the error:
> "Illegal attempt to establish a relationship 'user' between objects in different contexts"

This happened because:
1. **UserEntity** was created in the **main context**
2. **MealAnalysisEntity** was created in the **background context**
3. Trying to set `entity.user = user` failed because they were in different contexts

## Root Cause
Core Data requires that related objects must be in the same managed object context. You cannot establish relationships between objects from different contexts.

## Solution Applied

### 1. **Context Synchronization**
```swift
// Get the user in the background context to avoid context mismatch
guard let userObjectID = mainUser.objectID.isTemporaryID ? nil : mainUser.objectID,
      let user = try? context.existingObject(with: userObjectID) as? UserEntity else {
    // Handle error
}
```

**How it works**:
- Get the `objectID` from the main context user
- Use `existingObject(with:)` to get the same user in the background context
- Now both objects are in the same context and can be related

### 2. **Permanent Object IDs**
```swift
// Ensure the user entity has a permanent object ID
try coreDataManager.context.obtainPermanentIDs(for: [userEntity])
```

**Why this matters**:
- Temporary IDs can't be used across contexts
- Permanent IDs are stable and can be used to fetch objects in different contexts
- This ensures the user can be found in background contexts

### 3. **Enhanced Save Method**
```swift
func saveWithPermanentIDs(_ objects: [NSManagedObject]) throws {
    try context.obtainPermanentIDs(for: objects)
    if context.hasChanges {
        try context.save()
    }
}
```

**Benefits**:
- Ensures objects have permanent IDs before saving
- Makes objects accessible across contexts
- Prevents temporary ID issues

## Technical Details

### Core Data Context Rules
1. **Same Context Rule**: Related objects must be in the same context
2. **Object ID Stability**: Temporary IDs are context-specific, permanent IDs are global
3. **Context Isolation**: Each context maintains its own object graph

### Best Practices Applied
1. **Obtain Permanent IDs Early**: Right after object creation
2. **Use Object IDs for Cross-Context Access**: Not direct object references
3. **Validate Object ID**: Check if it's temporary before using
4. **Error Handling**: Graceful fallback if context operations fail

## Code Flow After Fix

### User Creation
```
1. Create UserEntity in main context
2. Obtain permanent ID immediately
3. Save to database
4. User is now accessible from any context via objectID
```

### Meal Analysis Save
```
1. Get user from main context
2. Extract permanent objectID
3. Create background context
4. Fetch user in background context using objectID
5. Create MealAnalysisEntity in background context
6. Establish relationship (both objects now in same context)
7. Save successfully
```

## Error Prevention

### Before Fix
- ❌ Context mismatch crashes
- ❌ Temporary ID issues
- ❌ Relationship establishment failures

### After Fix
- ✅ Objects in same context
- ✅ Permanent IDs for stability
- ✅ Proper error handling
- ✅ Graceful fallbacks

## Testing Verification

The fix ensures:
1. **No more context crashes** when saving meal analyses
2. **Proper user relationships** in all saved data
3. **Cross-context compatibility** for future features
4. **Data integrity** maintained across operations

## Result
✅ **Crash Eliminated**: No more Core Data context mismatch errors  
✅ **Data Integrity**: Proper relationships between users and meal analyses  
✅ **Performance**: Background context operations work correctly  
✅ **Reliability**: Robust error handling for edge cases  

The app now successfully saves meal analyses with proper user relationships without any Core Data crashes.