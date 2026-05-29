//
//  InteractorTests.swift
//  RIBs
//
//  Created by Alex Bush on 6/22/25.
//

@testable import RIBs
import XCTest
import RxSwift

@MainActor
final class InteractorTests: XCTestCase {
    
    private var interactor: InteractorMock!
    
    override func setUp() {
        super.setUp()
        
        interactor = InteractorMock() // NOTE: we're using InteractorMock here to test the underlying parent class, Interactor, behavior so this is appropriate here.
    }
    
    func test_interactorIsInactiveByDefault() {
        XCTAssertFalse(interactor.isActive)
        let _ = interactor.isActiveStream.subscribe { isActive in
            XCTAssertFalse(isActive)
        }
    }
    
    func test_isActive_whenStarted_isTrue() {
        // give
        // when
        interactor.activate()
        // then
        XCTAssertTrue(interactor.isActive)
        let _ = interactor.isActiveStream.subscribe { isActive in
            XCTAssertTrue(isActive)
        }
    }
    
    func test_isActive_whenDeactivated_isFalse() {
        // given
        interactor.activate()
        // when
        interactor.deactivate()
        // then
        XCTAssertFalse(interactor.isActive)
        let _ = interactor.isActiveStream.subscribe { isActive in
            XCTAssertFalse(isActive)
        }
    }
    
    func test_didBecomeActive_isCalledWhenStarted() {
        // given
        // when
        interactor.activate()
        // then
        XCTAssertEqual(interactor.didBecomeActiveCallCount, 1)
    }
    
    func test_didBecomeActive_isNotCalledWhenAlreadyActive() {
        // given
        interactor.activate()
        XCTAssertEqual(interactor.didBecomeActiveCallCount, 1)
        // when
        interactor.activate()
        // then
        XCTAssertEqual(interactor.didBecomeActiveCallCount, 1)
    }
    
    func test_willResignActive_isCalledWhenDeactivated() {
        // given
        interactor.activate()
        // when
        interactor.deactivate()
        // then
        XCTAssertEqual(interactor.willResignActiveCallCount, 1)
    }
    
    func test_willResignActive_isNotCalledWhenAlreadyInactive() {
        // given
        interactor.activate()
        interactor.deactivate()
        XCTAssertEqual(interactor.willResignActiveCallCount, 1)
        // when
        interactor.deactivate()
        // then
        XCTAssertEqual(interactor.willResignActiveCallCount, 1)
    }
    
    func test_isActiveStream_completedOnInteractorDeinit() async {
        // given
        var isActiveStreamCompleted = false
        interactor.activate()
        let _ = interactor.isActiveStream.subscribe { _ in } onCompleted: {
            isActiveStreamCompleted = true
        }
        
        // when
        interactor = nil
        // then
        XCTAssertTrue(isActiveStreamCompleted)
    }
    
    // MARK: - BEGIN Observables Attached/Detached to/from Interactor
    func test_observableAttachedToInactiveInteactorIsDisposedImmediately() {
        // given
        var onDisposeCalled = false
        let subjectEmiitingValues: PublishSubject<Int> = .init()
        let observable = subjectEmiitingValues.asObservable().do { _ in } onDispose: {
            onDisposeCalled = true
        }
        // when
        observable.subscribe().disposeOnDeactivate(interactor: interactor)
        // then
        XCTAssertTrue(onDisposeCalled)
    }
    
    func test_observableIsDisposedOnInteractorDeactivation() {
        // given
        var onDisposeCalled = false
        let subjectEmiitingValues: PublishSubject<Int> = .init()
        let observable = subjectEmiitingValues.asObservable().do { _ in } onDispose: {
            onDisposeCalled = true
        }
        interactor.activate()
        observable.subscribe().disposeOnDeactivate(interactor: interactor)
        // when
        interactor.deactivate()
        // then
        XCTAssertTrue(onDisposeCalled)
    }
    
    func test_observableIsDisposedOnInteractorDeinit() async {
        // given
        var onDisposeCalled = false
        let subjectEmiitingValues: PublishSubject<Int> = .init()
        let observable = subjectEmiitingValues.asObservable().do { _ in } onDispose: {
            onDisposeCalled = true
        }
        interactor.activate()
        observable.subscribe().disposeOnDeactivate(interactor: interactor)
        XCTAssertFalse(onDisposeCalled)
        // when
        interactor = nil
        // then
        XCTAssertTrue(onDisposeCalled)
    }
    // MARK: Observables Attached/Detached to/from Interactor END -
    
    // MARK: - BEGIN Observables Confined to Interactor
    func test_observableConfinedToInteractorOnlyEmitsValueWhenInteractorIsActive() {
        // given
        var emittedValue: Int?
        let subjectEmiitingValues: PublishSubject<Int> = .init()
        let confinedObservable = subjectEmiitingValues.asObservable().confineTo(interactor)
        let _ = confinedObservable.confineTo(interactor)
        let _ = confinedObservable.subscribe { newValue in
            emittedValue = newValue
        }

        subjectEmiitingValues.onNext(1)
        XCTAssertNil(emittedValue)
        // when
        interactor.activate()
        subjectEmiitingValues.onNext(2)
        // then
        XCTAssertNotNil(emittedValue)
        XCTAssertEqual(emittedValue, 2)
    }
    // MARK: Observables Confined to Interactor -
}
