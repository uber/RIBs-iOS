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

final class WorkflowConcurrencyTests: XCTestCase {

    func test_workflowTask_cancelsWhenWorkflowDisposableIsDisposed() async {
        let workflow = Workflow<()>()
        let taskCancelled = expectation(description: "Task cancelled")
        let task = workflow.task {
            while !Task.isCancelled {
                await Task.yield()
            }
            taskCancelled.fulfill()
        }
        let disposable = workflow
            .onStep { _ in
                Observable.just(((), ()))
            }
            .commit()
            .subscribe(())

        XCTAssertFalse(task.isCancelled)
        disposable.dispose()
        await fulfillment(of: [taskCancelled], timeout: 1)

        XCTAssertTrue(task.isCancelled)
    }

    func test_workflowThrowingTask_cancelsWhenWorkflowDisposableIsDisposed() async {
        let workflow = Workflow<()>()
        let task = workflow.throwingTask {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        let disposable = workflow
            .onStep { _ in
                Observable.just(((), ()))
            }
            .commit()
            .subscribe(())

        XCTAssertFalse(task.isCancelled)
        disposable.dispose()

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

        _ = step.commit()
        _ = workflow.subscribe("test")
        let value = try await stepTask.value

        XCTAssertEqual(value?.0, 4)
        XCTAssertEqual(value?.1, "test")
    }

    func test_stepAsAsyncSequence_invokesWorkflowDidComplete() async throws {
        let workflow = WorkflowConcurrencyTestWorkflow<Int>()
        let step = workflow
            .onStep { actionableItem in
                Observable.just((actionableItem, actionableItem))
            }
        let sequence = step.asAsyncSequence()
        let stepTask = Task { () -> (Int, Int)? in
            var iterator = sequence.makeAsyncIterator()
            let value = try await iterator.next()
            _ = try await iterator.next()
            return value
        }

        _ = step.commit()
        _ = workflow.subscribe(1)
        let value = try await stepTask.value

        XCTAssertEqual(value?.0, 1)
        XCTAssertEqual(value?.1, 1)
        XCTAssertEqual(workflow.completeCallCount, 1)
        XCTAssertEqual(workflow.errorCallCount, 0)
    }

    func test_stepAsAsyncSequence_invokesWorkflowDidReceiveError() async {
        let workflow = WorkflowConcurrencyTestWorkflow<Int>()
        let step = workflow
            .onStep { _ in
                Observable<(Int, Int)>.error(WorkflowConcurrencyTestError.error)
            }
        let sequence = step.asAsyncSequence()
        let stepTask = Task { () -> (Int, Int)? in
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next()
        }

        _ = step.commit()
        _ = workflow.subscribe(1)

        do {
            _ = try await stepTask.value
            XCTFail("Expected async sequence to throw")
        } catch WorkflowConcurrencyTestError.error {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(workflow.completeCallCount, 0)
        XCTAssertEqual(workflow.errorCallCount, 1)
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

        _ = step.commit()
        _ = workflow.subscribe(1)
        let value = try await stepTask.value

        XCTAssertEqual(value?.0, 2)
        XCTAssertEqual(value?.1, 3)
    }

    func test_onAsyncStep_invokesWorkflowDidReceiveError() async {
        let workflow = WorkflowConcurrencyTestWorkflow<Int>()
        let step = workflow
            .onStep { actionableItem in
                Observable.just((actionableItem, actionableItem))
            }
            .onAsyncStep { _, _ -> (Int, Int) in
                throw WorkflowConcurrencyTestError.error
            }
        let sequence = step.asAsyncSequence()
        let stepTask = Task { () -> (Int, Int)? in
            var iterator = sequence.makeAsyncIterator()
            return try await iterator.next()
        }

        _ = step.commit()
        _ = workflow.subscribe(1)

        do {
            _ = try await stepTask.value
            XCTFail("Expected async sequence to throw")
        } catch WorkflowConcurrencyTestError.error {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(workflow.completeCallCount, 0)
        XCTAssertEqual(workflow.errorCallCount, 1)
    }

    func test_onAsyncStep_cancelsTaskWhenWorkflowDisposableIsDisposed() async {
        let workflow = Workflow<()>()
        let taskStarted = expectation(description: "Async step task started")
        let taskCancelled = expectation(description: "Async step task cancelled")
        let disposable = workflow
            .onStep { _ in
                Observable.just(((), ()))
            }
            .onAsyncStep { _, _ -> ((), ()) in
                taskStarted.fulfill()
                while !Task.isCancelled {
                    await Task.yield()
                }
                taskCancelled.fulfill()
                return ((), ())
            }
            .commit()
            .subscribe(())

        await fulfillment(of: [taskStarted], timeout: 1)
        disposable.dispose()
        await fulfillment(of: [taskCancelled], timeout: 1)
    }

    func test_asyncSequenceFork_createsWorkflowStep() async {
        let workflow = WorkflowConcurrencyTestWorkflow<()>()
        let completed = expectation(description: "Workflow completed")
        workflow.onComplete = {
            completed.fulfill()
        }
        let asyncSequence = AsyncStream<((), ())> { continuation in
            continuation.yield(((), ()))
            continuation.finish()
        }

        let step: Step<(), (), ()> = asyncSequence.fork(workflow)
        _ = step.commit().subscribe(())
        await fulfillment(of: [completed], timeout: 1)

        XCTAssertEqual(workflow.forkCallCount, 1)
        XCTAssertEqual(workflow.completeCallCount, 1)
    }

    func test_asyncSequenceForkedStepAsAsyncSequence_emitsStepOutput() async throws {
        let workflow = WorkflowConcurrencyTestWorkflow<()>()
        let asyncSequence = AsyncStream<(Int, String)> { continuation in
            continuation.yield((1, "one"))
            continuation.finish()
        }

        let step: Step<(), Int, String> = asyncSequence.fork(workflow)
        let outputSequence = step.asAsyncSequence()
        var iterator = outputSequence.makeAsyncIterator()

        let value = try await iterator.next()
        let completedValue = try await iterator.next()

        XCTAssertEqual(value?.0, 1)
        XCTAssertEqual(value?.1, "one")
        XCTAssertNil(completedValue)
        XCTAssertEqual(workflow.forkCallCount, 1)
        XCTAssertEqual(workflow.completeCallCount, 0)
    }

    func test_asyncSequenceFork_nestedStepsDoNotRepeat() async {
        var outerStep1RunCount = 0
        var outerStep2RunCount = 0
        var outerStep3RunCount = 0

        let workflow = WorkflowConcurrencyTestWorkflow<()>()
        let completed = expectation(description: "Workflow completed")
        workflow.onComplete = {
            completed.fulfill()
        }
        let asyncSequence = AsyncStream<((), ())> { continuation in
            continuation.yield(((), ()))
            continuation.finish()
        }

        let step: Step<(), (), ()> = asyncSequence.fork(workflow)
        _ = step
            .onStep { _, _ -> Observable<((), ())> in
                outerStep1RunCount += 1
                return Observable.just(((), ()))
            }
            .onStep { _, _ -> Observable<((), ())> in
                outerStep2RunCount += 1
                return Observable.just(((), ()))
            }
            .onStep { _, _ -> Observable<((), ())> in
                outerStep3RunCount += 1
                return Observable.just(((), ()))
            }
            .commit()
            .subscribe(())
        await fulfillment(of: [completed], timeout: 1)

        XCTAssertEqual(outerStep1RunCount, 1, "Step 1 should not have been run more than once")
        XCTAssertEqual(outerStep2RunCount, 1, "Step 2 should not have been run more than once")
        XCTAssertEqual(outerStep3RunCount, 1, "Step 3 should not have been run more than once")
        XCTAssertEqual(workflow.completeCallCount, 1)
        XCTAssertEqual(workflow.errorCallCount, 0)
        XCTAssertEqual(workflow.forkCallCount, 1)
    }

    func test_asyncSequenceFork_workflowReceivesError() async {
        let workflow = WorkflowConcurrencyTestWorkflow<()>()
        let receivedError = expectation(description: "Workflow received error")
        workflow.onError = {
            receivedError.fulfill()
        }
        let asyncSequence = AsyncThrowingStream<((), ()), Error> { continuation in
            continuation.finish(throwing: WorkflowConcurrencyTestError.error)
        }

        let step: Step<(), (), ()> = asyncSequence.fork(workflow)
        _ = step.commit().subscribe(())
        await fulfillment(of: [receivedError], timeout: 1)

        XCTAssertEqual(workflow.completeCallCount, 0)
        XCTAssertEqual(workflow.errorCallCount, 1)
        XCTAssertEqual(workflow.forkCallCount, 1)
        guard case WorkflowConcurrencyTestError.error? = workflow.receivedError as? WorkflowConcurrencyTestError else {
            XCTFail("Expected workflow to receive WorkflowConcurrencyTestError.error")
            return
        }
    }
}

private enum WorkflowConcurrencyTestError: Error {
    case error
}

private final class WorkflowConcurrencyTestWorkflow<ActionableItemType>: Workflow<ActionableItemType> {
    var completeCallCount = 0
    var errorCallCount = 0
    var forkCallCount = 0
    var receivedError: Error?
    var onComplete: (() -> Void)?
    var onError: (() -> Void)?

    override func didComplete() {
        completeCallCount += 1
        onComplete?()
    }

    override func didFork() {
        forkCallCount += 1
    }

    override func didReceiveError(_ error: Error) {
        errorCallCount += 1
        receivedError = error
        onError?()
    }
}
