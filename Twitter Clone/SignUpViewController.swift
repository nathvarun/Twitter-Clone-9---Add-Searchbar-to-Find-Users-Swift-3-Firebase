//
//  SignUpViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 06/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth


class SignUpViewController: UIViewController {


    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
     @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var signUp: UIBarButtonItem!
 
    
    var databaseRef = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        signUp.isEnabled = false
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapCancel(_ sender: AnyObject) {
        
        dismiss(animated: true, completion: nil)
    }

  
    @IBAction func didTapSignup(_ sender: AnyObject) {

        //disbable the signUp Button to prevent user from clicking twice
        signUp.isEnabled = false
        
        FIRAuth.auth()?.createUser(withEmail: email.text!, password: password.text!, completion: { (user, error) in
        
            if(error != nil)
            {
                    self.errorMessage.text = error?.localizedDescription
            }
            else
            {
                self.errorMessage.text = "Registered Succesfully"
        
                FIRAuth.auth()?.signIn(withEmail: self.email.text!, password: self.password.text!, completion: { (user, error) in
        
                    if(error == nil)
                    {
                        self.databaseRef.child("user_profiles").child(user!.uid).child("email").setValue(self.email.text!)
                        
                        self.performSegue(withIdentifier: "HandleViewSegue", sender: nil)
                    }
                    
                })
            }
        })
        

    
    }
    @IBAction func textDidChange(_ sender: UITextField) {
        
        if(email.text!.characters.count>0 && password.text!.characters.count>0)
        {
            signUp.isEnabled = true
        }
        else
        {
            signUp.isEnabled = false
        }
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}
