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
    func close()
}

final class SecondViewableRIBViewController: UIViewController, SecondViewableRIBPresentable, SecondViewableRIBViewControllable {

    weak var listener: SecondViewableRIBPresentableListener?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .blue
        setupBackButton()
    }

    private func setupBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func didTapBack() {
        listener?.close()
    }
}
