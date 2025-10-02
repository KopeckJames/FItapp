-- Supabase SQL Schema for Fitness App
-- Run these commands in your Supabase SQL editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security
-- Note: JWT secret is automatically managed by Supabase

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    date_of_birth DATE,
    gender TEXT,
    height DECIMAL,
    weight DECIMAL,
    has_diabetes BOOLEAN DEFAULT FALSE,
    diabetes_type TEXT,
    diagnosis_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Meals table
CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    meal_type TEXT,
    carbs DECIMAL NOT NULL DEFAULT 0,
    protein DECIMAL NOT NULL DEFAULT 0,
    calories INTEGER NOT NULL DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Glucose readings table
CREATE TABLE glucose_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    level INTEGER NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Exercises table
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    intensity TEXT,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Health metrics table
CREATE TABLE health_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    heart_rate INTEGER,
    weight DECIMAL,
    temperature DECIMAL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Meal analyses table (enhanced)
CREATE TABLE meal_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    meal_name TEXT NOT NULL,
    analysis_data JSONB,
    nutritional_score DECIMAL,
    recommendations JSONB,
    confidence DECIMAL,
    total_calories INTEGER,
    carbohydrates DECIMAL,
    protein DECIMAL,
    fat DECIMAL,
    glycemic_index INTEGER,
    glp1_compatibility_score DECIMAL,
    overall_health_score DECIMAL,
    primary_dish TEXT,
    key_recommendations TEXT,
    warnings TEXT,
    analysis_version TEXT,
    image_url TEXT, -- Store image URLs instead of binary data
    user_rating INTEGER,
    user_notes TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Medications table
CREATE TABLE medications (
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

-- Medication doses table
CREATE TABLE medication_doses (
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

-- User settings table
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, setting_key)
);

-- App analytics table (anonymized)
CREATE TABLE app_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id TEXT
);

-- Create indexes for better performance
CREATE INDEX idx_meals_user_id ON meals(user_id);
CREATE INDEX idx_meals_timestamp ON meals(timestamp);
CREATE INDEX idx_glucose_readings_user_id ON glucose_readings(user_id);
CREATE INDEX idx_glucose_readings_timestamp ON glucose_readings(timestamp);
CREATE INDEX idx_exercises_user_id ON exercises(user_id);
CREATE INDEX idx_exercises_timestamp ON exercises(timestamp);
CREATE INDEX idx_health_metrics_user_id ON health_metrics(user_id);
CREATE INDEX idx_health_metrics_timestamp ON health_metrics(timestamp);
CREATE INDEX idx_meal_analyses_user_id ON meal_analyses(user_id);
CREATE INDEX idx_meal_analyses_timestamp ON meal_analyses(timestamp);
CREATE INDEX idx_medications_user_id ON medications(user_id);
CREATE INDEX idx_medication_doses_user_id ON medication_doses(user_id);
CREATE INDEX idx_medication_doses_scheduled_time ON medication_doses(scheduled_time);
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_app_analytics_user_id ON app_analytics(user_id);
CREATE INDEX idx_app_analytics_timestamp ON app_analytics(timestamp);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_doses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies - Users can only access their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Meals policies
CREATE POLICY "Users can view own meals" ON meals
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own meals" ON meals
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own meals" ON meals
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own meals" ON meals
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Glucose readings policies
CREATE POLICY "Users can view own glucose readings" ON glucose_readings
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own glucose readings" ON glucose_readings
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own glucose readings" ON glucose_readings
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own glucose readings" ON glucose_readings
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Exercises policies
CREATE POLICY "Users can view own exercises" ON exercises
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own exercises" ON exercises
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own exercises" ON exercises
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own exercises" ON exercises
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Health metrics policies
CREATE POLICY "Users can view own health metrics" ON health_metrics
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own health metrics" ON health_metrics
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own health metrics" ON health_metrics
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own health metrics" ON health_metrics
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Meal analyses policies
CREATE POLICY "Users can view own meal analyses" ON meal_analyses
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own meal analyses" ON meal_analyses
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own meal analyses" ON meal_analyses
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own meal analyses" ON meal_analyses
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Functions to automatically update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Medications policies
CREATE POLICY "Users can view own medications" ON medications
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own medications" ON medications
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own medications" ON medications
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own medications" ON medications
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Medication doses policies
CREATE POLICY "Users can view own medication doses" ON medication_doses
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own medication doses" ON medication_doses
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own medication doses" ON medication_doses
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own medication doses" ON medication_doses
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- User settings policies
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own settings" ON user_settings
    FOR DELETE USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- App analytics policies
CREATE POLICY "Users can view own analytics" ON app_analytics
    FOR SELECT USING (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own analytics" ON app_analytics
    FOR INSERT WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meals_updated_at BEFORE UPDATE ON meals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_glucose_readings_updated_at BEFORE UPDATE ON glucose_readings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON exercises
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_metrics_updated_at BEFORE UPDATE ON health_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_analyses_updated_at BEFORE UPDATE ON meal_analyses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medication_doses_updated_at BEFORE UPDATE ON medication_doses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile after auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (auth_user_id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();