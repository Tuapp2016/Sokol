//
//  HomeViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit

class HomeViewController: UIViewController {
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    let ref = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        if (Utilities.provider == nil || Utilities.user == nil) {
            let userRef = self.ref.child("users")
            if let uid = Utilities.user?.uid{
                let userId =  userRef.child(uid)
                userId.removeAllObservers()
            }
            Utilities.user = nil
            Utilities.linking = false
            Utilities.provider = nil
            try! FIRAuth.auth()?.signOut()
            self.dismissViewControllerAnimated(true, completion: {})
        }
        NSNotificationCenter.defaultCenter().addObserver(self,selector: "switchTabRoutes", name: "switchTabRoutes", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabProfile", name: "switchTabProfile", object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
   
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func switchTabProfile(){
        tabBarController?.selectedIndex = 1
        
    }
    func switchTabRoutes() {
        tabBarController?.selectedIndex = 0
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func toggleMenu(sender:AnyObject){
        NSNotificationCenter.defaultCenter().postNotificationName("toggleMenu",object:nil)
    }
    

}
