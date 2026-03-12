//
//  MainRIBViewController.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs
import UIKit

protocol MainRIBPresentableListener: AnyObject {}

final class MainRIBViewController: UIViewController, MainRIBPresentable, MainRIBViewControllable {

    weak var listener: MainRIBPresentableListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemIndigo
        title = "Main"
    }
}
