//
//  UserProfileViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 09/10/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//
//1. Get the logged in Users Data store it in self.loggedInUsersData
//2. Get the user's data, the user whose profile is being viewed.


import UIKit
import Firebase

class UserProfileViewController: UIViewController {

    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var followButton: UIButton!


    
    var otherUser:NSDictionary?
    let loggedInUser = FIRAuth.auth()?.currentUser//store the auth details of the logged in user
    var loggedInUserData:NSDictionary? //the users data from the database will be stored in this variable
    var databaseRef:FIRDatabaseReference!
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        
    //create a reference to the firebase database
        databaseRef = FIRDatabase.database().reference()
        
            //add an observer for the logged in user

        databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.loggedInUserData = snapshot.value as? NSDictionary
            self.loggedInUserData?.setValue(self.loggedInUser!.uid, forKey: "uid")
            }) { (error) in
                print(error.localizedDescription)
        }
        
        //        databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observe(FIRDataEventType.value, with: { (snapshot) in
//
//            print("VALUE CHANGED IN USER_PROFILES")
//            self.loggedInUserData = snapshot.value as? NSDictionary
//            //store the key in the users data variable
//            self.loggedInUserData?.setValue(self.loggedInUser!.uid, forKey: "uid")
//            
//            
//            }) { (error) in
//                print(error.localizedDescription)
//        }
        
        //add an observer for the user who's profile is being viewed
        //When the followers count is changed, it is updated here!
        //need to add the uid to the user's data
        databaseRef.child("user_profiles").child(self.otherUser?["uid"] as! String).observe(.value, with: { (snapshot) in
            
            let uid = self.otherUser?["uid"] as! String
            self.otherUser = snapshot.value as? NSDictionary
            //add the uid to the profile
            self.otherUser?.setValue(uid, forKey: "uid")
        
        
        }) { (error) in
                print(error.localizedDescription)
        }
        
        //check if the current user is being followed
        //if yes, Enable the UNfollow button
        //if no, Enable the Follow button
        
    databaseRef.child("following").child(self.loggedInUser!.uid).child(self.otherUser?["uid"] as! String).observe(.value, with: { (snapshot) in
    
            if(snapshot.exists())
            {
                self.followButton.setTitle("Unfollow", for: .normal)
                print("You are following the user")

            }
            else
            {
                self.followButton.setTitle("Follow", for: .normal)
                print("You are not following the user")
            }

        
        }) { (error) in
        
            print(error.localizedDescription)
        }
        

        
        self.name.text = self.otherUser?["name"] as? String
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapFollow(_ sender: AnyObject) {
        
        
        
        //use ternary operator to check if the profile_picture exists
        //if not set it as nil - firebase will not create a entry for the profile_pic
        let followersRef = "followers/\(self.otherUser?["uid"] as! String)/\(self.loggedInUserData?["uid"] as! String)"
        let followingRef = "following/" + (self.loggedInUserData?["uid"] as! String) + "/" + (self.otherUser?["uid"] as! String)
        
        
        if(self.followButton.titleLabel?.text == "Follow")
        {
            print("follow user")
            
            let loggedInUserProfilePic = self.loggedInUserData?["profile_pic"] != nil ? self.loggedInUserData?["profile_pic"]! : nil
            let otherUserProfilePic = self.otherUser?["profile_pic"] != nil ? self.otherUser?["profile_pic"]! : nil
            
            let followersData = ["name":self.loggedInUserData?["name"] as! String,
                        "handle":self.loggedInUserData?["handle"] as! String,
                "profile_pic": loggedInUserProfilePic]
            
            let followingData = ["name":self.otherUser?["name"] as! String,
                                 "handle":self.otherUser?["handle"] as! String,
                                 "profile_pic":otherUserProfilePic]
            
            //"profile_pic":self.otherUser?["profile_pic"] != nil ? self.loggedInUserData?["profile_pic"] as! String : ""
            let childUpdates = [followersRef:followersData,
                                followingRef:followingData]
            
            
            databaseRef.updateChildValues(childUpdates)
            
            print("data updated")
            
                        
            
            
            //update following count under the logged in user
            //update followers count in the user that is being followed
            let followersCount:Int?
            let followingCount:Int?
            if(self.otherUser?["followersCount"] == nil)
            {
                //set the follower count to 1
                followersCount=1
            }
            else
            {
                followersCount = self.otherUser?["followersCount"] as! Int + 1
            }
            
            //check if logged in user  is following anyone
            //if not following anyone then set the value of followingCount to 1
            if(self.loggedInUserData?["followingCount"] == nil)
            {
                followingCount = 1
            }
                //else just add one to the current following count
            else
            {
            
                followingCount = self.loggedInUserData?["followingCount"] as! Int + 1
            }
        
            databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("followingCount").setValue(followingCount!)
            databaseRef.child("user_profiles").child(self.otherUser?["uid"] as! String).child("followersCount").setValue(followersCount!)
            
            
        }
        else
        {
            databaseRef.child("user_profiles").child(self.loggedInUserData?["uid"] as! String).child("followingCount").setValue(self.loggedInUserData!["followingCount"] as! Int - 1)
            databaseRef.child("user_profiles").child(self.otherUser?["uid"] as! String).child("followersCount").setValue(self.otherUser!["followersCount"] as! Int - 1)
            
          let followersRef = "followers/\(self.otherUser?["uid"] as! String)/\(self.loggedInUserData?["uid"] as! String)"
          let followingRef = "following/" + (self.loggedInUserData?["uid"] as! String) + "/" + (self.otherUser?["uid"] as! String)
            
            
            let childUpdates = [followingRef:NSNull(),followersRef:NSNull()]
            databaseRef.updateChildValues(childUpdates)
            
            
        }
        
    }

}
