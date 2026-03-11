//
//  FirstViewableRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift
import Foundation


protocol FirstViewableRIBRouting: ViewableRouting {
    var firstViewableRIBViewController: FirstViewableRIBViewControllable { get }
    func routeToSecondViewableRIB()
    func routeAwayFromSecondViewableRIB()
    func routeToFourthViewableRIB() -> FourthViewableRIBActionableItem
    func routeAwayFromFourthViewableRIB()
}

protocol FirstViewableRIBPresentable: Presentable {
    var listener: FirstViewableRIBPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol FirstViewableRIBListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class FirstViewableRIBInteractor: PresentableInteractor<FirstViewableRIBPresentable>, FirstViewableRIBInteractable, FirstViewableRIBPresentableListener {

    weak var router: FirstViewableRIBRouting?
    weak var listener: FirstViewableRIBListener?
    
    private let actorService: ActorServicable
    private let rxSwiftService: RxSwiftServicable

    init(presenter: FirstViewableRIBPresentable, actorService: ActorServicable, rxSwiftService: RxSwiftServicable) {
        self.actorService = actorService
        self.rxSwiftService = rxSwiftService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        Single<Int>
            .timer(.seconds(3), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {  _ in
                self.printCurrentThread()
                self.router?.routeToSecondViewableRIB()
                self.printCurrentThread()
            })
            .disposeOnDeactivate(interactor: self)
        
        rxSwiftService.doWork()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { value in
                self.printCurrentThread()
                print("RxSwiftService.doWork() completed with value: \(value)")
                self.printCurrentThread()
            })
            .disposeOnDeactivate(interactor: self)
        
        Task {
            await someAsyncWork()
        }
        
        Task {
            await someAsyncWork2()
        }
    }
    
    private func someAsyncWork() async {
        printCurrentThread()
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        printCurrentThread()
    }
    
    private func someAsyncWork2() async {
        printCurrentThread()
        await actorService.doWork()
        printCurrentThread()
    }
    
    private func printCurrentThread() {
        print("Running on: \(Thread.current)")
    }

    func didComplete(_ secondViewableRIB: SecondViewableRIBInteractable) {
        router?.routeAwayFromSecondViewableRIB()
    }

    // MARK: - FirstViewableRIBActionableItem

    func openFourthViewableRIB() -> Observable<(FourthViewableRIBActionableItem, ())> {
        guard let fourthItem = router?.routeToFourthViewableRIB() else {
            return .empty()
        }
        return .just((fourthItem, ()))
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
