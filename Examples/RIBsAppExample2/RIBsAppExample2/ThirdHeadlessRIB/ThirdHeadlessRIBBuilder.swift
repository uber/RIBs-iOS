//
//  ThirdHeadlessRIBBuilder.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs

protocol ThirdHeadlessRIBDependency: Dependency {
    
    var thirdHeadlessRIBViewController: ThirdHeadlessRIBViewControllable { get }
    // TODO: Declare the set of dependencies required by this RIB, but won't be
    // created by this RIB.
}

final class ThirdHeadlessRIBComponent: Component<ThirdHeadlessRIBDependency>, FourthViewableRIBDependency {

    fileprivate var thirdHeadlessRIBViewController: ThirdHeadlessRIBViewControllable {
        return dependency.thirdHeadlessRIBViewController
    }

    fileprivate var fourthViewableRIBBuilder: FourthViewableRIBBuildable {
        FourthViewableRIBBuilder(dependency: self)
    }
}

// MARK: - Builder

protocol ThirdHeadlessRIBBuildable: Buildable {
    func build(withListener listener: ThirdHeadlessRIBListener) -> ThirdHeadlessRIBRouting
}

final class ThirdHeadlessRIBBuilder: Builder<ThirdHeadlessRIBDependency>, ThirdHeadlessRIBBuildable {

    override init(dependency: ThirdHeadlessRIBDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: ThirdHeadlessRIBListener) -> ThirdHeadlessRIBRouting {
        let component = ThirdHeadlessRIBComponent(dependency: dependency)
        let interactor = ThirdHeadlessRIBInteractor()
        interactor.listener = listener
        return ThirdHeadlessRIBRouter(interactor: interactor, viewController: component.thirdHeadlessRIBViewController, fourthViewableRIBBuilder: component.fourthViewableRIBBuilder)
    }
}
