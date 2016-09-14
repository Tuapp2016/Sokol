//
//  RegisterToken.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 13/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

class RegisterToken: IMessage{
    func sendMessage(body: String, title: String, id: String?, page: String?) {
        let URL = "https://fcmsokol.herokuapp.com/sender.json"
        let request = NSMutableURLRequest(URL: NSURL(string: URL)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let params = ["token":["token_id":body]]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTaskWithRequest(request) { (data,response,error) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse{
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
                if httpResponse.statusCode == 201{
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        print("The token was registerd succesfully")
                    })
                }else{
                    NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                        print("There was an error")
                    })
                }
            }
        }
        task.resume()
    }
}
