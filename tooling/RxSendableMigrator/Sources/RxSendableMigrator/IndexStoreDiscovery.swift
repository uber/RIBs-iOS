import Foundation

struct IndexStoreDiscovery {

    /// Searches `~/Library/Developer/Xcode/DerivedData` for the most appropriate
    /// IndexStore DataStore directory for the given source directory.
    ///
    /// Strategy:
    /// 1. Sort all DerivedData entries by modification date (newest first).
    /// 2. Prefer entries whose `info.plist` WorkspacePath is related to `sourceDir`
    ///    (i.e. the workspace lives inside or contains `sourceDir`).
    /// 3. Fall back to the most-recently-modified entry that has a valid DataStore.
    static func findIndexStorePath(for sourceDir: String) -> String? {
        let derivedDataURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData")

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: derivedDataURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return nil }

        let sorted = entries.sorted { modDate(of: $0) > modDate(of: $1) }
        let sourceDirURL = URL(fileURLWithPath: sourceDir).resolvingSymlinksInPath()

        for entry in sorted {
            if let workspacePath = readWorkspacePath(from: entry),
               isRelated(workspacePath: workspacePath, to: sourceDirURL),
               let dataStore = dataStorePath(in: entry) {
                return dataStore
            }
        }

        // Fallback: newest DataStore regardless of workspace match
        for entry in sorted {
            if let dataStore = dataStorePath(in: entry) {
                return dataStore
            }
        }

        return nil
    }

    // MARK: - Internal helpers (exposed for testing)

    /// Reads the `WorkspacePath` key from a DerivedData entry's `info.plist`.
    static func readWorkspacePath(from derivedDataEntry: URL) -> String? {
        let infoPlist = derivedDataEntry.appendingPathComponent("info.plist")
        guard
            let data = try? Data(contentsOf: infoPlist),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let workspacePath = plist["WorkspacePath"] as? String
        else { return nil }
        return workspacePath
    }

    /// Returns `true` when `workspacePath`'s parent directory is an ancestor or descendant
    /// of `sourceDir` (after resolving symlinks on both sides).
    static func isRelated(workspacePath: String, to sourceDir: URL) -> Bool {
        let workspaceDir = URL(fileURLWithPath: workspacePath)
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        let resolvedSource = sourceDir.resolvingSymlinksInPath()

        let a = workspaceDir.path
        let b = resolvedSource.path

        return b.hasPrefix(a + "/") || b == a
            || a.hasPrefix(b + "/") || a == b
    }

    /// Returns the DataStore path inside a DerivedData entry, or `nil` if none exists.
    /// Supports both modern (`Index.noindex/DataStore`) and legacy (`Index/DataStore`) layouts.
    static func dataStorePath(in derivedDataEntry: URL) -> String? {
        let modern = derivedDataEntry.appendingPathComponent("Index.noindex/DataStore")
        if FileManager.default.fileExists(
            atPath: modern.appendingPathComponent("v5/units").path
        ) {
            return modern.path
        }

        let legacy = derivedDataEntry.appendingPathComponent("Index/DataStore")
        if FileManager.default.fileExists(atPath: legacy.path) {
            return legacy.path
        }

        return nil
    }

    // MARK: - Private

    private static func modDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            ?? .distantPast
    }
}
