//
//  DirectionsTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 11/08/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit

class DirectionsTableViewController: UITableViewController {
    var directions:[String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelDirections:")
        let bounds  = UIScreen.mainScreen().bounds
        if bounds.width > 400 {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        tableView.estimatedRowHeight = 50.0
        tableView.rowHeight = UITableViewAutomaticDimension

    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! DirectionsTableViewCell

        cell.direction.text = directions[indexPath.row].html2String
        return cell
    }
    func cancelDirections(sender:AnyObject){
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    

}
extension String{
    var html2AttributedString:NSAttributedString? {
        guard let data = dataUsingEncoding(NSUTF8StringEncoding) else{
            return nil
        }
        do{
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
            
        }catch let error as NSError{
            print(error.localizedDescription)
            return nil
        }
    }
    var html2String:String{
        return html2AttributedString?.string ?? ""
    }
}
