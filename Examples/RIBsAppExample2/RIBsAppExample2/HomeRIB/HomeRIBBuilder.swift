//
//  HomeRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

// MARK: - Dependency

protocol HomeRIBDependency: Dependency {
    var currentUserService: CurrentUserServiceType { get }
}

// MARK: - Component

final class HomeRIBComponent: Component<HomeRIBDependency> {

    var currentUserService: CurrentUserServiceType {
        dependency.currentUserService
    }
}

// MARK: - Buildable

protocol HomeRIBBuildable: Buildable {
    func build(withListener listener: HomeRIBListener) -> HomeRIBRouting
}

// MARK: - Builder

final class HomeRIBBuilder: Builder<HomeRIBDependency>, HomeRIBBuildable {

    override init(dependency: HomeRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: HomeRIBListener) -> HomeRIBRouting {
        let component = HomeRIBComponent(dependency: dependency)
        let viewController = HomeRIBViewController()
        let interactor = HomeRIBInteractor(presenter: viewController, currentUserService: component.currentUserService)
        interactor.listener = listener
        return HomeRIBRouter(interactor: interactor, viewController: viewController)
    }
}
