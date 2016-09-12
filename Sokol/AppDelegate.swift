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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate,CLLocationManagerDelegate {
    
    var window: UIWindow?
    let locationMannager = CLLocationManager()
    
    
    override init() {
        // Firebase Init
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
        locationMannager.delegate = self
        locationMannager.requestAlwaysAuthorization()
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge,.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
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
        let information = userInfo["aps"] as! NSDictionary
        dispatch_async(dispatch_get_main_queue(), {
            UIApplication.sharedApplication().keyWindow?.rootViewController!.presentViewController(Utilities.alertMessage("Notification", message: "Hola"), animated: true, completion: nil)
            return
            
        })
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
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
        connectToFCM()
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
            
            dispatch_async(dispatch_get_main_queue(), {
                UIApplication.sharedApplication().keyWindow?.rootViewController!.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                return
                
            })

        
        }
        
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                     accessToken: authentication.accessToken)
        if Utilities.linking == false {
            
            FIRAuth.auth()?.signInWithCredential(credential, completion:{(user,error) in
            //Here we need to save the data about the user
                if error != nil {
                    self.window?.rootViewController?.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                }else{
                    let ref = FIRDatabase.database().reference()
                //ref.removeAllObservers()
                    
                    Utilities.user = user
                
                    Utilities.provider = "google.com"

                    //let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")

                    let userRef = ref.child("users")
                    let userIdRef = userRef.child((user?.uid)!)
                    userIdRef.observeEventType(.Value, withBlock: {snapshot in
                        if snapshot.value is NSNull{
                            userIdRef.setValue(["login":"google.com"])
                        }
                        
                    })
                    //userIdRef.removeAllObservers()
                    //self.window?.rootViewController?.presentViewController(viewController, animated: true, completion: nil)
                }
            })
        }else{
            
            FIRAuth.auth()?.currentUser?.linkWithCredential(credential, completion: {(user, error) in
                if error != nil {
                   self.window?.rootViewController?.presentViewController(Utilities.alertMessage("error", message:"There was an error"), animated: false, completion: nil)
                }else{
                    Utilities.user = user
                    Utilities.button!.hidden = true
                }
                
            })
        }
    }
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let r =  region as? CLCircularRegion{
            if UIApplication.sharedApplication().applicationState == .Active{
                dispatch_async(dispatch_get_main_queue(), {
                    UIApplication.sharedApplication().keyWindow?.rootViewController!.presentViewController(Utilities.alertMessage("Checkpoint", message: "You have just crossed for a checkpoint"), animated: true, completion: nil)
                    return
                    
                })
                
            }else{
                let geofence = r as! Geofence
                let notification = UILocalNotification()
                notification.alertTitle = "You are coressed for the checkpoint"
                let text = geofence.sokolAnnotation.title! == "Without description" ? "without title":"with the title: \(geofence.sokolAnnotation.title!)"
                let time = NSDate()
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
                notification.alertBody = "\(geofence.sokolAnnotation.subtitle), \(text)\n\(dateFormatter.stringFromDate(time))"
                notification.soundName = "Default"
                UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            }
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
    



}

