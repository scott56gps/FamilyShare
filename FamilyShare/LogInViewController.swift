//
//  LogInViewController.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 12/13/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import Alamofire

enum Toggle {
    case enable
    case disable
}

class LogInViewController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    let userModel = UserModel()
    let defaults = UserDefaults.standard
    
    //MARK: Outlets
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // If a user is not logged in
        if defaults.string(forKey: "User Id") == nil {
            // Disable the log out button
            toggleButton(button: logOutButton, toggle: .disable)
            
            // Hide the infoLabel
            toggleUsernameDisplay(displayLabel: infoLabel, toggle: .disable)
        } else {
            // Disable the log in button
            toggleButton(button: logInButton, toggle: .disable)
            
            // Disable the sign up button
            toggleButton(button: signUpButton, toggle: .disable)
            
            // Display the username
            if let username = defaults.string(forKey: "Username") {
                infoLabel.isHidden = false
                infoLabel.text = "\(username) signed in"
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
        
        if (usernameTextField.text!.isEmpty) {
            return
        }
        
        if usernameTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
        }
        
        // If there is no userId in UserDefaults, then make a request to get the id
        if (defaults.string(forKey: "User Id") == nil) {
            let username = usernameTextField.text!
            usernameTextField.text = ""
            
            // Make a log in request
            userModel.logInUser(username: username) { [unowned self] (error: String?, userId: Int?) in
                guard error == nil else {
                    debugPrint(error!)
                    return
                }
                
                if userId != nil {
                    // Save the userId and username in UserDefaults
                    self.defaults.set(userId, forKey: "User Id")
                    self.defaults.set(username, forKey: "Username")
                    
                    // Disable the log in button
                    self.toggleButton(button: self.logInButton, toggle: .disable)
                    
                    // Disable the sign up button
                    self.toggleButton(button: self.signUpButton, toggle: .disable)
                    
                    // Enable the log out button
                    self.toggleButton(button: self.logOutButton, toggle: .enable)
                    
                    // Display username
                    self.infoLabel.text = "\(username) logged in"
                    self.toggleUsernameDisplay(displayLabel: self.infoLabel, toggle: .enable)
                } else {
                    debugPrint("userId returned nil from logInUser")
                    return
                }
            }
        } else {
            print("User is already logged in")
        }
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        // Delete the values for User Id and Username
        defaults.removeObject(forKey: "User Id")
        defaults.removeObject(forKey: "Username")
        
        // Disable the log out button
        toggleButton(button: logOutButton, toggle: .disable)
        
        // Enable the log in button
        toggleButton(button: logInButton, toggle: .enable)
        
        // Enable the sign up button
        toggleButton(button: signUpButton, toggle: .enable)
        
        // Hide the username display
        toggleUsernameDisplay(displayLabel: infoLabel, toggle: .disable)
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        if (usernameTextField.text == nil) {
            return
        }
        
        if usernameTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
        }
        
        guard defaults.string(forKey: "User Id") == nil else {
            debugPrint("User Id is not nil.  User Id must be nil to create a user")
            return
        }
        
        let username = usernameTextField.text!
        usernameTextField.text = ""
        
        userModel.postUser(username: username) { [unowned self] (error: String?, userId: Int?) in
            guard error == nil else {
                debugPrint(error!)
                return
            }
            
            if userId != nil {
                // Save the userId and username in UserDefaults
                self.defaults.set(userId, forKey: "User Id")
                self.defaults.set(username, forKey: "Username")
                
                // Disable the log in button
                self.toggleButton(button: self.logInButton, toggle: .disable)
                
                // Enable the log out button
                self.toggleButton(button: self.logOutButton, toggle: .enable)
                
                // Display username
                self.infoLabel.text = "\(username) created.  \(username) logged in"
                self.toggleUsernameDisplay(displayLabel: self.infoLabel, toggle: .enable)
            } else {
                debugPrint("User Id is nil")
                return
            }
        }
    }
    
    // MARK: Private Methods
    private func toggleButton(button: UIButton, toggle: Toggle) {
        switch toggle {
        case .enable:
            button.isEnabled = true
            button.alpha = 1.0
        case .disable:
            button.isEnabled = false
            button.alpha = 0.5
        }
    }
    
    private func toggleUsernameDisplay(displayLabel: UILabel, toggle: Toggle) {
        switch toggle {
        case .enable:
            displayLabel.isHidden = false
        case .disable:
            displayLabel.isHidden = true
        }
    }
}
