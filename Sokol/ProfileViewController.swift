//
//  ProfileViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let titleTwitter:[String] = ["Name","User name"]
    let tittleFacebookAndSokol:[String] = ["Name","Email","Birthday"]
    let titleButtons = ["Change email","Change password"]
    var valueTwitter:[String]?
    var valueSokol:[String]?
    var valueFacebook:[String]?
    var profileImage:UIImage?
    var base:String?
    
    let ref = Firebase(url:"sokolunal.firebaseio.com")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false;
        if let authData = Utilities.authData {
            switch authData.provider {
            case "facebook":
                valueFacebook = [authData.providerData["displayName"]! as! String,authData.providerData["email"] as! String,Utilities.setBirthdayDate(authData.providerData["cachedUserProfile"]!["birthday"]!! as! String)]
                imageFromURL(authData.providerData["profileImageURL"] as! String)
                let userRef =  ref.childByAppendingPath("users")
                let user = userRef.childByAppendingPath(authData.uid)
               
                user.observeEventType(.Value, withBlock: { snapshot in
                    if !(snapshot.value is NSNull){
                        self.valueFacebook = [snapshot.value.objectForKey("name") as! String,snapshot.value.objectForKey("email") as! String,snapshot.value.objectForKey("birthday") as! String]
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
                return 3
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
                    }
                    
                }else{
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
                    }
                    
                }else{
                    let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                    cell.titleLabel.text = titleTwitter[indexPath.row]
                    cell.logo.image = UIImage(named: "twitter")
                    cell.providerLabel.text = "Login with twitter"
                    cell.valueLabel.text = valueTwitter![indexPath.row]
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
                        }
                        return cell
                    }
                    else if indexPath.row == 3 || indexPath.row == 4 {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                        cell.textLabel?.text = titleButtons[indexPath.row % 3]
                        return cell
                    }
                    else{
                        let cell = tableView.dequeueReusableCellWithIdentifier("cellSokol", forIndexPath: indexPath)as! ProfileTableViewCell
                        cell.titleLabel.text = tittleFacebookAndSokol[indexPath.row]
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
        if indexPath.row == 3 {
            self.presentViewController(Utilities.alertMessage("Change emial", message: ""), animated: true, completion: nil)
        }
        if indexPath.row == 4 {
            self.presentViewController(Utilities.alertMessage("Change password", message: ""), animated: true, completion: nil)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
