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

class RouteCreatorViewController: UIViewController, CLLocationManagerDelegate,MKMapViewDelegate,UITextFieldDelegate{
    @IBOutlet var mapView:MKMapView!
    var annotations = [SokolAnnotation]()
    var locationManager = CLLocationManager()
    var nameText: UITextField? = UITextField()
    var checkPoint:UISwitch?
    var addPin:UIAlertController?
    var point:CGPoint?
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsScale = true
        mapView.showsCompass =  false
        mapView.mapType = .Standard
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
        }
        
        // Do any additional setup after loading the view.
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
        
        
        let checkPointLabelFrame =  CGRectMake(5.0, 110.0, 240.0, 40.0)
        let checkPointLabel =  UILabel(frame: checkPointLabelFrame)
        checkPointLabel.text = "Is it a check point?"
        
        let checkPointFrame = CGRectMake(5.0, 160.0, 50.0, 40.0)
        checkPoint = UISwitch(frame: checkPointFrame)
        
        
        let cancelButtonFrame =  CGRectMake(5.0, 210.0, 100.0, 40.0)
        let cancelButton = UIButton(frame: cancelButtonFrame)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cancelButton.addTarget(self, action: "cancelPin", forControlEvents: .TouchUpInside)
        
        let addButtonFrame =  CGRectMake(170.0, 210.0, 50.0, 40.0)
        let addButton = UIButton(frame: addButtonFrame)
        addButton.setTitle("Add", forState: .Normal)
        addButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        addButton.addTarget(self, action: "addNewPin", forControlEvents: .TouchUpInside)
        
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
        let annotation = SokolAnnotation(coordinate: tappedCoordinate, title:text , subtitle: "This point is the number " + String(annotations.count + 1) , checkPoint: checkPoint!.on)
        
        
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
        checkPoint?.addTarget(self, action: "changePin:", forControlEvents: .ValueChanged)
        annotationView?.leftCalloutAccessoryView = view
        
        return annotationView
        
    }
    func changePin(sender:UISwitch){
        let a = annotations.removeAtIndex(sender.tag)
        mapView.removeAnnotation(a)
        let newAnnotation =  SokolAnnotation(coordinate: a.coordinate, title: a.title!, subtitle: a.subtitle!, checkPoint: sender.on)
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
        /*let legs =  route["legs"] as! [AnyObject]
        let leg = legs[0] as! NSDictionary
        let steps = leg["steps"] as! [AnyObject]
        for step in steps {
            let endLocation = step["end_location"] as! NSDictionary
            let startLocation = step["start_location"] as! NSDictionary
            let startLat = startLocation["lat"] as! Double
            let startLng = startLocation["lng"] as! Double
            let endLat = endLocation["lat"] as! Double
            let endLng =  endLocation["lng"] as! Double
            
            coordinates.append(CLLocationCoordinate2D(latitude: startLat, longitude: startLng))
            coordinates.append(CLLocationCoordinate2D(latitude: endLat, longitude: endLng))
            
        }*/
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
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.drawRoute(jsonResult)
                            
                        })
                        
                        
                    }catch {
                        print (error)
                    }
                }
            })
            task.resume()
            i += 1
        }
        
        
        
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= 15 // Bool
    }
    

}
