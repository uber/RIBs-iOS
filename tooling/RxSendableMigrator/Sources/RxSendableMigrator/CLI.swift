import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser

@main
struct RxSendableMigrator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rx-sendable-migrator",
        abstract: "Injects @Sendable into RxSwift operator closures for Swift 6 migration."
    )

    @Option(name: .long, help: "Path to the Swift source directory to migrate.")
    var sourceDir: String

    @Option(
        name: .long,
        help: "Path to the Xcode index store (e.g. DerivedData/.../Index/DataStore). Auto-detected from DerivedData if omitted."
    )
    var indexStorePath: String?

    @Flag(name: .long, help: "Print changes without writing to disk.")
    var dryRun = false

    @Option(name: .long, help: "Print IndexStore lookup details for files matching this suffix (e.g. LoginInteractor.swift).")
    var debugFile: String?

    func run() throws {
        let resolvedIndexStorePath = try resolveIndexStorePath()
        let indexService = try IndexStoreService(storePath: resolvedIndexStorePath)

        let sourceDirURL = URL(fileURLWithPath: sourceDir, isDirectory: true)
        guard let enumerator = FileManager.default.enumerator(
            at: sourceDirURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            print("Could not enumerate \(sourceDir)")
            return
        }

        var filesModified = 0

        for case let fileURL as URL in enumerator {
            // Skip vendor/build directories
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if isDir.boolValue {
                if VendorFilter.shouldExclude(directoryName: fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard fileURL.pathExtension == "swift" else { continue }

            let source: String
            do {
                source = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                fputs("Warning: could not read \(fileURL.path): \(error)\n", stderr)
                continue
            }

            let modified = migrateFile(source: source, filePath: fileURL.path, indexService: indexService)

            guard modified != source else { continue }

            filesModified += 1
            if dryRun {
                printUnifiedDiff(original: source, modified: modified, path: fileURL.path)
            } else {
                do {
                    try modified.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("Modified: \(fileURL.path)")
                } catch {
                    fputs("Error writing \(fileURL.path): \(error)\n", stderr)
                }
            }
        }

        let verb = dryRun ? "would be" : "were"
        print("\nDone. \(filesModified) file(s) \(verb) modified.")
    }

    // MARK: - Private

    private func resolveIndexStorePath() throws -> String {
        if let explicit = indexStorePath {
            return explicit
        }
        guard let discovered = IndexStoreDiscovery.findIndexStorePath(for: sourceDir) else {
            throw ValidationError(
                "Could not auto-detect an index store for \(sourceDir). " +
                "Build the project in Xcode first, or pass --index-store-path explicitly."
            )
        }
        print("Auto-detected index store: \(discovered)")
        return discovered
    }

    private func printUnifiedDiff(original: String, modified: String, path: String) {
        let originalLines = original.components(separatedBy: "\n")
        let modifiedLines = modified.components(separatedBy: "\n")

        // Collect changed hunks (±3 lines of context)
        let context = 3
        var hunks: [(range: Range<Int>, lines: [String])] = []
        var i = 0
        while i < max(originalLines.count, modifiedLines.count) {
            let origLine = i < originalLines.count ? originalLines[i] : nil
            let modLine  = i < modifiedLines.count  ? modifiedLines[i]  : nil
            if origLine != modLine {
                let start = max(0, i - context)
                var end = min(max(originalLines.count, modifiedLines.count), i + 1)
                // extend end until lines match again for context
                while end < max(originalLines.count, modifiedLines.count) {
                    let oe = end < originalLines.count ? originalLines[end] : nil
                    let me = end < modifiedLines.count  ? modifiedLines[end]  : nil
                    if oe == me { break }
                    end += 1
                }
                end = min(max(originalLines.count, modifiedLines.count), end + context)

                var hunkLines: [String] = []
                for j in start..<end {
                    let o = j < originalLines.count ? originalLines[j] : nil
                    let m = j < modifiedLines.count  ? modifiedLines[j]  : nil
                    if o == m {
                        hunkLines.append(" \(o ?? "")")
                    } else {
                        if let o { hunkLines.append("-\(o)") }
                        if let m { hunkLines.append("+\(m)") }
                    }
                }
                hunks.append((start..<end, hunkLines))
                i = end
            } else {
                i += 1
            }
        }

        guard !hunks.isEmpty else { return }
        print("--- \(path)")
        print("+++ \(path)")
        for hunk in hunks {
            print("@@ -\(hunk.range.lowerBound + 1) +\(hunk.range.lowerBound + 1) @@")
            hunk.lines.forEach { print($0) }
        }
        print("")
    }

    private func migrateFile(source: String, filePath: String, indexService: IndexStoreService) -> String {
        let tree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: filePath, tree: tree)
        let rewriter = RxSendableRewriter(
            filePath: filePath,
            locationConverter: converter,
            indexService: indexService,
            debugFile: debugFile
        )
        let newTree = rewriter.visit(tree)
        return newTree.description
    }
}
