//
//  SignUpTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 12/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class SignUpTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView:UIImageView!
    @IBOutlet var nameText:UITextField!
    @IBOutlet var lastNameText:UITextField!
    @IBOutlet var birthdayText:UITextField!
    @IBOutlet var emailText:UITextField!
    @IBOutlet var passwordText:UITextField!
    
    var alertController:UIAlertController?
    var datePicker:UIDatePicker?

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

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
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
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func dataPickerSelector(sender: AnyObject) {
        alertController = UIAlertController(title: "Date", message: "\n\n\n\n\n\n\n", preferredStyle: .ActionSheet)
        
        let buttonsFrame:CGRect = CGRectMake(5.0, 10.0, 350.0, 40.0)
        let buttonView = UIView(frame: buttonsFrame)
        
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
        buttonView.addSubview(buttonCancel)
        buttonView.addSubview(buttonDone)

        let pickerFrame:CGRect = CGRectMake(5.0, 50.0, 350.0, 150.0)
        datePicker = UIDatePicker(frame:pickerFrame)
        datePicker!.datePickerMode = .Date
        datePicker!.setDate(NSDate(), animated: true)
        datePicker!.maximumDate = NSDate()
        
        alertController!.view.addSubview(buttonView)
        alertController!.view.addSubview(datePicker!)
        /*let doneAction =  UIAlertAction(title: "Done", style: .Default, handler: {
            (action:UIAlertAction) in
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            //dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
            print("date selected \(datePicker.date)")
        })*/
        //alertController.addAction(doneAction)
        presentViewController(alertController!, animated: true, completion: nil)
        
        
    }
    
    func dismissAlertController(){
        alertController!.dismissViewControllerAnimated(true, completion: nil)
    }
    func setBirthdayDate(){
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        birthdayText.text = dateFormatter.stringFromDate(datePicker!.date)
        alertController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
   
   
    
}
