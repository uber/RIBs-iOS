//
//  FourthViewableRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol FourthViewableRIBInteractable: Interactable {
    var router: FourthViewableRIBRouting? { get set }
    var listener: FourthViewableRIBListener? { get set }
}

protocol FourthViewableRIBViewControllable: ViewControllable {
    func renderSomeOtherColor()
}

final class FourthViewableRIBRouter: ViewableRouter<FourthViewableRIBInteractable, FourthViewableRIBViewControllable>, FourthViewableRIBRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    override init(interactor: FourthViewableRIBInteractable, viewController: FourthViewableRIBViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
