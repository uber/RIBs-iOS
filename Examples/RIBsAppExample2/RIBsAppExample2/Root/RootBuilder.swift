//
//  RootBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol RootDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
}

final class RootComponent: Component<RootDependency>, FirstViewableRIBDependency {

    var firstViewableRIBBuilder: FirstViewableRIBBuildable {
        FirstViewableRIBBuilder(dependency: self)
    }
}

// MARK: - Builder

struct RootBuildResult {
    let launchRouter: LaunchRouting
    let urlHandler: UrlHandler
}

protocol RootBuildable: Buildable {
    func build() -> RootBuildResult
}

final class RootBuilder: Builder<RootDependency>, RootBuildable {

    override init(dependency: RootDependency) {
        super.init(dependency: dependency)
    }

    func build() -> RootBuildResult {
        let component = RootComponent(dependency: dependency)
        let viewController = RootViewController()
        let interactor = RootInteractor(presenter: viewController)
        let launchRouter = RootRouter(interactor: interactor, viewController: viewController, firstViewableRIBBuilder: component.firstViewableRIBBuilder)
        return RootBuildResult(launchRouter: launchRouter, urlHandler: interactor)
    }
}
