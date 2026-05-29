//
//  ThirdHeadlessRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol ThirdHeadlessRIBInteractable: Interactable, FourthViewableRIBListener {
    var router: ThirdHeadlessRIBRouting? { get set }
    var listener: ThirdHeadlessRIBListener? { get set }
}

protocol ThirdHeadlessRIBViewControllable: ViewControllable {
    // TODO: Declare methods the router invokes to manipulate the view hierarchy. Since
    // this RIB does not own its own view, this protocol is conformed to by one of this
    // RIB's ancestor RIBs' view.
}

final class ThirdHeadlessRIBRouter: Router<ThirdHeadlessRIBInteractable>, ThirdHeadlessRIBRouting {
    
    private let viewController: ThirdHeadlessRIBViewControllable

    private let fourthViewableRIBBuilder: FourthViewableRIBBuildable
    private var fourthViewableRIBRouter: FourthViewableRIBRouting?

    // TODO: Constructor inject child builder protocols to allow building children.
    init(interactor: ThirdHeadlessRIBInteractable, viewController: ThirdHeadlessRIBViewControllable, fourthViewableRIBBuilder: FourthViewableRIBBuildable) {
        self.viewController = viewController
        self.fourthViewableRIBBuilder = fourthViewableRIBBuilder
        super.init(interactor: interactor)
        interactor.router = self
    }

    func cleanupViews() {
        // TODO: Since this router does not own its view, it needs to cleanup the views
        // it may have added to the view hierarchy, when its interactor is deactivated.
        routeAwayFromFourthRIB()
    }

    
    func routeToFourthRIB() {
        let (fourthViewableRIBRouter, fourthViewableRIBInteractor) = fourthViewableRIBBuilder.build(withListener: interactor)
        self.fourthViewableRIBRouter = fourthViewableRIBRouter
        let fourthViewableRIBViewControllable = fourthViewableRIBRouter.viewControllable
        attachChild(fourthViewableRIBRouter)
        viewController.uiviewController.navigationController?.pushViewController(fourthViewableRIBViewControllable.uiviewController, animated: true)
    }
    
    func routeAwayFromFourthRIB() {
        if let fourthViewableRIBRouter = fourthViewableRIBRouter {
            self.fourthViewableRIBRouter = nil
            viewController.uiviewController.navigationController?.popViewController(animated: true)
            detachChild(fourthViewableRIBRouter)
        }
    }
}
