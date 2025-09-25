import Foundation

struct User: Codable {
    let id: UUID
    let email: String
    let name: String
    
    init(email: String, name: String) {
        self.id = UUID()
        self.email = email
        self.name = name
    }
}