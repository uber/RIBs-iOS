#!/usr/bin/env swift
//
// add_sendable_to_rxswift_closures_tests.swift
//
// Tests for add_sendable_to_rxswift_closures.swift
//
// Usage:
//   swift tooling/add_sendable_to_rxswift_closures_tests.swift

import Foundation

// MARK: - Transform logic (kept in sync with add_sendable_to_rxswift_closures.swift)

let patternString = #"(?<!onSuccess: )(?<!onFailure: )(?<!fromAsync )\{(\h*+(?:\[[^\]]*\]\h*+)?+)(?!\h*@Sendable\b)(?=[^\n{}]*\bin\b)"#

guard let regex = try? NSRegularExpression(pattern: patternString) else {
    fputs("error: failed to compile regex\n", stderr); exit(1)
}

func transform(_ text: String) -> String {
    let range = NSRange(text.startIndex..., in: text)
    let matches = regex.matches(in: text, range: range)
    guard !matches.isEmpty else { return text }
    var result = text
    for match in matches.reversed() {
        guard
            let fullRange = Range(match.range, in: result),
            let captureRange = Range(match.range(at: 1), in: result)
        else { continue }
        let capture = String(result[captureRange])
        result.replaceSubrange(fullRange, with: "{\(capture)@Sendable ")
    }
    return result
}

func shouldProcessFile(path: String = "MyFile.swift", text: String) -> Bool {
    guard !path.contains("/Pods/") else { return false }
    return text.contains("import RxSwift") || text.contains("import RxRelay")
}

// MARK: - Test runner

var passed = 0
var failed = 0

func test(_ name: String, input: String, expected: String) {
    let result = transform(input)
    if result == expected {
        print("✓ \(name)")
        passed += 1
    } else {
        print("✗ \(name)")
        print("  input:    \(input.debugDescription)")
        print("  expected: \(expected.debugDescription)")
        print("  got:      \(result.debugDescription)")
        failed += 1
    }
}

func testNoChange(_ name: String, input: String) {
    test(name, input: input, expected: input)
}

func testBool(_ name: String, value: Bool, expected: Bool) {
    if value == expected {
        print("✓ \(name)")
        passed += 1
    } else {
        print("✗ \(name)")
        print("  expected: \(expected), got: \(value)")
        failed += 1
    }
}

// MARK: - Tests: should transform

print("-- should transform --")

// Real pattern from trainerbase-mobile/HomeInteractor.swift
test(
    "plain parameter — subscribe trailing closure",
    input:    ".subscribe { response in",
    expected: ".subscribe { @Sendable response in"
)
test(
    "subscribe void — underscore",
    input:    ".subscribe { _ in",
    expected: ".subscribe { @Sendable _ in"
)


// Other common forms
test(
    "typed parameter",
    input:    ".map { (value: Int) in",
    expected: ".map { @Sendable (value: Int) in"
)
test(
    "multiple captures",
    input:    ".map { [weak self, unowned coordinator] value in",
    expected: ".map { [weak self, unowned coordinator] @Sendable value in"
)

// MARK: - Tests: should NOT transform

print()
print("-- should NOT transform --")

// onSuccess: and onFailure: labeled closures are excluded
testNoChange(
    "onSuccess: labeled closure — plain parameter",
    input: ".subscribe(onSuccess: { clients in"
)
testNoChange(
    "onSuccess: labeled closure — long name",
    input: ".subscribe(onSuccess: { currentSubscription in"
)
testNoChange(
    "onSuccess: labeled closure — with chain",
    input: ".observe(on: MainScheduler.instance).subscribe(onSuccess: { updatedEvent in"
)
testNoChange(
    "onSuccess: labeled closure — [weak self]",
    input: ".subscribe(onSuccess: { [weak self] customerInfo in"
)
testNoChange(
    "onFailure: labeled closure — plain parameter",
    input: "}, onFailure: { error in"
)
testNoChange(
    "onFailure: trailing closure syntax",
    input: "} onFailure: { error in"
)
testNoChange(
    "onFailure: labeled closure — [weak self]",
    input: "}, onFailure: { [weak self] error in"
)
testNoChange(
    "fromAsync closure — capture list only",
    input: "Single<[Client]>.fromAsync { [clientsService] in"
)
testNoChange(
    "fromAsync closure — no capture list",
    input: "Single<Void>.fromAsync { in"
)

// Already annotated — idempotency
testNoChange(
    "already has @Sendable — no capture list",
    input: ".map { @Sendable value in"
)
testNoChange(
    "already has @Sendable — with capture list",
    input: ".map { [weak self] @Sendable value in"
)
testNoChange(
    "already has @Sendable — capture list only",
    input: "Single<Void>.fromAsync { [userService] @Sendable in"
)

// Shorthand closures — no `in`, cannot be annotated
testNoChange(
    "shorthand closure — $0",
    input: "self.clients.first(where: { Int($0.id) == id })"
)
testNoChange(
    "shorthand closure — expression body",
    input: ".map { $0.name }"
)

// Block openers that are not closures
testNoChange(
    "class declaration",
    input: "final class ClientsListInteractor: BaseInteractor<ClientsListPresentable> {"
)
testNoChange(
    "function declaration",
    input: "private func fetchClients(withQuery query: String? = nil) {"
)
testNoChange(
    "if statement",
    input: "if clients.isEmpty {"
)
testNoChange(
    "guard statement",
    input: "guard let self = self else {"
)
testNoChange(
    "for-in loop",
    input: "for client in clients {"
)
testNoChange(
    "function body brace followed by call on next line",
    input: "func presentEmptyState() {\n    internalView.renderEmptyStateMessage(\"Add payments here to track when clients are due.\")\n}"
)
testNoChange(
    "function body brace — no content on same line as brace",
    input: "func doSomething() {"
)

// MARK: - Tests: script adds ONLY @Sendable — no capture list injection

print()
print("-- adds @Sendable only, nothing else --")

// These verify the script never injects [weak self] or any other capture.
test(
    "no [weak self] added to plain closure",
    input:    ".map { customerInfo in",
    expected: ".map { @Sendable customerInfo in"
)
testNoChange(
    "no [weak self] added to fromAsync closure",
    input: "Single<Void>.fromAsync { [userService] in"
)
test(
    "existing [weak self] preserved exactly",
    input:    ".subscribe { [weak self] info in",
    expected: ".subscribe { [weak self] @Sendable info in"
)

// MARK: - Tests: file import guard

print()
print("-- file import guard --")

testBool(
    "processes files with import RxSwift",
    value:    shouldProcessFile(text: "import UIKit\nimport RxSwift\nimport RIBs\n"),
    expected: true
)
testBool(
    "processes files with import RxRelay",
    value:    shouldProcessFile(text: "import RxRelay\n"),
    expected: true
)
testBool(
    "skips files with neither import",
    value:    shouldProcessFile(text: "import UIKit\nimport Foundation\n"),
    expected: false
)
testBool(
    "skips files with only import RIBs",
    value:    shouldProcessFile(text: "import RIBs\nimport UIKit\n"),
    expected: false
)
testBool(
    "skips Pods files even with import RxSwift",
    value:    shouldProcessFile(path: "/project/Pods/RxRelay/Observable+Bind.swift", text: "import RxSwift\n"),
    expected: false
)
testBool(
    "skips nested Pods path",
    value:    shouldProcessFile(path: "/project/Pods/RxSwift/RxSwift/Observable.swift", text: "import RxSwift\n"),
    expected: false
)

// MARK: - Tests: idempotency

print()
print("-- idempotency --")

let cases = [
    ".subscribe { response in",
    ".subscribe { _ in",
    ".map { value in",
    ".filter { item in",
]
for input in cases {
    let oncePassed = transform(input)
    let twicePassed = transform(oncePassed)
    test(
        "idempotent: \(input.debugDescription)",
        input:    twicePassed,
        expected: oncePassed
    )
}

// MARK: - Summary

print()
let total = passed + failed
print("\(total) test(s): \(passed) passed, \(failed) failed")
if failed > 0 { exit(1) }
