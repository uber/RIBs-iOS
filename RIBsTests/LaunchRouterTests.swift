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
import XCTest

class LaunchRouterTests: XCTestCase {

    private var mockWindow: UIWindow!
    private var mockControllable: ViewControllableMock!
    private var mockInteractor: MockInteractor!
    private var router: LaunchRouter<MockInteractor, ViewControllableMock>!

    override func setUp() {
        super.setUp()

        mockWindow = UIWindow()
        mockControllable = ViewControllableMock()
        mockInteractor = MockInteractor()
        router = LaunchRouter(interactor: mockInteractor, viewController: mockControllable)
    }

    func test_launch() {
        router.launch(from: mockWindow)

        XCTAssertTrue(mockWindow.rootViewController === mockControllable.uiviewController)
        XCTAssertTrue(mockWindow.isKeyWindow)
    }
}

private class ViewControllableMock: ViewControllable {
    let uiviewController = UIViewController()
}
