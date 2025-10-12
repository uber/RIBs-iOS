//
//  LeakDetectorMock.swift
//  RIBs
//
//  Created by Alex Bush on 7/26/25.
//

@testable import RIBs
import Foundation
import RxSwift
import UIKit

final class LeakDetectionHandleMock: LeakDetectionHandle {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

final class LeakDetectorMock: LeakDetector {
    
    private let queue = DispatchQueue(label: "com.LeakDetectorMock.state")

    private var _statusCallCount = 0
    var statusCallCount: Int {
        queue.sync { self._statusCallCount }
    }
    override var status: Observable<LeakDetectionStatus> {
        // Note: The get block for a computed property is synchronous.
        queue.sync {
            self._statusCallCount += 1
        }
        return super.status
    }
    

    var onDeallocateCalled: (() -> Void)?
    private var _expectDeallocateCallCount = 0
    var expectDeallocateCallCount: Int {
        queue.sync { self._expectDeallocateCallCount }
    }
    override func expectDeallocate(object: AnyObject, inTime time: TimeInterval) -> LeakDetectionHandle {
        queue.sync {
            self._expectDeallocateCallCount += 1
        }
        onDeallocateCalled?()
        return LeakDetectionHandleMock()
    }
    

    var onViewControllerDisappearCalled: (() -> Void)?
    private var _expectViewControllerDisappearCallCount = 0
    var expectViewControllerDisappearCallCount: Int {
        queue.sync { self._expectViewControllerDisappearCallCount }
    }
    override func expectViewControllerDisappear(viewController: UIViewController, inTime time: TimeInterval) -> LeakDetectionHandle {
        queue.sync {
            self._expectViewControllerDisappearCallCount += 1
        }
        onViewControllerDisappearCalled?()
        return LeakDetectionHandleMock()
    }
}
