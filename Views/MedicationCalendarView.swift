import SwiftUI

struct MedicationCalendarView: View {
    @ObservedObject var medicationService: MedicationService
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDayDetail = false
    @State private var selectedCalendarDay: MedicationCalendarDay?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Month navigation header
                monthNavigationHeader
                
                // Calendar grid
                calendarGrid
                
                // Selected day details
                if let selectedDay = selectedCalendarDay {
                    selectedDayDetails(selectedDay)
                } else {
                    Spacer()
                }
            }
        }
        .onAppear {
            updateSelectedDay()
        }
        .onChange(of: selectedDate) { _ in
            updateSelectedDay()
        }
        .sheet(isPresented: $showingDayDetail) {
            if let selectedDay = selectedCalendarDay {
                DayDetailView(
                    calendarDay: selectedDay,
                    medicationService: medicationService
                )
            }
        }
    }
    
    // MARK: - Month Navigation Header
    
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Color.gray.opacity(0.1))
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(calendarDays, id: \.id) { day in
                    CalendarDayView(
                        day: day,
                        isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(day.date, inSameDayAs: Date()),
                        isCurrentMonth: calendar.isDate(day.date, equalTo: currentMonth, toGranularity: .month)
                    ) {
                        selectedDate = day.date
                        selectedCalendarDay = day
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
        }
    }
    
    // MARK: - Selected Day Details
    
    private func selectedDayDetails(_ day: MedicationCalendarDay) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.date, style: .date)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(day.completedDoses)/\(day.totalDoses) doses completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button("View Details") {
                    showingDayDetail = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Adherence progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(adherenceColor(day.adherenceScore))
                        .frame(width: geometry.size.width * day.adherenceScore, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.3), value: day.adherenceScore)
                }
            }
            .frame(height: 6)
            
            // Quick dose summary
            if !day.doses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(day.doses.prefix(5)) { dose in
                            MiniDoseCard(
                                dose: dose,
                                medication: getMedication(for: dose.medicationId)
                            )
                        }
                        
                        if day.doses.count > 5 {
                            Text("+\(day.doses.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12, corners: [.topLeft, .topRight])
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private var calendarDays: [MedicationCalendarDay] {
        medicationService.getCalendarDays(for: currentMonth)
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func updateSelectedDay() {
        selectedCalendarDay = calendarDays.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private func getMedication(for id: UUID) -> Medication? {
        medicationService.medications.first { $0.id == id }
    }
    
    private func adherenceColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.3..<0.6:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let day: MedicationCalendarDay
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day.date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Adherence indicator dots
                HStack(spacing: 2) {
                    ForEach(0..<min(day.totalDoses, 4), id: \.self) { index in
                        Circle()
                            .fill(index < day.completedDoses ? .green : .gray.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                    
                    if day.totalDoses > 4 {
                        Text("...")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 8)
            }
            .frame(width: 40, height: 50)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.5)
        } else if isToday {
            return Color(red: 0.7, green: 0.9, blue: 0.3)
        } else if isSelected {
            return .white
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.3)
        } else if isToday {
            return Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color(red: 0.7, green: 0.9, blue: 0.3)
        } else if isToday {
            return Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 0
    }
}

// MARK: - Mini Dose Card

struct MiniDoseCard: View {
    let dose: MedicationDose
    let medication: Medication?
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(medication?.color.color ?? .gray)
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: dose.status.icon)
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                )
            
            Text(dose.scheduledTime, style: .time)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Day Detail View

struct DayDetailView: View {
    let calendarDay: MedicationCalendarDay
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Day summary
                        VStack(spacing: 12) {
                            Text(calendarDay.date, style: .date)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                StatItem(
                                    icon: "checkmark.circle.fill",
                                    value: "\(calendarDay.completedDoses)",
                                    label: "Completed",
                                    color: .green
                                )
                                
                                StatItem(
                                    icon: "pills.fill",
                                    value: "\(calendarDay.totalDoses)",
                                    label: "Total",
                                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                                )
                                
                                StatItem(
                                    icon: "percent",
                                    value: "\(Int(calendarDay.adherenceScore * 100))%",
                                    label: "Adherence",
                                    color: adherenceColor(calendarDay.adherenceScore)
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                        
                        // Doses list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Doses")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(calendarDay.doses.sorted { $0.scheduledTime < $1.scheduledTime }) { dose in
                                DoseCard(
                                    dose: dose,
                                    medication: getMedication(for: dose.medicationId),
                                    isOverdue: false
                                ) {
                                    // Handle dose tap
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
        }
    }
    
    private func getMedication(for id: UUID) -> Medication? {
        medicationService.medications.first { $0.id == id }
    }
    
    private func adherenceColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.3..<0.6:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MedicationCalendarView(medicationService: MedicationService())
        .preferredColorScheme(.dark)
}