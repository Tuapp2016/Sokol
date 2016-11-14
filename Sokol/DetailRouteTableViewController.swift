//
//  DetailRouteTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 04/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class DetailRouteTableViewController: UITableViewController {
    
    var route:Route?
    let ref  = FIRDatabase.database().reference()
    var routeTemp:Route?
    var details:[Bool] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(DetailRouteTableViewController.movePoint(_:)))
        tableView.addGestureRecognizer(longPress)
        tableView.estimatedRowHeight = 215
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = false

        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.hidesBackButton = false
        if let route = route {
            routeTemp = route.copy() as! Route
        }
        details = Array(count: self.route!.annotations.count, repeatedValue: false)
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
        return (route?.annotations.count)!
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:PointTableViewCell?
        var cellSmall:PointSmallTableViewCell?
        let lat = route!.annotations[indexPath.row].coordinate.latitude
        let lng = route!.annotations[indexPath.row].coordinate.longitude
        let check = route!.annotations[indexPath.row].checkPoint
        if !details[indexPath.row]{
            cellSmall = tableView.dequeueReusableCellWithIdentifier("pointCellSmall", forIndexPath: indexPath) as! PointSmallTableViewCell
            cellSmall!.pointNameText.text = route?.annotations[indexPath.row].title
            cellSmall!.addressText.text = "We are looking for the direction of the point, this task can take a while ..\n"
            cellSmall!.checkpoint.on = check
            cellSmall!.showMore.tag = indexPath.row
            cellSmall!.showMore.addTarget(self, action: #selector(DetailRouteTableViewController.showMore(_:)), forControlEvents: .TouchUpInside)
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("pointCell", forIndexPath: indexPath) as! PointTableViewCell
            cell!.latitudeText.text = "Lat: " + String(lat)
            cell!.longitudeText.text = "Lng " + String(lng)
            cell!.checkpoint.on = check
            cell!.pointNameText.text = route?.annotations[indexPath.row].title
            cell!.checkpoint.tag = indexPath.row
            cell!.checkpoint.addTarget(self, action: #selector(DetailRouteTableViewController.changeCheckpoint(_:)), forControlEvents: .ValueChanged)
            cell!.addressText.text = "We are looking for the direction of the point, this task can take a while ..\n"
            cell!.showLess.tag = indexPath.row
            cell!.showLess.addTarget(self, action: #selector(DetailRouteTableViewController.showMore(_:)), forControlEvents: .TouchUpInside)
        }
        
        
               // Configure the cell...

        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng="+String(lat)+","+String(lng)+"&key="+Constants.DIRECTION_KEY
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request,completionHandler: {(data,response,error)-> Void in
                if let error = error {
                    print(error)
                }
                if let data = data {
                do{
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    let status = jsonResult["status"] as! String
                    if !(status == "ZERO_RESULTS"){
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            let results = jsonResult["results"] as! NSArray
                            let result = results[0] as! NSDictionary
                            let formatted_address = result["formatted_address"] as! String
                            if let c = cell{
                                cell!.addressText.text = "Calculated address: \(formatted_address)"
                            }else{
                                cellSmall!.addressText.text = "Calculated address: \(formatted_address)"
                            }
                            
                        })
                    }else{
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            if let c = cell {
                                cell!.addressText.text = "We can't find any directions"
                            }else{
                                cellSmall!.addressText.text = "We can't find any directions"

                            }
                        })
                    
            
                    }
                }catch {
                    print (error)
                }
            }
        })
        
        task.resume()
        if details[indexPath.row]{
           return cell!
        }else{
            return cellSmall!
        }
    }
    func showMore(sender:AnyObject?){
        details[sender!.tag] = !details[sender!.tag]
        var indexs = [NSIndexPath]()
        indexs.append(NSIndexPath(forRow: sender!.tag, inSection: 0))
        tableView.reloadRowsAtIndexPaths(indexs, withRowAnimation: .Fade)
    }
    func changeCheckpoint(sender:UISwitch){
        route?.annotations[sender.tag].checkPoint = sender.on
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Points"
    }
    /*override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 200.0
    }*/
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 105.0
    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("headerCell") as! HeaderTableViewCell
        headerCell.nameText.text =  route!.name
        headerCell.descriptionText.text = route!.descriptionRoute
        
        return headerCell.contentView
        
    }
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            let routes = ref.child("routes")
            let routeId = routes.child(route!.id)
            var checks = [Bool]()
            var lats = [String]()
            var lngs = [String]()
            var pointNames = [String]()
            var ids = [String]()
            for a in route!.annotations{
                checks.append(a.checkPoint)
                lats.append(String(a.coordinate.latitude))
                lngs.append(String(a.coordinate.longitude))
                pointNames.append(a.title!)
                ids.append(a.id!)
            }
            let values = ["latitudes":lats,
                          "longitudes":lngs,
                          "checkPoints":checks,
                          "pointNames":pointNames,
                          "ids":ids
            ]
            
            routeId.updateChildValues(values as [NSObject : AnyObject])
        }
    }
    func movePoint(gestureRecognizer:UIGestureRecognizer){
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state =  longPress.state
        let locationInView = longPress.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(locationInView)
        
        struct MyCell {
            static var cellSnapshot:UIView? = nil
            static var cellIsAnimating = false
            static var cellNeedToShow =  false
        }
        struct Path {
            static var initialIndexPath:NSIndexPath? = nil
        }
        switch state {
        case .Began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView.cellForRowAtIndexPath(indexPath!)
                MyCell.cellSnapshot = snapshot(cell!)
                var center = cell!.center
                MyCell.cellSnapshot!.center =  center
                MyCell.cellSnapshot!.alpha = 0.0
                tableView.addSubview(MyCell.cellSnapshot!)
                UIView.animateWithDuration(0.25, animations: {() -> Void in
                    center.y = locationInView.y
                    MyCell.cellIsAnimating = true
                    MyCell.cellSnapshot!.center = center
                    MyCell.cellSnapshot!.transform = CGAffineTransformMakeScale(1.05, 1.05)
                    MyCell.cellSnapshot!.alpha = 0.9
                    cell!.alpha = 0.0
                    }, completion: {(finished) -> Void in
                        if finished {
                            MyCell.cellIsAnimating = false
                            if MyCell.cellNeedToShow {
                                MyCell.cellNeedToShow = false
                                UIView.animateWithDuration(0.25, animations: {() -> Void in
                                    cell!.alpha = 1.0
                                })
                            }else{
                                cell!.hidden =  true
                            }
                        }
                })
            }
        case .Changed:
            if MyCell.cellSnapshot != nil {
                var center = MyCell.cellSnapshot!.center
                center.y = locationInView.y
                MyCell.cellSnapshot!.center =  center
                if indexPath != nil && indexPath !=  Path.initialIndexPath! {
                    self.route!.annotations.insert(self.route!.annotations.removeAtIndex(Path.initialIndexPath!.row), atIndex: indexPath!.row)
                    self.details.insert(details.removeAtIndex(Path.initialIndexPath!.row), atIndex: indexPath!.row)
                    
                    tableView.moveRowAtIndexPath(Path.initialIndexPath!, toIndexPath: indexPath!)
                    Path.initialIndexPath =  indexPath!
                    
                }
                
            }
        
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView.cellForRowAtIndexPath(Path.initialIndexPath!)
                if MyCell.cellIsAnimating {
                    MyCell.cellNeedToShow = true
                }else{
                    cell!.hidden = false
                    cell!.alpha = 0.0
                }
                UIView.animateWithDuration(0.25, animations: {() -> Void in
                    MyCell.cellSnapshot!.center = cell!.center
                    MyCell.cellSnapshot!.transform =  CGAffineTransformIdentity
                    MyCell.cellSnapshot!.alpha = 0.0
                    cell!.alpha = 1.0
                    }, completion: {(finished) -> Void in
                        if finished {
                            Path.initialIndexPath = nil
                            MyCell.cellSnapshot!.removeFromSuperview()
                            MyCell.cellSnapshot =  nil
                            self.navigationItem.hidesBackButton = true
                            self.presentViewController(Utilities.alertMessage("Warning", message: "You have changed the order of your points.\n Plase Click in the modify button and check your new route."), animated: true, completion: nil)
                        }
                })
                tableView.reloadData()
            }
        }
        
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "confirmRoute" {
            var i = 0
            for a in route!.annotations {
                a.subtitle =  "This point is the number " + String(i+1)
                i += 1
            }
            let destinationController = segue.destinationViewController as! RouteModifierViewController
            destinationController.route = route
            destinationController.routeTemp = routeTemp
        }
    }
    @IBAction func close(segue:UIStoryboardSegue) {
        if let viewController = segue.sourceViewController as? RouteModifierViewController {
            if let route = viewController.routeTemp {
                self.routeTemp = route.copy() as! Route
                self.route = route.copy() as! Route
                tableView.reloadData()
            }
        }
        
    }
    func snapshot(cell:UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
        cell.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let cellSnapshot:UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds =  false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
}
