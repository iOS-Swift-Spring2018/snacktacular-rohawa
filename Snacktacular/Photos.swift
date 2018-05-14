//
//  Photos.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Photos {
    var photoArray = [Photo]()
    var db: Firestore!
    var storage: Storage!
    
    init() {
        db = Firestore.firestore()
        storage = Storage.storage()
    }
    
    func loadData(spot: Spot, completed: @escaping () -> ()) {
        guard spot.documentID != "" else {
            return
        }
        db.collection("spots").document(spot.documentID).collection("photos").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("*** ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.photoArray = []
            var loadAttempts = 0
            let storageRef = self.storage.reference().child(spot.documentID)
            for document in querySnapshot!.documents {
                let photo = Photo(dictionary: document.data())
                photo.documentID = document.documentID
                self.photoArray.append(photo)
                // Create a ref to hold the new photo that we're saving
                let photoRef = storageRef.child(photo.documentID)
                photoRef.getData(maxSize: 25 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("*** ERROR: An error occurred while reading data from file ref: \(photoRef), error \(error.localizedDescription)")
                    } else {
                        let image = UIImage(data: data!)
                        photo.image = image!
                    }
                    loadAttempts += 1
                    if loadAttempts >= querySnapshot!.documents.count {
                        print("Load attemps = \(loadAttempts)")
                        completed()
                    }
                }
            }
        }
    }
}
