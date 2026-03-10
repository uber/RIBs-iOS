//
//  SecondViewableRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol SecondViewableRIBDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
}

final class SecondViewableRIBComponent: Component<SecondViewableRIBDependency>, ThirdHeadlessRIBDependency {

    var thirdHeadlessRIBBuilder: ThirdHeadlessRIBBuildable {
        ThirdHeadlessRIBBuilder(dependency: self)
    }
    
    var viewController: SecondViewableRIBPresentable & SecondViewableRIBViewControllable {
        SecondViewableRIBViewController()
    }
    
    var thirdHeadlessRIBViewController: any ThirdHeadlessRIBViewControllable {
        viewController
    }
}

// MARK: - Builder

protocol SecondViewableRIBBuildable: Buildable {
    func build(withListener listener: SecondViewableRIBListener) -> SecondViewableRIBRouting
}

final class SecondViewableRIBBuilder: Builder<SecondViewableRIBDependency>, SecondViewableRIBBuildable {

    override init(dependency: SecondViewableRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SecondViewableRIBListener) -> SecondViewableRIBRouting {
        let component = SecondViewableRIBComponent(dependency: dependency)
        let viewController = component.viewController
        let exampleWorker = ExampleWorkerImp()
        let interactor = SecondViewableRIBInteractor(presenter: viewController, exampleWorker: exampleWorker)
        interactor.listener = listener
        return SecondViewableRIBRouter(interactor: interactor, viewController: viewController, thirdHeadlessRIBBuilder: component.thirdHeadlessRIBBuilder)
    }
}
