//
//  Reviews.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/13/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Reviews {
    var reviewArray = [Review]()
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(spot: Spot, completed: @escaping () -> ()) {
        guard spot.documentID != "" else {
            return
        }
        db.collection("spots").document(spot.documentID).collection("reviews").addSnapshotListener { querySnapshot, error in
            guard error == nil else {
                print("*** ERROR: in the snapshotListener Reviews.loadData() \(error!.localizedDescription)")
                return
            }
            self.reviewArray = []
            for document in querySnapshot!.documents {
                let review = Review(dictionary: document.data())
                review.documentID = document.documentID
                self.reviewArray.append(review)
            }
            completed()
        }
    }
}
