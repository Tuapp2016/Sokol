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

class RouteModifierViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate,UITextFieldDelegate {
    
    @IBOutlet weak var confirm: UIButton!
    var route:Route?
    var routeTemp:Route?
    var locationManager = CLLocationManager()
    let ref = FIRDatabase.database().reference()
    var addPin:UIAlertController?
    var nameText:UITextField?
    var checkPoint:UISwitch?
    var point:CGPoint?

    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.mapType = .Standard
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(RouteModifierViewController.addAnnotation(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            //locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
        }
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //UIApplication.sharedApplication().keyWindow!.rootViewController = self
        //UIApplication.sharedApplication().keyWindow!.makeKeyAndVisible()
    }
  
    func addAnnotation(sender:UILongPressGestureRecognizer){
        if sender.state != .Ended {
            return
        }
        addPin =  UIAlertController(title: "Add Pin", message: "\n\n\n\n\n", preferredStyle: .Alert)
        let height = NSLayoutConstraint(item: addPin!.view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 260.0)
        let width = NSLayoutConstraint(item: addPin!.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 250.0)
        addPin!.view.addConstraints([height,width])
        
        let nameTextFrame = CGRectMake(5.0, 60.0, 240.0, 40.0)
        nameText = UITextField(frame: nameTextFrame)
        nameText!.borderStyle = .None
        nameText!.placeholder =  "Enter the name of the point"
        
        let checkPointLabelFrame = CGRectMake(5.0, 110.0, 240.0, 40.0)
        let checkPointLabel = UILabel(frame: checkPointLabelFrame)
        checkPointLabel.text = "Is it a check point?"
        
        let checkPointFrame = CGRectMake(5.0, 160.0, 50.0, 40.0)
        checkPoint = UISwitch(frame: checkPointFrame)
        
        let cancelButtonFrame =  CGRectMake(5.0, 210.0, 100.0, 40.0)
        let cancelButton = UIButton(frame: cancelButtonFrame)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(RouteModifierViewController.cancelPin), forControlEvents: .TouchUpInside)
        
        
        let addButtonFrame = CGRectMake(170.0, 210.0, 50.0, 40.0)
        let addButton = UIButton(frame: addButtonFrame)
        addButton.setTitle("Add", forState: .Normal)
        addButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        addButton.addTarget(self, action: #selector(RouteModifierViewController.addNewPin), forControlEvents: .TouchUpInside)
        
        addPin!.view.addSubview(nameText!)
        addPin!.view.addSubview(checkPointLabel)
        addPin!.view.addSubview(checkPoint!)
        addPin!.view.addSubview(cancelButton)
        addPin!.view.addSubview(addButton)
        
        point = sender.locationInView(mapView)
        nameText?.delegate = self
        
        self.presentViewController(addPin!, animated: true, completion: nil)
        
        
        
    }

    func cancelPin(){
        addPin!.dismissViewControllerAnimated(true, completion: nil)
    }
    func addNewPin(){
        addPin!.dismissViewControllerAnimated(true, completion: nil)
        let tappedCoordinate = mapView.convertPoint(point!, toCoordinateFromView: mapView)
        var text = (nameText!).text!
        if text == "" {
            text = "Without description"
        }
        let id = NSUUID().UUIDString
        let annotation = SokolAnnotation(coordinate: tappedCoordinate, title: text, subtitle: "This point is the number " + String((route!.annotations.count) + 1), checkPoint: checkPoint!.on,id:id)
        route!.annotations.append(annotation)
        mapView.showAnnotations(route!.annotations, animated: true)
        calculateRoute()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = true
        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
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
        var ids = [String]()
        for a in route!.annotations{
            lats.append(String(a.coordinate.latitude))
            lngs.append(String(a.coordinate.longitude))
            checks.append(a.checkPoint)
            pointNames.append(a.title!)
            ids.append(a.id!)
            
        }
        let values = ["latitudes":lats,
                      "longitudes":lngs,
                      "checkPoints":checks,
                      "pointNames":pointNames,
                      "ids":ids
        ]
        routeID.updateChildValues(values as [NSObject : AnyObject])
        self.mapView.showsUserLocation = false
        navigationController?.popToRootViewControllerAnimated(true)
        //self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    func calculateRoute(){
        mapView.removeOverlays(mapView.overlays)
        var i = 0
        while i  < route!.annotations.count-1 {
            let origin =  String(route!.annotations[i].coordinate.latitude) + "," + String(route!.annotations[i].coordinate.longitude)
            let end = String(route!.annotations[i+1].coordinate.latitude) + "," + String(route!.annotations[i+1].coordinate.longitude)
            //print("\(origin) - \(end)")
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
                                self.confirm.hidden = false
                                self.drawRoute(jsonResult)
                                
                            })
                        }else{
                            NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                                self.confirm.hidden = true
                            })
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
        let checkFrame = CGRectMake(2.0, 5.0, 50.0, 47.0)
        checkPoint = UISwitch(frame: checkFrame)
        if let a = getAnnotation(annotation) {
            if a.checkPoint {
                checkPoint!.on = true
                if #available(iOS 9.0, *){
                    annotationView?.pinTintColor =  UIColor.greenColor()
                }
            }else{
                checkPoint!.on = false
                if #available(iOS 9.0, *){
                    annotationView?.pinTintColor =  UIColor.redColor()
                }
            }
        }
        let view:UIView = UIView(frame: CGRectMake(0.0,0.0,53.0,53.0))
        checkPoint!.tag = getPositionAnnotation(annotation)
        checkPoint!.addTarget(self, action: #selector(RouteModifierViewController.changePin(_:)), forControlEvents: .ValueChanged)
        view.addSubview(checkPoint!)
        annotationView!.leftCalloutAccessoryView = view
        let button = UIButton(type: .Custom) as UIButton
        button.frame = CGRectMake(0.0, 0.0, 53.0, 53.0)
        button.setImage(UIImage(named: "remove"), forState: .Normal)
        button.addTarget(self, action: #selector(RouteModifierViewController.removePin(_:)), forControlEvents: .TouchUpInside)
        button.tag = getPositionAnnotation(annotation)
        annotationView!.rightCalloutAccessoryView = button
        annotationView?.draggable =  true
        
        return annotationView
    }
    func removePin(sender:UIButton){
        if route?.annotations.count > 2 {
            let a  = route!.annotations.removeAtIndex(sender.tag)
            mapView.removeAnnotation(a)
            var annotationsTemp = [SokolAnnotation]()
            for (index,annotation) in route!.annotations.enumerate() {
                annotation.subtitle =  "This point is the number " + String(index + 1)
                annotationsTemp.append(annotation)
            }
            mapView.removeAnnotations(route!.annotations)
            route!.annotations = []
            for annotation in annotationsTemp {
                route!.annotations.append(annotation)
            }
            mapView.showAnnotations(route!.annotations, animated: true)
            calculateRoute()
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "We can't delete the pin becase the minimun number of points is 2"), animated: true, completion: nil)
        }
    }
    func changePin(sender:UISwitch){
        let a = route!.annotations.removeAtIndex(sender.tag)
        mapView.removeAnnotation(a)
        let newAnnotation = SokolAnnotation(coordinate: a.coordinate, title: a.title!, subtitle: a.subtitle!, checkPoint: sender.on,id:a.id!)
        route!.annotations.insert(newAnnotation, atIndex: sender.tag)
        mapView.showAnnotations(route!.annotations, animated: true)
    }
    func getPositionAnnotation(annotation:MKAnnotation) -> Int {
        var i = 0
        for a in route!.annotations {
            if a.coordinate.latitude == annotation.coordinate.latitude && a.coordinate.longitude == annotation.coordinate.longitude {
                return i
            }
            i += 1
        }
        return -1
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
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else{
            return true
        }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 15
    }
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways:
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation =  true
        case .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation =  true
        default:
            print("The user doesn't allow to know where he is")
        }
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
