//
//  LeftMenuTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 16/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit

class LeftMenuTableViewController: UITableViewController {
    let values = ["My routes","Profile","Log out"]
    let valuesImage = ["route","profile","logout"]
    var profileImage:UIImage? = nil
    var header:LeftMenuTableViewCell? = nil
    let ref = FIRDatabase.database().reference()
    
    override func viewDidLoad(){
    
        super.viewDidLoad()
        if Utilities.user?.providerData[0].providerID == "twitter.com"{
            let userId = Twitter.sharedInstance().sessionStore.session()?.userID
            let client = TWTRAPIClient(userID: userId)
            let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/account/verify_credentials.json", parameters: ["include_email": "true", "skip_status": "true"], error: nil)
            
            client.sendTwitterRequest(request, completion: {response, data,connectionError in
                if connectionError == nil {
                    do{
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                        let value = ["email":json!["screen_name"] as! String]
                        let user = self.ref.child("users").child((Utilities.user?.uid)!)
                        user.updateChildValues(value)
                    }catch let jsonError as NSError {
                        print("json error: \(jsonError.localizedDescription)")
                    }
                }
            })
                
            
        }
        self.tableView.separatorStyle = .None
        if let user = Utilities.user{
            let userRef = ref.child("users")
            let userId = userRef.child(user.uid)
            userId.observeEventType(.Value, withBlock: {snapshot in
                if !(snapshot.value is NSNull){
                    let values = snapshot.value  as! [String:AnyObject]
                    if self.header != nil {
                        self.header?.nameLabel.text = values["name"] as! String
                        let url = values["profileImage"] as! String
                        if url == "There is no an image available" {
                            self.header?.profileImage.image = UIImage(named: "profile")
                        }else if url.containsString("https")  || url.containsString("http")  {
                            self.imageFromURL(url)
                        }else{
                            self.header?.profileImage.image = Utilities.base64ToImage(url)
                            self.header?.profileImage.layer.cornerRadius = 50.0
                            self.header?.profileImage.clipsToBounds = true

                        }
                    }
                }else{
                    try! FIRAuth.auth()?.signOut()
                    self.dismissViewControllerAnimated(true, completion: {});
                }

                
                
            })
            
        }
        tableView.backgroundColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
        
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
        if let user = Utilities.user {
            //self.name = authData.providerData["displayName"] as! String
            if user.providerData[0].displayName != nil{
                headerCell.nameLabel.text = user.providerData[0].displayName!
            }
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
            let userRef = ref.child("users")
            if let uid = Utilities.user?.uid{
                let userId =  userRef.child(uid)
                userId.removeAllObservers()
            }
            
            Utilities.user = nil
            try! FIRAuth.auth()?.signOut()
            self.dismissViewControllerAnimated(true, completion: {});
            
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