# Supabase Integration Setup Guide

This guide will help you set up Supabase integration for your iOS fitness app with Core Data sync capabilities.

## Prerequisites

- Xcode 15.0+
- iOS 16.0+
- A Supabase account (free tier available)

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create an account
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: "DiabFit" (or your preferred name)
   - Database Password: Generate a strong password
   - Region: Choose closest to your users
5. Click "Create new project"
6. Wait for the project to be ready (2-3 minutes)

## Step 2: Configure Database Schema

1. In your Supabase dashboard, go to the SQL Editor
2. Copy and paste the contents of `supabase_schema.sql` into the editor
3. Click "Run" to execute the schema
4. Verify tables are created in the Table Editor

## Step 3: Get Project Credentials

1. Go to Settings → API in your Supabase dashboard
2. Copy the following values:
   - Project URL
   - Anon (public) key
   - Service role key (keep this secret!)

## Step 4: Configure iOS App

1. Open `FitnessIos/FitnessIos/Config/SupabaseConfig.swift`
2. Replace the placeholder values:
   ```swift
   private let supabaseURL = "https://your-project-id.supabase.co"
   private let supabaseAnonKey = "your-anon-key-here"
   ```

## Step 5: Add Supabase Swift Package

1. In Xcode, go to File → Add Package Dependencies
2. Enter the URL: `https://github.com/supabase/supabase-swift.git`
3. Choose "Up to Next Major Version" with version 2.0.0
4. Add to your target

## Step 6: Update Core Data Model

Add the following attributes to your Core Data entities:

### For ALL entities (UserEntity, MealEntity, GlucoseReadingEntity, etc.):
- `lastSyncedAt` (Date, Optional)
- `isDeleted` (Boolean, Default: NO)
- `needsSync` (Boolean, Default: YES)
- `supabaseId` (String, Optional)

### Steps to add attributes:
1. Open `DiabfitDataModel.xcdatamodeld`
2. Select each entity
3. Click "+" to add attributes
4. Set the attribute names and types as listed above
5. Save the model

## Step 7: Enable Authentication

1. In Supabase dashboard, go to Authentication → Settings
2. Configure your authentication providers:
   - Email/Password: Enable
   - OAuth providers: Configure as needed (Google, Apple, etc.)
3. Set up email templates if needed

## Step 8: Configure Row Level Security (RLS)

The SQL schema already includes RLS policies, but verify they're active:

1. Go to Authentication → Policies
2. Ensure all tables have policies enabled
3. Test with a sample user to verify access control

## Step 9: Test the Integration

1. Build and run your app
2. Create a test account
3. Add some data (meals, glucose readings, etc.)
4. Check the Supabase dashboard to see if data appears
5. Test offline mode by turning off internet
6. Verify data syncs when back online

## Step 10: Production Considerations

### Security
- Never commit your service role key to version control
- Use environment variables or secure storage for keys
- Enable additional security features in Supabase

### Performance
- Monitor your database usage in Supabase dashboard
- Consider implementing pagination for large datasets
- Use indexes for frequently queried fields

### Monitoring
- Set up alerts for sync failures
- Monitor sync performance and user experience
- Implement proper error handling and user feedback

## Troubleshooting

### Common Issues

1. **Authentication fails**
   - Check your project URL and anon key
   - Verify email/password auth is enabled
   - Check network connectivity

2. **Data not syncing**
   - Verify RLS policies are correct
   - Check user permissions
   - Look for sync errors in the app logs

3. **Core Data conflicts**
   - Ensure proper conflict resolution strategy
   - Check entity relationships
   - Verify attribute mappings

### Debug Steps

1. Enable verbose logging in the app
2. Check Supabase logs in the dashboard
3. Test with a fresh database
4. Verify network connectivity
5. Check authentication state

## Features Included

✅ **Authentication**: Email/password signup and signin
✅ **Real-time Sync**: Automatic sync when online
✅ **Offline Support**: Local Core Data storage when offline
✅ **Conflict Resolution**: Server-wins strategy (customizable)
✅ **Security**: Row Level Security (RLS) policies
✅ **Data Mapping**: Automatic Core Data ↔ Supabase mapping
✅ **Progress Tracking**: Sync status and progress indicators
✅ **Error Handling**: Comprehensive error reporting

## Next Steps

1. Customize the sync strategy for your needs
2. Add real-time subscriptions for collaborative features
3. Implement data export/import functionality
4. Add analytics and monitoring
5. Consider implementing custom conflict resolution

## Support

- Supabase Documentation: https://supabase.com/docs
- Swift SDK: https://github.com/supabase/supabase-swift
- Community: https://github.com/supabase/supabase/discussions

Remember to test thoroughly before deploying to production!