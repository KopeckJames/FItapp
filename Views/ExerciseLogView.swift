import SwiftUI

struct ExerciseLogView: View {
    @State private var selectedExerciseType = "Walking"
    @State private var duration = ""
    @State private var intensity = "Moderate"
    @State private var notes = ""
    @State private var exerciseDate = Date()
    @State private var exercises: [Exercise] = []
    
    let exerciseTypes = ["Walking", "Running", "Cycling", "Swimming", "Strength Training", "Yoga", "Dancing", "Other"]
    let intensityLevels = ["Light", "Moderate", "Vigorous"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise logging section
                        VStack(spacing: 15) {
                            Text("Log Exercise")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Exercise Type")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("Exercise Type", selection: $selectedExerciseType) {
                                        ForEach(exerciseTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .colorScheme(.dark)
                                }
                                
                                HStack {
                                    Text("Duration (minutes)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    TextField("Minutes", text: $duration)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 100)
                                }
                                
                                HStack {
                                    Text("Intensity")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("Intensity", selection: $intensity) {
                                        ForEach(intensityLevels, id: \.self) { level in
                                            Text(level).tag(level)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .colorScheme(.dark)
                                }
                                
                                HStack {
                                    Text("Date")
                                        .foregroundColor(.white)
                                    Spacer()
                                    DatePicker("", selection: $exerciseDate, displayedComponents: [.date])
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes (Optional)")
                                        .foregroundColor(.white)
                                    TextField("How did you feel? Any observations...", text: $notes, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(3...6)
                                }
                            }
                            
                            Button(action: logExercise) {
                                Text("Log Exercise")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Weekly summary
                        VStack(spacing: 15) {
                            Text("This Week's Activity")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                WeeklySummaryCard(
                                    title: "Total Minutes",
                                    value: "\(calculateWeeklyMinutes())",
                                    icon: "clock.fill"
                                )
                                
                                WeeklySummaryCard(
                                    title: "Sessions",
                                    value: "\(calculateWeeklySessions())",
                                    icon: "figure.walk"
                                )
                            }
                        }
                        
                        // Recent exercises
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Exercises")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if exercises.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.gray.opacity(0.6))
                                    Text("No exercises logged yet")
                                        .foregroundColor(Color.gray.opacity(0.8))
                                    Text("Start by logging your first exercise above")
                                        .font(.caption)
                                        .foregroundColor(Color.gray.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                            } else {
                                ForEach(exercises.reversed()) { exercise in
                                    ExerciseCard(exercise: exercise)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercise Log")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func logExercise() {
        guard let durationInt = Int(duration), durationInt > 0 else { return }
        
        let exercise = Exercise(
            type: selectedExerciseType,
            duration: durationInt,
            intensity: intensity,
            date: exerciseDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        exercises.append(exercise)
        
        // Reset form
        duration = ""
        notes = ""
        exerciseDate = Date()
    }
    
    private func calculateWeeklyMinutes() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return exercises
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.duration }
    }
    
    private func calculateWeeklySessions() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return exercises
            .filter { $0.date >= weekAgo }
            .count
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let type: String
    let duration: Int
    let intensity: String
    let date: Date
    let notes: String?
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.type)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(exercise.duration) min")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                
                HStack {
                    Text(exercise.intensity)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(intensityColor(exercise.intensity).opacity(0.2))
                        .foregroundColor(intensityColor(exercise.intensity))
                        .cornerRadius(8)
                    
                    Text(exercise.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(Color.gray.opacity(0.8))
                }
                
                if let notes = exercise.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: exerciseIcon(exercise.type))
                .font(.title2)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func intensityColor(_ intensity: String) -> Color {
        switch intensity {
        case "Light":
            return .blue
        case "Moderate":
            return Color(red: 0.7, green: 0.9, blue: 0.3)
        case "Vigorous":
            return .red
        default:
            return .gray
        }
    }
    
    private func exerciseIcon(_ type: String) -> String {
        switch type {
        case "Walking":
            return "figure.walk"
        case "Running":
            return "figure.run"
        case "Cycling":
            return "bicycle"
        case "Swimming":
            return "figure.pool.swim"
        case "Strength Training":
            return "dumbbell.fill"
        case "Yoga":
            return "figure.yoga"
        case "Dancing":
            return "music.note"
        default:
            return "figure.mixed.cardio"
        }
    }
}

struct WeeklySummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.8))
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ExerciseLogView()
}