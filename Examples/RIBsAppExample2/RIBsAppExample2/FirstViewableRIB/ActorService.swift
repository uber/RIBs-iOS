//
//  ActorService.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import Foundation

protocol ActorServicable: Actor {
    func doWork() async
}

actor ActorService: ActorServicable {
    func doWork() async {
        printCurrentThread()
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        printCurrentThread()
    }
    
    private func printCurrentThread() {
        print("Running on: \(Thread.current)")
    }
}

