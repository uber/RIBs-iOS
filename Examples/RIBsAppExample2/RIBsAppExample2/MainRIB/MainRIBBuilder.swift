//
//  MainRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs

// MARK: - Dependency

protocol MainRIBDependency: Dependency {
    
}

// MARK: - Component

final class MainRIBComponent: Component<MainRIBDependency>, HomeRIBDependency {

    let currentUserService: CurrentUserServiceType

    init(dependency: MainRIBDependency, userSession: UserSession) {
        self.currentUserService = CurrentUserService(session: userSession)
        super.init(dependency: dependency)
    }

    fileprivate var homeRIBBuilder: HomeRIBBuildable {
        HomeRIBBuilder(dependency: self)
    }
}

// MARK: - Buildable

protocol MainRIBBuildable: Buildable {
    func build(withDynamicBuildDependency listener: MainRIBListener,
               dynamicComponentDependency userSession: UserSession) -> MainRIBRouting
}

// MARK: - Builder

final class MainRIBBuilder: ComponentizedBuilder<MainRIBComponent, MainRIBRouting, MainRIBListener, UserSession>, MainRIBBuildable {

    override func build(with component: MainRIBComponent, _ listener: MainRIBListener) -> MainRIBRouting {
        let viewController = MainRIBViewController()
        let interactor = MainRIBInteractor(presenter: viewController, currentUserService: component.currentUserService)
        interactor.listener = listener
        return MainRIBRouter(interactor: interactor, viewController: viewController, homeRIBBuilder: component.homeRIBBuilder)
    }
}
