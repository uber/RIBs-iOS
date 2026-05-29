//
//  RxSwiftService.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import Foundation
import RxSwift

protocol RxSwiftServicable {
    func doWork() -> Single<Int>
}

final class RxSwiftService: RxSwiftServicable {
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    
    func doWork() -> Single<Int> {
        return Single<Int>
            .timer(.seconds(3), scheduler: backgroundScheduler)
            .map { @Sendable _ in 42 }
        
//        return Single<Int>.create { @Sendable single in
//            // Replace .main with .global() for background execution
//            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
//                // This closure now executes on a background thread
//                print("Executing on thread: \(Thread.current)")
//                single(.success(123))
//            }
//            
//            return Disposables.create()
//        }
//        .subscribe(on: backgroundScheduler)
    }
}

