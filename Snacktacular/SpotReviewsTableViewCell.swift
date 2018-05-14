//
//  SpotReviewsTableViewCell.swift
//  Snacktacular
//
//  Created by John Gallaugher on 3/23/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit

class SpotReviewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var reviewTitleLabel: UILabel!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet var starImageCollection: [UIImageView]!
    
    // This is a property observer, the didSet keyword executes the code below whenever the observer has been changed.
    var review: Review! {
        didSet {
            reviewTitleLabel.text = review.title
            reviewTextLabel.text = review.text
            for index in 0..<starImageCollection.count {
                let image = UIImage(named: ( index < review.rating ? "star-filled" : "star-empty" ) )
                starImageCollection[index].image = image
            }
        }
    }
}
