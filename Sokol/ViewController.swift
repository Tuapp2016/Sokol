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
import Fabric
import TwitterKit

class ViewController: UIViewController,GIDSignInUIDelegate{
    
    @IBOutlet weak var signInButtonGoogle: GIDSignInButton!
    @IBOutlet weak var signInButtonFacebook:UIButton!
    @IBOutlet weak var signInButtonSokol:UIButton!
    @IBOutlet weak var signInButtonTwitter:UIView!
    
    
    var emailText:UITextField?
    var passwordText:UITextField?
    var loginWithSokol:UIAlertController?
    var passwordRecovery:UIAlertController?
    var blurEffectView:UIVisualEffectView?
    
    let ref = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        FIRAuth.auth()?.addAuthStateDidChangeListener({ auth,user in
            if let user = user {
                let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                Utilities.user = user
                self.presentViewController(viewController, animated: true, completion: nil)
            } else {
                //print("hola")
                let facebookLogin = FBSDKLoginManager()
                facebookLogin.logOut()
                if let userId = Twitter.sharedInstance().sessionStore.session()?.userID {
                    Twitter.sharedInstance().sessionStore.logOutUserID(userId)
                }
                GIDSignIn.sharedInstance().signOut()
                
            }
        })
        

        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let loginButton = TWTRLogInButton(logInCompletion: {session, error in
            if session != nil {
                let authToken = session?.authToken
                let authTokenSecret = session?.authTokenSecret
                let credential = FIRTwitterAuthProvider.credentialWithToken(authToken!, secret: authTokenSecret!)
                FIRAuth.auth()?.signInWithCredential(credential, completion:{(user, error) in
                    if error != nil {
                        self.presentViewController(Utilities.alertMessage("Error", message: (error?.description)!), animated: true, completion: nil)
                    }else{
                        //self.ref.removeAllObservers()
                        for profile in (user?.providerData)!{
                            let uid = profile.uid
                            var name = profile.displayName
                            if name == nil{
                                name = "There is no  name"
                            }
                            var email = profile.email
                            if email == nil{
                                email = "There is no an email"
                            }
                            let photoURL = (profile.photoURL!).absoluteString
                            let userRef = self.ref.child("users")
                            let userIdRef = userRef.child((user?.uid)!)
                            let newUser = ["provider": profile.providerID,"name": name!,"email":email!,"profileImage":photoURL]
                            userIdRef.setValue(newUser)
                            
                        }
                        
                        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                        if Utilities.user == nil {
                            Utilities.user = user
                        }
                        self.presentViewController(viewController, animated: true, completion: nil)
                        
                        
                    }
                })
                
            }else{
                self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                
            }
            
        })
        
        loginButton.frame = CGRect(x: signInButtonTwitter.frame.origin.x, y: signInButtonTwitter.frame.origin.y-55, width: signInButtonTwitter.frame.width, height: signInButtonTwitter.frame.height)
        FIRAuth.auth()?.addAuthStateDidChangeListener({auth,user in
            if let user = user {
                self.ref.removeAllObservers()
                Utilities.user = user
                let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                
                //Utilities.authData = authData
                self.presentViewController(viewController, animated: true, completion: nil)
            }
        })
        signInButtonTwitter.addSubview(loginButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logIn(sender:AnyObject){
        switch sender.tag {
        case 0:
            print ("Login with sokol")
            let blurEffect = UIBlurEffect(style: .Dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = view.bounds
            blurEffectView?.tag = 10
            loginWithSokol = UIAlertController(title: "Log in", message: "\n\n\n\n\n", preferredStyle: .Alert)
            let height:NSLayoutConstraint = NSLayoutConstraint(item: loginWithSokol!.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 250.0)
            loginWithSokol!.view.addConstraint(height)
           
            let emailTextFrame:CGRect =  CGRectMake(5.0, 40.0, 250.0, 40.0)
            emailText = UITextField(frame: emailTextFrame)
            emailText!.placeholder = "Enter your emial"
            emailText!.autocapitalizationType = .None
            emailText!.keyboardType = .EmailAddress
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
            self.view.addSubview(blurEffectView!)
                        
        case 2:
            let facebookLogin = FBSDKLoginManager()
            facebookLogin.logOut()
            //facebookLogin.loginBehavior = .Web
            facebookLogin.logInWithReadPermissions(["email","public_profile","user_friends"], fromViewController: self, handler: {
                (facebookResult, facebookError) -> Void in
                if facebookError != nil {
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                }else if facebookResult.isCancelled {
                    self.presentViewController(Utilities.alertMessage("Error", message: facebookResult.debugDescription), animated: true, completion: nil)
                }else{
                    let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                    FIRAuth.auth()?.signInWithCredential(credential, completion: {(user,error) in
                        if error != nil {
                            self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                        }else{
                            self.ref.removeAllObservers()
                            for profile in (user?.providerData)!{
                                let uid = profile.uid
                                var name = profile.displayName
                                if name == nil{
                                    name = "There is no  name"
                                }
                                var email = profile.email
                                if email == nil{
                                    email = "There is no an email"
                                }
                                let photoURL = (profile.photoURL!).absoluteString
                                let userRef = self.ref.child("users")
                                let userIdRef = userRef.child((user?.uid)!)
                                let newUser = ["provider": profile.providerID,"name": name!,"email":email!,"profileImage":photoURL]
                                userIdRef.setValue(newUser)
                                
                            }

                            if Utilities.user == nil {
                                Utilities.user = user
                            }
                            
                        }
                    })
                    
                }
            })
            
            
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
        emailText!.keyboardType = .EmailAddress

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
        FIRAuth.auth()?.sendPasswordResetWithEmail((emailText?.text)!, completion: {error in
            if error != nil {
                self.presentViewController(Utilities.alertMessage("Error", message: "There was an error we couldn't send you the recovery password"), animated: true, completion: nil)
            }else{
                self.presentViewController(Utilities.alertMessage("Success", message: "We sent the recovery password to the email provided"), animated: true, completion: nil)
            }
        })
 
        removeBlurEffect()
    }
    func cancelLogin(){
        loginWithSokol?.dismissViewControllerAnimated(true, completion: nil)
        removeBlurEffect()
    }
    func loginSokol(){
        loginWithSokol?.dismissViewControllerAnimated(true, completion: nil)
        removeBlurEffect()
        FIRAuth.auth()?.signInWithEmail((emailText?.text)!, password: (passwordText?.text)!, completion: {(user:FIRUser?,error) in
            if error != nil {
                self.presentViewController(Utilities.alertMessage("Error", message: (error?.description)!), animated: true, completion: nil)
            }else{
                //self.ref.removeAllObservers()
                let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                Utilities.user = user
                self.presentViewController(viewController, animated: true, completion: nil)
            }
        })
        
        
    }
    func removeBlurEffect(){
        self.view.subviews.forEach({
            temp in
            if temp.tag == 10 {
                temp.removeFromSuperview()
            }
        })
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        blurEffectView?.frame = view.bounds
    }
    
    
    
}

