//
//  SecondViewableRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol SecondViewableRIBInteractable: Interactable {
    var router: SecondViewableRIBRouting? { get set }
    var listener: SecondViewableRIBListener? { get set }
}

protocol SecondViewableRIBViewControllable: ViewControllable {
    
}

final class SecondViewableRIBRouter: ViewableRouter<SecondViewableRIBInteractable, SecondViewableRIBViewControllable>, SecondViewableRIBRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    override init(interactor: SecondViewableRIBInteractable, viewController: SecondViewableRIBViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    var secondViewableRIBViewController: any SecondViewableRIBViewControllable {
        viewController
    }
}
