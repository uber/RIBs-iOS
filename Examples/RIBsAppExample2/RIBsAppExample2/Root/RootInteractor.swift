//
//  RootInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift

protocol RootRouting: ViewableRouting {
    func routeToFirstViewableRIB()
    func routeAwayFromFirstViewableRIB()
}

protocol RootPresentable: Presentable {
    var listener: RootPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol RootListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class RootInteractor: PresentableInteractor<RootPresentable>, RootInteractable, RootPresentableListener {

    weak var router: RootRouting?
    weak var listener: RootListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: RootPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        router?.routeToFirstViewableRIB()
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
