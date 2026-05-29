//
//  ThirdHeadlessRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs
import RxSwift

protocol ThirdHeadlessRIBRouting: Routing {
    func cleanupViews()
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
    func routeToFourthRIB()
    func routeAwayFromFourthRIB()
}

protocol ThirdHeadlessRIBListener: AnyObject {
    func sendData(_ interactor: ThirdHeadlessRIBInteractable)
}

final class ThirdHeadlessRIBInteractor: Interactor, ThirdHeadlessRIBInteractable {
    
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

    weak var router: ThirdHeadlessRIBRouting?
    weak var listener: ThirdHeadlessRIBListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init() {}

    override func didBecomeActive() {
        super.didBecomeActive()
        
        print("do some work in the ThirdHeadlessRIBInteractor")
        
        Single<Int>
            .timer(.seconds(3), scheduler: backgroundScheduler)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {  _ in
                self.listener?.sendData(self)
                self.router?.routeToFourthRIB()
            })
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()

        router?.cleanupViews()
        // TODO: Pause any business logic.
    }
}
