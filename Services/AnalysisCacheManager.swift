import Foundation
import UIKit
import CoreData

class AnalysisCacheManager: ObservableObject {
    static let shared = AnalysisCacheManager()
    
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    @Published var cachedAnalyses: [CachedAnalysis] = []
    @Published var cacheSize: Int = 0
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("MealAnalysisCache")
        
        createCacheDirectoryIfNeeded()
        loadCachedAnalyses()
        cleanupOldCache()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func cacheResult(_ result: MealAnalysisResult, image: UIImage) async throws {
        let cacheEntry = CachedAnalysis(
            id: result.id ?? UUID(),
            timestamp: Date(),
            result: result,
            imageHash: image.hash
        )
        
        // Save image
        let imageURL = cacheDirectory.appendingPathComponent("\(cacheEntry.id.uuidString)_image.jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            try imageData.write(to: imageURL)
        }
        
        // Save analysis result
        let resultURL = cacheDirectory.appendingPathComponent("\(cacheEntry.id.uuidString)_result.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let resultData = try encoder.encode(result)
        try resultData.write(to: resultURL)
        
        // Save cache entry metadata
        let metadataURL = cacheDirectory.appendingPathComponent("\(cacheEntry.id.uuidString)_metadata.json")
        let metadataData = try encoder.encode(cacheEntry)
        try metadataData.write(to: metadataURL)
        
        await MainActor.run {
            cachedAnalyses.append(cacheEntry)
            updateCacheSize()
        }
        
        // Cleanup if cache is too large
        await cleanupCacheIfNeeded()
    }
    
    func getCachedResult(for imageHash: String) -> MealAnalysisResult? {
        guard let cachedEntry = cachedAnalyses.first(where: { $0.imageHash == imageHash }) else {
            return nil
        }
        
        let resultURL = cacheDirectory.appendingPathComponent("\(cachedEntry.id.uuidString)_result.json")
        
        do {
            let data = try Data(contentsOf: resultURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MealAnalysisResult.self, from: data)
        } catch {
            // Remove corrupted cache entry
            removeCacheEntry(cachedEntry)
            return nil
        }
    }
    
    func getCachedImage(for analysisId: UUID) -> UIImage? {
        let imageURL = cacheDirectory.appendingPathComponent("\(analysisId.uuidString)_image.jpg")
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    private func loadCachedAnalyses() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            let metadataFiles = contents.filter { $0.pathExtension == "json" && $0.lastPathComponent.contains("_metadata") }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for metadataFile in metadataFiles {
                do {
                    let data = try Data(contentsOf: metadataFile)
                    let cachedEntry = try decoder.decode(CachedAnalysis.self, from: data)
                    cachedAnalyses.append(cachedEntry)
                } catch {
                    // Remove corrupted metadata file
                    try? FileManager.default.removeItem(at: metadataFile)
                }
            }
            
            // Sort by timestamp (newest first)
            cachedAnalyses.sort { $0.timestamp > $1.timestamp }
            updateCacheSize()
            
        } catch {
            print("Failed to load cached analyses: \(error)")
        }
    }
    
    private func updateCacheSize() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            cacheSize = contents.compactMap { url in
                try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            }.reduce(0, +)
        } catch {
            cacheSize = 0
        }
    }
    
    private func cleanupOldCache() {
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)
        let oldEntries = cachedAnalyses.filter { $0.timestamp < cutoffDate }
        
        for entry in oldEntries {
            removeCacheEntry(entry)
        }
    }
    
    private func cleanupCacheIfNeeded() async {
        guard cacheSize > maxCacheSize else { return }
        
        // Remove oldest entries until we're under the size limit
        let sortedEntries = cachedAnalyses.sorted { $0.timestamp < $1.timestamp }
        
        for entry in sortedEntries {
            removeCacheEntry(entry)
            if cacheSize <= maxCacheSize * 3/4 { // Remove until 75% of max size
                break
            }
        }
    }
    
    private func removeCacheEntry(_ entry: CachedAnalysis) {
        let baseURL = cacheDirectory.appendingPathComponent(entry.id.uuidString)
        
        // Remove all files for this entry
        let filesToRemove = [
            baseURL.appendingPathExtension("jpg").appendingPathComponent("_image"),
            baseURL.appendingPathExtension("json").appendingPathComponent("_result"),
            baseURL.appendingPathExtension("json").appendingPathComponent("_metadata")
        ]
        
        for fileURL in filesToRemove {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Remove from memory
        cachedAnalyses.removeAll { $0.id == entry.id }
        updateCacheSize()
    }
    
    func clearAllCache() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try FileManager.default.removeItem(at: file)
            }
            
            cachedAnalyses.removeAll()
            cacheSize = 0
            
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    func exportAnalysisHistory() -> [AnalysisHistoryEntry] {
        return cachedAnalyses.compactMap { cachedEntry in
            guard let result = getCachedResult(for: cachedEntry.imageHash) else { return nil }
            
            return AnalysisHistoryEntry(
                id: cachedEntry.id,
                timestamp: cachedEntry.timestamp,
                dishName: result.mealIdentification.primaryDishes.first ?? "Unknown Meal",
                calories: result.nutritionalAnalysis.totalCalories,
                confidence: result.confidence,
                diabeticScore: result.healthScore.diabeticFriendly,
                glp1Score: result.healthScore.glp1Compatible
            )
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getAnalysisStatistics() -> AnalysisStatistics {
        let analyses = cachedAnalyses.compactMap { getCachedResult(for: $0.imageHash) }
        
        guard !analyses.isEmpty else {
            return AnalysisStatistics(
                totalAnalyses: 0,
                averageConfidence: 0,
                averageCalories: 0,
                averageDiabeticScore: 0,
                averageGLP1Score: 0,
                mostCommonDishes: [],
                nutritionalTrends: NutritionalTrends(
                    averageCarbs: 0,
                    averageProtein: 0,
                    averageFat: 0,
                    averageFiber: 0
                )
            )
        }
        
        let totalAnalyses = analyses.count
        let averageConfidence = analyses.map(\.confidence).reduce(0, +) / Double(totalAnalyses)
        let averageCalories = analyses.map { Double($0.nutritionalAnalysis.totalCalories) }.reduce(0, +) / Double(totalAnalyses)
        let averageDiabeticScore = analyses.map(\.healthScore.diabeticFriendly).reduce(0, +) / Double(totalAnalyses)
        let averageGLP1Score = analyses.map(\.healthScore.glp1Compatible).reduce(0, +) / Double(totalAnalyses)
        
        // Find most common dishes
        let dishCounts = analyses.flatMap(\.mealIdentification.primaryDishes)
            .reduce(into: [String: Int]()) { counts, dish in
                counts[dish, default: 0] += 1
            }
        let mostCommonDishes = dishCounts.sorted { $0.value > $1.value }.prefix(5).map(\.key)
        
        // Calculate nutritional trends
        let nutritionalTrends = NutritionalTrends(
            averageCarbs: analyses.map(\.nutritionalAnalysis.macronutrients.carbohydrates.grams).reduce(0, +) / Double(totalAnalyses),
            averageProtein: analyses.map(\.nutritionalAnalysis.macronutrients.protein.grams).reduce(0, +) / Double(totalAnalyses),
            averageFat: analyses.map(\.nutritionalAnalysis.macronutrients.fat.grams).reduce(0, +) / Double(totalAnalyses),
            averageFiber: analyses.map(\.nutritionalAnalysis.macronutrients.fiber.grams).reduce(0, +) / Double(totalAnalyses)
        )
        
        return AnalysisStatistics(
            totalAnalyses: totalAnalyses,
            averageConfidence: averageConfidence,
            averageCalories: averageCalories,
            averageDiabeticScore: averageDiabeticScore,
            averageGLP1Score: averageGLP1Score,
            mostCommonDishes: Array(mostCommonDishes),
            nutritionalTrends: nutritionalTrends
        )
    }
}

// MARK: - Data Models

struct CachedAnalysis: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let result: MealAnalysisResult
    let imageHash: String
}

struct AnalysisHistoryEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let dishName: String
    let calories: Int
    let confidence: Double
    let diabeticScore: Double
    let glp1Score: Double
}

struct AnalysisStatistics {
    let totalAnalyses: Int
    let averageConfidence: Double
    let averageCalories: Double
    let averageDiabeticScore: Double
    let averageGLP1Score: Double
    let mostCommonDishes: [String]
    let nutritionalTrends: NutritionalTrends
}

struct NutritionalTrends {
    let averageCarbs: Double
    let averageProtein: Double
    let averageFat: Double
    let averageFiber: Double
}

// MARK: - UIImage Extension for Hashing

extension UIImage {
    var hash: String {
        guard let data = self.pngData() else { return UUID().uuidString }
        return data.sha256
    }
}

extension Data {
    var sha256: String {
        let digest = self.withUnsafeBytes { bytes in
            return SHA256.hash(data: bytes)
        }
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

import CryptoKit

extension SHA256 {
    static func hash(data: UnsafeRawBufferPointer) -> SHA256Digest {
        return SHA256.hash(data: Data(data))
    }
}