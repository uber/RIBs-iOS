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
import XCTest
@testable import RIBs

final class RouterMock: Routing {
    
    var interactable: Interactable
    
    var children: [Routing]

    init(interactor: Interactable) {
        self.interactable = interactor
        self.children = []
    }
    
    var attachChildCallCount = 0
    func attachChild(_ child: Routing) {
        attachChildCallCount += 1
    }
    
    var detachChildCallCount = 0
    func detachChild(_ child: Routing) {
        detachChildCallCount += 1
    }
    
    var lifecycle: Observable<RouterLifecycle> {
        return Observable.just(.didLoad)
    }
    
    var loadCallCount = 0
    func load() {
        loadCallCount += 1
    }
}

@MainActor
final class RouterTests: XCTestCase {

    private var router: Router<Interactable>!
    private var lifecycleDisposable: Disposable = Disposables.create()
    private var leakDetectorMock: LeakDetectorMock = LeakDetectorMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        leakDetectorMock = LeakDetectorMock()
        LeakDetector.setInstance(leakDetectorMock)

    }

    override func tearDown() {
        super.tearDown()

        lifecycleDisposable.dispose()
    }

    // MARK: - Tests

    func test_load_verifyLifecycleObservable() async {
        router = Router(interactor: InteractableMock())
        var currentLifecycle: RouterLifecycle?
        var didComplete = false
        lifecycleDisposable = router
            .lifecycle
            .subscribe(onNext: { lifecycle in
                currentLifecycle = lifecycle
            }, onCompleted: {
                currentLifecycle = nil
                didComplete = true
            })

        XCTAssertNil(currentLifecycle)
        XCTAssertFalse(didComplete)

        router.load()

        XCTAssertEqual(currentLifecycle, RouterLifecycle.didLoad)
        XCTAssertFalse(didComplete)

        router = nil

        XCTAssertNil(currentLifecycle)
        XCTAssertTrue(didComplete)
    }
    
    func test_attachChild() {
        // given
        router = Router(interactor: InteractableMock())
        let mockChildInteractor = InteractableMock()
        let mockChildRouter = RouterMock(interactor: mockChildInteractor)

        // when
        router.attachChild(mockChildRouter)
        
        // then
        XCTAssertEqual(router.children.count, 1)
        XCTAssertEqual(mockChildInteractor.activateCallCount, 1)
        XCTAssertEqual(mockChildRouter.loadCallCount, 1)
    }
    
    func test_attachChild_activatesSubtreeOfTheChild() {
        // given
        router = Router(interactor: InteractableMock())
        let childInteractor = InteractableMock()
        let childRouter = Router(interactor: childInteractor)
        let grandChildInteractor = InteractableMock()
        let grandChildRouter = RouterMock(interactor: grandChildInteractor)
        childRouter.attachChild(grandChildRouter)
        router.load()

        // when
        router.attachChild(childRouter)
        
        // then
        XCTAssertEqual(grandChildInteractor.activateCallCount, 1)
        XCTAssertEqual(grandChildRouter.loadCallCount, 1)
    }
    
    func test_detachChild() {
        // given
        router = Router(interactor: InteractableMock())
        let mockChildInteractor = InteractableMock()
        let mockChildRouter = RouterMock(interactor: mockChildInteractor)
        router.attachChild(mockChildRouter)

        // when
        router.detachChild(mockChildRouter)
        
        // then
        XCTAssertEqual(router.children.count, 0)
        XCTAssertEqual(mockChildInteractor.deactivateCallCount, 1)
    }
   
    func test_detachChild_deactivatesSubtreeOfTheChild() async {
        // given
        router = Router(interactor: InteractableMock())
        let childInteractor = Interactor()
        let childRouter = Router(interactor: childInteractor)
        let grandChildInteractor = InteractableMock()
        let grandChildRouter = RouterMock(interactor: grandChildInteractor)
        router.load()
        router.attachChild(childRouter)
        childRouter.attachChild(grandChildRouter)
        grandChildInteractor.isActive = true
        
        // when
        router.detachChild(childRouter)
        
        // then
        XCTAssertEqual(grandChildInteractor.deactivateCallCount, 1)
    }

    func test_deinit_triggers_leakDetection() async {
        // given
        let interactor = InteractableMock()
        router = Router(interactor: interactor)
        router.load()
        // when
        router = nil
        // then
        XCTAssertEqual(leakDetectorMock.expectDeallocateCallCount, 1)
    }
}
