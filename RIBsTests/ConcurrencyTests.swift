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

final class ConcurrencyTests: XCTestCase {

    func test_asyncSequenceConfineTo_yieldsLatestElementWhenInteractorBecomesActive() async throws {
        let interactor = Interactor()
        var sourceContinuation: AsyncStream<Int>.Continuation?
        let source = AsyncStream<Int> { continuation in
            sourceContinuation = continuation
        }
        var iterator = source.confineTo(interactor).makeAsyncIterator()

        sourceContinuation?.yield(1)
        interactor.activate()
        let firstValue = try await iterator.next()
        sourceContinuation?.yield(2)
        let secondValue = try await iterator.next()
        interactor.deactivate()
        sourceContinuation?.yield(3)
        interactor.activate()
        let thirdValue = try await iterator.next()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 2)
        XCTAssertEqual(thirdValue, 3)
    }

    func test_taskOnDeactivate_cancelsTaskWhenInteractorDeactivates() async {
        let interactor = Interactor()
        interactor.activate()

        let task = interactor.taskOnDeactivate {
            while !Task.isCancelled {
                await Task.yield()
            }
        }
        XCTAssertFalse(task.isCancelled)

        interactor.deactivate()
        await Task.yield()

        XCTAssertTrue(task.isCancelled)
    }

    func test_taskOnDeactivate_cancelsImmediatelyWhenInteractorIsInactive() async {
        let interactor = Interactor()

        let task = interactor.taskOnDeactivate {
            while !Task.isCancelled {
                await Task.yield()
            }
        }
        await Task.yield()

        XCTAssertTrue(task.isCancelled)
    }

    func test_taskOnStop_cancelsTaskWhenWorkerStops() async {
        let interactor = Interactor()
        let worker = Worker()
        interactor.activate()
        worker.start(interactor)

        let task = worker.taskOnStop {
            while !Task.isCancelled {
                await Task.yield()
            }
        }
        XCTAssertFalse(task.isCancelled)

        worker.stop()
        await Task.yield()

        XCTAssertTrue(task.isCancelled)
    }

    func test_workflowTask_cancelsWhenWorkflowDisposableIsDisposed() async {
        let workflow = Workflow<()>()
        let task = workflow.task {
            while !Task.isCancelled {
                await Task.yield()
            }
        }
        let disposable = workflow
            .onStep { _ in
                Observable.just(((), ()))
            }
            .commit()
            .subscribe(())

        XCTAssertFalse(task.isCancelled)
        disposable.dispose()
        await Task.yield()

        XCTAssertTrue(task.isCancelled)
    }

    func test_asyncSequenceFork_createsWorkflowStep() {
        let workflow = TestWorkflow()
        let asyncSequence = AsyncStream<((), ())> { continuation in
            continuation.yield(((), ()))
            continuation.finish()
        }

        let step: Step<(), (), ()> = asyncSequence.fork(workflow)
        _ = step.commit().subscribe(())

        XCTAssertEqual(workflow.forkCallCount, 1)
        XCTAssertEqual(workflow.completeCallCount, 1)
    }
}

private class TestWorkflow: Workflow<()> {
    var completeCallCount = 0
    var forkCallCount = 0

    override func didComplete() {
        completeCallCount += 1
    }

    override func didFork() {
        forkCallCount += 1
    }
}
