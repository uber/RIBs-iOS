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

public extension InteractorScope {

    /// The lifecycle of this interactor exposed as an async stream.
    var isActiveSequence: AsyncStream<Bool> {
        return isActiveStream.asAsyncStream(bufferingPolicy: .bufferingNewest(1))
    }
}

public extension RouterScope {

    /// The lifecycle events of this router exposed as an async stream.
    var lifecycleSequence: AsyncStream<RouterLifecycle> {
        return lifecycle.asAsyncStream()
    }
}

public extension Working {

    /// The lifecycle of this worker exposed as an async stream.
    var isStartedSequence: AsyncStream<Bool> {
        return isStartedStream.asAsyncStream(bufferingPolicy: .bufferingNewest(1))
    }
}

public extension LeakDetector {

    /// The leak detection status exposed as an async stream.
    var statusSequence: AsyncStream<LeakDetectionStatus> {
        return status.asAsyncStream(bufferingPolicy: .bufferingNewest(1))
    }
}
#endif
