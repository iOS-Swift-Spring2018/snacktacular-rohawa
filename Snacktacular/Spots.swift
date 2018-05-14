//
//  Spots.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 4/20/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Spots {
    var spotArray = [Spot]()
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(completed: @escaping () -> ()) {
        db.collection("spots").addSnapshotListener { querySnapshot, error in
            guard error == nil else {
                print("*** ERROR: in the snapshotListener Spots.loadData() \(error!.localizedDescription)")
                return
            }
            self.spotArray = []
            for document in querySnapshot!.documents {
                let spot = Spot(dictionary: document.data())
                spot.documentID = document.documentID
                self.spotArray.append(spot)
            }
            completed()
        }
    }
}
