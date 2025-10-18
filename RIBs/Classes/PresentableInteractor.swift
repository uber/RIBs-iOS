//
//  Copyright (c) 2017. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Base class of an `Interactor` that actually has an associated `Presenter` and `View`.
nonisolated open class PresentableInteractor<PresenterType: Presentable & SendableMetatype>: Interactor {

    /// The `Presenter` associated with this `Interactor`.
    public let presenter: PresenterType

    /// Initializer.
    ///
    /// - note: This holds a strong reference to the given `Presenter`.
    ///
    /// - parameter presenter: The presenter associated with this `Interactor`.
    public init(presenter: PresenterType) {
        self.presenter = presenter
    }
    
    
    /// A helper method to safely call presenter methods on the main thread.
    /// Use this when you encounter main actor isolation warnings when calling methods on the presenter object.
    /// All presenter methods should be executed on the main thread because they ultimately trigger UI rendering.
    /// This method captures the presenter object in a MainActor task, allowing you to safely call methods on it.
    /// The closure you pass contains the code for your custom presenter method calls, and the closure provides
    /// you with the presenter instance/reference of this interactor.
    /// 
    /// You can use this method to call presenter UI callbacks in RxSwift observable subscriptions or from Tasks.
    ///
    /// Example usage in RxSwift subscription:
    /// ```swift
    /// stream.dataObservable
    ///     .subscribe(on: backgroundScheduler)
    ///     .observe(on: MainScheduler.instance)
    ///     .subscribe(onNext: { _ in
    ///         self.presentOnMainThread { presenter in
    ///             presenter.presentStuff()
    ///         }
    ///     }).disposeOnDeactivate(interactor: self)
    /// ```
    ///
    /// Example usage in async Task:
    /// ```swift
    /// Task {
    ///     try? await Task.sleep(for: .seconds(2))
    ///     
    ///     await MainActor.run {
    ///         presenter.presentStuff()
    ///     }
    ///     
    ///     await presenter.presentStuff()
    ///     
    ///     Task { @MainActor in
    ///         presenter.presentStuff()
    ///     }
    ///     
    ///     self.presentOnMainThread { presenter in
    ///         presenter.presentStuff()
    ///     }
    /// }
    /// ```
    public nonisolated func presentOnMainThread(_ block: @escaping @MainActor (_ presenter: PresenterType) -> Void) {
        nonisolated(unsafe) let presenter = self.presenter
        
        Task { @MainActor in
            block(presenter)
        }
    }

    // MARK: - Private

    deinit {
        LeakDetector.instance.expectDeallocate(object: presenter as AnyObject)
    }
}
