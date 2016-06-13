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
    var emailText:UITextField?
    var passwordText:UITextField?
    var loginWithSokol:UIAlertController?
    var passwordRecovery:UIAlertController?
    
    let ref = Firebase(url:"sokolunal.firebaseio.com")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logIn(sender:UIButton){
        switch sender.tag {
        case 0,
             3:
            print ("Login with sokol")
            loginWithSokol = UIAlertController(title: "Log in", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: loginWithSokol!.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 250.0)
            loginWithSokol!.view.addConstraint(height)
           
            let emailTextFrame:CGRect =  CGRectMake(5.0, 40.0, 250.0, 40.0)
            emailText = UITextField(frame: emailTextFrame)
            emailText!.placeholder = "Enter your emial"
            emailText!.autocapitalizationType = .None
            //emailText!.borderStyle = .Bezel
            
            let passwordTextFrame:CGRect = CGRectMake(5.0, 90.0, 250.0, 40.0)
            passwordText = UITextField(frame: passwordTextFrame)
            passwordText!.secureTextEntry = true
            passwordText!.placeholder = "Enter your password"
            passwordText!.autocapitalizationType = .None
            //passwordText!.borderStyle = .Line
            
            let forgetPasswordFrame:CGRect = CGRectMake(70.0, 140.0, 200.0, 40.0)
            let forgetPassword = UIButton(frame: forgetPasswordFrame)
            forgetPassword.setTitle("Forget your password?", forState: .Normal)
            forgetPassword.setTitleColor(UIColor.blueColor(), forState: .Normal)
            forgetPassword.addTarget(self, action: "passwordForgotten", forControlEvents: .TouchUpInside)
            
            let buttonsFrame:CGRect = CGRectMake(5.0, 180.0, 250.0, 60.0)
            let buttonsView:UIView = UIView(frame: buttonsFrame)
            
            let cancelFrame:CGRect = CGRectMake(50.0, 10.0, 100.0, 40.0)
            let cancelButton:UIButton = UIButton(frame: cancelFrame)
            cancelButton.setTitle("Cancel", forState: .Normal)
            cancelButton.setTitleColor(UIColor.blueColor(),forState: .Normal)
            cancelButton.addTarget(self, action: "cancelLogin", forControlEvents: .TouchUpInside)
            
            let loginFrame:CGRect = CGRectMake(170.0, 10.0, 100.0, 40.0)
            let loginButton:UIButton =  UIButton(frame: loginFrame)
            loginButton.setTitle("Log in", forState: .Normal)
            loginButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            loginButton.addTarget(self, action: "loginSokol", forControlEvents: .TouchUpInside)
            
            
            buttonsView.addSubview(cancelButton)
            buttonsView.addSubview(loginButton)
            
            loginWithSokol!.view.addSubview(emailText!)
            loginWithSokol!.view.addSubview(passwordText!)
            loginWithSokol!.view.addSubview(forgetPassword)
            loginWithSokol!.view.addSubview(buttonsView)
            
            
            presentViewController(loginWithSokol!, animated: true, completion: nil)
                        
        case 1:
            print ("Login with facebook")
        case 2:
            print ("Login with twitter")
        default:
            print ("We don't support this opertation")
        }
    }
    @IBAction func unwindToHomeScreen(segue:UIStoryboardSegue) {
        
    }
    func passwordForgotten() {
        loginWithSokol?.dismissViewControllerAnimated(true, completion: nil)
        passwordRecovery = UIAlertController(title: "Password recovery", message: nil, preferredStyle:.Alert)
        let height:NSLayoutConstraint = NSLayoutConstraint(item: passwordRecovery!.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 150)
        passwordRecovery!.view.addConstraint(height)
        let emailTextFrame:CGRect =  CGRectMake(5.0, 40.0, 250.0, 40.0)
        emailText = UITextField(frame: emailTextFrame)
        emailText!.placeholder = "Enter your emial"
        emailText!.autocapitalizationType = .None
        
        let sendButtonFrame:CGRect =  CGRectMake(5.0, 90, 250.0, 40.0)
        let sendButton:UIButton = UIButton(frame: sendButtonFrame)
        sendButton.setTitle("Recover", forState: .Normal)
        sendButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        sendButton.titleLabel?.textAlignment = .Center
        sendButton.addTarget(self, action: "sendPassword", forControlEvents: .TouchUpInside)
        passwordRecovery!.view.addSubview(emailText!)
        passwordRecovery!.view.addSubview(sendButton)
        presentViewController(passwordRecovery!, animated: true, completion: nil)
        
    }
    func sendPassword(){
        passwordRecovery!.dismissViewControllerAnimated(true, completion: nil)
        //print("\(emailText?.text)")
        ref.resetPasswordForUser(emailText?.text, withCompletionBlock: { error in
            if error != nil {
               let errorMessage = UIAlertController(title: "Error", message: "There was an error we couldn't send you the recovery password", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                errorMessage.addAction(okAction)
                self.presentViewController(errorMessage, animated: true, completion: nil)
            }else{
                let successMessage = UIAlertController(title: "Success", message: "We sent the recovery password to the email provided", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                successMessage.addAction(okAction)
                self.presentViewController(successMessage, animated: true, completion: nil)
            }
        })
    }
    func cancelLogin(){
        loginWithSokol?.dismissViewControllerAnimated(true, completion: nil)
    }
    func loginSokol(){
        loginWithSokol?.dismissViewControllerAnimated(true, completion: nil)
        ref.authUser(emailText?.text, password: passwordText?.text,  withCompletionBlock: { error, authData in
            if error != nil {
                let errorMessage = UIAlertController(title: "Error", message: "There was an error", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                errorMessage.addAction(okAction)
                self.presentViewController(errorMessage, animated: true, completion: nil)
            }else{
                let successMessage = UIAlertController(title: "Success", message: "The login was succesful", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                successMessage.addAction(okAction)
                self.presentViewController(successMessage, animated: true, completion: nil)
                //TODO: We should redirect to other view throough a segue
            }
            
        })
        
    }
    
}

