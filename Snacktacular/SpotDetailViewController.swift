//
//  SpotDetailViewController.swift
//  Snacktacular
//
//  Created by John Gallaugher on 3/23/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit

import UIKit
import MapKit
import GooglePlaces
import Contacts
import Firebase

class SpotDetailViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var averageRatingField: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var reviewButton: UIButton!
    
    var spot: Spot!
    var reviews: Reviews!
    var photos: Photos!
    var photo: Photo!
    let regionDistance: CLLocationDistance = 750 // in meters, about 1/2 mile
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var imagePicker = UIImagePickerController()
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        mapView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.dataSource = self
        collectionView.delegate = self
        imagePicker.delegate = self
        
        photos = Photos()
        
        if let spot = spot {
            nameField.text = spot.name
            addressField.text = spot.address
            disableTextEditing()
            saveBarButton.title = ""
            cancelBarButton.title = ""
            navigationController?.setToolbarHidden(true, animated: true)
        } else {
            spot = Spot()
            nameField.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
            addressField.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
            getLocation()
        }
        
        let region = MKCoordinateRegionMakeWithDistance(spot.coordinate, regionDistance, regionDistance)
        mapView.setRegion(region, animated: true)
        reviews = Reviews()
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("@@@ Starting viewDidAppear()")
        let averageRatingBeforeUpdate = spot.averageRating
        let numberOfReviewsBeforeUpdate = spot.numberOfReviews
        reviews.loadData(spot: spot) {
            self.tableView.reloadData()
            if self.reviews.reviewArray.count > 0 {
                var total = 0
                for review in self.reviews.reviewArray {
                    total += review.rating
                }
                let average = Double(total) / Double(self.reviews.reviewArray.count)
                self.averageRatingField.text = "\(average.roundTo(places: 1))"
                if average != averageRatingBeforeUpdate || self.reviews.reviewArray.count != numberOfReviewsBeforeUpdate {
                    self.spot.averageRating = average
                    self.spot.numberOfReviews = self.reviews.reviewArray.count
                    self.spot.saveData() { _ in
                    }
                }
            } else {
                self.averageRatingField.text = "-.-"
            }
        }
        
        photos.loadData(spot: spot) {
            self.collectionView.reloadData()
        }
    }
    
    func updateUserInterface() {
        nameField.text = spot.name
        addressField.text = spot.address
        updateMap()
    }
    
    func disableTextEditing() {
        nameField.backgroundColor = UIColor.clear
        nameField.isEnabled = false
        addressField.backgroundColor = UIColor.clear
        addressField.isEnabled = false
        nameField.addBorder(borderWidth: 0.0, cornerRadius: 5.0)
        addressField.addBorder(borderWidth: 0.0, cornerRadius: 5.0)
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(spot)
        mapView.setCenter(spot.coordinate, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        spot.name = nameField.text!
        spot.address = addressField.text!
        switch segue.identifier ?? "" {
        case "AddReview":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ReviewTableViewController
            destination.spot = spot
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        case "ShowReview":
            let destination = segue.destination as! ReviewTableViewController
            let selectedReview = tableView.indexPathForSelectedRow!.row
            destination.review = reviews.reviewArray[selectedReview]
            destination.spot = spot
        case "AddPhoto":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! PhotoTableViewController
            destination.spot = spot
            destination.photo = photo
        case "ShowPhoto":
            let destination = segue.destination as! PhotoTableViewController
            let selectedPhoto = collectionView.indexPathsForSelectedItems?.first
            destination.photo = photos.photoArray[selectedPhoto!.row]
            destination.spot = spot
        default:
            print("*** ERROR: Couldn't find a case for segue identifier \(segue.identifier!)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func saveCancelAlert(title: String, message: String, segueIdentifier: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            self.spot.saveData() { success in
                if success {
                    self.saveBarButton.title = "Done"
                    self.cancelBarButton.title = ""
                    self.navigationController?.setToolbarHidden(true, animated: false)
                    self.disableTextEditing()
                    if segueIdentifier == "AddReview" {
                        self.reviews.loadData(spot: self.spot) {
                            self.tableView.reloadData()
                        }
                        self.performSegue(withIdentifier: "AddReview", sender: nil)
                    } else if segueIdentifier == "AddPhoto" {
                        self.cameraLibraryAlert()
                    }
                } else {
                    print("*** ERROR: Could not save data in saveCancelAlert")
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func cameraLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.accessCamera()
        }
        let libraryAction = UIAlertAction(title: "Library", style: .default) { _ in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func textFieldEditingDidBegin(_ sender: UITextField) {
        for annotation in mapView.annotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        saveBarButton.isEnabled = !(nameField.text == "")
    }
    
    @IBAction func textFieldReturnPressed(_ sender: UITextField) {
        sender.resignFirstResponder()
        spot.name = nameField.text!
        spot.address = addressField.text!
        updateUserInterface()
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        sender.resignFirstResponder()
        spot.name = nameField.text!
        spot.address = addressField.text!
        updateUserInterface()
    }
    
    
    @IBAction func reviewButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This Venue Has Not Been Saved", message: "You must save this venue before you can review it.", segueIdentifier: "AddReview")
        } else {
            performSegue(withIdentifier: "AddReview", sender: nil)
        }
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This Venue Has Not Been Saved", message: "You must save this venue before you can add a photo", segueIdentifier: "AddPhoto")
        } else {
            cameraLibraryAlert()
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        spot.saveData { (success) in
            if success {
                self.performSegue(withIdentifier: "UnwindFromSpotDetailViewControllerWithSegue", sender: sender)
            } else {
                self.showAlert(title: "Save Failed", message: "Could not save data. Try again, or contact developer")
            }
        }
    }
    
    @IBAction func lookupButtonPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
}

extension SpotDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Spot else {
            return nil
        }
        let identifer = "Marker"
        var annotationView: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifer) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            annotationView = dequeuedView
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            annotationView.canShowCallout = true
            //annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            let mapButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
            mapButton.setBackgroundImage(UIImage(named: "open-maps"), for: UIControlState())
            annotationView.rightCalloutAccessoryView = mapButton
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let launchOptions = [MKLaunchOptionsMapCenterKey: spot.coordinate]
        spot.mapItem().openInMaps(launchOptions: launchOptions)
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let view = views.first(where: {$0.annotation is MKUserLocation}) {
            view.isEnabled = false
        }
    }
}

extension SpotDetailViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        spot.name = place.name
        spot.address = place.formattedAddress ?? ""
        spot.coordinate = place.coordinate
        dismiss(animated: true, completion: nil)
        updateUserInterface()
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension SpotDetailViewController: CLLocationManagerDelegate {
    
    func getLocation(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func handleLocationAuthorizationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            showAlertToPrivacySettings(title: "User has not authorized location services", message: "Select 'Settings' below to open device settings and enable location services for this app.")
        case .restricted:
            showAlert(title: "Location services denied", message: "It may be that parental controls are restricting location use in this app")
        }
    }
    
    func showAlertToPrivacySettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else {
            print("Something went wrong getting the UIApplicationOpenSettingsURLString")
            return
        }
        let settingsActions = UIAlertAction(title: "Settings", style: .default) { value in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsActions)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard spot.name == "" else {
            return
        }
        let geoCoder = CLGeocoder()
        var name = ""
        var address = ""
        currentLocation = locations.last
        let currentLatitude = currentLocation.coordinate.latitude
        let currentLongitude = currentLocation.coordinate.longitude
        spot.coordinate = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {placemarks, error in
            if placemarks != nil {
                let placemark = placemarks?.last
                name = (placemark?.name)!
                if let postalAddress = placemark?.postalAddress {
                    address = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                }
            } else {
                print("Error retrieving place. Error code: \(error!)")
            }
            self.spot.name = name
            self.spot.address = address
            self.updateUserInterface()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location.")
    }
}

extension SpotDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.reviewArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reviewCell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as! SpotReviewsTableViewCell
        reviewCell.review = reviews.reviewArray[indexPath.row]
        return reviewCell
    }
}

extension SpotDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! SpotPhotosCollectionViewCell
        // photoCell.photo = photos.photoArray[indexPath.row]
        photoCell.photoImageView.image = photos.photoArray[indexPath.row].image
        return photoCell
    }
}

extension SpotDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        photo = Photo()
        photo.image = info[UIImagePickerControllerOriginalImage] as! UIImage
        photos.photoArray.append(photo)
        dismiss(animated: true) {
            self.performSegue(withIdentifier: "AddPhoto", sender: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}
