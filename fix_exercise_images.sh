#!/bin/bash

# Script to rename exercise images to avoid conflicts
# This script renames 0.jpg and 1.jpg to use the parent directory name

cd "FitnessIos/FitnessIos/Images/exercises"

for dir in */; do
    if [ -d "$dir" ]; then
        exercise_name=$(basename "$dir")
        
        # Rename 0.jpg to {exercise_name}_0.jpg
        if [ -f "$dir/0.jpg" ]; then
            mv "$dir/0.jpg" "$dir/${exercise_name}_0.jpg"
            echo "Renamed $dir/0.jpg to $dir/${exercise_name}_0.jpg"
        fi
        
        # Rename 1.jpg to {exercise_name}_1.jpg
        if [ -f "$dir/1.jpg" ]; then
            mv "$dir/1.jpg" "$dir/${exercise_name}_1.jpg"
            echo "Renamed $dir/1.jpg to $dir/${exercise_name}_1.jpg"
        fi
    fi
done

echo "Exercise image renaming complete!"