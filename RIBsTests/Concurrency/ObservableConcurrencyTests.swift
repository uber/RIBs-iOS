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

final class ObservableConcurrencyTests: XCTestCase {

    func test_observableAsAsyncStream_emitsValuesAndCompletes() async {
        var iterator = Observable.from([1, 2]).asAsyncStream().makeAsyncIterator()

        let firstValue = await iterator.next()
        let secondValue = await iterator.next()
        let completedValue = await iterator.next()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 2)
        XCTAssertNil(completedValue)
    }

    func test_observableAsAsyncStream_completesOnError() async {
        var iterator = Observable<Int>
            .error(ObservableConcurrencyTestError.error)
            .asAsyncStream()
            .makeAsyncIterator()

        let value = await iterator.next()

        XCTAssertNil(value)
    }

    func test_observableAsAsyncThrowingStream_emitsValuesAndCompletes() async throws {
        var iterator = Observable.from([1, 2]).asAsyncThrowingStream().makeAsyncIterator()

        let firstValue = try await iterator.next()
        let secondValue = try await iterator.next()
        let completedValue = try await iterator.next()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 2)
        XCTAssertNil(completedValue)
    }

    func test_observableAsAsyncThrowingStream_throwsOnError() async {
        var iterator = Observable<Int>
            .error(ObservableConcurrencyTestError.error)
            .asAsyncThrowingStream()
            .makeAsyncIterator()

        do {
            _ = try await iterator.next()
            XCTFail("Expected async sequence to throw")
        } catch ObservableConcurrencyTestError.error {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_observableAsAsyncStream_disposesSubscriptionWhenTaskIsCancelled() async {
        let disposed = expectation(description: "Subscription disposed")
        let observable = Observable<Int>.never().do(onDispose: {
            disposed.fulfill()
        })

        let task = Task {
            var iterator = observable.asAsyncStream().makeAsyncIterator()
            _ = await iterator.next()
        }

        await Task.yield()
        task.cancel()
        await fulfillment(of: [disposed], timeout: 1)
    }

    func test_observableAsAsyncThrowingStream_disposesSubscriptionWhenTaskIsCancelled() async {
        let disposed = expectation(description: "Subscription disposed")
        let observable = Observable<Int>.never().do(onDispose: {
            disposed.fulfill()
        })

        let task = Task {
            var iterator = observable.asAsyncThrowingStream().makeAsyncIterator()
            _ = try? await iterator.next()
        }

        await Task.yield()
        task.cancel()
        await fulfillment(of: [disposed], timeout: 1)
    }
}

private enum ObservableConcurrencyTestError: Error {
    case error
}
