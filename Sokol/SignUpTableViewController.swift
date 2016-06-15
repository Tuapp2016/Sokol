//
//  SignUpTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 12/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class SignUpTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView:UIImageView!
    @IBOutlet var nameText:UITextField!
    @IBOutlet var lastNameText:UITextField!
    @IBOutlet var birthdayText:UITextField!
    @IBOutlet var emailText:UITextField!
    @IBOutlet var passwordText:UITextField!
    
    
    var imageProfileSelected = false
    var alertController:UIAlertController?
    var datePicker:UIDatePicker?
    
    let ref = Firebase(url:"sokolunal.firebaseio.com")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0{
            let alertController = UIAlertController(title: "Chose a photo", message: nil, preferredStyle: .ActionSheet)
            let cameraAction =  UIAlertAction(title: "Camera", style: .Default, handler: {
                (actioin:UIAlertAction) in
                if UIImagePickerController.isSourceTypeAvailable(.Camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing = false
                    imagePicker.delegate = self
                    imagePicker.sourceType = .Camera
                    
                    self.presentViewController(imagePicker, animated: true, completion: nil)
                    
                }
            })
            let libraryAction =  UIAlertAction(title: "Photo library", style: .Default, handler: {
                (action:UIAlertAction) in
                if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
                   let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing =  false
                    imagePicker.delegate = self
                    imagePicker.sourceType = .PhotoLibrary
                    
                    self.presentViewController(imagePicker, animated: true, completion: nil)
                }
            })
            alertController.addAction(cameraAction)
            alertController.addAction(libraryAction)
            presentViewController(alertController, animated: true, completion: nil)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        imageView.image = Utilities.resizeImage(info[UIImagePickerControllerOriginalImage] as! UIImage, newWidth: 200.0, newHeight: 200.0)
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        let leadingConstraint = NSLayoutConstraint(item: imageView, attribute:.Leading, relatedBy: .Equal, toItem: imageView.superview, attribute: .Leading, multiplier: 1, constant: 0)
        leadingConstraint.active = true
        let trailingConstraint = NSLayoutConstraint(item: imageView, attribute:.Trailing, relatedBy:.Equal, toItem: imageView.superview, attribute: .Trailing, multiplier: 1, constant: 0)
        trailingConstraint.active = true
        let topConstraint = NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: imageView.superview, attribute: .Top, multiplier: 1, constant: 0)
        topConstraint.active = true
        let bottomConstraint = NSLayoutConstraint(item: imageView, attribute:.Bottom, relatedBy: .Equal, toItem: imageView.superview, attribute:.Bottom, multiplier: 1, constant: 0)
        bottomConstraint.active = true
        imageProfileSelected =  true
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func dataPickerSelector(sender: AnyObject) {
        view.endEditing(true)
        alertController = UIAlertController(title: "Date", message: "\n\n\n\n\n\n\n", preferredStyle: .ActionSheet)
        let height:NSLayoutConstraint = NSLayoutConstraint(item: alertController!.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 250.0)
        let width:NSLayoutConstraint = NSLayoutConstraint(item: alertController!.view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 350.0)
        
        alertController!.view.addConstraint(height)
        alertController!.view.addConstraint(width)
        
        let buttonsFrame:CGRect = CGRectMake(5.0, 10.0, 340.0, 40.0)
        let buttonsView = UIView(frame: buttonsFrame)
        
        let buttonCancelFrame:CGRect = CGRectMake(5.0, 15.0, 100.0, 30.0)
        let buttonCancel:UIButton = UIButton(frame: buttonCancelFrame)
        buttonCancel.setTitle("Cancel", forState: .Normal)
        buttonCancel.setTitleColor(UIColor.blueColor(), forState: .Normal)
        buttonCancel.addTarget(self, action: "dismissAlertController", forControlEvents: .TouchUpInside)
        let buttonDoneFrame:CGRect = CGRectMake(240.0, 15.0, 100.0, 30.0)
        let buttonDone:UIButton = UIButton(frame:buttonDoneFrame)
        buttonDone.setTitle("Done",forState: .Normal)
        buttonDone.setTitleColor(UIColor.blueColor(), forState: .Normal)
        buttonDone.addTarget(self, action: "setBirthdayDate", forControlEvents: .TouchUpInside)
        buttonsView.addSubview(buttonCancel)
        buttonsView.addSubview(buttonDone)

        let pickerFrame:CGRect = CGRectMake(5.0, 50.0, 340.0, 170.0)
        datePicker = UIDatePicker(frame:pickerFrame)
        datePicker!.datePickerMode = .Date
        datePicker!.setDate(NSDate(), animated: true)
        datePicker!.maximumDate = NSDate()
        
        alertController!.view.addSubview(buttonsView)
        alertController!.view.addSubview(datePicker!)
        presentViewController(alertController!, animated: true, completion: nil)
        
        
    }
    
    func dismissAlertController(){
        alertController!.dismissViewControllerAnimated(true, completion: nil)
    }
    func setBirthdayDate(){
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        birthdayText.text = dateFormatter.stringFromDate(datePicker!.date)
        alertController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func singUp() {
        let name = nameText.text
        let lastName = lastNameText.text
        let birthday =  birthdayText.text
        let email =  emailText.text
        let password =  passwordText.text
        let imageProfile = imageView.image
        if(imageProfileSelected && name?.characters.count>0 && lastName?.characters.count>0 && birthday?.characters.count>0 && Utilities.isValidEmail(email!) && password?.characters.count>5){
            let imageEncode64 = Utilities.imageToBase64(imageProfile: imageProfile!)
            //TODO: We should create the user with the information that she/he provied us
            ref.createUser(email!, password: password,
                           withValueCompletionBlock: { error, result in
                            if error != nil {
                                // There was an error creating the account
                                self.presentViewController(Utilities.alertMessage("Error", message: "There was an error\nThe possible problems are:\nAn internet issue\nThe email is already registerd with another user"), animated: true, completion: nil)
                            }else{
                                /*let successMessage = UIAlertController(title: "Success", message: "The account was created", preferredStyle: .Alert)
                                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                                successMessage.addAction(okAction)
                                self.presentViewController(successMessage, animated: true, completion: nil)*/
                                let newUser = [
                                    "provider": "password",
                                    "name": name! + " " + lastName!,
                                    "birthday": birthday!,
                                    "email":email!,
                                    "profileImage":imageEncode64
                                ]
                                let uid = result["uid"] as? String
                                let userRef = self.ref.childByAppendingPath("users")
                                let user = userRef.childByAppendingPath(uid)
                                user.setValue(newUser)
                                self.performSegueWithIdentifier("unWindToHomeScreen", sender: nil)
                                self.ref.removeAllObservers()
                                
                            }
            })
            
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "All the fields are required or some fields are incorrect"), animated: true, completion: nil)
        }
    }
    
    
}
