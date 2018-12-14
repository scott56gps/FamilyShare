//
//  Ancestor.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class Ancestor {
    var id: Int
    var givenNames: String
    var surname: String
    var gender: String
    var neededOrdinance: Ordinance
    
    init?(id: Int, givenNames: String, surname: String, gender: String, neededOrdinance: Ordinance) {
        if (givenNames.isEmpty || surname.isEmpty || gender.isEmpty) {
            return nil
        }
        
        self.id = id
        self.givenNames = givenNames
        self.surname = surname
        self.gender = gender
        self.neededOrdinance = neededOrdinance
    }
}
