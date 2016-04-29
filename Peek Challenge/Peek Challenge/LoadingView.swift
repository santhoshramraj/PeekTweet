//
//  LoadingView.swift
//  Peek Challenge
//
//  Created by Santhosh Ramaraju on 4/27/16.
//  Copyright © 2016 Santhosh Ramaraju. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    var loadingIndicator:UIActivityIndicatorView?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup(){
        backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.6)
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingIndicator?.frame = CGRectZero
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(loadingIndicator!)
    }
    func animate(){
        let height = NSLayoutConstraint.init(item: loadingIndicator!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 50.0)
        let width = NSLayoutConstraint.init(item: loadingIndicator!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 50.0)
        let centerX = NSLayoutConstraint.init(item: loadingIndicator!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint.init(item: loadingIndicator!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activateConstraints([centerX,centerY,height,width])
        loadingIndicator?.startAnimating()
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
