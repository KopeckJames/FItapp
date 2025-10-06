# NaN/Infinity Conversion Crash Fix

## Issue
The app was crashing with a fatal error:
```
Fatal error: Double value cannot be converted to Int because it is either infinite or NaN
Swift/arm64-apple-ios-simulator.swiftinterface:36631
```

## Root Cause
The crash was occurring when trying to convert Double values to Int in calorie calculations. Two locations were problematic:

### 1. WorkoutSession.estimatedCalories (EnhancedWorkoutModels.swift)
```swift
var estimatedCalories: Int {
    let baseCalories = totalDuration * 5
    let intensityMultiplier: Double = { /* ... */ }()
    return Int(Double(baseCalories) * intensityMultiplier) // ❌ Crash if result is NaN/Infinity
}
```

### 2. ExerciseCompletionView.estimatedCalories
```swift
private var estimatedCalories: Int {
    let minutes = Double(duration) / 60.0
    return Int(exercise.caloriesPerMinute * minutes) // ❌ Crash if result is NaN/Infinity
}
```

## When NaN/Infinity Can Occur

### Potential Causes:
1. **Invalid Input Data**: 
   - `totalDuration` could be extremely large
   - `exercise.caloriesPerMinute` could be NaN or infinity
   - `duration` could be invalid

2. **Mathematical Operations**:
   - Division by zero (though not directly present here)
   - Multiplication overflow
   - Invalid floating-point operations

3. **Data Corruption**:
   - Core Data or Supabase returning corrupted numeric values
   - JSON parsing errors resulting in invalid numbers

## Solution Applied

### Safe Conversion Pattern:
```swift
let result = /* calculation */

// Safe conversion to Int, handling NaN and infinity
if result.isNaN || result.isInfinite {
    return 0 // Safe fallback
}
return Int(result.clamped(to: reasonableRange))
```

### Fixed WorkoutSession.estimatedCalories:
```swift
var estimatedCalories: Int {
    let baseCalories = totalDuration * 5
    let intensityMultiplier: Double = { /* ... */ }()
    let result = Double(baseCalories) * intensityMultiplier
    
    // Safe conversion to Int, handling NaN and infinity
    if result.isNaN || result.isInfinite {
        return 0
    }
    return Int(result.clamped(to: 0...10000)) // Reasonable calorie range
}
```

### Fixed ExerciseCompletionView.estimatedCalories:
```swift
private var estimatedCalories: Int {
    let minutes = Double(duration) / 60.0
    let result = exercise.caloriesPerMinute * minutes
    
    // Safe conversion to Int, handling NaN and infinity
    if result.isNaN || result.isInfinite {
        return 0
    }
    return Int(result.clamped(to: 0...2000)) // Reasonable calorie range for single exercise
}
```

### Added Double Extension:
```swift
extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
```

## Benefits of the Fix

1. **Crash Prevention**: App no longer crashes on invalid Double values
2. **Graceful Fallback**: Returns 0 calories when calculations fail
3. **Range Validation**: Clamps results to reasonable calorie ranges
4. **Data Integrity**: Prevents display of impossible calorie values
5. **User Experience**: Users see consistent, reasonable calorie estimates

## Reasonable Calorie Ranges

### Workout Sessions (0-10,000 calories):
- Typical 30-minute workout: 150-400 calories
- Intense 90-minute workout: 800-1,200 calories
- Extreme cases capped at 10,000 calories

### Individual Exercises (0-2,000 calories):
- Light 10-minute exercise: 50-100 calories
- Intense 60-minute exercise: 400-800 calories
- Extreme cases capped at 2,000 calories

## Files Modified

1. **FitnessIos/FitnessIos/Models/EnhancedWorkoutModels.swift**
   - Fixed `WorkoutSession.estimatedCalories` calculation
   - Added `Double.clamped(to:)` extension

2. **FitnessIos/FitnessIos/Views/ExerciseCompletionView.swift**
   - Fixed `estimatedCalories` calculation

## Testing

The fix ensures:
- ✅ No crashes when calorie calculations result in NaN/Infinity
- ✅ Reasonable calorie estimates are always displayed
- ✅ Invalid data doesn't break the user interface
- ✅ Workout and exercise completion flows work reliably
- ✅ All mathematical operations are safe

## Prevention Strategies

To prevent similar issues in the future:

1. **Input Validation**: Validate numeric inputs before calculations
2. **Safe Math Functions**: Always check for NaN/Infinity before Int conversion
3. **Range Checking**: Use reasonable bounds for all calculated values
4. **Data Sanitization**: Clean data from external sources (Core Data, Supabase)
5. **Unit Testing**: Test edge cases with extreme or invalid values

The workout system is now mathematically robust and handles edge cases gracefully! 🧮✅