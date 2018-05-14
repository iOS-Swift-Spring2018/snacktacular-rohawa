//
//  SnackUser.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import Firebase

class SnackUser {
    var email: String
    var displayName: String
    var photoURL: String
    var userSince: Date
    var documentID: String
    
    var dictionary: [String: Any] {
        return ["email": email, "displayName": displayName, "photoURL": photoURL, "userSince": userSince]
    }
    
    init(email: String, displayName: String, photoURL: String, userSince: Date, documentID: String) {
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.userSince = userSince
        self.documentID = documentID
    }
    
    convenience init (user: User) {
        self.init(email: user.email ?? "", displayName: user.displayName ?? "", photoURL: (user.photoURL != nil ? "\(user.photoURL!)" : ""), userSince: Date(), documentID: user.uid)
    }
    
    convenience init (userID: String) {
        self.init(email: "", displayName: "", photoURL: "", userSince: Date(), documentID: userID)
    }
    
    func loadData(completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(documentID)
        userRef.getDocument { document, error in
            guard error == nil else {
                print("*** ERROR: in SnackUser accessing document for user \(self.documentID) \(error!.localizedDescription)")
                return completed(false)
            }
            guard let dictionary = document?.data() else {
                print("*** ERROR: could not create a dictionary from documentID \(self.documentID)")
                return completed(false)
            }
            self.email = dictionary["email"] as! String? ?? ""
            self.displayName = dictionary["displayName"] as! String? ?? ""
            self.photoURL = dictionary["photoURL"] as! String? ?? ""
            self.userSince = dictionary["userSince"] as! Date? ?? Date()
            completed(true)
        }
    }
    
    func saveIfNewUser() {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(documentID)
        userRef.getDocument { document, error in
            guard error == nil else {
                print("*** ERROR: in accessing document with uid \(self.documentID) \(error!.localizedDescription)")
                return
            }
            guard document?.exists == false else {
                print("Just a reminder, the user already exists so we are not creating a doucment for \(self.documentID)")
                return
            }
            self.saveData()
        }
    }
    
    private func saveData() {
        let db = Firestore.firestore()
        let dataToSave: [String: Any] = self.dictionary
        db.collection("users").document(documentID).setData(dataToSave) { error in
            if let error  = error {
                print("*** ERROR: adding user \(self.documentID) \(error.localizedDescription)")
            }
        }
    }
}
