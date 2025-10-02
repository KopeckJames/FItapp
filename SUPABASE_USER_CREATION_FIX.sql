-- Enhanced User Creation System for Supabase
-- This ensures users are properly created in both auth.users and public.users tables

-- First, let's improve the existing trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into public.users table with proper auth_user_id linking
    INSERT INTO public.users (
        auth_user_id, 
        email, 
        name,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(
            NEW.raw_user_meta_data->>'name', 
            NEW.raw_user_meta_data->>'full_name',
            split_part(NEW.email, '@', 1) -- Use email prefix as fallback name
        ),
        NOW(),
        NOW()
    );
    
    -- Log the user creation for debugging
    INSERT INTO app_analytics (
        user_id,
        event_type,
        event_data,
        timestamp
    )
    SELECT 
        u.id,
        'user_created',
        jsonb_build_object(
            'email', NEW.email,
            'auth_user_id', NEW.id,
            'signup_method', COALESCE(NEW.raw_user_meta_data->>'provider', 'email')
        ),
        NOW()
    FROM users u 
    WHERE u.auth_user_id = NEW.id;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth signup
        RAISE LOG 'Error creating user profile for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists and is properly configured
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- Function to manually create missing user profiles
CREATE OR REPLACE FUNCTION public.create_missing_user_profiles()
RETURNS TABLE(email text, created boolean, error_message text) AS $$
DECLARE
    auth_user RECORD;
    user_exists boolean;
BEGIN
    -- Loop through all auth users that don't have profiles
    FOR auth_user IN 
        SELECT au.id, au.email, au.raw_user_meta_data
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.auth_user_id
        WHERE pu.auth_user_id IS NULL
    LOOP
        BEGIN
            -- Check if user already exists by email (in case auth_user_id is wrong)
            SELECT EXISTS(SELECT 1 FROM public.users WHERE email = auth_user.email) INTO user_exists;
            
            IF user_exists THEN
                -- Update existing user with correct auth_user_id
                UPDATE public.users 
                SET auth_user_id = auth_user.id,
                    updated_at = NOW()
                WHERE email = auth_user.email;
                
                RETURN QUERY SELECT auth_user.email::text, true, 'Updated existing profile'::text;
            ELSE
                -- Create new user profile
                INSERT INTO public.users (
                    auth_user_id,
                    email,
                    name,
                    created_at,
                    updated_at
                ) VALUES (
                    auth_user.id,
                    auth_user.email,
                    COALESCE(
                        auth_user.raw_user_meta_data->>'name',
                        auth_user.raw_user_meta_data->>'full_name',
                        split_part(auth_user.email, '@', 1)
                    ),
                    NOW(),
                    NOW()
                );
                
                RETURN QUERY SELECT auth_user.email::text, true, 'Created new profile'::text;
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                RETURN QUERY SELECT auth_user.email::text, false, SQLERRM::text;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify user profile integrity
CREATE OR REPLACE FUNCTION public.verify_user_profiles()
RETURNS TABLE(
    email text, 
    has_auth_record boolean, 
    has_profile_record boolean, 
    auth_ids_match boolean,
    issue_description text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(au.email, pu.email) as email,
        au.id IS NOT NULL as has_auth_record,
        pu.id IS NOT NULL as has_profile_record,
        (au.id = pu.auth_user_id) as auth_ids_match,
        CASE 
            WHEN au.id IS NULL THEN 'Missing auth record'
            WHEN pu.id IS NULL THEN 'Missing profile record'
            WHEN au.id != pu.auth_user_id THEN 'Auth ID mismatch'
            ELSE 'OK'
        END as issue_description
    FROM auth.users au
    FULL OUTER JOIN public.users pu ON au.email = pu.email
    ORDER BY email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.create_missing_user_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_user_profiles() TO authenticated;

-- Run the fix for existing users
SELECT * FROM public.create_missing_user_profiles();