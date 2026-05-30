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

final class RouterConcurrencyTests: XCTestCase {

    func test_lifecycleSequence_emitsDidLoad() async {
        let router = Router(interactor: Interactor())
        var iterator = router.lifecycleSequence.makeAsyncIterator()
        let lifecycleTask = Task {
            await iterator.next()
        }

        router.load()
        let lifecycle = await lifecycleTask.value

        XCTAssertEqual(lifecycle, .didLoad)
    }

    func test_lifecycleSequence_completesWhenRouterDeinitializes() async {
        var router: Router<Interactor>? = Router(interactor: Interactor())
        var iterator = router?.lifecycleSequence.makeAsyncIterator()

        router = nil
        let completedValue = await iterator?.next()

        XCTAssertNil(completedValue)
    }
}
