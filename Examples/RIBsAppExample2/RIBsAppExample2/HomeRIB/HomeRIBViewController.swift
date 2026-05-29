//
//  HomeRIBViewController.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 3/12/26.
//

import RIBs
import UIKit

protocol HomeRIBPresentableListener: AnyObject {
    func logout()
}

final class HomeRIBViewController: UIViewController, HomeRIBPresentable, HomeRIBViewControllable {

    weak var listener: HomeRIBPresentableListener?

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        title = "Home"
        setupViews()
    }

    // MARK: - HomeRIBPresentable

    func presentUsername(_ username: String) {
        usernameLabel.text = "Welcome, \(username)!"
    }

    // MARK: - Private

    private func setupViews() {
        view.addSubview(usernameLabel)
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            usernameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20),
        ])

        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    @objc private func logoutTapped() {
        listener?.logout()
    }
}
