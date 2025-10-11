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
final class ViewControllerMock: @MainActor ViewControllable {
    
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
        // when
        interactor.deactivate()
        // then
        XCTAssertEqual(leakDetectorMock.expectViewControllerDisappearCallCount, 1)
    }

    func test_deinit_triggers_leakDetection() {
        // given
        let interactor = PresentableInteractor(presenter: PresenterMock())
        let viewController = ViewControllerMock()
        router = ViewableRouter(interactor: interactor, viewController: viewController)
        router.load()
        // when
        router = nil
        // then
        XCTAssertEqual(leakDetectorMock.expectDeallocateCallCount, 2)
    }
}
