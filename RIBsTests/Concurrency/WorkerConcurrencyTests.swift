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

import XCTest
@testable import RIBs

final class WorkerConcurrencyTests: XCTestCase {

    func test_isStartedSequence_emitsCurrentValueAndChanges() async {
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

    func test_isStartedSequence_completesWhenWorkerDeinitializes() async {
        var worker: Worker? = Worker()
        var iterator = worker?.isStartedSequence.makeAsyncIterator()

        let initialValue = await iterator?.next()
        worker = nil
        let completedValue = await iterator?.next()

        XCTAssertEqual(initialValue, false)
        XCTAssertNil(completedValue)
    }

    func test_taskOnStop_cancelsTaskWhenWorkerStops() async {
        let interactor = Interactor()
        let worker = Worker()
        let taskCancelled = expectation(description: "Task cancelled")
        interactor.activate()
        worker.start(interactor)

        let task = worker.taskOnStop {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        XCTAssertFalse(task.isCancelled)

        worker.stop()
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_taskOnStop_cancelsImmediatelyWhenWorkerIsStopped() async {
        let worker = Worker()
        let taskCancelled = expectation(description: "Task cancelled")

        let task = worker.taskOnStop {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_throwingTaskOnStop_cancelsTaskWhenWorkerStops() async {
        let interactor = Interactor()
        let worker = Worker()
        interactor.activate()
        worker.start(interactor)

        let task = worker.throwingTaskOnStop {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        XCTAssertFalse(task.isCancelled)

        worker.stop()

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

    func test_throwingTaskOnStop_cancelsImmediatelyWhenWorkerIsStopped() async {
        let worker = Worker()

        let task = worker.throwingTaskOnStop {
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

    func test_taskOnStop_cancelsTaskWhenWorkerDeinitializes() async {
        let interactor = Interactor()
        var worker: Worker? = Worker()
        let taskCancelled = expectation(description: "Task cancelled")
        interactor.activate()
        worker?.start(interactor)

        let task = worker!.taskOnStop {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        XCTAssertFalse(task.isCancelled)

        worker = nil
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_throwingTaskOnStop_cancelsTaskWhenWorkerDeinitializes() async {
        let interactor = Interactor()
        var worker: Worker? = Worker()
        interactor.activate()
        worker?.start(interactor)

        let task = worker!.throwingTaskOnStop {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        XCTAssertFalse(task.isCancelled)

        worker = nil

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
