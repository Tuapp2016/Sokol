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
import TwitterKit

class ProfileViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let titleTwitterAndGoogle:[String] = ["Name","Email","Twitter thoughts"]
    let titleFacebook:[String] = ["Name","Email"]
    let titleSokol:[String] = ["Name","Email","Birthday"]
    let titleButtons = ["Change email","Change password"]
    var valueTwitter:[String:String]? = [:]
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
    var providers:[String] = []
    var i = 0
    var button:UIButton =  UIButton()
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    let ref =  FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .None
        if traitCollection.forceTouchCapability == .Available{
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        //self.automaticallyAdjustsScrollViewInsets = false;
        if let user = Utilities.user {
            if let provider = Utilities.provider{
                var i = 0;
                var j = 0;
                for data in user.providerData{
                    if provider == data.providerID{
                        i = j
                    }
                    j += 1
                }
                switch provider {
                case "facebook.com":
                    let data = user.providerData[i]
                    var name = ""
                    var email = ""
                    if data.displayName != nil {
                        name = data.displayName!
                    }else{
                        name = "There is no name available"
                    }
                    if data.email != nil {
                        email = data.email!
                    }else{
                        email = "There is no image available"
                    }
                    valueFacebook = [name,email]
                    self.imageFromURL((data.photoURL?.absoluteString)!)
                
                case "google.com":
                    let data = user.providerData[i]
                    var name = ""
                    var email = ""
                    var photoURL = ""
                    if data.displayName != nil {
                        name = data.displayName!
                    }else{
                        name = "There is no name available"
                    }
                    if data.email != nil {
                        email = data.email!
                    }else{
                        email = "There is no image available"
                    }
                    if data.photoURL?.absoluteString == nil {
                        self.profileImage = UIImage(named: "profile")
                    }else{
                        photoURL = (data.photoURL?.absoluteString)!
                        self.imageFromURL(photoURL)
                    }
                    valueGoogle = [name,email]
                
                case "twitter.com":
                    let data = user.providerData[i]
                    var name = ""
                    var email = ""
                    var photoURL = ""
                    if data.displayName != nil {
                        name = data.displayName!
                    }else{
                        name = "There is no name available"
                    }
                    if data.email != nil {
                        email = data.email!
                    }else{
                        let userId = Twitter.sharedInstance().sessionStore.session()?.userID
                        let client = TWTRAPIClient(userID: userId)
                        let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/account/verify_credentials.json", parameters: ["include_email": "true", "skip_status": "true"], error: nil)
                        client.sendTwitterRequest(request, completion: {response, data,connectionError in
                            if connectionError == nil {
                                do{
                                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                                    self.valueTwitter!["Email"] = json!["screen_name"] as! String
                                    NSOperationQueue.mainQueue().addOperationWithBlock({
                                        self.tableView.reloadData()
                                    })
                                }catch let jsonError as NSError {
                                    print("json error: \(jsonError.localizedDescription)")
                                }
                            }
                        })
                    }
                    if data.photoURL?.absoluteString == nil {
                        self.profileImage = UIImage(named: "profile")
                    }else{
                        photoURL = (data.photoURL?.absoluteString)!
                        self.imageFromURL(photoURL)
                    }
                    valueTwitter!["Name"] = name
                    self.imageFromURL((data.photoURL?.absoluteString)!)
                
                default:
                    let userRef = ref.child("users")
                    let userId =  userRef.child(user.uid)
                    userId.observeEventType(.Value, withBlock: {(snapshot) in
                        if !(snapshot.value is NSNull){
                            let values = snapshot.value as! [String:AnyObject]
                            self.valueSokol = [values["name"] as! String, values["email"] as!   String,values["birthday"] as! String]
                            self.base = values["profileImage"] as! String
                    //self.imageFromURL(values["profileImage"] as! String)
                            NSOperationQueue.mainQueue().addOperationWithBlock({
                                self.tableView.reloadData()
                            })
                        }else{
                            try! FIRAuth.auth()?.signOut()
                            self.dismissViewControllerAnimated(true, completion: {});
                        }
                    })
                }
            }
        }
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = Utilities.user {
            
            if var provider = Utilities.provider {
                i = 0
                for data in (FIRAuth.auth()?.currentUser?.providerData)! {
                    if data.providerID == "facebook.com" || data.providerID == "google.com" || data.providerID == "twitter.com" || data.providerID == "password" {
                        i += 1
                    }
                }
                providers = []
                if provider == "sokol"{
                    provider = "password"
                }
                for data in (FIRAuth.auth()?.currentUser?.providerData)! {
                    if data.providerID != provider {
                        providers.append(data.providerID)
                    }
                }
                switch provider  {
                case "facebook.com":
                    if i == 4 {
                        return 6
                    }else{
                        return 3 + (i-1) + 1
                    }
                case "twitter.com":
                    if i == 4 {
                        return 6
                    }else{
                        return 3 + (i - 1) + 1
                    }
                case "google.com":
                    if i == 4{
                        return 5
                    }else{
                        return 2 + (i-1) + 1
                    }
                default:
                    if i == 4 {
                        return 8
                    }else{
                        return 5 + (i-1) + 1
                    }
                }
            }
        }
        return 0

    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let user = Utilities.user {
            if let provider = Utilities.provider {
                switch provider {
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
                    else if indexPath.row == 1 {
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                        cell.titleLabel.text = titleFacebook[indexPath.row]
                        cell.logo.image = UIImage(named: "facebook")
                        cell.providerLabel.text = "Login with facebook"
                        cell.valueLabel.text = valueFacebook![indexPath.row]
                    
                        return cell
                    }
                    else if i < 4 { //We have linked some accounts but not all
                        if indexPath.row == 3 { //This is the button to link more accounts
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Link accounts"
                            cell.imageView?.image = nil
                            return cell
                            //cell.imageView?.image = UIImage(named: "")
                            
                        }else{ //Here we present the accounts which we have linked
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 4])
                            cell.imageView?.image = getProviderImage(providers[indexPath.row % 4])
                            return cell
                            
                        }
                    }else{ //Here we have linked all the accounts
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                        cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 3])
                        cell.imageView?.image = getProviderImage(providers[indexPath.row % 3])
                        return cell
                    }
                case "twitter.com":
                    if indexPath.row == 0{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol1", forIndexPath: indexPath) as! ProfileImageTableViewCell
                        cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                        if valueTwitter![titleTwitterAndGoogle[indexPath.row]] != nil {
                            cell.valueLabel.text = valueTwitter![titleTwitterAndGoogle[indexPath.row]]
                        }else{
                            cell.valueLabel.text = ""
                        }
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
                        cell.valueLabel.text = valueTwitter![titleTwitterAndGoogle[indexPath.row]]
                        return cell
                    }else if indexPath.row == 2 {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                        cell.textLabel?.text = titleTwitterAndGoogle[indexPath.row]
                    
                        return cell
                    }
                    else if i < 4 { //We have linked some accounts but not all
                        if indexPath.row == 3 { //This is the button to link more accounts
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Link accounts"
                            cell.imageView?.image = nil
                            return cell
                            //cell.imageView?.image = UIImage(named: "")
                            
                            
                        }else{ //Here we present the accounts which we have linked
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 4])
                            cell.imageView?.image = getProviderImage(providers[indexPath.row % 4])
                            return cell
                            
                        }
                    }else{ //Here we have linked all the accounts
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                        cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 3])
                        cell.imageView?.image = getProviderImage(providers[indexPath.row % 3])
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
                    
                    }else if indexPath.row == 1{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                        cell.titleLabel.text = titleTwitterAndGoogle[indexPath.row]
                        cell.logo.image = UIImage(named: "googlePlus")
                        cell.providerLabel.text = "Login with google"
                        cell.valueLabel.text = valueGoogle![indexPath.row]
                    
                        return cell
                    }
                    else if i < 4 { //We have linked some accounts but not all
                        if indexPath.row == 2 { //This is the button to link more accounts
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Link accounts"
                            cell.imageView?.image = nil
                            return cell
                            //cell.imageView?.image = UIImage(named: "")
                            
                            
                        }else{ //Here we present the accounts which we have linked
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 3])
                            cell.imageView?.image = getProviderImage(providers[indexPath.row % 3])
                            return cell
                            
                        }
                    }else{ //Here we have linked all the accounts
                        //print ("\(indexPath.row) - \(i)")
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                        cell.textLabel!.text = "Unlink " + getProviderName(providers[(indexPath.row + 1) % 3])
                        cell.imageView?.image = getProviderImage(providers[(indexPath.row + 1) % 3])
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
                            cell.imageView?.image = nil
                            return cell
                        }
                        else if indexPath.row == 1 || indexPath.row == 2{
                            let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath) as!ProfileTableViewCell
                            cell.titleLabel.text = titleSokol[indexPath.row]
                            cell.logo.image = UIImage(named: "sokol_logo")
                            cell.providerLabel.text = "Login with sokol"
                            cell.valueLabel.text = valueSokol![indexPath.row]
                        
                            return cell
                        }
                        else if i < 4 { //We have linked some accounts but not all
                            if indexPath.row == 5 { //This is the button to link more accounts
                                let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                                cell.textLabel!.text = "Link accounts"
                                cell.imageView?.image = nil
                                return cell
                                //cell.imageView?.image = UIImage(named: "")
                                
                                
                            }else{ //Here we present the accounts which we have linked
                                //print(indexPath.row)
                                let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                                cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 6])
                                cell.imageView?.image = getProviderImage(providers[indexPath.row % 6])
                                return cell
                                
                                
                            }
                        }else{ //Here we have linked all the accounts
                            let cell = tableView.dequeueReusableCellWithIdentifier("Cell",forIndexPath: indexPath)
                            cell.textLabel!.text = "Unlink " + getProviderName(providers[indexPath.row % 5])
                            cell.imageView?.image = getProviderImage(providers[indexPath.row % 5])
                            return cell
                        }
                    }
                
                }
            }
        }
        return UITableViewCell()
    }
    func getProviderName(name:String) -> String{
        var provider = ""
        if name == "password"{
            provider = "Sokol"
        }else{
            provider = name
        }
        return provider
    }
    func getProviderImage(name:String) -> UIImage{
        switch name {
        case "facebook.com":
            return UIImage(named: "facebook")!
        case "twitter.com":
            return UIImage(named: "twitter")!
        case "google.com":
            return UIImage(named: "googlePlus")!
        default:
            return UIImage(named: "sokol_logo")!
        }
    }
    func unlinkAccount(name:String) {
        FIRAuth.auth()?.currentUser?.unlinkFromProvider(name, completion: {(user, error) in
            if let error = error {
                self.presentViewController(Utilities.alertMessage("Error", message: "We can't unlink this account"), animated: true, completion: nil)
            }else{
                Utilities.user = user
                if name == "password"{
                    Utilities.sokolLinking = false
                    let userRef = self.ref.child("users")
                    let userIdRef = userRef.child((FIRAuth.auth()?.currentUser?.uid)!)
                    var value = ""
                    if (FIRAuth.auth()?.currentUser?.providerData[0].providerID)! == "password"{
                        value = (FIRAuth.auth()?.currentUser?.providerData[1].providerID)!
                    }else{
                        value = (FIRAuth.auth()?.currentUser?.providerData[0].providerID)!
                    }
                    userIdRef.setValue(["login":value])
                    self.logOut(self.button)
                }else{
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.tableView.reloadData()
                    })
                    self.presentViewController(Utilities.alertMessage("Success", message: "This account was unlinked"), animated: true, completion: nil)
                }
            }
        })
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let provider = Utilities.provider
        
        if indexPath.row == 2 && (provider == "facebook.com"){
            //We need to change the view
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookFriends")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            //userProfile.navigationController?.setViewControllers([viewController], animated: false)
            
            self.navigationController?.viewControllers = [userProfile,viewController]

            
        }
        
        if (indexPath.row == 3 && i < 4 && (provider == "facebook.com" || provider == "twitter.com")) || (indexPath.row == 2 && i < 4 && (provider == "google.com")) || (indexPath.row == 5 && i < 4 && (provider == "password" || provider == "sokol")) {
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("linkAccounts")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            self.navigationController?.viewControllers = [userProfile,viewController]
        }
        
        if indexPath.row > 3 && i < 4 && (provider == "facebook.com" || provider == "twitter.com"){
            self.unlinkAccount(providers[indexPath.row % 4])
            
        }
        if indexPath.row >= 3 && i == 4 && (provider == "facebook.com" || provider == "twitter.com") {
            self.unlinkAccount(providers[indexPath.row % 3])

        }
        if indexPath.row > 2 && i < 4 && provider == "google.com" {
            self.unlinkAccount(providers[indexPath.row % 3])
        }
        if indexPath.row >= 2 && i == 4 && provider == "google.com" {
            self.unlinkAccount(providers[(indexPath.row + 1) % 3])

        }
        if indexPath.row > 5 && i < 4 && (provider == "password" || provider == "sokol"){
            self.unlinkAccount(providers[indexPath.row % 6])
        }
        if indexPath.row >= 5 && i == 4 && (provider == "password" || provider == "sokol") {
            self.unlinkAccount(providers[indexPath.row % 5])
        }
        if indexPath.row == 2 && provider == "twitter.com"{
            self.ref.removeAllObservers()
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("twitterThoughts")
            let userProfile = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("userProfile")
            
            self.navigationController?.viewControllers = [userProfile,viewController]
        }
        if indexPath.row == 3 && (provider == "password" || provider == "sokol"){
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
        if indexPath.row == 4 && (provider == "password" || provider == "sokol"){
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
        let userRef = self.ref.child("user")
        let userIdRef = userRef.child((FIRAuth.auth()?.currentUser?.uid)!)
        userIdRef.removeAllObservers()
        self.ref.removeAllObservers()
        try! FIRAuth.auth()?.signOut()
        Utilities.user = nil
        Utilities.linking = false
        
        //let window = UIApplication.sharedApplication().windows[0] as UIWindow;
        //window.rootViewController = viewController;
        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("leftMenu")
        viewController.dismissViewControllerAnimated(true, completion: {});
        self.dismissViewControllerAnimated(true, completion: {})
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
        if let provider = Utilities.provider {
            switch provider {
            case "facebook.com":
                guard let indexPath = tableView.indexPathForRowAtPoint(location) else {
                    return nil
                }
                guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
                    return nil
                }
                if indexPath.row >= 3 {
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
                if indexPath.row >= 3 {
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
        return nil
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        //self.ref.removeAllObservers()
        showViewController(viewControllerToCommit, sender: self)
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
    }
    
    

}
