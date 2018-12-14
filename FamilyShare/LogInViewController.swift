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
    //MARK: Outlets
    @IBOutlet weak var infoLable: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameTextField.delegate = self
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
        let defaults = UserDefaults.standard
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
                        
                        // Save the userId in UserDefaults
                        defaults.set(userId!, forKey: "User Id")
                    }
                }
            }
        } else {
            infoLable.text = "User is already logged in"
        }
    }
    

}
