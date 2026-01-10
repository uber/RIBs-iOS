//
//  SecondViewableRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift

protocol SecondViewableRIBRouting: ViewableRouting {
    var secondViewableRIBViewController: SecondViewableRIBViewControllable { get }
}

protocol SecondViewableRIBPresentable: Presentable {
    var listener: SecondViewableRIBPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol SecondViewableRIBListener: AnyObject {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class SecondViewableRIBInteractor: PresentableInteractor<SecondViewableRIBPresentable>, SecondViewableRIBInteractable, SecondViewableRIBPresentableListener {

    weak var router: SecondViewableRIBRouting?
    weak var listener: SecondViewableRIBListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: SecondViewableRIBPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        // TODO: Implement business logic here.
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
