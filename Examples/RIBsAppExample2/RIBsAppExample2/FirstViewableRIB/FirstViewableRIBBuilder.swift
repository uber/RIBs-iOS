//
//  FirstViewableRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs

protocol FirstViewableRIBDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
}

final class FirstViewableRIBComponent: Component<FirstViewableRIBDependency>, SecondViewableRIBDependency {
    
    var secondViewableRIBBuilder: SecondViewableRIBBuildable {
        SecondViewableRIBBuilder(dependency: self)
    }
}

// MARK: - Builder

protocol FirstViewableRIBBuildable: Buildable {
    func build(withListener listener: FirstViewableRIBListener) -> FirstViewableRIBRouting
}

final class FirstViewableRIBBuilder: Builder<FirstViewableRIBDependency>, FirstViewableRIBBuildable {

    override init(dependency: FirstViewableRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: FirstViewableRIBListener) -> FirstViewableRIBRouting {
        let component = FirstViewableRIBComponent(dependency: dependency)
        let viewController = FirstViewableRIBViewController()
        let interactor = FirstViewableRIBInteractor(presenter: viewController)
        interactor.listener = listener
        return FirstViewableRIBRouter(interactor: interactor, viewController: viewController, secondViewableRIBBuilder: component.secondViewableRIBBuilder)
    }
}
