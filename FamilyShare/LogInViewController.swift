//
//  LogInViewController.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 12/13/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import Alamofire

class LogInViewController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    let defaults = UserDefaults.standard
    var isLoggedIn: Bool = false
    
    //MARK: Outlets
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // If a user is not logged in
        if defaults.string(forKey: "User Id") == nil {
            // Disable the log out button
            logOutButton.isEnabled = false
            logOutButton.alpha = 0.5
            
            // Hide the infoLabel
            infoLabel.isHidden = true
        } else {
            // Disable the log in button
            logInButton.isEnabled = false
            logInButton.alpha = 0.5
            
            // Display the username
            if let username = defaults.string(forKey: "Username") {
                infoLabel.isHidden = false
                infoLabel.text = "\(username) logged in"
            }
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        
        return true
    }
    
    //MARK: Actions
    @IBAction func logIn(_ sender: UIButton) {
        if (usernameTextField.text == nil) {
            return
        }
        
        // If there is no userId in UserDefaults, then make a request to get the id
        if (defaults.string(forKey: "User Id") == nil) {
            // Make parameters
            let username = usernameTextField.text!
            
            // Make a log in request
            Alamofire.request("https://postgres-query-ancestors.herokuapp.com/login/" + username, method: .get).responseJSON { response in
                guard response.result.isSuccess else {
                    print("GET request for user_id failed: \(String(describing: response.result.error))")
                    return
                }
                
                guard let value = response.result.value else {
                    print("Data received was not able to be formed correctly")
                    return
                }
                
                print(response)
                
                if let array = value as? [Any] {
                    for object in array {
                        let jsonArray = object as? [String: Any]
                        let userId = jsonArray!["user_id"]! as? Int
                        
                        // Save the userId and username in UserDefaults
                        self.defaults.set(userId!, forKey: "User Id")
                        self.defaults.set(username, forKey: "Username")
                    }
                }
            }
        } else {
            infoLabel.text = "User is already logged in"
        }
    }
    

}
