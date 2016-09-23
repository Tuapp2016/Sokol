//
//  SendMessageClient.swift
//  Sokol
//
//  Created by Andres Rene Gutierrez on 13/09/2016.
//  Copyright © 2016 Andres Rene Gutierrez. All rights reserved.
//

import Foundation

class SendMessageClient{
    var strategy: IMessage
    
    required init(strategy:IMessage){
        self.strategy = strategy
    }
    
    func sendMessage(body:String,title:String,id:String?,page:String?){
        strategy.sendMessage(body, title: title, id: id, page: page)
    }
    
    
}