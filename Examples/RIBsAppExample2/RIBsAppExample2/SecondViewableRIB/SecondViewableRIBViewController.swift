//
//  SecondViewableRIBViewController.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import RIBs
import RxSwift
import UIKit

protocol SecondViewableRIBPresentableListener: AnyObject {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
}

final class SecondViewableRIBViewController: UIViewController, SecondViewableRIBPresentable, SecondViewableRIBViewControllable {

    weak var listener: SecondViewableRIBPresentableListener?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blue
    }
}
