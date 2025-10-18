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

import RxSwift

/// The base protocol for all routers that own their own view controllers.
public protocol ViewableRouting: Routing {

    // The following methods must be declared in the base protocol, since `Router` internally invokes these methods.
    // In order to unit test router with a mock child router, the mocked child router first needs to conform to the
    // custom subclass routing protocol, and also this base protocol to allow the `Router` implementation to execute
    // base class logic without error.

    /// The base view controllable associated with this `Router`.
    var viewControllable: ViewControllable { get }
}

/// The base class of all routers that owns view controllers, representing application states.
///
/// A `Router` acts on inputs from its corresponding interactor, to manipulate application state and view state,
/// forming a tree of routers that drives the tree of view controllers. Router drives the lifecycle of its owned
/// interactor. `Router`s should always use helper builders to instantiate children `Router`s.
open class ViewableRouter<InteractorType, ViewControllerType>: Router<InteractorType>, ViewableRouting {

    /// The corresponding `ViewController` owned by this `Router`.
    public let viewController: ViewControllerType

    /// The base `ViewControllable` associated with this `Router`.
    public let viewControllable: ViewControllable

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    /// - parameter viewController: The corresponding `ViewController` of this `Router`.
    public init(interactor: InteractorType, viewController: ViewControllerType) {
        self.viewController = viewController
        guard let viewControllable = viewController as? ViewControllable else {
            fatalError("\(viewController) should conform to \(ViewControllable.self)")
        }
        self.viewControllable = viewControllable

        super.init(interactor: interactor)
    }
    
    /// A helper method to safely call viewController methods for UI navigation on the main thread.
    /// When routing in RIBs that have UI (using ViewableRouter), the plumbing of routing such as clearing out
    /// child RIB references, setting them up, or attaching/detaching child routers can happen on any thread.
    /// However, the actual physical/mechanical navigation of the UI - such as pushing or popping child RIB's UI
    /// onto/off the navigation controller stack, modally presenting or dismissing it, or attaching/detaching it
    /// from the UI hierarchy via custom implementation using child containment API - must all be done on the main thread
    /// since they manipulate the UI tree and trigger UI rendering.
    /// 
    /// This method ensures that your viewController method calls run on the main thread.
    /// Use this method when you encounter compiler warnings such as:
    /// "Main actor-isolated property 'uiviewController' cannot be referenced from a nonisolated context"
    ///
    /// Example usage - routing away from child RIB:
    /// ```swift
    /// func routeAwayFromChildRIB() {
    ///     if let childRIBRouter = childRIBRouter {
    ///         self.childRIBRouter = nil
    ///         
    ///         navigateOnMainThread { thisRouterViewController in
    ///             thisRouterViewController.uiviewController.dismiss(animated: true) { [weak self] in
    ///                 self?.detachChild(childRIBRouter)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    public nonisolated func navigateOnMainThread(_ block: @escaping @MainActor (_ thisRouterViewController: ViewControllerType) -> Void) {
        nonisolated(unsafe) let thisRouterViewController = self.viewController

        Task { @MainActor in
            block(thisRouterViewController)
        }
    }
    
    /// A helper method to safely call viewController methods for UI navigation on the main thread with a child view controller.
    /// This overload provides both the current router's view controller and a child view controller to the closure,
    /// ensuring all UI operations happen on the main thread.
    /// 
    /// When routing in RIBs that have UI (using ViewableRouter), the plumbing of routing such as clearing out
    /// child RIB references, setting them up, or attaching/detaching child routers can happen on any thread.
    /// However, the actual physical/mechanical navigation of the UI - such as pushing or popping child RIB's UI
    /// onto/off the navigation controller stack, modally presenting or dismissing it, or attaching/detaching it
    /// from the UI hierarchy via custom implementation using child containment API - must all be done on the main thread
    /// since they manipulate the UI tree and trigger UI rendering.
    /// 
    /// This method ensures that your viewController method calls run on the main thread.
    /// Use this method when you encounter compiler warnings such as:
    /// "Main actor-isolated property 'uiviewController' cannot be referenced from a nonisolated context"
    /// 
    /// This is an overload of the basic `navigateOnMainThread(_:)` method that includes a child view controller parameter.
    /// Use this method when you need to perform UI navigation that involves both the current router's view controller
    /// and a child view controller, such as presenting, pushing, or custom containment operations.
    /// For navigation operations that only involve the current router's view controller, use the basic `navigateOnMainThread(_:)` method instead.
    ///
    /// Example usage - routing to child RIB:
    /// ```swift
    /// func routeToChildRIB() {
    ///     let childRIBRouter = childRIBBuilder.build(withListener: interactor)
    ///     self.childRIBRouter = childRIBRouter
    ///     navigateOnMainThread(with: childRIBRouter.viewControllable) { thisRouterViewController, childViewController in
    ///         thisRouterViewController.attachChildRIBViewController(childViewController.uiviewController)
    ///     }
    ///     attachChild(childRIBRouter)
    /// }
    /// ```
    
    public nonisolated func navigateOnMainThread(with childViewController: ViewControllable, _ block: @escaping @MainActor (_ thisRouterViewController: ViewControllerType, _ childViewController: ViewControllable) -> Void) {
        nonisolated(unsafe) let thisRouterViewController = self.viewController
        nonisolated(unsafe) let childVC = childViewController

        Task { @MainActor in
            block(thisRouterViewController, childVC)
        }
    }
    
    // MARK: - Internal

    override func internalDidLoad() {
        setupViewControllerLeakDetection()

        super.internalDidLoad()
    }

    // MARK: - Private

    private var viewControllerDisappearExpectation: LeakDetectionHandle?

    private func setupViewControllerLeakDetection() {
        
        
        let disposable = interactable.isActiveStream
            // Do not retain self here to guarantee execution. Retaining self will cause the dispose bag to never be
            // disposed, thus self is never deallocated. Also cannot just store the disposable and call dispose(),
            // since we want to keep the subscription alive until deallocation, in case the router is re-attached.
            // Using weak does require the router to be retained until its interactor is deactivated.
            .subscribe(onNext: { [weak self] (isActive: Bool) in
                guard let strongSelf = self else { return }
                nonisolated(unsafe) let `self` = strongSelf
                Task { @MainActor in
                    
                    self.viewControllerDisappearExpectation?.cancel()
                    self.viewControllerDisappearExpectation = nil
                    
                    if !isActive {
                        let viewController = self.viewControllable.uiviewController
                        self.viewControllerDisappearExpectation = LeakDetector.instance.expectViewControllerDisappear(viewController: viewController)
                        
                    }
                }
            })
        _ = deinitDisposable.insert(disposable)
    }

    deinit {
        nonisolated(unsafe) let viewControllable = self.viewControllable
        
        Task { @MainActor in
            let _ = LeakDetector.instance.expectDeallocate(object: viewControllable.uiviewController, inTime: LeakDefaultExpectationTime.viewDisappear)
        }
    }
}
