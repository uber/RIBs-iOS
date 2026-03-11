//
//  FourthViewableRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol FourthViewableRIBDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
}

final class FourthViewableRIBComponent: Component<FourthViewableRIBDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
}

// MARK: - Builder

protocol FourthViewableRIBBuildable: Buildable {
    func build(withListener listener: FourthViewableRIBListener) -> (routing: FourthViewableRIBRouting, actionableItem: FourthViewableRIBActionableItem)
}

final class FourthViewableRIBBuilder: Builder<FourthViewableRIBDependency>, FourthViewableRIBBuildable {

    override init(dependency: FourthViewableRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: FourthViewableRIBListener) -> (routing: FourthViewableRIBRouting, actionableItem: FourthViewableRIBActionableItem) {
        let component = FourthViewableRIBComponent(dependency: dependency)
        let viewController = FourthViewableRIBViewController()
        let presenter = FourthViewableRIBPresenter(viewController: viewController)
        let interactor = FourthViewableRIBInteractor(presenter: presenter)
        interactor.listener = listener
        let router = FourthViewableRIBRouter(interactor: interactor, viewController: viewController)
        return (routing: router, actionableItem: interactor)
    }
}
