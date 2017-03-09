//
//  NewTweetViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 25/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class NewTweetViewController: UIViewController,UITextViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{

    @IBOutlet weak var newTweetTextView: UITextView!
    
    @IBOutlet weak var newTweetToolbar: UIToolbar!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    var toolbarBottomConstraintInitialValue:CGFloat?
    
    //create a reference to the database
    var databaseRef = FIRDatabase.database().reference()
    var loggedInUser:AnyObject?
    var loggedInUserData:NSDictionary? // data of logged in user
    //followers will be passed from the homeViewController
    var listFollowers = [NSDictionary?]()
    
    var imagePicker = UIImagePickerController()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        
        print("Received all the followers MACCHA")
        print(listFollowers)
        
        self.newTweetToolbar.isHidden = true
        
        self.loggedInUser = FIRAuth.auth()?.currentUser
        
        newTweetTextView.textContainerInset = UIEdgeInsetsMake(30, 20, 20, 20)
        newTweetTextView.text = "What's Happening?"
        newTweetTextView.textColor = UIColor.lightGray
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        enableKeyboardHideOnTap()
        
        self.toolbarBottomConstraintInitialValue = toolbarBottomConstraint.constant
     }
    
    fileprivate func enableKeyboardHideOnTap(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewTweetViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewTweetViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewTweetViewController.hideKeyboard))
        
        self.view.addGestureRecognizer(tap)
        
    }
    
    func keyboardWillShow(_ notification: Notification)
    {
        let info = (notification as NSNotification).userInfo!
        
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let duration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration, animations: { 
            
            self.toolbarBottomConstraint.constant = keyboardFrame.size.height
            
            self.newTweetToolbar.isHidden = false
            self.view.layoutIfNeeded()
        }) 
    }
    
    func keyboardWillHide(_ notification: Notification)
    {
        let duration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration, animations: { 
            
            self.toolbarBottomConstraint.constant = self.toolbarBottomConstraintInitialValue!
            
            self.newTweetToolbar.isHidden = true
            self.view.layoutIfNeeded()
        }) 
    }
    
    func hideKeyboard(){
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapCancel(_ sender: AnyObject) {
        
        dismiss(animated: true, completion: nil)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if(newTweetTextView.textColor == UIColor.lightGray)
        {
            newTweetTextView.text = ""
            newTweetTextView.textColor = UIColor.black
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return false
    }

    @IBAction func didTapTweet(_ sender: AnyObject) {
        
        var imagesArray = [AnyObject]()
        
        //extract the images from the attributed text
        self.newTweetTextView.attributedText.enumerateAttribute(NSAttachmentAttributeName, in: NSMakeRange(0, self.newTweetTextView.text.characters.count), options: []) { (value, range, true) in
        
            if(value is NSTextAttachment)
            {
                let attachment = value as! NSTextAttachment
                var image : UIImage? = nil
                
                if(attachment.image !== nil)
                {
                    image = attachment.image!
                    imagesArray.append(image!)
                }
                else
                {
                    print("No image found")
                }
            }
        }
        
        let tweetLength = newTweetTextView.text.characters.count
        let numImages = imagesArray.count
        
        //create a unique auto generated key from firebase database
        let key = self.databaseRef.child("tweets").childByAutoId().key
       
        let storageRef = FIRStorage.storage().reference()
        let pictureStorageRef = storageRef.child("user_profiles/\(self.loggedInUser!.uid)/media/\(key)")
        
        //reduce resolution of selected picture
        
        //user has entered text and an image
        if(tweetLength>0 && numImages>0)
        {
            let lowResImageData = UIImageJPEGRepresentation(imagesArray[0] as! UIImage, 0.50)

            _ = pictureStorageRef.put(lowResImageData!,metadata: nil)
            {metadata,error in
                
                if(error == nil)
                {
                    let downloadUrl = metadata!.downloadURL()
                    let timestamp = Date().timeIntervalSince1970
                    
                    /**
                     Under the user's id, put the user's id again and save his tweet under that
                    **/
                    var childUpdates = ["/users_feed/\(self.loggedInUser!.uid!)/\(key)/text":self.newTweetTextView.text,
                                        "/users_feed/\(self.loggedInUser!.uid!)/\(key)/timestamp":"\(timestamp)",
                                        "/users_feed/\(self.loggedInUser!.uid!)/\(key)/picture":downloadUrl!.absoluteString] as [String : Any]
                    
                    //post the tweet on all the followers timelines
                    for user in self.listFollowers{
                        
                        //post on the followers timeline as well
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/handle"] = self.loggedInUserData!["handle"] as! String
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/name"] = self.loggedInUserData!["name"] as! String
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/text"] = self.newTweetTextView.text
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/timestamp"]  = "\(Date().timeIntervalSince1970)"
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/uid"] = self.loggedInUser!.uid
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/picture"] = downloadUrl!.absoluteString
                    }
                    
                    self.databaseRef.updateChildValues(childUpdates)
                }

            }
            
            dismiss(animated: true, completion: nil)
        }
        //user has entered only text
        else if(tweetLength>0)
        {
          
            var childUpdates = ["/users_feed/\(self.loggedInUser!.uid!)/\(key)/text":newTweetTextView.text,
                                "/users_feed/\(self.loggedInUser!.uid!)/\(key)/timestamp":"\(Date().timeIntervalSince1970)"
                ] as [String : Any]
        
            /**
                Post under the logged in user_profile_tweets node
                These will show on the user's profile
            **/
            childUpdates["/user_profile_tweets/\(self.loggedInUser!.uid!)/\(key)/text"] =  newTweetTextView.text
            childUpdates["/user_profile_tweets/\(self.loggedInUser!.uid!)/\(key)/timestamp"] = "\(Date().timeIntervalSince1970)"
            childUpdates["/user_profile_tweets/\(self.loggedInUser!.uid!)/\(key)/tweet_by_uid"] = self.loggedInUser!.uid
           
            
            for user in self.listFollowers{
                
                //post on the followers timeline as well
                childUpdates["/users_feed/\(user!["uid"]!)/\(key)/handle"] = self.loggedInUserData!["handle"] as! String
                childUpdates["/users_feed/\(user!["uid"]!)/\(key)/name"] = self.loggedInUserData!["name"] as! String
                childUpdates["/users_feed/\(user!["uid"]!)/\(key)/text"] = self.newTweetTextView.text
                childUpdates["/users_feed/\(user!["uid"]!)/\(key)/timestamp"]  = "\(Date().timeIntervalSince1970)"
                childUpdates["/users_feed/\(user!["uid"]!)/\(key)/tweet_by_uid"] = self.loggedInUser!.uid
                childUpdates["users_feed/\(user!["uid"]!)/\(key)/key"] = key //store the key of the original tweet
                
            }

            self.databaseRef.updateChildValues(childUpdates)
            
            dismiss(animated: true, completion: nil)

        }
        //user has entered only an image
        else if(numImages>0)
        {
            let lowResImageData = UIImageJPEGRepresentation(imagesArray[0] as! UIImage, 0.50)

            _ = pictureStorageRef.put(lowResImageData!,metadata: nil)
            {metadata,error in
                
                if(error == nil)
                {
                    let downloadUrl = metadata!.downloadURL()
                    
                    var childUpdates = ["/users_feed/\(self.loggedInUser!.uid!)/\(key)/timestamp":"\(Date().timeIntervalSince1970)",
                                        "/users_feed/\(self.loggedInUser!.uid!)/\(key)/picture":downloadUrl!.absoluteString] as [String : Any]
                    
                    for user in self.listFollowers{
                        
                        //post on the followers timeline as well
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/handle"] = self.loggedInUserData!["handle"] as! String
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/name"] = self.loggedInUserData!["name"] as! String
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/timestamp"]  = "\(Date().timeIntervalSince1970)"
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/uid"] = self.loggedInUser!.uid
                        childUpdates["/users_feed/\(user!["uid"]!)/\(key)\(self.loggedInUser!.uid!)/\(key)/picture"] = downloadUrl!.absoluteString
                    }

                    self.databaseRef.updateChildValues(childUpdates)
                }
                else
                {
                    print(error?.localizedDescription)
                }
                
            }
            
            dismiss(animated: true, completion: nil)

        }
        
    }
    
    
    
    @IBAction func selectImageFromPhotos(_ sender: AnyObject) {
        
        //open the photo gallery
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        {
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .savedPhotosAlbum
            self.imagePicker.allowsEditing = true
            self.present(self.imagePicker, animated: true, completion: nil)
        }
      
    }
    
    //after user has picked an image from photo gallery, this function will be called
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        var attributedString = NSMutableAttributedString()
        
        if(self.newTweetTextView.text.characters.count>0)
        {
            attributedString = NSMutableAttributedString(string:self.newTweetTextView.text)
        }
        else
        {
            attributedString = NSMutableAttributedString(string:"What's Happening?\n")
        }
        
        let textAttachment = NSTextAttachment()
        
        textAttachment.image = image
        
        let oldWidth:CGFloat = textAttachment.image!.size.width
        
        let scaleFactor:CGFloat = oldWidth/(newTweetTextView.frame.size.width-50)
        
        textAttachment.image = UIImage(cgImage: textAttachment.image!.cgImage!, scale: scaleFactor, orientation: .up)
        
        let attrStringWithImage = NSAttributedString(attachment: textAttachment)
        
        attributedString.append(attrStringWithImage)
        
        newTweetTextView.attributedText = attributedString
        self.dismiss(animated: true, completion: nil)
        
        
        
    }
    
    
    

}
