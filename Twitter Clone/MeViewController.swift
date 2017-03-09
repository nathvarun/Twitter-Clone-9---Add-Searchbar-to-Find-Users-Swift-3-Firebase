//
//  MeViewController.swift
//
//
//  Created by Varun Nath on 30/08/16.
//
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


class MeViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate {
    
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
    
    var loggedInUser:AnyObject?
    var databaseRef = FIRDatabase.database().reference()
    var storageRef = FIRStorage.storage().reference()
    
    var imagePicker = UIImagePickerController()
    
    var loggedInUserData: NSDictionary?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loggedInUser = FIRAuth.auth()?.currentUser
        
        //get the user profile by using observeSingleEvent to reduce loading times when something is changed
        //add separate observers for the required things
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            
            let snapshot = snapshot.value as! NSDictionary

            /** Store it in a variable **/
            self.loggedInUserData = snapshot
           
            
            self.name.text = snapshot["name"] as? String
            self.handle.text = snapshot["handle"] as? String
            
            //initially the user will not have an about data
            
            if(snapshot["about"] as? String != nil)
            {
                self.about.text = snapshot["about"] as? String
            }
            
            if(snapshot["profile_pic"] as? String != nil)
            {
                let databaseProfilePic = snapshot["profile_pic"]
                    as! String
                
                let data = try? Data(contentsOf: URL(string: databaseProfilePic)!)
                
                self.setProfilePicture(self.profilePicture,imageToSet:UIImage(data:data!)!)
                
            }
            
            
            if(snapshot["followersCount"] != nil)
            {
                print("followers count")
                print (snapshot["followersCount"]!)
                self.numberFollowers.setTitle("\(snapshot["followersCount"]!)", for: .normal)
            }
            
            if(snapshot["followingCount"] != nil)
            {
                print("following count")
                self.numberFollowing.setTitle("\(snapshot["followingCount"]!)", for: .normal)
            }
            
            
            
            
            self.imageLoader.stopAnimating()

            }) { (error) in
//          
                print("error")
//                print(error.localizedDescription)
        }
        
        /*
         add a separate observer for followersCount
        */
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("followersCount").observe(.value, with: { (snapshot) in
            
            print("followersCount")
            if(snapshot.exists())
            {
                self.numberFollowers.setTitle("\(snapshot.value!)", for: .normal)
            }
            
            }) { (error) in
                print(error.localizedDescription)
        }
        
        /*
         add a separate observer for followingCount
        */
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("followingCount").observe(.value, with: { (snapshot) in
        
            if(snapshot.exists())
            {
                self.numberFollowing.setTitle("\(snapshot.value!)", for: .normal)
            }
            }) { (error) in
                print(error.localizedDescription)
        }
        
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapLogout(_ sender: AnyObject) {
        
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
    
    
    internal func setProfilePicture(_ imageView:UIImageView,imageToSet:UIImage)
    {
        imageView.layer.cornerRadius = 10.0
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        imageView.image = imageToSet
    }
    
    
    @IBAction func didTapProfilePicture(_ sender: UITapGestureRecognizer) {
        
        //create the action sheet
        
        let myActionSheet = UIAlertController(title:"Profile Picture",message:"Select",preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let viewPicture = UIAlertAction(title: "View Picture", style: UIAlertActionStyle.default) { (action) in
            
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
        
        let photoGallery = UIAlertAction(title: "Photos", style: UIAlertActionStyle.default) { (action) in
            
            if UIImagePickerController.isSourceTypeAvailable( UIImagePickerControllerSourceType.savedPhotosAlbum)
            {
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true
                    , completion: nil)
            }
        }
        
        let camera = UIAlertAction(title: "Camera", style: UIAlertActionStyle.default) { (action) in
            
            if UIImagePickerController.isSourceTypeAvailable( UIImagePickerControllerSourceType.camera)
            {
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                self.imagePicker.allowsEditing = true
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
        
        myActionSheet.addAction(viewPicture)
        myActionSheet.addAction(photoGallery)
        myActionSheet.addAction(camera)
        
        myActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(myActionSheet, animated: true, completion: nil)
        
    }
    
    
    func dismissFullScreenImage(_ sender:UITapGestureRecognizer)
    {
        //remove the larger image from the view
        sender.view?.removeFromSuperview()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        self.imageLoader.startAnimating()
        setProfilePicture(self.profilePicture,imageToSet: image)
        
        
        
        if let imageData: Data = UIImagePNGRepresentation(self.profilePicture.image!)!
        {
            
            let profilePicStorageRef = storageRef.child("user_profiles/\(self.loggedInUser!.uid)/profile_pic")
            
            let _ = profilePicStorageRef.put(imageData, metadata: nil)
            {metadata,error in
                
                if(error == nil)
                {
                    let downloadUrl = metadata!.downloadURL()
                    
                    self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("profile_pic").setValue(downloadUrl!.absoluteString)
                }
                else
                {
                    print("error")
//                    print(error?.localizedDescription)
                }
                
                self.imageLoader.stopAnimating()
            }
        }
    
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    @IBAction func AboutDidEndEditing(_ sender: AnyObject) {
        
        
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("about").setValue(self.about.text)
        
    }

    @IBAction func didTapFollowing(_ sender: UIButton) {
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
       
        if(segue.identifier == "showFollowingTableViewController")
        {
            let showFollowingTableViewController = segue.destination as! ShowFollowingTableViewController
            showFollowingTableViewController.user = self.loggedInUser as? FIRUser
            
        }
        else if(segue.identifier == "showFollowersTableViewController")
        {
            let showFollowersTableViewController = segue.destination as! ShowFollowersTableViewController
            showFollowersTableViewController.user = self.loggedInUser as? FIRUser
            
        }
        
        
    }
   
    


}
