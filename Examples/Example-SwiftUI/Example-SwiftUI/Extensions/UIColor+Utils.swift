//
//  UIColor+Utils.swift
//
//  Created by Mathew Gacy on 12/5/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import UIKit

extension UIColor {
    static func random() -> UIColor {
        UIColor(
            red: CGFloat(drand48()),
            green: CGFloat(drand48()),
            blue: CGFloat(drand48()),
            alpha: 1.0)
    }

    func image(_ size: CGSize = CGSize(width: 300, height: 300)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
