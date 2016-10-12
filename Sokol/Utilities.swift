//
//  Utilities.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 14/06/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Utilities {
    static var user:FIRUser?
    static var linking:Bool = false
    static var provider:String?
    static var auth:AnyObject?
    static var button:GIDSignInButton?
    static var buttonSokol:UIButton?
    static var sokolLinking:Bool = false
    static func isValidEmail(test:String) -> Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let range = test.rangeOfString(emailRegEx, options:.RegularExpressionSearch)
        let result = range != nil ? true : false
        return result
    }
    static func imageToBase64(imageProfile image:UIImage) -> String {
        let imageData:NSData = UIImagePNGRepresentation(image)!
        return imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    }
    static func base64ToImage(base:String) ->UIImage {
        
        let dataDecoded:NSData = NSData(base64EncodedString:base, options: .IgnoreUnknownCharacters)!
        let decodedimage:UIImage = UIImage(data: dataDecoded)!
        return decodedimage
    }
    static func resizeImage(image:UIImage,newWidth:CGFloat,newHeight:CGFloat) -> UIImage{
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    static func setBirthdayDate(tempDate:String) ->String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.dateFromString(tempDate)
        
        dateFormatter.dateStyle = .LongStyle
        return dateFormatter.stringFromDate(date!)
        //eturn tempDate
        
    }
    static func alertMessage(title:String,message:String) -> UIAlertController{
        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction =  UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertMessage.addAction(okAction)
        return alertMessage
    }
    
}
