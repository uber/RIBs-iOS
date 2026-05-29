import XCTest
@testable import RxSendableMigrator

final class VendorFilterTests: XCTestCase {

    // MARK: - shouldExclude

    func test_excludes_pods() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: "Pods"))
    }

    func test_excludes_carthage() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: "Carthage"))
    }

    func test_excludes_swiftBuild() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: ".build"))
    }

    func test_excludes_swiftpm() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: ".swiftpm"))
    }

    func test_excludes_vendor() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: "vendor"))
    }

    func test_excludes_git() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: ".git"))
    }

    func test_excludes_build() {
        XCTAssertTrue(VendorFilter.shouldExclude(directoryName: "build"))
    }

    func test_doesNotExclude_sourceDirs() {
        XCTAssertFalse(VendorFilter.shouldExclude(directoryName: "Sources"))
        XCTAssertFalse(VendorFilter.shouldExclude(directoryName: "Interactors"))
        XCTAssertFalse(VendorFilter.shouldExclude(directoryName: "MyFeature"))
        XCTAssertFalse(VendorFilter.shouldExclude(directoryName: "RxSwift"))
    }

    // MARK: - Enumeration integration

    func test_enumerationSkipsPodsFiles() throws {
        let root = try makeProjectTree([
            "Sources/MyInteractor.swift": "// source",
            "Pods/RxSwift/Observable.swift": "// pod",
            "Pods/RxSwift/Nested/Deep.swift": "// deep pod",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = collectSwiftFiles(under: root)

        XCTAssertEqual(found.map(\.lastPathComponent).sorted(), ["MyInteractor.swift"])
    }

    func test_enumerationSkipsCarthageFiles() throws {
        let root = try makeProjectTree([
            "Sources/MyInteractor.swift": "// source",
            "Carthage/Build/SomeLib.swift": "// carthage",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = collectSwiftFiles(under: root)

        XCTAssertEqual(found.map(\.lastPathComponent).sorted(), ["MyInteractor.swift"])
    }

    func test_enumerationSkipsMultipleVendorDirs() throws {
        let root = try makeProjectTree([
            "Sources/A.swift": "// a",
            "Sources/B.swift": "// b",
            "Pods/PodFile.swift": "// pod",
            "Carthage/CartFile.swift": "// cart",
            ".build/BuildFile.swift": "// build",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = collectSwiftFiles(under: root)

        XCTAssertEqual(found.map(\.lastPathComponent).sorted(), ["A.swift", "B.swift"])
    }

    func test_enumerationKeepsAllSourceFilesWhenNoVendorDirs() throws {
        let root = try makeProjectTree([
            "FeatureA/Interactor.swift": "// a",
            "FeatureB/Router.swift": "// b",
            "FeatureB/Builder.swift": "// c",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = collectSwiftFiles(under: root)

        XCTAssertEqual(found.count, 3)
    }

    // MARK: - Helpers

    /// Mimics the enumeration loop in CLI.run(), applying VendorFilter.
    private func collectSwiftFiles(under root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var result: [URL] = []
        for case let url as URL in enumerator {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue {
                if VendorFilter.shouldExclude(directoryName: url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard url.pathExtension == "swift" else { continue }
            result.append(url)
        }
        return result
    }

    /// Creates a temporary directory tree from a `[relativePath: content]` dictionary.
    private func makeProjectTree(_ files: [String: String]) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VendorFilterTest-\(UUID().uuidString)")
        for (relativePath, content) in files {
            let fileURL = root.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        return root
    }
}
