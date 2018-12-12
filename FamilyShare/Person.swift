//
//  Person.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/20/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class Person {
    var name: String
    
    init?(name: String) {
        // A person must have a name
        guard (!name.isEmpty) else {
            return nil
        }
        
        self.name = name
    }
}
