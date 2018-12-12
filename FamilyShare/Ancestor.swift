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
    var gender: Gender
    var ordinancesAvailable: [Ordinance]
    var reservedDate: Date
    var sharedBy: Member?
    
    init(name: String, gender: Gender, ordinancesAvailable: [Ordinance], reservedDate: Date, sharedBy: Member?) {
        self.name = name
        self.gender = gender
        self.ordinancesAvailable = ordinancesAvailable
        self.reservedDate = reservedDate
        self.sharedBy = sharedBy
    }
}
