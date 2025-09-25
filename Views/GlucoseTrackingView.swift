import SwiftUI

struct GlucoseTrackingView: View {
    @State private var glucoseLevel = ""
    @State private var selectedTime = Date()
    @State private var notes = ""
    @State private var glucoseReadings: [GlucoseReading] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        glucoseInputSection
                        recentReadingsSection
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Glucose Tracking")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var glucoseInputSection: some View {
        VStack(spacing: 15) {
            Text("Log Glucose Reading")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                glucoseLevelInput
                timeInput
                notesInput
            }
            
            logReadingButton
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var glucoseLevelInput: some View {
        HStack {
            Text("Glucose Level")
                .foregroundColor(.white)
            Spacer()
            TextField("mg/dL", text: $glucoseLevel)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
        }
    }
    
    private var timeInput: some View {
        HStack {
            Text("Time")
                .foregroundColor(.white)
            Spacer()
            DatePicker("", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .colorScheme(.dark)
        }
    }
    
    private var notesInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .foregroundColor(.white)
            TextField("Add notes about your reading...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var logReadingButton: some View {
        Button(action: addGlucoseReading) {
            Text("Log Reading")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Readings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if glucoseReadings.isEmpty {
                emptyReadingsView
            } else {
                ForEach(glucoseReadings.reversed()) { reading in
                    GlucoseReadingCard(reading: reading)
                }
            }
        }
    }
    
    private var emptyReadingsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(Color.gray.opacity(0.6))
            Text("No readings yet")
                .foregroundColor(Color.gray.opacity(0.8))
            Text("Add your first glucose reading above")
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private func addGlucoseReading() {
        guard let level = Int(glucoseLevel), level > 0 else { return }
        
        let reading = GlucoseReading(
            level: level,
            timestamp: selectedTime,
            notes: notes.isEmpty ? nil : notes
        )
        
        glucoseReadings.append(reading)
        
        // Reset form
        glucoseLevel = ""
        selectedTime = Date()
        notes = ""
    }
}

struct GlucoseReadingCard: View {
    let reading: GlucoseReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(reading.level) mg/dL")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(reading.status.text)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(reading.status.color.opacity(0.2))
                        .foregroundColor(reading.status.color)
                        .cornerRadius(8)
                }
                
                Text(reading.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.8))
                
                if let notes = reading.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(reading.status.color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Models
// GlucoseReading and GlucoseStatus are defined in GlucoseModels.swift

#Preview {
    GlucoseTrackingView()
}