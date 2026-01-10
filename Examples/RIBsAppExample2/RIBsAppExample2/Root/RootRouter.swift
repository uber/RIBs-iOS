//
//  RootRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol RootInteractable: Interactable, FirstViewableRIBListener {
    var router: RootRouting? { get set }
    var listener: RootListener? { get set }
}

protocol RootViewControllable: ViewControllable {
    func embedMainView(_ viewControllable: ViewControllable)
    func removeMainView(_ viewControllable: ViewControllable)
}

final class RootRouter: LaunchRouter<RootInteractable, RootViewControllable>, RootRouting {
    
    private let firstViewableRIBBuilder: FirstViewableRIBBuildable
    private var firstViewableRIBRouter: FirstViewableRIBRouting?

    init(interactor: RootInteractable, viewController: RootViewControllable, firstViewableRIBBuilder: FirstViewableRIBBuildable) {
        self.firstViewableRIBBuilder = firstViewableRIBBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    func routeToFirstViewableRIB() {
        let firstViewableRIBRouter = firstViewableRIBBuilder.build(withListener: interactor)
        self.firstViewableRIBRouter = firstViewableRIBRouter
        let firstViewableRIBViewController = firstViewableRIBRouter.firstViewableRIBViewController
        viewController.embedMainView(firstViewableRIBViewController)
        attachChild(firstViewableRIBRouter)
    }
    
    func routeAwayFromFirstViewableRIB() {
        if let firstViewableRIBRouter = firstViewableRIBRouter {
            self.firstViewableRIBRouter = nil
            let firstViewableRIBViewController = firstViewableRIBRouter.firstViewableRIBViewController
            viewController.removeMainView(firstViewableRIBViewController)
            detachChild(firstViewableRIBRouter)
        }
    }
}
