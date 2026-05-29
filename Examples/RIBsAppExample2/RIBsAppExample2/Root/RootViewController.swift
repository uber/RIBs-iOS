//
//  RootViewController.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift
import UIKit

protocol RootPresentableListener: AnyObject {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
}

final class RootViewController: UIViewController, RootPresentable, RootViewControllable {

    weak var listener: RootPresentableListener?
    
    func embedMainView(_ viewControllable: ViewControllable) {
        let navController = UINavigationController(rootViewController: viewControllable.uiviewController)
        
        addChild(navController)
        view.addSubview(navController.view)
        navController.didMove(toParent: self)
        let childView = navController.view!
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: self.view.topAnchor),
            childView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            childView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    func removeMainView(_ viewControllable: ViewControllable) {
        guard let navController = viewControllable.uiviewController.navigationController else { return }
        navController.willMove(toParent: nil)
        navController.view.removeFromSuperview()
        navController.removeFromParent()
    }
}
