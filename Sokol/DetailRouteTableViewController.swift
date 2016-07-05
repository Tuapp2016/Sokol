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

    override func viewDidLoad() {
        super.viewDidLoad()

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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (route?.annotations.count)!
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pointCell", forIndexPath: indexPath) as! PointTableViewCell
        let lat = route!.annotations[indexPath.row].coordinate.latitude
        let lng = route!.annotations[indexPath.row].coordinate.longitude
        let check = route!.annotations[indexPath.row].checkPoint
        cell.latitudeText.text = "Lat: " + String(lat)
        cell.longitudeText.text = "Lng " + String(lng)
        cell.checkpoint.on = check
        cell.checkpoint.tag = indexPath.row
        cell.checkpoint.addTarget(self, action: "changeCheckpoint:", forControlEvents: .ValueChanged)
        // Configure the cell...

        return cell
    }
    func changeCheckpoint(sender:UISwitch){
        route?.annotations[sender.tag].checkPoint = sender.on
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Points"
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 200.0
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 105.0
    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("headerCell") as! HeaderTableViewCell
        headerCell.nameText.text =  route!.name
        headerCell.descriptionText.text = route!.description
        
        return headerCell
        
    }
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            let routes = ref.child("routes")
            let routeId = routes.child(route!.id)
            var check=[Bool]()
            for a in route!.annotations{
                check.append(a.checkPoint)
            }
            routeId.updateChildValues(["checkPoints":check])
        }
    }
}
