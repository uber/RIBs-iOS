import XCTest
import Foundation
@testable import RxSendableMigrator

/// Integration tests for RxSendableMigrator.
///
/// These tests are slow because they require building a sample project with xcodebuild
/// to generate a real IndexStore. They are skipped by default unless RUN_INTEGRATION_TESTS=1
/// environment variable is set.
final class IntegrationTests: XCTestCase {
    
    var tempDir: URL!
    var sampleProjectDir: URL!
    var projectRoot: URL!
    var derivedDataPath: URL!
    
    override func setUpWithError() throws {
        // Only run integration tests if explicitly requested, as they are slow and depend on Xcode environment
        try XCTSkipIf(ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] == nil, "Skipping integration tests. Set RUN_INTEGRATION_TESTS=1 to run.")
        
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("RxSendableMigratorIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Find the project root (walking up from this file)
        projectRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // RxSendableMigratorTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // RxSendableMigrator
            .deletingLastPathComponent() // tooling
            .deletingLastPathComponent() // project root
        
        let sourceSampleDir = projectRoot.appendingPathComponent("Examples/RIBsAppExample2")
        sampleProjectDir = tempDir.appendingPathComponent("RIBsAppExample2")
        
        // Copy sample project to temp dir
        try runCommand("/bin/cp", arguments: ["-R", sourceSampleDir.path, sampleProjectDir.path])
        
        // Patch project.pbxproj to use absolute path for RIBs-iOS dependency,
        // so it can be built from the temporary directory.
        let pbxprojPath = sampleProjectDir.appendingPathComponent("RIBsAppExample2.xcodeproj/project.pbxproj")
        var pbxprojContent = try String(contentsOf: pbxprojPath, encoding: .utf8)
        pbxprojContent = pbxprojContent.replacingOccurrences(of: "../../../RIBs-iOS", with: projectRoot.path)
        try pbxprojContent.write(to: pbxprojPath, atomically: true, encoding: .utf8)
        
        derivedDataPath = tempDir.appendingPathComponent("DerivedData")
        
        print("Building sample project to generate IndexStore...")
        // Build the sample project to generate IndexStore records.
        // destination 'generic/platform=iOS' works even without physical device/simulator.
        try runCommand("/usr/bin/xcodebuild", arguments: [
            "-project", sampleProjectDir.appendingPathComponent("RIBsAppExample2.xcodeproj").path,
            "-scheme", "RIBsAppExample2",
            "-destination", "generic/platform=iOS",
            "-derivedDataPath", derivedDataPath.path,
            "-clonedSourcePackagesDirPath", tempDir.appendingPathComponent("Packages").path,
            "COMPILER_INDEX_STORE_ENABLE=YES",
            "build",
            "-quiet"
        ])
    }
    
    override func tearDownWithError() throws {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
    }
    
    func test_migrateSampleProject() throws {
        let indexStorePath = IndexStoreDiscovery.findIndexStorePath(for: sampleProjectDir.path, derivedDataURL: derivedDataPath)
        XCTAssertNotNil(indexStorePath, "Should have discovered an index store in \(derivedDataPath.path)")
        
        // Run the migrator logic
        let arguments = [
            "rx-sendable-migrator",
            "--source-dir", sampleProjectDir.path,
            "--index-store-path", indexStorePath!
        ]
        
        print("Running migrator on sample project...")
        var migrator = try RxSendableMigrator.parseAsRoot(arguments)
        try migrator.run()
        
        // Verify changes in a specific file
        let interactorPath = sampleProjectDir.appendingPathComponent("RIBsAppExample2/Root/RootInteractor.swift")
        let content = try String(contentsOf: interactorPath, encoding: .utf8)
        
        // Before: return firstViewableRIBActionableItemSubject.map { ($0, ()) }
        // After:  return firstViewableRIBActionableItemSubject.map { @Sendable ($0, ()) }
        XCTAssertTrue(content.contains(".map { @Sendable ($0, ()) }"), "File should have been migrated: \(interactorPath.path)")
        
        // Verify subscribe was NOT migrated
        XCTAssertTrue(content.contains(".subscribe { event in"), "Subscribe should NOT have been migrated")
        XCTAssertFalse(content.contains(".subscribe { @Sendable event in"), "Subscribe should NOT have been migrated")
    }
    
    func test_dryRunDoesNotModifyFiles() throws {
        let indexStorePath = IndexStoreDiscovery.findIndexStorePath(for: sampleProjectDir.path, derivedDataURL: derivedDataPath)
        XCTAssertNotNil(indexStorePath)
        
        let interactorPath = sampleProjectDir.appendingPathComponent("RIBsAppExample2/Root/RootInteractor.swift")
        let originalContent = try String(contentsOf: interactorPath, encoding: .utf8)
        
        let arguments = [
            "rx-sendable-migrator",
            "--source-dir", sampleProjectDir.path,
            "--index-store-path", indexStorePath!,
            "--dry-run"
        ]
        
        var migrator = try RxSendableMigrator.parseAsRoot(arguments)
        try migrator.run()
        
        let newContent = try String(contentsOf: interactorPath, encoding: .utf8)
        XCTAssertEqual(originalContent, newContent, "Files should not be modified in dry-run mode")
    }
    
    @discardableResult
    private func runCommand(_ executable: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "IntegrationTests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Command failed: \(executable) \(arguments.joined(separator: " "))\nOutput: \(output)"])
        }
        
        return output
    }
}
