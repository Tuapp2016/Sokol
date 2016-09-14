//
//  FollowTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 21/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class FollowTableViewController: UITableViewController,UISearchResultsUpdating {
    var routesBySection:[String:[Route]] = [:]
    var routesSectionTitles = [String]()
    var routes = [Route]()
    var routesSearch = [Route]()
    var addAlertController:UIAlertController?
    var routeIdText:UITextField?
    let ref = FIRDatabase.database().reference()
    var routeIds = [String]()
    var searchController:UISearchController!
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search route..."
        searchController.searchBar.tintColor = UIColor.whiteColor()
        searchController.searchBar.barTintColor =  UIColor(red: 30.0/255.0, green: 30.0/2550.0, blue: 30.0/255.0, alpha: 1.0)
        tableView.tableHeaderView = searchController.searchBar
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        tableView.rowHeight = 150
        tableView.separatorStyle = .None
        self.tableView.setContentOffset(CGPointMake(0, 44.0), animated: false)

        
    }
  
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        if let _ = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        let followRouteRef = ref.child("followRoutesByUser")
        if let user = FIRAuth.auth()?.currentUser{
            let followRouteUserRef = followRouteRef.child(user.uid)
            followRouteUserRef.observeEventType(.Value, withBlock: {(snapshot) in
                if !(snapshot.value is NSNull){
                    let values =  snapshot.value as! NSDictionary
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
        super.viewWillDisappear(true)
        let followRouteRef = ref.child("followRoutesByUser")
        if let user = FIRAuth.auth()?.currentUser {
            let followRouteUserRef = followRouteRef.child(user.uid)
            followRouteUserRef.removeAllObservers()
        }
        let routeRef = ref.child("routes")
        for a in routes{
            let routeIdRef = routeRef.child(a.id)
            routeIdRef.removeAllObservers()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active {
            return routesSearch.count
        }else{
            let key = routesSectionTitles[section]
            if let routesValues = routesBySection[key]{
                return routesValues.count
            }
            return 0
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if searchController.active{
            return 1
        }
        return routesSectionTitles.count
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.active{
            return nil
        }
        return routesSectionTitles[section]
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("routeCell", forIndexPath: indexPath) as! RouteTableViewCell
        if indexPath.row < routes.count{
            var route = Route(id: "", name: "", description: "", annotations: [])
            if searchController.active{
                route = routesSearch[indexPath.row]
            }else{
                let key = routesSectionTitles[indexPath.section]
                if let r = routesBySection[key] {
                    route =  r[indexPath.row]
                }

            }
            cell.nameText.text = route.name
            cell.descriptionText.text = route.descriptionRoute
            let checks = getChecks(route.annotations)
            cell.informationText.text = "This route has " + String(checks) + " checkpoints"
            cell.cardView.layer.masksToBounds = false
            cell.cardView.layer.cornerRadius = 10
            cell.cardView.layer.shadowOffset = CGSizeMake(-0.2, -0.2)
            if searchController.active{
                cell.cardView.tag = indexPath.row
            }else{
                cell.cardView.tag = ((indexPath.section * 10000)+30000) + (indexPath.row * 10)
            }
            cell.cardView.layer.shadowOpacity = 0.2
        }
        
        return cell


    }
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if searchController.active{
            return nil
        }
        return routesSectionTitles
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.font = UIFont(name: "Avenir", size: 25.0)
    }
    func getChecks(annotations:[SokolAnnotation]) -> Int{
        var i = 0
        for a in annotations {
            if a.checkPoint {
                i += 1
            }
        }
        return i
    }
    

    @IBAction func addRoute(sender: AnyObject) {
        addAlertController =  UIAlertController(title: "Add route", message: "\n\n\n\n\n", preferredStyle: .Alert)
        let height = NSLayoutConstraint(item: addAlertController!.view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 160.0)
        let width = NSLayoutConstraint(item: addAlertController!.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 250.0)
        addAlertController!.view.addConstraints([height,width])
        let routeIdTextFrame = CGRectMake(5.0, 50.0, 240.0, 50.0)
        routeIdText = UITextField(frame: routeIdTextFrame)
        routeIdText?.placeholder = "Enter the id of the route"
        routeIdText!.borderStyle = .None
        
        let cancelButtonFrame = CGRectMake(20.0, 110.0, 100.0, 40.0)
        let cancelButton = UIButton(frame: cancelButtonFrame)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cancelButton.addTarget(self, action: "cancelAddRoute:", forControlEvents: .TouchUpInside)
        
        let addButtonFrame = CGRectMake(130.0, 110.0, 100.0, 40.0)
        let addButton = UIButton(frame: addButtonFrame)
        addButton.setTitle("Add", forState: .Normal)
        addButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        addButton.addTarget(self, action: "addNewRoute:", forControlEvents: .TouchUpInside)
        
        addAlertController!.view.addSubview(routeIdText!)
        addAlertController!.view.addSubview(cancelButton)
        addAlertController!.view.addSubview(addButton)
        
        self.presentViewController(addAlertController!, animated: true, completion: nil)
    }
    
    func cancelAddRoute(sender:UIButton) {
        addAlertController!.dismissViewControllerAnimated(true, completion:nil)
    }
    func addNewRoute(sender:UIButton) {
        addAlertController!.dismissViewControllerAnimated(true, completion: nil)
        let id = routeIdText!.text
        if checkId (id!) {
            let routeRef = ref.child("routes")
            let routeIdRef = routeRef.child(id!)
            routeIdRef.observeSingleEventOfType(.Value, withBlock: {(snapshot)
                in
                if snapshot.value is NSNull{
                    self.presentViewController(Utilities.alertMessage("Error", message: "This id doesn't exist.\n Please enter the id again"), animated: true, completion: nil)
                }else {
                    let values = snapshot.value as! NSDictionary
                    let name =  values["name"] as! String
                    let description =  values["description"] as! String
                    let lats = values["latitudes"] as! [String]
                    let lngs = values["longitudes"] as! [String]
                    let check = values["checkPoints"] as! [Bool]
                    let names = values["pointNames"] as! [String]
                    var annotations = [SokolAnnotation]()
                    for (index,element) in lats.enumerate(){
                        let coord = CLLocationCoordinate2D(latitude: Double(element)! , longitude: Double(lngs[index])!)
                        let id = NSUUID().UUIDString
                        let a = SokolAnnotation(coordinate: coord, title: names[index], subtitle: "This point is the number " + String(index + 1), checkPoint: check[index],id: id)
                        annotations.append(a)
                    }
                    
                    let followRouteRef = self.ref.child("followRoutesByUser")
                    if let user = FIRAuth.auth()?.currentUser{
                        let followRouteUserRef = followRouteRef.child(user.uid)
                        self.routeIds.append(id!)
                        followRouteUserRef.updateChildValues(["routes":self.routeIds])
                    }
                    let route = Route(id: id!, name: name , description: description, annotations: annotations)
                    NSOperationQueue.mainQueue().addOperationWithBlock({() in
                        self.routes.append(route)
                        self.createDictionary()
                        FIRMessaging.messaging().subscribeToTopic("/topics/"+id!)
                    })
                }
            })
            
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "You have aleready registerd this id"), animated: true, completion: nil)
        }
    }
    func checkId(id:String) -> Bool {
        for a in routes{
            if a.id == id{
                return false
            }
            
        }
        return true
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
    func getRoutes(ids:[String]){
        self.routes = []
        let routeRef = ref.child("routes")
        for id in routeIds {
            let routeIdRef = routeRef.child(id)
            routeIdRef.observeEventType(.Value, withBlock: {(snapshot) in
                if !(snapshot.value is NSNull){
                    let values = snapshot.value as! NSDictionary
                    let name =  values["name"] as! String
                    let description =  values["description"] as! String
                    let lats = values["latitudes"] as! [String]
                    let lngs = values["longitudes"] as! [String]
                    let check = values["checkPoints"] as! [Bool]
                    let names = values["pointNames"] as! [String]
                    let ids = values["ids"] as! [String]
                    var annotations = [SokolAnnotation]()
                    for (index,element) in lats.enumerate(){
                        let coord = CLLocationCoordinate2D(latitude: Double(element)! , longitude: Double(lngs[index])!)
                        let a = SokolAnnotation(coordinate: coord, title: names[index], subtitle: "This point is the number " + String(index + 1), checkPoint: check[index],id: ids[index])
                        annotations.append(a)
                    }
                    let route = Route(id: id, name: name , description: description, annotations: annotations)
                    let i = self.checkIdIndex(id)
                    if i == -1 {
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.routes.append(route)
                            self.createDictionary()
                            
                            FIRMessaging.messaging().subscribeToTopic("/topics/"+route.id)

                        })
                        
                        
                    }else{//We should update the value because the user changes something in the route
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.routes.removeAtIndex(i)
                            self.routes.insert(route, atIndex: i)
                            self.createDictionary()
                        })
                        
                    }
                    
                }else{
                    let id = routeIdRef.key
                    routeIdRef.removeAllObservers()
                    let i = self.checkIdIndex(id)
                    if i != -1{
                        if self.routes.count > 0{
                            NSOperationQueue.mainQueue().addOperationWithBlock({() in                                self.routes.removeAtIndex(i)
                                self.createDictionary()
                            })
                        }
                    }
                    let followRoutes = self.ref.child("followRoutesByUser")
                    if let user = FIRAuth.auth()?.currentUser {
                        let followRoutesId = followRoutes.child(user.uid)
                        if self.routes.count == 0 {
                            followRoutesId.removeValue()
                        }else{
                            var ids = [String]()
                            for a in self.routes {
                                ids.append(a.id)
                            }
                            followRoutes.updateChildValues(["routes":ids])
                        }
                    }
                    
                }
            })
        }
    }
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let unfollowActionButton = UITableViewRowAction(style: .Default, title: "  Unfollow  ", handler: {(action,indexPath) in
            let route = self.routes.removeAtIndex(indexPath.row)
            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                FIRMessaging.messaging().unsubscribeFromTopic("/topics/"+route.id)
            })
            //self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            self.createDictionary()
            let followRoutes = self.ref.child("followRoutesByUser")
            if let user = FIRAuth.auth()?.currentUser {
                let followRoutesId = followRoutes.child(user.uid)
                if self.routes.count == 0{
                    //followRoutesId.removeAllObservers()
                    followRoutesId.removeValue()
                }else{
                    var ids = [String]()
                    for a in self.routes {
                        ids.append(a.id)
                    }
                    followRoutesId.updateChildValues(["routes":ids])
                }
            }
        })
        unfollowActionButton.backgroundColor = UIColor.redColor()
        return [unfollowActionButton]
    }
    
    @IBAction func openFollowRoute(sender: AnyObject) {
        let viewController = UIStoryboard(name: "Follow", bundle: nil).instantiateViewControllerWithIdentifier("followRoute") as! FollowRouteViewController
        if searchController.active{
            viewController.route = routesSearch[sender.tag]
        }else{
            let row = ((sender.tag - 30000) % 10000)/10
            let section = ((sender.tag - (row*10))-30000)/10000
            if let r =  routesBySection[routesSectionTitles[section]]{
                viewController.route = r[row]
                
            }
        }
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
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
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if searchController.active {
            return false
        }else{
            return true
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "openFollowRoute" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destinationViewController as! FollowRouteViewController
                if searchController.active{
                    destinationController.route = self.routesSearch[indexPath.row]
                }else{
                    let key = routesSectionTitles[indexPath.section]
                    if let r = routesBySection[key]{
                        destinationController.route = r[indexPath.row]
                    }
                }
            }
        }
    }
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
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
    
}
