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

final class InteractorConcurrencyTests: XCTestCase {

    func test_isActiveSequence_emitsCurrentValueAndChanges() async {
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

    func test_isActiveSequence_completesWhenInteractorDeinitializes() async {
        var interactor: Interactor? = Interactor()
        var iterator = interactor?.isActiveSequence.makeAsyncIterator()

        let initialValue = await iterator?.next()
        interactor = nil
        let completedValue = await iterator?.next()

        XCTAssertEqual(initialValue, false)
        XCTAssertNil(completedValue)
    }

    func test_asyncSequenceConfineTo_onlyEmitsValueWhenInteractorIsActive() async throws {
        let interactor = Interactor()
        var sourceContinuation: AsyncStream<Int>.Continuation!
        let source = AsyncStream<Int> { continuation in
            sourceContinuation = continuation
        }
        let activeExpectation = expectation(
            description: "Should emit when interactor is active"
        )

        var receivedValue: Int?

        let task = Task {
            var iterator = source.confineTo(interactor).makeAsyncIterator()

            while let value = try await iterator.next() {
                receivedValue = value

                if value == 2 {
                    activeExpectation.fulfill()
                    break
                }
            }
        }

        sourceContinuation.yield(1)

        interactor.activate()
        sourceContinuation.yield(2)

        await fulfillment(of: [activeExpectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, 2)
        task.cancel()
        sourceContinuation.finish()
    }

    func test_asyncSequenceConfineTo_throwsWhenBaseSequenceThrows() async {
        let interactor = Interactor()
        let source = AsyncThrowingStream<Int, Error> { continuation in
            continuation.finish(throwing: InteractorConcurrencyTestError.error)
        }
        var iterator = source.confineTo(interactor).makeAsyncIterator()

        do {
            _ = try await iterator.next()
            XCTFail("Expected confined async sequence to throw")
        } catch InteractorConcurrencyTestError.error {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_asyncSequenceConfineTo_yieldsLatestElementAfterBaseSequenceCompletes() async throws {
        let interactor = Interactor()
        var sourceContinuation: AsyncStream<Int>.Continuation?
        let source = AsyncStream<Int> { continuation in
            sourceContinuation = continuation
        }
        var iterator = source.confineTo(interactor).makeAsyncIterator()
        let valueReceived = expectation(description: "Value received")
        var receivedValue: Int?

        let valueTask = Task {
            receivedValue = try await iterator.next()
            valueReceived.fulfill()
        }
        sourceContinuation?.yield(1)
        sourceContinuation?.finish()
        interactor.activate()
        await fulfillment(of: [valueReceived], timeout: 1)
        try await valueTask.value

        XCTAssertEqual(receivedValue, 1)
    }

    func test_taskOnDeactivate_cancelsTaskWhenInteractorDeactivates() async {
        let interactor = Interactor()
        interactor.activate()
        let taskCancelled = expectation(description: "Task cancelled")

        let task = interactor.taskOnDeactivate {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        XCTAssertFalse(task.isCancelled)

        interactor.deactivate()
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_taskOnDeactivate_cancelsImmediatelyWhenInteractorIsInactive() async {
        let interactor = Interactor()
        let taskCancelled = expectation(description: "Task cancelled")

        let task = interactor.taskOnDeactivate {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_throwingTaskOnDeactivate_cancelsTaskWhenInteractorDeactivates() async {
        let interactor = Interactor()
        interactor.activate()

        let task = interactor.throwingTaskOnDeactivate {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        XCTAssertFalse(task.isCancelled)

        interactor.deactivate()

        do {
            try await task.value
            XCTFail("Expected task to throw CancellationError")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(task.isCancelled)
    }

    func test_throwingTaskOnDeactivate_cancelsImmediatelyWhenInteractorIsInactive() async {
        let interactor = Interactor()

        let task = interactor.throwingTaskOnDeactivate {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }

        do {
            try await task.value
            XCTFail("Expected task to throw CancellationError")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(task.isCancelled)
    }

    func test_taskOnDeactivate_cancelsTaskWhenInteractorDeinitializes() async {
        var interactor: Interactor? = Interactor()
        interactor?.activate()
        let taskCancelled = expectation(description: "Task cancelled")

        let task = interactor!.taskOnDeactivate {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        XCTAssertFalse(task.isCancelled)

        interactor = nil
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_throwingTaskOnDeactivate_cancelsTaskWhenInteractorDeinitializes() async {
        var interactor: Interactor? = Interactor()
        interactor?.activate()

        let task = interactor!.throwingTaskOnDeactivate {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        XCTAssertFalse(task.isCancelled)

        interactor = nil

        do {
            try await task.value
            XCTFail("Expected task to throw CancellationError")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(task.isCancelled)
    }
}

private enum InteractorConcurrencyTestError: Error {
    case error
}
