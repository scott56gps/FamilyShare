//
//  Ancestor.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class AncestorSummary {
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
    
    init?(ancestorDictionary: [String: Any]) {
        guard let id = ancestorDictionary["id"]! as? Int else {
            return nil
        }
        guard let givenName = ancestorDictionary["given_name"]! as? String else {
            return nil
        }
        guard let surname = ancestorDictionary["surname"]! as? String else {
            return nil
        }
        guard let gender = ancestorDictionary["gender"]! as? String else {
            return nil
        }
        guard let ordinanceString = ancestorDictionary["ordinance_needed"]! as? String else {
            return nil
        }
        
        self.id = id
        self.givenNames = givenName
        self.surname = surname
        self.gender = gender
        
        if let ordinance = Ordinance(rawValue: ordinanceString) {
            self.neededOrdinance = ordinance
        } else {
            return nil
        }
    }
}
