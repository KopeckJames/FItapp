-- Development Auth Fix: Disable Email Confirmation and Auto-Confirm Users
-- Run this in your Supabase SQL editor for development/testing

-- 1. Disable email confirmation requirement
UPDATE auth.config 
SET enable_confirmations = false
WHERE true;

-- 2. Auto-confirm any existing unconfirmed users
UPDATE auth.users 
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  confirmed_at = COALESCE(confirmed_at, NOW())
WHERE email_confirmed_at IS NULL OR confirmed_at IS NULL;

-- 3. Create function to auto-confirm new users
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Auto-confirm the user
  NEW.email_confirmed_at = NOW();
  NEW.confirmed_at = NOW();
  
  -- Log for debugging
  RAISE NOTICE 'Auto-confirmed user: %', NEW.email;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_auto_confirm ON auth.users;

-- 5. Create trigger to auto-confirm new signups
CREATE TRIGGER on_auth_user_created_auto_confirm
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_user();

-- 6. Verify settings
SELECT 
  'Current auth config:' as info,
  enable_signup,
  enable_confirmations
FROM auth.config;

-- 7. Show any unconfirmed users (should be none after running this)
SELECT 
  'Unconfirmed users:' as info,
  COUNT(*) as count
FROM auth.users 
WHERE email_confirmed_at IS NULL OR confirmed_at IS NULL;

-- 8. Test query - show recent users
SELECT 
  'Recent users:' as info,
  email,
  email_confirmed_at IS NOT NULL as email_confirmed,
  confirmed_at IS NOT NULL as confirmed,
  created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;