# Fix: Disable Email Confirmation in Supabase

## Issue
New user signups are failing with "authentication failed: email not confirmed" because Supabase requires email confirmation by default.

## Solution Options

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Settings**
3. Scroll down to **User Signups**
4. **Disable** "Enable email confirmations"
5. **Enable** "Enable signups" (if not already enabled)
6. Click **Save**

### Option 2: SQL Script (Alternative)
Run the provided `DISABLE_EMAIL_CONFIRMATION.sql` script in your Supabase SQL editor.

### Option 3: Environment Variables (If using Supabase CLI)
Add to your Supabase config:
```toml
[auth]
enable_signup = true
enable_confirmations = false
```

## Verification
After making changes:
1. Try creating a new user account
2. The signup should complete without requiring email confirmation
3. Users should be able to sign in immediately after signup

## Security Note
Disabling email confirmation means:
- Users can sign up with any email address (even fake ones)
- No email verification is required
- Consider re-enabling this in production with proper email setup

For development/testing, this is fine. For production, you'll want to:
1. Set up proper SMTP email configuration
2. Re-enable email confirmations
3. Handle the confirmation flow in your app

## Testing
After applying the fix, test with a new email address to ensure signup works without confirmation.