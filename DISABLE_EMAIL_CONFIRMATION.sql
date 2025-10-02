-- Disable email confirmation requirement in Supabase
-- Run this in your Supabase SQL editor

-- Update auth configuration to disable email confirmation
UPDATE auth.config 
SET 
  enable_signup = true,
  enable_confirmations = false,
  enable_email_confirmations = false
WHERE id = 1;

-- If the above doesn't work, you can also try updating the auth settings directly
-- This disables email confirmation for new signups
INSERT INTO auth.config (id, enable_signup, enable_confirmations, enable_email_confirmations)
VALUES (1, true, false, false)
ON CONFLICT (id) 
DO UPDATE SET 
  enable_signup = true,
  enable_confirmations = false,
  enable_email_confirmations = false;

-- Alternative: Update auth schema settings
-- This ensures new users are automatically confirmed
UPDATE auth.users 
SET email_confirmed_at = NOW(), confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- Create a trigger to auto-confirm new users (if the above config doesn't work)
CREATE OR REPLACE FUNCTION auto_confirm_users()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email_confirmed_at = NOW();
  NEW.confirmed_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it exists and recreate it
DROP TRIGGER IF EXISTS auto_confirm_users_trigger ON auth.users;

CREATE TRIGGER auto_confirm_users_trigger
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION auto_confirm_users();

-- Verify the configuration
SELECT 
  enable_signup,
  enable_confirmations,
  enable_email_confirmations
FROM auth.config 
WHERE id = 1;