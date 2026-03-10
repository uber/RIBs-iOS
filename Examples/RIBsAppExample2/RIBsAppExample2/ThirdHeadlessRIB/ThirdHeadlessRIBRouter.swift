//
//  ThirdHeadlessRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol ThirdHeadlessRIBInteractable: Interactable {
    var router: ThirdHeadlessRIBRouting? { get set }
    var listener: ThirdHeadlessRIBListener? { get set }
}

protocol ThirdHeadlessRIBViewControllable: ViewControllable {
    // TODO: Declare methods the router invokes to manipulate the view hierarchy. Since
    // this RIB does not own its own view, this protocol is conformed to by one of this
    // RIB's ancestor RIBs' view.
}

final class ThirdHeadlessRIBRouter: Router<ThirdHeadlessRIBInteractable>, ThirdHeadlessRIBRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    init(interactor: ThirdHeadlessRIBInteractable, viewController: ThirdHeadlessRIBViewControllable) {
        self.viewController = viewController
        super.init(interactor: interactor)
        interactor.router = self
    }

    func cleanupViews() {
        // TODO: Since this router does not own its view, it needs to cleanup the views
        // it may have added to the view hierarchy, when its interactor is deactivated.
    }

    // MARK: - Private

    private let viewController: ThirdHeadlessRIBViewControllable
}
