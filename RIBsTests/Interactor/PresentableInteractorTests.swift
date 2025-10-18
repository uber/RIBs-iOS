//
//  PresentableInteractorTests.swift
//  RIBs
//
//  Created by Alex Bush on 6/23/25.
//

@testable import RIBs
import XCTest
import RxSwift

protocol MockPresentableListener: AnyObject {
    
}

protocol TestPresenter: Presentable where Listener == MockPresentableListener {}

final class PresenterMock: TestPresenter {
    nonisolated(unsafe) weak var listener: MockPresentableListener?
}

final class PresentableInteractorTests: XCTestCase {
    
    private var interactor: PresentableInteractor<PresenterMock>!
    
    override func setUp() {
        super.setUp()
    
    }
    
    func test_deinit_doesNotLeakPresenter() {
        // given
        let presenterMock = PresenterMock()
        let disposeBag = DisposeBag()
        interactor = PresentableInteractor<PresenterMock>(presenter: presenterMock)
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
