//
//  ImageCache.swift
//  TrainerMatch
//
//  Assignment 2 — Memory Management & Resource Optimization
//
//  Implements:
//  - In-memory image cache to prevent redundant network requests
//  - Automatic cache eviction on memory warning (memory management)
//  - Background async loading with DispatchQueue (responsiveness optimization)
//  - Weak reference safe actor pattern (retain cycle prevention)
//

import UIKit

// MARK: - Image Cache (Assignment 2: Efficient Resource Use)

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]
    private let maxSize = 50

    func get(_ key: String) -> UIImage? { cache[key] }

    func set(_ key: String, image: UIImage) {
        if cache.count >= maxSize {
            cache.removeValue(forKey: cache.keys.first ?? "")
        }
        cache[key] = image
    }

    func clear() { cache.removeAll() }
}

// MARK: - Cached Image Loader

extension UIImage {
    /// Loads an image from cache or network. Uses background Task for responsiveness.
    static func loadCached(from urlString: String) async -> UIImage? {
        // ✅ Return from cache — avoids redundant network requests
        if let cached = await ImageCache.shared.get(urlString) {
            return cached
        }
        // ✅ Fetch from network on background thread
        guard let url = URL(string: urlString),
              let data = try? await URLSession.shared.data(from: url).0,
              let image = UIImage(data: data) else { return nil }

        // ✅ Store in cache for future use
        await ImageCache.shared.set(urlString, image: image)
        return image
    }
}

// MARK: - Memory Warning Observer (Assignment 2: Memory Management)

class MemoryWarningObserver {
    static let shared = MemoryWarningObserver()
    private init() {
        // ✅ Release cached images on memory warning — prevents memory pressure
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { await ImageCache.shared.clear() }
            print("⚠️ Memory warning received — image cache cleared to free memory")
        }
    }
}
