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

final class FirstViewableRIBComponent: Component<FirstViewableRIBDependency>, SecondViewableRIBDependency, FourthViewableRIBDependency, MainRIBDependency {

    var actorService: ActorServicable {
        ActorService()
    }

    var rxSwiftService: RxSwiftServicable {
        RxSwiftService()
    }

    var secondViewableRIBBuilder: SecondViewableRIBBuildable {
        SecondViewableRIBBuilder(dependency: self)
    }

    var fourthViewableRIBBuilder: FourthViewableRIBBuildable {
        FourthViewableRIBBuilder(dependency: self)
    }

    var authService: AuthServiceType {
        shared { FakeAuthService() }
    }

    var mainRIBBuilder: MainRIBBuildable {
        MainRIBBuilder { (userSession: UserSession) -> MainRIBComponent in
            MainRIBComponent(dependency: self, userSession: userSession)
        }
    }
}

// MARK: - Builder

protocol FirstViewableRIBBuildable: Buildable {
    func build(withListener listener: FirstViewableRIBListener) -> (routing: FirstViewableRIBRouting, actionableItem: FirstViewableRIBActionableItem)
}

final class FirstViewableRIBBuilder: Builder<FirstViewableRIBDependency>, FirstViewableRIBBuildable {

    override init(dependency: FirstViewableRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: FirstViewableRIBListener) -> (routing: FirstViewableRIBRouting, actionableItem: FirstViewableRIBActionableItem) {
        let component = FirstViewableRIBComponent(dependency: dependency)
        let viewController = FirstViewableRIBViewController()
        let interactor = FirstViewableRIBInteractor(presenter: viewController, actorService: component.actorService, rxSwiftService: component.rxSwiftService, authService: component.authService)
        interactor.listener = listener
        let router = FirstViewableRIBRouter(interactor: interactor, viewController: viewController, secondViewableRIBBuilder: component.secondViewableRIBBuilder, fourthViewableRIBBuilder: component.fourthViewableRIBBuilder, mainRIBBuilder: component.mainRIBBuilder)
        return (routing: router, actionableItem: interactor)
    }
}
