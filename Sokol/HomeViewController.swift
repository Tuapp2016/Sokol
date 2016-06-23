//
//  HomeViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    //let ref = Firebase(url:"sokolunal.firebaseio.com")
    let ref = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        FIRAuth.auth()?.addAuthStateDidChangeListener({(auth,user) in
            if user == nil {
                let userRef = self.ref.child("users")
                if let uid = Utilities.user?.uid{
                    let userId =  userRef.child(uid)
                    userId.removeAllObservers()
                }
                Utilities.user = nil
                self.dismissViewControllerAnimated(true, completion: {})
            }
        })
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabRoutes", name: "switchTabRoutes", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchTabProfile", name: "switchTabProfile", object: nil)


        // Do any additional setup after loading the view.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
