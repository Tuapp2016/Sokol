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
        signInButtonFacebook.backgroundColor =  UIColor(red: 59.0/255.0, green: 89.0/255.0, blue: 152.0/255.0, alpha: 1.0)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Utilities.linking =  false
        FIRAuth.auth()?.addAuthStateDidChangeListener{ auth, user in
            let appDelegate  = UIApplication.sharedApplication().delegate as! AppDelegate
            let viewController = appDelegate.window!.rootViewController as? HomeTableViewController
            Utilities.user =  user
            if let user = user{
                if viewController == nil {
                    let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                    if Utilities.provider == nil {
                        Utilities.provider =  FIRAuth.auth()?.currentUser?.providerData[0].providerID
                    }
                    self.presentViewController(viewController, animated: true, completion: nil)
                }
                
            }else{
                if let userId = Twitter.sharedInstance().sessionStore.session()?.userID {
                    Twitter.sharedInstance().sessionStore.logOutUserID(userId)
                }
                GIDSignIn.sharedInstance().signOut()
            }
            
        }
        GIDSignIn.sharedInstance().uiDelegate = self
        let loginButton = TWTRLogInButton(logInCompletion: {session, error in
            if !Utilities.linking{
                if session != nil {
                    let authToken = session?.authToken
                    let authTokenSecret = session?.authTokenSecret
                    let credential = FIRTwitterAuthProvider.credentialWithToken(authToken!, secret: authTokenSecret!)
                    FIRAuth.auth()?.signInWithCredential(credential, completion:{(user, error) in
                        if error != nil {
                            self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                        }else{
                            //let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                            Utilities.provider = "twitter.com"

                            Utilities.user = user
                            let userRef = self.ref.child("users")
                            let userIdRef = userRef.child((user?.uid)!)
                            userIdRef.observeEventType(.Value, withBlock: {snapshot in
                                if snapshot.value is NSNull{
                                    userIdRef.setValue(["login":"twitter.com"])
                                }
                                
                            })
                            //userIdRef.removeAllObservers()
                            //self.presentViewController(viewController, animated: true, completion: nil)
                        }
                    })
                
                }else{
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                
                }
            }
            
        })
        
        loginButton.frame = CGRect(x: signInButtonTwitter.frame.origin.x, y: signInButtonTwitter.frame.origin.y, width: 300, height: 50)
        loginButton.tag = 100
        var isViewAdded = false
        for subview in signInButtonTwitter.subviews{
            if subview.tag == 100{
                isViewAdded = true
            }
        }
        if !isViewAdded{
            signInButtonTwitter.addSubview(loginButton)

        }
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logIn(sender:AnyObject){
        switch sender.tag {
        case 0:
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
            forgetPassword.addTarget(self, action: #selector(ViewController.passwordForgotten), forControlEvents: .TouchUpInside)
            
            let buttonsFrame:CGRect = CGRectMake(5.0, 180.0, 250.0, 60.0)
            let buttonsView:UIView = UIView(frame: buttonsFrame)
            
            let cancelFrame:CGRect = CGRectMake(50.0, 10.0, 100.0, 40.0)
            let cancelButton:UIButton = UIButton(frame: cancelFrame)
            cancelButton.setTitle("Cancel", forState: .Normal)
            cancelButton.setTitleColor(UIColor.blueColor(),forState: .Normal)
            cancelButton.addTarget(self, action: #selector(ViewController.cancelLogin), forControlEvents: .TouchUpInside)
            
            let loginFrame:CGRect = CGRectMake(170.0, 10.0, 100.0, 40.0)
            let loginButton:UIButton =  UIButton(frame: loginFrame)
            loginButton.setTitle("Log in", forState: .Normal)
            loginButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
            loginButton.addTarget(self, action: #selector(ViewController.loginSokol), forControlEvents: .TouchUpInside)
            
            
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
                    self.presentViewController(Utilities.alertMessage("Error", message: "The login was canceled"), animated: true, completion: nil)
                }else{
                    let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                    FIRAuth.auth()?.signInWithCredential(credential, completion: {(user,error) in
                        if error != nil {
                            self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                        }else{
                            //let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("Home")
                            self.ref.removeAllObservers()
                            let userRef = self.ref.child("users")
                            let userIdRef = userRef.child((user?.uid)!)
                            userIdRef.observeEventType(.Value, withBlock: {snapshot in
                                if snapshot.value is NSNull {
                                    userIdRef.setValue(["login":"facebook.com"])
                                }
                                
                            })
                            //userIdRef.removeAllObservers()
                            Utilities.provider = "facebook.com"
                            Utilities.user = user
                            
                            //self.presentViewController(viewController, animated: true, completion: nil)
                            
                        }
                    })
                    
                }
            })
            
            
        default:
            self.presentViewController(Utilities.alertMessage("Error", message: "We don't support this opertation"), animated: true, completion: nil)
        }
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
        sendButton.addTarget(self, action: #selector(ViewController.sendPassword), forControlEvents: .TouchUpInside)
        passwordRecovery!.view.addSubview(emailText!)
        passwordRecovery!.view.addSubview(sendButton)
        presentViewController(passwordRecovery!, animated: true, completion: nil)
        
    }
    func sendPassword(){
        passwordRecovery!.dismissViewControllerAnimated(true, completion: nil)
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
                Utilities.provider = "sokol"
                //self.presentViewController(viewController, animated: true, completion: nil)
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
    
    @IBAction func signUp(sender: UIBarButtonItem) {
        let viewController = UIStoryboard(name:"Main",bundle:nil).instantiateViewControllerWithIdentifier("signUp") as! UINavigationController
        
        let signUpView = viewController.viewControllers[0] as! SignUpTableViewController
        signUpView.linking = false
    
        self.presentViewController(viewController, animated: true, completion: nil)

        
    }
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        blurEffectView?.frame = view.bounds
    }
    
    
    
}

