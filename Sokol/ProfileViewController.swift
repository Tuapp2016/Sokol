//
//  ProfileViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit

class ProfileViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let titleTwitterAndGoogle:[String] = ["Name","Email","Twitter thoughts"]
    let titleFacebook:[String] = ["Name","Email"]
    let titleSokol:[String] = ["Name","Email","Birthday"]
    let titleButtons = ["Change email","Change password"]
    var valueTwitter:[String]? = ["",""]
    var valueGoogle:[String]? = ["",""]
    var valueSokol:[String]? = ["","",""]
    var valueFacebook:[String]? = ["",""]
    var profileImage:UIImage?
    var base:String?
    var changeEmaillAlert:UIAlertController?
    var changePasswordAlert:UIAlertController?
    var emailText:UITextField?
    var oldPassword:UITextField?
    var newPassword:UITextField?
    var newEmail:UITextField?
    var blurEffectView:UIVisualEffectView?
    var whiteRoundedView : UIView?
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    let ref =  FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .None
        if traitCollection.forceTouchCapability == .Available{
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        FIRAuth.auth()?.addAuthStateDidChangeListener({(auth,user) in
            if user == nil {
                let userRef = self.ref.child("users")
                if let uid = Utilities.user?.uid{
                    let userId =  userRef.child(uid)
                    userId.removeAllObservers()
                }
                
                Utilities.user = nil
                self.dismissViewControllerAnimated(true, completion: {})
            }
        })
        
        //self.automaticallyAdjustsScrollViewInsets = false;
        if let user = Utilities.user {
            switch user.providerData[0].providerID {
                
            case "facebook.com":
                let userRef = ref.child("users")
                let userId =  userRef.child(user.uid)
                userId.observeEventType(.Value, withBlock: {(snapshot) in
                    
                    let values = snapshot.value as! [String:AnyObject]
                    
                    let email = values["email"] as!String
                    let name = values["name"] as! String
                    
                    let photoURL = values["profileImage"] as! String
                    if photoURL == "There is no an image available" {//We use an image for default
                        self.profileImage = UIImage(named: "profile")
                    }else{
                        self.imageFromURL(photoURL)
                    }
                    self.valueFacebook = [name,email]
                    //self.profileImage = Utilities.base64ToImage(values["profileImage"] as! String)
                    //self.imageFromURL(values["profileImage"] as! String)
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.tableView.reloadData()
                    })
                })
                
            case "google.com":
                let userRef = ref.child("users")
                let userId =  userRef.child(user.uid)
                userId.observeEventType(.Value, withBlock: {(snapshot) in
                    
                    let values = snapshot.value as! [String:AnyObject]
                    
                    let email = values["email"] as!String
                    let name = values["name"] as! String
                    
                    let photoURL = values["profileImage"] as! String
                    if photoURL == "There is no an image available" {//We use an image for default
                        self.profileImage = UIImage(named: "profile")
                    }else{
                        self.imageFromURL(photoURL)
                    }
                    self.valueGoogle = [name,email]
                    //self.profileImage = Utilities.base64ToImage(values["profileImage"] as! String)
                    //self.imageFromURL(values["profileImage"] as! String)
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.tableView.reloadData()
                    })
                })

                
            case "twitter.com":
                let userRef = ref.child("users")
                let userId =  userRef.child(user.uid)
                userId.observeEventType(.Value, withBlock: {(snapshot) in
                    
                    let values = snapshot.value as! [String:AnyObject]
                    
                    let email = values["email"] as!String
                    let name = values["name"] as! String
                    
                    let photoURL = values["profileImage"] as! String
                    if photoURL == "There is no an image available" {//We use an image for default
                        self.profileImage = UIImage(named: "profile")
                    }else{
                        self.imageFromURL(photoURL)
                    }
                    self.valueTwitter = [name,email]
                    //self.profileImage = Utilities.base64ToImage(values["profileImage"] as! String)
                    //self.imageFromURL(values["profileImage"] as! String)
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.tableView.reloadData()
                    })
                })
                
            default:
                let userRef = ref.child("users")
                let userId =  userRef.child(user.uid)
                userId.observeEventType(.Value, withBlock: {(snapshot) in
                    
                    let values = snapshot.value as! [String:AnyObject]
                    self.valueSokol = [values["name"] as! String, values["email"] as! String,values["birthday"] as! String]
                    self.base = values["profileImage"] as! String
                    //self.imageFromURL(values["profileImage"] as! String)
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.tableView.reloadData()
                    })
                })
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = Utilities.user {
            switch user.providerData[0].providerID  {
            case "facebook.com":
                return 3
            case "twitter.com":
                return 3
            case "google.com":
                return 2
            default:
                return 5
            }
        }
        return 0

    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let user = Utilities.user {
            switch user.providerData[0].providerID {
            case "facebook.com":
                if indexPath.row == 0{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                    cell.titleLabel.text = titleFacebook[indexPath.row]
                    cell.valueLabel.text = valueFacebook![indexPath.row]
                    if let profileImage =  profileImage{
                        cell.profileImage.image = profileImage
                        cell.profileImage.layer.cornerRadius = 40.0
                        cell.profileImage.clipsToBounds = true
                    }
                    return cell
                    
                }else if indexPath.row == 2 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                    cell.textLabel?.text = "Friends who are using sokol"
                    
                    return cell
                }
                else{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = titleFacebook[indexPath.row]
                    cell.logo.image = UIImage(named: "facebook")
                    cell.providerLabel.text = "Login with facebook"
                    cell.valueLabel.text = valueFacebook![indexPath.row]
                    
                    return cell
                }
                
            case "twitter.com":
                if indexPath.row == 0{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                    cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                    cell.valueLabel.text = valueTwitter![indexPath.row]
                    if let profileImage =  profileImage{
                        cell.profileImage.image = profileImage
                        cell.profileImage.layer.cornerRadius = 40.0
                        cell.profileImage.clipsToBounds = true

                    }
                    
                    return cell
                    
                }else if indexPath.row == 1{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                    cell.logo.image = UIImage(named: "twitter")
                    cell.providerLabel.text = "Login with twitter"
                    cell.valueLabel.text = valueTwitter![indexPath.row]
                    
                    return cell
                }else {
                    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                    cell.textLabel?.text = titleTwitterAndGoogle[indexPath.row]
                    
                    return cell
                }
            case "google.com":
                if indexPath.row == 0{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                    cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                    cell.valueLabel.text = valueGoogle![indexPath.row]
                    if let profileImage =  profileImage{
                        cell.profileImage.image = profileImage
                        cell.profileImage.layer.cornerRadius = 40.0
                        cell.profileImage.clipsToBounds = true
                        
                    }
                    
                    return cell
                    
                }else{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                    cell.logo.image = UIImage(named: "googlePlus")
                    cell.providerLabel.text = "Login with google"
                    cell.valueLabel.text = valueGoogle![indexPath.row]
                    
                    return cell
                }

                
            default:
                
                if valueSokol != nil {
                    if indexPath.row == 0{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                        cell.titleLabel.text = titleSokol[indexPath.row]
                        cell.valueLabel.text = valueSokol![indexPath.row]
                        if let base = base{
                            cell.profileImage.image = Utilities.base64ToImage(base)
                            cell.profileImage.layer.cornerRadius = 40.0
                            cell.profileImage.clipsToBounds = true

                        }
                        
                        return cell
                    }
                    else if indexPath.row == 3 || indexPath.row == 4  {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                        cell.textLabel?.text = titleButtons[indexPath.row % 3]
                        
                        return cell
                    }
                    else{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                        cell.titleLabel.text = titleSokol[indexPath.row]
                        cell.logo.image = UIImage(named: "sokol_logo")
                        cell.providerLabel.text = "Login with sokol"
                        cell.valueLabel.text = valueSokol![indexPath.row]
                        
                        return cell
                    }
                    
                }
            
                
            }
        }
        return UITableViewCell()
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == 2 && Utilities.user?.providerData[0].providerID == "facebook.com"{
            //We need to change the view
            self.ref.removeAllObservers()
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookFriends")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            //userProfile.navigationController?.setViewControllers([viewController], animated: false)
            
            self.navigationController?.viewControllers = [userProfile,viewController]

            
        }
        if indexPath.row == 2 && Utilities.user?.providerData[0].providerID == "twitter.com"{
            self.ref.removeAllObservers()
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("twitterThoughts")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            
            self.navigationController?.viewControllers = [userProfile,viewController]
        }
        if indexPath.row == 3 && Utilities.user?.providerData[0].providerID != "facebook.com"{
            let blurEffect = UIBlurEffect(style: .Dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = view.bounds
            blurEffectView?.tag = 10
            changeEmaillAlert = UIAlertController(title: "Change your email", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Height, relatedBy:NSLayoutRelation.Equal , toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 275.0)
            let width:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 250.0)
            changeEmaillAlert!.view.addConstraint(width)
            changeEmaillAlert!.view.addConstraint(height)
            let emailTextFrame:CGRect = CGRectMake(5.0, 40.0, 240.0, 50.0)
            emailText = UITextField(frame: emailTextFrame)
            emailText!.placeholder = "Enter your old  email"
            emailText!.autocapitalizationType = .None
            emailText!.keyboardType = .EmailAddress
            
            let passwordTextFrame:CGRect = CGRectMake(5.0, 100.0, 240.0, 50.0)
            oldPassword = UITextField(frame: passwordTextFrame)
            oldPassword!.placeholder = "Enter your password"
            oldPassword!.secureTextEntry = true
            
            let newEmailTextFrame:CGRect = CGRectMake(5.0, 160.0, 240.0, 50.0)
            newEmail = UITextField(frame: newEmailTextFrame)
            newEmail!.placeholder = "Enter your new email"
            newEmail!.autocapitalizationType = .None
            newEmail!.keyboardType = .EmailAddress
            
            let changeEmailButtonFrame:CGRect =  CGRectMake(5.0, 220.0, 240.0, 50.0)
            let changeEmailButton = UIButton(frame: changeEmailButtonFrame)
            changeEmailButton.setTitle("Change Email", forState: .Normal)
            changeEmailButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            changeEmailButton.addTarget(self, action: "changeEmail", forControlEvents: .TouchUpInside)
            
            changeEmaillAlert!.view.addSubview(emailText!)
            changeEmaillAlert!.view.addSubview(oldPassword!)
            changeEmaillAlert!.view.addSubview(newEmail!)
            changeEmaillAlert!.view.addSubview(changeEmailButton)
            self.view.addSubview(blurEffectView!)
            self.presentViewController(changeEmaillAlert!, animated: true, completion: nil)
            
        }
        if indexPath.row == 4 && Utilities.user?.providerData[0].providerID != "facebook.com"{
            let blurEffect = UIBlurEffect(style: .Dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = view.bounds
            blurEffectView?.tag = 10
            changePasswordAlert = UIAlertController(title: "Change password", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: changePasswordAlert!.view, attribute: .Height, relatedBy:NSLayoutRelation.Equal , toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 275.0)
            let width:NSLayoutConstraint = NSLayoutConstraint(item: changePasswordAlert!.view, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 250.0)
            changePasswordAlert?.view.addConstraint(height)
            changePasswordAlert?.view.addConstraint(width)
            
            let emailTextFrame:CGRect = CGRectMake(5.0, 40.0, 240.0, 50.0)
            emailText = UITextField(frame: emailTextFrame)
            emailText!.placeholder = "Enter your  email"
            emailText!.autocapitalizationType = .None
            emailText!.keyboardType = .EmailAddress
            
            let oldPasswordFrame:CGRect = CGRectMake(5.0, 100.0, 240.0, 50.0)
            oldPassword = UITextField(frame: oldPasswordFrame)
            oldPassword?.placeholder = "Enter your old password"
            oldPassword?.autocapitalizationType = .None
            oldPassword?.secureTextEntry = true
        
            let newPasswordFrame:CGRect = CGRectMake(5.0, 160.0, 240.0, 50.0)
            newPassword = UITextField(frame: newPasswordFrame)
            newPassword?.placeholder = "Enter your new password"
            newPassword?.autocapitalizationType = .None
            
            let changePasswordButtonFrame:CGRect = CGRectMake(5.0, 220.0, 240.0, 50.0)
            let changePasswordButton = UIButton(frame: changePasswordButtonFrame)
            changePasswordButton.setTitle("Change Password", forState: .Normal)
            changePasswordButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            changePasswordButton.addTarget(self, action: "changePassword", forControlEvents: .TouchUpInside)
            
            changePasswordAlert?.view.addSubview(emailText!)
            changePasswordAlert?.view.addSubview(oldPassword!)
            changePasswordAlert?.view.addSubview(newPassword!)
            changePasswordAlert?.view.addSubview(changePasswordButton)
            
            self.view.addSubview(blurEffectView!)
            self.presentViewController(changePasswordAlert!, animated: true, completion: nil)

        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

    }
    func removeBlurEffect(){
        self.view.subviews.forEach({
            temp in
            if temp.tag == 10 {
                temp.removeFromSuperview()
            }
        })
    }
    func changePassword(){
        changePasswordAlert!.dismissViewControllerAnimated(true, completion: nil)
        removeBlurEffect()
        let email = emailText!.text
        let password = oldPassword!.text
        let newPassword = self.newPassword!.text
        if Utilities.isValidEmail(email!) && newPassword?.characters.count >= 5{
            let credential = FIREmailPasswordAuthProvider.credentialWithEmail(email!, password: password!)
            if let user = FIRAuth.auth()?.currentUser {
                user.reauthenticateWithCredential(credential, completion: {error in
                    if error != nil {
                        self.presentViewController(Utilities.alertMessage("Error", message: "There was an error with the credentials"), animated: true, completion: nil)
                    }else{
                        user.updatePassword(newPassword!, completion:{error in
                            if error != nil{
                                self.presentViewController(Utilities.alertMessage("Error", message: "We can update the password\n Please try later"), animated: true, completion: nil)
                            }else{
                                self.presentViewController(Utilities.alertMessage("Success", message: "We have update your password"), animated: true, completion: nil)
                            }
                        })
                    }
                })
            }
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "The  email is not valid or your new password is very short\nRemenber that your password has to be at least five characters"), animated: true, completion: nil)
        }
    }
    func changeEmail(){
        changeEmaillAlert!.dismissViewControllerAnimated(true, completion: nil)
        removeBlurEffect()
        let email = emailText!.text
        let newEmailValue = newEmail!.text
        let password = oldPassword!.text
        if Utilities.isValidEmail(email!) && Utilities.isValidEmail(newEmailValue!) {
            let credential = FIREmailPasswordAuthProvider.credentialWithEmail(email!, password: password!)
            if let user = FIRAuth.auth()?.currentUser{
                user.reauthenticateWithCredential(credential, completion: { error in
                    if error != nil {
                        self.presentViewController(Utilities.alertMessage("Error", message: "There was an error with the credentials"), animated: true, completion: nil)
                    }
                    else{
                        user.updateEmail(newEmailValue!, completion: {error in
                            if error !=  nil{
                                self.presentViewController(Utilities.alertMessage("Error", message: "We can update the email\n Please try later"), animated: true, completion: nil)
                            }
                            else{
                                let userRef = self.ref.child("users")
                                let userId =  userRef.child(user.uid)
                                let values = ["email":newEmailValue!]
                                userId.updateChildValues(values)
                                self.presentViewController(Utilities.alertMessage("Success", message: "We have update your emial"), animated: true, completion: nil)
                            }
                        })
                    }
                })
            }
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "The new email is not valid or the credetianls are not valid"), animated: true, completion: nil)
        }
    }
    
    
    @IBAction func logOut(sender: AnyObject) {
        let userRef = ref.child("users")
        let userId = userRef.child(Utilities.user!.uid)
        userId.removeAllObservers()
        try! FIRAuth.auth()?.signOut()
        Utilities.user = nil
        
        //let window = UIApplication.sharedApplication().windows[0] as UIWindow;
        //window.rootViewController = viewController;
        self.dismissViewControllerAnimated(true, completion: {});
        //self.presentViewController(viewController, animated: true, completion: nil)

        
    }
    func imageFromURL(url:String){
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            if let data = data {
                self.profileImage = UIImage(data: data)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.tableView.reloadData()

                })
                
            }
            
        })
        task.resume()
        
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        blurEffectView?.frame = view.bounds
        //tableView.reloadData()
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch (Utilities.user?.providerData[0].providerID)! {
        case "facebook.com":
            guard let indexPath = tableView.indexPathForRowAtPoint(location) else {
                return nil
            }
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
                return nil
            }
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookFriends")
            
            viewController.preferredContentSize = CGSize(width: 0.0, height: 450.0)
            
            previewingContext.sourceRect = cell.frame
            return viewController
        case "twitter.com":
            guard let indexPath = tableView.indexPathForRowAtPoint(location) else {
                return nil
            }
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
                return nil
            }
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("twitterThoughts")
            
            viewController.preferredContentSize = CGSize(width: 0.0, height: 450.0)
            
            previewingContext.sourceRect = cell.frame
            return viewController
        default:
            return nil
        }
        
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        //self.ref.removeAllObservers()
        showViewController(viewControllerToCommit, sender: self)
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

}
