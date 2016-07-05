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

class HomeViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var routes = [Route]()
    let ref = FIRDatabase.database().reference()
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.tableView.separatorStyle = .None
        //self.tableView.estimatedRowHeight = 150
        self.tableView.rowHeight = 150
        self.tableView.allowsSelection = false
        let userByRoutes = ref.child("userByRoutes")
        let userByRoutesID = userByRoutes.child(FIRAuth.auth()!.currentUser!.uid)
        userByRoutesID.observeEventType(.Value, withBlock: {snapshot in
            if !(snapshot.value is NSNull){
                let routesValues = snapshot.value as! NSDictionary
                let routes = routesValues["routes"] as! [String]
                self.getValues(routes)
                
            }
        })
        
    
        if (Utilities.provider == nil || Utilities.user == nil) {
            let userRef = self.ref.child("users")
            if let uid = Utilities.user?.uid{
                let userId =  userRef.child(uid)
                userId.removeAllObservers()
            }
            Utilities.user = nil
            Utilities.linking = false
            Utilities.provider = nil
            try! FIRAuth.auth()?.signOut()
            self.dismissViewControllerAnimated(true, completion: {})
        }
        NSNotificationCenter.defaultCenter().addObserver(self,selector: "switchTabRoutes", name: "switchTabRoutes", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabProfile", name: "switchTabProfile", object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
   
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func switchTabProfile(){
        tabBarController?.selectedIndex = 1
        
    }
    func switchTabRoutes() {
        tabBarController?.selectedIndex = 0
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
        cell.descriptionText.text =  route.description
        let checks = getChecks(route.annotations)
        cell.informationText.text = "This route has " + String(checks) + " checkpoints"
        cell.cardView.layer.masksToBounds = false
        cell.cardView.layer.cornerRadius = 10
        cell.cardView.layer.shadowOffset = CGSizeMake(-0.2, -0.2)
        //let path:UIBezierPath = UIBezierPath(rect: cell.cardView.bounds)
        //cell.cardView.layer.shadowPath = path.CGPath
        cell.cardView.layer.shadowOpacity = 0.2
        return cell
        
    }
    func getChecks(annotations:[SokolAnnotation]) -> Int{
        var i = 0
        for a in annotations {
            if a .checkPoint {
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
                    var annotations = [SokolAnnotation]()
                    var i = 0
                    while i < lats.count {
                        let coordinate = CLLocationCoordinate2D(latitude: Double(lats[i])!, longitude: Double(lngs[i])!)
                        let newAnnotation = SokolAnnotation(coordinate: coordinate, title: names[i], subtitle: "This point is the number " + String(i+1), checkPoint: check[i])
                        annotations.append(newAnnotation)
                        i += 1
                    }
                    let newRoute =  Route(id: a, name: routeValues["name"] as! String, description: routeValues["description"] as! String, annotations: annotations )
                    self.routes.append(newRoute)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.tableView.reloadData()
                    })
                }
            })
        }
        
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
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            let routes = self.ref.child("routes")
            let routeId = routes.child(route.id)
            routeId.removeValue()
            let userByRoute = self.ref.child("userByRoutes")
            let userByRouteId = userByRoute.child(FIRAuth.auth()!.currentUser!.uid)
            if self.routes.count == 0 {
                userByRouteId.removeValue()
            }else{
                var ids = [String]()
                for a in self.routes {
                    ids.append(a.id)
                }
                userByRouteId.setValue(["routes":ids])
            }
        })
        
        shareActionButton.backgroundColor = UIColor(red: 28.0/255.0, green: 165.0/255.0, blue: 253.0/255.0, alpha: 1.0)
        deleteActionButton.backgroundColor = UIColor.redColor()
        return [deleteActionButton,shareActionButton]
    }
    

}
