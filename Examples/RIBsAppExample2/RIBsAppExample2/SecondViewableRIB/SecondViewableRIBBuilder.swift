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

final class SecondViewableRIBComponent: Component<SecondViewableRIBDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
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
        let viewController = SecondViewableRIBViewController()
        let interactor = SecondViewableRIBInteractor(presenter: viewController)
        interactor.listener = listener
        return SecondViewableRIBRouter(interactor: interactor, viewController: viewController)
    }
}
