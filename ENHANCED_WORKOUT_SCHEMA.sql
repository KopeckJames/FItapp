-- Enhanced Workout Schema for Specialized Health-Based Programs
-- Add these tables to your existing Supabase schema

-- Workout Plans table - Pre-defined workout programs
CREATE TABLE workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    target_condition TEXT NOT NULL, -- 'type2_diabetes', 'glp1_users', 'type1_diabetes', 'general'
    fitness_level TEXT NOT NULL, -- 'beginner', 'intermediate', 'advanced', 'athlete'
    duration_weeks INTEGER NOT NULL,
    sessions_per_week INTEGER NOT NULL,
    session_duration_minutes INTEGER NOT NULL,
    equipment_needed TEXT[], -- Array of equipment
    benefits TEXT[],
    precautions TEXT[],
    image_url TEXT,
    created_by TEXT DEFAULT 'system',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Sessions table - Individual workout sessions within plans
CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
    session_number INTEGER NOT NULL, -- Week 1 Day 1, etc.
    week_number INTEGER NOT NULL,
    day_number INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    warm_up_duration INTEGER DEFAULT 5, -- minutes
    cool_down_duration INTEGER DEFAULT 5, -- minutes
    total_duration INTEGER NOT NULL, -- minutes
    intensity_level TEXT NOT NULL, -- 'low', 'moderate', 'high'
    focus_areas TEXT[], -- 'cardio', 'strength', 'flexibility', 'balance'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercise Library table - Comprehensive exercise database
CREATE TABLE exercise_library (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'cardio', 'strength', 'flexibility', 'balance', 'functional'
    subcategory TEXT, -- 'upper_body', 'lower_body', 'core', 'full_body'
    difficulty_level TEXT NOT NULL, -- 'beginner', 'intermediate', 'advanced'
    equipment_needed TEXT[],
    muscle_groups TEXT[],
    instructions TEXT[],
    safety_tips TEXT[],
    modifications TEXT[], -- Easier/harder variations
    diabetes_benefits TEXT[],
    glp1_considerations TEXT[],
    contraindications TEXT[],
    calories_per_minute DECIMAL,
    image_url TEXT,
    video_url TEXT,
    demonstration_gif_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Session Exercises table - Exercises within each workout session
CREATE TABLE session_exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercise_library(id) ON DELETE CASCADE,
    order_in_session INTEGER NOT NULL,
    sets INTEGER,
    reps INTEGER,
    duration_seconds INTEGER,
    rest_seconds INTEGER DEFAULT 60,
    intensity_percentage INTEGER, -- % of max effort
    notes TEXT,
    is_optional BOOLEAN DEFAULT FALSE
);

-- User Workout Plans table - User's enrolled workout plans
CREATE TABLE user_workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    workout_plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    target_end_date DATE,
    current_week INTEGER DEFAULT 1,
    current_session INTEGER DEFAULT 1,
    status TEXT DEFAULT 'active', -- 'active', 'paused', 'completed', 'cancelled'
    progress_percentage DECIMAL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Workout Sessions table - Track completed sessions
CREATE TABLE user_workout_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user_workout_plan_id UUID REFERENCES user_workout_plans(id) ON DELETE CASCADE,
    workout_session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    calories_burned INTEGER,
    perceived_exertion INTEGER, -- 1-10 scale
    notes TEXT,
    glucose_before INTEGER, -- For diabetic users
    glucose_after INTEGER, -- For diabetic users
    mood_before TEXT, -- 'energetic', 'tired', 'motivated', etc.
    mood_after TEXT,
    status TEXT DEFAULT 'scheduled', -- 'scheduled', 'in_progress', 'completed', 'skipped'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Exercise Performance table - Track individual exercise performance
CREATE TABLE user_exercise_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercise_library(id) ON DELETE CASCADE,
    user_workout_session_id UUID REFERENCES user_workout_sessions(id) ON DELETE CASCADE,
    sets_completed INTEGER,
    reps_completed INTEGER,
    duration_completed_seconds INTEGER,
    weight_used DECIMAL, -- For strength exercises
    difficulty_rating INTEGER, -- 1-10 scale
    form_rating INTEGER, -- 1-10 scale (self-assessed)
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Achievements table
CREATE TABLE workout_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    category TEXT, -- 'consistency', 'milestone', 'improvement', 'special'
    condition_type TEXT, -- 'general', 'type2_diabetes', 'glp1_users', 'type1_diabetes'
    criteria JSONB, -- Achievement criteria
    reward_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Achievements table
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES workout_achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress_data JSONB -- Store progress data when earned
);

-- Create indexes for performance
CREATE INDEX idx_workout_plans_condition_level ON workout_plans(target_condition, fitness_level);
CREATE INDEX idx_workout_sessions_plan_id ON workout_sessions(workout_plan_id);
CREATE INDEX idx_exercise_library_category ON exercise_library(category, difficulty_level);
CREATE INDEX idx_session_exercises_session_id ON session_exercises(workout_session_id);
CREATE INDEX idx_user_workout_plans_user_id ON user_workout_plans(user_id);
CREATE INDEX idx_user_workout_sessions_user_id ON user_workout_sessions(user_id);
CREATE INDEX idx_user_exercise_performance_user_id ON user_exercise_performance(user_id);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);

-- Enable RLS for new tables
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_exercise_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout tables
-- Workout plans and exercise library are public (read-only)
CREATE POLICY "Anyone can view workout plans" ON workout_plans FOR SELECT USING (is_active = true);
CREATE POLICY "Anyone can view workout sessions" ON workout_sessions FOR SELECT USING (true);
CREATE POLICY "Anyone can view exercise library" ON exercise_library FOR SELECT USING (true);
CREATE POLICY "Anyone can view session exercises" ON session_exercises FOR SELECT USING (true);
CREATE POLICY "Anyone can view workout achievements" ON workout_achievements FOR SELECT USING (is_active = true);

-- User-specific workout data
CREATE POLICY "Users can view own workout plans" ON user_workout_plans
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own workout plans" ON user_workout_plans
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own workout plans" ON user_workout_plans
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view own workout sessions" ON user_workout_sessions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own workout sessions" ON user_workout_sessions
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own workout sessions" ON user_workout_sessions
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view own exercise performance" ON user_exercise_performance
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own exercise performance" ON user_exercise_performance
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can view own achievements" ON user_achievements
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own achievements" ON user_achievements
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- Update triggers
CREATE TRIGGER update_workout_plans_updated_at BEFORE UPDATE ON workout_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercise_library_updated_at BEFORE UPDATE ON exercise_library
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_workout_plans_updated_at BEFORE UPDATE ON user_workout_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_workout_sessions_updated_at BEFORE UPDATE ON user_workout_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();