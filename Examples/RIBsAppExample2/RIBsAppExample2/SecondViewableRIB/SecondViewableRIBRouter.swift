//
//  SecondViewableRIBRouter.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol SecondViewableRIBInteractable: Interactable, ThirdHeadlessRIBListener {
    var router: SecondViewableRIBRouting? { get set }
    var listener: SecondViewableRIBListener? { get set }
}

protocol SecondViewableRIBViewControllable: ViewControllable, ThirdHeadlessRIBViewControllable {
    
}

final class SecondViewableRIBRouter: ViewableRouter<SecondViewableRIBInteractable, SecondViewableRIBViewControllable>, SecondViewableRIBRouting {
    
    private let thirdHeadlessRIBBuilder: ThirdHeadlessRIBBuildable
    private var thirdHeadlessRIBRouter: ThirdHeadlessRIBRouting?

    init(interactor: SecondViewableRIBInteractable, viewController: SecondViewableRIBViewControllable, thirdHeadlessRIBBuilder: ThirdHeadlessRIBBuildable) {
        self.thirdHeadlessRIBBuilder = thirdHeadlessRIBBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    var secondViewableRIBViewController: any SecondViewableRIBViewControllable {
        viewController
    }
    
    override func didLoad() {
        super.didLoad()
        
        routeToThirdHeadlessRIB()
    }
    
    private func routeToThirdHeadlessRIB() {
        let thirdHeadlessRIBRouter = thirdHeadlessRIBBuilder.build(withListener: interactor)
        self.thirdHeadlessRIBRouter = thirdHeadlessRIBRouter
        attachChild(thirdHeadlessRIBRouter)
    }
}
