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

class WorkflowTests: XCTestCase {

    private var workflow: MockWorkflow!

    override func setUp() {
        super.setUp()

        workflow = MockWorkflow()
    }

    func test_subscribe_verifyOnStepInvocation() {
        workflow
            .onStep { (interactor: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        let interactor = Interactor()
        interactor.activate()
        workflow.subscribe(interactor)

        XCTAssertTrue(workflow.invokedStepCount == 1)
    }

    func test_multipleSteps_verifyInvocation() {
        workflow
            .onStep { (interactor: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .onStep { (interactor: Interactor, value: ()) -> AnyPublisher<(Interactor, ()), Error> in
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        let interactor = Interactor()
        interactor.activate()
        workflow.subscribe(interactor)

        XCTAssertTrue(workflow.invokedStepCount == 2)
    }

    func test_interactorInactive_verifyNoStepInvocation() {
        let interactor = Interactor()

        workflow
            .onStep { (actionableItem: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                XCTAssertTrue(actionableItem === interactor)
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        workflow.subscribe(interactor)

        XCTAssertTrue(workflow.invokedStepCount == 0)
    }

    func test_interactorActive_verifyStepInvocation() {
        let interactor = Interactor()
        interactor.activate()

        workflow
            .onStep { (actionableItem: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                XCTAssertTrue(actionableItem === interactor)
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        workflow.subscribe(interactor)

        XCTAssertTrue(workflow.invokedStepCount == 1)
    }

    func test_multipleSteps_interactorActiveOnlyAtFirstStep_verifySingleStepInvocation() {
        let interactor = Interactor()
        interactor.activate()

        workflow
            .onStep { (actionableItem: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                XCTAssertTrue(actionableItem === interactor)
                self.workflow.invokedStepCount += 1
                interactor.deactivate()
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .onStep { (actionableItem: Interactor, value: ()) -> AnyPublisher<(Interactor, ()), Error> in
                XCTFail()
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        workflow.subscribe(interactor)

        XCTAssertTrue(workflow.invokedStepCount == 1)
    }

    func test_subscription_verifyComplete() {
        workflow
            .onStep { (interactor: Interactor) -> AnyPublisher<(Interactor, ()), Error> in
                self.workflow.invokedStepCount += 1
                return Just((interactor, ())).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .commit()

        let interactor = Interactor()
        interactor.activate()
        
        let expectation = XCTestExpectation(description: "Workflow completed")
        workflow.didCompleteCallCount = 0
        workflow.didCompleteExpectation = expectation
        
        workflow.subscribe(interactor)

        wait(for: [expectation], timeout: 5)
        XCTAssertTrue(workflow.didCompleteCallCount == 1)
    }
}

fileprivate class MockWorkflow: Workflow<Interactor> {

    var invokedStepCount = 0
    var didCompleteCallCount = 0
    var didCompleteExpectation: XCTestExpectation?

    override func didComplete() {
        super.didComplete()
        didCompleteCallCount += 1
        didCompleteExpectation?.fulfill()
    }
}
