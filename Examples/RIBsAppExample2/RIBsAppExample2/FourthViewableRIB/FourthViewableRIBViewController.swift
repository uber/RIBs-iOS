//
//  FourthViewableRIBViewController.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/10/26.
//

import RIBs
import RxSwift
import UIKit

protocol FourthViewableRIBViewControllableDelegate: AnyObject {
    
}

final class FourthViewableRIBViewController: UIViewController, FourthViewableRIBViewControllable {

    weak var delegate: FourthViewableRIBViewControllableDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemRed
    }
    
    func renderSomeOtherColor() {
        view.backgroundColor = .systemPurple
    }
}
