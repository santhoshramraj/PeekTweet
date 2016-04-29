//
//  PeekTweet.swift
//  Peek Challenge
//
//  Created by Santhosh Ramaraju on 4/27/16.
//  Copyright © 2016 Santhosh Ramaraju. All rights reserved.
//

import UIKit
class PeekTweet: NSObject {
    var userName:String?
    var avatar:UIImage?
    var tweet:String?
    var id:String?
    init(userName:String, avatar:UIImage, tweet:String, id:String) {
        self.userName = userName
        self.avatar = avatar
        self.tweet = tweet
        self.id = id
    }
}
