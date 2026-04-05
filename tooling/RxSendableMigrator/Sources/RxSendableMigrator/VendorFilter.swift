import Foundation

struct VendorFilter {
    /// Directory names that are unconditionally skipped during source file enumeration.
    /// These are vendor dependency managers and build artefacts we never want to migrate.
    static let excludedDirectoryNames: Set<String> = [
        "Pods",         // CocoaPods
        "Carthage",     // Carthage
        ".build",       // Swift Package Manager build output
        ".swiftpm",     // SPM package cache
        "vendor",       // Generic vendor directory
        "Packages",     // Resolved Swift packages
        ".git",         // Git internals
        "build",        // Generic Xcode/CMake build output
        "DerivedData",  // Xcode derived data (if nested in source tree)
        "node_modules", // JavaScript tooling (React Native, etc.)
    ]

    static func shouldExclude(directoryName: String) -> Bool {
        excludedDirectoryNames.contains(directoryName)
    }
}
