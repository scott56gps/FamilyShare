//
//  User.swift
//  FamilyShareWorkingPrototype
//
//  Created by Scott Nicholes on 7/9/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class User {
    var ancestors: [Ancestor]
    
    init?() {
        //self.ancestors = ancestors
        
        // For now, make dummy data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let mayDate = dateFormatter.date(from: "2018/05/31")
        
        self.ancestors = [Ancestor(name: "Margarita Lopez", gender: Gender.female, ordinancesAvailable: [.baptism], reservedDate: mayDate!, sharedBy: nil), Ancestor(name: "Carolina Gonzales", gender: Gender.female, ordinancesAvailable: [.endowment], reservedDate: mayDate!, sharedBy: nil), Ancestor(name: "Miguel Lopez", gender: Gender.male, ordinancesAvailable: [.initiatory], reservedDate: mayDate!, sharedBy: nil)]
    }
}
