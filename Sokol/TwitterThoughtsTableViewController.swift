//
//  TwitterThoughtsTableViewController.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 22/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import UIKit
import Fabric
import TwitterKit
import Firebase

class TwitterThoughtsTableViewController: UITableViewController,TWTRTweetViewDelegate {
    let userId = Twitter.sharedInstance().sessionStore.session()?.userID
    var tweetsID:[Int] = []
    var tweets:[AnyObject] = []
    let tweetTableReuseIdentifier = "TweetCell"
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
        self.refreshControl?.addTarget(self, action: "handleRefresh", forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.registerClass(TWTRTweetTableViewCell.self, forCellReuseIdentifier: tweetTableReuseIdentifier)
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        getTweetIds()
        
        
                // Do any additional setup after loading the view.
    }
    func handleRefresh(){
        getTweetIds()
        self.refreshControl?.endRefreshing()
    }
    func getTweetIds(){
        let client = TWTRAPIClient(userID: userId)
        let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/search/tweets.json?q=%23SokolApp", parameters: nil, error: nil)
        client.sendTwitterRequest(request, completion: { (response, data, connectionError) in
            if connectionError != nil {
                self.presentViewController(Utilities.alertMessage("Error", message: "There was an error with the conncection"), animated: true, completion: nil)
            }else{
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                    
                    let tweets = json!["statuses"] as! [AnyObject]
                    self.tweetsID = []
                    for t in tweets {
                        self.tweetsID.append(t["id"] as! Int)
                        
                    }
                    self.getTweets(self.tweetsID)
                    
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                }
                
            }
        })
    }
    func getTweets(ids:[Int]){
        tweets = []
        let client = TWTRAPIClient(userID: userId)
        for i in ids {
            client.loadTweetWithID(String(i), completion:{tweet,error in
                if let t = tweet {
                    self.tweets.append(t)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.tableView.reloadData()
                        
                    })
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tweets.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(tweetTableReuseIdentifier, forIndexPath: indexPath) as! TWTRTweetTableViewCell
        cell.tweetView.delegate = self
        let tweet = tweets[indexPath.row]
        cell.configureWithTweet(tweet as! TWTRTweet)
        // Configure the cell...

        return cell
    }
 
}
