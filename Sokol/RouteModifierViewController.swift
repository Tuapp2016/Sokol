//
//  RouteModifierViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 10/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import MapKit
import Polyline
import Firebase

class RouteModifierViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    var route:Route?
    var locationManager = CLLocationManager()
    let ref = FIRDatabase.database().reference()

    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.mapType = .Standard
        
        /*let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPressGestureRecognizer.minimumPressDuration = 0.5*/
        //mapView.addGestureRecognizer(longPressGestureRecognizer)

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        locationManager.startUpdatingLocation()
        mapView.showAnnotations(route!.annotations, animated: true)
        calculateRoute()

    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirmNewRoute(sender: AnyObject) {
            //let viewController =  navigationController?.viewControllers[0]
        let routesRef = ref.child("routes")
        let routeID = routesRef.child(route!.id)
        var lats = [String]()
        var lngs = [String]()
        var checks = [Bool]()
        var pointNames = [String]()
        for a in route!.annotations{
            lats.append(String(a.coordinate.latitude))
            lngs.append(String(a.coordinate.longitude))
            checks.append(a.checkPoint)
            pointNames.append(a.title!)
            
        }
        let values = ["latitudes":lats,
                      "longitudes":lngs,
                      "checkPoints":checks,
                      "pointNames":pointNames
        ]
        routeID.updateChildValues(values as [NSObject : AnyObject])
        navigationController?.popToRootViewControllerAnimated(true)
        //self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    func calculateRoute(){
        mapView.removeOverlays(mapView.overlays)
        var i = 0
        while i  < route!.annotations.count-1 {
            let origin =  String(route!.annotations[i].coordinate.latitude) + "," + String(route!.annotations[i].coordinate.longitude)
            let end = String(route!.annotations[i+1].coordinate.latitude) + "," + String(route!.annotations[i+1].coordinate.longitude)
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
                            self.presentViewController(Utilities.alertMessage("Error", message: "We can't find any route.\n Please try to move or add more points"), animated: true, completion: nil)
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
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        let annotationView = views[0]
        let endFrame = annotationView.frame
        annotationView.frame =  CGRectOffset(endFrame, 0, -600)
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            annotationView.frame = endFrame
        })
        
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation){
            return nil
        }
        var annotationView:MKPinAnnotationView? = mapView.dequeueReusableAnnotationViewWithIdentifier("myPin") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            annotationView?.canShowCallout = true
        }
        annotationView?.canShowCallout = true
        if let a = getAnnotation(annotation) {
            if a.checkPoint {
                if #available(iOS 9.0, *){
                   annotationView?.pinTintColor =  UIColor.greenColor()
                }
            }else{
                if #available(iOS 9.0, *){
                    annotationView?.pinTintColor =  UIColor.redColor()
                }
            }
        }
        annotationView?.draggable =  true
        return annotationView
    }
    func getAnnotation(annotation:MKAnnotation) -> SokolAnnotation?{
        for a in route!.annotations {
            if a.coordinate.latitude == annotation.coordinate.latitude && a.coordinate.longitude == annotation.coordinate.longitude {
                return a
            }
        }
        return nil
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            calculateRoute()
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
