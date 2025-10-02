# Quick Setup Checklist ✅

Your Supabase credentials are now configured! Follow these steps to complete the setup:

## ✅ Step 1: Database Schema (REQUIRED)
1. Go to your Supabase dashboard: https://ccdqnrmhhwlaprhsxjzj.supabase.co
2. Navigate to **SQL Editor**
3. Copy and paste the entire contents of `supabase_schema.sql`
4. Click **Run** to create all tables and policies

## ✅ Step 2: Add Supabase Package to Xcode
1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter URL: `https://github.com/supabase/supabase-swift.git`
4. Choose **Up to Next Major Version** starting from `2.0.0`
5. Add to your **FitnessIos** target

## ✅ Step 3: Update Core Data Model
Add these attributes to ALL your Core Data entities:

### Required Attributes for Each Entity:
- `lastSyncedAt` (Date, Optional)
- `isDeleted` (Boolean, Default Value: NO)
- `needsSync` (Boolean, Default Value: YES)  
- `supabaseId` (String, Optional)

### Entities to Update:
- ✅ UserEntity
- ✅ MealEntity  
- ✅ GlucoseReadingEntity
- ✅ ExerciseEntity
- ✅ HealthMetricEntity
- ✅ MealAnalysisEntity

### How to Add Attributes:
1. Open `DiabfitDataModel.xcdatamodeld`
2. Select each entity
3. Click **+** in the Data Model Inspector
4. Add each attribute with correct name and type
5. Set default values where specified
6. Save the model

## ✅ Step 4: Test the Integration
1. Build and run your app
2. Navigate to Settings (add the test view to your settings)
3. Use the **SupabaseTestView** to verify everything works
4. Test authentication, sync, and offline mode

## ✅ Step 5: Enable Authentication (Optional)
If you want to test authentication immediately:
1. In Supabase dashboard → **Authentication → Settings**
2. Enable **Email** provider
3. Configure email templates if needed

## 🚀 You're Ready!

Once you complete these steps, your app will have:
- ✅ Real-time cloud sync
- ✅ Offline support  
- ✅ User authentication
- ✅ Automatic conflict resolution
- ✅ Secure data isolation

## 🔧 Quick Test Commands

After setup, you can test with these actions in your app:
1. Create a meal → Should sync to cloud
2. Turn off internet → App still works offline
3. Turn on internet → Data syncs automatically
4. Check Supabase dashboard → See your data

## 🆘 Need Help?

If you encounter issues:
1. Check the detailed `SUPABASE_SETUP_GUIDE.md`
2. Use the built-in test view to diagnose problems
3. Verify your Core Data model has all required attributes
4. Check Supabase dashboard for data and errors

Your credentials are already configured - just complete the database setup and you're good to go! 🎉