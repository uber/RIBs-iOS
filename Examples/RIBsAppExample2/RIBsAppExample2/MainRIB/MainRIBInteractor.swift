//
//  MainRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

protocol MainRIBRouting: ViewableRouting {
    func routeToHomeRIB()
    func routeAwayFromHomeRIB()
}

protocol MainRIBPresentable: Presentable {
    var listener: MainRIBPresentableListener? { get set }
}

protocol MainRIBListener: AnyObject {
    func didCompleteWithLogout(_ interactor: MainRIBInteractable)
}

final class MainRIBInteractor: PresentableInteractor<MainRIBPresentable>, MainRIBInteractable, MainRIBPresentableListener {

    weak var router: MainRIBRouting?
    weak var listener: MainRIBListener?

    // MainRIBInteractor receives currentUserService directly, but it also lives
    // in the component so HomeRIB can access it without going through Main.
    private let currentUserService: CurrentUserServiceType

    init(presenter: MainRIBPresentable, currentUserService: CurrentUserServiceType) {
        self.currentUserService = currentUserService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        self.router?.routeToHomeRIB()
    }

    override func willResignActive() {
        super.willResignActive()
    }

    // MARK: - HomeRIBListener

    func didCompleteHomeByRequestingLogout(_ interactor: any HomeRIBInteractable) {
        listener?.didCompleteWithLogout(self)
    }
}
