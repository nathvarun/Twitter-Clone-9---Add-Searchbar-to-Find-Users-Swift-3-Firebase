//
//  HomeViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 24/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SDWebImage

class HomeViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate {

    var databaseRef = FIRDatabase.database().reference()
    var loggedInUser:AnyObject?
    var loggedInUserData:NSDictionary?
    var listFollowers = [NSDictionary?]()//store all the followers
    var listFollowing = [NSDictionary?]()
    
    @IBOutlet weak var aivLoading: UIActivityIndicatorView!
    @IBOutlet weak var homeTableView: UITableView!
    
    var defaultImageViewHeightConstraint:CGFloat = 77.0
    
    var tweets = [NSDictionary]()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        /** 
            Get The logged In User and store it in a variable
         **/
        self.loggedInUser = FIRAuth.auth()?.currentUser
        
        
        
        /**
            Retrieve the Logged In User's Details
        **/
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observeSingleEvent(of: .value) { (snapshot:FIRDataSnapshot) in
            
            //store the logged in users details into the variable 
            self.loggedInUserData = snapshot.value as? NSDictionary
//            print(self.loggedInUserData)
            
            //get all the tweets that are made by the user
            
            self.databaseRef.child("users_feed").child(self.loggedInUser!.uid).observe(.childAdded, with: { (snapshot:FIRDataSnapshot) in
              
                //get the key of the tweet so that it can be updated
                let key = snapshot.key
                let snapshot = snapshot.value as? NSDictionary
                snapshot?.setValue(key, forKey: "key")
                
                self.tweets.append(snapshot!)
                
                
                self.homeTableView.insertRows(at: [IndexPath(row:0,section:0)], with: UITableViewRowAnimation.automatic)
                
                self.aivLoading.stopAnimating()
                
            }){(error) in
           
                print(error.localizedDescription)
            }
            
        }
        
  
       /**
            When the user has no posts, stop animating the aiv after 5 seconds
        **/
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(stopAnimating), userInfo: nil, repeats: false)
        
        
        
        self.homeTableView.rowHeight = UITableViewAutomaticDimension
        self.homeTableView.estimatedRowHeight = 140
    
        /**
            Get all the users that the logged in user is following
        **/
        self.databaseRef.child("following").child(self.loggedInUser!.uid).observe(.childAdded, with: { (snapshot) in
            
            let snapshot = snapshot.value as? NSDictionary
            self.listFollowing.append(snapshot)
            
        }) { (error) in
                print(error.localizedDescription)
        }
        

        /**
            Get all the users that are FOLLOWING the LOGGED IN USER
        **/
        self.databaseRef.child("followers").child(self.loggedInUser!.uid).observe(.childAdded, with: { (snapshot) in
            
            let key = snapshot.key
            let snapshot = snapshot.value as? NSDictionary
            snapshot?.setValue(key, forKey: "uid")
            self.listFollowers.append(snapshot!)
            
            
            }) { (error) in
                
                print(error.localizedDescription)
        }
        
        
    }
    
    
    /**
        Hide the animating Spinner
    **/
    open func stopAnimating()
    {
        self.aivLoading.stopAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    
    /** Set the number of sections of the table **/
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /** 
        Set the number of rows of the table
    **/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tweets.count
        
    }
    
    
    /** 
        Configure the particular cell
     **/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: HomeViewTableViewCell = tableView.dequeueReusableCell(withIdentifier: "HomeViewTableViewCell", for: indexPath) as! HomeViewTableViewCell
        

        /** store the tweet in a variable**/
        let tweet = self.tweets[(self.tweets.count-1) - (indexPath.row)]
        
        
        /** store the tweet text in a variable **/
        let tweetText = tweet["text"] as! String
        
        /** 
            1.add tap gesture to image
            2.add tap gesture to retweet button
            3.add tap gesture to tweetImage
         **/
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(self.didTapMediaInTweet(_:)))
        let retweetTap = UITapGestureRecognizer(target: self, action: #selector(self.didTapRetweet(_:)))
        let replyTap = UITapGestureRecognizer(target: self, action: #selector(self.didTapReply(_:)))
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(self.didTapLike(_:)))
        
        cell.reply.addGestureRecognizer(replyTap)
        cell.retweet.addGestureRecognizer(retweetTap)
        cell.tweetImage.addGestureRecognizer(imageTap)
        cell.like.addGestureRecognizer(likeTap)
       
        /**
         Check if tweet has picture
         */
        if(tweet["picture"] != nil)
        {   /** if yes - SHOW PICTURE **/
            cell.tweetImage.isHidden = false
            cell.imageViewHeightConstraint.constant = defaultImageViewHeightConstraint
            
            let picture = tweet["picture"] as! String
            
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
        
        /**
         Check if tweet is made by other user and tweet has not already been retweeted by logged in user
         - if yes - ENABLE RETWEET BUTTON
         - if no  - DISABLE RETWEET BUTTON
        **/
        if(tweet["tweet_by_uid"] != nil && tweet["retweet"] == nil)
        {
            print("TWEET IS BY OTHER USER AND HAS NOT BEEN RETWEETED BY YOU")
            cell.retweet.isEnabled = true

        }
        else /** Hide the retweet button **/
        {
            cell.retweet.isEnabled = false
        }
        
        
        /**
            - Check if anyone has retweeted the tweet
            - if yes
                - show the retweet icon and the retweet count
                - Check if retweet is by logged in user
                - if yes
                    - show "by You" next to the retweet icon
                - else 
                    - retweet was by a person you are following, show his name
            - else
                - Hide the retweet icon and empty the retweetedByName label
         */
        if(tweet["retweet"] != nil)
        {
            /** The tweet has been retweeted, Show the retweet count **/
            cell.retweet.setTitle(" \(tweet["retweet_count"]!)", for: .disabled)
            cell.retweet.setTitle(" \(tweet["retweet_count"]!)", for: .normal)


            
                /** Did you retweet the tweet yourself **/
                if(tweet["retweeted_by_self"] != nil)
                {
                    //show the retweeted icon
                    cell.retweetedIcon.isHidden = false
                    cell.retweetedByName.text = "by You"

                }
          
                /** If the original tweet was not made by you then show the name of the user(you follow) who retweeted a tweet  **/
                else if(tweet["tweet_by_uid"] != nil)
                {
                    cell.retweetedIcon.isHidden = false
                    cell.retweetedByName.text = "by" + (tweet["retweeted_by_name"] as! String)
                }
                
                /** Your tweet has been retweeted by someone, since you cant show everyone's name, dont thow the name, later we can show it in the notifications tab **/
                else
                {
                    cell.retweetedIcon.isHidden = true
                    cell.retweetedByName.text = ""
                }
            
            
        }
        else
        {//hide the retweet icon
            cell.retweetedIcon.isHidden = true
            cell.retweetedByName.text = ""

            //Its possible that someone else may have retweeted this tweet, so display the count
            if(tweet["retweet_count"] != nil)
            {
                cell.retweet.setTitle("\(tweet["retweet_count"]!)" , for: .normal)
                cell.retweet.setTitle("\(tweet["retweet_count"]!)", for: UIControlState.disabled)
            }
        }
        
    
        /**
            - if tweet is by other user 
                - show the name and handle of the other user
            - else  
                - show name and handle of the logged in user
         **/
        let name = tweet["name"] != nil ? tweet["name"] : self.loggedInUserData!["name"]
        let handle = tweet["handle"] != nil ? tweet["handle"] : self.loggedInUserData!["handle"]
        
        /**
         if tweet is from another user then change color of name of the user's name
         */
        if(tweet["tweet_by_uid"] != nil)
        {
            cell.name.textColor = UIColor.purple
        }
 
   
        cell.configure(nil,name:name as! String,handle:handle as! String,tweet:tweetText)
        
        return cell
    }
    
    /**
        The retween button was Tapped
    **/
    func didTapRetweet(_ sender: UITapGestureRecognizer)
    {
        print("Tapped Retweet")
       
        
        /** Get the indexPath of the tapped tweet **/
        let tapLocation = sender.location(in: self.homeTableView)
        let indexPath = self.homeTableView.indexPathForRow(at: tapLocation)! as IndexPath
        
        /** Get the cell of the tapped tweet using the indexPath **/
        let cell:HomeViewTableViewCell = self.tableView(self.homeTableView, cellForRowAt: indexPath) as! HomeViewTableViewCell
        
        /** get the tweet from the array using the indexPath
            Since all our users data is not in the cell 
        */
        let tweet = self.tweets[(self.tweets.count - 1) - indexPath.row]
       
        var tweet_followers = [NSDictionary?]()
       
    

        
//        let key = self.databaseRef.child("users_feed").childByAutoId().key
        let key = tweet["key"]!
        
        /** The cell may/may not have picture/text so create optional constants */
        let tweetPicture:Any?
        let tweetText:Any?
        
        /** if tweet has text then set the text **/
        if(tweet["text"] != nil)
        {
            tweetText = tweet["text"] as! String
        }
        else
        {
            tweetText = NSNull()
        }
        /** if tweet has picture, then set the picture **/
        if(tweet["picture"] != nil)
        {
                tweetPicture = tweet["picture"] as! String
        }
        else
        {
            tweetPicture = NSNull()
        }
       
        /** THIS WILL BE USED ONLY WHEN THE USER IS ALLOWED TO RETWEEN OWN TWEET
            AS of now we are not enabling this 
            DO NOT DELETE
         **/
        //remove the tweet from its current location and move it to the top
//        self.tweets.remove(at: indexPath.row)
//        print(self.tweets)
//        self.homeTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
        
        /** END RETWEET **/
        
        
        /** add a retweet node to the particular tweet to indicate that the tweet has been retweeted **/
        let retweetCount:Int?

        if(tweet["retweet_count"] == nil)
        {
            retweetCount = 1
        }
        else
        {
            retweetCount = (tweet["retweet_count"] as! Int) + 1
        }
        

        
        /** TAKING TOO LONG TO COMPILE **/
//        var childUpdates = ["users_feed/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet": true,
//                            "users_feed/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweeted_by_self": true,
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/text":tweetText! as! String,
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/timestamp":"\(Date().timeIntervalSince1970)",
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet":true,
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet_count": retweetCount!,
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/tweet_by_name":cell.name.text!,
//                            "user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/tweet_by_handle":cell.handle.text!] as [String: Any]

        
        
        
        
        var childUpdates = [String:Any]()
        
        
        /**
            Update the retweet_count for logged in user in the users_feed and user_profile_tweets
        **/
        childUpdates["users_feed/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet_count"] = retweetCount
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet_count"] = retweetCount!

        
        
        childUpdates["users_feed/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet"] = true
        childUpdates["users_feed/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweeted_by_self"] =  true
        
        
        
        /**
            post the retweet to the user_profile_tweets of the logged in user
        */
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/text"] = tweetText! as! String
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/timestamp"] = "\(Date().timeIntervalSince1970)"
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/retweet"] = true
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/tweet_by_name"] = cell.name.text!
        /** remove the first @ from the handle **/
        cell.handle.text!.remove(at: cell.handle.text!.startIndex)
        childUpdates["user_profile_tweets/\(self.loggedInUser!.uid!)/\(tweet["key"]!)/tweet_by_handle"] = cell.handle.text!


        
        /**
            Update the retweet count for the person who created the tweet
        **/
        childUpdates["users_feed/\(tweet["tweet_by_uid"]!)/\(tweet["key"]!)/retweet_count"] = retweetCount
        childUpdates["user_profile_tweets/\(tweet["tweet_by_uid"]!)/\(tweet["key"]!)/retweet_count"] = retweetCount
        
        
        /**
         Add the tweet to the followers feed
         - last line adds a retweet node also to indicate that it was retweeted
         */
        for user in self.listFollowers{
            
            
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/handle"] = tweet["handle"] as! String
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/name"] =  tweet["name"] as! String
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/text"] = tweetText!//may or maynot have a text
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/timestamp"]  = "\(Date().timeIntervalSince1970)"
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/picture"] = tweetPicture! // may or may not have picture
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/retweet"] = true //user has retweeted it
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/retweet_count"] = retweetCount
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/retweeted_by_uid"] = self.loggedInUser!.uid as String
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/retweeted_by_name"] = self.loggedInUserData!["name"] as! String
            childUpdates["users_feed/\(user!["uid"]!)/\(tweet["key"]!)/retweeted_by_handle"] = self.loggedInUserData!["handle"] as! String
        
        }
  
        
        /**
            other people that are already following the user and have the tweet,update retweet_count for them aswell
        **/
 
        self.databaseRef.child("followers").child("\(tweet["tweet_by_uid"]!)").observeSingleEvent(of: .value, with: { (snapshot) in
            print("ALL FOLLOWERS")
            
            let snapshot = snapshot.value as? NSDictionary

            for (key,_) in snapshot!{
                
                childUpdates["users_feed/\(key)/\(tweet["key"]!)/retweet_count"] = retweetCount
            }
            
            
            //update the values in the database
            self.databaseRef.updateChildValues(childUpdates)
         
            /**
             To indicate that it has been retweeted
             - add the retweet node and set its value to true
             - add the retweeted_by_name for the users feed
             - add retweeted_by_self for users feed
             - add retweet_count for both users_feed and users_profile_tweets
             - then reload the particular cell
             */
            (self.tweets[(self.tweets.count - 1) - indexPath.row]).setValue(true, forKey: "retweet")
            (self.tweets[(self.tweets.count - 1) - indexPath.row]).setValue(self.loggedInUserData!["name"], forKey: "retweeted_by_name")
            (self.tweets[(self.tweets.count - 1) - indexPath.row]).setValue(true, forKey:"retweeted_by_self")
            (self.tweets[(self.tweets.count - 1) - indexPath.row]).setValue(retweetCount, forKey: "retweet_count")
            self.homeTableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            
        }) { (error) in
            //
            print("error")
            //                print(error.localizedDescription)
        }

        

        print("Retweet this post!")
    }
    
    /**
        The reply button was tapped
    **/
    func didTapReply(_ sender: UITapGestureRecognizer)
    {
        print("did tap comment")
    }
    
    /**
        Enlarge the image in the tweet when it is Tapped
    **/
    func didTapMediaInTweet(_ sender:UITapGestureRecognizer)
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

    /**
     Tapped the like button for a particular cell
    **/
    func didTapLike(_ sender: UITapGestureRecognizer)
    {
        print("Tapped Like")
        let tapLocation = sender.location(in: self.homeTableView)
        let indexPath = self.homeTableView.indexPathForRow(at: tapLocation)! as IndexPath
        
        let tweet = self.tweets[(self.tweets.count - 1) - indexPath.row]

        var childUpdates = [String:Any]()
        
        
    }
    
    /**
        Pass contextual data along with the segue
    **/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "findUserSegue")
        {
            let showFollowingTableViewController = segue.destination as! FollowUsersTableViewController
            
 
            showFollowingTableViewController.loggedInUser = self.loggedInUser as? FIRUser
            
            //  showFollowingTableViewController.followData = self.followData
        }
        else if(segue.identifier == "showFollowersTableViewController")
        {
            let showFollowersTableViewController = segue.destination as! ShowFollowersTableViewController
            showFollowersTableViewController.user = self.loggedInUser as? FIRUser
            
        }
        else if(segue.identifier == "showNewTweetViewController")
        {
         
            let showNewTweetViewController = segue.destination as! NewTweetViewController
            showNewTweetViewController.listFollowers = self.listFollowers
            showNewTweetViewController.loggedInUserData = self.loggedInUserData
        }
    
        
    }
    

    

    

}
