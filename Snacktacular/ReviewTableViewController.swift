//
//  ReviewTableViewController.swift
//  Snacktacular
//
//  Created by Rohan Pahwa on 5/14/18.
//  Copyright © 2018 John Gallaugher. All rights reserved.
//

import UIKit
import Firebase

class ReviewTableViewController: UITableViewController {
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var postedByLabel: UILabel!
    @IBOutlet weak var reviewTitleField: UITextField!
    @IBOutlet weak var reviewDateLabel: UILabel!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet var starButtonCollection: [UIButton]!
    @IBOutlet weak var starButtonView: UIView!
    
    var curentUser = Auth.auth().currentUser
    var review: Review!
    var spot: Spot!
    let dateFormatter = DateFormatter()
    var rating = 0 {
        didSet {
            review.rating = rating
            for index in 0...starButtonCollection.count-1 {
                let image = UIImage(named: (starButtonCollection[index].tag < rating ? "star-filled" : "star-empty"))
                starButtonCollection[index].setImage(image, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        guard spot != nil else {
            print("*** ERROR: No spot passed to ReviewTableViewController.swift")
            return
        }
        
        if review == nil {
            review = Review()
        }
        updateUserInterface()
    }
    
    func updateUserInterface() {
        nameLabel.text = spot.name
        addressLabel.text = spot.address
        reviewTitleField.text = review.title
        reviewTextView.text = review.text
        rating = review.rating
        let formattedDate = dateFormatter.string(from: review.date)
        reviewDateLabel.text = "posted: \(formattedDate)"
        if review.documentID != "" { // this is an existing review
            if review.reviewUserID != curentUser?.uid { // the review was not posted by the current user
                let postingUser = SnackUser(userID: review.reviewUserID)
                postingUser.loadData() { success in
                    if success {
                        self.postedByLabel.text = "Posted by: \(postingUser.email)"
                    } else {
                        self.postedByLabel.text = "Posted by: unknown user"
                    }
                }
                saveBarButton.title = ""
                cancelBarButton.title = ""
                reviewTitleField.isEnabled = false
                reviewTitleField.backgroundColor = UIColor.white
                reviewTextView.isEditable = false
                reviewTextView.backgroundColor = UIColor.white
                for starButton in starButtonCollection {
                    starButton.backgroundColor = UIColor.white
                    starButton.adjustsImageWhenDisabled = false
                    starButton.isEnabled = false
                }
            } else { // this is a review from the current user
                self.navigationItem.leftItemsSupplementBackButton = false
                self.saveBarButton.title = "Update"
                deleteButton.isHidden = false
                addBordersToEditableObjects()
            }
        } else { // this is a new review
            addBordersToEditableObjects()
        }
        enableDisableSaveButton()
    }
    
    func addBordersToEditableObjects() {
        reviewTitleField.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
        reviewTextView.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
        starButtonView.addBorder(borderWidth: 0.5, cornerRadius: 5.0)
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func enableDisableSaveButton(){
        if reviewTitleField.text != "" {
            saveBarButton.isEnabled = true
        } else {
            saveBarButton.isEnabled = false
        }
    }
    
    @IBAction func titleChanged(_ sender: UITextField) {
        enableDisableSaveButton()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        review.title = reviewTitleField.text!
        review.text = reviewTextView.text!
        review.saveData(spot: spot) { success in
            if success {
                self.leaveViewController()
            } else {
                self.showAlert(title: "Error Occurred", message: "Could Not Save Review")
            }
        }
    }
    
    @IBAction func starButtonPressed(_ sender: UIButton) {
        rating = Int(sender.tag) + 1
    }
    
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        review.deleteData(spot: spot) { success in
            if success {
                self.leaveViewController()
            } else {
                self.showAlert(title: "Error Occurred", message: "Could Not Delete Review")
            }
        }
    }
}
