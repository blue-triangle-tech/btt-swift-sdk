//
//  PhotoDetailViewController.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 9/4/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import UIKit

class PhotoDetailViewController: UIViewController {
    private let imageLoader: ImageLoading
    private let photo: Photo

    var timer: BTTimer!

    // MARK: - Subviews

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    init(imageLoader: ImageLoading, photo: Photo) {
        self.imageLoader = imageLoader
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start timer and retain reference to it
        let page = Page(pageName: "Photo_Detail",
                        brandValue: 0.5,
                        pageType: "Other_Page_Type",
                        referringURL: "https://mobelux.com/a",
                        url: "https://mobelux.com/photo",
                        customVariables: nil,
                        customCategories: nil,
                        customNumbers: nil)

        timer = BlueTriangle.startTimer(page: page)

        view.backgroundColor = .systemBackground
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        Task {
            await loadPhoto()
        }
    }

    // MARK: -

    @MainActor
    private func loadPhoto() async {
        do {
            guard let image = try await imageLoader.load(photo.url) else {
                // Stop timer
                print("ERROR: Missing Image")
                BlueTriangle.endTimer(timer, purchaseConfirmation: nil)
                return
            }

            imageView.image = image

            // Stop timer
            let purchaseConfirmation = PurchaseConfirmation(cartValue: 99.99)
            BlueTriangle.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
        } catch {
            // Stop timer
            print("ERROR: \(error)")
            BlueTriangle.endTimer(timer, purchaseConfirmation: nil)
        }
    }
}
