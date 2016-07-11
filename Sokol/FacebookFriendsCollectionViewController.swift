//
//  FacebookFriendsCollectionViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 24/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit

private let reuseIdentifier = "facebookFriendCell"

class FacebookFriendsCollectionViewController: UICollectionViewController,UIViewControllerPreviewingDelegate {

    let ref = FIRDatabase.database().reference()

    var next:String?
    var facebookIds:[String] = []
    var facebookName:[String:String] = [:]
    var facebookPhoto:[String:UIImage] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .Available{
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        collectionView?.backgroundColor = UIColor.whiteColor()

        getFriendsFacebook("me/friends")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return facebookIds.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FacebookFriendsCollectionViewCell
        if facebookPhoto.count > indexPath.row {
            cell.facebookProfileImage.image = facebookPhoto[facebookIds[indexPath.row]]
            cell.facebookProfileImage.layer.cornerRadius = 90.0
            cell.facebookProfileImage.clipsToBounds = true
        }else{
            cell.facebookProfileImage.image = UIImage(named: "profile")
        }
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let alertViewController = UIAlertController(title: "Information", message: "\n\n\n\n\n", preferredStyle:.Alert)
        
        let height = NSLayoutConstraint(item: alertViewController.view, attribute: NSLayoutAttribute.Height, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 300)
        let width = NSLayoutConstraint(item: alertViewController.view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 230)
        
        alertViewController.view.addConstraint(height)
        alertViewController.view.addConstraint(width)
        
        let imageFrame = CGRectMake(15.0, 15.0, 200.0, 200.0)
        let profileImage = UIImageView(frame: imageFrame)
        profileImage.image = facebookPhoto[facebookIds[indexPath.row]]
        
        let labelFrame = CGRectMake(15.0,230.0,200.0,50.0)
        let labeText = UILabel(frame: labelFrame)
        labeText.numberOfLines = 0
        labeText.font = UIFont(name:"Helvetica Neue", size: 18.0)
        labeText.text =  facebookName[facebookIds[indexPath.row]]
        
        alertViewController.view.addSubview(profileImage)
        alertViewController.view.addSubview(labeText)
        
        
        self.presentViewController(alertViewController, animated: false, completion:{
            alertViewController.view.superview?.userInteractionEnabled = true
            alertViewController.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
        })
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }
    func alertControllerBackgroundTapped()
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func getFriendsFacebook(path:String?){
        var next:String?
        if path == nil {
            getFriendsFacebookPhoto(facebookIds)
            return;
        }else {
            let fbRequest = FBSDKGraphRequest(graphPath: path!, parameters: nil)
            
            fbRequest.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    self.presentViewController(Utilities.alertMessage("Error", message: "There was an error.\n Please Log out and make the log in with the facebook account again")
                        , animated: false, completion:nil)
                }else{
                    let data = result.objectForKey("data") as! NSArray
                    for i in data {
                        self.facebookIds.append(i.objectForKey("id") as! String)
                        self.facebookName[i.objectForKey("id")
                            as! String] = i.objectForKey("name") as! String
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.collectionView!.reloadData()
                        })
                        
                    }
                    //print(result)
                    let pagination = result.objectForKey("paging") as! NSDictionary
                    next = pagination.objectForKey("next") as? String
                    if next != nil {
                        next = next!.substringFromIndex(next!.startIndex.advancedBy(32))
                        self.getFriendsFacebook(next)
                    }else{
                        self.getFriendsFacebook(nil)
                    }
                    
                }
            })
            
        }
        
    }
    func getFriendsFacebookPhoto(ids:[String]) {
        for id in ids {
            let request = id+"/picture?type=large&redirect=false"
            let fbRequestImage = FBSDKGraphRequest(graphPath:request , parameters: nil)
            fbRequestImage.startWithCompletionHandler({ (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error != nil {
                    Utilities.alertMessage("Error", message: "There was an error")
                }else{
                    let data = result.objectForKey("data") as! NSDictionary
                    self.imageFromURL(data.objectForKey("url") as! String,id:id)
                }
            })
        }
        
        
    }
    func imageFromURL(url:String,id:String){
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let urlSession = NSURLSession.sharedSession()
        let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            if let data = data {
                self.facebookPhoto[id]=UIImage(data: data)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.collectionView!.reloadData()
                    
                })
            }
            
        })
        task.resume()
        
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItemAtPoint(location) else {
            return nil
        }
        guard let cell = collectionView?.cellForItemAtIndexPath(indexPath) else {
            return nil
        }
        let viewController = UIStoryboard(name: "Home", bundle: nil).instantiateViewControllerWithIdentifier("facebookInformation") as! FacebookCellViewController
        if indexPath.row <= facebookIds.count && indexPath.row <= facebookName.count && indexPath.row <= facebookPhoto.count{
            viewController.nameText = facebookName[facebookIds[indexPath.row]]
            viewController.image = facebookPhoto[facebookIds[indexPath.row]]
        }
        
        viewController.preferredContentSize = CGSize(width: 250, height: 300.0)
        previewingContext.sourceRect = cell.frame

        return viewController
        
    }
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
    }

    

}
