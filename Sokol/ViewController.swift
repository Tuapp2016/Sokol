//
//  ViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 03/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sokol: UIButton!
    @IBOutlet weak var facebook: UIButton!
    @IBOutlet weak var twitter: UIButton!
    
    let ref = Firebase(url:"sokolunal.firebaseio.com")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender:UIButton){
        switch sender.tag {
        case 0:
            print ("Login with sokol")
            let loginWithSokol = UIAlertController(title: "Log in", message: nil, preferredStyle: .Alert)
           
            loginWithSokol.addTextFieldWithConfigurationHandler({
                (textField:UITextField) -> Void in
                textField.placeholder = "Enter your emial"
            })
            loginWithSokol.addTextFieldWithConfigurationHandler({
                (textField:UITextField) -> Void in
                textField.placeholder = "Enter your password"
                textField.secureTextEntry = true
            })
            let loginAction = UIAlertAction(title: "Login", style: .Default, handler: {
                (action:UIAlertAction) ->Void in
                let email = loginWithSokol.textFields![0] as UITextField
                let password  = loginWithSokol.textFields![1] as UITextField
                
                let emailValue = email.text!
                let passwordValue =  password.text!
                
                if emailValue.characters.count>0 && passwordValue.characters.count>0{
                   //We have to authenticate the user
                }
                
            })
            let cancelAction =  UIAlertAction(title: "dismiss", style: .Cancel, handler: nil)
            loginWithSokol.addAction(loginAction)
            loginWithSokol.addAction(cancelAction)
            presentViewController(loginWithSokol, animated: true, completion: nil)
                        
        case 1:
            print ("Login with facebook")
        case 2:
            print ("Login with twitter")
        default:
            print ("We don't support this opertation")
        }
    }

    
}

