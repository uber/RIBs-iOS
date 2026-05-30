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

#if swift(>=5.6) && canImport(_Concurrency)

import RxSwift

public extension ObservableType {

    /// Convert this observable into an async stream.
    ///
    /// The underlying Rx subscription is disposed when the async stream is terminated.
    func asAsyncStream(
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Element> {
        return AsyncStream(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
            let disposable = subscribe(
                onNext: { element in
                    continuation.yield(element)
                },
                onError: { _ in
                    continuation.finish()
                },
                onCompleted: {
                    continuation.finish()
                }
            )

            continuation.onTermination = { _ in
                disposable.dispose()
            }
        }
    }

    /// Convert this observable into an async throwing stream.
    ///
    /// The underlying Rx subscription is disposed when the async stream is terminated.
    func asAsyncThrowingStream(
        bufferingPolicy: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncThrowingStream<Element, Error> {
        return AsyncThrowingStream(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
            let disposable = subscribe(
                onNext: { element in
                    continuation.yield(element)
                },
                onError: { error in
                    continuation.finish(throwing: error)
                },
                onCompleted: {
                    continuation.finish()
                }
            )

            continuation.onTermination = { _ in
                disposable.dispose()
            }
        }
    }
}
#endif
