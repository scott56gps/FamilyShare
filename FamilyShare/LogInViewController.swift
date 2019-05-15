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
    var isLoggedIn: Bool = false
    
    //MARK: Outlets
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
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
            
            // Disable the sign up button
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.5
            
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
                    self.setUserIdToDefaults(userId: userId!, defaults: self.defaults)
                    
                    // Disable the log in button
                    self.toggleButton(button: self.logInButton, toggle: .disable)
                    
                    // Disable the sign up button
                    self.toggleButton(button: self.signUpButton, toggle: .disable)
                    
                    // Enable the log out button
                    self.toggleButton(button: self.logOutButton, toggle: .enable)
                    
                    // Display username
                    self.toggleUsernameDisplay(infoLabel: self.infoLabel, username: username, toggle: .enable)
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
        logOutButton.isEnabled = false
        logOutButton.alpha = 0.5
        
        // Enable the log in button
        logInButton.isEnabled = true
        logInButton.alpha = 1.0
        
        // Enable the sign up button
        signUpButton.isEnabled = true
        signUpButton.alpha = 1.0
        
        // Hide the infoLabel
        infoLabel.isHidden = true
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        if (usernameTextField.text == nil) {
            return
        }
        
        if usernameTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
        }
        
        if (defaults.string(forKey: "User Id") == nil) {
            let username = usernameTextField.text!
            usernameTextField.text = ""
            
            Alamofire.request("https://postgres-query-ancestors.herokuapp.com/createUser/" + username, method: .post).validate().responseJSON { response in
                guard response.result.isSuccess else {
                    print("POST request for user_id failed")
                    
                    if let error = response.result.error as? AFError {
                        switch error {
                        case .responseValidationFailed(let reason):
                            
                            switch reason {
                            case .unacceptableStatusCode(let code):
                                self.infoLabel.isHidden = false
                                self.infoLabel.text = "\(username) is already signed up"
                            case .dataFileNil:
                                print("dataFileNil")
                            case .dataFileReadFailed(let at):
                                print("dataFileReadFailed at: \(at)")
                            case .missingContentType(let acceptableContentTypes):
                                print("missingContentType.  Acceptable types: \(acceptableContentTypes)")
                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                print("unacceptableContentType.  Acceptable types: \(acceptableContentTypes)")
                            }
                        default:
                            let defaultDescription = "Unknown"
                            print("Unknown error: \(error.errorDescription ?? defaultDescription)")
                        }
                    }
                    
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
                        
                        // Disable the log in button
                        self.logInButton.isEnabled = false
                        self.logInButton.alpha = 0.5
                        
                        // Enable the log out button
                        self.logOutButton.isEnabled = true
                        self.logOutButton.alpha = 1.0
                        
                        // Display username
                        self.infoLabel.isHidden = false
                        self.infoLabel.text = "\(username) created.  \(username) logged in"
                    }
                }
            }
        }
    }
    
    // MARK: Private Methods
    private func setUserIdToDefaults(userId: Int, defaults: UserDefaults) { defaults.set(userId, forKey: "User Id") }
    
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
    
    private func toggleUsernameDisplay(infoLabel: UILabel, username: String, toggle: Toggle) {
        switch toggle {
        case .enable:
            infoLabel.isHidden = false
            infoLabel.text = "\(username) logged in"
        case .disable:
            infoLabel.isHidden = true
            infoLabel.text = ""
        }
    }
}
