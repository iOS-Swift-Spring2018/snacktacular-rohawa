//
//  UIView+addBorder.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit

extension UIView {
    func addBorder(borderWidth: CGFloat, cornerRadius: CGFloat) {
        let borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = cornerRadius
    }
}
