//
//  HandleViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 06/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class HandleViewController: UIViewController {

    
    
    @IBOutlet weak var fullName: UITextField!
    @IBOutlet weak var handle: UITextField!
    @IBOutlet weak var startTweeting: UIBarButtonItem!
    @IBOutlet weak var errorMessage: UILabel!
    
    var user:AnyObject?

    var rootRef = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.user = FIRAuth.auth()?.currentUser
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func didTapStartTweeting(_ sender: AnyObject) {

        let handle = self.rootRef.child("handles").child(self.handle.text!).observeSingleEvent(of: .value, with: {(snapshot:FIRDataSnapshot) in
            
            if(!snapshot.exists())
            {
                //update the handle in the user_profiles and in the handles node
                
                self.rootRef.child("user_profiles").child(self.user!.uid).child("handle").setValue(self.handle.text!.lowercased())
                
                //update the name of the user
                
                self.rootRef.child("user_profiles").child(self.user!.uid).child("name").setValue(self.fullName.text!)
                
                
                //update the handle in the handle node
                
                self.rootRef.child("handles").child(self.handle.text!.lowercased()).setValue(self.user?.uid)
            
                //send the user to home screen
                self.performSegue(withIdentifier: "HomeViewSegue", sender: nil)
                
            
            }
            else
            {
                self.errorMessage.text = "Handle already in use!"
            }
            
            
        })
        
    }

    @IBAction func didTapBack(_ sender: AnyObject) {
        
        dismiss(animated: true, completion: nil)
    }

}
