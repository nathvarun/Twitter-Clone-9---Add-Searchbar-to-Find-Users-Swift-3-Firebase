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
    
    var loggedInUser:AnyObject?
    var databaseRef = FIRDatabase.database().reference()
    var storageRef = FIRStorage.storage().reference()
    
    var imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loggedInUser = FIRAuth.auth()?.currentUser
        
        self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).observeSingleEvent(of: .value) { (snapshot:FIRDataSnapshot) in
            
            
            let snapshot = snapshot.value as! [String: AnyObject]
            
            self.name.text = snapshot["name"] as? String
            self.handle.text = snapshot["handle"] as? String
            
            //initially the user will not have an about data
            
            if(snapshot["about"] !== nil)
            {
                self.about.text = snapshot["about"] as? String
            }
            
            if(snapshot["profile_pic"] !== nil)
            {
                let databaseProfilePic = snapshot["profile_pic"]
                    as! String
                
                let data = try? Data(contentsOf: URL(string: databaseProfilePic)!)
                
                self.setProfilePicture(self.profilePicture,imageToSet:UIImage(data:data!)!)
            }
            
            self.imageLoader.stopAnimating()
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
            
            let uploadTask = profilePicStorageRef.put(imageData, metadata: nil)
            {metadata,error in
                
                if(error == nil)
                {
                    let downloadUrl = metadata!.downloadURL()
                    
                    self.databaseRef.child("user_profiles").child(self.loggedInUser!.uid).child("profile_pic").setValue(downloadUrl!.absoluteString)
                }
                else
                {
                    print(error?.localizedDescription)
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
    
}
