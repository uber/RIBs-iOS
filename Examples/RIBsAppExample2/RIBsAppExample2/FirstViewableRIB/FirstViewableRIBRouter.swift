//
//  FirstViewableRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol FirstViewableRIBInteractable: Interactable, FirstViewableRIBActionableItem, SecondViewableRIBListener, FourthViewableRIBListener {
    var router: FirstViewableRIBRouting? { get set }
    var listener: FirstViewableRIBListener? { get set }
}

protocol FirstViewableRIBViewControllable: ViewControllable {
    
}

final class FirstViewableRIBRouter: ViewableRouter<FirstViewableRIBInteractable, FirstViewableRIBViewControllable>, FirstViewableRIBRouting {

    private let secondViewableRIBBuilder: SecondViewableRIBBuildable
    private var secondViewableRIBRouter: SecondViewableRIBRouting?

    private let fourthViewableRIBBuilder: FourthViewableRIBBuildable
    private var fourthViewableRIBRouter: FourthViewableRIBRouting?

    init(interactor: FirstViewableRIBInteractable, viewController: FirstViewableRIBViewControllable, secondViewableRIBBuilder: SecondViewableRIBBuildable, fourthViewableRIBBuilder: FourthViewableRIBBuildable) {
        self.secondViewableRIBBuilder = secondViewableRIBBuilder
        self.fourthViewableRIBBuilder = fourthViewableRIBBuilder
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

    func routeToFourthViewableRIB() -> FourthViewableRIBActionableItem {
        let (fourthViewableRIBRouter, actionableItem) = fourthViewableRIBBuilder.build(withListener: interactor)
        self.fourthViewableRIBRouter = fourthViewableRIBRouter
        attachChild(fourthViewableRIBRouter)
        viewController.uiviewController.navigationController?.pushViewController(fourthViewableRIBRouter.viewControllable.uiviewController, animated: true)
        return actionableItem
    }

    func routeAwayFromFourthViewableRIB() {
        if let fourthViewableRIBRouter = fourthViewableRIBRouter {
            self.fourthViewableRIBRouter = nil
            viewController.uiviewController.navigationController?.popToViewController(viewController.uiviewController, animated: true)
            detachChild(fourthViewableRIBRouter)
        }
    }
}
