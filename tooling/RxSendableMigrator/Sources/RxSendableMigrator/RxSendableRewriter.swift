import Foundation
import SwiftSyntax

final class RxSendableRewriter: SyntaxRewriter {
    let filePath: String
    let locationConverter: SourceLocationConverter
    let indexService: IndexStoreService

    // Operators whose closure parameters need @Sendable.
    // These are operators that *store* the closure and call it from RxSwift's internal
    // scheduler machinery — potentially on a different thread from where it was created.
    //
    // Excluded intentionally:
    //   subscribe / subscribeNext / subscribeError / subscribeCompleted / bind / drive —
    //     terminal consumers; by the time you subscribe you've typically already switched
    //     to the right scheduler with observe(on:), so the closure executes where expected.
    //   observeOn / subscribeOn / debounce / throttle / timeout / delay —
    //     take schedulers or time intervals, not user closures.
    //   merge / concat / switchLatest / amb / startWith / share / publish / replay /
    //   multicast / toArray / materialize / dematerialize / ignoreElements —
    //     no user-supplied transform/predicate closures.
    static let rxOperators: Set<String> = [
        // Transforming — closure is applied on the source scheduler
        "map", "compactMap",
        "flatMap", "flatMapLatest", "flatMapFirst", "flatMapWithIndex", "concatMap",
        "scan", "reduce",
        "groupBy",
        "buffer", "window",

        // Filtering / conditional — predicate is called on the source scheduler
        "filter",
        "distinctUntilChanged",
        "skipWhile", "takeWhile",
        "single",

        // Combining — result-selector closure is called on the source scheduler
        "withLatestFrom",
        "combineLatest",
        "zip",

        // Error handling — handler is called wherever the error was thrown
        "catch", "catchError", "catchErrorJustReturn",
        "retryWhen",

        // Side effects — closures fire on the source scheduler, same risk as map/filter
        "do",
    ]

    var debugFile: String?

    init(filePath: String, locationConverter: SourceLocationConverter, indexService: IndexStoreService, debugFile: String? = nil) {
        self.filePath = filePath
        self.locationConverter = locationConverter
        self.indexService = indexService
        self.debugFile = debugFile
        super.init()
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Capture the operator's source position from the ORIGINAL node before recursing.
        // super.visit() modifies children (e.g. injects @Sendable into inner closures),
        // which shifts byte offsets in the returned tree. If we read the position after
        // recursing, the shifted offset maps to the wrong line/column in SourceLocationConverter
        // (which was built from the original source).
        let originalLocation = captureLocation(of: node)

        // Recurse into children so inner operators are handled first.
        let visited = super.visit(node)
        guard let callNode = visited.as(FunctionCallExprSyntax.self) else {
            return visited
        }
        return ExprSyntax(processCall(callNode, originalLocation: originalLocation) ?? callNode)
    }

    // MARK: - Core transformation

    private struct OperatorLocation {
        let name: String
        let line: Int
        let column: Int
    }

    /// Reads the operator name and its source position from the node as it exists
    /// in the original (unmodified) source tree.
    private func captureLocation(of node: FunctionCallExprSyntax) -> OperatorLocation? {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return nil
        }
        let name = memberAccess.declName.baseName.text
        guard Self.rxOperators.contains(name) else { return nil }
        let loc = locationConverter.location(
            for: memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia
        )
        return OperatorLocation(name: name, line: loc.line, column: loc.column)
    }

    private func processCall(_ node: FunctionCallExprSyntax, originalLocation: OperatorLocation?) -> FunctionCallExprSyntax? {
        guard let loc = originalLocation else { return nil }

        if let debugFile, filePath.hasSuffix(debugFile) {
            fputs("Checking \(loc.name) at line=\(loc.line) col=\(loc.column)\n", stderr)
        }
        guard indexService.isRxSwiftCall(file: filePath, line: loc.line, column: loc.column, debugFile: debugFile) else {
            return nil
        }

        // Prefer trailing closure, then fall back to a closure nested in arguments.
        if let trailingClosure = node.trailingClosure,
           let newClosure = injectSendable(into: trailingClosure) {
            return node.with(\.trailingClosure, newClosure)
        }

        var elements = Array(node.arguments)
        for i in elements.indices {
            if let closure = elements[i].expression.as(ClosureExprSyntax.self),
               let newClosure = injectSendable(into: closure) {
                elements[i] = elements[i].with(\.expression, ExprSyntax(newClosure))
                return node.with(\.arguments, LabeledExprListSyntax(elements))
            }
        }

        return nil
    }

    // MARK: - Closure mutation

    private func injectSendable(into closure: ClosureExprSyntax) -> ClosureExprSyntax? {
        if let sig = closure.signature {
            guard !hasSendable(sig.attributes) else { return nil }
            let newSig = sig.with(\.attributes, prependSendable(to: sig.attributes))
            return closure.with(\.signature, newSig)
        } else {
            // Bare closure like `{ $0 + 1 }` — synthesize `{ @Sendable in $0 + 1 }`
            let newSig = ClosureSignatureSyntax(
                attributes: AttributeListSyntax([.attribute(makeSendableAttribute(trailingSpace: true))]),
                inKeyword: .keyword(.in, leadingTrivia: [], trailingTrivia: .space)
            )
            return closure.with(\.signature, newSig)
        }
    }

    private func prependSendable(to attrs: AttributeListSyntax) -> AttributeListSyntax {
        // @Sendable needs a trailing space to separate it from whatever follows.
        let sendable = AttributeListSyntax.Element.attribute(makeSendableAttribute(trailingSpace: true))
        return AttributeListSyntax([sendable] + Array(attrs))
    }

    private func hasSendable(_ attrs: AttributeListSyntax) -> Bool {
        attrs.contains { element in
            guard case .attribute(let attr) = element,
                  let ident = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return ident.name.text == "Sendable"
        }
    }

    private func makeSendableAttribute(trailingSpace: Bool) -> AttributeSyntax {
        AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(
                name: .identifier("Sendable", trailingTrivia: trailingSpace ? .spaces(1) : [])
            )
        )
    }
}
