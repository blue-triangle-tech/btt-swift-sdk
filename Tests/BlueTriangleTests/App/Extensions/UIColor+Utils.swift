//
//  UIColor+Image.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 1/7/22.
//

import UIKit

extension UIColor {
    func pngData(_ size: CGSize = CGSize(width: 1, height: 1)) -> Data {
        return UIGraphicsImageRenderer(size: size).pngData { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension UIColor {
    static let sampleColors: [UIColor] = [
        .red,
        .yellow,
        .blue,
        .green,
        .orange
    ]
}
