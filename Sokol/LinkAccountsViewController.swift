//
//  LinkAccountsViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 27/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit

class LinkAccountsViewController: UIViewController,GIDSignInUIDelegate {
    @IBOutlet weak var signInSokol: UIButton!
    @IBOutlet weak var signInFacebook: UIButton!
    @IBOutlet weak var signInTwitter: UIView!
    @IBOutlet weak var signInGoogle: GIDSignInButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.linking = true
        Utilities.button = signInGoogle
        Utilities.buttonSokol = signInSokol
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let user = FIRAuth.auth()?.currentUser {
            // User is signed in.
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LogIn")
            self.presentViewController(viewController, animated: true, completion: nil)
            
        }
        GIDSignIn.sharedInstance().uiDelegate = self
        let logInButton = TWTRLogInButton(logInCompletion: {session, error in
            if Utilities.linking{
                if session != nil {
                    let authToken = session?.authToken
                    let authTokenSecret = session?.authTokenSecret
                    let credential = FIRTwitterAuthProvider.credentialWithToken(authToken!, secret: authTokenSecret!)
                    FIRAuth.auth()?.currentUser?.linkWithCredential(credential, completion:{(user,error) in
                        if error != nil {
                            self.presentViewController(Utilities.alertMessage("Error", message: (error?.description)!), animated: true, completion: nil)
                        }else{
                            self.signInTwitter.hidden = true
                        }
                    })
                    
                    
                }else{
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                    
                }
            }
            
        })
        //logInButton.center = self.view.center
        logInButton.frame.size.width = signInTwitter.frame.width
        logInButton.frame.size.height = signInTwitter.frame.height
        //logInButton.frame = CGRect(x: signInTwitter.frame.origin.x, y: signInTwitter.frame.origin.y, width: signInTwitter.frame.width, height: signInTwitter.frame.height)
        signInTwitter.addSubview(logInButton)

        
        
        //signInTwitter.addSubview(loginButton)
        for data in (FIRAuth.auth()?.currentUser?.providerData)! {
            
            switch data.providerID {
            case "facebook.com":
                signInFacebook.hidden = true
            case "twitter.com":
                signInTwitter.hidden = true
            case "google.com":
                signInGoogle.hidden = true
            default:
                signInSokol.hidden = true
            }
        }
        if Utilities.sokolLinking {
            signInSokol.hidden = true
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func logInSokol(sender: AnyObject) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("signUp") as! UINavigationController
        (viewController.viewControllers[0] as! SignUpTableViewController).linking = true
        presentViewController(viewController, animated: true, completion: nil)
    }
    @IBAction func logInFaceboook(sender: AnyObject) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logOut()
        facebookLogin.logInWithReadPermissions(["email","public_profile","user_friends"],fromViewController: self, handler: {(facebookResult, facebookError) in
            if facebookError != nil{
                self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
            }else if facebookResult.isCancelled {
                self.presentViewController(Utilities.alertMessage("Error", message: "The login was canceled"), animated: true, completion: nil)
            }else{
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.currentUser?.linkWithCredential(credential, completion:{ (user, error) in
                    if error != nil {
                        self.presentViewController(Utilities.alertMessage("Error", message: "There was an error"), animated: true, completion: nil)
                    }else{
                        Utilities.user = user
                        self.signInFacebook.hidden = true
                    }
                })
            }
        })
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
