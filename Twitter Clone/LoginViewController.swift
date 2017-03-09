//
//  LoginViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 06/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class LoginViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorMessage: UILabel!

    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    
    var rootRef = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        //add gesture recognizer to hide keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.hideKeyboard))
        
        self.view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
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

    @IBAction func didTapLogin(_ sender: AnyObject) {
        
        FIRAuth.auth()?.signIn(withEmail: self.email.text!, password: self.password.text!, completion: { (user, error
            ) in
            
            if(error == nil)
            {
                self.rootRef.child("user_profiles").child((user?.uid)!).child("handle").observeSingleEvent(of: .value, with: { (snapshot:FIRDataSnapshot) in
                    
                    if(!snapshot.exists())
                    {
                        //user does not have a handle
                        //send the user to the handleView
                        
                        self.performSegue(withIdentifier: "HandleViewSegue", sender: nil)
                    }
                    else
                    {
                        self.performSegue(withIdentifier: "HomeViewSegue", sender: nil)
                    }
                })
            }
            else
            {
                self.errorMessage.text = error?.localizedDescription
            }

        })
    
    }
    
    @IBAction func didTapLoginAsVarun(_ sender: UIButton) {
        
        email.text = "nathvarun@hotmail.com"
        password.text = "password"
        
    }
    
    @IBAction func didTapLoginAsJohn(_ sender: UIButton) {
        
        email.text = "test@gmail.com"
        password.text = "password"
        
    }
    
    @IBAction func didTapUnsure(_ sender: UIButton) {
        
        email.text = "unsureprogrammer@gmail.com"
        password.text = "password"
    }
    
    
}
