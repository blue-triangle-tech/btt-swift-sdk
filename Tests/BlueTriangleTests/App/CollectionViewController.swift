//
//  CollectionViewController.swift
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
import BlueTriangle

typealias CollectionViewLayoutBuilder = () -> UICollectionViewLayout

struct LayoutBuilder {
    let fractionalItemWidth: CGFloat
    let fractionalItemHeight: CGFloat

    static let standard: Self = {
        .init(fractionalItemWidth: (1.0 / 3.0),
              fractionalItemHeight: 1.0)
    }()
}

@available(iOS 14.0, tvOS 14.0, *)
final class CollectionViewController: UIViewController {
}
#endif
