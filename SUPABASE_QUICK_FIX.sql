-- QUICK FIX for remaining sync issues
-- Run this in your Supabase SQL Editor

-- 1. Add all missing columns to meal_analyses table (complete set)
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS meal_name TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS analysis_data JSONB;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS nutritional_score DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS recommendations JSONB;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS confidence DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS total_calories INTEGER DEFAULT 0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS carbohydrates DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS protein DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS fat DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS glycemic_index INTEGER DEFAULT 0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS glp1_compatibility_score DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS overall_health_score DECIMAL DEFAULT 0.0;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS primary_dish TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS key_recommendations TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS warnings TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS analysis_version TEXT DEFAULT '1.0';
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS user_rating INTEGER;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS user_notes TEXT;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- 2. Update existing records with default values
UPDATE meal_analyses SET meal_name = 'Unknown Meal' WHERE meal_name IS NULL;
UPDATE meal_analyses SET nutritional_score = 0.0 WHERE nutritional_score IS NULL;
UPDATE meal_analyses SET confidence = 0.0 WHERE confidence IS NULL;
UPDATE meal_analyses SET total_calories = 0 WHERE total_calories IS NULL;
UPDATE meal_analyses SET carbohydrates = 0.0 WHERE carbohydrates IS NULL;
UPDATE meal_analyses SET protein = 0.0 WHERE protein IS NULL;
UPDATE meal_analyses SET fat = 0.0 WHERE fat IS NULL;
UPDATE meal_analyses SET glycemic_index = 0 WHERE glycemic_index IS NULL;
UPDATE meal_analyses SET glp1_compatibility_score = 0.0 WHERE glp1_compatibility_score IS NULL;
UPDATE meal_analyses SET overall_health_score = 0.0 WHERE overall_health_score IS NULL;
UPDATE meal_analyses SET is_favorite = FALSE WHERE is_favorite IS NULL;
UPDATE meal_analyses SET analysis_version = '1.0' WHERE analysis_version IS NULL;

-- 3. Fix RLS policies to be more permissive (temporarily for debugging)
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 4. Refresh the schema cache
NOTIFY pgrst, 'reload schema';

-- Success message
SELECT 'Quick fix applied - missing columns added and RLS policies updated!' as status;