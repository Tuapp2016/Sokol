//
//  IMessage.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 13/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

protocol IMessage{
    func sendMessage(body:String,title:String,id:String?,page:String?)
}
