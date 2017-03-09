//
//  UsersProfileTweetsTableViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 09/11/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import Firebase

class OtherUserProfileTableViewController: UITableViewController {
    
    
    var databaseRef = FIRDatabase.database().reference()
    /**
     Not passing the following along with segue, because the meViewController and this embedded view will load simultaneously and thus the value of these variables will be nil
     **/
    var loggedInUser:FIRUser?
    var loggedInUserData:NSDictionary?
    
    var tweets = [NSDictionary]()
    var defaultImageViewHeightConstraint:CGFloat = 77.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UsersProfileTweetsTableViewController.hideKeyboard))
        
        self.view.addGestureRecognizer(tap)
        
        self.loggedInUser = FIRAuth.auth()?.currentUser
        
        /**
         Get the logged in users data
         **/
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.loggedInUserData = snapshot.value! as? NSDictionary
            /**
             Get all the tweets and retweets of the user from user_profile_tweets node
             **/
            self.databaseRef.child("user_profile_tweets").child(self.loggedInUser!.uid).observe(.childAdded, with: { (snapshot) in
                
                /** get the key of the tweet so that it can be updated **/
                let key = snapshot.key
                let snapshot = snapshot.value as? NSDictionary
                snapshot?.setValue(key, forKey: "key")
                
                //add the tweet to the tweets array
                self.tweets.append(snapshot!)
                
                /** Add the row **/
                self.tableView.insertRows(at: [IndexPath(row:0,section:0)], with: .automatic)
                
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
        /** Auto resize the cell */
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140
        
    }
    
    /**
     Hide the Keyboard
     **/
    func hideKeyboard(){
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.tweets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:HomeViewTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HomeViewTableViewCell
        
        let tweet = self.tweets[(self.tweets.count-1) - (indexPath.row)]
        print("ALL About the tweet")
        print(tweet)
        
        //add tap gesture to the image
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(didTapMediaInTweet(_:)))
        
        
        let retweetTap = UITapGestureRecognizer(target: self, action: #selector(didTapRetweet(_:)))
        
        let replyTap = UITapGestureRecognizer(target:self,action: #selector(didTapReply(_:)))
        
        cell.reply.addGestureRecognizer(replyTap)
        cell.retweet.addGestureRecognizer(retweetTap)
        cell.tweetImage.addGestureRecognizer(imageTap)
        
        /*
         Check if tweet has picture
         */
        if(tweet["picture"] != nil)
        {   /** SHOW PICTURE **/
            cell.tweetImage.isHidden = false
            cell.imageViewHeightConstraint.constant = defaultImageViewHeightConstraint
            
            let picture = tweets[(self.tweets.count-1) - (indexPath.row)]["picture"] as! String
            
            let url = URL(string:picture)
            cell.tweetImage.layer.cornerRadius = 10
            cell.tweetImage.layer.borderWidth = 3
            cell.tweetImage.layer.borderColor = UIColor.white.cgColor
            
            cell.tweetImage!.sd_setImage(with: url, placeholderImage: UIImage(named:"twitter")!)
            
        }
        else /** HIDE PICTURE **/
        {
            cell.tweetImage.isHidden = true
            cell.imageViewHeightConstraint.constant = 0
        }
        
        //user cannot retweet own tweets, or tweets that are retweeted from another persons timeline
        cell.retweet.isEnabled = false
        /**
         If tweet is retweeted by you
         **/
        if(tweet["retweet"] != nil)
        {
            cell.retweetedIcon.isHidden = false
            cell.retweetedByName.text = "By You"
            cell.retweet.setTitle(" \(tweet["retweet_count"]!)", for: .disabled)
        }
        else
        {
            cell.retweetedIcon.isHidden = true
            cell.retweetedByName.text = ""
        }
        
        /**
         - Check if YOUR tweet was tweeted by someone else
         - display a count of the retweets
         **/
        if(tweet["tweet_by_uid"] as? String == self.loggedInUser!.uid && tweet["retweet_count"] != nil)
        {
            cell.retweet.setTitle(" \(tweet["retweet_count"]!)", for: .disabled)
        }
        
        /** If retweeted then get the other users name, else its my own tweet, display my name**/
        let name = tweet["tweet_by_name"] != nil ? tweet["tweet_by_name"] : self.loggedInUserData!["name"]
        let handle = tweet["tweet_by_handle"] != nil ? tweet["tweet_by_handle"] : self.loggedInUserData!["handle"]
        
        cell.configure(nil,name:name as! String,handle:handle as! String,tweet:tweet["text"] as! String)
        
        
        return cell
    }
    
    func didTapMediaInTweet(_ sender : UITapGestureRecognizer)
    {
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        
        newImageView.frame = self.view.frame
        
        newImageView.backgroundColor = UIColor.black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target:self,action:#selector(self.dismissFullScreenImage))
        
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
    }
    
    /**
     Selector is called - hide the full screen image
     **/
    func dismissFullScreenImage(_ sender:UITapGestureRecognizer)
    {
        sender.view?.removeFromSuperview()
    }
    func didTapRetweet(_ sender: UITapGestureRecognizer)
    {
        print("Tapped Retweet")
        
    }
    
    func didTapReply(_ sender: UITapGestureRecognizer)
    {
        print("did tap reply")
    }
    
    func didTapComment(_ sender:UITapGestureRecognizer)
    {
        print("didTapComment")
    }
    
    
}
