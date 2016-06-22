//
//  FacebookFriendTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 16/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import FBSDKCoreKit

class FacebookFriendTableViewController: UITableViewController {
    var next:String?
    var facebookIds:[String] = []
    var facebookName:[String:String] = [:]
    var facebookPhoto:[String:UIImage] = [:]
    var whiteRoundedView : UIView?
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    override func viewDidLoad() {
        super.viewDidLoad()
        /*ref.observeAuthEventWithBlock({authData in
            if authData == nil {
                self.ref.removeAllObservers()
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
                self.presentViewController(viewController, animated: true, completion: nil)
            }
        })*/
        self.tableView.separatorStyle = .None
        getFriendsFacebook("me/friends")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

}
