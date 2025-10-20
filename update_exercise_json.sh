#!/bin/bash

# Script to update JSON files to reference renamed images

cd "FitnessIos/FitnessIos/Images/exercises"

for json_file in *.json; do
    if [ -f "$json_file" ]; then
        exercise_name=$(basename "$json_file" .json)
        
        # Update the JSON to reference the renamed images
        sed -i '' "s|\"${exercise_name}/0.jpg\"|\"${exercise_name}/${exercise_name}_0.jpg\"|g" "$json_file"
        sed -i '' "s|\"${exercise_name}/1.jpg\"|\"${exercise_name}/${exercise_name}_1.jpg\"|g" "$json_file"
        
        echo "Updated $json_file"
    fi
done

echo "JSON file updates complete!"