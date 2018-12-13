//
//  Ancestor.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class Ancestor {
    var name: String
    var gender: String
    var neededOrdinance: Ordinance
    
    init?(name: String, gender: String, neededOrdinance: Ordinance) {
        if (name.isEmpty || gender.isEmpty) {
            return nil
        }
        
        self.name = name
        self.gender = gender
        self.neededOrdinance = neededOrdinance
    }
}
