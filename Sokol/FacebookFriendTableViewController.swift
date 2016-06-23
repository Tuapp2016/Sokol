//
//  FacebookFriendTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 16/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase

class FacebookFriendTableViewController: UITableViewController {
    var next:String?
    var facebookIds:[String] = []
    var facebookName:[String:String] = [:]
    var facebookPhoto:[String:UIImage] = [:]
    var whiteRoundedView : UIView?
    let ref = FIRDatabase.database().reference()
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.refreshControl?.addTarget(self, action: "handleRefresh", forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.separatorStyle = .None
        getFriendsFacebook("me/friends")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return facebookIds.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("facebookCell", forIndexPath: indexPath) as! FacebookFriendsTableViewCell
        cell.contentView.backgroundColor = UIColor.clearColor()
        if indexPath.row < facebookName.count && facebookName.count == facebookIds.count {
            cell.nameText.text = facebookName[facebookIds[indexPath.row]]
            
        }
        if indexPath.row >= facebookPhoto.count && facebookPhoto.count != facebookIds.count {
            cell.profileImage.image = UIImage(named: "user_profile")
            cell.profileImage.layer.cornerRadius = 50.0
            cell.profileImage.clipsToBounds = true

        }else{
            cell.profileImage.image = facebookPhoto[facebookIds[indexPath.row]]
        }
        whiteRoundedView = UIView(frame: CGRectMake(10, 10, self.view.frame.size.width - 20, self.view.frame.size.height))
        whiteRoundedView?.tag = 10
        
        whiteRoundedView!.layer.backgroundColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [1.0, 1.0, 1.0, 0.8])
        whiteRoundedView!.layer.masksToBounds = false
        whiteRoundedView!.layer.cornerRadius = 5.0
        whiteRoundedView!.layer.shadowOffset = CGSizeMake(-1, 1)
        whiteRoundedView!.layer.shadowOpacity = 0.2
        cell.contentView.subviews.forEach({temp in
            if temp.tag == 10 {
                temp.removeFromSuperview()
            }
        })
        cell.contentView.addSubview(whiteRoundedView!)
        cell.contentView.sendSubviewToBack(whiteRoundedView!)

        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    func handleRefresh(){
        facebookIds = []
        getFriendsFacebook("me/friends")
        self.refreshControl?.endRefreshing()

    }
    func getFriendsFacebook(path:String?){
        var next:String?
        if path == nil {
            getFriendsFacebookPhoto(facebookIds)
            return;
        }else {
            let fbRequest = FBSDKGraphRequest(graphPath: path!, parameters: nil)
            
            fbRequest.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error")
, animated: false, completion:nil)
                }else{
                    let data = result.objectForKey("data") as! NSArray
                    for i in data {
                        self.facebookIds.append(i.objectForKey("id") as! String)
                        self.facebookName[i.objectForKey("id")
                        as! String] = i.objectForKey("name") as! String
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.tableView.reloadData()
                        })
                        
                    }
                    let pagination = result.objectForKey("paging") as! NSDictionary
                    next = pagination.objectForKey("next") as? String
                    if next != nil {
                        next = next!.substringFromIndex(next!.startIndex.advancedBy(32))
                        self.getFriendsFacebook(next)
                    }else{
                        self.getFriendsFacebook(nil)
                    }
                    
                }
            })
            
        }
        
    }
    func getFriendsFacebookPhoto(ids:[String]) {
        for id in ids {
            let request = id+"/picture?type=large&redirect=false"
            let fbRequestImage = FBSDKGraphRequest(graphPath:request , parameters: nil)
            fbRequestImage.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    Utilities.alertMessage("Error", message: "There was an error")
                }else{
                    let data = result.objectForKey("data") as! NSDictionary
                    self.imageFromURL(data.objectForKey("url") as! String,id:id)
                }
            })
        }
        
        
    }
    func imageFromURL(url:String,id:String){
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            if let data = data {
                self.facebookPhoto[id]=UIImage(data: data)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.tableView.reloadData()
                    
                })
            }
            
        })
        task.resume()
        
    }
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
        
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
    }
    

   
}
