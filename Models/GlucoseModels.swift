import Foundation
import SwiftUI

// MARK: - Glucose Tracking Models

struct GlucoseReading: Identifiable, Codable {
    let id: UUID
    let level: Int
    let timestamp: Date
    let notes: String?
    
    init(level: Int, timestamp: Date, notes: String? = nil) {
        self.id = UUID()
        self.level = level
        self.timestamp = timestamp
        self.notes = notes
    }
    
    var status: GlucoseStatus {
        switch level {
        case 0..<70:
            return .low
        case 70...180:
            return .normal
        default:
            return .high
        }
    }
}

enum GlucoseStatus: String, CaseIterable, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .normal:
            return Color(red: 0.7, green: 0.9, blue: 0.3)
        case .high:
            return .red
        }
    }
    
    var text: String {
        return self.rawValue
    }
}

// MARK: - Glucose Analytics Models

struct GlucoseTrend: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let averageLevel: Double
    let readings: [GlucoseReading]
    let trend: TrendDirection
    let variability: Double
    let timeInRange: TimeInRange
    
    init(startDate: Date, endDate: Date, averageLevel: Double, readings: [GlucoseReading], trend: TrendDirection, variability: Double, timeInRange: TimeInRange) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.averageLevel = averageLevel
        self.readings = readings
        self.trend = trend
        self.variability = variability
        self.timeInRange = timeInRange
    }
}

enum TrendDirection: String, CaseIterable, Codable {
    case rising = "Rising"
    case stable = "Stable"
    case falling = "Falling"
    
    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .rising: return .red
        case .stable: return .green
        case .falling: return .blue
        }
    }
}

// TimeInRange and GlucosePattern are defined in AnalyticsEngine.swift

enum TimeOfDay: String, CaseIterable, Codable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
    
    var timeRange: ClosedRange<Int> {
        switch self {
        case .morning: return 6...11
        case .afternoon: return 12...17
        case .evening: return 18...21
        case .night: return 22...5
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .afternoon: return "sun.min.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }
}

// MARK: - Glucose Alerts

struct GlucoseAlert: Identifiable, Codable {
    let id: UUID
    let type: AlertType
    let level: Int
    let timestamp: Date
    let acknowledged: Bool
    let notes: String?
    
    init(type: AlertType, level: Int, timestamp: Date = Date(), acknowledged: Bool = false, notes: String? = nil) {
        self.id = UUID()
        self.type = type
        self.level = level
        self.timestamp = timestamp
        self.acknowledged = acknowledged
        self.notes = notes
    }
    
    enum AlertType: String, CaseIterable, Codable {
        case low = "Low Glucose"
        case high = "High Glucose"
        case rapidRise = "Rapid Rise"
        case rapidFall = "Rapid Fall"
        
        var severity: AlertSeverity {
            switch self {
            case .low, .high: return .high
            case .rapidRise, .rapidFall: return .medium
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .high: return .red
            case .rapidRise: return .orange
            case .rapidFall: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .high: return "arrow.up.circle.fill"
            case .rapidRise: return "arrow.up.right.circle.fill"
            case .rapidFall: return "arrow.down.right.circle.fill"
            }
        }
    }
    
    enum AlertSeverity: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
}