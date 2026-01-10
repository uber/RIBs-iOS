//
//  FirstViewableRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift

protocol FirstViewableRIBRouting: ViewableRouting {
    var firstViewableRIBViewController: FirstViewableRIBViewControllable { get }
    func routeToSecondViewableRIB()
    func routeAwayFromSecondViewableRIB()
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

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: FirstViewableRIBPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        Single<Int>
            .timer(.seconds(3), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] _ in
                self?.router?.routeToSecondViewableRIB()
            })
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
