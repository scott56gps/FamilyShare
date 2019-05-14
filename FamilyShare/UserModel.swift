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
    func logInUser(username: String, _ callback: @escaping (Error?) -> Void) {
        // Make a request to log the user in
        let loginUrl = url.appendingPathComponent("login")
        
        var parameters = [String: String]()
    }
}
