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

public extension Interactor {

    /// Runs a task that is cancelled when this interactor deactivates.
    ///
    /// If the interactor is inactive when this method is invoked, the task is cancelled immediately.
    @discardableResult
    func taskOnDeactivate(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> ()
    ) -> Task<Void, Never> {
        let task = Task(priority: priority) {
            await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeOnDeactivate(interactor: self)
        return task
    }

    /// Runs a throwing task that is cancelled when this interactor deactivates.
    ///
    /// If the interactor is inactive when this method is invoked, the task is cancelled immediately.
    @discardableResult
    func throwingTaskOnDeactivate(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> ()
    ) -> Task<Void, Error> {
        let task = Task(priority: priority) {
            try await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeOnDeactivate(interactor: self)
        return task
    }
}

public extension Worker {

    /// Runs a task that is cancelled when this worker stops.
    ///
    /// If the worker is stopped when this method is invoked, the task is cancelled immediately.
    @discardableResult
    func taskOnStop(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> ()
    ) -> Task<Void, Never> {
        let task = Task(priority: priority) {
            await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeOnStop(self)
        return task
    }

    /// Runs a throwing task that is cancelled when this worker stops.
    ///
    /// If the worker is stopped when this method is invoked, the task is cancelled immediately.
    @discardableResult
    func throwingTaskOnStop(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> ()
    ) -> Task<Void, Error> {
        let task = Task(priority: priority) {
            try await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeOnStop(self)
        return task
    }
}

public extension Workflow {

    /// Runs a task that is cancelled when this workflow is disposed.
    @discardableResult
    func task(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> ()
    ) -> Task<Void, Never> {
        let task = Task(priority: priority) {
            await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeWith(workflow: self)
        return task
    }

    /// Runs a throwing task that is cancelled when this workflow is disposed.
    @discardableResult
    func throwingTask(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> ()
    ) -> Task<Void, Error> {
        let task = Task(priority: priority) {
            try await operation()
        }
        Disposables.create {
            task.cancel()
        }
        .disposeWith(workflow: self)
        return task
    }
}
#endif
