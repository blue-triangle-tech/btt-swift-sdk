//
//  Collection+Utils.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Collection {
    func splitTuple() -> ([Element], [Element]) {
        enumerated().reduce(into: ([Element](), [Element]())) { accumulate, element in
            element.0 % 2 == 0 ? accumulate.0.append(element.1) : accumulate.1.append(element.1)
        }
    }
}
