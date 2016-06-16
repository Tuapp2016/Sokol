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
    var facebookName:[String] = []
    var facebookPhoto:[UIImage] = []
    override func viewDidLoad() {
        super.viewDidLoad()
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return facebookIds.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("facebookCell", forIndexPath: indexPath) as! FacebookFriendsTableViewCell

        if indexPath.row < facebookName.count {
            cell.nameText.text = facebookName[indexPath.row]
            
        }
        if indexPath.row >= facebookPhoto.count {
            cell.profileImage.image = UIImage(named: "user_profile")
        }else{
            cell.profileImage.image = facebookPhoto[indexPath.row]
        }

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
            let fbRequest = FBSDKGraphRequest(graphPath: path!, parameters: ["limit":25])
            
            fbRequest.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    Utilities.alertMessage("Error", message: "There was an error")
                    return;
                }else{
                    //print(result)
                    let data = result.objectForKey("data") as! NSArray
                    for i in data {
                        self.facebookIds.append(i.objectForKey("id") as! String)
                        self.facebookName.append(i.objectForKey("name") as! String)
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.tableView.reloadData()
                        })
                        
                    }
                    let pagination = result.objectForKey("paging") as! NSDictionary
                    next = pagination.objectForKey("next") as? String
                    //print(next)
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
        for id in ids{
            let request = id+"/picture?type=large&redirect=false"
            let fbRequestImage = FBSDKGraphRequest(graphPath:request , parameters: nil)
            fbRequestImage.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    Utilities.alertMessage("Error", message: "There was an error")
                }else{
                    let data = result.objectForKey("data") as! NSDictionary
                    self.imageFromURL(data.objectForKey("url") as! String)
                }
            })
        }
        
        
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
                self.facebookPhoto.append(UIImage(data: data)!)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.tableView.reloadData()
                    
                })
            }
            
        })
        task.resume()
        
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
