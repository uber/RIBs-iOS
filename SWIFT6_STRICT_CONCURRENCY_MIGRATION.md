# Migrating to Swift 6 Strict Concurrency with RIBs

This guide covers what you need to do (if anything) when adopting Swift 6 and/or stricter concurrency settings in a project that uses RIBs.

## Context

The RIBs framework has always operated on the main thread at runtime. This release makes that explicit at the type system level by annotating all core framework types with `@MainActor`. For most existing projects this is a transparent, non-breaking change. For projects moving to Swift 6, the path depends on your default isolation setting.

## Requirements

`isolated deinit` — used in `Interactor`, `PresentableInteractor`, `Router`, `ViewableRouter`, and `Worker` — requires **Xcode 26.2 / Swift 6.2**. The rest of the `@MainActor` annotations are compatible with earlier toolchains. Apple requires apps submitted to the App Store to be built with Xcode 26 starting April 28, 2026 ([Apple's developer news](https://developer.apple.com/news/?id=ueeok6yw), more details [here](https://developer.apple.com/app-store/submitting/)). 

## Compatibility at a glance

| Swift | Default isolation | Strictness | What you need to do |
|---|---|---|---|
| 5 | nonisolated | Minimal | Nothing |
| 5 | nonisolated | Targeted | Nothing |
| 5 | nonisolated | Complete | Nothing |
| 5 | `@MainActor` | Minimal | Nothing |
| 5 | `@MainActor` | Targeted | Nothing |
| 5 | `@MainActor` | Complete | Nothing |
| 6 | nonisolated | Minimal | ❌ Not supported — see below |
| 6 | nonisolated | Targeted | ❌ Not supported — see below |
| 6 | nonisolated | Complete | ❌ Not supported — see below |
| 6 | `@MainActor` | Minimal | Switch to `@MainActor` default + handle RxSwift caveat |
| 6 | `@MainActor` | Targeted | Switch to `@MainActor` default + handle RxSwift caveat |
| 6 | `@MainActor` | Complete | Switch to `@MainActor` default + handle RxSwift caveat |

---

## Swift 5 (all configurations)

No action required. `@MainActor` annotations on library types are additive and fully source-compatible. Your existing RIB subclasses compile and behave identically.

---

## Swift 6 + `nonisolated` default (not supported)

When your project uses Swift 6 with `nonisolated` as the default isolation, your own types are implicitly `nonisolated`. Subclassing or conforming to `@MainActor`-annotated framework types produces actor isolation mismatch compile errors throughout your RIB code. This configuration is not supported.

**Your options:**

1. **Stay on Swift 5** — fully supported in all configurations, no code changes needed.
2. **Switch to Swift 6 with `@MainActor` default isolation** — the supported path for Swift 6 users (see next section).
3. **Stay on Swift 6 with `nonisolated` default and add explicit `@MainActor` annotations throughout your RIB code** — if switching your entire project's default isolation is not feasible, you can keep `nonisolated` as the default and manually annotate your code to satisfy the compiler. This goes beyond just annotating RIB subclasses — you will also need to annotate the protocols your app defines (presentable listener protocols, interactor listener protocols, routing protocols, etc.) and potentially other types that interact with RIBs at isolation boundaries. The exact scope of changes depends on your codebase. This path is possible but is left to you to work through; the compiler will guide you to every site that needs attention.

---

## Swift 6 + `@MainActor` default isolation

This is the target configuration. With `@MainActor` as your project's default isolation, your own types are also implicitly `@MainActor`, aligning with the framework. This is how brand new projects with Xcode 26+ are set up by default.

### Enabling it

In your Xcode project's build settings:

- **Swift Language Version:** Swift 6
- **Swift Compiler — Upcoming Features / Strict Concurrency:** your choice of Minimal, Targeted, or Complete — all work
- **Default Actor Isolation:** `@MainActor`
  (`-default-isolation MainActor` in `OTHER_SWIFT_FLAGS` if setting manually)

### Your RIB subclasses

Your custom `Interactor`, `Router`, `Builder`, `Worker`, and `Presenter` subclasses inherit `@MainActor` isolation through the base classes. No annotation needed in most cases.

### Services and injected dependencies

Anything passed into a RIB via constructor injection through a `Component` must be compatible with `@MainActor`:

- Types that are themselves `@MainActor` — no changes needed
- Types that are `Sendable` — no changes needed
- Types that do background work — mark them `nonisolated` where appropriate, or use `async`/`await` to cross actor boundaries explicitly

### `deinit` in your own RIB subclasses

If you have custom `deinit` implementations that access `@MainActor`-isolated state, mark them `isolated deinit` (Xcode 26.2 / Swift 6.2 required):

```swift
final class MyInteractor: PresentableInteractor<MyPresentable> {
    isolated deinit {
        // safe to access @MainActor state here
        someMainActorResource.cleanup()
    }
}
```

If you are on an earlier toolchain temporarily, `nonisolated(unsafe)` is a stopgap, but migrate to `isolated deinit` as soon as your toolchain supports it.

---

## RxSwift `@Sendable` caveat (Swift 6 only)

With Swift 6 enabled, closures passed to RxSwift operators (`map`, `filter`, `flatMap`, `subscribe`, etc.) must be `@Sendable` or you will encounter a runtime crash. This is a known RxSwift limitation ([ReactiveX/RxSwift#2639](https://github.com/ReactiveX/RxSwift/pull/2639)) that predates and is independent of these RIBs changes.

**Option A — annotate affected closures:**

```swift
observable
    .map { @Sendable value in transform(value) }
    .subscribe(onNext: { @Sendable value in handle(value) })
```

**Option B — migrate to async/await:**

RIBs now fully supports async/await at the type system level. The standard bridging pattern for one-shot async work is:

```swift
Single<MyResult>.create { single in
    Task {
        do {
            let result = try await myAsyncFunction()
            single(.success(result))
        } catch {
            single(.failure(error))
        }
    }
    return Disposables.create()
}
.observe(on: MainScheduler.instance)
.subscribe(onSuccess: { [weak self] result in
    self?.handle(result)
})
.disposeOnDeactivate(interactor: self)
```

Additional async/await convenience utilities are planned as a follow-up release, making this pattern even more concise.

---

## Summary

| Scenario | Action |
|---|---|
| Staying on Swift 5 | Nothing — fully compatible |
| Moving to Swift 6, keeping `nonisolated` default | Not supported without changes; annotate each RIB subclass explicitly with `@MainActor`, or switch to `@MainActor` default |
| Moving to Swift 6, switching to `@MainActor` default | Enable `@MainActor` default isolation; handle RxSwift `@Sendable` if using RxSwift |
| Custom `deinit` accessing main-actor state | Use `isolated deinit` (Xcode 26.2+) |
