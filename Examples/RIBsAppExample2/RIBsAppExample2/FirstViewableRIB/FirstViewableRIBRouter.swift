//
//  FirstViewableRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol FirstViewableRIBInteractable: Interactable, SecondViewableRIBListener {
    var router: FirstViewableRIBRouting? { get set }
    var listener: FirstViewableRIBListener? { get set }
}

protocol FirstViewableRIBViewControllable: ViewControllable {
    
}

final class FirstViewableRIBRouter: ViewableRouter<FirstViewableRIBInteractable, FirstViewableRIBViewControllable>, FirstViewableRIBRouting {

    private let secondViewableRIBBuilder: SecondViewableRIBBuildable
    private var secondViewableRIBRouter: SecondViewableRIBRouting?

    init(interactor: FirstViewableRIBInteractable, viewController: FirstViewableRIBViewControllable, secondViewableRIBBuilder: SecondViewableRIBBuildable) {
        self.secondViewableRIBBuilder = secondViewableRIBBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    var firstViewableRIBViewController: any FirstViewableRIBViewControllable {
        viewController
    }
    
    func routeToSecondViewableRIB() {
        let secondViewableRIBRouter = secondViewableRIBBuilder.build(withListener: interactor)
        self.secondViewableRIBRouter = secondViewableRIBRouter
        let secondViewableRIBViewControllable = secondViewableRIBRouter.secondViewableRIBViewController
        attachChild(secondViewableRIBRouter)
        viewController.uiviewController.navigationController?.pushViewController(secondViewableRIBViewControllable.uiviewController, animated: true)
    }
    
    func routeAwayFromSecondViewableRIB() {
        if let secondViewableRIBRouter = secondViewableRIBRouter {
            self.secondViewableRIBRouter = nil
            viewController.uiviewController.navigationController?.popToViewController(viewController.uiviewController, animated: true)
            detachChild(secondViewableRIBRouter)
        }
    }
}
