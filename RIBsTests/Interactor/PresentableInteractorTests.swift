//
//  PresentableInteractorTests.swift
//  RIBs
//
//  Created by Alex Bush on 6/23/25.
//

@testable import RIBs
import XCTest
import RxSwift

protocol TestPresenter {}

final class PresenterMock: TestPresenter {}

@MainActor
final class PresentableInteractorTests: XCTestCase {
    
    private var interactor: PresentableInteractor<TestPresenter>!
    
    override func setUp() {
        super.setUp()
    
    }
    
    func test_deinit_doesNotLeakPresenter() async {
        // given
        let presenterMock = PresenterMock()
        let disposeBag = DisposeBag()
        interactor = PresentableInteractor<TestPresenter>(presenter: presenterMock)
        var status: LeakDetectionStatus = .DidComplete
        LeakDetector.instance.status.subscribe { newStatus in
            status = newStatus
        }.disposed(by: disposeBag)

        // when
        interactor = nil
        // then
        XCTAssertEqual(status, .InProgress)
    }
}
