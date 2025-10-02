# Performance Optimizations

## Current Performance Issues

### 1. Memory Management
- Large base64 image encoding in OpenAI service
- Images stored in Core Data causing memory bloat
- Potential memory leaks in async operations

### 2. Network Efficiency
- No request caching
- Missing compression for API calls
- Inefficient sync operations

### 3. UI Performance
- Blocking operations on main thread
- Missing lazy loading for large datasets
- No image caching system

## Optimization Solutions

### 1. Image Handling Improvements
```swift
// Optimize image processing
class OptimizedImageProcessor {
    private let maxImageSize: CGFloat = 1024
    private let compressionQuality: CGFloat = 0.7
    
    func processImageForAPI(_ image: UIImage) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Resize on background thread
                let resized = self.resizeImage(image, maxSize: self.maxImageSize)
                let data = resized?.jpegData(compressionQuality: self.compressionQuality)
                continuation.resume(returning: data)
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        return await UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
```

### 2. Caching System
```swift
// Add intelligent caching
class CacheManager {
    private let cache = NSCache<NSString, AnyObject>()
    private let diskCache: URL
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        diskCache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppCache")
        
        try? FileManager.default.createDirectory(at: diskCache, withIntermediateDirectories: true)
    }
    
    func cacheAnalysisResult(_ result: MealAnalysisResult, forKey key: String) {
        // Memory cache
        cache.setObject(result as AnyObject, forKey: key as NSString)
        
        // Disk cache for persistence
        Task {
            let data = try JSONEncoder().encode(result)
            let url = diskCache.appendingPathComponent("\(key).json")
            try data.write(to: url)
        }
    }
}
```

### 3. Database Query Optimization
```swift
// Optimize Core Data queries
extension CoreDataManager {
    func fetchMealAnalyses(limit: Int = 20, offset: Int = 0) -> [MealAnalysisEntity] {
        let request: NSFetchRequest<MealAnalysisEntity> = MealAnalysisEntity.fetchRequest()
        
        // Add proper sorting and limits
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealAnalysisEntity.timestamp, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        // Use batch faulting for better performance
        request.returnsObjectsAsFaults = false
        
        // Prefetch relationships to avoid N+1 queries
        request.relationshipKeyPathsForPrefetching = ["user"]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meal analyses: \(error)")
            return []
        }
    }
}
```

### 4. Async Operation Improvements
```swift
// Better async task management
class TaskManager {
    private var activeTasks: Set<Task<Void, Never>> = []
    
    func addTask(_ task: Task<Void, Never>) {
        activeTasks.insert(task)
        
        Task {
            await task.value
            activeTasks.remove(task)
        }
    }
    
    func cancelAllTasks() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}
```

## Performance Monitoring
- Add performance metrics collection
- Monitor memory usage patterns
- Track network request timing
- Implement crash reporting with performance data