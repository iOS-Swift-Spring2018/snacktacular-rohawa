//
//  Review.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class Review {
    var title: String
    var text: String
    var rating: Int
    var reviewUserID: String
    var date: Date
    var documentID: String
    
    var dictionary: [String: Any] {
        return ["title": title, "text": text, "rating": rating, "reviewUserID": reviewUserID, "date": date]
    }
    
    init(title: String, text: String, rating: Int, reviewUserID: String, date: Date, documentID: String) {
        self.title = title
        self.text = text
        self.rating = rating
        self.reviewUserID = reviewUserID
        self.date = date
        self.documentID = documentID
    }
    
    convenience init(dictionary: [String: Any]) {
        let title = dictionary["title"] as! String? ?? ""
        let text = dictionary["text"] as! String? ?? ""
        let rating = dictionary["rating"] as! Int? ?? 0
        let reviewUserID = dictionary["reviewUserID"] as! String? ?? ""
        let date = dictionary["date"] as! Date? ?? Date()
        self.init(title: title, text: text, rating: rating, reviewUserID: reviewUserID, date: date, documentID: "")
    }
    
    convenience init() {
        let reviewUserID = Auth.auth().currentUser?.uid ?? ""
        self.init(title: "", text: "", rating: 0, reviewUserID: reviewUserID, date: Date(), documentID: "")
    }
    
    func saveData(spot: Spot, completed: @escaping (Bool) -> () ) {
        let db = Firestore.firestore()
        
        let dataToSave = self.dictionary
        if self.documentID != "" { // save data to an existing document
            // get the path for the exiseting document
            let ref = db.collection("spots").document(spot.documentID).collection("reviews").document(self.documentID)
            ref.setData(dataToSave) { error in
                if let error = error {
                    print("*** ERROR: updating document \(self.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("Successfully updated documentID \(ref.documentID)")
                    completed(true)
                }
            }
        } else { // create a new document and save the data to that one.
            var ref: DocumentReference? = nil // Firestore will create the new documentID with a unique value, below
            ref = db.collection("spots").document(spot.documentID).collection("reviews").addDocument(data: dataToSave) { error in
                if let error = error {
                    print("*** ERROR: creating document \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("Successfully created documentID \(ref!.documentID)")
                    self.documentID = ref!.documentID
                    completed(true)
                }
            }
        }
    }
    
    func deleteData(spot: Spot, completed: @escaping (Bool) -> () ) {
        let db = Firestore.firestore()
        db.collection("spots").document(spot.documentID).collection("reviews").document(documentID).delete() { error in
            if error != nil {
                print("*** ERROR: couldn't delete document \(self.documentID) \(error!.localizedDescription)")
                completed(false)
            } else {
                completed(true)
            }
        }
        
    }
}
