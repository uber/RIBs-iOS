import XCTest
import SwiftSyntax
import SwiftParser
@testable import RxSendableMigrator

final class RxSendableRewriterTests: XCTestCase {

    func test_rewrite_standardClosure_injectsSendable() {
        assertRewrite(
            input: ".map { value in value + 1 }",
            expected: ".map { @Sendable value in value + 1 }"
        )
    }

    func test_rewrite_shorthandClosure_synthesizesSignature() {
        assertRewrite(
            input: ".map { $0 + 1 }",
            expected: ".map { @Sendable in $0 + 1 }"
        )
    }

    func test_rewrite_closureWithCaptureList_injectsBeforeCapture() {
        assertRewrite(
            input: ".map { [weak self] value in self?.transform(value) }",
            expected: ".map { @Sendable [weak self] value in self?.transform(value) }"
        )
    }

    func test_rewrite_alreadyHasSendable_doesNotDuplicate() {
        assertRewrite(
            input: ".map { @Sendable value in value + 1 }",
            expected: ".map { @Sendable value in value + 1 }"
        )
    }

    func test_rewrite_noParams_synthesizesSignature() {
        assertRewrite(
            input: ".do { print(\"side effect\") }",
            expected: ".do { @Sendable in print(\"side effect\") }"
        )
    }

    func test_rewrite_subscribe_shouldNotBeConverted() {
        // As per user instructions and comments in RxSendableRewriter.swift
        assertRewrite(
            input: ".subscribe { value in print(value) }",
            expected: ".subscribe { value in print(value) }"
        )
    }

    func test_rewrite_bind_shouldNotBeConverted() {
        assertRewrite(
            input: ".bind { value in print(value) }",
            expected: ".bind { value in print(value) }"
        )
    }

    func test_rewrite_nonRxOperator_shouldNotBeConverted() {
        assertRewrite(
            input: ".someOtherMethod { value in value + 1 }",
            expected: ".someOtherMethod { value in value + 1 }"
        )
    }

    // MARK: - Helpers

    private func assertRewrite(input: String, expected: String, file: StaticString = #file, line: UInt = #line) {
        let tree = Parser.parse(source: input)
        let rewriter = RxSendableRewriter(
            filePath: "test.swift",
            locationConverter: SourceLocationConverter(fileName: "test.swift", tree: tree),
            indexService: MockIndexStoreProvider()
        )
        let modified = rewriter.visit(tree)
        XCTAssertEqual(modified.description, expected, file: file, line: line)
    }
}

private final class MockIndexStoreProvider: IndexStoreProviding {
    func isRxSwiftCall(file: String, line: Int, column: Int, debugFile: String?) -> Bool {
        // For unit tests of the rewriter, we assume whitelisted operators are Rx calls
        return true
    }
}
