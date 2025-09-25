import SwiftUI

struct AddMedicationView: View {
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var selectedFrequency = MedicationFrequency.onceDaily
    @State private var selectedType = MedicationType.other
    @State private var prescribedBy = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var instructions = ""
    @State private var sideEffects: [String] = []
    @State private var newSideEffect = ""
    @State private var reminderEnabled = true
    @State private var reminderTimes: [Date] = []
    @State private var selectedColor = MedicationColor.blue
    @State private var selectedShape = MedicationShape.round
    
    @State private var showingTimePicker = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic Information Section
                        basicInformationSection
                        
                        // Dosage and Frequency Section
                        dosageAndFrequencySection
                        
                        // Reminders Section
                        remindersSection
                        
                        // Appearance Section
                        appearanceSection
                        
                        // Additional Information Section
                        additionalInformationSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveMedication()
                        }
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .disabled(medicationName.isEmpty || dosage.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            setupDefaultReminderTimes()
        }
        .onChange(of: selectedFrequency) { _ in
            setupDefaultReminderTimes()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(reminderTimes: $reminderTimes)
        }
    }
    
    // MARK: - Basic Information Section
    
    private var basicInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                FormField(title: "Medication Name", isRequired: true) {
                    TextField("Enter medication name", text: $medicationName)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                FormField(title: "Dosage", isRequired: true) {
                    TextField("e.g., 500mg, 1 tablet", text: $dosage)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                FormField(title: "Type") {
                    Picker("Medication Type", selection: $selectedType) {
                        ForEach(MedicationType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.white)
                }
                
                FormField(title: "Prescribed By") {
                    TextField("Doctor's name (optional)", text: $prescribedBy)
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Dosage and Frequency Section
    
    private var dosageAndFrequencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Schedule", icon: "clock.fill")
            
            VStack(spacing: 12) {
                FormField(title: "Frequency") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                            HStack {
                                Image(systemName: frequency.icon)
                                Text(frequency.rawValue)
                            }
                            .tag(frequency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.white)
                }
                
                FormField(title: "Start Date") {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Has End Date", isOn: $hasEndDate)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                        .foregroundColor(.white)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Reminders Section
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Reminders", icon: "bell.fill")
            
            VStack(spacing: 12) {
                Toggle("Enable Reminders", isOn: $reminderEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                    .foregroundColor(.white)
                
                if reminderEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Reminder Times")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Customize") {
                                showingTimePicker = true
                            }
                            .font(.caption)
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(reminderTimes.indices, id: \.self) { index in
                                Text(reminderTimes[index], style: .time)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Appearance", icon: "paintbrush.fill")
            
            VStack(spacing: 12) {
                FormField(title: "Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(MedicationColor.allCases, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedColor)
                            }
                        }
                    }
                }
                
                FormField(title: "Shape") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(MedicationShape.allCases, id: \.self) { shape in
                            Button(action: { selectedShape = shape }) {
                                Image(systemName: shape.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedShape == shape ? Color(red: 0.7, green: 0.9, blue: 0.3) : .gray)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedShape == shape ? Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.2) : Color.clear)
                                    )
                                    .scaleEffect(selectedShape == shape ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedShape)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Additional Information Section
    
    private var additionalInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Additional Information", icon: "doc.text.fill")
            
            VStack(spacing: 12) {
                FormField(title: "Instructions") {
                    TextField("Special instructions (optional)", text: $instructions, axis: .vertical)
                        .textFieldStyle(CustomTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Side Effects")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("Add side effect", text: $newSideEffect)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Button("Add") {
                            if !newSideEffect.isEmpty {
                                sideEffects.append(newSideEffect)
                                newSideEffect = ""
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .disabled(newSideEffect.isEmpty)
                    }
                    
                    if !sideEffects.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(sideEffects.indices, id: \.self) { index in
                                HStack {
                                    Text(sideEffects[index])
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: { sideEffects.remove(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaultReminderTimes() {
        reminderTimes = selectedFrequency.defaultTimes
    }
    
    private func saveMedication() async {
        guard !medicationName.isEmpty && !dosage.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        isLoading = true
        
        do {
            let medication = Medication(
                name: medicationName,
                dosage: dosage,
                frequency: selectedFrequency,
                medicationType: selectedType,
                prescribedBy: prescribedBy.isEmpty ? nil : prescribedBy,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                instructions: instructions.isEmpty ? nil : instructions,
                sideEffects: sideEffects,
                isActive: true,
                reminderEnabled: reminderEnabled,
                reminderTimes: reminderTimes,
                color: selectedColor,
                shape: selectedShape
            )
            
            try await medicationService.addMedication(medication)
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct FormField<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: Content
    
    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            content
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Time Picker View

struct TimePickerView: View {
    @Binding var reminderTimes: [Date]
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Add new time
                    VStack(spacing: 12) {
                        Text("Add Reminder Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker("Time", selection: $newTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .colorScheme(.dark)
                        
                        Button("Add Time") {
                            if !reminderTimes.contains(where: { Calendar.current.isDate($0, equalTo: newTime, toGranularity: .minute) }) {
                                reminderTimes.append(newTime)
                                reminderTimes.sort { $0 < $1 }
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Current times
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Reminder Times")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if reminderTimes.isEmpty {
                            Text("No reminder times set")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(reminderTimes.indices, id: \.self) { index in
                                HStack {
                                    Text(reminderTimes[index], style: .time)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        reminderTimes.remove(at: index)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reminder Times")
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
}

#Preview {
    AddMedicationView(medicationService: MedicationService())
        .preferredColorScheme(.dark)
}