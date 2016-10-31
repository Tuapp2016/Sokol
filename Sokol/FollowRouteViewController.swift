//
//  FollowRouteViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 21/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import Polyline
import CoreLocation
import ReachabilitySwift


class FollowRouteViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,UIPopoverPresentationControllerDelegate {
    var route:Route?
    let ref = FIRDatabase.database().reference()
    var peekAndPop = false
    var is3D = false
    var location:CLLocation?
    var checkCount = 0
    @IBOutlet weak var mapView: MKMapView!
    var directions:[String] = []
    var reachability:Reachability?
    
    @IBOutlet weak var cancel: UIButton!
    
    @IBOutlet weak var screenshot: UIButton!
    var locationManager:CLLocationManager? = CLLocationManager()
    
    @IBOutlet weak var start: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.mapType = .Standard
        mapView.pitchEnabled = true
        mapView.showsBuildings = true
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        
        screenshot.hidden = true
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager!.delegate =  self
            locationManager!.requestAlwaysAuthorization()
            locationManager!.requestWhenInUseAuthorization()
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager!.distanceFilter = kCLDistanceFilterNone
            locationManager!.activityType = .AutomotiveNavigation
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.hidden = true
        if peekAndPop{
            let leadingConstraint = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: mapView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
            let trailingConstraint = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: mapView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            view.addConstraints([leadingConstraint,trailingConstraint])
        }
        do{
            reachability = try Reachability.reachabilityForInternetConnection()
        }catch{
            print("Error")
        }
        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        //UIApplication.sharedApplication().keyWindow!.rootViewController = self
        //UIApplication.sharedApplication().keyWindow!.makeKeyAndVisible()
        checkCount = getCheckPoints()
        
        mapView.showAnnotations(route!.annotations,animated: true)
        calculaterRoute()
        addOverlays()
        
    }
    deinit{
        locationManager!.delegate = nil
        locationManager = nil
    }
    func getCheckPoints() -> Int {
        var i = 0
        for a in route!.annotations {
            if a.checkPoint{
                i += 1
            }
        }
        return i
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        var annotationView:MKPinAnnotationView? = mapView.dequeueReusableAnnotationViewWithIdentifier("myPin") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView =  MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            annotationView?.canShowCallout = true
        }
        if let a = getAnnotation(annotation) {
            if a.checkPoint {
                annotationView?.pinTintColor = UIColor.greenColor()
            }else{
                annotationView?.pinTintColor = UIColor.redColor()
            }
        }
    
        return annotationView
    }
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 2.0
            circleRenderer.strokeColor = UIColor.purpleColor()
            circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
            return circleRenderer
        }else{
            let render = MKPolylineRenderer(overlay: overlay)
            render.lineWidth = 5.0
            render.strokeColor = UIColor.purpleColor()
            render.alpha = 0.5
            return render
        }
    }
    func drawRoute(jsonResult:NSDictionary){
        
        var coordinates = [CLLocationCoordinate2D]()
        let routes = jsonResult["routes"] as! [AnyObject]
        let route = routes[0] as! NSDictionary
        let legs  = route["legs"] as! [AnyObject]
        let leg = legs[0] as! NSDictionary
        let steps = leg["steps"] as! [AnyObject]
        for step in steps{
            let s = step as! NSDictionary
            directions.append(s["html_instructions"] as! String)
        }
        let overview = route["overview_polyline"] as! NSDictionary
        let points = overview["points"] as! String
        let polylines = Polyline(encodedPolyline: points)
        coordinates = polylines.coordinates!
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

    }
    func getAnnotation(annotation:MKAnnotation) -> SokolAnnotation? {
        for a in route!.annotations {
            if  a.coordinate.longitude == annotation.coordinate.longitude && a.coordinate.latitude == annotation.coordinate.latitude {
                return a
            }
        }
        return nil
    }
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        let annotationView = views[0]
        let endFrame = annotationView.frame
        annotationView.frame = CGRectOffset(endFrame, 0, -600)
        UIView.animateWithDuration(0.3, animations: { () in
                annotationView.frame = endFrame
        })
        
    }
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways:
            locationManager!.startUpdatingLocation()
            mapView.showsUserLocation =  true
        case .AuthorizedWhenInUse:
            locationManager!.startUpdatingLocation()
            mapView.showsUserLocation =  true
        default:
            let alertController = UIAlertController(title: "Location", message: "In order to  enjoy this functionality, please enable the location service in settings", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(action) in
                self.stopMonitoringAnnotations()
                self.locationManager?.stopUpdatingLocation()
                self.start.hidden = true
            })
            let openAction = UIAlertAction(title: "Open settings", style: .Default, handler: {(action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString){
                    UIApplication.sharedApplication().openURL(url)
                }
            })
            alertController.addAction(cancelAction)
            alertController.addAction(openAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    func regionWithAnnotation(annotation:SokolAnnotation) -> CLCircularRegion{
        let region = CLCircularRegion(center: annotation.coordinate, radius: 250.0, identifier: annotation.id! + String("SOKOL") + route!.id)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        return region
    }
    func startMonitoringAnnotation(annotation:SokolAnnotation){
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion){
            self.presentViewController(Utilities.alertMessage("Error", message: "Geofencing is not supported on this device!"), animated: true, completion: nil)
        }
        var isMonitoring = false
        let region = regionWithAnnotation(annotation)
        for r in locationManager!.monitoredRegions {
            if let reg = r  as? CLCircularRegion{
                if reg.identifier == region.identifier {
                    isMonitoring = true
                }
            }
        }
        if !isMonitoring{
            locationManager!.startMonitoringForRegion(region)
            addRadiusOverlayForAnnotation(annotation)
        }
    }
    func stopMonitoringAnnotations(){
        for region in locationManager!.monitoredRegions{
            if let circularRegion = region as? CLCircularRegion{
                locationManager!.stopMonitoringForRegion(circularRegion)
            }
        }
        removeOverlayForAnnotations()
    }
    func addOverlays(){
        for region in locationManager!.monitoredRegions{
            if let circularRegion = region as? CLCircularRegion{
                mapView.addOverlay(MKCircle(centerCoordinate: circularRegion.center, radius: 250.0))
            }
        }
    }
    func addRadiusOverlayForAnnotation(annotation:SokolAnnotation){
        mapView.addOverlay(MKCircle(centerCoordinate: annotation.coordinate, radius: 250.0))
    }

    func removeOverlayForAnnotations(){
        for overlay in mapView.overlays{
            if let o = overlay as? MKCircle{
                mapView.removeOverlay(o)
            }
        }
    }
    func getNearestAnnotations()-> [SokolAnnotation]{
        var annotations = [SokolAnnotation]()
        for a in route!.annotations {
            if a.checkPoint {
                annotations.append(a)
            }
        }
        annotations.sortInPlace{(a:SokolAnnotation,b:SokolAnnotation) -> Bool in
            let R = 6371e3
            let phiA = a.coordinate.latitude.degreesToRadians
            let phiB = a.coordinate.latitude.degreesToRadians
            let phiUser = location!.coordinate.latitude.degreesToRadians
            let deltaPhiA = (location!.coordinate.latitude - a.coordinate.latitude).degreesToRadians
            let deltaPhiB = (location!.coordinate.latitude - b.coordinate.latitude).degreesToRadians
            let deltaLamdaA = (location!.coordinate.longitude - a.coordinate.longitude).degreesToRadians
            let deltaLamdaB = (location!.coordinate.longitude - b.coordinate.longitude).degreesToRadians
            
            var aA = sin(deltaPhiA/2.0) * sin(deltaPhiA/2.0 ) + cos(phiA) * cos(phiUser)
            aA += sin(deltaLamdaA/2.0) * sin(deltaLamdaA/2.0)

            let cA = 2 * atan2(sqrt(aA), sqrt(1 - aA))
            let dA = R * cA
            
            var aB = sin(deltaPhiB/2.0) * sin(deltaPhiB/2.0 ) + cos(phiB) * cos(phiUser)
            aB += sin(deltaLamdaB/2.0) * sin(deltaLamdaB/2.0)
            let cB = 2 * atan2(sqrt(aB), sqrt(1 - aB))
            let dB = R * cB
            return dA < dB
        }
        let ann = Array(annotations[0..<20])
        return ann
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        if is3D {
            let activeRoute = self.ref.child("logs")
            let activeRouteById = activeRoute.child(route!.id)
            if let user = FIRAuth.auth()?.currentUser {
                let activeRouteByIdByUser = activeRouteById.child(user.uid)
                activeRouteByIdByUser.observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                    if !(snapshot.value is NSNull){
                        let values = snapshot.value as! NSDictionary
                        var coor = [String]()
                        let dateFormater = NSDateFormatter()
                        dateFormater.dateFormat = "yyyy-MM-dd, HH:mm:ss"
                        dateFormater.timeZone = NSTimeZone(name: "COT")
                        let str = dateFormater.stringFromDate(NSDate())
                        var coordinates = values["coordiantes"] as? [String]
                        if var c = coordinates{
                            c.append(String(self.location!.coordinate.latitude) + "+" + String(self.location!.coordinate.longitude) + "+" + str)
                            coor = c
                        }else{
                            var c = [String]()
                            c.append(String(self.location!.coordinate.latitude) + "+" + String(self.location!.coordinate.longitude) + "+" + str)
                            coor = c
                        }
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({()
                            activeRouteByIdByUser.updateChildValues(["coordinates":coor])
                        })
                        
                    }
                })
                
            }

            if checkCount < 21 {
                for a in route!.annotations {
                    if a.checkPoint {
                        startMonitoringAnnotation(a)
                    }
                }
            }else{//We need to find the nearest annotations to the user
                stopMonitoringAnnotations()
                let annotations = getNearestAnnotations()
                for a in annotations{
                    startMonitoringAnnotation(a)
                }
                
            }
            let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            self.mapView.setRegion(region, animated: true)
            let altitude:CLLocationDistance = 100.0
            let heading:CLLocationDirection = 45.0
            let camera = MKMapCamera(lookingAtCenterCoordinate: center, fromDistance: altitude, pitch: 80.0, heading: heading)
            mapView.setCamera(camera, animated: true)
        }
    }
    func calculaterRoute(){
        directions = []
        mapView.removeOverlays(mapView.overlays)
        var i = 0
        let annotations = route!.annotations
        while  i < (annotations.count - 1) {
            let origin = String(annotations[i].coordinate.latitude) + "," + String(annotations[i].coordinate.longitude)
            let end = String(annotations[i+1].coordinate.latitude) + "," + String(annotations[i+1].coordinate.longitude)
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin="+origin+"&destination="+end+"&key="+Constants.DIRECTION_KEY
            let request = NSURLRequest(URL: NSURL(string:urlString)!)
            let urlSession = NSURLSession.sharedSession()
            let task = urlSession.dataTaskWithRequest(request,completionHandler: {(data,response,error)-> Void in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    do{
                        let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary
                        let status = jsonResult["status"] as! String
                        if !(status == "ZERO_RESULTS"){
                            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                                self.drawRoute(jsonResult)
                            })
                        }else{
                            self.presentViewController(Utilities.alertMessage("Error", message: "We can't find any route.\n"), animated: true, completion: nil)
                        }
                    }catch {
                        print(error)
                    }
                }
            })
            task.resume()
            i += 1
            
        }
    }
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        self.presentViewController(Utilities.alertMessage("Error", message: "Monitoring failed for region with identifier: \(region!.identifier) "), animated: true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        self.presentViewController(Utilities.alertMessage("Error", message: "Location Manager failed"), animated: true, completion: nil)
       
    }
    
   
    @IBAction func takeScreenshot(sender: AnyObject) {
        is3D = false
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 250.0, longitudeDelta: 250.0))
        self.mapView.setRegion(region, animated: false)
        let altitude:CLLocationDistance = 1000
        let heading:CLLocationDirection = 45.0
        let camera = MKMapCamera(lookingAtCenterCoordinate: center, fromDistance: altitude, pitch: 80.0, heading: heading)
        mapView.setCamera(camera, animated: false)
        screenshot.hidden = true
        let timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(FollowRouteViewController.takeScreenshotTimer), userInfo: nil, repeats: false)
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = UIImagePNGRepresentation(image!)
        
        if imageData != nil {
            if reachability?.currentReachabilityStatus == .ReachableViaWiFi || reachability?.currentReachabilityStatus == .ReachableViaWWAN{
                sendRequest(imageData)
            }else{
                self.presentViewController(Utilities.alertMessage("Error", message: "We need an active connection to take the screenshot"), animated: true, completion: nil)
            }
        }
        
        
    }
    func takeScreenshotTimer(){
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = UIImagePNGRepresentation(image!)
        
        if imageData != nil {
            if reachability?.currentReachabilityStatus == .ReachableViaWiFi || reachability?.currentReachabilityStatus == .ReachableViaWWAN{
                sendRequest(imageData)
            }else{
                self.presentViewController(Utilities.alertMessage("Error", message: "We need an active connection to take the screenshot"), animated: true, completion: nil)
            }
        }

        
    }
    func sendRequest(image:NSData?){
        let URL = NSURL(string:"https://fcmsokol.herokuapp.com/images/createAndSend")
        let request = NSMutableURLRequest(URL: URL!,cachePolicy: .UseProtocolCachePolicy,timeoutInterval: 30.0)
        request.HTTPMethod = "POST"
        let boundary = "Boundary-\(NSUUID().UUIDString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = NSMutableData()
        let values = ["token_id":FIRInstanceID.instanceID().token()!,"route":route!.id]
        for (key,value) in values{
            body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("\(value)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        
        let fname = "screenshot.png"
        let mimetype = "image/png"

        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(image!)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        request.HTTPBody = body
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {
            (data,response,error) in
            if let httpResponse = response as? NSHTTPURLResponse{
                
                //let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
                if httpResponse.statusCode == 200 {
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        self.is3D = true
                        self.screenshot.hidden = false

                        self.presentViewController(Utilities.alertMessage("Success", message: "We have sent the screenshot"), animated: true, completion: nil)
                    })
                }else{
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        self.is3D = true
                        self.screenshot.hidden = false
                        self.presentViewController(Utilities.alertMessage("Error", message: "We can't send the screenshot"), animated: true, completion: nil)
                    })
                }
            }

        }
        task.resume()
    }
    
    @IBAction func startRoute(sender: AnyObject) {
        //start.removeFromSuperview()
        if start.currentTitle != "Show directions" {
            screenshot.hidden = false
            let dateFormater = NSDateFormatter()
            dateFormater.dateFormat = "yyyy-MM-dd, HH:mm:ss"
            dateFormater.timeZone = NSTimeZone(name: "COT")
            let str = dateFormater.stringFromDate(NSDate())
            let activeRoute = self.ref.child("logs")
            let activeRouteById = activeRoute.child(route!.id)
            if let user = FIRAuth.auth()?.currentUser {
                let activeRouteByIdByUser = activeRouteById.child(user.uid)
                activeRouteByIdByUser.updateChildValues(["startRoute":str,"finishRoute":"No time","coordinates":[]])
            }
            if reachability?.currentReachabilityStatus == .ReachableViaWiFi || reachability?.currentReachabilityStatus == .ReachableViaWWAN {
                let strategy:SendTopic = SendTopic()
                let sendMessageClient:SendMessageClient = SendMessageClient(strategy: strategy)
                
                sendMessageClient.sendMessage("The route with id: \(route!.id) just started at \(str)", title: "Notification start route", id: route?.id, page: nil)
            }else{
                SmallCache.sharedInstance.cacheOperations["startRoute"] = ["title":"Notification start route","body":"The route with id: \(route!.id) just started at \(str)","id":route!.id,"time":str]
            }
            cancel.setTitle("Finish route", forState: .Normal)
            
            is3D = true
            if location != nil {
                let altitude:CLLocationDistance = 400.0
                let heading:CLLocationDirection = 0.0
                let camera = MKMapCamera(lookingAtCenterCoordinate: CLLocationCoordinate2D(latitude: location!.coordinate.latitude,longitude: location!.coordinate.longitude), fromDistance: altitude, pitch: 80.0, heading: heading)
                mapView.setCamera(camera, animated: true)
            }
            start.setTitle("Show directions", forState: .Normal)

        }else {//Here we should open our directions view
            let storyboard = UIStoryboard(name: "Follow", bundle: nil)
            let navigation = storyboard.instantiateViewControllerWithIdentifier("directionsRoute") as! UINavigationController
            var directionsController = navigation.viewControllers[0] as! DirectionsTableViewController
            let bounds = UIScreen.mainScreen().bounds
            if bounds.width > 400.0 {
                navigation.modalPresentationStyle = .Popover
                navigation.preferredContentSize = CGSizeMake(320, 150)
                let popoverMenuViewController = navigation.popoverPresentationController
                popoverMenuViewController?.permittedArrowDirections = .Any
                popoverMenuViewController?.delegate = self
                popoverMenuViewController?.sourceView = start;
                popoverMenuViewController?.sourceRect = CGRect(x: 0, y: 25, width: 1, height: 1)
            }
            directionsController.directions = self.directions
                
            presentViewController(navigation, animated: true, completion: nil)
                
        }
        
        
    }
    @IBAction func cancelRoute(sender: AnyObject) {
        if cancel.currentTitle == "Finish route"{
            cancel.enabled = false
            let dateFormater = NSDateFormatter()
            dateFormater.dateFormat = "yyyy-MM-dd, HH:mm:ss"
            dateFormater.timeZone = NSTimeZone(name: "COT")
            let str = dateFormater.stringFromDate(NSDate())
            let activeRoute = self.ref.child("logs")
            let activeRouteById = activeRoute.child(route!.id)
            if let user = FIRAuth.auth()?.currentUser {
                let activeRouteByIdByUser = activeRouteById.child(user.uid)
                activeRouteByIdByUser.updateChildValues(["finishRoute":str])
            }
            
            if reachability?.currentReachabilityStatus == .ReachableViaWiFi || reachability?.currentReachabilityStatus == .ReachableViaWWAN {
                let strategy:SendTopic = SendTopic()
                let sendMessageClient:SendMessageClient = SendMessageClient(strategy: strategy)
                sendMessageClient.sendMessage("The route with id: \(route!.id) just finished at \(str)", title: "Notification finish route", id: route?.id, page: nil)
            }else{
                SmallCache.sharedInstance.cacheOperations["finishRoute"] = ["title":"Notification finish route","body":"The route with id: \(route!.id) just finished at \(str))","id":route!.id,"time":str]
            }
            is3D = false
            locationManager!.stopUpdatingLocation()
            stopMonitoringAnnotations()
            mapView.showsUserLocation = false
            if peekAndPop {
                navigationController?.popViewControllerAnimated(true)
            }else{
                let timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(FollowRouteViewController.closeTimer), userInfo: nil, repeats: false)
            }
    

        }else{
            is3D = false
            locationManager!.stopUpdatingLocation()
            stopMonitoringAnnotations()
            mapView.showsUserLocation = false
            if peekAndPop{
                navigationController?.popViewControllerAnimated(true)
            }else{
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    func closeTimer(){
        self.dismissViewControllerAnimated(true, completion: nil)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    func adaptivePresentationStyleForPresentationController(PC: UIPresentationController) -> UIModalPresentationStyle{
        
        let size = PC.presentingViewController.view.frame.size
        if(size.width>400.0){
            return .None
        }else{
            return .FullScreen
        }
        
    }
    
}
extension Double{
    var degreesToRadians:Double {return Double(self) * M_PI / 180}
}
