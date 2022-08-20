//
//  PhotoCollectionViewController.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import UIKit

typealias CollectionViewLayoutBuilder = () -> UICollectionViewLayout

struct LayoutBuilder {
    let fractionalItemWidth: CGFloat
    let fractionalItemHeight: CGFloat

    func buildLayout() -> UICollectionViewLayout {
        let provider: UICollectionViewCompositionalLayoutSectionProvider = { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionalItemWidth),
                                                 heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalWidth(fractionalItemWidth))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        return UICollectionViewCompositionalLayout(sectionProvider: provider, configuration: config)
    }

    static let standard: Self = {
        .init(fractionalItemWidth: (1.0 / 3.0),
              fractionalItemHeight: 1.0)
    }()
}

final class PhotoCollectionViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<SingleSection, Photo>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SingleSection, Photo>
    typealias CellRegistration = UICollectionView.CellRegistration<PhotoCell, Photo>

    private let jsonPlaceholder: PlaceholderServiceProtocol
    private let layoutBuilder: LayoutBuilder
    private lazy var dataSource = makeDataSource(for: collectionView)

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layoutBuilder.buildLayout())
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    init(jsonPlaceholder: PlaceholderServiceProtocol, layoutBuilder: LayoutBuilder = .standard) {
        self.jsonPlaceholder = jsonPlaceholder
        self.layoutBuilder = layoutBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        fetchData()
    }

    // MARK: - Networking

    private func fetchData() {
    }

    private func handleError(_ error: Error) {
    }
}

// MARK: - CollectionView Support
private extension PhotoCollectionViewController {
    private func makeCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, indexPath, photo in
            self?.configure(cell: cell, with: photo)
        }
    }

    private func configure(cell: PhotoCell, with photo: Photo) {
        cell.photo = photo
        cell.render(.loading)
        cell.loadingTask = Task {
            // ...
        }
    }

    func makeDataSource(
        for collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<SingleSection, Photo> {
        let cellRegistration = makeCellRegistration()
        return UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistration,
                    for: indexPath,
                    item: item
                )
            })
    }
}

// MARK: - UICollectionViewDelegate
extension PhotoCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        // ...
    }
}
