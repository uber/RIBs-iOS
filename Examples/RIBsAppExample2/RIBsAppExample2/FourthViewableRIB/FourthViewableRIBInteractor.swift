//
//  FourthViewableRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs
import RxSwift

protocol FourthViewableRIBRouting: ViewableRouting {
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol FourthViewableRIBPresentable: Presentable {
    var listener: FourthViewableRIBPresentableListener? { get set }
    
    func presentSomeStuff()
}

protocol FourthViewableRIBListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class FourthViewableRIBInteractor: PresentableInteractor<FourthViewableRIBPresentable>, FourthViewableRIBInteractable, FourthViewableRIBPresentableListener {

    weak var router: FourthViewableRIBRouting?
    weak var listener: FourthViewableRIBListener?
    
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: FourthViewableRIBPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        Single<Int>
            .timer(.seconds(4), scheduler: backgroundScheduler)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {  _ in
                self.presenter.presentSomeStuff()
            })
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
