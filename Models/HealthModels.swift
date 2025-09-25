import Foundation
import SwiftUI

// MARK: - Health Metrics Models

struct HealthMetric: Identifiable, Codable {
    let id: UUID
    let type: String
    let value: Double
    let unit: String
    let timestamp: Date
    
    var title: String {
        switch type {
        case "heart_rate": return "Heart Rate"
        case "systolic_bp": return "Systolic BP"
        case "diastolic_bp": return "Diastolic BP"
        case "weight": return "Weight"
        case "temperature": return "Temperature"
        default: return type.capitalized
        }
    }
    
    var displayValue: String {
        switch type {
        case "heart_rate": return "\(Int(value)) bpm"
        case "systolic_bp", "diastolic_bp": return "\(Int(value)) mmHg"
        case "weight": return "\(String(format: "%.1f", value)) lbs"
        case "temperature": return "\(String(format: "%.1f", value))°F"
        default: return "\(value) \(unit)"
        }
    }
    
    var icon: String {
        switch type {
        case "heart_rate": return "heart.fill"
        case "systolic_bp", "diastolic_bp": return "drop.fill"
        case "weight": return "scalemass.fill"
        case "temperature": return "thermometer"
        default: return "chart.bar.fill"
        }
    }
    
    var color: Color {
        switch type {
        case "heart_rate": return .red
        case "systolic_bp", "diastolic_bp": return .blue
        case "weight": return .green
        case "temperature": return .orange
        default: return .gray
        }
    }
    
    init(from entity: HealthMetricEntity) {
        self.id = UUID()
        self.type = entity.type ?? ""
        self.value = entity.value
        self.unit = entity.unit ?? ""
        self.timestamp = entity.timestamp ?? Date()
    }
    
    init(type: String, value: Double, unit: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}

// MARK: - Health Trends and Analytics

struct HealthTrend: Identifiable, Codable {
    let id: UUID
    let metricType: String
    let startDate: Date
    let endDate: Date
    let values: [HealthMetric]
    let trend: HealthTrendDirection
    let averageValue: Double
    let changePercentage: Double
    
    init(metricType: String, startDate: Date, endDate: Date, values: [HealthMetric], trend: HealthTrendDirection, averageValue: Double, changePercentage: Double) {
        self.id = UUID()
        self.metricType = metricType
        self.startDate = startDate
        self.endDate = endDate
        self.values = values
        self.trend = trend
        self.averageValue = averageValue
        self.changePercentage = changePercentage
    }
}

enum HealthTrendDirection: String, CaseIterable, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Health Goals and Targets

struct HealthGoal: Identifiable, Codable {
    let id: UUID
    let metricType: String
    let targetValue: Double
    let currentValue: Double
    let unit: String
    let deadline: Date?
    let isActive: Bool
    let progress: Double
    
    var progressPercentage: Double {
        guard targetValue != 0 else { return 0 }
        return min(currentValue / targetValue * 100, 100)
    }
    
    var status: GoalStatus {
        if progress >= 100 {
            return .achieved
        } else if progress >= 75 {
            return .onTrack
        } else if progress >= 50 {
            return .needsAttention
        } else {
            return .offTrack
        }
    }
    
    init(metricType: String, targetValue: Double, currentValue: Double = 0, unit: String, deadline: Date? = nil, isActive: Bool = true, progress: Double = 0) {
        self.id = UUID()
        self.metricType = metricType
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.deadline = deadline
        self.isActive = isActive
        self.progress = progress
    }
}

enum GoalStatus: String, CaseIterable, Codable {
    case achieved = "Achieved"
    case onTrack = "On Track"
    case needsAttention = "Needs Attention"
    case offTrack = "Off Track"
    
    var color: Color {
        switch self {
        case .achieved: return .green
        case .onTrack: return .blue
        case .needsAttention: return .orange
        case .offTrack: return .red
        }
    }
}

// MARK: - Health Insights

struct HealthInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: InsightCategory
    let priority: InsightPriority
    let actionable: Bool
    let recommendations: [String]
    let relatedMetrics: [String]
    let generatedAt: Date
    
    init(title: String, description: String, category: InsightCategory, priority: InsightPriority, actionable: Bool = true, recommendations: [String] = [], relatedMetrics: [String] = [], generatedAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.actionable = actionable
        self.recommendations = recommendations
        self.relatedMetrics = relatedMetrics
        self.generatedAt = generatedAt
    }
}

enum InsightCategory: String, CaseIterable, Codable {
    case cardiovascular = "Cardiovascular"
    case weight = "Weight Management"
    case diabetes = "Diabetes Control"
    case general = "General Health"
    case lifestyle = "Lifestyle"
    
    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .diabetes: return "drop.fill"
        case .general: return "cross.fill"
        case .lifestyle: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .cardiovascular: return .red
        case .weight: return .green
        case .diabetes: return .blue
        case .general: return .purple
        case .lifestyle: return .orange
        }
    }
}

enum InsightPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}