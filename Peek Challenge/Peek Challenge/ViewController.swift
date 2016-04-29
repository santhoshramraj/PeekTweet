//
//  ViewController.swift
//  Peek Challenge
//
//  Created by Santhosh Ramaraju on 4/26/16.
//  Copyright © 2016 Santhosh Ramaraju. All rights reserved.
//

import UIKit
import TwitterKit

let kSearchURL = "https://api.twitter.com/1.1/search/tweets.json"
let kRetweetURL = "https://api.twitter.com/1.1/statuses/retweet/%@.json"
enum TweetsFetchType {
    case Refresh
    case NextBatch
    case Default
}
class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tweetsTable: UITableView!
    let evenCellColor = UIColor.init(red: 131/255, green: 175/255, blue: 208/255, alpha: 1)
    let oddCellColor = UIColor.init(red: 154/255, green: 189/255, blue: 216/255, alpha: 1)
    let twitterColor = UIColor.init(red: 85/255, green: 172/255, blue: 238/255, alpha: 1)
    var tweets:[PeekTweet]!
    var loadingView:LoadingView!
    var nextResultsURLStr:String?
    var refreshURLStr:String?
    var refreshControl:UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        let navbar = UINavigationBar(frame: CGRectMake(0,0,view.frame.width,60.0))
        navbar.barTintColor = twitterColor
        navbar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        navbar.setItems([UINavigationItem.init(title: "Peek Tweet")], animated: false)
        view.addSubview(navbar)
        tweetsTable.dataSource = self
        tweetsTable.delegate = self
        tweets = [PeekTweet]()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(ViewController.refreshTweets), forControlEvents: UIControlEvents.ValueChanged)
        tweetsTable.addSubview(refreshControl)
        tweetsTable.separatorInset = UIEdgeInsetsZero
        loadingView = LoadingView.init(frame: view.bounds)
        self.view.addSubview(loadingView)
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[loadingView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["loadingView":loadingView]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[loadingView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["loadingView":loadingView]))
        loadingView.animate()
        getTheTweets(.Default)
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(animated: Bool) {
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count > 0 ? tweets.count:1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:TweetCell? = tableView.dequeueReusableCellWithIdentifier("tweetCell") as? TweetCell
        if tweets.count>0 {
            let tweet = tweets[indexPath.row]
            cell?.tweetData = tweet
            cell?.backgroundColor = (indexPath.row % 2)==0 ? evenCellColor:oddCellColor
            if indexPath.row == tweets.count-7 {
                getTheTweets(.NextBatch)
            }
        }

        return cell!
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tweet = tweets[indexPath.row]
        retweet(tweet.id!)
    }
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
            self.tweets.removeAtIndex(indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
        }
        delete.backgroundColor = UIColor.redColor()
        return [delete]
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    // MARK: Get Data
    func refreshTweets(){
        getTheTweets(.Refresh)
    }
    func getTheTweets(type:TweetsFetchType){
        let client = TWTRAPIClient()
        var urlString:String?
        var params:[String:String]?
        switch type{
                    case .Default:
                        urlString = kSearchURL
                        params = ["q": "@peek"]
                    case .NextBatch:
                        urlString = nextResultsURLStr != nil ? kSearchURL+nextResultsURLStr! : nil
                    case .Refresh:
                        urlString = refreshURLStr != nil ? kSearchURL+refreshURLStr! : nil
                    }
        if urlString == nil {
                        return
                }
        var clientError : NSError?
        let request = client.URLRequestWithMethod("GET", URL: urlString!, parameters: params, error: &clientError)
        let mutableRequest:NSMutableURLRequest = request as! NSMutableURLRequest
        //Adding Timeout interval to the request as the refresh control and tableview get hung up if the request takes too long
        mutableRequest.timeoutInterval = 5.0
        client.sendTwitterRequest(mutableRequest) { (response, data, connectionError) -> Void in
            if connectionError != nil || (response as! NSHTTPURLResponse).statusCode != 200 || data == nil{
                print("Error: \(connectionError), Response: \(response)")
                if self.refreshControl.refreshing{
                    self.refreshControl.endRefreshing()
                }
                if self.view.subviews.contains(self.loadingView){
                    self.loadingView.removeFromSuperview()
                }
                return
            }
            //Doing asyncly to not stutter the UI
            dispatch_async(dispatch_get_global_queue(0, 0), {
                do {
                    let dataDict = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                    let metaData = dataDict["search_metadata"]
                    self.refreshURLStr = metaData!!["refresh_url"] as? String
                    self.nextResultsURLStr = metaData!!["next_results"] as? String
                    let statuses = dataDict["statuses"] as! [AnyObject]
                    var tempArray = [PeekTweet]()
                    for aStatus in statuses{
                        let imageStr = aStatus["user"]!!["profile_image_url"] as! String
                        let imageURL = NSURL(string: imageStr.stringByReplacingOccurrencesOfString("normal", withString: "bigger"))
                        let imageData = try NSData(contentsOfURL: imageURL!, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                        let avatar = UIImage(data:imageData)
                        let aTweet = PeekTweet(userName: aStatus["user"]!!["screen_name"] as! String, avatar:avatar!, tweet: aStatus["text"] as! String, id: aStatus["id_str"] as! String)
                        if !self.tweets.contains({$0.id == aTweet.id}){
                            tempArray.append(aTweet)
                        }
                    }
                    switch type{
                    case .Default:
                        self.tweets = tempArray
                    case .NextBatch:
                        self.tweets = self.tweets+tempArray
                    case .Refresh:
                        self.tweets = tempArray+self.tweets
                    }
                    
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.tweetsTable.reloadData()
                    if self.refreshControl.refreshing{
                        self.refreshControl.endRefreshing()
                    }
                    if self.view.subviews.contains(self.loadingView){
                        self.loadingView.removeFromSuperview()
                    }
                })

            })
        }
    }
    
    //MARK: Login and RT
    func login(tweetId:String){
        let backView = UIView(frame: view.bounds)
        backView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        view.addSubview(backView)
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[backView]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["backView":backView]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[backView]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["backView":backView]))
        let close = UIButton(frame: CGRectMake(0,0,100.0,40.0))
        close.addTarget(self, action: #selector(removeView), forControlEvents: .TouchUpInside)
        close.setTitle("X", forState: .Normal)
        close.titleLabel?.font = UIFont.systemFontOfSize(26.0)
        close.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(close)
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[close(40.0)]-10-|", options: .DirectionLeadingToTrailing, metrics: nil, views:["close":close]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-20-[close(40.0)]", options: .DirectionLeadingToTrailing, metrics: nil, views:["close":close]))
        
        let loginLabel = UILabel(frame: CGRectMake(0,0,300.0,50.0))
        loginLabel.text = "Please login to retweet"
        loginLabel.textColor = UIColor.whiteColor()
        loginLabel.font = UIFont.systemFontOfSize(26.0)
        loginLabel.textAlignment = .Center
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(loginLabel)
        let logInButton = TWTRLogInButton { (session, error) in
            if session != nil {
                backView.removeFromSuperview()
                self.retweet(tweetId)
            } else {
                NSLog("Login error: %@", error!.localizedDescription);
            }
        }
        logInButton.center = self.view.center
        backView.addSubview(logInButton)
        
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-40-[label]-40-|", options: .DirectionLeadingToTrailing, metrics: nil, views:["label":loginLabel]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label(40.0)]-20-[loginbutton]", options: .DirectionLeadingToTrailing, metrics: nil, views:["label":loginLabel,"loginbutton":logInButton]))
        let loginCenterX = NSLayoutConstraint(item: logInButton, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let loginCenterY = NSLayoutConstraint(item: logInButton, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0)
        NSLayoutConstraint.activateConstraints([loginCenterX,loginCenterY])
    }
    func removeView(sender:UIControl){
        sender.superview?.removeFromSuperview()
    }
    func retweet(id:String){
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            let client = TWTRAPIClient(userID: userID)
            let statusesShowEndpoint = String.localizedStringWithFormat(kRetweetURL, id)
            var clientError : NSError?
            let request = client.URLRequestWithMethod("POST", URL: statusesShowEndpoint, parameters: nil, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if connectionError != nil || data == nil{
                    print("Error: \(connectionError)")
                    var msg:String!
                    if connectionError?.code == 327 {
                        msg = "You have already retweeted this."
                    } else {
                        msg = "Something went wrong. Please try again."
                    }
                    self.showAlert("Oops!", message: msg, buttonTitle: "OK")
                    return
                }
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                    self.showAlert("Yay!", message: "Retweeted successfully. Please refresh in a while to see your RT.", buttonTitle: "OK")
                    print("json: \(json)")
                
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                    self.showAlert("Oops!", message: "Something went wrong. Please try again.", buttonTitle: "OK")
                }
            }
            
        } else {
            login(id)
        }
    }
    func showAlert(title:String,message:String,buttonTitle:String){
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.Alert
        )
        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
