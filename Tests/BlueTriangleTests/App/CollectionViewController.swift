//
//  CollectionViewController.swift
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import UIKit
@testable import BlueTriangle

typealias CollectionViewLayoutBuilder = () -> UICollectionViewLayout

struct LayoutBuilder {
    let fractionalItemWidth: CGFloat
    let fractionalItemHeight: CGFloat

    func buildLayout() -> UICollectionViewLayout {
        let provider: UICollectionViewCompositionalLayoutSectionProvider = { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionalItemWidth),
                                                  heightDimension: .fractionalHeight(fractionalItemHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalHeight(0.25))
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

@available(iOS 14.0, *)
final class CollectionViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<SingleSection, Photo>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SingleSection, Photo>
    typealias CellRegistration = UICollectionView.CellRegistration<ImageCell, Photo>

    private let networkClient: NetworkClientMock
    private let layoutBuilder: LayoutBuilder
    private lazy var dataSource = makeDataSource(for: collectionView)
    private var loadingTask: Task<Void, Never>?

    var timer: BTTimer?

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layoutBuilder.buildLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    init(networkClient: NetworkClientMock, layoutBuilder: LayoutBuilder = .standard) {
        self.networkClient = networkClient
        self.layoutBuilder = layoutBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        timer = BlueTriangle.startTimer(page: Page(pageName: "PerformanceTest"))
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

    private func fetchData() {
        loadingTask = Task {
            do {
                let albums = try await networkClient.fetchAlbums()
                guard let album = albums.first else {
                    return
                }
                let photos = try await networkClient.fetchPhotos(albumId: album.id)

                let snapshot = SingleSection.makeInitialSnapshot(for: photos)
                dataSource.apply(snapshot)

                // FIXME: end timer after all cells load
                BlueTriangle.endTimer(timer!)

                loadingTask?.cancel()
                loadingTask = nil
            } catch {
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        print("ERROR: \(error)")
    }

    // MARK: - CollectionView

    private func makeCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, indexPath, photo in
            self?.configure(cell: cell, with: photo)
        }
    }

    private func configure(cell: ImageCell, with photo: Photo) {
        cell.photo = photo
        cell.render(.loading)
        cell.loadingTask = Task {
            do {
                let imageData = try await networkClient.fetchPhoto(url: photo.thumbnailUrl)
                guard cell.photo?.id == photo.id else {
                    return
                }
                guard let image = UIImage(data: imageData) else {
                    cell.render(.empty)
                    return
                }
                cell.render(.loaded(image))
            } catch {
                cell.render(.errror(error))
            }
        }
    }

    func makeDataSource(
        for collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<SingleSection, Photo> {
        let cellRegistration = makeCellRegistration()
        return UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { [weak self] collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistration,
                    for: indexPath,
                    item: item
                )
            })
    }
}
