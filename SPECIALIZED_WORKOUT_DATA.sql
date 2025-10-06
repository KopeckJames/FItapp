-- Specialized Workout Programs Data
-- Insert comprehensive workout plans for different health conditions and fitness levels

-- First, let's populate the exercise library with diabetes-friendly exercises
INSERT INTO exercise_library (name, category, subcategory, difficulty_level, equipment_needed, muscle_groups, instructions, safety_tips, modifications, diabetes_benefits, glp1_considerations, calories_per_minute, image_url) VALUES

-- BEGINNER CARDIO EXERCISES
('Gentle Walking', 'cardio', 'low_impact', 'beginner', '{}', '{"legs", "cardiovascular"}', 
 '{"Start with a comfortable pace", "Maintain steady breathing", "Walk for 10-30 minutes", "Focus on good posture"}',
 '{"Check blood sugar before and after", "Carry glucose tablets", "Stay hydrated", "Wear proper footwear"}',
 '{"Slower pace for beginners", "Increase duration gradually", "Add inclines for challenge"}',
 '{"Improves insulin sensitivity", "Lowers blood glucose", "Reduces cardiovascular risk", "Low impact on joints"}',
 '{"Excellent for GLP-1 users", "Helps with weight management", "Low risk of hypoglycemia"}',
 4.5, 'walking-exercise.jpg'),

('Stationary Bike (Easy)', 'cardio', 'low_impact', 'beginner', '{"stationary_bike"}', '{"legs", "cardiovascular"}',
 '{"Adjust seat height properly", "Start with low resistance", "Maintain steady pace", "Keep core engaged"}',
 '{"Monitor heart rate", "Check glucose levels", "Start with short sessions", "Stop if feeling dizzy"}',
 '{"Use recumbent bike for back support", "Increase resistance gradually", "Add intervals for progression"}',
 '{"Excellent glucose control", "Joint-friendly exercise", "Builds leg strength", "Improves circulation"}',
 '{"Perfect for weight loss goals", "Low impact option", "Easy to monitor intensity"}',
 6.0, 'stationary-bike-beginner.jpg'),

('Chair Exercises', 'cardio', 'seated', 'beginner', '{"chair"}', '{"arms", "core", "legs"}',
 '{"Sit tall with feet flat", "Perform arm circles", "Leg extensions", "Seated marching"}',
 '{"Ensure chair stability", "Move within comfort range", "Breathe steadily", "Stop if pain occurs"}',
 '{"Add light weights", "Increase repetitions", "Stand for some exercises if able"}',
 '{"Accessible for all fitness levels", "Improves circulation", "Builds strength safely"}',
 '{"Great for those with mobility limitations", "Low energy expenditure"}',
 3.0, 'chair-exercises.jpg'),

-- INTERMEDIATE CARDIO EXERCISES
('Brisk Walking', 'cardio', 'moderate_impact', 'intermediate', '{}', '{"legs", "cardiovascular"}',
 '{"Walk at 3-4 mph pace", "Pump arms naturally", "Maintain conversation pace", "Focus on heel-to-toe stride"}',
 '{"Monitor blood sugar", "Carry emergency supplies", "Wear reflective gear if outdoors", "Stay hydrated"}',
 '{"Add hills or inclines", "Increase duration", "Try interval walking"}',
 '{"Significant glucose lowering", "Improves cardiovascular health", "Burns calories effectively"}',
 '{"Supports weight loss goals", "Moderate intensity perfect for GLP-1 users"}',
 5.5, 'brisk-walking.jpg'),

('Swimming (Moderate)', 'cardio', 'full_body', 'intermediate', '{"pool"}', '{"full_body", "cardiovascular"}',
 '{"Start with easy strokes", "Focus on breathing rhythm", "Swim at comfortable pace", "Use pool edge for rest"}',
 '{"Never swim alone", "Check glucose before entering water", "Have poolside glucose supplies", "Exit if feeling unwell"}',
 '{"Use kickboard for beginners", "Try different strokes", "Add pool walking"}',
 '{"Excellent full-body workout", "Joint-friendly", "Great for circulation", "Burns significant calories"}',
 '{"Low impact option", "Excellent calorie burn", "Reduces joint stress"}',
 8.0, 'swimming-moderate.jpg'),

('Cycling (Moderate)', 'cardio', 'moderate_impact', 'intermediate', '{"bicycle"}', '{"legs", "cardiovascular"}',
 '{"Maintain steady cadence", "Use appropriate gear", "Keep proper posture", "Brake safely"}',
 '{"Wear helmet always", "Check glucose before long rides", "Carry supplies", "Avoid traffic when possible"}',
 '{"Use stationary bike indoors", "Add hills for challenge", "Try interval training"}',
 '{"Builds leg strength", "Improves glucose control", "Great cardiovascular workout"}',
 '{"Excellent for weight management", "Can adjust intensity easily"}',
 7.5, 'cycling-moderate.jpg'),

-- ADVANCED CARDIO EXERCISES
('Running (Steady State)', 'cardio', 'high_impact', 'advanced', '{"running_shoes"}', '{"legs", "cardiovascular"}',
 '{"Maintain steady pace", "Land midfoot", "Keep arms relaxed", "Breathe rhythmically"}',
 '{"Monitor glucose closely", "Carry fast-acting carbs", "Run with partner if possible", "Check feet regularly"}',
 '{"Start with walk-run intervals", "Increase distance gradually", "Add speed work"}',
 '{"Powerful glucose lowering effect", "Builds cardiovascular fitness", "Burns high calories"}',
 '{"Monitor for hypoglycemia risk", "Excellent for weight loss", "High calorie burn"}',
 10.0, 'running-steady.jpg'),

('HIIT Cardio', 'cardio', 'high_intensity', 'advanced', '{}', '{"full_body", "cardiovascular"}',
 '{"Alternate high and low intensity", "Work for 30 seconds, rest 30 seconds", "Maintain good form", "Push hard during work periods"}',
 '{"Monitor glucose carefully", "Have glucose readily available", "Stop if feeling unwell", "Start conservatively"}',
 '{"Reduce work intervals", "Increase rest periods", "Lower intensity for beginners"}',
 '{"Excellent post-exercise glucose lowering", "Improves insulin sensitivity", "Time-efficient"}',
 '{"Great for weight loss", "Improves metabolic rate", "Monitor for low blood sugar"}',
 12.0, 'hiit-cardio.jpg'),

-- BEGINNER STRENGTH EXERCISES
('Wall Push-ups', 'strength', 'upper_body', 'beginner', '{}', '{"chest", "arms", "shoulders"}',
 '{"Stand arms length from wall", "Place palms flat against wall", "Push away and return slowly", "Keep body straight"}',
 '{"Start with few repetitions", "Focus on proper form", "Stop if wrist pain occurs"}',
 '{"Move feet further from wall for difficulty", "Progress to incline push-ups"}',
 '{"Builds upper body strength", "Improves bone density", "Supports daily activities"}',
 '{"Low intensity strength building", "Good for beginners"}',
 3.5, 'wall-pushups.jpg'),

('Bodyweight Squats', 'strength', 'lower_body', 'beginner', '{}', '{"legs", "glutes", "core"}',
 '{"Stand with feet shoulder-width apart", "Lower as if sitting in chair", "Keep knees behind toes", "Return to standing"}',
 '{"Start with partial range of motion", "Hold onto chair if needed", "Keep chest up"}',
 '{"Use chair for support", "Increase depth gradually", "Add weight when ready"}',
 '{"Builds functional leg strength", "Improves glucose uptake", "Supports daily activities"}',
 '{"Excellent functional exercise", "Builds muscle mass"}',
 4.0, 'bodyweight-squats.jpg'),

('Seated Leg Extensions', 'strength', 'lower_body', 'beginner', '{"chair"}', '{"quadriceps"}',
 '{"Sit tall in chair", "Extend one leg straight", "Hold for 2 seconds", "Lower slowly"}',
 '{"Use chair with back support", "Move within pain-free range", "Breathe normally"}',
 '{"Add ankle weights", "Increase hold time", "Do both legs simultaneously"}',
 '{"Strengthens leg muscles", "Improves knee stability", "Accessible exercise"}',
 '{"Low impact strength building", "Good for those with limited mobility"}',
 2.5, 'seated-leg-extensions.jpg'),

-- INTERMEDIATE STRENGTH EXERCISES
('Modified Push-ups', 'strength', 'upper_body', 'intermediate', '{}', '{"chest", "arms", "shoulders", "core"}',
 '{"Start in plank position on knees", "Lower chest to floor", "Push back up", "Keep straight line from knees to head"}',
 '{"Maintain proper form", "Start with fewer reps", "Progress gradually"}',
 '{"Wall push-ups for easier", "Full push-ups for harder", "Elevate feet for challenge"}',
 '{"Builds upper body strength", "Improves core stability", "Functional movement"}',
 '{"Good progression exercise", "Builds muscle mass"}',
 5.0, 'modified-pushups.jpg'),

('Dumbbell Rows', 'strength', 'upper_body', 'intermediate', '{"dumbbells", "bench"}', '{"back", "arms"}',
 '{"Bend over with one knee on bench", "Pull dumbbell to ribcage", "Squeeze shoulder blades", "Lower with control"}',
 '{"Start with light weight", "Keep back straight", "Avoid jerky movements"}',
 '{"Use resistance band if no weights", "Increase weight gradually", "Try single-arm variations"}',
 '{"Strengthens back muscles", "Improves posture", "Balances pushing exercises"}',
 '{"Builds lean muscle mass", "Improves metabolism"}',
 4.5, 'dumbbell-rows.jpg'),

('Goblet Squats', 'strength', 'lower_body', 'intermediate', '{"dumbbell"}', '{"legs", "glutes", "core"}',
 '{"Hold dumbbell at chest", "Squat down keeping chest up", "Drive through heels to stand", "Keep core engaged"}',
 '{"Start with light weight", "Focus on form over weight", "Keep knees aligned"}',
 '{"Bodyweight version first", "Increase weight gradually", "Add pause at bottom"}',
 '{"Builds functional strength", "Improves glucose uptake", "Strengthens core"}',
 '{"Excellent compound exercise", "Burns calories while building strength"}',
 6.0, 'goblet-squats.jpg'),

-- ADVANCED STRENGTH EXERCISES
('Full Push-ups', 'strength', 'upper_body', 'advanced', '{}', '{"chest", "arms", "shoulders", "core"}',
 '{"Start in plank position", "Lower chest to floor", "Push back up explosively", "Maintain straight body line"}',
 '{"Warm up thoroughly", "Progress gradually", "Stop if form breaks down"}',
 '{"Elevate feet for difficulty", "Add clap push-ups", "Try single-arm variations"}',
 '{"Builds significant upper body strength", "Improves core stability", "Functional power"}',
 '{"High intensity strength exercise", "Builds muscle mass efficiently"}',
 7.0, 'full-pushups.jpg'),

('Deadlifts', 'strength', 'full_body', 'advanced', '{"barbell", "dumbbells"}', '{"legs", "back", "core"}',
 '{"Stand with feet hip-width apart", "Hinge at hips to lower weight", "Keep back straight", "Drive hips forward to stand"}',
 '{"Learn proper form first", "Start with light weight", "Keep weight close to body"}',
 '{"Use dumbbells instead of barbell", "Elevate weight on platform", "Try sumo stance"}',
 '{"Builds total body strength", "Improves functional movement", "Excellent for bone density"}',
 '{"High calorie burn", "Builds significant muscle mass", "Improves metabolism"}',
 8.0, 'deadlifts.jpg'),

-- FLEXIBILITY EXERCISES
('Gentle Yoga Flow', 'flexibility', 'full_body', 'beginner', '{"yoga_mat"}', '{"full_body"}',
 '{"Move slowly between poses", "Focus on breathing", "Hold poses for 30 seconds", "Listen to your body"}',
 '{"Avoid extreme stretches", "Modify poses as needed", "Stay hydrated", "Check glucose if long session"}',
 '{"Use props for support", "Shorter holds for beginners", "Chair yoga variations"}',
 '{"Reduces stress and cortisol", "Improves flexibility", "Aids in glucose control", "Promotes relaxation"}',
 '{"Excellent stress management", "Low impact activity", "Supports overall wellness"}',
 2.5, 'gentle-yoga.jpg'),

('Tai Chi', 'flexibility', 'balance', 'beginner', '{}', '{"full_body", "balance"}',
 '{"Move slowly and deliberately", "Focus on breathing", "Maintain good posture", "Flow from one movement to next"}',
 '{"Start with basic movements", "Practice on non-slip surface", "Move within comfort range"}',
 '{"Seated variations available", "Shorter sessions for beginners", "Focus on breathing"}',
 '{"Improves balance and coordination", "Reduces stress", "Gentle on joints", "Improves circulation"}',
 '{"Low impact stress relief", "Good for balance and stability"}',
 2.0, 'tai-chi.jpg');

-- Now insert the specialized workout plans
INSERT INTO workout_plans (name, description, target_condition, fitness_level, duration_weeks, sessions_per_week, session_duration_minutes, equipment_needed, benefits, precautions, image_url) VALUES

-- TYPE 2 DIABETES PROGRAMS
('Type 2 Diabetes Beginner Program', 'A gentle introduction to exercise designed specifically for people with Type 2 diabetes. Focuses on improving insulin sensitivity and glucose control through low-impact activities.', 'type2_diabetes', 'beginner', 8, 3, 30, '{"comfortable_shoes", "water_bottle", "glucose_meter"}', 
 '{"Improves insulin sensitivity", "Lowers blood glucose levels", "Reduces cardiovascular risk", "Builds confidence in exercise", "Supports weight management"}',
 '{"Monitor blood glucose before and after exercise", "Carry fast-acting carbohydrates", "Stay hydrated", "Start slowly and progress gradually", "Consult healthcare provider"}',
 'type2-diabetes-beginner.jpg'),

('Type 2 Diabetes Intermediate Program', 'Progressive exercise program for people with Type 2 diabetes who have some exercise experience. Combines cardio and strength training for optimal glucose control.', 'type2_diabetes', 'intermediate', 12, 4, 45, '{"dumbbells", "resistance_bands", "yoga_mat", "glucose_meter"}',
 '{"Significant improvement in HbA1c", "Enhanced insulin sensitivity", "Weight loss support", "Improved cardiovascular health", "Better sleep quality"}',
 '{"Regular glucose monitoring", "Adjust medication timing if needed", "Proper warm-up and cool-down", "Monitor for signs of hypoglycemia"}',
 'type2-diabetes-intermediate.jpg'),

('Type 2 Diabetes Advanced Program', 'Comprehensive fitness program for experienced exercisers with Type 2 diabetes. Includes HIIT, strength training, and flexibility work for maximum health benefits.', 'type2_diabetes', 'advanced', 16, 5, 60, '{"full_gym_access", "heart_rate_monitor", "glucose_meter"}',
 '{"Optimal glucose control", "Significant weight loss", "Improved cardiovascular fitness", "Enhanced muscle mass", "Better insulin sensitivity"}',
 '{"Close glucose monitoring", "Coordinate with healthcare team", "Proper recovery between sessions", "Watch for overtraining"}',
 'type2-diabetes-advanced.jpg'),

-- GLP-1 USER PROGRAMS
('GLP-1 Beginner Fitness Program', 'Specially designed for people starting GLP-1 medications. Focuses on gentle movement to support weight loss goals while managing potential side effects.', 'glp1_users', 'beginner', 10, 3, 35, '{"comfortable_shoes", "water_bottle", "light_dumbbells"}',
 '{"Supports GLP-1 weight loss effects", "Improves energy levels", "Builds healthy habits", "Reduces nausea through gentle movement", "Enhances mood"}',
 '{"Exercise may help with nausea", "Stay hydrated", "Eat small snacks before exercise", "Listen to your body", "Start very gradually"}',
 'glp1-beginner.jpg'),

('GLP-1 Intermediate Program', 'Progressive fitness program for GLP-1 users ready to increase intensity. Combines cardio and strength training to maximize weight loss and health benefits.', 'glp1_users', 'intermediate', 12, 4, 50, '{"dumbbells", "resistance_bands", "cardio_equipment", "yoga_mat"}',
 '{"Accelerated weight loss", "Improved body composition", "Better cardiovascular health", "Enhanced energy levels", "Improved insulin sensitivity"}',
 '{"Monitor for dehydration", "Adjust intensity based on medication side effects", "Maintain adequate nutrition", "Regular progress tracking"}',
 'glp1-intermediate.jpg'),

('GLP-1 Advanced Program', 'High-intensity program for GLP-1 users who have established exercise habits. Designed to maximize weight loss and fitness gains while on GLP-1 therapy.', 'glp1_users', 'advanced', 16, 5, 65, '{"full_gym_access", "heart_rate_monitor", "various_equipment"}',
 '{"Maximum weight loss potential", "Excellent cardiovascular fitness", "Significant muscle preservation", "Optimal metabolic health", "Enhanced quality of life"}',
 '{"Monitor for rapid weight loss effects", "Ensure adequate protein intake", "Regular body composition assessments", "Coordinate with healthcare provider"}',
 'glp1-advanced.jpg'),

-- TYPE 1 DIABETES PROGRAMS
('Type 1 Diabetes Beginner Program', 'Carefully structured program for people with Type 1 diabetes new to exercise. Emphasizes glucose management strategies and safe exercise practices.', 'type1_diabetes', 'beginner', 8, 3, 30, '{"glucose_meter", "fast_acting_carbs", "comfortable_shoes", "water_bottle"}',
 '{"Improved glucose stability", "Better insulin sensitivity", "Enhanced cardiovascular health", "Increased confidence in exercise", "Better overall diabetes management"}',
 '{"Frequent glucose monitoring", "Always carry fast-acting carbs", "Exercise with others when possible", "Learn to adjust insulin for exercise", "Start with shorter sessions"}',
 'type1-diabetes-beginner.jpg'),

('Type 1 Diabetes Intermediate Program', 'Progressive program for Type 1 diabetics with exercise experience. Includes strategies for managing glucose during varied exercise intensities.', 'type1_diabetes', 'intermediate', 12, 4, 45, '{"glucose_meter", "continuous_glucose_monitor", "dumbbells", "cardio_equipment"}',
 '{"Improved time in range", "Better exercise glucose management", "Enhanced fitness levels", "Reduced diabetes complications risk", "Improved quality of life"}',
 '{"Use continuous glucose monitoring if available", "Develop exercise-specific insulin strategies", "Monitor for delayed hypoglycemia", "Maintain detailed exercise logs"}',
 'type1-diabetes-intermediate.jpg'),

('Type 1 Diabetes Athlete Program', 'High-performance program for competitive athletes with Type 1 diabetes. Advanced glucose management strategies for intense training.', 'type1_diabetes', 'athlete', 20, 6, 90, '{"continuous_glucose_monitor", "sports_nutrition", "full_gym_access", "heart_rate_monitor"}',
 '{"Elite athletic performance", "Optimal glucose control during competition", "Advanced diabetes management skills", "Peak physical condition", "Competitive advantage"}',
 '{"Work closely with diabetes team", "Advanced glucose monitoring", "Sophisticated insulin strategies", "Regular performance assessments", "Specialized nutrition planning"}',
 'type1-diabetes-athlete.jpg');

-- Insert sample workout sessions for the Type 2 Diabetes Beginner Program
INSERT INTO workout_sessions (workout_plan_id, session_number, week_number, day_number, name, description, total_duration, intensity_level, focus_areas) VALUES
((SELECT id FROM workout_plans WHERE name = 'Type 2 Diabetes Beginner Program'), 1, 1, 1, 'Gentle Introduction', 'Your first workout focusing on gentle movement and glucose monitoring', 30, 'low', '{"cardio", "flexibility"}'),
((SELECT id FROM workout_plans WHERE name = 'Type 2 Diabetes Beginner Program'), 2, 1, 3, 'Building Confidence', 'Second session to build confidence and establish routine', 30, 'low', '{"cardio", "strength"}'),
((SELECT id FROM workout_plans WHERE name = 'Type 2 Diabetes Beginner Program'), 3, 1, 5, 'Week 1 Progress', 'End of week 1 - celebrating progress and building momentum', 30, 'low', '{"cardio", "flexibility"}');

-- Insert session exercises for the first session
INSERT INTO session_exercises (workout_session_id, exercise_id, order_in_session, duration_seconds, rest_seconds, notes) VALUES
((SELECT id FROM workout_sessions WHERE name = 'Gentle Introduction'), (SELECT id FROM exercise_library WHERE name = 'Gentle Walking'), 1, 600, 60, 'Start with comfortable pace, monitor how you feel'),
((SELECT id FROM workout_sessions WHERE name = 'Gentle Introduction'), (SELECT id FROM exercise_library WHERE name = 'Chair Exercises'), 2, 300, 60, 'Seated exercises for upper body movement'),
((SELECT id FROM workout_sessions WHERE name = 'Gentle Introduction'), (SELECT id FROM exercise_library WHERE name = 'Gentle Yoga Flow'), 3, 600, 0, 'Cool down with gentle stretching');

-- Insert workout achievements
INSERT INTO workout_achievements (name, description, icon, category, condition_type, criteria, reward_points) VALUES
('First Steps', 'Complete your first workout session', 'figure.walk', 'milestone', 'general', '{"sessions_completed": 1}', 10),
('Consistency Champion', 'Complete 7 workout sessions', 'calendar.badge.checkmark', 'consistency', 'general', '{"sessions_completed": 7}', 25),
('Glucose Guardian', 'Monitor glucose before and after 10 workouts', 'heart.text.square', 'special', 'type2_diabetes', '{"glucose_monitored_sessions": 10}', 30),
('GLP-1 Warrior', 'Complete 30 days of consistent exercise on GLP-1', 'bolt.heart', 'consistency', 'glp1_users', '{"consecutive_days": 30}', 50),
('T1D Champion', 'Successfully manage glucose during 20 workouts', 'star.circle', 'special', 'type1_diabetes', '{"successful_glucose_management": 20}', 40);