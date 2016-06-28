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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate {
    
    var window: UIWindow?
    override init() {
        // Firebase Init
        FIRApp.configure()
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
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
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
        self.window?.rootViewController?.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
            return
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
                    if Utilities.user == nil {
                        Utilities.user = user
                        
                    }
                    Utilities.provider = "google.com"

                    //let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")

                    let userRef = ref.child("users")
                    let userIdRef = userRef.child((user?.uid)!)
                    userIdRef.observeEventType(.Value, withBlock: {snapshot in
                        if snapshot.value is NSNull{
                            userIdRef.setValue(["login":""])
                        }
                        
                    })
                    //self.window?.rootViewController?.presentViewController(viewController, animated: true, completion: nil)
                }
            })
        }else{
            
            FIRAuth.auth()?.currentUser?.linkWithCredential(credential, completion: {(user, error) in
                if error != nil {
                   self.window?.rootViewController?.presentViewController(Utilities.alertMessage("error", message:(error?.description)!), animated: false, completion: nil)
                }else{
                    Utilities.button!.hidden = true
                }
                
            })
        }
    }



}

