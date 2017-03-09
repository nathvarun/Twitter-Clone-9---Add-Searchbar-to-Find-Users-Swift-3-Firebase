//
//  ViewController.swift
//  Twitter Clone
//
//  Created by Varun Nath on 06/08/16.
//  Copyright © 2016 UnsureProgrammer. All rights reserved.
//

import UIKit
import FirebaseAuth


class ViewController: UIViewController{

    override func viewDidLoad() {
        super.viewDidLoad()

        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            
            if user != nil{
                
                print("user is signed in")
                
                //send the user to the homeViewController
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main",bundle:nil)
                
                let homeViewController: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarControllerView")
                
                //send the user to the homescreen
                self.present(homeViewController, animated: true, completion: nil)
                
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

