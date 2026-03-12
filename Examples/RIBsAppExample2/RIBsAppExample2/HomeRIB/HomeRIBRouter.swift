//
//  HomeRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

protocol HomeRIBInteractable: Interactable {
    var router: HomeRIBRouting? { get set }
    var listener: HomeRIBListener? { get set }
}

protocol HomeRIBViewControllable: ViewControllable {}

final class HomeRIBRouter: ViewableRouter<HomeRIBInteractable, HomeRIBViewControllable>, HomeRIBRouting {

    override init(interactor: HomeRIBInteractable, viewController: HomeRIBViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
