//
//  ExampleWorker.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift
import Foundation

protocol ExampleWorker: Working {}

final class ExampleWorkerImp: Worker, ExampleWorker {

    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

    override func didStart(_ interactorScope: InteractorScope) {
        Single<Int>
            .timer(.seconds(3), scheduler: backgroundScheduler)
            .map { @Sendable _ in "mock response" }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { value in
                print("ExampleWorker: Single fired with value: \(value)")
            })
            .disposeOnStop(self)
    }
}
