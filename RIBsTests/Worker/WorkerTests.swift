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

@testable import RIBs
import Combine
import XCTest

class WorkerTests: XCTestCase {

    private var interactor: MockInteractor!
    private var worker: MockWorker!

    override func setUp() {
        super.setUp()

        interactor = MockInteractor()
        worker = MockWorker()
    }

    func test_start_verifyInvokeDidStart() {
        interactor.activate()
        worker.start(interactor)

        XCTAssertTrue(worker.didStartCallCount == 1)
    }

    func test_start_verifySetIsStarted() {
        worker.start(interactor)

        XCTAssertTrue(worker.isStarted)
    }

    func test_start_multipleTimes_verifyOnlyInvokeOnce() {
        interactor.activate()
        worker.start(interactor)
        worker.start(interactor)

        XCTAssertTrue(worker.didStartCallCount == 1)
    }

    func test_start_whenScopeInactive_verifyNotInvokeDidStart() {
        worker.start(interactor)

        XCTAssertTrue(worker.didStartCallCount == 0)
    }

    func test_start_whenScopeInactive_thenBecomeActive_verifyInvokeDidStart() {
        worker.start(interactor)
        interactor.activate()

        XCTAssertTrue(worker.didStartCallCount == 1)
    }

    func test_start_whenScopeActive_thenBecomeInactive_verifyInvokeDidStop() {
        interactor.activate()
        worker.start(interactor)
        interactor.deactivate()

        XCTAssertTrue(worker.didStopCallCount == 1)
    }

    func test_stop_verifyInvokeDidStop() {
        interactor.activate()
        worker.start(interactor)

        worker.stop()

        XCTAssertTrue(worker.didStopCallCount == 1)
    }

    func test_stop_verifySetIsStarted() {
        interactor.activate()
        worker.start(interactor)

        worker.stop()

        XCTAssertFalse(worker.isStarted)
    }

    func test_stop_multipleTimes_verifyOnlyInvokeOnce() {
        interactor.activate()
        worker.start(interactor)

        worker.stop()
        worker.stop()

        XCTAssertTrue(worker.didStopCallCount == 1)
    }

    func test_stop_beforeStart_verifyNoOp() {
        worker.stop()

        XCTAssertTrue(worker.didStopCallCount == 0)
    }

    func test_deinit_whenStarted_verifyInvokeDidStop() {
        interactor.activate()
        worker.start(interactor)

        worker = nil

        // Cannot test didStopCallCount since the instance is deallocated.
    }
}

class MockWorker: Worker {

    var didStartCallCount = 0
    override func didStart(_ interactorScope: InteractorScope) {
        super.didStart(interactorScope)

        didStartCallCount += 1
    }

    var didStopCallCount = 0
    override func didStop() {
        super.didStop()

        didStopCallCount += 1
    }
}
