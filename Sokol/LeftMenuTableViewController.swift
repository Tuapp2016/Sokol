//
//  LeftMenuTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 16/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class LeftMenuTableViewController: UITableViewController {
    let values = ["My routes","Profile","Log out"]
    let valuesImage = ["route","profile","logout"]
    var profileImage:UIImage? = nil
    var header:LeftMenuTableViewCell? = nil
    let ref = Firebase(url:"sokolunal.firebaseio.com")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .None
        if let authData = Utilities.authData{
            imageFromURL(authData.providerData["profileImageURL"] as! String)
            let userRef = ref.childByAppendingPath("users")
            let user = userRef.childByAppendingPath(authData.uid)
            user.observeEventType(.Value, withBlock: {snapshot in
                if !(snapshot.value is NSNull) {
                    
                    if self.header != nil {
                        self.header?.nameLabel.text = snapshot.value.objectForKey("name") as! String
                        self.imageFromURL(snapshot.value.objectForKey("profileImage") as! String)
                    }

                }
                
            })
            
        }
        tableView.backgroundColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
        //tableView.tintColor = UIColor.whiteColor()

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
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell1" ,forIndexPath: indexPath)
        cell.backgroundColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
        cell.textLabel!.text = values[indexPath.row]
        cell.imageView?.image =  UIImage(named: valuesImage[indexPath.row])

        return cell

    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! LeftMenuTableViewCell
        if let authData = Utilities.authData {
            //self.name = authData.providerData["displayName"] as! String
            headerCell.nameLabel.text = authData.providerData["displayName"] as! String
            headerCell.backgroundColor = UIColor.blackColor()
        }
        header = headerCell
        return headerCell
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 200.0
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
        
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        switch indexPath.row {
        case 0:
            NSNotificationCenter.defaultCenter().postNotificationName("switchTabRoutes", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("closeMenuViaNotification", object: nil)
        case 1:
            NSNotificationCenter.defaultCenter().postNotificationName("switchTabProfile", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("closeMenuViaNotification", object: nil)
        case 2:
            ref.unauth()
            ref.removeAllObservers()
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            Utilities.authData = nil
            self.presentViewController(viewController, animated: true, completion: nil)
            
        default:
            print("")
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
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.profileImage = UIImage(data: data)
                    self.header?.profileImage.image = self.profileImage
                    self.header?.profileImage.layer.cornerRadius = 50.0
                    self.header?.profileImage.clipsToBounds = true
                    
                })
                
                
            }
            
        })
        task.resume()
        
    }

    
}
