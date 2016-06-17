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
    
    let titleTwitter:[String] = ["Name","User name"]
    let tittleFacebookAndSokol:[String] = ["Name","Email","Birthday"]
    let titleButtons = ["Change email","Change password"]
    var valueTwitter:[String]?
    var valueSokol:[String]?
    var valueFacebook:[String]?
    var profileImage:UIImage?
    var base:String?
    var changeEmaillAlert:UIAlertController?
    var changePasswordAlert:UIAlertController?
    var emailText:UITextField?
    var oldPassword:UITextField?
    var newPassword:UITextField?
    var blurEffectView:UIVisualEffectView?
    var whiteRoundedView : UIView?
    
    let ref = Firebase(url:"sokolunal.firebaseio.com")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .None
        if traitCollection.forceTouchCapability == .Available{
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        ref.observeAuthEventWithBlock({authData in
            if authData == nil {
                self.ref.removeAllObservers()
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
                self.presentViewController(viewController, animated: true, completion: nil)
            }
        })
        //self.automaticallyAdjustsScrollViewInsets = false;
        if let authData = Utilities.authData {
            switch authData.provider {
            case "facebook":
                var email:String? = authData.providerData["email"] as? String
                var birthday:String? = authData.providerData["cachedUserProfile"]!["birthday"] as? String
                if email == nil {
                    email = "There is no a valid email"
                }
                if birthday == nil {
                    birthday = "There is no a valid birthday"
                }else{
                    birthday = Utilities.setBirthdayDate(birthday!)
                }
                valueFacebook = [authData.providerData["displayName"]! as! String,email!,birthday!]
                let userRef =  ref.childByAppendingPath("users")
                let user = userRef.childByAppendingPath(authData.uid)
                
                user.observeEventType(.Value, withBlock: { snapshot in
                    if !(snapshot.value is NSNull){
                        self.valueFacebook = [snapshot.value.objectForKey("name") as!String,snapshot.value.objectForKey("email") as! String,snapshot.value.objectForKey("birthday") as! String]
                        self.imageFromURL(snapshot.value.objectForKey("profileImage") as! String)
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.tableView.reloadData()
                        })
                        
                    }
                })
             case "twitter":
                let userRef =  ref.childByAppendingPath("users")
                let user = userRef.childByAppendingPath(authData.uid)
                valueTwitter = [authData.providerData["displayName"] as! String, authData.providerData["username"] as! String]
                imageFromURL(authData.providerData["profileImageURL"] as! String)
                user.observeEventType(.Value, withBlock: { snapshot in
                    if !(snapshot.value is NSNull){
                        self.valueTwitter = [snapshot.value.objectForKey("name") as! String,snapshot.value.objectForKey("username") as! String]
                        self.imageFromURL(snapshot.value.objectForKey("profileImage") as! String)
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.tableView.reloadData()
                        })
                    }
                })
            default:
                let userRef =  ref.childByAppendingPath("users")
                let user = userRef.childByAppendingPath(authData.uid)
                user.observeEventType(.Value, withBlock: { snapshot in
                    //print("\(snapshot.value)")
                    if !(snapshot.value is NSNull){
                        self.valueSokol = [snapshot.value.objectForKey("name") as! String, snapshot.value.objectForKey("email") as! String, snapshot.value.objectForKey("birthday") as! String]
                        //print("\(snapshot.value.objectForKey("profileImage"))")
                        self.base = snapshot.value.objectForKey("profileImage") as! String
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.tableView.reloadData()
                        })
                    }
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
        if let authData = Utilities.authData {
            switch authData.provider {
            case "facebook":
                return 4
            case "twitter":
                return 2
            default:
                return 5
            }
        }
        return 0

    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let authData = Utilities.authData {
            switch authData.provider {
            case "facebook":
                if indexPath.row == 0{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                    cell.titleLabel.text = tittleFacebookAndSokol[indexPath.row]
                    cell.valueLabel.text = valueFacebook![indexPath.row]
                    if let profileImage =  profileImage{
                        cell.profileImage.image = profileImage
                        cell.profileImage.layer.cornerRadius = 40.0
                        cell.profileImage.clipsToBounds = true
                    }
                    
                    return cell
                    
                }else if indexPath.row == 3 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                    cell.textLabel?.text = "Friends who are using sokol"
                    cell.contentView.subviews.forEach({temp in
                        if temp.tag == 10 {
                            temp.removeFromSuperview()
                        }
                    })
                    
                    return cell
                }
                else{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = tittleFacebookAndSokol[indexPath.row]
                    cell.logo.image = UIImage(named: "facebook")
                    cell.providerLabel.text = "Login with facebook"
                    cell.valueLabel.text = valueFacebook![indexPath.row]
                    
                    return cell
                }
                
            case "twitter":
                if indexPath.row == 0{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                    cell.titleLabel.text = titleTwitter[indexPath.row]
                    cell.valueLabel.text = valueTwitter![indexPath.row]
                    if let profileImage =  profileImage{
                        cell.profileImage.image = profileImage
                        cell.profileImage.layer.cornerRadius = 40.0
                        cell.profileImage.clipsToBounds = true

                    }
                    cell.contentView.subviews.forEach({temp in
                        if temp.tag == 10 {
                            temp.removeFromSuperview()
                        }
                    })
                                       return cell
                    
                }else{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = titleTwitter[indexPath.row]
                    cell.logo.image = UIImage(named: "twitter")
                    cell.providerLabel.text = "Login with twitter"
                    cell.valueLabel.text = valueTwitter![indexPath.row]
                    cell.contentView.subviews.forEach({temp in
                        if temp.tag == 10 {
                            temp.removeFromSuperview()
                        }
                    })
                    
                    return cell
                }
            default:
                
                if valueSokol != nil {
                    if indexPath.row == 0{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                        cell.titleLabel.text = tittleFacebookAndSokol[indexPath.row]
                        cell.valueLabel.text = valueSokol![indexPath.row]
                        if let base = base{
                            cell.profileImage.image = Utilities.base64ToImage(base)
                            cell.profileImage.layer.cornerRadius = 40.0
                            cell.profileImage.clipsToBounds = true

                        }
                        
                        return cell
                    }
                    else if indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5 {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                        cell.textLabel?.text = titleButtons[indexPath.row % 3]
                        cell.contentView.subviews.forEach({temp in
                            if temp.tag == 10 {
                                temp.removeFromSuperview()
                            }
                        })
                        
                        return cell
                    }
                    else{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                        cell.titleLabel.text = tittleFacebookAndSokol[indexPath.row]
                        cell.logo.image = UIImage(named: "sokol_logo")
                        cell.providerLabel.text = "Login with sokol"
                        cell.valueLabel.text = valueSokol![indexPath.row]
                        cell.contentView.subviews.forEach({temp in
                            if temp.tag == 10 {
                                temp.removeFromSuperview()
                            }
                        })
                        
                        return cell
                    }
                    
                }
            
                
            }
        }
        return UITableViewCell()
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 3 && Utilities.authData?.provider == "facebook"{
            //We need to change the view
            self.ref.removeAllObservers()
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookFriends")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            //userProfile.navigationController?.setViewControllers([viewController], animated: false)
            
            self.navigationController?.viewControllers = [userProfile,viewController]

            
        }
        if indexPath.row == 3 && Utilities.authData?.provider != "facebook"{
            let blurEffect = UIBlurEffect(style: .Dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = view.bounds
            blurEffectView?.tag = 10
            changeEmaillAlert = UIAlertController(title: "Change your email", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Height, relatedBy:NSLayoutRelation.Equal , toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 220.0)
            let width:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 250.0)
            changeEmaillAlert!.view.addConstraint(width)
            changeEmaillAlert!.view.addConstraint(height)
            let emailTextFrame:CGRect = CGRectMake(5.0, 40.0, 240.0, 50.0)
            emailText = UITextField(frame: emailTextFrame)
            emailText!.placeholder = "Enter your new email"
            emailText!.autocapitalizationType = .None
            emailText!.keyboardType = .EmailAddress
            
            let passwordTextFrame:CGRect = CGRectMake(5.0, 100.0, 240.0, 50.0)
            oldPassword = UITextField(frame: passwordTextFrame)
            oldPassword!.placeholder = "Enter your password"
            oldPassword!.secureTextEntry = true
            
            let changeEmailButtonFrame:CGRect =  CGRectMake(5.0, 160.0, 240.0, 50.0)
            let changeEmailButton = UIButton(frame: changeEmailButtonFrame)
            changeEmailButton.setTitle("Change Email", forState: .Normal)
            changeEmailButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            changeEmailButton.addTarget(self, action: "changeEmail", forControlEvents: .TouchUpInside)
            
            changeEmaillAlert!.view.addSubview(emailText!)
            changeEmaillAlert!.view.addSubview(oldPassword!)
            changeEmaillAlert!.view.addSubview(changeEmailButton)
            self.view.addSubview(blurEffectView!)
            self.presentViewController(changeEmaillAlert!, animated: true, completion: nil)
            
        }
        if indexPath.row == 4 && Utilities.authData?.provider != "facebook"{
            let blurEffect = UIBlurEffect(style: .Dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = view.bounds
            blurEffectView?.tag = 10
            changePasswordAlert = UIAlertController(title: "Change password", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Height, relatedBy:NSLayoutRelation.Equal , toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 220.0)
            let width:NSLayoutConstraint = NSLayoutConstraint(item: changeEmaillAlert!.view, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 250.0)
            changePasswordAlert?.view.addConstraint(height)
            changePasswordAlert?.view.addConstraint(width)
            
            let oldPasswordFrame:CGRect = CGRectMake(5.0, 40.0, 240.0, 50.0)
            oldPassword = UITextField(frame: oldPasswordFrame)
            oldPassword?.placeholder = "Enter your old password"
            oldPassword?.autocapitalizationType = .None
            
            let newPasswordFrame:CGRect = CGRectMake(5.0, 100.0, 240.0, 50.0)
            newPassword = UITextField(frame: newPasswordFrame)
            newPassword?.placeholder = "Enter your new password"
            newPassword?.autocapitalizationType = .None
            
            let changePasswordButtonFrame:CGRect = CGRectMake(5.0, 160.0, 240.0, 50.0)
            let changePasswordButton = UIButton(frame: changePasswordButtonFrame)
            changePasswordButton.setTitle("Change Password", forState: .Normal)
            changePasswordButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            changePasswordButton.addTarget(self, action: "changePassword", forControlEvents: .TouchUpInside)
            
            changePasswordAlert?.view.addSubview(oldPassword!)
            changePasswordAlert?.view.addSubview(newPassword!)
            changePasswordAlert?.view.addSubview(changePasswordButton)
            
            self.view.addSubview(blurEffectView!)
            
            
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
        let password = newPassword?.text
        if password?.characters.count > 4 {
            ref.changePasswordForUser(Utilities.authData?.providerData["email"] as! String, fromOld: oldPassword?.text, toNew: password!, withCompletionBlock: {error in
                if error != nil {
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                }else {
                    self.presentViewController(Utilities.alertMessage("Success", message: "We have changed the your password"), animated: true, completion: nil)
                }
            })
        }else {
            self.presentViewController(Utilities.alertMessage("Error", message: "The password has to be almost of 5 characters"), animated: true, completion: nil)
        }
    }
    func changeEmail(){
        changeEmaillAlert!.dismissViewControllerAnimated(true, completion: nil)
        removeBlurEffect()
        let email = emailText!.text
        if Utilities.isValidEmail(email!) {
            let oldEmail = Utilities.authData?.providerData["email"] as! String
            ref.changeEmailForUser(oldEmail, password: oldPassword?.text, toNewEmail: email!, withCompletionBlock: {error in
                if error != nil {
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                }else {
                    let userRef = self.ref.childByAppendingPath("users")
                    let user = userRef.childByAppendingPath(Utilities.authData!.uid)
                    let values = ["email":email!]
                    user.updateChildValues(values)
                    self.presentViewController(Utilities.alertMessage("Success", message: "We have changed the your email"), animated: true, completion: nil)
                }
            
            })
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "The new email is not valid"), animated: true, completion: nil)
        }
    }
    
    
    @IBAction func logOut(sender: AnyObject) {
        ref.unauth()
        self.ref.removeAllObservers()
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
        self.presentViewController(viewController, animated: true, completion: nil)

        
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
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else {
            return nil
        }        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }
        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookFriends")
       
        //viewController.preferredContentSize = CGSize(width: 0.0, height: 450.0)
        if Utilities.authData?.provider != "facebook" {
            return nil
        }
        previewingContext.sourceRect = cell.frame
        return viewController
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.ref.removeAllObservers()
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
