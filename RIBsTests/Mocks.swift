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

class MockRouter: Routing {
    
    var interactable: Interactable {
        return mockInteractor
    }
    
    var children: [Routing] = []
    
    var lifecycle: AnyPublisher<RouterLifecycle, Never> {
        return lifecycleSubject.eraseToAnyPublisher()
    }
    
    var loadCallCount = 0
    func load() {
        loadCallCount += 1
    }
    
    var attachCallCount = 0
    var attachChild_child: Routing?
    func attachChild(_ child: Routing) {
        attachCallCount += 1
        attachChild_child = child
        children.append(child)
    }
    
    var detachCallCount = 0
    var detachChild_child: Routing?
    func detachChild(_ child: Routing) {
        detachCallCount += 1
        detachChild_child = child
        children.removeElementByReference(child)
    }
    
    let mockInteractor = MockInteractor()
    private let lifecycleSubject = PassthroughSubject<RouterLifecycle, Never>()
}

class MockInteractor: Interactable {
    
    var isActive: Bool = false
    
    var isActiveCallCount = 0
    var isActiveSetCallCount = 0
    var isActiveStream: AnyPublisher<Bool, Never> {
        isActiveCallCount += 1
        return isActiveSubject.eraseToAnyPublisher()
    }
    
    var activateCallCount = 0
    func activate() {
        activateCallCount += 1
        isActive = true
        isActiveSubject.send(true)
    }
    
    var deactivateCallCount = 0
    func deactivate() {
        deactivateCallCount += 1
        isActive = false
        isActiveSubject.send(false)
    }
    
    private let isActiveSubject = CurrentValueSubject<Bool, Never>(false)
}
