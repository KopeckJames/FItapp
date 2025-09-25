import SwiftUI
import Charts

struct AdherenceReportView: View {
    @ObservedObject var medicationService: MedicationService
    @State private var selectedPeriod = AdherencePeriod.month
    @State private var selectedMedication: Medication?
    @State private var showingAllMedications = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Period and medication selector
                    selectionControls
                    
                    // Overall adherence summary
                    overallAdherenceSummary
                    
                    // Adherence chart
                    adherenceChart
                    
                    // Medication-specific reports
                    medicationReports
                    
                    // Insights and recommendations
                    insightsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Selection Controls
    
    private var selectionControls: some View {
        VStack(spacing: 12) {
            // Period selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Period")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AdherencePeriod.allCases, id: \.self) { period in
                        HStack {
                            Image(systemName: period.icon)
                            Text(period.rawValue)
                        }
                        .tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorScheme(.dark)
            }
            
            // Medication selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Medication")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                HStack {
                    Button(action: { 
                        showingAllMedications = true
                        selectedMedication = nil
                    }) {
                        Text("All Medications")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(showingAllMedications ? Color(red: 0.7, green: 0.9, blue: 0.3) : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(medicationService.medications.filter { $0.isActive }) { medication in
                                Button(action: {
                                    showingAllMedications = false
                                    selectedMedication = medication
                                }) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(medication.color.color)
                                            .frame(width: 12, height: 12)
                                        
                                        Text(medication.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedMedication?.id == medication.id ? Color(red: 0.7, green: 0.9, blue: 0.3) : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Overall Adherence Summary
    
    private var overallAdherenceSummary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Adherence Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(selectedPeriod.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Main adherence percentage
            VStack(spacing: 8) {
                Text("\(Int(overallAdherence))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(adherenceColor(overallAdherence))
                
                Text("Overall Adherence")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: overallAdherence / 100)
                    .stroke(adherenceColor(overallAdherence), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: overallAdherence)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(totalTakenDoses)",
                    label: "Taken",
                    color: .green
                )
                
                StatItem(
                    icon: "xmark.circle.fill",
                    value: "\(totalSkippedDoses)",
                    label: "Missed",
                    color: .red
                )
                
                StatItem(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Streak",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Adherence Chart
    
    private var adherenceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Adherence Trend")
                .font(.headline)
                .foregroundColor(.white)
            
            if #available(iOS 16.0, *) {
                Chart(chartData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Adherence", dataPoint.adherence)
                    )
                    .foregroundStyle(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Adherence", dataPoint.adherence)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray)
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray)
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                // Fallback for iOS 15 and earlier
                Text("Chart requires iOS 16+")
                    .foregroundColor(.gray)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Medication Reports
    
    private var medicationReports: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication Details")
                .font(.headline)
                .foregroundColor(.white)
            
            if showingAllMedications {
                ForEach(medicationService.medications.filter { $0.isActive }) { medication in
                    MedicationAdherenceCard(
                        medication: medication,
                        report: medicationService.getAdherenceReport(for: medication.id, period: selectedPeriod)
                    )
                }
            } else if let selectedMedication = selectedMedication {
                MedicationAdherenceCard(
                    medication: selectedMedication,
                    report: medicationService.getAdherenceReport(for: selectedMedication.id, period: selectedPeriod)
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(insights, id: \.title) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var overallAdherence: Double {
        medicationService.getOverallAdherence(for: selectedPeriod)
    }
    
    private var totalTakenDoses: Int {
        // Calculate from medication service
        return 0 // Placeholder
    }
    
    private var totalSkippedDoses: Int {
        // Calculate from medication service
        return 0 // Placeholder
    }
    
    private var currentStreak: Int {
        // Calculate current streak
        return 0 // Placeholder
    }
    
    private var chartData: [AdherenceDataPoint] {
        // Generate chart data based on selected period
        let calendar = Calendar.current
        let now = Date()
        var data: [AdherenceDataPoint] = []
        
        let days = selectedPeriod == .week ? 7 : (selectedPeriod == .month ? 30 : 90)
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let adherence = Double.random(in: 70...100) // Placeholder data
                data.append(AdherenceDataPoint(date: date, adherence: adherence))
            }
        }
        
        return data.reversed()
    }
    
    private var insights: [AdherenceInsight] {
        var insights: [AdherenceInsight] = []
        
        if overallAdherence >= 90 {
            insights.append(AdherenceInsight(
                title: "Excellent Adherence!",
                description: "You're doing great with your medication routine. Keep it up!",
                type: .positive,
                icon: "star.fill"
            ))
        } else if overallAdherence >= 70 {
            insights.append(AdherenceInsight(
                title: "Good Progress",
                description: "Your adherence is good, but there's room for improvement. Consider setting more reminders.",
                type: .neutral,
                icon: "lightbulb.fill"
            ))
        } else {
            insights.append(AdherenceInsight(
                title: "Needs Attention",
                description: "Your adherence could be better. Try adjusting your reminder times or speak with your doctor.",
                type: .warning,
                icon: "exclamationmark.triangle.fill"
            ))
        }
        
        return insights
    }
    
    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 30..<60:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Supporting Views and Models

struct AdherenceDataPoint {
    let date: Date
    let adherence: Double
}

struct AdherenceInsight {
    let title: String
    let description: String
    let type: InsightType
    let icon: String
    
    enum InsightType {
        case positive, neutral, warning
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .blue
            case .warning: return .orange
            }
        }
    }
}

struct MedicationAdherenceCard: View {
    let medication: Medication
    let report: AdherenceReport
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(medication.color.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: medication.medicationType.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(medication.dosage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(report.adherencePercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(adherenceColor(report.adherencePercentage))
                    
                    Text("Adherence")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(report.takenDoses)")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Taken")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(report.skippedDoses)")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Missed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(report.streak)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(report.longestStreak)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 30..<60: return .orange
        default: return .red
        }
    }
}

struct InsightCard: View {
    let insight: AdherenceInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(insight.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(insight.type.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    AdherenceReportView(medicationService: MedicationService())
        .preferredColorScheme(.dark)
}