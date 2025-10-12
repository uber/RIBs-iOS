//
//  ViewableRouterTests.swift
//  RIBs
//
//  Created by Alex Bush on 7/26/25.
//

import RxSwift
import XCTest
@testable import RIBs
import CwlPreconditionTesting


@MainActor
final class ViewControllerMock: ViewControllable {
    
    var uiviewController: UIViewController {
        return UIViewController()
    }
}

final class ViewableRouterTests: XCTestCase {

    private var router: ViewableRouter<PresentableInteractor<PresenterMock>, ViewControllerMock>!
    private var leakDetectorMock: LeakDetectorMock = LeakDetectorMock()

    override func setUp() {
        super.setUp()

        leakDetectorMock = LeakDetectorMock()
        LeakDetector.setInstance(leakDetectorMock)
    }

    func test_leakDetection() {
        // given
        let interactor = PresentableInteractor(presenter: PresenterMock())
        let viewController = ViewControllerMock()
        router = ViewableRouter(interactor: interactor, viewController: viewController)
        router.load()

        let disappearExpectation = self.expectation(description: "Wait for view controller to disappear")

        leakDetectorMock.onViewControllerDisappearCalled = { [weak leakDetectorMock] in
            if leakDetectorMock?.expectViewControllerDisappearCallCount == 1 {
                disappearExpectation.fulfill()
            }
        }

        // when
        interactor.deactivate()

        // then
        wait(for: [disappearExpectation], timeout: 2.0)
    }
    
    func test_deinit_triggers_leakDetection() {
        // given
        let interactor = PresentableInteractor(presenter: PresenterMock())
        let viewController = ViewControllerMock()
        router = ViewableRouter(interactor: interactor, viewController: viewController)
        router.load()
        // when
        let deallocationExpectation = self.expectation(description: "Expect deallocate to be called twice")
        
        leakDetectorMock.onDeallocateCalled = { [weak leakDetectorMock] in
            
            if leakDetectorMock?.expectDeallocateCallCount == 2 {
                deallocationExpectation.fulfill()
            }
        }
        
        // when
        router = nil
        
        // then
        wait(for: [deallocationExpectation], timeout: 5.0)
    }
}
