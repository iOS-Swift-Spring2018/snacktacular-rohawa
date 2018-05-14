//
//  PhotoTableViewController.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit
import Firebase

class PhotoTableViewController: UITableViewController {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var postedByLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    var spot: Spot!
    var photo: Photo!
    let dateFormatter = DateFormatter()
    let currentUser = Auth.auth().currentUser!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        guard spot != nil else {
            print("*** ERROR: for some reason spot was nil when PhotoTableViewController loaded.")
            return
        }
        
        if photo == nil {
            photo = Photo()
        }
        updateUserInterface()
    }
    
    func updateUserInterface() {
        photoImageView.image = photo.image
        descriptionField.text = photo.description
        let formattedDate = dateFormatter.string(from: photo.date)
        dateLabel.text = formattedDate
        if photo.documentID != "" { // this is an existing photo
            if photo.postedBy != currentUser.uid { // the photo was not posted by the current user
                let postingUser = SnackUser(userID: photo.postedBy)
                postingUser.loadData() { success in
                    if success {
                        self.postedByLabel.text = postingUser.email
                    } else {
                        self.postedByLabel.text = "unknown user"
                    }
                }
                saveBarButton.title = ""
                cancelBarButton.title = ""
                descriptionField.isEnabled = false
                descriptionField.backgroundColor = UIColor.white
            } else { // this is a review from the current user
                self.navigationItem.leftItemsSupplementBackButton = false
                self.saveBarButton.title = "Update"
                deleteButton.isHidden = false
                descriptionField.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
                postedByLabel.text = "You"
            }
        } else { // this is a new review
            descriptionField.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
            postedByLabel.text = "You"
        }
        enableDisableSaveButton()
    }
    
    func enableDisableSaveButton() {
        if descriptionField.text != "" {
            saveBarButton.isEnabled = true
        } else {
            saveBarButton.isEnabled = false
        }
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func saveThenSegue() {
        photo.description = descriptionField.text
        photo.saveData(spot: spot) { success in
            if success {
                self.leaveViewController()
            } else {
                print("*** ERROR: Did not successfullly save from photo.saveData")
            }
        }
    }
    
    @IBAction func descriptionDoneKeyPressed(_ sender: UITextField) {
        saveThenSegue()
    }
    
    @IBAction func descriptionChanged(_ sender: UITextField) {
        enableDisableSaveButton()
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        //TODO: Delete code here
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        saveThenSegue()
    }
    
}
