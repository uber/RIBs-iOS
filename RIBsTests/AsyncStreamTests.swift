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

final class AsyncStreamTests: XCTestCase {

    func test_observableAsAsyncStream_emitsValuesAndCompletes() async {
        var iterator = Observable.from([1, 2]).asAsyncStream().makeAsyncIterator()

        let firstValue = await iterator.next()
        let secondValue = await iterator.next()
        let completedValue = await iterator.next()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 2)
        XCTAssertNil(completedValue)
    }

    func test_observableAsAsyncThrowingStream_throwsOnError() async {
        var iterator = Observable<Int>
            .error(AsyncStreamTestError.error)
            .asAsyncThrowingStream()
            .makeAsyncIterator()

        do {
            _ = try await iterator.next()
            XCTFail("Expected async sequence to throw")
        } catch AsyncStreamTestError.error {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_interactorIsActiveSequence_emitsCurrentValueAndChanges() async {
        let interactor = Interactor()
        var iterator = interactor.isActiveSequence.makeAsyncIterator()

        let initialValue = await iterator.next()
        interactor.activate()
        let activeValue = await iterator.next()
        interactor.deactivate()
        let inactiveValue = await iterator.next()

        XCTAssertEqual(initialValue, false)
        XCTAssertEqual(activeValue, true)
        XCTAssertEqual(inactiveValue, false)
    }

    func test_workerIsStartedSequence_emitsCurrentValueAndChanges() async {
        let interactor = Interactor()
        let worker = Worker()
        var iterator = worker.isStartedSequence.makeAsyncIterator()

        let initialValue = await iterator.next()
        interactor.activate()
        worker.start(interactor)
        let startedValue = await iterator.next()
        worker.stop()
        let stoppedValue = await iterator.next()

        XCTAssertEqual(initialValue, false)
        XCTAssertEqual(startedValue, true)
        XCTAssertEqual(stoppedValue, false)
    }

    func test_routerLifecycleSequence_emitsDidLoad() async {
        let router = Router(interactor: Interactor())
        var iterator = router.lifecycleSequence.makeAsyncIterator()
        let lifecycleTask = Task {
            await iterator.next()
        }

        router.load()
        let lifecycle = await lifecycleTask.value

        XCTAssertEqual(lifecycle, .didLoad)
    }

    func test_stepAsAsyncSequence_emitsStepOutput() async throws {
        let workflow = Workflow<String>()
        let step = workflow
            .onStep { actionableItem in
                Observable.just((actionableItem.count, actionableItem))
            }
        let sequence = step.asAsyncSequence()
        let stepTask = Task { () -> (Int, String)? in
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next()
        }

        _ = workflow.subscribe("test")
        let value = try await stepTask.value

        XCTAssertEqual(value?.0, 4)
        XCTAssertEqual(value?.1, "test")
    }

    func test_onAsyncStep_emitsAsyncResult() async throws {
        let workflow = Workflow<Int>()
        let step = workflow
            .onStep { actionableItem in
                Observable.just((actionableItem, actionableItem))
            }
            .onAsyncStep { actionableItem, value in
                return (actionableItem + 1, value + 2)
            }
        let sequence = step.asAsyncSequence()
        let stepTask = Task { () -> (Int, Int)? in
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next()
        }

        _ = workflow.subscribe(1)
        let value = try await stepTask.value

        XCTAssertEqual(value?.0, 2)
        XCTAssertEqual(value?.1, 3)
    }
}

private enum AsyncStreamTestError: Error {
    case error
}
