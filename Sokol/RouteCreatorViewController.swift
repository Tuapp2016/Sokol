//
//  RouteCreatorViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 03/07/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import MapKit
import Polyline
import Firebase

class RouteCreatorViewController: UIViewController, CLLocationManagerDelegate,MKMapViewDelegate,UITextFieldDelegate{
    
    @IBOutlet weak var calculateRoute: UIButton!
    @IBOutlet var mapView:MKMapView!
    var isRouteCalculated = false
    var annotations = [SokolAnnotation]()
    var locationManager = CLLocationManager()
    var nameText: UITextField? = UITextField()
    var checkPoint:UISwitch?
    var addPin:UIAlertController?
    var point:CGPoint?
    var nameRouteText:UITextField?
    var descriptionRouteText: UITextField?
    var saveRouteAlert:UIAlertController?
    let ref = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass =  false
        mapView.mapType = .Standard
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(RouteCreatorViewController.addAnnotation(_:)))
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
        addPin = UIAlertController(title: "Add pin", message: "\n\n\n\n\n", preferredStyle: .Alert)
        let height =  NSLayoutConstraint(item: addPin!.view, attribute: NSLayoutAttribute.Height, relatedBy:NSLayoutRelation.Equal , toItem: nil , attribute: .NotAnAttribute, multiplier: 1.0, constant: 260.0)
        let width =  NSLayoutConstraint(item: addPin!.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 250.0)
        addPin!.view.addConstraints([height,width])
        
        
        let nameTextFrame =  CGRectMake(5.0, 60.0, 240.0, 40.0)
        nameText = UITextField(frame: nameTextFrame)
        nameText?.borderStyle = .None
        nameText?.placeholder = "Enter the name of the location"
        nameText!.delegate = self
        
        let checkPointLabelFrame =  CGRectMake(5.0, 110.0, 240.0, 40.0)
        let checkPointLabel =  UILabel(frame: checkPointLabelFrame)
        checkPointLabel.text = "Is it a check point?"
        
        let checkPointFrame = CGRectMake(5.0, 160.0, 50.0, 40.0)
        checkPoint = UISwitch(frame: checkPointFrame)
        
        
        let cancelButtonFrame =  CGRectMake(5.0, 210.0, 100.0, 40.0)
        let cancelButton = UIButton(frame: cancelButtonFrame)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(RouteCreatorViewController.cancelPin), forControlEvents: .TouchUpInside)
        
        let addButtonFrame =  CGRectMake(170.0, 210.0, 50.0, 40.0)
        let addButton = UIButton(frame: addButtonFrame)
        addButton.setTitle("Add", forState: .Normal)
        addButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        addButton.addTarget(self, action: #selector(RouteCreatorViewController.addNewPin), forControlEvents: .TouchUpInside)
        
        addPin?.view.addSubview(nameText!)
        addPin?.view.addSubview(checkPointLabel)
        addPin?.view.addSubview(checkPoint!)
        addPin?.view.addSubview(cancelButton)
        addPin?.view.addSubview(addButton)
        nameText!.delegate = self
        
        point = sender.locationInView(mapView)
        
        
        self.presentViewController(addPin!, animated:false , completion: nil)
        
        
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        locationManager.startUpdatingLocation()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func cancelPin(){
        addPin!.dismissViewControllerAnimated(true, completion: nil)
    }
    func addNewPin(){
        addPin!.dismissViewControllerAnimated(true, completion: nil)
        let tappedCoordinate =  mapView.convertPoint(point!, toCoordinateFromView: mapView)
        var text = (nameText!).text!
        if text == "" {
            text = "Whitout description"
        }
        let id = NSUUID().UUIDString
        let annotation = SokolAnnotation(coordinate: tappedCoordinate, title:text , subtitle: "This point is the number " + String(annotations.count + 1) , checkPoint: checkPoint!.on,id:id)
        
        
        annotations.append(annotation)
        mapView.showAnnotations(annotations, animated: true)
        
    }
   
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        let annotationView = views[0]
        let endFrame =  annotationView.frame
        annotationView.frame = CGRectOffset(endFrame, 0, -600)
        UIView.animateWithDuration(0.3, animations: { () in
            annotationView.frame = endFrame
        })
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        var annotationView:MKPinAnnotationView? = mapView.dequeueReusableAnnotationViewWithIdentifier("myPin") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            annotationView?.canShowCallout = true
        }
        let checkFrame = CGRectMake(2.0, 5.0, 50.0, 47.0)
        checkPoint = UISwitch(frame: checkFrame)

        if let a = getAnnotation(annotation){
            if a.checkPoint {
                if #available(iOS 9.0, *){
                    annotationView?.pinTintColor = UIColor.greenColor()
                }
                checkPoint?.on = true
                
            }else{
                checkPoint?.on = false
                if #available(iOS 9.0, *){
                    annotationView?.pinTintColor = UIColor.redColor()
                }
            }
        }
        let view:UIView = UIView(frame: CGRectMake(0.0, 0.0, 53.0, 53.0))
        
        view.addSubview(checkPoint!)
        checkPoint?.tag = getPositionAnnotation(annotation)
        checkPoint?.addTarget(self, action: #selector(RouteCreatorViewController.changePin(_:)), forControlEvents: .ValueChanged)
        annotationView?.leftCalloutAccessoryView = view
        let button = UIButton(type: .Custom) as UIButton
        button.frame = CGRectMake(0, 0, 53, 53)
        button.setImage(UIImage(named: "remove"), forState: .Normal)
        button.addTarget(self, action: #selector(RouteCreatorViewController.removePin(_:)), forControlEvents: .TouchUpInside)
        button.tag = getPositionAnnotation(annotation)
        
        annotationView?.rightCalloutAccessoryView = button
        annotationView?.draggable = true
        
        return annotationView
        
    }
    func removePin(sender:UIButton){
        let a = annotations.removeAtIndex(sender.tag)
        mapView.removeAnnotation(a)
        var i = 0
        var annotationsTemp = [SokolAnnotation]()
        for annotation in annotations {
            annotation.subtitle = "This point is the number " + String(i + 1)
            i += 1
            annotationsTemp.append(annotation)
        }
        mapView.removeAnnotations(annotations)

        annotations = []
        for annotation in annotationsTemp{
            annotations.append(annotation)
        }
        
        mapView.showAnnotations(annotations, animated: true)
        if isRouteCalculated{
            calculateRoute(sender)
        }
    }
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            calculateRoute(calculateRoute)
        }
    }
    func changePin(sender:UISwitch){
        let a = annotations.removeAtIndex(sender.tag)
        mapView.removeAnnotation(a)
        let newAnnotation =  SokolAnnotation(coordinate: a.coordinate, title: a.title!, subtitle: a.subtitle!, checkPoint: sender.on,id:a.id!)
        annotations.insert(newAnnotation, atIndex: sender.tag)
        mapView.showAnnotations(annotations, animated: true)
        
    }
    func getAnnotation(annotation:MKAnnotation) -> SokolAnnotation?{
        for a in annotations {
            if a.coordinate.latitude == annotation.coordinate.latitude && a.coordinate.longitude == annotation.coordinate.longitude {
                return a
            }
        }
        return nil
    }
    func getPositionAnnotation(annotation:MKAnnotation) -> Int {
        var i = 0
        for a in annotations {
            if a.coordinate.latitude == annotation.coordinate.latitude && a.coordinate.longitude == annotation.coordinate.longitude {
                return i
            }
            i += 1
        }
        return -1
    }
    
    
    @IBAction func cancel(sender: AnyObject) {
        self.mapView.showsUserLocation = false
        self.dismissViewControllerAnimated(true, completion: nil)
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
    
    @IBAction func calculateRoute(sender: AnyObject) {
        mapView.removeOverlays(mapView.overlays)
        var i = 0
        
        while i < (annotations.count-1) {
            let origin =  String(annotations[i].coordinate.latitude)+","+String(annotations[i].coordinate.longitude)
            let end =  String(annotations[i+1].coordinate.latitude)+","+String(annotations[i+1].coordinate.longitude)
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin="+origin+"&destination="+end+"&key="+Constants.DIRECTION_KEY
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
                            self.isRouteCalculated = true
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                self.drawRoute(jsonResult)
                            
                            })
                        }else{
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
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
    
    
    @IBAction func saveRoute(sender: AnyObject) {
        if annotations.count >= 2 && isRouteCalculated {
            //Here we should save the route
            saveRouteAlert = UIAlertController(title: "Save Route", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height = NSLayoutConstraint(item: saveRouteAlert!.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 210.0)
            let width = NSLayoutConstraint(item: saveRouteAlert!.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 250.0)
            saveRouteAlert!.view.addConstraints([height,width])
            
            let nameRouteFrame = CGRectMake(5.0, 40.0, 240.0, 50.0)
            nameRouteText =  UITextField(frame: nameRouteFrame)
            nameRouteText?.borderStyle = .None
            nameRouteText?.placeholder = "Enter the name of the route"
            nameRouteText?.delegate = self
            
            let descriptionRouteFrame = CGRectMake(5.0, 100.0, 240.0, 50.0)
            descriptionRouteText = UITextField(frame: descriptionRouteFrame)
            descriptionRouteText?.borderStyle = .None
            descriptionRouteText?.placeholder = "Enter the description of the route"
            descriptionRouteText?.delegate = self
            
            let cancelButtonFrame = CGRectMake(5.0, 160.0, 100.0, 40.0)
            let cancelButton = UIButton(frame: cancelButtonFrame)
            cancelButton.setTitle("Cancel", forState: .Normal)
            cancelButton.setTitleColor(UIColor.blueColor(),forState: .Normal)
            cancelButton.addTarget(self, action: #selector(RouteCreatorViewController.cancelSaveRoute(_:)), forControlEvents: .TouchUpInside)
            
            let saveButtonFrame = CGRectMake(145.0, 160.0, 100.0, 40.0)
            let saveButton =  UIButton(frame: saveButtonFrame)
            saveButton.setTitle("Save", forState: .Normal)
            saveButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            saveButton.addTarget(self, action: #selector(RouteCreatorViewController.saveRouteFirebase(_:)), forControlEvents: .TouchUpInside)
            
            saveRouteAlert?.view.addSubview(nameRouteText!)
            saveRouteAlert?.view.addSubview(descriptionRouteText!)
            saveRouteAlert?.view.addSubview(cancelButton)
            saveRouteAlert?.view.addSubview(saveButton)
            
            self.presentViewController(saveRouteAlert!, animated: true, completion: nil)
            
        }else{
            self.presentViewController(Utilities.alertMessage("Error", message: "The route has to have minimum 2 points, yuo also have to calculate the route first"), animated: false, completion: nil)
        }
    }
    func cancelSaveRoute(sender:UIButton){
        saveRouteAlert!.dismissViewControllerAnimated(false, completion: nil)
    }
    func saveRouteFirebase(sender:UIButton){
        saveRouteAlert?.dismissViewControllerAnimated(false, completion: nil)
        //TODO 
        //We should the route to firebase
        let nameRoute = nameRouteText?.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        let descriptionRoute = descriptionRouteText?.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if nameRoute?.characters.count <= 3 || descriptionRoute?.characters.count <= 3 {
            self.presentViewController(Utilities.alertMessage("Error", message: "The name and the description are mandatory, this fields should be at least 4 characters"), animated: true, completion: nil)
        }
        else{
            let route = ref.child("routes")
            
            
            let routeId = route.childByAutoId()
        
            var lats:[String] = []
            var lngs:[String] = []
            var checks:[Bool] = []
            var pointNames:[String] = []
            var ids:[String] = []
            
            for a in annotations {
                lats.append(String(a.coordinate.latitude))
                lngs.append(String(a.coordinate.longitude))
                checks.append(a.checkPoint)
                pointNames.append((a.title!))
                ids.append(a.id!)
            }
            
            
            let values = ["name":nameRoute!,
                "description":descriptionRoute!,
                "latitudes":lats,
                "longitudes":lngs,
                "checkPoints":checks,
                "pointNames":pointNames,
                "ids":ids,
                "userID":FIRAuth.auth()!.currentUser!.uid
            ]
        
            routeId.setValue(values)
            
            let userByRoute = ref.child("userByRoutes")
            let userByRouteID = userByRoute.child(FIRAuth.auth()!.currentUser!.uid)
            let careRoutes = self.ref.child("careRoutesByUser")
            
                if let user = FIRAuth.auth()?.currentUser{
                    let careRoutesUser = careRoutes.child(user.uid)
                    careRoutesUser.observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                        if !(snapshot.value is NSNull){
                            let values = snapshot.value as! NSDictionary
                            var routesIds = values["routes"] as! [String]
                            routesIds.append(routeId.key)
                            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                                careRoutesUser.updateChildValues(["routes":routesIds])
                            })
                        }else{
                            NSOperationQueue.mainQueue().addOperationWithBlock({() in
                                careRoutesUser.updateChildValues(["routes":[routeId.key]])
                            })
                        }
                    })
                }
                FIRMessaging.messaging().subscribeToTopic("/topics/"+routeId.key)
            
            
            userByRouteID.observeSingleEventOfType(.Value, withBlock: {snapshot in
                if snapshot.value is NSNull{
                    var otherValues = [String]()
                    otherValues.append(routeId.key)
                    userByRouteID.setValue(["routes":otherValues])
                }else{
                    let routesValues =  snapshot.value as! NSDictionary
                    var routes = routesValues["routes"] as! [String]
                    
                    routes.append(routeId.key)
                    userByRouteID.updateChildValues(["routes":routes])
                }
            })
            
            self.mapView.showsUserLocation = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 15
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
    

}
