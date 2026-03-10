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

final class ThirdHeadlessRIBComponent: Component<ThirdHeadlessRIBDependency> {

    fileprivate var thirdHeadlessRIBViewController: ThirdHeadlessRIBViewControllable {
        return dependency.thirdHeadlessRIBViewController
    }

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
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
        return ThirdHeadlessRIBRouter(interactor: interactor, viewController: component.thirdHeadlessRIBViewController)
    }
}
