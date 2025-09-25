import SwiftUI

struct MedicationTrackerView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Medication Tracker")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Coming Soon")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Medications")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    MedicationTrackerView()
}