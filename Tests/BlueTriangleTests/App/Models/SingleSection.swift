//
//  SingleSection.swift
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

/// Model for diffable data sources with a single section.
enum SingleSection: CaseIterable {
    case main

    static func makeInitialSnapshot<T: Hashable & Sendable>(for updated: [T])
    -> NSDiffableDataSourceSnapshot<Self, T> {
        var snapshot = NSDiffableDataSourceSnapshot<Self, T>()
        snapshot.appendSections([.main])
        snapshot.appendItems(updated, toSection: .main)
        return snapshot
    }
}

#endif
