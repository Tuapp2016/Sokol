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
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit

class CareTableViewController: UITableViewController, UISearchResultsUpdating,UITextFieldDelegate {
    var addAlertController:UIAlertController?
    var routeIdText:UITextField?
    var routesSectionTitles = [String]()
    var routesBySection:[String:[Route]] = [:]
    var routesSearch = [Route]()
    var routes = [Route]()
    var routeIds = [String]()
    var searchController:UISearchController!
    let ref  = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search route..."
        searchController.searchBar.tintColor =  UIColor.whiteColor()
        searchController.searchBar.barTintColor = UIColor(red: 30.0/255.0, green: 30.0/2550.0, blue: 30.0/255.0, alpha: 1.0)
        tableView.tableHeaderView = searchController.searchBar
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
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
                    self.createDictionary()
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
        if searchController.active{
            return 1
        }
        return routesSectionTitles.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.active{
            return routesSearch.count
        }else{
            let key = routesSectionTitles[section]
            if let routesValues = routesBySection[key]{
                return routesValues.count
            }
            return 0
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.active{
            return nil
        }
        return routesSectionTitles[section]
    }
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if searchController.active{
            return nil
        }
        return routesSectionTitles
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.font = UIFont(name: "Avenir", size: 25.0)
    }
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let shareToFacebookButton = UITableViewRowAction(style: .Default, title: "Share to\n Facebook", handler: {(action,indexPath) in
            
            let key = self.routesSectionTitles[indexPath.section]
            if let r = self.routesBySection[key]{
                let route = r[indexPath.row]
                let text = "This is the code of my route\n Please subscribe to it.\n The route id is " + route.id
                
                let content = FBSDKShareLinkContent()
                content.contentURL = NSURL(string: "https://fcmsokol.herokuapp.com")
                content.quote = text
                let dialog = FBSDKShareDialog()
                dialog.fromViewController = self
                dialog.shareContent = content
                dialog.show()
                
                
            }
            
        })
        let shareActionButton = UITableViewRowAction(style: .Default, title: "Share", handler: {(action,indexPath) in
            let key = self.routesSectionTitles[indexPath.section]
            if let r = self.routesBySection[key]{
                let route = r[indexPath.row]
                let text = "This is the code of my route\n Please subscribe to it.\n The route id is " + route.id
                let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                activityController.excludedActivityTypes = [UIActivityTypePostToFacebook]
                self.presentViewController(activityController, animated: true, completion: nil)
                
            }
            
        })

        let unKeepActionButton = UITableViewRowAction(style: .Default, title: "Remove", handler: {(action,indexPath) in
            let key = self.routesSectionTitles[indexPath.section]
            if let r = self.routesBySection[key]{
                let route = r[indexPath.row]
                self.deleteRoute(route.id)
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    self.createDictionary()
                    let careRouteRef = self.ref.child("careRoutesByUser")
                    if let userTemp = FIRAuth.auth()?.currentUser{
                        let careRouteByUserRef = careRouteRef.child(userTemp.uid)
                        if self.routes.count == 0 {
                            careRouteByUserRef.removeValue()
                        }else{
                            var ids = [String]()
                            for a in self.routes{
                                ids.append(a.id)
                            }
                            careRouteByUserRef.updateChildValues(["routes":ids])
                        }
                    }
                })
                
            }
        })
        shareToFacebookButton.backgroundColor = UIColor(red: 100.0/255.0, green: 20.0/255.0, blue: 155.0/255.0, alpha: 1.0)
        shareActionButton.backgroundColor = UIColor(red: 28.0/255.0, green: 165.0/255.0, blue: 253.0/255.0, alpha: 1.0)
        unKeepActionButton.backgroundColor = UIColor.redColor()
        return [shareToFacebookButton,shareActionButton,unKeepActionButton]
    }
    func deleteRoute(id:String){
        var existID = false
        var i = 0
        for r in routes{
            if r.id == id {
                existID = true
                break
            }
            i += 1
        }
        if existID{
            routes.removeAtIndex(i)
        }

    }
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if searchController.active {
            return false
        }else{
            return true
        }
    }

    func createDictionary(){
        routesBySection = [:]
        for r in routes{
            let key = r.name.substringToIndex(r.name.startIndex.advancedBy(1))
            if var routesTemp = routesBySection[key]{
                routesTemp.append(r)
                routesBySection[key] = routesTemp
            }else{
                routesBySection[key] = [r]
            }
        }
        routesSectionTitles = [String](routesBySection.keys)
        routesSectionTitles = routesSectionTitles.sort({ $0 < $1 })
        NSOperationQueue.mainQueue().addOperationWithBlock({()
            self.tableView.reloadSectionIndexTitles()
            self.tableView.reloadData()
        })
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
                            self.createDictionary()
                        })
                    }else{
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            self.routes.removeAtIndex(i)
                            self.routes.insert(route, atIndex: i)
                            self.createDictionary()
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
        routeIdText!.delegate = self
        
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
        var r:Route?
        if searchController.active{
            r = routesSearch[indexPath.row]
        }else{
            let key = routesSectionTitles[indexPath.section]
            if let routesTemp = routesBySection[key]{
                r = routesTemp[indexPath.row]
            }
        }
        cell.nameText.text = r!.name
        cell.descriptionText.text = r!.descriptionRoute
        cell.followerText.text = "We are looking for the followers of this route..."
        cell.activeRoutesText.text = "We are going to check how many routes are active at the moment, this task can take a while..."
        let usersRoute = ref.child("usersByFollowRoute")
        let usersFollowRoute = usersRoute.child(r!.id)
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
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text{
            filterContentForSearchText(searchText)
            tableView.reloadData()
        }
    }
    func filterContentForSearchText(searchText:String){
        routesSearch =  routes.filter({(r:Route)-> Bool in
            let nameMatch = r.name.rangeOfString(searchText,options: NSStringCompareOptions.CaseInsensitiveSearch)
            return nameMatch != nil
        })
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
