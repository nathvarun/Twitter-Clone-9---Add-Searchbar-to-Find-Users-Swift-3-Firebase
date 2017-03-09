//
//  OtherUsersProfileViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 10/11/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import Firebase

class OtherUsersProfileViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var tweetsContainer: UIView!
    @IBOutlet weak var mediaContainer: UIView!
    @IBOutlet weak var likesContainer: UIView!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var handle: UILabel!
    @IBOutlet weak var about: UITextField!
    @IBOutlet weak var imageLoader: UIActivityIndicatorView!

    
    @IBOutlet weak var numberFollowing: UIButton!
    @IBOutlet weak var numberFollowers: UIButton!
    
    var loggedInUser:NSDictionary!
    
    var otherUser:NSDictionary!
    var userProfileData:NSDictionary?
    var databaseRef = FIRDatabase.database().reference()
    var storageRef = FIRStorage.storage().reference()
    
    var imagePicker = UIImagePickerController()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.name.text = otherUser!["name"] as? String
        self.handle.text = "@"+(otherUser!["handle"] as? String)!

        if(otherUser["about"] != nil)
        {
            self.about.text = otherUser!["about"] as? String
        }
        
        if(otherUser["profile_pic"] != nil)
        {
            let databaseProfilePic = otherUser!["profile_pic"] as! String
            let data = try? Data(contentsOf:URL(string:databaseProfilePic)!)
            
            self.setProfilePicture(self.profilePicture,imageToSet:UIImage(data:data!)!)
        }
        else
        {
            imageLoader.stopAnimating()
        }
    
        if(otherUser["followersCount"] != nil)
        {
            print("Followers Count")
            
            let followersCount = ("\(otherUser["followersCount"]!)")
            
            self.numberFollowers.setTitle(followersCount, for: .normal)
        }
    
        if(otherUser?["followingCount"] != nil)
        {
            let followingCount = ("\(otherUser["followersCount"]!)")
            self.numberFollowing.setTitle(followingCount, for: .normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    internal func setProfilePicture(_ imageView:UIImageView,imageToSet:UIImage)
    {
        imageView.layer.cornerRadius = 10.0
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        imageView.image = imageToSet
    }
    
    
    @IBAction func didTapLogout(_ sender: UIButton) {
      
        try! FIRAuth.auth()!.signOut()
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let welcomeViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "welcomeViewController")
        
        self.present(welcomeViewController, animated: true, completion: nil)

    }
    
    @IBAction func showComponents(_ sender: AnyObject) {
        
        if(sender.selectedSegmentIndex == 0)
        {
            UIView.animate(withDuration: 0.5, animations: {
                
                self.tweetsContainer.alpha = 1
                self.mediaContainer.alpha = 0
                self.likesContainer.alpha = 0
            })
        }
        else if(sender.selectedSegmentIndex == 1)
        {
            UIView.animate(withDuration: 0.5, animations: {
                
                self.mediaContainer.alpha = 1
                self.tweetsContainer.alpha = 0
                self.likesContainer.alpha = 0
                
            })
        }
        else
        {
            UIView.animate(withDuration: 0.5, animations: {
                self.likesContainer.alpha = 1
                self.tweetsContainer.alpha = 0
                self.mediaContainer.alpha = 0
            })
        }
    }
    



}
