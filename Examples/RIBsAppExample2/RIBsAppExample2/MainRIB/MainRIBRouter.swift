//
//  MainRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

protocol MainRIBInteractable: Interactable, HomeRIBListener {
    var router: MainRIBRouting? { get set }
    var listener: MainRIBListener? { get set }
}

protocol MainRIBViewControllable: ViewControllable {}

final class MainRIBRouter: ViewableRouter<MainRIBInteractable, MainRIBViewControllable>, MainRIBRouting {

    private let homeRIBBuilder: HomeRIBBuildable
    private var homeRIBRouter: HomeRIBRouting?

    init(interactor: MainRIBInteractable, viewController: MainRIBViewControllable, homeRIBBuilder: HomeRIBBuildable) {
        self.homeRIBBuilder = homeRIBBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func routeToHomeRIB() {
        let homeRIBRouter = homeRIBBuilder.build(withListener: interactor)
        self.homeRIBRouter = homeRIBRouter
        viewController.uiviewController.navigationController?.pushViewController(
            homeRIBRouter.viewControllable.uiviewController, animated: false
        )
        attachChild(homeRIBRouter)
    }

    func routeAwayFromHomeRIB() {
        if let homeRIBRouter = homeRIBRouter {
            self.homeRIBRouter = nil
            viewController.uiviewController.navigationController?.popToViewController(viewController.uiviewController, animated: true)
            detachChild(homeRIBRouter)
        }
    }
}
