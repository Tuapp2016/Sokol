//
//  AppDelegate.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 03/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit
import Fabric
import TwitterKit
import CoreLocation
import ReachabilitySwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate,CLLocationManagerDelegate {
    
    var window: UIWindow?
    var reachability: Reachability?
    let locationManager = CLLocationManager()
    
    
    override init() {
        // Firebase Init
        super.init()
        if #available(iOS 10, *){
            let authOptions : UNAuthorizationOptions = [.Alert, .Badge, .Sound]
            UNUserNotificationCenter.currentNotificationCenter().requestAuthorizationWithOptions(
                authOptions,
                completionHandler: {_,_ in })
            UNUserNotificationCenter.currentNotificationCenter().delegate = self
            FIRMessaging.messaging().remoteMessageDelegate = self
        }else{
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge,.Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            
            
        }

        UIApplication.sharedApplication().registerForRemoteNotifications()
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        let ref = FIRDatabase.database().reference()
        let userRef = ref.child("users")
        userRef.keepSynced(true)
        let routesRef = ref.child("routes")
        routesRef.keepSynced(true)
        let userByRoutesRef = ref.child("userByRoutes")
        userByRoutesRef.keepSynced(true)
        let followRoutes = ref.child("followRoutesByUser")
        followRoutes.keepSynced(true)
    }
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        do{
            reachability = try Reachability.reachabilityForInternetConnection()
        }catch {
            print("Unable to create Reachibility")
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
        do{
            try reachability?.startNotifier()
        }catch{
            print("Could not start reachability notifier")
        }
        UINavigationBar.appearance().barTintColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        if let barFont = UIFont(name: "Avenir-Light", size: 24){
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor(), NSFontAttributeName:barFont]
            
        }
        UITabBar.appearance().tintColor = UIColor(red: 22.0/255.0, green: 109.0/255.0, blue: 186.0/255.0, alpha: 1.0)
        UITabBar.appearance().barTintColor = UIColor.blackColor()
        //FIRApp.configure()
        // Override point for customization after application launch.
        NSThread.sleepForTimeInterval(2)
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        Twitter.sharedInstance().startWithConsumerKey(Constants.TWITTER_KEY, consumerSecret: Constants.TWITTER_SECRET_KEY)
        Fabric.with([Twitter.self])
        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.activityType = .AutomotiveNavigation
        }
        

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.tokenRefreshNotification),
                                                         name: kFIRInstanceIDTokenRefreshNotification, object: nil)
        
        return FBSDKApplicationDelegate.sharedInstance().application(application,didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication,
                     openURL url: NSURL,
                             sourceApplication: String?,
                             annotation: AnyObject) -> Bool {
        
        var options: [String: AnyObject] = [UIApplicationOpenURLOptionsSourceApplicationKey: sourceApplication!,UIApplicationOpenURLOptionsAnnotationKey: annotation]
        if Twitter.sharedInstance().application(application, openURL:url, options: options){
            return true
        }
        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            openURL: url,
            sourceApplication: sourceApplication,
            annotation: annotation) ||  GIDSignIn.sharedInstance().handleURL(url,sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String,annotation: options[UIApplicationOpenURLOptionsAnnotationKey])
    }
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        let information = userInfo["aps"] as! NSDictionary
        
        let alert = information["alert"] as! NSDictionary
        showAlert( alert["title"] as! String, message: alert["body"] as! String)
        print(userInfo)
        
    }
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Sandbox)
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(SmallCache.sharedInstance, toFile: cacheURL().path!)
        if !isSuccessfulSave {
            print("Failed to save meals...")
        }
        if #available(iOS 10, *){
            let content = UNMutableNotificationContent()
            content.title = "Reminder"
            content.subtitle = "We miss you"
            content.body = "You can check the state of your routes or create, update and absolutely register in new ones. \n If you are interested in knowing where your loved ones are, please come and visit our app."
            content.sound = UNNotificationSound.defaultSound()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24*60*60*5, repeats: true)
            let request = UNNotificationRequest(identifier: Constants.SOKOL_NOTIFICATION_REMINDER, content: content, trigger: trigger)
            UNUserNotificationCenter.currentNotificationCenter().addNotificationRequest(request, withCompletionHandler: nil)
            
        }
        
        
    
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
        connectToFCM()
        if let cache = NSKeyedUnarchiver.unarchiveObjectWithFile(cacheURL().path!) as? SmallCache{
            SmallCache.sharedInstance.cacheOperations = cache.cacheOperations
        }
        if #available(iOS 10, *){
            UNUserNotificationCenter.currentNotificationCenter().removePendingNotificationRequestsWithIdentifiers([Constants.SOKOL_NOTIFICATION_REMINDER])
        }
    }
   
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        signIn.signOut()
    }
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
                withError error: NSError!) {
        if let error = error {
            self.showAlert("Error", message: "There was an error")
        }
        
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                     accessToken: authentication.accessToken)
        if Utilities.linking == false {
            
            FIRAuth.auth()?.signInWithCredential(credential, completion:{(user,error) in
            //Here we need to save the data about the user
                if error != nil {
                    self.showAlert("Error", message: "There was an error when we tried to make the log in")
                    
                }else{
                    let ref = FIRDatabase.database().reference()
                    //ref.removeAllObservers()
                    Utilities.user = user
                
                    Utilities.provider = "google.com"

                    

                    let userRef = ref.child("users")
                    let userIdRef = userRef.child((user?.uid)!)
                    userIdRef.observeEventType(.Value, withBlock: {snapshot in
                        if snapshot.value is NSNull{
                            userIdRef.setValue(["login":"google.com"])
                        }
                        
                    })
                    
                }
            })
        }else{
            
            FIRAuth.auth()?.currentUser?.linkWithCredential(credential, completion: {(user, error) in
                if error != nil {
                    self.showAlert("Error", message: "There was an error when we tried to link your account")
                   
                }else{
                    Utilities.user = user
                    Utilities.button!.hidden = true
                }
                
            })
        }
    }
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let r =  region as? CLCircularRegion{
            let dateFormater = NSDateFormatter()
            dateFormater.dateFormat = "yyyy-MM-dd, HH:mm:ss"
            dateFormater.timeZone = NSTimeZone(name: "COT")
            let str = dateFormater.stringFromDate(NSDate())
            //let geofence = r as! Geofence
            let ids = r.identifier.componentsSeparatedByString("SOKOL")
            if reachability?.currentReachabilityStatus == .ReachableViaWiFi || reachability?.currentReachabilityStatus == .ReachableViaWWAN {
                let strategy:SendTopic = SendTopic()
                let sendMessageClient:SendMessageClient = SendMessageClient(strategy: strategy)
                sendMessageClient.sendMessage("the route with id: \(ids[1]) just crossed for a checkpoint with id: \(ids[0]) at \(str)", title: "Notification checkpoint", id: ids[1], page: nil)
            }else{
                SmallCache.sharedInstance.cacheOperations[NSUUID().UUIDString] = ["title":"Notification checkpoint","body":"The route  with id: \(ids[1]) just crossed for a checkpoint with id: \(ids[0]) at \(str)","id":ids[1],"time":str]
            }
            if UIApplication.sharedApplication().applicationState == .Active{
                showAlert("Checkpoint", message: "You have just coressed for a checkpoint")
                
            }else{
                if #available(iOS 10.0, *) {
                    let content = UNMutableNotificationContent()
                    content.title = "Checkpoint"
                    content.subtitle = "Route: \(ids[1])"
                    content.body = "You have just crossed for the checkpoint with id: \(ids[0])"
                    content.sound = UNNotificationSound.defaultSound()
                    let request = UNNotificationRequest(identifier: Constants.SOKOL_NOTIFICATION_CHECKPOINT, content: content, trigger: nil)
                    UNUserNotificationCenter.currentNotificationCenter().addNotificationRequest(request, withCompletionHandler: nil)
                } else {
                    let notification = UILocalNotification()
                    notification.alertTitle = "Checkpoint"
                    
                    let dateFormater = NSDateFormatter()
                    dateFormater.dateFormat = "yyyy-MM-dd, HH:mm:ss"
                    dateFormater.timeZone = NSTimeZone(name: "COT")
                    let str = dateFormater.stringFromDate(NSDate())
                    notification.alertBody = "You have just crossed for the checkpoint with id: \(ids[0]) in the route \(ids[1]) at \(str)"
                    notification.soundName = "Default"
                    UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                }
                
               
            }
        }else{
            showAlert("Checkpoint", message: "There was an error with the chekcpoint")
        }
        
        
    
    }
    func reachabilityChanged(note:NSNotification){
        let reachability = note.object as! Reachability
        if reachability.isReachable() {
            let strategy:SendTopic = SendTopic()
            let strategyRegister:RegisterToken = RegisterToken()
            let sendMessageClient:SendMessageClient = SendMessageClient(strategy: strategy)
            for (key,value) in SmallCache.sharedInstance.cacheOperations{
                let myValue = value as? [String:String]
                switch key as! String {
                case "token":
                    sendMessageClient.strategy = strategyRegister
                    sendMessageClient.sendMessage(myValue!["token"]!, title:"Register token" , id: nil, page:nil )
                default:
                    sendMessageClient.strategy = strategy
                    sendMessageClient.sendMessage(myValue!["body"]!, title: myValue!["title"]!, id: myValue!["id"], page: nil)
                }
                
            }
            SmallCache.sharedInstance.cacheOperations = [:]
            

        }else{
            print("Network not reachable")
        }
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        
    }
    func tokenRefreshNotification(notification: NSNotification){
        if let refresedToken = FIRInstanceID.instanceID().token() {
            print("Instance ID \(refresedToken)")
        }
        connectToFCM()
    }
    func connectToFCM(){
        FIRMessaging.messaging().connectWithCompletion{ (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)" )
            }else{
                print("Connected to FCM.")
            }
            
        }
    }
    func cacheURL() -> NSURL{
        let documentDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return documentDirectory.URLByAppendingPathComponent("sokol")!
    }
    

}
extension AppDelegate{
    func showAlert(title:String,message:String){
        dispatch_async(dispatch_get_main_queue(), {
                       let topWindow: UIWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
            topWindow.rootViewController = UIViewController()
            topWindow.windowLevel = UIWindowLevelAlert + 1
            let alertController =  UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okAcion = UIAlertAction(title: "OK", style: .Cancel, handler: {(action) -> Void in
                topWindow.hidden = true
            })
            alertController.addAction(okAcion)
            topWindow.makeKeyAndVisible()
            topWindow.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            
        })

    }
}
@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate{
    func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        print("%@", userInfo)
    }
    
}
extension AppDelegate: FIRMessagingDelegate{
    func applicationReceivedRemoteMessage(remoteMessage: FIRMessagingRemoteMessage) {
        let userInfo = remoteMessage.appData
        let information = userInfo["notification"] as! NSDictionary
        showAlert( information["title"] as! String, message: information["body"] as! String)
        print(userInfo)
    }
}

