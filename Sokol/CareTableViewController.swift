//
//  CareTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 17/10/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class CareTableViewController: UITableViewController {
    var addAlertController:UIAlertController?
    var routeIdText:UITextField?
    var routes = [Route]()
    var routeIds = [String]()
    let ref  = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .SingleLine
        tableView.tableFooterView = UIView()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(animated: Bool) {
        if let _ = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        let careRouteRef = ref.child("careRoutesByUser")
        if let user = FIRAuth.auth()?.currentUser{
            let careRouteUserRef = careRouteRef.child(user.uid)
            careRouteUserRef.observeEventType(.Value, withBlock: {(snapshot) in
                if !(snapshot.value is NSNull){
                    let values = snapshot.value as! NSDictionary
                    self.routeIds = values["routes"] as! [String]
                    self.getRoutes(self.routeIds)
                }else{
                    self.routes = []
                    self.routeIds = []
                }
            })
        }
    }
    override func viewWillDisappear(animated: Bool) {
        let careRouteRef = ref.child("careRoutesByUser")
        if let user = FIRAuth.auth()?.currentUser{
            let careRouteUserRef = careRouteRef.child(user.uid)
            careRouteUserRef.removeAllObservers()
        }
        let usersRouteRef = ref.child("usersByFollowRoute")
        
        for r in routes{
            let usersFollowRouteRef = usersRouteRef.child(r.id)
            usersFollowRouteRef.removeAllObservers()
        }
      
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
        return routes.count
    }
    func getRoutes(idsRoutes:[String]){
        self.routes = []
        let routeRef = ref.child("routes")
        for id in idsRoutes{
            let routeIdRef = routeRef.child(id)
            routeIdRef.observeEventType(.Value, withBlock: {(snapshot) in
                if !(snapshot.value is NSNull){
                    let values = snapshot.value as! NSDictionary
                    let name = values["name"] as! String
                    let description = values["description"] as! String
                    let lats = values["latitudes"] as! [String]
                    let lngs = values["longitudes"] as! [String]
                    let check = values["checkPoints"] as! [Bool]
                    let names = values["pointNames"] as! [String]
                    let ids = values["ids"] as! [String]
                    var annotations = [SokolAnnotation]()
                    for (index,elemente) in lats.enumerate(){
                        let coord = CLLocationCoordinate2D(latitude: Double(lats[index])!, longitude: Double(lngs[index])!)
                        let a = SokolAnnotation(coordinate: coord, title: names[index], subtitle: "This point is the number " + String(index), checkPoint: check[index], id: ids[index])
                        annotations.append(a)
                    }
                    let route = Route(id: id, name: name, description: description, annotations: annotations)
                    let i = self.checkIdIndex(id)
                    if i == -1 {
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            self.routes.append(route)
                            FIRMessaging.messaging().subscribeToTopic("/topics/"+route.id)
                            self.tableView.reloadData()
                        })
                    }else{
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            self.routes.removeAtIndex(i)
                            self.routes.insert(route, atIndex: i)
                            self.tableView.reloadData()
                        })
                    }
                    
                }
            })
        }
    }
    func checkIdIndex(id:String) -> Int {
        var i = 0
        for a in routes{
            if a.id == id{
                return i
            }
            i += 1
        }
        return -1
    }
    @IBAction func addRoute(sender: AnyObject) {
        addAlertController = UIAlertController(title: "Add route", message: "\n\n\n\n\n", preferredStyle: .Alert)
        let height = NSLayoutConstraint(item: addAlertController!.view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 160.0)
        let width = NSLayoutConstraint(item: addAlertController!.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 250.0)
        addAlertController!.view.addConstraints([height,width])
        let routeIdTextFrame = CGRectMake(5.0, 50.0, 240.0, 50.0)
        routeIdText = UITextField(frame: routeIdTextFrame)
        routeIdText!.placeholder = "Enter the id of the route"
        routeIdText!.borderStyle = .None
        
        let cancelButtonFrame =  CGRectMake(20.0, 110.0, 100.0, 40.0)
        let cancelButton = UIButton(frame: cancelButtonFrame)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(CareTableViewController.cancelAddRoute(_:)), forControlEvents: .TouchUpInside)
        let addButtonFrame = CGRectMake(130.0, 110.0, 100.0, 40.0)
        let addButton = UIButton(frame: addButtonFrame)
        addButton.setTitle("Add", forState: .Normal)
        addButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        addButton.addTarget(self, action: #selector(CareTableViewController.addNewRoute(_:)), forControlEvents: .TouchUpInside)
        addAlertController!.view.addSubview(routeIdText!)
        addAlertController!.view.addSubview(cancelButton)
        addAlertController!.view.addSubview(addButton)
        
        self.presentViewController(addAlertController!, animated: true, completion: nil)
        
        
    }
    func cancelAddRoute(sender:AnyObject){
        addAlertController!.dismissViewControllerAnimated(true, completion: nil)
    }
    func addNewRoute(sender:AnyObject){
        addAlertController!.dismissViewControllerAnimated(true, completion: nil)
        let id  = routeIdText!.text
        if id!.characters.count > 0 {
            if checkId(id!){
                let routeRef =  ref.child("routes")
                let routeIdRef = routeRef.child(id!)
                routeIdRef.observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                    if snapshot.value is NSNull{
                        NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                            self.presentViewController(Utilities.alertMessage("Error", message: "This id doesn't exist.\n Please enter the id again"), animated: true, completion: nil)
                        })
                    }else{
                        let values = snapshot.value as! NSDictionary
                        let name = values["name"] as! String
                        let description = values["description"] as! String
                        let lats = values["latitudes"] as! [String]
                        let lngs = values["longitudes"] as! [String]
                        let check = values["checkPoints"] as! [Bool]
                        let names = values["pointNames"] as! [String]
                        let ids = values["ids"] as! [String]
                        var annotations = [SokolAnnotation]()
                        for (index,element) in lats.enumerate(){
                            let coord = CLLocationCoordinate2D(latitude: Double(lats[index])!, longitude: Double(lngs[index])!)
                            
                            let a = SokolAnnotation(coordinate: coord, title: names[index], subtitle: "This point is the number " + String(index + 1), checkPoint: check[index],id: ids[index])
                            annotations.append(a)
                        }
                        let route = Route(id: id!, name: name, description: description, annotations: annotations)
                        
                        let careRoutes = self.ref.child("careRoutesByUser")
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            if let user = FIRAuth.auth()?.currentUser{
                                let careRoutesUser = careRoutes.child(user.uid)
                                self.routeIds.append(id!)
                                careRoutesUser.updateChildValues(["routes":self.routeIds])
                            }
                            self.routes.append(route)
                            FIRMessaging.messaging().subscribeToTopic("/topics/"+route.id)
                            self.tableView.reloadData()
                        })
                        
                    }
                })
            }else{
                self.presentViewController(Utilities.alertMessage("Error", message: "You have aleready registerd this id"), animated: true, completion: nil)
            }
        }
    }
    func checkId(id:String) -> Bool{
        for a in routes{
            if a.id == id{
                return false
            }
        }
        return true
    }
    
    @IBAction func toggleMenu(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)

    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("careCell", forIndexPath: indexPath) as! CareTableViewCell
        let r = routes[indexPath.row]
        cell.nameText.text = r.name
        cell.descriptionText.text = r.descriptionRoute
        cell.followerText.text = "We are looking for the followers of this route..."
        cell.activeRoutesText.text = ""
        let usersRoute = ref.child("usersByFollowRoute")
        let usersFollowRoute = usersRoute.child(r.id)
        usersFollowRoute.observeEventType(.Value, withBlock: {(snapshot) in
            if !(snapshot.value is NSNull){
                let values = snapshot.value  as! NSDictionary
                let users = values["users"] as! [String]
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    cell.followerText.text = "This route has " + String(users.count) + " followers"
                })
            
            }else{
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    cell.followerText.text = "This route has 0 followers"
                })
            }
        })
        
        return cell
    }
}
