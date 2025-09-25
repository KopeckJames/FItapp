import SwiftUI

struct ExerciseView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Exercise Tracking")
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
            .navigationTitle("Exercise")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ExerciseView()
}