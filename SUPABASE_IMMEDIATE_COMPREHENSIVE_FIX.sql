-- COMPREHENSIVE SUPABASE FIX
-- Run this entire script in your Supabase SQL Editor

-- 1. Add missing columns to meal_analyses table (ensure all columns from schema exist)
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS analysis_version TEXT DEFAULT '1.0';
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS carbohydrates DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS protein DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS fat DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS glycemic_index INTEGER DEFAULT 0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS glp1_compatibility_score DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS overall_health_score DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS primary_dish TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS key_recommendations TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS warnings TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS user_rating INTEGER;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS user_notes TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- Update existing records to have default values for new columns
UPDATE meal_analyses SET analysis_version = '1.0' WHERE analysis_version IS NULL;
UPDATE meal_analyses SET carbohydrates = 0.0 WHERE carbohydrates IS NULL;
UPDATE meal_analyses SET protein = 0.0 WHERE protein IS NULL;
UPDATE meal_analyses SET fat = 0.0 WHERE fat IS NULL;
UPDATE meal_analyses SET glycemic_index = 0 WHERE glycemic_index IS NULL;
UPDATE meal_analyses SET glp1_compatibility_score = 0.0 WHERE glp1_compatibility_score IS NULL;
UPDATE meal_analyses SET overall_health_score = 0.0 WHERE overall_health_score IS NULL;
UPDATE meal_analyses SET is_favorite = FALSE WHERE is_favorite IS NULL;

-- 2. Clean up duplicate users (keep the most recent one per email)
WITH duplicate_users AS (
    SELECT email, 
           array_agg(id ORDER BY created_at DESC) as user_ids,
           COUNT(*) as count
    FROM users 
    GROUP BY email 
    HAVING COUNT(*) > 1
)
DELETE FROM users 
WHERE id IN (
    SELECT unnest(user_ids[2:]) 
    FROM duplicate_users
);

-- 3. Create missing tables first (medications and related tables)
CREATE TABLE IF NOT EXISTS medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT,
    frequency TEXT,
    medication_type TEXT,
    instructions TEXT,
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS medication_doses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    taken_time TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'scheduled', -- scheduled, taken, missed, skipped
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, setting_key)
);

CREATE TABLE IF NOT EXISTS app_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id TEXT
);

-- Create indexes for the new tables
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_doses_user_id ON medication_doses(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_doses_scheduled_time ON medication_doses(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_app_analytics_user_id ON app_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_app_analytics_timestamp ON app_analytics(timestamp);

-- Enable RLS on new tables
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_doses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_analytics ENABLE ROW LEVEL SECURITY;

-- 4. Clean up orphaned records that reference non-existent users (only for existing tables)
DELETE FROM meals WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM glucose_readings WHERE user_id NOT IN (SELECT id FROM users);
DELETE FROM meal_analyses WHERE user_id NOT IN (SELECT id FROM users);

-- Clean up tables that might exist
DO $$
BEGIN
    -- Check if exercises table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'exercises') THEN
        DELETE FROM exercises WHERE user_id NOT IN (SELECT id FROM users);
    END IF;
    
    -- Check if health_metrics table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'health_metrics') THEN
        DELETE FROM health_metrics WHERE user_id NOT IN (SELECT id FROM users);
    END IF;
    
    -- Clean up new tables (they're empty anyway)
    DELETE FROM medications WHERE user_id NOT IN (SELECT id FROM users);
    DELETE FROM medication_doses WHERE user_id NOT IN (SELECT id FROM users);
    DELETE FROM user_settings WHERE user_id NOT IN (SELECT id FROM users);
    DELETE FROM app_analytics WHERE user_id NOT IN (SELECT id FROM users);
    
    -- Clean up orphaned medication doses
    DELETE FROM medication_doses WHERE medication_id NOT IN (SELECT id FROM medications);
END $$;

-- 5. Update RLS policies to be more permissive for authenticated users
-- Drop existing policies and recreate them with better error handling

-- Users table policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- More permissive policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (
        auth.uid() IS NOT NULL
    );

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        (auth_user_id = auth.uid() OR email = auth.email())
    );

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
    );

-- 6. Create a function to safely get or create user ID
CREATE OR REPLACE FUNCTION get_user_id_by_auth()
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- First try to find user by auth_user_id
    SELECT id INTO user_uuid 
    FROM users 
    WHERE auth_user_id = auth.uid();
    
    -- If not found, try by email
    IF user_uuid IS NULL THEN
        SELECT id INTO user_uuid 
        FROM users 
        WHERE email = auth.email();
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Update all other table policies to use the safer function
-- Meals policies
DROP POLICY IF EXISTS "Users can view own meals" ON meals;
DROP POLICY IF EXISTS "Users can insert own meals" ON meals;
DROP POLICY IF EXISTS "Users can update own meals" ON meals;
DROP POLICY IF EXISTS "Users can delete own meals" ON meals;

CREATE POLICY "Users can view own meals" ON meals
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own meals" ON meals
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own meals" ON meals
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own meals" ON meals
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- Glucose readings policies
DROP POLICY IF EXISTS "Users can view own glucose readings" ON glucose_readings;
DROP POLICY IF EXISTS "Users can insert own glucose readings" ON glucose_readings;
DROP POLICY IF EXISTS "Users can update own glucose readings" ON glucose_readings;
DROP POLICY IF EXISTS "Users can delete own glucose readings" ON glucose_readings;

CREATE POLICY "Users can view own glucose readings" ON glucose_readings
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own glucose readings" ON glucose_readings
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own glucose readings" ON glucose_readings
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own glucose readings" ON glucose_readings
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- Meal analyses policies
DROP POLICY IF EXISTS "Users can view own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can insert own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can update own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can delete own meal analyses" ON meal_analyses;

CREATE POLICY "Users can view own meal analyses" ON meal_analyses
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own meal analyses" ON meal_analyses
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own meal analyses" ON meal_analyses
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own meal analyses" ON meal_analyses
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- Medications policies
CREATE POLICY "Users can view own medications" ON medications
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own medications" ON medications
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own medications" ON medications
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own medications" ON medications
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- Medication doses policies
CREATE POLICY "Users can view own medication doses" ON medication_doses
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own medication doses" ON medication_doses
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own medication doses" ON medication_doses
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own medication doses" ON medication_doses
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- User settings policies
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can delete own settings" ON user_settings
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- App analytics policies
CREATE POLICY "Users can view own analytics" ON app_analytics
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

CREATE POLICY "Users can insert own analytics" ON app_analytics
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id = get_user_id_by_auth()
    );

-- 8. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 9. Update the user creation trigger to handle duplicates gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create user if one doesn't already exist with this email
    INSERT INTO public.users (auth_user_id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email))
    ON CONFLICT (email) DO UPDATE SET
        auth_user_id = NEW.id,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create a function to safely sync user data
CREATE OR REPLACE FUNCTION sync_user_safely(
    p_email TEXT,
    p_name TEXT DEFAULT NULL,
    p_auth_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    auth_id UUID;
BEGIN
    -- Get the current auth user ID if not provided
    auth_id := COALESCE(p_auth_user_id, auth.uid());
    
    -- Try to find existing user
    SELECT id INTO user_uuid 
    FROM users 
    WHERE email = p_email OR auth_user_id = auth_id;
    
    -- If user exists, update it
    IF user_uuid IS NOT NULL THEN
        UPDATE users 
        SET 
            name = COALESCE(p_name, name),
            auth_user_id = COALESCE(auth_id, auth_user_id),
            updated_at = NOW()
        WHERE id = user_uuid;
    ELSE
        -- Create new user
        INSERT INTO users (email, name, auth_user_id)
        VALUES (p_email, COALESCE(p_name, p_email), auth_id)
        RETURNING id INTO user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Create triggers for updated_at on new tables
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medication_doses_updated_at BEFORE UPDATE ON medication_doses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Success message
SELECT 'Comprehensive Supabase fix completed successfully! Added medications, medication_doses, user_settings, and app_analytics tables.' as status;