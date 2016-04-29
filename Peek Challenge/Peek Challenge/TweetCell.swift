//
//  TweetCell.swift
//  Peek Challenge
//
//  Created by Santhosh Ramaraju on 4/26/16.
//  Copyright © 2016 Santhosh Ramaraju. All rights reserved.
//

import UIKit

class TweetCell: UITableViewCell{
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var tweet: UILabel!
    var tweetData:PeekTweet {
        get{
            return self.tweetData
        }
        set{
            userName.text = "@"+newValue.userName!
            avatar.image = newValue.avatar
            tweet.text = newValue.tweet
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutMargins = UIEdgeInsetsZero
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
