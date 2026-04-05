#!/usr/bin/env swift
//
// add_sendable_to_rxswift_closures.swift
//
// Heuristic script: adds @Sendable to explicit-parameter closures in Swift files
// that import RxSwift or RxRelay.
//
// Background
// ----------
// Swift 6 strict concurrency requires closures passed to RxSwift operators (map,
// filter, subscribe, etc.) to be marked @Sendable. This script inserts @Sendable
// into the closure header automatically for the common forms:
//
//   .map { value in ... }               ->  .map { @Sendable value in ... }
//   .map { (value: T) in ... }          ->  .map { @Sendable (value: T) in ... }
//   .map { [weak self] value in ... }   ->  .map { [weak self] @Sendable value in ... }
//   .subscribe(onNext: { _ in ... })    ->  .subscribe(onNext: { @Sendable _ in ... })
//
// Limitations
// -----------
// - Shorthand closures ($0, $1) have no explicit parameter list and cannot be
//   annotated automatically. Rewrite them with explicit parameters first; the
//   Swift compiler will identify every remaining site.
// - Multi-line closures where the parameter list is on a different line from the
//   opening { are not matched and must be fixed manually.
// - @Sendable is inserted in ALL eligible closures in files that import RxSwift,
//   not only those inside RxSwift operator calls. This is generally harmless —
//   an unnecessary @Sendable is not an error — but review the diff carefully.
//
// Usage
// -----
//   swift tooling/add_sendable_to_rxswift_closures.swift              # whole repo
//   swift tooling/add_sendable_to_rxswift_closures.swift path/to/src  # subtree
//
// After running, review every change with `git diff` before committing.

import Foundation

// Matches a closure opening brace followed by an optional capture list, on the
// condition that @Sendable is not already present and that the word `in` appears
// before the next brace or newline (distinguishing closures from plain block
// openers like `if condition {` or `class Foo {`).
//
// Group 1 captures: optional whitespace + optional [capture-list] + optional
// whitespace, so we can re-emit it verbatim and insert @Sendable afterwards.
let patternString = #"(?<!onSuccess: )(?<!onFailure: )(?<!fromAsync )\{(\h*+(?:\[[^\]]*\]\h*+)?+)(?!\h*@Sendable\b)(?=[^\n{}]*\bin\b)"#

guard let regex = try? NSRegularExpression(pattern: patternString) else {
    fputs("error: failed to compile regex\n", stderr)
    exit(1)
}

func transform(_ text: String) -> String {
    let range = NSRange(text.startIndex..., in: text)
    let matches = regex.matches(in: text, range: range)
    guard !matches.isEmpty else { return text }

    // Process in reverse order to preserve string offsets as we mutate.
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

func processFile(at url: URL) -> Bool {
    guard !url.path.contains("/Pods/") else { return false }
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
    guard text.contains("import RxSwift") || text.contains("import RxRelay") else { return false }

    let updated = transform(text)
    guard updated != text else { return false }

    do {
        try updated.write(to: url, atomically: true, encoding: .utf8)
        return true
    } catch {
        fputs("error: could not write \(url.path): \(error)\n", stderr)
        return false
    }
}

let rootPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath
let rootURL = URL(fileURLWithPath: rootPath)

guard FileManager.default.fileExists(atPath: rootPath) else {
    fputs("error: path does not exist: \(rootPath)\n", stderr)
    exit(1)
}

let enumerator = FileManager.default.enumerator(
    at: rootURL,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
)

var changed: [URL] = []
while let fileURL = enumerator?.nextObject() as? URL {
    guard fileURL.pathExtension == "swift" else { continue }
    if processFile(at: fileURL) {
        changed.append(fileURL)
    }
}

if changed.isEmpty {
    print("No files modified.")
} else {
    print("Modified \(changed.count) file(s):")
    for url in changed.sorted(by: { $0.path < $1.path }) {
        print("  \(url.path)")
    }
    print()
    print("Next steps:")
    print("  1. Review changes:     git diff")
    print("  2. Build the project — the compiler will surface any remaining sites,")
    print("     including shorthand closures ($0/$1) that need explicit parameters")
    print("     before @Sendable can be applied.")
    print("  3. Commit when satisfied.")
}
