//
//  LogByRouteByUserMapViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/11/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import Polyline

class LogByRouteByUserMapViewController: UIViewController,MKMapViewDelegate {
    let ref =  FIRDatabase.database().reference()
    
    @IBOutlet weak var mapView: MKMapView!
    var routeId:String?
    var userId:String?
    var logsByRouteByUserArray = [LogByRouteByUser]()
    var startDate = ""
    var finishDate = ""
    var finishRoute = false
    var notificationView:UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.mapType = .Standard
        // Do any additional setup after loading the view.
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
                self.startDate =  values["startRoute"] as! String
                self.finishDate =  values["finishRoute"] as! String
                if self.finishDate != "No time"{
                    self.showNotification()
                }
                
                let coordinates = values["coordinates"] as? [String]
                if let c = coordinates {
                    for v in c {
                        let valuesCoordinates = v.componentsSeparatedByString("+")
                        self.logsByRouteByUserArray.append(LogByRouteByUser(lat: valuesCoordinates[0], lng: valuesCoordinates[1], date: valuesCoordinates[2],details:false,lifespan:valuesCoordinates[3]))
                    }
                }
            }else{
                self.logsByRouteByUserArray = []
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                self.loadAnnotations()
            })
        })
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let logs = ref.child("logs")
        let logsByRoute = logs.child(routeId!)
        let logsByRouteByUser = logsByRoute.child(userId!)
        logsByRouteByUser.removeAllObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        let annotationView = views[0]
        let endFrame = annotationView.frame
        annotationView.frame =  CGRectOffset(endFrame, 0, -600)
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            annotationView.frame = endFrame
        })
    }
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.lineWidth = 3.0
        render.strokeColor = UIColor.purpleColor()
        render.alpha = 0.5
        return render
    }
    func drawRoute(jsonResult:NSDictionary){
        var coordinates = [CLLocationCoordinate2D]()
        let routes = jsonResult["routes"] as! [AnyObject]
        let route = routes[0] as! NSDictionary
        let overview = route["overview_polyline"] as! NSDictionary
        let points = overview["points"] as! String
        let polylines = Polyline(encodedPolyline: points,precision: 1e5)
        coordinates = polylines.coordinates!
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
    }
    func showNotification(){
        if !finishRoute{
            let frame = CGRectMake(0, 0, view.frame.width, 100.0)
            notificationView = UIView(frame: frame)
            notificationView!.backgroundColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
            let frameLabel = CGRectMake(10.0, 10.0, view.frame.width - 10.0 , 80.0)
            let label = UILabel(frame: frameLabel)
            label.text = "The route just finished \nDate: \(finishDate)"
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 3
            label.tintColor = UIColor.whiteColor()
            label.textColor = UIColor.whiteColor()
            label.font = UIFont(name: "Avenir", size: 22.0)

            notificationView!.addSubview(label)
            notificationView!.alpha = 0
            view.addSubview(notificationView!)
            UIView.animateWithDuration(3) {() -> Void in
                self.notificationView!.alpha = 1
            }
            let timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(LogByRouteByUserMapViewController.closeNotification), userInfo: nil, repeats: false)
            
        }
        finishRoute = true
    }
    func closeNotification(){
        UIView.animateWithDuration(3) {() -> Void in
            self.notificationView!.alpha = 0
        }
    }
    func loadAnnotations(){
        var annotations = [CareAnnotation]()
        for c in logsByRouteByUserArray{
            let id = NSUUID().UUIDString
            let coordinate = CLLocationCoordinate2D(latitude: Double(c.lat)!, longitude: Double(c.lng)!)
            let a =  CareAnnotation(coordinate: coordinate, title: "Date: " + c.date, subtitle: "Lifespan: " + c.lifespan + " seconds", id: id)
            annotations.append(a)
            
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.showAnnotations(annotations, animated: true)
        if logsByRouteByUserArray.count > 1 {
            calculateRoute()
        }
    }
    func calculateRoute(){
        mapView.removeOverlays(mapView.overlays)
        var i = 0
        while i  < logsByRouteByUserArray.count - 1 {
            let origin =  logsByRouteByUserArray[i].lat + "," + logsByRouteByUserArray[i].lng
            let end =  logsByRouteByUserArray[i + 1].lat + "," + logsByRouteByUserArray[i + 1].lng
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin="+origin+"&destination="+end+"&key="+Constants.DIRECTION_KEY
            let request = NSURLRequest(URL: NSURL(string: urlString)!)
            let urlSession = NSURLSession.sharedSession()
            let task = urlSession.dataTaskWithRequest(request, completionHandler: {(data,response,error) in
                if let error  = error {
                    print(error)
                }
                if let data = data {
                    do{
                        let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        let status = jsonResult["status"] as! String
                        if !(status == "ZERO_RESULTS"){
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                self.drawRoute(jsonResult)
                                
                            })
                        }else{
                            NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                                self.presentViewController(Utilities.alertMessage("Error", message: "We can't find any route.\n Please try to move or add more points"), animated: true, completion: nil)
                            })
                            
                        }
                    }catch {
                        print (error)
                    }
                    
                }
            })
            task.resume()
            i += 1
            
        }
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


}
