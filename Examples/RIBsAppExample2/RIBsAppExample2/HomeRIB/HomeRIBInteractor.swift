//
//  HomeRIBInteractor.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

protocol HomeRIBRouting: ViewableRouting {}

protocol HomeRIBPresentable: Presentable {
    var listener: HomeRIBPresentableListener? { get set }
    func presentUsername(_ username: String)
}

protocol HomeRIBListener: AnyObject {
    func didCompleteHomeByRequestingLogout(_ interactor: HomeRIBInteractable)
}

final class HomeRIBInteractor: PresentableInteractor<HomeRIBPresentable>, HomeRIBInteractable, HomeRIBPresentableListener {

    weak var router: HomeRIBRouting?
    weak var listener: HomeRIBListener?

    private let currentUserService: CurrentUserServiceType

    init(presenter: HomeRIBPresentable, currentUserService: CurrentUserServiceType) {
        self.currentUserService = currentUserService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        presenter.presentUsername(currentUserService.session.username)
    }

    override func willResignActive() {
        super.willResignActive()
    }

    // MARK: - HomeRIBPresentableListener

    func logout() {
        listener?.didCompleteHomeByRequestingLogout(self)
    }
}
