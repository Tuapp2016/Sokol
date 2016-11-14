//
//  LogByRouteByUserTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 31/10/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class LogByRouteByUserTableViewController: UITableViewController {
    var routeId:String?
    var userId:String?
    var ref = FIRDatabase.database().reference()
    var startDate:String? = ""
    var finishDate:String? = ""
    var logsByRouteByUserArray = [LogByRouteByUser]()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 125
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .SingleLine
        tableView.tableFooterView =  UIView()
        let image = UIImage(named: "route")
        let rigthBarButton = UIBarButtonItem(image:image, style: .Done, target: self, action: #selector(LogByRouteByUserTableViewController.openMap))
        self.navigationItem.rightBarButtonItem = rigthBarButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let logs = ref.child("logs")
        let logsByRoute = logs.child(routeId!)
        let logsByRouteByUser = logsByRoute.child(userId!)
        logsByRouteByUser.observeEventType(.Value, withBlock: {(snapshot) in
            if !(snapshot.value is NSNull){
                self.logsByRouteByUserArray = []
                let values = snapshot.value as! NSDictionary
                self.finishDate = values["finishRoute"] as! String
                self.startDate = values["startRoute"] as! String
                let coordinates = values["coordinates"] as? [String]
                if let c = coordinates {
                    for v in c{
                        let valuesCoordinates = v.componentsSeparatedByString("+")
                        self.logsByRouteByUserArray.append(LogByRouteByUser(lat: valuesCoordinates[0], lng: valuesCoordinates[1], date: valuesCoordinates[2],details:false,lifespan:valuesCoordinates[3]))
                        
                    }
                }
                
                
            }else{
                self.logsByRouteByUserArray = []
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                self.tableView.reloadData()
            })
        })
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        let logs = ref.child("logs")
        let logsByRoute = logs.child(routeId!)
        let logsByRouteByUser = logsByRoute.child(userId!)
        logsByRouteByUser.removeAllObservers()
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
        return logsByRouteByUserArray.count
    }
    func openMap(selector:AnyObject?){
        let viewController = UIStoryboard.init(name: "Care", bundle: nil).instantiateViewControllerWithIdentifier("logMap") as! LogByRouteByUserMapViewController
        viewController.userId = userId!
        viewController.routeId = routeId!
        self.presentViewController(viewController, animated: true, completion: nil)
        
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 95.0
    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("headerLog") as! HeaderLogTableViewCell
        headerCell.startDateText.text = "Start date: " + startDate!
        headerCell.finishDateText.text = finishDate! == "No time" ? "Finish date:  The route is in progress" : "Finish date: " + finishDate!
        return headerCell.contentView
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellSmall:LogByUserSmallTableViewCell?
        var cell:LogByUserTableViewCell?
        if !logsByRouteByUserArray[indexPath.row].details{
            cellSmall = tableView.dequeueReusableCellWithIdentifier("logByUserSmall") as! LogByUserSmallTableViewCell
            cellSmall!.dateText.text = "Date: " + logsByRouteByUserArray[indexPath.row].date
            cellSmall!.dateText.textAlignment = .Right
            cellSmall!.nameText.text = "We are looking for the direction of the point, this task can take a while ..\n"
            cellSmall!.showMore.tag = indexPath.row
            cellSmall!.showMore.addTarget(self, action: #selector(LogByRouteByUserTableViewController.showMore(_:)), forControlEvents: .TouchUpInside)
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("logByUser") as! LogByUserTableViewCell
            cell!.dateText.text = "Date: " + logsByRouteByUserArray[indexPath.row].date
            cell!.dateText.textAlignment = .Right
            cell!.nameText.text = "We are looking for the direction of the point, this task can take a while ..\n"
            
            cell!.latitudeText.text = "Lat: " + logsByRouteByUserArray[indexPath.row].lat
            cell!.longitudeText.text = "Lng: " + logsByRouteByUserArray[indexPath.row].lng
            cell!.showLess.tag = indexPath.row
            cell!.lifespanText.text = "Lifespan: " + logsByRouteByUserArray[indexPath.row].lifespan
            cell!.showLess.addTarget(self, action: #selector(LogByRouteByUserTableViewController.showMore(_:)), forControlEvents: .TouchUpInside)

        }
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng="+String(logsByRouteByUserArray[indexPath.row].lat
            )+","+String(logsByRouteByUserArray[indexPath.row].lng)+"&key="+Constants.DIRECTION_KEY
        let request = NSURLRequest(URL: NSURL(string: urlString )!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request){(data, response, error) in
            if let error  = error {
                print(error)
            }
            if let data = data{
                do{
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                    let status = jsonResult["status"] as! String
                    if !(status == "ZERO_RESULTS"){
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            let results = jsonResult["results"] as! NSArray
                            let result = results[0] as! NSDictionary
                            let formatted_address = result["formatted_address"] as! String
                            if let c = cell{
                                cell!.nameText.text = "Calculated address: \(formatted_address)"

                            }else{
                                cellSmall!.nameText.text = "Calculated address: \(formatted_address)"
                            }
                        })
                    }else{
                        NSOperationQueue.mainQueue().addOperationWithBlock({() in
                            if let c = cell{
                                cell!.nameText.text = "We can't find any address"
                                
                            }else{
                                cellSmall!.nameText.text = "We can't find any address"
                            }
                        })
                    }
                }catch {
                    print(error)
                }
            }
        }
       
        task.resume()
        if logsByRouteByUserArray[indexPath.row].details{
            return cell!
        }else{
            return cellSmall!
        }
        
    }
    func showMore(sender:AnyObject?){
        logsByRouteByUserArray[sender!.tag].details = !logsByRouteByUserArray[sender!.tag].details
        var indexs = [NSIndexPath]()
        indexs.append(NSIndexPath(forRow: sender!.tag, inSection: 0))
        self.tableView.reloadRowsAtIndexPaths(indexs, withRowAnimation: .Fade)
    }
}
