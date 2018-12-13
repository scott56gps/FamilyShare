//
//  LogInViewController.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 12/13/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import Alamofire

class LogInViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var infoLable: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK: Actions
    @IBAction func logIn(_ sender: UITextField) {
        // If there is no userId in UserDefaults, then make a request to get the id
        let defaults = UserDefaults.standard
        if (defaults.string(forKey: "User Id") == nil) {
            // Make parameters
            var parameters = [String: String]()
            parameters["username"] = sender.text!
            
            // Make a log in request
            Alamofire.request("https://postgres-query-ancestors.herokuapp.com/login", method: .get, parameters: parameters).responseJSON { response in
                guard response.result.isSuccess else {
                    print("GET request for user_id failed: \(String(describing: response.result.error))")
                    return
                }
                
                guard let value = response.result.value else {
                    print("Data received was not able to be formed correctly")
                    return
                }
                
                if let array = value as? [Any] {
                    for object in array {
                        let jsonArray = object as? [String: Any]
                        let userId = jsonArray!["user_id"]! as? String
                        
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
