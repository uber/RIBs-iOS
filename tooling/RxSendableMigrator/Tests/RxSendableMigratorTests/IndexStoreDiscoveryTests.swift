import XCTest
@testable import RxSendableMigrator

final class IndexStoreDiscoveryTests: XCTestCase {

    // MARK: - isRelated

    func test_isRelated_sourceDirInsideWorkspaceDir() {
        let workspacePath = "/projects/MyApp/iosApp/MyApp.xcworkspace"
        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp/Sources")
        XCTAssertTrue(IndexStoreDiscovery.isRelated(workspacePath: workspacePath, to: sourceDir))
    }

    func test_isRelated_sourceDirEqualsWorkspaceDir() {
        let workspacePath = "/projects/MyApp/iosApp/MyApp.xcworkspace"
        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp")
        XCTAssertTrue(IndexStoreDiscovery.isRelated(workspacePath: workspacePath, to: sourceDir))
    }

    func test_isRelated_workspaceDirInsideSourceDir() {
        // Source dir is repo root; workspace is nested inside
        let workspacePath = "/repo/iosApp/iosApp.xcworkspace"
        let sourceDir = URL(fileURLWithPath: "/repo")
        XCTAssertTrue(IndexStoreDiscovery.isRelated(workspacePath: workspacePath, to: sourceDir))
    }

    func test_isRelated_unrelatedPaths() {
        let workspacePath = "/projects/OtherApp/OtherApp.xcworkspace"
        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp")
        XCTAssertFalse(IndexStoreDiscovery.isRelated(workspacePath: workspacePath, to: sourceDir))
    }

    func test_isRelated_partialPrefixDoesNotMatch() {
        // "/projects/MyApp" must not match "/projects/MyAppExtension"
        let workspacePath = "/projects/MyAppExtension/MyAppExtension.xcworkspace"
        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp")
        XCTAssertFalse(IndexStoreDiscovery.isRelated(workspacePath: workspacePath, to: sourceDir))
    }

    // MARK: - readWorkspacePath

    func test_readWorkspacePath_returnsPath() throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try writePlist(["WorkspacePath": "/projects/MyApp/MyApp.xcworkspace"], to: dir)

        XCTAssertEqual(
            IndexStoreDiscovery.readWorkspacePath(from: dir),
            "/projects/MyApp/MyApp.xcworkspace"
        )
    }

    func test_readWorkspacePath_missingPlist_returnsNil() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        XCTAssertNil(IndexStoreDiscovery.readWorkspacePath(from: dir))
    }

    func test_readWorkspacePath_missingKey_returnsNil() throws {
        let dir = try makeTempDir()
        defer { cleanup(dir) }

        try writePlist(["SomeOtherKey": "value"], to: dir)

        XCTAssertNil(IndexStoreDiscovery.readWorkspacePath(from: dir))
    }

    // MARK: - dataStorePath

    func test_dataStorePath_modernFormat() throws {
        let entry = try makeTempDir()
        defer { cleanup(entry) }

        try makeDir(entry.appendingPathComponent("Index.noindex/DataStore/v5/units"))

        XCTAssertEqual(
            IndexStoreDiscovery.dataStorePath(in: entry),
            entry.appendingPathComponent("Index.noindex/DataStore").path
        )
    }

    func test_dataStorePath_legacyFormat() throws {
        let entry = try makeTempDir()
        defer { cleanup(entry) }

        try makeDir(entry.appendingPathComponent("Index/DataStore"))

        XCTAssertEqual(
            IndexStoreDiscovery.dataStorePath(in: entry),
            entry.appendingPathComponent("Index/DataStore").path
        )
    }

    func test_dataStorePath_noIndex_returnsNil() throws {
        let entry = try makeTempDir()
        defer { cleanup(entry) }

        XCTAssertNil(IndexStoreDiscovery.dataStorePath(in: entry))
    }

    func test_dataStorePath_prefersModernOverLegacy() throws {
        let entry = try makeTempDir()
        defer { cleanup(entry) }

        try makeDir(entry.appendingPathComponent("Index.noindex/DataStore/v5/units"))
        try makeDir(entry.appendingPathComponent("Index/DataStore"))

        XCTAssertEqual(
            IndexStoreDiscovery.dataStorePath(in: entry),
            entry.appendingPathComponent("Index.noindex/DataStore").path
        )
    }

    // MARK: - findIndexStorePath (integration using fake DerivedData)

    func test_findIndexStorePath_picksRelatedEntry() throws {
        // We can't override the system DerivedData path, so we test the building blocks
        // that `findIndexStorePath` composes. This test validates the full selection
        // logic by calling `readWorkspacePath`, `isRelated`, and `dataStorePath` together.

        let fakeDerived = try makeFakeDerivedDataEntry(
            workspacePath: "/projects/MyApp/iosApp/MyApp.xcworkspace"
        )
        defer { cleanup(fakeDerived.root) }

        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp/Sources")

        let workspacePath = IndexStoreDiscovery.readWorkspacePath(from: fakeDerived.entry)
        let related = workspacePath.map { IndexStoreDiscovery.isRelated(workspacePath: $0, to: sourceDir) } ?? false
        let dataStore = IndexStoreDiscovery.dataStorePath(in: fakeDerived.entry)

        XCTAssertNotNil(workspacePath)
        XCTAssertTrue(related)
        XCTAssertEqual(dataStore, fakeDerived.dataStorePath)
    }

    func test_findIndexStorePath_rejectsUnrelatedEntry() throws {
        let fakeDerived = try makeFakeDerivedDataEntry(
            workspacePath: "/projects/OtherApp/OtherApp.xcworkspace"
        )
        defer { cleanup(fakeDerived.root) }

        let sourceDir = URL(fileURLWithPath: "/projects/MyApp/iosApp/Sources")

        let workspacePath = IndexStoreDiscovery.readWorkspacePath(from: fakeDerived.entry)
        let related = workspacePath.map { IndexStoreDiscovery.isRelated(workspacePath: $0, to: sourceDir) } ?? false

        XCTAssertFalse(related)
    }

    // MARK: - Helpers

    private struct FakeDerivedDataEntry {
        let root: URL
        let entry: URL
        let dataStorePath: String
    }

    private func makeFakeDerivedDataEntry(workspacePath: String) throws -> FakeDerivedDataEntry {
        let root = try makeTempDir()
        let entry = root.appendingPathComponent("MyApp-abcdef1234")
        try makeDir(entry.appendingPathComponent("Index.noindex/DataStore/v5/units"))
        try writePlist(["WorkspacePath": workspacePath], to: entry)
        return FakeDerivedDataEntry(
            root: root,
            entry: entry,
            dataStorePath: entry.appendingPathComponent("Index.noindex/DataStore").path
        )
    }

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("IndexStoreDiscoveryTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeDir(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func writePlist(_ dict: [String: Any], to dir: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: dir.appendingPathComponent("info.plist"))
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
