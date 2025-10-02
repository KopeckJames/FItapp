-- COMPREHENSIVE MEAL_ANALYSES TABLE FIX
-- This will ensure the table has all required columns

-- First, let's see what columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'meal_analyses' 
ORDER BY ordinal_position;

-- Add all missing columns (IF NOT EXISTS prevents errors if they already exist)
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4();
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS meal_name TEXT NOT NULL DEFAULT 'Unknown Meal';
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
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE meal_analyses ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Update existing records with default values for new columns
UPDATE meal_analyses SET meal_name = 'Unknown Meal' WHERE meal_name IS NULL OR meal_name = '';
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
UPDATE meal_analyses SET analysis_version = '1.0' WHERE analysis_version IS NULL OR analysis_version = '';
UPDATE meal_analyses SET timestamp = NOW() WHERE timestamp IS NULL;
UPDATE meal_analyses SET created_at = NOW() WHERE created_at IS NULL;
UPDATE meal_analyses SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE meal_analyses SET is_deleted = FALSE WHERE is_deleted IS NULL;

-- Ensure RLS is enabled
ALTER TABLE meal_analyses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies if they don't exist
DROP POLICY IF EXISTS "Users can view own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can insert own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can update own meal analyses" ON meal_analyses;
DROP POLICY IF EXISTS "Users can delete own meal analyses" ON meal_analyses;

CREATE POLICY "Users can view own meal analyses" ON meal_analyses
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND 
        user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can insert own meal analyses" ON meal_analyses
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND 
        user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can update own meal analyses" ON meal_analyses
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND 
        user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can delete own meal analyses" ON meal_analyses
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND 
        user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_meal_analyses_user_id ON meal_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_analyses_timestamp ON meal_analyses(timestamp);
CREATE INDEX IF NOT EXISTS idx_meal_analyses_created_at ON meal_analyses(created_at);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_meal_analyses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_meal_analyses_updated_at ON meal_analyses;
CREATE TRIGGER update_meal_analyses_updated_at 
    BEFORE UPDATE ON meal_analyses
    FOR EACH ROW EXECUTE FUNCTION update_meal_analyses_updated_at();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

-- Show final column structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'meal_analyses' 
ORDER BY ordinal_position;

SELECT 'Meal analyses table fully configured with all required columns!' as status;