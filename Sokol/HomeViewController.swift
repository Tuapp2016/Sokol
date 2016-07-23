//
//  HomeViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit
import MapKit

class HomeViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var routes = [Route]()
    var routesId = [String]()
    let ref = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        //self.tableView.separatorStyle = .None
        //self.tableView.estimatedRowHeight = 150
        self.tableView.rowHeight = 150
    
        NSNotificationCenter.defaultCenter().addObserver(self,selector: "switchTabRoutes", name: "switchTabRoutes", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabProfile", name: "switchTabProfile", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabFollow", name: "switchTabFollow", object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        if Utilities.user == nil || Utilities.provider == nil {
            let userRef = self.ref.child("user")
            userRef.removeAllObservers()
            let userIdRef = userRef.child((FIRAuth.auth()?.currentUser?.uid)!)
            userIdRef.removeAllObservers()
            self.ref.removeAllObservers()
            try! FIRAuth.auth()?.signOut()
            Utilities.user = nil
            Utilities.linking = false
            let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("leftMenu")
            viewController.dismissViewControllerAnimated(true, completion: {});
            self.dismissViewControllerAnimated(true, completion: {})
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
        routes = []
        tableView.reloadData()
        let userByRoutes = ref.child("userByRoutes")
        let userByRoutesID = userByRoutes.child(FIRAuth.auth()!.currentUser!.uid)
        userByRoutesID.observeEventType(.Value, withBlock: {snapshot in
            if !(snapshot.value is NSNull){
                let routesValues = snapshot.value as! NSDictionary
                self.routesId = routesValues["routes"] as! [String]
                self.getValues(self.routesId)
                
            }else{
                self.routes = []
                NSOperationQueue.mainQueue().addOperationWithBlock({() in
                    self.tableView.reloadData()
                })
            }
        })
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let routesRef = ref.child("routes")
        let userByRoutes = ref.child("userByRoutes")
        if let user = Utilities.user?.uid {
            let userByRoutesID = userByRoutes.child(user)
            userByRoutesID.removeAllObservers()
            for i in routes{
                let routeID = routesRef.child(i.id)
                routeID.removeAllObservers()
            }
        }
    }
   
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func switchTabProfile(){
        tabBarController?.selectedIndex = 2
        
    }
    func switchTabRoutes() {
        tabBarController?.selectedIndex = 0
    }
    func switchTabFollow(){
        tabBarController?.selectedIndex = 1
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let route = routes[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("routeCell") as! RouteTableViewCell
        cell.nameText.text = route.name
        cell.descriptionText.text =  route.descriptionRoute
        let checks = getChecks(route.annotations)
        cell.informationText.text = "This route has " + String(checks) + " checkpoints"
        cell.cardView.layer.masksToBounds = false
        cell.cardView.layer.cornerRadius = 10
        cell.cardView.layer.shadowOffset = CGSizeMake(-0.2, -0.2)
        cell.cardView.tag = indexPath.row
        //let path:UIBezierPath = UIBezierPath(rect: cell.cardView.bounds)
        //cell.cardView.layer.shadowPath = path.CGPath
        cell.cardView.layer.shadowOpacity = 0.2
        return cell
        
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
    func getValues(routesID:[String]) {
        self.routes = []
        let routesRef = ref.child("routes")
        for a in routesID{
            let routeID = routesRef.child(a)
            routeID.observeEventType(.Value, withBlock: {snapshot in
                if !(snapshot.value is NSNull) {
                    let routeValues = snapshot.value as! NSDictionary
                    let lats = routeValues["latitudes"] as! [String]
                    let lngs =  routeValues["longitudes"] as! [String]
                    let check = routeValues["checkPoints"] as! [Bool]
                    let names = routeValues["pointNames"] as! [String]
                    let ids = routeValues["ids"] as! [String]
                    var annotations = [SokolAnnotation]()
                    var i = 0
                    while i < lats.count {
                        let coordinate = CLLocationCoordinate2D(latitude: Double(lats[i])!, longitude: Double(lngs[i])!)
                        let newAnnotation = SokolAnnotation(coordinate: coordinate, title: names[i], subtitle: "This point is the number " + String(i+1), checkPoint: check[i],id:ids[i])
                        annotations.append(newAnnotation)
                        i += 1
                    }
                    let newRoute =  Route(id: a, name: routeValues["name"] as! String, description: routeValues["description"] as! String, annotations: annotations )
                    if self.isNewRoute(newRoute){
                        self.routes.append(newRoute)
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.tableView.reloadData()
                        })
                    }else{
                        let i = self.checkIdIndex(newRoute.id)
                        self.routes.removeAtIndex(i)
                        self.routes.insert(newRoute, atIndex: i)
                        let indexPath = NSIndexPath(forRow: (i), inSection: 0)
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                        })
                        
                    }
                    
                    
                    
                }else{
                    let id = routeID.key
                    routeID.removeAllObservers()
                    let i = self.checkIdIndex(id)
                    if self.routes.count > 0 {
                        self.routes.removeAtIndex(i)
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            let indexPath = NSIndexPath(forRow: i, inSection: 0)
                            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                        })
                    }
                    let userByRoute = self.ref.child("userByRoutes")
                    if let user = FIRAuth.auth()?.currentUser {
                        let userByRouteId = userByRoute.child(user.uid)
                        if self.routes.count == 0 {
                            
                            userByRouteId.removeValue()
                        }else{
                            var ids = [String]()
                            for a in self.routes {
                                ids.append(a.id)
                            }
                            userByRouteId.setValue(["routes":ids])
                        }
                    }
                }
            })
        }
        
    }
    func isNewRoute(route:Route) -> Bool{
        for a in routes{
            if a.id == route.id {
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
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let shareActionButton = UITableViewRowAction(style: .Default, title: "Share", handler: {(action,indexPath) in
            let route = self.routes[indexPath.row]
            let text = "This is the code of my route\n Please subscribe to it.\n The route id is " + route.id
            let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self.presentViewController(activityController, animated: true, completion: nil)
        })
        let deleteActionButton = UITableViewRowAction(style: .Default, title: "  Delete          ", handler: {(action,indexPath) in
            let route = self.routes.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            let routes = self.ref.child("routes")
            let routeId = routes.child(route.id)
            routeId.removeAllObservers()
            routeId.removeValue()
            let userByRoute = self.ref.child("userByRoutes")
            if let user = FIRAuth.auth()?.currentUser {
                let userByRouteId = userByRoute.child(user.uid)
                if self.routes.count == 0 {
                
                    userByRouteId.removeValue()
                }else{
                    var ids = [String]()
                    for a in self.routes {
                        ids.append(a.id)
                    }
                    userByRouteId.setValue(["routes":ids])
                }
            }
            
        })
        
        shareActionButton.backgroundColor = UIColor(red: 28.0/255.0, green: 165.0/255.0, blue: 253.0/255.0, alpha: 1.0)
        deleteActionButton.backgroundColor = UIColor.redColor()
        return [deleteActionButton,shareActionButton]
    }
    
    @IBAction func openDetail(sender: AnyObject) {
        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("informationRoute") as! DetailRouteTableViewController
        viewController.route = routes[sender.tag]
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailRoute" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destinationViewController as! DetailRouteTableViewController
                destinationController.route =  routes[indexPath.row]
            }
        }
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else{
            return nil
        }
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }
        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("informationRoute") as! DetailRouteTableViewController
        viewController.route = routes[indexPath.row]
        
        viewController.preferredContentSize =  CGSize(width: 0.0, height: 450.0)
        return viewController

    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
    

}
