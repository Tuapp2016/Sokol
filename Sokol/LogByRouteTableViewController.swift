//
//  LogByRouteTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 30/10/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class LogByRouteTableViewController: UITableViewController {
    var route:Route?
    let ref = FIRDatabase.database().reference()
    struct Log{
        var userId:String?
        var startTime:String?
        var finishTime:String?
    }
    var logs = [Log]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .SingleLine
        tableView.tableFooterView =  UIView()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(animated: Bool) {
        if let _ = FIRAuth.auth()?.currentUser{
            
        }else{
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
        }
        let logs = self.ref.child("logs")
        let logsByRoute = logs.child(route!.id)
        logsByRoute.observeEventType(.Value, withBlock: {(snapshot) in
            if !(snapshot.value is NSNull){
                let values = snapshot.value as! NSDictionary
                self.logs = []
                for (key,_) in values{
                    let v = values[key as! String] as! NSDictionary
                    let a = Log(userId: key as! String, startTime: v["startRoute"] as! String, finishTime: v["finishRoute"] as! String)
                    self.logs.append(a)
                }
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    self.tableView.reloadData()
                })
            }else{
                self.logs = []
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    self.tableView.reloadData()
                })
            }
        })
    }
    override func viewWillDisappear(animated: Bool) {
        let logs = self.ref.child("logs")
        let logsByRoute = logs.child(route!.id)
        logsByRoute.removeAllObservers()
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
        return logs.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("logByRoute", forIndexPath: indexPath) as! LogTableViewCell
        let l = logs[indexPath.row]
        cell.userIdText.text = "User id: " + l.userId!
        let users = self.ref.child("users")
        let usersById = users.child(l.userId!)
        usersById.observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            if !(snapshot.value is NSNull){
                let values = snapshot.value as! NSDictionary
                let name = values["name"] as? String
                if let name = name {
                    NSOperationQueue.mainQueue().addOperationWithBlock({() in
                        cell.userIdText.text = "User name: " + name
                    })
                }
            }
        })
        cell.startTimeText.text  = "Start time: " + l.startTime!
        if l.finishTime! == "No time"{
            cell.finishTimeText.text = "Finish time: The route is currently in progress"
            cell.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
            
        }else{
            cell.finishTimeText.text = "Finish time: " + l.finishTime!
            cell.backgroundColor = UIColor.whiteColor()
        }
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

}
