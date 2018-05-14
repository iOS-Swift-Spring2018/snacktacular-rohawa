//
//  Double+roundTo.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation

extension Double {
    func roundTo(places: Int) -> Double {
        let tenToPower = pow(10.0, Double(places))
        let rounded = (self * tenToPower).rounded() / tenToPower
        return rounded
    }
}
