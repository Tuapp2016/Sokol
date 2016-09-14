//
//  SendTopic.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 13/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

class SendTopic: IMessage{
    func sendMessage(body: String, title: String, id: String?, page: String?) {
        let URL = "https://fcmsokol.herokuapp.com/sender/sendTopic.json"
        let request = NSMutableURLRequest(URL: NSURL(string: URL)!)
        let session = NSURLSession.sharedSession()

        request.HTTPMethod = "POST"
        request.HTTPBody = ("topic=\(id!)&title=\(title)&body=\(body)" as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let task = session.dataTaskWithRequest(request) {data,response,error -> Void in
            if let httpResponse = response as? NSHTTPURLResponse{
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
                if httpResponse.statusCode == 200 {
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        print("The message was sent succesfully \(data)")
                    })
                }else{
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        print("We can't send the message")
                    })
                }
            }
        }
        task.resume()
    }
}