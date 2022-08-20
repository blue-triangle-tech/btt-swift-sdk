//
//  PhotoCell.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import UIKit

final class PhotoCell: UICollectionViewCell {
    var photo: Photo?
    var loadingTask: Task<Void, Never>?

    // MARK: - Subviews

    let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        contentView.addSubview(activityIndicator)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            // activityIndicator
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            // imageView
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingTask?.cancel()
        loadingTask = nil
        render(.empty)
    }

    func render(_ viewState: ViewState<UIImage>) {
        switch viewState {
        case .empty:
            activityIndicator.stopAnimating()
            imageView.image = nil
        case .loading:
            activityIndicator.startAnimating()
            imageView.isHidden = true
        case .loaded(let image):
            activityIndicator.stopAnimating()
            imageView.image = image
            imageView.isHidden = false
        case .errror(let error):
            print("ERROR: \(error)")
            activityIndicator.stopAnimating()
        }
    }
}
