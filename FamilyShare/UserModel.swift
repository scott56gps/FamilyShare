//
//  UserModel.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 5/13/19.
//  Copyright © 2019 Scott Nicholes. All rights reserved.
//

import Foundation
import Alamofire

class UserModel {
    var url = URL(string: "https://familyshare-server.herokuapp.com")!
    func logInUser(username: String, _ callback: @escaping (String?, Int?) -> Void) {
        // Make a request to log the user in
        let loginUrl = url.appendingPathComponent("login")
        
        var parameters = [String: String]()
        parameters["username"] = username
        
        Alamofire.request(loginUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        .validate()
        .responseJSON() { response in
            switch response.result {
            case .success:
                guard let userIdDictionary = response.result.value as? Dictionary<String, Any> else {
                    callback("Could not create dictionary for value \(String(describing: response.result.value))", nil)
                    return
                }
                
                if let userId = userIdDictionary["userId"] as? Int {
                    callback(nil, userId)
                    return
                } else {
                    callback("Did not parse userId from dictionary \(userIdDictionary)", nil)
                    return
                }
            case .failure(let error):
                callback(error.localizedDescription, nil)
                return
            }
        }
    }
}
