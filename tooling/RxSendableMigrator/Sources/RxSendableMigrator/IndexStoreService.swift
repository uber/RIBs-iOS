import Foundation
import IndexStoreDB

enum MigratorError: Error, CustomStringConvertible {
    case indexStoreLibraryNotFound

    var description: String {
        "Could not find libIndexStore.dylib. Ensure Xcode is installed and xcrun is available."
    }
}

final class IndexStoreService {
    private let db: IndexStoreDB

    init(storePath: String) throws {
        let libPath = try Self.findIndexStoreLibrary()
        let library = try IndexStoreLibrary(dylibPath: libPath)

        // IndexStoreDB needs a scratch directory for its own derived cache.
        // The directory must exist before passing it to IndexStoreDB (LMDB requires it).
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RxSendableMigrator-db-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: databaseURL, withIntermediateDirectories: true)
        let databasePath = databaseURL.path

        self.db = try IndexStoreDB(
            storePath: storePath,
            databasePath: databasePath,
            library: library,
            waitUntilDoneInitializing: true,
            readonly: false
        )
    }

    /// Returns true if the call site at (file, line, column) resolves to a RxSwift symbol.
    /// `line` and `column` are 1-based, UTF-8 byte offsets — matching SourceLocationConverter output.
    func isRxSwiftCall(file: String, line: Int, column: Int, debugFile: String? = nil) -> Bool {
        // symbolOccurrences(inFilePath:) returns all symbol references recorded in the file.
        // We filter to the exact call-site position, then check the symbol's USR.
        // Swift USRs are mangled names; RxSwift symbols contain "RxSwift" in their USR
        // (e.g. "s:7RxSwift17ObservableConvertibleTypeP3map...").
        let occs = db.symbolOccurrences(inFilePath: file)
        if let debugFile, file.hasSuffix(debugFile) {
            let nearby = occs.filter { abs($0.location.line - line) <= 1 }
                             .sorted { $0.location.line < $1.location.line }
            for o in nearby {
                let hit = o.location.line == line && o.location.utf8Column == column
                fputs("  [\(hit ? "HIT" : "   ")] line=\(o.location.line) col=\(o.location.utf8Column) name=\(o.symbol.name) usr=\(o.symbol.usr.prefix(60))\n", stderr)
            }
        }
        return occs.contains { occ in
            occ.location.line == line &&
            occ.location.utf8Column == column &&
            occ.symbol.usr.contains("RxSwift")
        }
    }

    // MARK: - Private

    private static func findIndexStoreLibrary() throws -> String {
        // Ask xcrun where clang lives; derive the toolchain lib path from that
        if let candidate = toolchainLibPath() {
            return candidate
        }
        // Fallback to default Xcode install location
        let fallback = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"
        guard FileManager.default.fileExists(atPath: fallback) else {
            throw MigratorError.indexStoreLibraryNotFound
        }
        return fallback
    }

    private static func toolchainLibPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--find", "clang"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !output.isEmpty else { return nil }

        // clang lives at .../usr/bin/clang → lib is at .../usr/lib/libIndexStore.dylib
        let libPath = URL(fileURLWithPath: output)
            .deletingLastPathComponent()  // remove "clang"
            .deletingLastPathComponent()  // remove "bin"
            .appendingPathComponent("lib/libIndexStore.dylib")
            .path

        return FileManager.default.fileExists(atPath: libPath) ? libPath : nil
    }
}
