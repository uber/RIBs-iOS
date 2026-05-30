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

/// A type-erased async sequence used to preserve element type information without requiring typed
/// `AsyncSequence` availability.
public struct AnyAsyncSequence<Element>: AsyncSequence {

    public struct AsyncIterator: AsyncIteratorProtocol {

        private var nextElement: () async throws -> Element?

        fileprivate init<Iterator: AsyncIteratorProtocol>(_ iterator: Iterator) where Iterator.Element == Element {
            var iterator = iterator
            nextElement = {
                try await iterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            return try await nextElement()
        }
    }

    private let makeIterator: () -> AsyncIterator

    public init<Sequence: AsyncSequence>(_ sequence: Sequence) where Sequence.Element == Element {
        makeIterator = {
            AsyncIterator(sequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        return makeIterator()
    }
}

public extension AsyncSequence {

    /// Confines the async sequence's elements to the given interactor scope.
    ///
    /// Elements are only yielded while the interactor scope is active. While the sequence is being iterated,
    /// values emitted while inactive are ignored except for the latest value, which can be emitted when the scope
    /// becomes active again.
    ///
    /// - parameter interactorScope: The interactor scope whose activeness this async sequence is confined to.
    /// - returns: The async sequence confined to this interactor's activeness lifecycle.
    func confineTo(_ interactorScope: InteractorScope) -> AnyAsyncSequence<Element> {
        return AnyAsyncSequence(
            asObservable()
                .confineTo(interactorScope)
                .values
        )
    }
}

#endif
