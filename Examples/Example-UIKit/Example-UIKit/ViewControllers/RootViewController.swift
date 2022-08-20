//
//  RootViewController.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 10/15/21.
//

import UIKit

class RootViewController: UIViewController {

    // MARK: - Subviews

    private lazy var crashButton: UIButton = {
        let action = UIAction(title: "Crash") { [weak self] _ in
            self?.causeNSException()
        }
        let control = UIButton(primaryAction: action)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [crashButton])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 8.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Actions

    private func causeNSException() {
        let array = NSArray()
        let crash = array.object(at: 99)
        print("CRASHED: \(crash)")
    }
}
