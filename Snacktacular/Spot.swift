//
//  Spot.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 4/20/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Contacts
import Firebase

class Spot: NSObject, MKAnnotation {
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    var averageRating: Double
    var numberOfReviews: Int
    var postingUserID: String
    var documentID: String
    
    var latitude: CLLocationDegrees {
        return coordinate.latitude
    }
    
    var longitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        return address
    }
    
    var dictionary: [String: Any] {
        return ["name": name, "address": address, "latitude": latitude, "longitude": longitude, "averageRating": averageRating, "numberOfReviews": numberOfReviews, "postingUserID": postingUserID]
        
    }
    
    init(name: String, address: String, coordinate: CLLocationCoordinate2D, averageRating: Double, numberOfReviews: Int, postingUserID: String, documentID: String) {
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.averageRating = averageRating
        self.numberOfReviews = numberOfReviews
        self.postingUserID = postingUserID
        self.documentID = documentID
    }
    
    convenience override init() {
        self.init(name: "", address: "", coordinate: CLLocationCoordinate2D(), averageRating: 0.0, numberOfReviews: 0, postingUserID: "", documentID: "")
    }
    
    convenience init (dictionary: [String: Any]) {
        let name = dictionary["name"] as! String? ?? ""
        let address = dictionary["address"] as! String? ?? ""
        let averageRating = dictionary["averageRating"] as! Double? ?? 0.0
        let numberOfReviews = dictionary["numberOfReviews"] as! Int? ?? 0
        let latitude = dictionary["latitude"] as! CLLocationDegrees? ?? 0.0
        let longitude = dictionary["longitude"] as! CLLocationDegrees? ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        let documentID = dictionary["documentID"] as! String? ?? ""
        self.init(name: name, address: address, coordinate: coordinate, averageRating: averageRating, numberOfReviews: numberOfReviews, postingUserID: postingUserID, documentID: documentID)
    }
    
    func saveData(completed: @escaping (Bool) -> () ) {
        let db = Firestore.firestore()
        
        // Grab the user ID
        guard let postingUserID = Auth.auth().currentUser?.uid else {
            print("**** ERROR: Could not save data because we don't have a valid postingUserID")
            return completed(false)
        }
        self.postingUserID = postingUserID
        let dataToSave = self.dictionary
        if self.documentID != "" { // save data to an existing document
            // get the path for the exiseting document
            let ref = db.collection("spots").document(self.documentID)
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
            ref = db.collection("spots").addDocument(data: dataToSave) { error in
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
    
    func mapItem() -> MKMapItem {
        let addressDictionary = [CNPostalAddressStreetKey: subtitle!]
        let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
}
