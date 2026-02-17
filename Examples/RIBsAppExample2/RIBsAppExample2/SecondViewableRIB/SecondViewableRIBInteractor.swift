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
    func didComplete(_ secondViewableRIB: SecondViewableRIBInteractable)
}

final class SecondViewableRIBInteractor: PresentableInteractor<SecondViewableRIBPresentable>, SecondViewableRIBInteractable, SecondViewableRIBPresentableListener {

    weak var router: SecondViewableRIBRouting?
    weak var listener: SecondViewableRIBListener?

    private let exampleWorker: ExampleWorker

    init(presenter: SecondViewableRIBPresentable, exampleWorker: ExampleWorker) {
        self.exampleWorker = exampleWorker
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        exampleWorker.start(self)
    }

    func close() {
        listener?.didComplete(self)
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
}
